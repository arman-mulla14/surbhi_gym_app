import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../utils/date_utils.dart';
import '../../models/member.dart';
import '../../models/payment.dart';
import '../members/add_member_screen.dart';
import '../members/member_detail_screen.dart';
import '../../widgets/member_avatar.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onNavigateToPayments;

  const DashboardScreen({super.key, required this.onNavigateToPayments});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

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

          // Calculate pending dues for the selected month
          double monthlyPending = 0.0;
          for (var member in members) {
            // Was member active in this month?
            if (_selectedMonth.year > member.joiningDate.year ||
                (_selectedMonth.year == member.joiningDate.year && _selectedMonth.month >= member.joiningDate.month)) {
              
              final paidThisMonth = payments.where((p) => 
                p.memberId == member.id &&
                p.paymentDate.year == _selectedMonth.year &&
                p.paymentDate.month == _selectedMonth.month
              ).isNotEmpty;

              if (!paidThisMonth) {
                monthlyPending += member.feeAmount;
              }
            }
          }

          // Calculate monthly income for the selected month
          final monthlyPayments = payments.where((p) => 
            p.paymentDate.year == _selectedMonth.year && 
            p.paymentDate.month == _selectedMonth.month
          );
          final monthlyIncome = monthlyPayments.fold(0.0, (sum, p) => sum + p.amount);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeHeader(context, provider.settings.gymName),
                const SizedBox(height: 24),
                _buildStatsGrid(context, totalMembers, activeMembers),
                const SizedBox(height: 24),
                _buildMonthlyIncomeCard(context, monthlyIncome, pendingDues, monthlyPending),
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
          gymName.isEmpty ? 'Surbhi Fitness' : gymName,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, int total, int active) {
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
      ],
    );
  }

  Widget _buildMonthlyIncomeCard(BuildContext context, double monthlyIncome, double pendingDues, double monthlyPending) {
    final monthFormat = DateFormat('MMMM yyyy');
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _previousMonth,
                ),
                Text(
                  monthFormat.format(_selectedMonth),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _nextMonth,
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      'Income',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppDateUtils.formatCurrency(monthlyIncome),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      'Pending',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppDateUtils.formatCurrency(monthlyPending > 0 ? monthlyPending : 0),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
          onTap: widget.onNavigateToPayments,
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
            leading: MemberAvatar(member: member),
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
