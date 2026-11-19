import 'package:flutter/material.dart';
import '../main.dart';
import '../theme.dart';
import 'owner_list_screen.dart';

/// CUSTOMERS screen (owner only): every customer who ever asked,
/// grouped by mobile number — the customer list for tracking.
///
/// One row per customer: name, mobile, how many enquiries they made,
/// when they last asked, and the status of their latest enquiry.
/// Tap a customer to see only their enquiries.
class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

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
      appBar: AppTheme.gradientAppBar(title: const Text('Customers')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase.from('enquiries').stream(primaryKey: ['id']),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Could not load customers: ${snapshot.error}'));
          }
          final enquiries =
              List<Map<String, dynamic>>.from(snapshot.data ?? []);

          // Group by mobile number: one customer = one mobile number.
          final byMobile = <String, List<Map<String, dynamic>>>{};
          for (final e in enquiries) {
            final mobile = (e['mobile'] as String?) ?? '';
            (byMobile[mobile] ??= []).add(e);
          }
          for (final list in byMobile.values) {
            list.sort((a, b) => (b['created_at'] as String)
                .compareTo(a['created_at'] as String));
          }
          final groups = byMobile.entries.toList()
            ..sort((a, b) => (b.value.first['created_at'] as String)
                .compareTo(a.value.first['created_at'] as String));

          if (groups.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No customers yet.\nWhen someone asks about a product, they will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: AppTheme.body),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              final latest = group.value.first;
              final name =
                  (latest['customer_name'] as String?) ?? 'Customer';
              final count = group.value.length;
              final latestStatus = latest['status'] as String?;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: AppTheme.cardDecoration,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => OwnerListScreen(
                        customerMobile: group.key,
                        customerName: name,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.navy,
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: AppTheme.heading,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${group.key}  •  $count ${count == 1 ? 'enquiry' : 'enquiries'}'
                                '  •  last ${_timeAgo(latest['created_at'] as String?)}',
                                style:
                                    const TextStyle(color: AppTheme.body),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: latestStatus == 'done'
                                ? Colors.green
                                : latestStatus == 'replied'
                                    ? Colors.blue
                                    : Colors.teal,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            (latestStatus ?? 'new').toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ],
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
