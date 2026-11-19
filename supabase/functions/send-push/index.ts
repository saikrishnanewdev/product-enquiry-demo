// Supabase Edge Function: send-push
//
// Sends a Firebase Cloud Messaging push when something new happens:
//   - a new enquiry is inserted  -> all OWNER phones get a push
//   - a new message is inserted  -> the OTHER side gets a push
//     (customer message -> owner phones; owner message -> that
//      enquiry's customer phone)
//
// TRIGGER: create a Database Webhook in the Supabase dashboard
// (Database -> Webhooks -> Create a new webhook):
//   - Table: enquiries, Events: Insert, Type: HTTP Request,
//     URL: https://<your-project-ref>.supabase.co/functions/v1/send-push
//     HTTP Headers: Authorization: Bearer <your anon key>
//   - Same again for Table: messages, Events: Insert.
// The webhook POSTs { type, table, record, ... } to this function.
//
// SECRET: set the Firebase service-account JSON as a Supabase secret
// named FIREBASE_SERVICE_ACCOUNT (whole JSON file contents, one line):
//   supabase secrets set FIREBASE_SERVICE_ACCOUNT='<contents of the .json>'
// Get the JSON from Firebase Console -> Project settings ->
// Service accounts -> Generate new private key.
// NEVER commit that JSON to git.
//
// Deploy: supabase functions deploy send-push

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { initializeApp, cert, getApps } from "npm:firebase-admin@12/app";
import { getMessaging } from "npm:firebase-admin@12/messaging";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

function firebaseApp() {
  if (getApps().length > 0) return getApps()[0];
  const raw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
  if (!raw) throw new Error("FIREBASE_SERVICE_ACCOUNT secret is not set");
  const serviceAccount = JSON.parse(raw);
  return initializeApp({ credential: cert(serviceAccount) });
}

async function tokensFor(
  supabase: ReturnType<typeof createClient>,
  role: string,
  enquiryId?: string,
): Promise<string[]> {
  let query = supabase.from("device_tokens").select("token").eq("role", role);
  if (enquiryId) query = query.eq("enquiry_id", enquiryId);
  const { data, error } = await query;
  if (error) throw error;
  return (data ?? []).map((row) => row.token as string);
}

Deno.serve(async (req) => {
  try {
    const payload = await req.json();
    const table = payload.table as string | undefined;
    const record = payload.record as Record<string, unknown> | undefined;
    if (payload.type !== "INSERT" || !table || !record) {
      return new Response(JSON.stringify({ ok: true, skipped: "not an insert" }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    const messaging = getMessaging(firebaseApp());

    let title = "";
    let body = "";
    let tokens: string[] = [];
    let data: Record<string, string> = {};

    if (table === "enquiries") {
      title = `New enquiry from ${record.customer_name ?? "a customer"}`;
      body = (record.description as string ?? "").slice(0, 100);
      tokens = await tokensFor(supabase, "owner");
      data = { type: "new_enquiry", enquiryId: String(record.id ?? "") };
    } else if (table === "messages") {
      const sender = record.sender as string;
      const enquiryId = String(record.enquiry_id ?? "");
      body = (record.message as string ?? "").slice(0, 100);
      // Look up who this chat belongs to so the push can name them.
      const { data: enq } = await supabase
        .from("enquiries")
        .select("customer_name")
        .eq("id", enquiryId)
        .single();
      const customerName = (enq?.customer_name as string) ?? "a customer";
      if (sender === "customer") {
        title = `New message from ${customerName}`;
        tokens = await tokensFor(supabase, "owner");
      } else {
        title = "Reply from the shop";
        tokens = await tokensFor(supabase, "customer", enquiryId);
      }
      data = { type: "new_message", enquiryId };
    } else {
      return new Response(JSON.stringify({ ok: true, skipped: "unknown table" }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    if (tokens.length === 0) {
      return new Response(
        JSON.stringify({ ok: true, sent: 0, reason: "no device tokens" }),
        { headers: { "Content-Type": "application/json" } },
      );
    }

    // DATA-ONLY message (no `notification` field): Android does NOT
    // auto-display it, so the app shows it exactly once — in the
    // foreground handler when open, in the background handler when
    // closed. Sending a `notification` payload as well made the phone
    // show every push twice (once by the system, once by the app).
    const result = await messaging.sendEachForMulticast({
      tokens,
      data: { ...data, title, body },
      android: { priority: "high" },
    });

    return new Response(
      JSON.stringify({
        ok: true,
        sent: result.successCount,
        failed: result.failureCount,
      }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (err) {
    console.error(err);
    return new Response(JSON.stringify({ ok: false, error: String(err) }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
