import 'package:flutter/material.dart';
import '../main.dart';
import '../notifications.dart';
import 'enquiry_chat_screen.dart';

/// BUSINESS OWNER portal: live list of customer enquiries.
///
/// Uses Supabase Realtime: when a customer submits an enquiry while this
/// screen is open, the new row appears at the top immediately, a banner
/// pops up, and the "New" badge counts it. Closed-app push notifications
/// arrive via Firebase (see notifications.dart).
class OwnerListScreen extends StatefulWidget {
  const OwnerListScreen({super.key});

  @override
  State<OwnerListScreen> createState() => _OwnerListScreenState();
}

class _OwnerListScreenState extends State<OwnerListScreen> {
  final Set<String> _seenIds = {};
  bool _firstLoad = true;
  String? _latestNewName;
  int _newCount = 0;

  @override
  void initState() {
    super.initState();
    // This phone gets a push for every new enquiry, even with the app closed.
    PushNotifications.registerToken(role: 'owner');
  }

  void _checkForNew(List<Map<String, dynamic>> enquiries) {
    if (_firstLoad) {
      _seenIds.addAll(enquiries.map((e) => e['id'] as String));
      _firstLoad = false;
      return;
    }
    final fresh = enquiries.where((e) => !_seenIds.contains(e['id'] as String)).toList();
    if (fresh.isNotEmpty) {
      _seenIds.addAll(fresh.map((e) => e['id'] as String));
      setState(() {
        _latestNewName = fresh.first['customer_name'] as String?;
        _newCount += fresh.length;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'New enquiry from ${_latestNewName ?? 'a customer'}! Tap to view.',
          ),
          backgroundColor: Colors.teal,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  String _timeAgo(String? createdAt) {
    if (createdAt == null) return '';
    final dt = DateTime.tryParse(createdAt);
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
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Customer enquiries'),
            if (_newCount > 0) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 12,
                backgroundColor: Colors.red,
                child: Text(
                  '$_newCount',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
      body: Column(
        children: [
          if (_latestNewName != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.teal.shade100,
              child: Row(
                children: [
                  const Icon(Icons.notifications_active, color: Colors.teal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'New enquiry from $_latestNewName',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _latestNewName = null;
                      _newCount = 0;
                    }),
                    child: const Text('Dismiss'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase.from('enquiries').stream(primaryKey: ['id']),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Could not load: ${snapshot.error}'));
                }
                final enquiries = List<Map<String, dynamic>>.from(snapshot.data ?? [])
                  ..sort((a, b) => (b['created_at'] as String)
                      .compareTo(a['created_at'] as String));
                _checkForNew(enquiries);
                if (enquiries.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No enquiries yet.\nWhen a customer asks about a product, it will appear here instantly.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: enquiries.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final e = enquiries[index];
                    final photoUrl = e['photo_url'] as String?;
                    final isNew = (e['status'] as String?) == 'new';
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: photoUrl != null && photoUrl.isNotEmpty
                            ? Image.network(
                                photoUrl,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const SizedBox(
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
                        e['customer_name'] as String? ?? 'Customer',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        e['description'] as String? ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _timeAgo(e['created_at'] as String?),
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                          const SizedBox(height: 4),
                          if (isNew)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.teal,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'NEW',
                                style: TextStyle(color: Colors.white, fontSize: 11),
                              ),
                            ),
                        ],
                      ),
                      onTap: () {
                        setState(() {
                          if (_newCount > 0) _newCount--;
                        });
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EnquiryChatScreen(
                              enquiryId: e['id'] as String,
                              role: ChatRole.owner,
                              title: e['customer_name'] as String? ?? 'Enquiry',
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
