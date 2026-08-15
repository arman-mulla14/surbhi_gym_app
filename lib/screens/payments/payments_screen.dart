import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../utils/date_utils.dart';
import '../../services/export_service.dart';
import '../../widgets/member_avatar.dart';
import '../members/log_payment_screen.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  String _shiftFilter = 'All'; // All, DAY, NIGHT
  String _statusFilter = 'All'; // All, Paid, Not Paid
  String _expiryFilter = 'All'; // All, Expired, < 5 Days, < 10 Days, < 15 Days
  String _sortBy = 'Name'; // Name, Expiry Date

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

  @override
  Widget build(BuildContext context) {
    final monthName = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][_selectedMonth.month - 1];
    final year = _selectedMonth.year;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
        centerTitle: false,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilters(monthName, year),
          Expanded(
            child: Consumer<AppProvider>(
              builder: (context, provider, child) {
                final now = DateTime.now();
                var members = provider.members.where((m) {
                  // Apply shift filter
                  if (_shiftFilter != 'All' && m.shift != _shiftFilter) {
                    return false;
                  }
                  
                  // Don't show members before they joined
                  if (_selectedMonth.year < m.joiningDate.year ||
                      (_selectedMonth.year == m.joiningDate.year && _selectedMonth.month < m.joiningDate.month)) {
                    return false;
                  }

                  
                  // Apply expiry filter
                  if (_expiryFilter != 'All') {
                    final expiryDate = m.joiningDate.add(Duration(days: m.membershipDuration));
                    final daysLeft = expiryDate.difference(now).inDays;
                    
                    if (_expiryFilter == 'Expired' && daysLeft >= 0) return false;
                    if (_expiryFilter == '< 5 Days' && (daysLeft < 0 || daysLeft > 5)) return false;
                    if (_expiryFilter == '< 10 Days' && (daysLeft < 0 || daysLeft > 10)) return false;
                    if (_expiryFilter == '< 15 Days' && (daysLeft < 0 || daysLeft > 15)) return false;
                    if (_expiryFilter == '< 30 Days' && (daysLeft < 0 || daysLeft > 30)) return false;
                  }
                  
                  return true;
                }).toList();
                
                // Apply sort
                members.sort((a, b) {
                  if (_sortBy == 'Name') {
                    return a.name.compareTo(b.name);
                  } else {
                    final expiryA = a.joiningDate.add(Duration(days: a.membershipDuration));
                    final expiryB = b.joiningDate.add(Duration(days: b.membershipDuration));
                    return expiryA.compareTo(expiryB);
                  }
                });

                // Build a list of items with their payment status for this month
                final List<Map<String, dynamic>> memberStatuses = members.map((m) {
                  final memberPaymentsThisMonth = provider.payments.where((p) {
                    return p.memberId == m.id &&
                        p.paymentDate.year == _selectedMonth.year &&
                        p.paymentDate.month == _selectedMonth.month;
                  }).toList();

                  final hasPaid = memberPaymentsThisMonth.isNotEmpty;
                  final amountPaid = memberPaymentsThisMonth.fold(0.0, (sum, p) => sum + p.amount);
                  memberPaymentsThisMonth.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
                  final latestPayment = memberPaymentsThisMonth.isNotEmpty ? memberPaymentsThisMonth.first : null;

                  return {
                    'member': m,
                    'hasPaid': hasPaid,
                    'amountPaid': amountPaid,
                    'latestPayment': latestPayment,
                  };
                }).toList();

                // Apply Status filter
                final filteredStatuses = memberStatuses.where((status) {
                  if (_statusFilter == 'Paid' && !status['hasPaid']) return false;
                  if (_statusFilter == 'Not Paid' && status['hasPaid']) return false;
                  return true;
                }).toList();

                if (filteredStatuses.isEmpty) {
                  return const Center(child: Text('No members found for this filter.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: filteredStatuses.length,
                  itemBuilder: (context, index) {
                    final item = filteredStatuses[index];
                    final member = item['member'];
                    final hasPaid = item['hasPaid'];
                    final amountPaid = item['amountPaid'];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: hasPaid ? Colors.green.shade200 : Colors.red.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                  MemberAvatar(
                                    member: member,
                                    radius: 20,
                                    backgroundColor: hasPaid ? Colors.green.shade100 : Colors.red.shade100,
                                    textStyle: TextStyle(color: hasPaid ? Colors.green.shade800 : Colors.red.shade800),
                                  ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      Text('${member.shift} Shift', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                      Text(
                                        'Expires: ${AppDateUtils.formatDate(member.joiningDate.add(Duration(days: member.membershipDuration)))}',
                                        style: TextStyle(color: Colors.orange.shade700, fontSize: 11, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: hasPaid ? Colors.green : Colors.red,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    hasPaid ? 'PAID' : 'NOT PAID',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            if (hasPaid) ...[
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Amount Paid in $monthName:', style: TextStyle(color: Colors.grey.shade700)),
                                  Row(
                                    children: [
                                      Text(AppDateUtils.formatCurrency(amountPaid), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.share, color: Colors.blue, size: 20),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Share Receipt',
                                        onPressed: () {
                                          if (item['latestPayment'] != null) {
                                            ExportService.generateInvoicePdf(
                                              member: member,
                                              payment: item['latestPayment'],
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                            if (!hasPaid) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => LogPaymentScreen(member: member),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.payment, color: Colors.red),
                                  label: const Text('Log Payment', style: TextStyle(color: Colors.red)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.red),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                            ],
                          ],
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

  Widget _buildFilters(String monthName, int year) {
    return Container(
      color: Theme.of(context).primaryColor.withOpacity(0.05),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: _previousMonth),
              Text(
                '$monthName $year',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: _nextMonth),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Shift',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  value: _shiftFilter,
                  items: ['All', 'DAY', 'NIGHT'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _shiftFilter = val);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  value: _statusFilter,
                  items: ['All', 'Paid', 'Not Paid'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _statusFilter = val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Expiry',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  value: _expiryFilter,
                  style: const TextStyle(fontSize: 13, color: Colors.black),
                  items: ['All', 'Expired', '< 5 Days', '< 10 Days', '< 15 Days', '< 30 Days']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _expiryFilter = val);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Sort By',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  value: _sortBy,
                  style: const TextStyle(fontSize: 13, color: Colors.black),
                  items: ['Name', 'Expiry Date']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _sortBy = val);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
