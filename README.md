# Product Enquiry Demo — Android app (Flutter + Supabase)

A basic **working demo** for a client: a customer asks "is this product
available?" with a photo, and the business owner replies inside the app.

## What it does

**Customer portal** ("I am a Customer")
- Take a photo or pick one from the gallery
- Write a short description, name, and mobile number
- Submit → the enquiry is saved, and the customer sees the owner's replies

**Business owner portal** ("I am the Business Owner")
- Live list of enquiries — a new enquiry appears at the top **instantly**,
  with a notification banner, a red badge, and a pop-up message
- Open an enquiry to see the photo, description, name, and mobile
  (tap the phone icon to call the customer)
- Chat with the customer in the app — e.g. "yes, available, Rs 1,200"

## Honest note about notifications

The instant alert works **while the owner portal is open** (Supabase
Realtime). Closed-app push notifications work too, through Firebase Cloud
Messaging (FCM) — see "Push notifications (closed app)" below. They need
a Firebase project, which is free, plus two small setup steps.

## Push notifications (closed app) — FCM setup

The app already contains the code (`lib/notifications.dart`, Edge
Function `supabase/functions/send-push`). Three things are needed to
switch it on:

**1. Firebase project + google-services.json (one time)**
- Create a free project at https://console.firebase.google.com
- Add an Android app with package name
  `com.automatebusinesssolutions.productenquiry_demo`
- Download `google-services.json` and put it at `android/app/google-services.json`
- Without this file the APK **will not build** — that is a Firebase
  requirement, not a bug. The file is a client config (it ships inside
  the app), not a secret.

**2. Deploy the Edge Function + set its secret**
- In Firebase Console → Project settings → Service accounts →
  Generate new private key. This downloads a JSON file — keep it private,
  never commit it to git.
- Install the Supabase CLI, then from the project folder:
  ```bash
  supabase link --project-ref <your-project-ref>
  supabase secrets set FIREBASE_SERVICE_ACCOUNT='<paste the whole JSON here>'
  supabase functions deploy send-push
  ```
  (The function also needs the standard `SUPABASE_URL` and
  `SUPABASE_SERVICE_ROLE_KEY` secrets, which Supabase sets automatically.)

**3. Two Database Webhooks (in the Supabase dashboard)**
- Database → Webhooks → Create a new webhook, twice:
  - Table `enquiries`, Events: Insert → URL
    `https://<your-project-ref>.supabase.co/functions/v1/send-push`,
    header `Authorization: Bearer <your anon key>`
  - Table `messages`, Events: Insert → same URL and header
- How it works: a new enquiry wakes the Edge Function, which sends an
  FCM push to every owner phone. A new message pushes to the other side
  (owner message → that enquiry's customer phone, and the other way round).

## Setup (5 minutes)

1. **Supabase** — create a free project at https://supabase.com
   (or reuse an existing one).
2. In the Supabase dashboard, open **SQL Editor → New query**, paste the
   whole `supabase-setup.sql` file, and press **Run**. This creates the
   `enquiries` and `messages` tables, the `enquiry-photos` storage bucket,
   and the demo policies.
3. In the dashboard go to **Settings → API**, copy the **Project URL** and
   the **anon public** key.
4. Open `lib/config.dart` — the Supabase URL and publishable key are
   already filled in. Those two are client keys made to ship inside the
   app. Never put the service_role key or the database password in the
   code.
5. Build & install (see below).

## Build the APK

```bash
flutter pub get
flutter build apk --release
```

The APK is at `build/app/outputs/flutter-apk/app-release.apk`.
Install it on two phones to demo both sides at once.

Every push to `main` also builds the APK automatically
(see `.github/workflows/build-apk.yml`) — download it from the
repo's **Actions** tab.

## Project layout

- `lib/main.dart` — app start, Supabase + push init
- `lib/notifications.dart` — FCM token, foreground/background push display
- `lib/config.dart` — Supabase URL + anon key (placeholders)
- `lib/screens/home_screen.dart` — role switch (Customer / Owner)
- `lib/screens/customer_enquiry_screen.dart` — photo + enquiry form
- `lib/screens/enquiry_chat_screen.dart` — chat thread (both sides)
- `lib/screens/owner_list_screen.dart` — live enquiry list + alerts
- `supabase-setup.sql` — tables, realtime, storage bucket, policies
- `supabase/functions/send-push/index.ts` — Edge Function that sends FCM pushes
