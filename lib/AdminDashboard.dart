
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:govassist/loginPage.dart';
import 'package:govassist/uploadSchemeDataset.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  static const Color primaryBlue = Color(0xFF315DB5);
  static const Color darkBlue = Color(0xFF173B7A);
  static const Color pageBackground = Color(0xFFF5F7FB);
  static const Color textDark = Color(0xFF17233C);

  // Supports Firestore Timestamp and common date formats.
  static DateTime? parseDeadline(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      final date = value.toDate();
      return DateTime(date.year, date.month, date.day);
    }

    final text = value.toString().trim();
    if (text.isEmpty) return null;

    final parsed = DateTime.tryParse(text);
    if (parsed != null) {
      return DateTime(parsed.year, parsed.month, parsed.day);
    }

    final parts = text.split('/');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);

      if (day != null && month != null && year != null) {
        // Reject impossible calendar dates.
        final date = DateTime(year, month, day);
        if (date.year == year &&
            date.month == month &&
            date.day == day) {
          return date;
        }
      }
    }

    return null;
  }

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'Are you sure you want to log out of your GovAssist admin account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseAuth.instance.signOut();
      if (!context.mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginPage()),
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  void _openPage(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim() ?? '';
    final name = displayName.isNotEmpty ? displayName : 'Admin';
    final email = user?.email ?? 'Email not available';
    final initials = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Scaffold(
      backgroundColor: pageBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 30),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [darkBlue, primaryBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.account_balance_rounded,
                          color: Colors.white,
                          size: 38,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'GovAssist',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 23,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'Admin control center',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Log out',
                          onPressed: () => _logout(context),
                          icon: const Icon(
                            Icons.logout,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    const Text(
                      'Welcome back,',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      email,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(18),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE9EDF4)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 27,
                          backgroundColor: const Color(0xFFE7EEFF),
                          child: Text(
                            initials.isEmpty ? 'A' : initials,
                            style: const TextStyle(
                              color: primaryBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                email,
                                style: const TextStyle(
                                  color: Color(0xFF788397),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 7),
                              const Text(
                                'ADMINISTRATOR',
                                style: TextStyle(
                                  color: Color(0xFF18794E),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.verified_user_outlined,
                          color: Color(0xFF23845B),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Dashboard overview',
                    style: TextStyle(
                      color: textDark,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Manage government scheme information in one place.',
                    style: TextStyle(color: Color(0xFF788397)),
                  ),
                  const SizedBox(height: 16),

                  // Live dashboard statistics.
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('schemes')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Text(
                          'Unable to load scheme statistics. Check Firestore rules.',
                          style: TextStyle(color: Colors.red),
                        );
                      }

                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final docs = snapshot.data!.docs;
                      final today = DateTime.now();
                      final todayDate =
                          DateTime(today.year, today.month, today.day);
                      final limit = todayDate.add(
                        const Duration(days: 30),
                      );

                      var active = 0;
                      var upcoming = 0;
                      var expired = 0;

                      for (final doc in docs) {
                        final data = doc.data();
                        final status = (data['status'] ?? '')
                            .toString()
                            .trim()
                            .toLowerCase();

                        if (status != 'active') continue;

                        active++;

                        final deadline =
                            AdminDashboard.parseDeadline(
                          data['application_deadline'],
                        );

                        if (deadline == null) continue;

                        if (deadline.isBefore(todayDate)) {
                          expired++;
                        } else if (!deadline.isAfter(limit)) {
                          upcoming++;
                        }
                      }

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final columns =
                              constraints.maxWidth >= 600 ? 4 : 2;
                          final width = (constraints.maxWidth -
                                  (columns - 1) * 12) /
                              columns;

                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              SizedBox(
                                width: width,
                                child: _StatCard(
                                  icon: Icons.dataset_outlined,
                                  label: 'Total schemes',
                                  value: '${docs.length}',
                                  accent: primaryBlue,
                                ),
                              ),
                              SizedBox(
                                width: width,
                                child: _StatCard(
                                  icon: Icons.check_circle_outline,
                                  label: 'Active schemes',
                                  value: '$active',
                                  accent: const Color(0xFF16805D),
                                ),
                              ),
                              SizedBox(
                                width: width,
                                child: _StatCard(
                                  icon: Icons.event_available_outlined,
                                  label: 'Deadlines in 30 days',
                                  value: '$upcoming',
                                  accent: const Color(0xFF9A62C7),
                                ),
                              ),
                              SizedBox(
                                width: width,
                                child: _StatCard(
                                  icon: Icons.event_busy_outlined,
                                  label: 'Past deadlines',
                                  value: '$expired',
                                  accent: const Color(0xFFCC8A24),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Scheme management',
                    style: TextStyle(
                      color: textDark,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 13),
                  _ActionTile(
                    icon: Icons.upload_file_rounded,
                    color: primaryBlue,
                    title: 'Upload scheme dataset',
                    subtitle: 'Import a CSV or JSON dataset',
                    onTap: () => _openPage(
                      context,
                      const UploadSchemeDataset(),
                    ),
                  ),
                  const SizedBox(height: 11),
                  _ActionTile(
                    icon: Icons.tune_rounded,
                    color: const Color(0xFF9A62C7),
                    title: 'Manage schemes and eligibility',
                    subtitle: 'Search, review and delete scheme records',
                    onTap: () => _openPage(
                      context,
                      const _SchemeManagementPage(),
                    ),
                  ),
                  const SizedBox(height: 11),
                  _ActionTile(
                    icon: Icons.history_rounded,
                    color: const Color(0xFFCC8A24),
                    title: 'Dataset upload history',
                    subtitle: 'Review imports, record counts and errors',
                    onTap: () => _openPage(
                      context,
                      const _UploadHistoryPage(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Log out securely'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFB42318),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      '© GovAssist • Secure & Simple',
                      style: TextStyle(
                        color: Color(0xFF9AA2AF),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9EDF4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(height: 15),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF17233C),
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF788397),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: const Color(0xFFE9EDF4)),
          ),
          child: Row(
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 23),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF17233C),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF788397),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF9AA2AF),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Dataset Upload History page.
// Expected Firestore collection: upload_history.
class _UploadHistoryPage extends StatelessWidget {
  const _UploadHistoryPage();

  String _formatDate(dynamic value) {
    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    } else if (value is String) {
      date = DateTime.tryParse(value);
    }

    if (date == null) return 'Date unavailable';

    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');

    return '$day/$month/${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminDashboard.pageBackground,
      appBar: AppBar(
        title: const Text('Dataset Upload History'),
        backgroundColor: AdminDashboard.darkBlue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('upload_history')
            .orderBy('uploadedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Could not load upload history. Check Firestore rules '
                  'and ensure uploaded records contain uploadedAt.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final uploads = snapshot.data!.docs;

          if (uploads.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history,
                      size: 55,
                      color: Color(0xFF9AA2AF),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No upload history yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Upload history will appear here after your upload '
                      'code saves records to Firestore.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Total uploads: ${uploads.length}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AdminDashboard.textDark,
                ),
              ),
              const SizedBox(height: 12),
              ...uploads.map((doc) {
                final data = doc.data();
                final fileName =
                    (data['fileName'] ?? 'Unnamed dataset').toString();
                final status =
                    (data['status'] ?? 'unknown').toString();
                final normalizedStatus = status.toLowerCase();
                final success = normalizedStatus == 'success' ||
                    normalizedStatus == 'completed';
                final failed = normalizedStatus == 'failed';

                final statusColor = success
                    ? const Color(0xFF16805D)
                    : failed
                        ? Colors.red
                        : const Color(0xFFCC8A24);

                return Card(
                  elevation: 0,
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(
                      color: Color(0xFFE9EDF4),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.description_outlined,
                              color: AdminDashboard.primaryBlue,
                              size: 30,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                fileName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _HistoryDetail(
                          label: 'Uploaded at',
                          value: _formatDate(data['uploadedAt']),
                        ),
                        _HistoryDetail(
                          label: 'Uploaded by',
                          value: (data['uploadedBy'] ?? 'Unknown').toString(),
                        ),
                        _HistoryDetail(
                          label: 'Total records',
                          value: '${data['totalRecords'] ?? 0}',
                        ),
                        _HistoryDetail(
                          label: 'Added records',
                          value: '${data['addedRecords'] ?? 0}',
                        ),
                        _HistoryDetail(
                          label: 'Updated records',
                          value: '${data['updatedRecords'] ?? 0}',
                        ),
                        if ((data['errorDetails'] ?? '').toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Error: ${data['errorDetails']}',
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _HistoryDetail extends StatelessWidget {
  const _HistoryDetail({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF788397),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AdminDashboard.textDark,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SchemeManagementPage extends StatefulWidget {
  const _SchemeManagementPage();

  @override
  State<_SchemeManagementPage> createState() =>
      _SchemeManagementPageState();
}

class _SchemeManagementPageState
    extends State<_SchemeManagementPage> {
  final TextEditingController _searchController =
      TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteScheme(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete scheme?'),
        content: Text(
          'Delete "${doc.data()['scheme_name'] ?? doc.id}"? '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await doc.reference.delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scheme deleted successfully.')),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not delete scheme: ${e.message ?? e.code}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminDashboard.pageBackground,
      appBar: AppBar(
        title: const Text('Manage Government Schemes'),
        backgroundColor: AdminDashboard.darkBlue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() => _search = value.trim().toLowerCase());
              },
              decoration: InputDecoration(
                hintText: 'Search name, ID, state or provider',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _search = '');
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<
                QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('schemes')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Could not load schemes. Check Firestore rules.'),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data();
                  final searchable = [
                    doc.id,
                    data['scheme_name'],
                    data['state'],
                    data['provider_name'],
                    data['scheme_type'],
                  ].map((v) => (v ?? '').toString().toLowerCase())
                      .join(' ');

                  return searchable.contains(_search);
                }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text('No schemes found.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();

                    return Card(
                      color: Colors.white,
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFE7EEFF),
                          child: Icon(
                            Icons.account_balance_outlined,
                            color: AdminDashboard.primaryBlue,
                          ),
                        ),
                        title: Text(
                          (data['scheme_name'] ?? 'Unnamed scheme')
                              .toString(),
                        ),
                        subtitle: Text(
                          'ID: ${doc.id}\n'
                          '${data['provider_name'] ?? 'Provider not specified'}'
                          ' • ${data['state'] ?? 'State not specified'}\n'
                          'Status: ${data['status'] ?? 'Not specified'}',
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          tooltip: 'Delete scheme',
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () => _deleteScheme(doc),
                        ),
                      ),
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
