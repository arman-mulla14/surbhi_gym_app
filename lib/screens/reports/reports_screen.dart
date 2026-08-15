import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../utils/date_utils.dart';
import '../../widgets/member_avatar.dart';
import '../../models/member.dart';
import '../../models/payment.dart';
import '../../services/export_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  bool _isMonthWise = true;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTimeRange? _customDateRange;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    });
  }

  Future<void> _pickCustomDateRange() async {
    final initialDateRange = _customDateRange ?? DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 7)),
      end: DateTime.now(),
    );

    final newRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: initialDateRange,
    );

    if (newRange != null) {
      setState(() {
        _customDateRange = newRange;
      });
    }
  }

  bool _isDateInRange(DateTime date) {
    if (_isMonthWise) {
      return date.year == _selectedMonth.year && date.month == _selectedMonth.month;
    } else {
      if (_customDateRange == null) return true;
      // Truncate times for accurate comparison
      final dateOnly = DateTime(date.year, date.month, date.day);
      final startOnly = DateTime(_customDateRange!.start.year, _customDateRange!.start.month, _customDateRange!.start.day);
      final endOnly = DateTime(_customDateRange!.end.year, _customDateRange!.end.month, _customDateRange!.end.day);
      
      return (dateOnly.isAtSameMomentAs(startOnly) || dateOnly.isAfter(startOnly)) &&
             (dateOnly.isAtSameMomentAs(endOnly) || dateOnly.isBefore(endOnly));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        centerTitle: false,
        elevation: 0,
        actions: [
          Consumer<AppProvider>(
            builder: (context, provider, child) {
              return Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf),
                    tooltip: 'Export PDF',
                    onPressed: () => _exportReport(provider, isPdf: true),
                  ),
                  IconButton(
                    icon: const Icon(Icons.table_chart),
                    tooltip: 'Export Excel',
                    onPressed: () => _exportReport(provider, isPdf: false),
                  ),
                ],
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'New Members'),
            Tab(text: 'Paid'),
            Tab(text: 'Unpaid'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          Expanded(
            child: Consumer<AppProvider>(
              builder: (context, provider, child) {
                // Filter Data based on date range
                final newMembers = provider.members.where((m) => _isDateInRange(m.joiningDate)).toList();
                
                final paymentsInRange = provider.payments.where((p) => _isDateInRange(p.paymentDate)).toList();
                
                final totalRevenue = paymentsInRange.fold(0.0, (sum, p) => sum + p.amount);
                
                // For "Unpaid", we look at all members to see if they have pending dues in this period.
                // It's tricky to define "unpaid in a custom period", so we'll just show members who are currently unpaid,
                // OR we can just show global pending dues. Let's show members who currently have pending dues.
                final unpaidMembers = provider.members.where((m) {
                  if (!_isDateInRange(m.joiningDate)) return false;
                  final memberPayments = provider.payments.where((p) => p.memberId == m.id);
                  final totalPaid = memberPayments.fold(0.0, (sum, p) => sum + p.amount);
                  final pending = m.totalBilled - totalPaid;
                  return pending > 0;
                }).toList();

                final totalPending = unpaidMembers.fold(0.0, (sum, m) {
                  final memberPayments = provider.payments.where((p) => p.memberId == m.id);
                  final totalPaid = memberPayments.fold(0.0, (sum, p) => sum + p.amount);
                  return sum + (m.totalBilled - totalPaid);
                });

                return Column(
                  children: [
                    _buildSummaryCards(totalRevenue, newMembers.length, totalPending),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildNewMembersList(newMembers),
                          _buildPaidList(paymentsInRange, provider.members),
                          _buildUnpaidList(unpaidMembers, provider.payments),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _exportReport(AppProvider provider, {required bool isPdf}) async {
    // 1. Gather filtered data exactly as displayed
    final newMembers = provider.members.where((m) => _isDateInRange(m.joiningDate)).toList();
    final paymentsInRange = provider.payments.where((p) => _isDateInRange(p.paymentDate)).toList();
    
    final unpaidMembers = provider.members.where((m) {
      if (!_isDateInRange(m.joiningDate)) return false;
      final memberPayments = provider.payments.where((p) => p.memberId == m.id);
      final totalPaid = memberPayments.fold(0.0, (sum, p) => sum + p.amount);
      final pending = m.totalBilled - totalPaid;
      return pending > 0;
    }).toList();

    String reportTitle = _isMonthWise 
        ? 'Report_${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][_selectedMonth.month - 1]}_${_selectedMonth.year}'
        : 'Report_Custom_Range';

    try {
      if (isPdf) {
        await ExportService.exportToPdf(
          reportTitle: reportTitle,
          newMembers: newMembers,
          payments: paymentsInRange,
          unpaidMembers: unpaidMembers,
          allMembers: provider.members,
        );
      } else {
        await ExportService.exportToExcel(
          reportTitle: reportTitle,
          newMembers: newMembers,
          payments: paymentsInRange,
          unpaidMembers: unpaidMembers,
          allMembers: provider.members,
        );
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${isPdf ? 'PDF' : 'Excel'} exported successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildDateSelector() {
    return Container(
      color: Theme.of(context).primaryColor.withOpacity(0.05),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: const Text('Month Wise'),
                selected: _isMonthWise,
                onSelected: (selected) {
                  if (selected) setState(() => _isMonthWise = true);
                },
              ),
              const SizedBox(width: 16),
              ChoiceChip(
                label: const Text('Custom Range'),
                selected: !_isMonthWise,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _isMonthWise = false);
                    if (_customDateRange == null) _pickCustomDateRange();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isMonthWise)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.chevron_left), onPressed: _previousMonth),
                Text(
                  '${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][_selectedMonth.month - 1]} ${_selectedMonth.year}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(icon: const Icon(Icons.chevron_right), onPressed: _nextMonth),
              ],
            )
          else
            InkWell(
              onTap: _pickCustomDateRange,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _customDateRange == null 
                          ? 'Select Date Range' 
                          : '${AppDateUtils.formatDate(_customDateRange!.start)} - ${AppDateUtils.formatDate(_customDateRange!.end)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(double revenue, int newMembersCount, double totalPending) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: _buildCard('Revenue', AppDateUtils.formatCurrency(revenue), Colors.green),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildCard('New Members', newMembersCount.toString(), Colors.blue),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildCard('Pending Dues', AppDateUtils.formatCurrency(totalPending), Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildNewMembersList(List<Member> members) {
    if (members.isEmpty) return const Center(child: Text('No new members in this period.'));
    
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: members.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final member = members[index];
        return ListTile(
          leading: MemberAvatar(member: member),
          title: Text(member.name),
          subtitle: Text('Joined: ${AppDateUtils.formatDate(member.joiningDate)}'),
          trailing: Text('${member.shift} Shift', style: TextStyle(color: Colors.grey.shade600)),
        );
      },
    );
  }

  Widget _buildPaidList(List<Payment> payments, List<Member> allMembers) {
    if (payments.isEmpty) return const Center(child: Text('No payments recorded in this period.'));
    
    // Sort payments latest first
    final sortedPayments = List<Payment>.from(payments)..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sortedPayments.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final payment = sortedPayments[index];
        final member = allMembers.firstWhere((m) => m.id == payment.memberId, orElse: () => Member(id: '', name: 'Unknown', mobile: '', address: '', joiningDate: DateTime.now(), membershipDuration: 0, feeAmount: 0, totalBilled: 0, shift: ''));
        
        return ListTile(
          leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.check, color: Colors.white)),
          title: Text(member.name),
          subtitle: Text(AppDateUtils.formatDate(payment.paymentDate)),
          trailing: Text(AppDateUtils.formatCurrency(payment.amount), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
        );
      },
    );
  }

  Widget _buildUnpaidList(List<Member> unpaidMembers, List<Payment> allPayments) {
    if (unpaidMembers.isEmpty) return const Center(child: Text('No pending dues!'));
    
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: unpaidMembers.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final member = unpaidMembers[index];
        final memberPayments = allPayments.where((p) => p.memberId == member.id);
        final totalPaid = memberPayments.fold(0.0, (sum, p) => sum + p.amount);
        final pending = member.totalBilled - totalPaid;

        return ListTile(
          leading: MemberAvatar(member: member),
          title: Text(member.name),
          subtitle: Text(member.mobile),
          trailing: Text(AppDateUtils.formatCurrency(pending), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 16)),
        );
      },
    );
  }
}
