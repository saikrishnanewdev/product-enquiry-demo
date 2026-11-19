import 'package:flutter/material.dart';
import '../main.dart';
import '../my_enquiries.dart';
import 'enquiry_chat_screen.dart';

/// CUSTOMER's own queries: the enquiries this phone submitted,
/// so the customer can find a query again after going back.
///
/// The ids are kept on the phone (see MyEnquiries); the rows
/// themselves are read live from Supabase, so the status is current.
class MyEnquiriesScreen extends StatefulWidget {
  const MyEnquiriesScreen({super.key});

  @override
  State<MyEnquiriesScreen> createState() => _MyEnquiriesScreenState();
}

class _MyEnquiriesScreenState extends State<MyEnquiriesScreen> {
  List<String> _ids = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ids = await MyEnquiries.listIds();
    if (mounted) {
      setState(() {
        _ids = ids;
        _loading = false;
      });
    }
  }

  String _timeAgo(String? createdAt) {
    final dt = DateTime.tryParse(createdAt ?? '');
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My queries')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _ids.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      "You haven't asked about anything yet.\nTap 'I am a Customer' to ask about a product.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ),
                )
              : FutureBuilder<List<Map<String, dynamic>>>(
                  future: supabase
                      .from('enquiries')
                      .select()
                      .inFilter('id', _ids)
                      .order('created_at', ascending: false),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                            'Could not load your queries: ${snapshot.error}'),
                      );
                    }
                    final rows = snapshot.data ?? [];
                    if (rows.isEmpty) {
                      return const Center(
                        child: Text('No queries found.'),
                      );
                    }
                    return ListView.separated(
                      itemCount: rows.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final e = rows[index];
                        final photoUrl = e['photo_url'] as String?;
                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: photoUrl != null && photoUrl.isNotEmpty
                                ? Image.network(
                                    photoUrl,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const SizedBox(
                                      width: 56,
                                      height: 56,
                                      child: Icon(Icons.image),
                                    ),
                                  )
                                : const SizedBox(
                                    width: 56,
                                    height: 56,
                                    child: Icon(Icons.image),
                                  ),
                          ),
                          title: Text(
                            e['description'] as String? ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${_timeAgo(e['created_at'] as String?)}'
                            '  •  ${(e['status'] as String?) ?? 'new'}',
                          ),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => EnquiryChatScreen(
                                enquiryId: e['id'] as String,
                                role: ChatRole.customer,
                                title: 'Your enquiry',
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
