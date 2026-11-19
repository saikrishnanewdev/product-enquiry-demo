import 'package:flutter/material.dart';
import '../app_role.dart';
import '../main.dart';
import '../notifications.dart';
import 'customers_screen.dart';
import 'enquiry_chat_screen.dart';
import 'owner_pin_screen.dart';
import 'role_gate.dart';

/// BUSINESS OWNER portal: live list of customer enquiries.
///
/// Uses Supabase Realtime: when a customer submits an enquiry while this
/// screen is open, the new row appears at the top immediately, a banner
/// pops up, and the "New" badge counts it. Closed-app push notifications
/// arrive via Firebase (see notifications.dart).
class OwnerListScreen extends StatefulWidget {
  const OwnerListScreen({super.key, this.customerMobile, this.customerName});

  /// When set, the list shows only this customer's enquiries
  /// (opened from the Customers screen).
  final String? customerMobile;
  final String? customerName;

  @override
  State<OwnerListScreen> createState() => _OwnerListScreenState();
}

class _OwnerListScreenState extends State<OwnerListScreen> {
  final Set<String> _seenIds = {};
  bool _firstLoad = true;
  String? _latestNewName;
  int _newCount = 0;
  String _statusFilter = 'all';

  Widget _statusPill(String? status) {
    final label = switch (status) {
      'replied' => 'REPLIED',
      'done' => 'DONE',
      _ => 'NEW',
    };
    final color = switch (status) {
      'replied' => Colors.blue,
      'done' => Colors.green,
      _ => Colors.teal,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 11),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // This phone gets a push for every new enquiry, even with the app closed.
    PushNotifications.registerToken(role: 'owner');
    // Ask for the notification permission here too, in case the
    // home-screen ask was missed.
    PushNotifications.askPermissionAndRegister();
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
            Text(widget.customerName ?? 'Customer enquiries'),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Switch role',
            onPressed: () async {
              // Only the owner (who knows the PIN) can switch this
              // phone back to the role picker.
              final navigator = Navigator.of(context);
              final ok = await navigator.push<bool>(
                MaterialPageRoute(
                  builder: (_) =>
                      const OwnerPinScreen(mode: OwnerPinMode.verify),
                ),
              );
              if (ok == true && mounted) {
                await AppRole.clear();
                if (!mounted) return;
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const RoleGate()),
                  (_) => false,
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.lock_outline),
            tooltip: 'Change PIN',
            onPressed: () async {
              final navigator = Navigator.of(context);
              final ok = await navigator.push<bool>(
                MaterialPageRoute(
                  builder: (_) =>
                      const OwnerPinScreen(mode: OwnerPinMode.verify),
                ),
              );
              if (ok == true && mounted) {
                navigator.push(
                  MaterialPageRoute(
                    builder: (_) =>
                        const OwnerPinScreen(mode: OwnerPinMode.set),
                  ),
                );
              }
            },
          ),
          if (widget.customerMobile == null)
            IconButton(
              icon: const Icon(Icons.people),
              tooltip: 'Customers',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const CustomersScreen()),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Live push status — if an enquiry push ever goes missing,
          // this line says on the phone itself where it got stuck.
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: ValueListenableBuilder<String>(
              valueListenable: PushNotifications.statusNotifier,
              builder: (context, status, _) => Text(
                'Notifications: $status',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
          ),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                for (final f in const ['all', 'new', 'replied', 'done'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f == 'all'
                          ? 'All'
                          : f[0].toUpperCase() + f.substring(1)),
                      selected: _statusFilter == f,
                      onSelected: (_) =>
                          setState(() => _statusFilter = f),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: widget.customerMobile == null
                  ? supabase.from('enquiries').stream(primaryKey: ['id'])
                  : supabase
                      .from('enquiries')
                      .stream(primaryKey: ['id'])
                      .eq('mobile', widget.customerMobile!),
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
                final visible = _statusFilter == 'all'
                    ? enquiries
                    : enquiries
                        .where((e) =>
                            (e['status'] as String?) == _statusFilter)
                        .toList();
                if (visible.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        enquiries.isEmpty
                            ? 'No enquiries yet.\nWhen a customer asks about a product, it will appear here instantly.'
                            : 'No $_statusFilter enquiries.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: visible.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final e = visible[index];
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
                          _statusPill(e['status'] as String?),
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
