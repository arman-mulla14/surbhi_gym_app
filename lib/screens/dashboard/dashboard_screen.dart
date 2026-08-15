import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../utils/date_utils.dart';
import '../../models/member.dart';
import '../../models/payment.dart';
import '../members/add_member_screen.dart';
import '../members/member_detail_screen.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback onNavigateToPayments;

  const DashboardScreen({super.key, required this.onNavigateToPayments});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: false,
        elevation: 0,
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          final members = provider.members;
          final payments = provider.payments;
          
          final totalMembers = members.length;
          final now = DateTime.now();
          final activeMembers = members.where((m) {
            final expiryDate = m.joiningDate.add(Duration(days: m.membershipDuration));
            return expiryDate.isAfter(now);
          }).length;
          
          final totalRevenue = payments.fold(0.0, (sum, p) => sum + p.amount);
          
          final totalBilled = members.fold(0.0, (sum, m) => sum + m.totalBilled);
          final pendingDues = totalBilled - totalRevenue;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeHeader(context, provider.settings.gymName),
                const SizedBox(height: 24),
                _buildStatsGrid(context, totalMembers, activeMembers, totalRevenue, pendingDues),
                const SizedBox(height: 32),
                _buildSectionHeader('Quick Actions'),
                const SizedBox(height: 16),
                _buildQuickActions(context),
                const SizedBox(height: 32),
                _buildSectionHeader('Recent Activity'),
                const SizedBox(height: 16),
                _buildRecentActivity(context, members, payments),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context, String gymName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome to',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        Text(
          gymName.isEmpty ? 'Surbhi Gym' : gymName,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, int total, int active, double revenue, double pendingDues) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          context,
          title: 'Total Members',
          value: total.toString(),
          icon: Icons.people_alt_outlined,
          color: Colors.blue,
        ),
        _buildStatCard(
          context,
          title: 'Active Members',
          value: active.toString(),
          icon: Icons.how_to_reg,
          color: Colors.green,
        ),
        _buildStatCard(
          context,
          title: 'Total Revenue',
          value: AppDateUtils.formatCurrency(revenue),
          icon: Icons.account_balance_wallet_outlined,
          color: Colors.orange,
        ),
        _buildStatCard(
          context,
          title: 'Pending Dues',
          value: AppDateUtils.formatCurrency(pendingDues > 0 ? pendingDues : 0),
          icon: Icons.warning_amber_rounded,
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionItem(
          context,
          icon: Icons.person_add_alt_1,
          label: 'Add Member',
          color: Colors.indigo,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddMemberScreen()),
            );
          },
        ),
        _buildActionItem(
          context,
          icon: Icons.payment,
          label: 'Collect',
          color: Colors.teal,
          onTap: onNavigateToPayments,
        ),
      ],
    );
  }

  Widget _buildActionItem(BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context, List<Member> members, List<Payment> payments) {
    if (members.isEmpty && payments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'No recent activity',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ),
      );
    }
    
    // Simple recent list of members for now
    final recentMembers = members.take(3).toList();
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: recentMembers.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final member = recentMembers[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Text(member.name.substring(0, 1).toUpperCase(),
                style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text('Joined ${AppDateUtils.formatDate(member.joiningDate)}'),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MemberDetailScreen(member: member),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
