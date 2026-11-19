import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';

enum ChatRole { customer, owner }

/// Chat thread for one enquiry. Used by both sides:
/// - the customer sees the shop's replies here after submitting,
/// - the owner sees the photo + details and replies here.
class EnquiryChatScreen extends StatefulWidget {
  const EnquiryChatScreen({
    super.key,
    required this.enquiryId,
    required this.role,
    required this.title,
  });

  final String enquiryId;
  final ChatRole role;
  final String title;

  @override
  State<EnquiryChatScreen> createState() => _EnquiryChatScreenState();
}

class _EnquiryChatScreenState extends State<EnquiryChatScreen> {
  final _messageController = TextEditingController();
  Map<String, dynamic>? _enquiry;
  bool _sending = false;

  bool get _isOwner => widget.role == ChatRole.owner;
  String get _sender => _isOwner ? 'owner' : 'customer';

  @override
  void initState() {
    super.initState();
    _loadEnquiry();
  }

  Future<void> _loadEnquiry() async {
    final row = await supabase
        .from('enquiries')
        .select()
        .eq('id', widget.enquiryId)
        .single();
    if (mounted) setState(() => _enquiry = row);
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await supabase.from('messages').insert({
        'enquiry_id': widget.enquiryId,
        'sender': _sender,
        'message': text,
      });
      _messageController.clear();
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send: ${e.message}')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _callCustomer() async {
    final mobile = _enquiry?['mobile'] as String?;
    if (mobile == null || mobile.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: mobile);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enquiry = _enquiry;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (_isOwner && enquiry != null)
            IconButton(
              icon: const Icon(Icons.call),
              tooltip: 'Call customer',
              onPressed: _callCustomer,
            ),
        ],
      ),
      body: Column(
        children: [
          if (enquiry != null) _EnquiryHeader(enquiry: enquiry),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase
                  .from('messages')
                  .stream(primaryKey: ['id'])
                  .eq('enquiry_id', widget.enquiryId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Could not load chat: ${snapshot.error}'));
                }
                // The realtime stream can briefly deliver a fresh
                // message twice; show each id once so the newest
                // bubble never doubles up.
                final seenIds = <String>{};
                final messages = List<Map<String, dynamic>>.from(snapshot.data ?? [])
                  ..retainWhere((m) => seenIds.add(m['id'] as String))
                  ..sort((a, b) => (a['created_at'] as String)
                      .compareTo(b['created_at'] as String));
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      _isOwner
                          ? 'No replies yet. Say hello and answer below.'
                          : 'Waiting for the shop to reply...',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final mine = msg['sender'] == _sender;
                    return Align(
                      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: mine ? Colors.teal : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          msg['message'] as String? ?? '',
                          style: TextStyle(
                            color: mine ? Colors.white : Colors.black87,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: _isOwner
                            ? 'Reply: yes, available, Rs...'
                            : 'Write a message...',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _sendMessage,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EnquiryHeader extends StatelessWidget {
  const _EnquiryHeader({required this.enquiry});

  final Map<String, dynamic> enquiry;

  @override
  Widget build(BuildContext context) {
    final photoUrl = enquiry['photo_url'] as String?;
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.teal.shade50,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (photoUrl != null && photoUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                photoUrl,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const SizedBox(width: 72, height: 72, child: Icon(Icons.image)),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  enquiry['description'] as String? ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  '${enquiry['customer_name'] ?? ''}  •  ${enquiry['mobile'] ?? ''}',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
