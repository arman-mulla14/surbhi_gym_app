import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../models/member.dart';
import '../../models/payment.dart';
import '../../providers/app_provider.dart';
import '../../utils/date_utils.dart';
import 'add_member_screen.dart';
import 'log_payment_screen.dart';

class MemberDetailScreen extends StatelessWidget {
  final Member member;

  const MemberDetailScreen({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        // Fetch the latest member data in case it was updated
        final latestMember = provider.members.firstWhere(
          (m) => m.id == member.id,
          orElse: () => member,
        );

        final memberPayments = provider.payments
            .where((p) => p.memberId == latestMember.id)
            .toList()
          ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate)); // latest first

        final totalPaid = memberPayments.fold(0.0, (sum, p) => sum + p.amount);
        final pendingAmount = latestMember.totalBilled - totalPaid;

        final expiryDate = latestMember.joiningDate.add(Duration(days: latestMember.membershipDuration));
        final isActive = expiryDate.isAfter(DateTime.now());

        return Scaffold(
          appBar: AppBar(
            title: const Text('Member Details'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddMemberScreen(member: latestMember),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _confirmDelete(context),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(context, latestMember, isActive),
                const SizedBox(height: 24),
                _buildInfoCard(context, latestMember, expiryDate),
                const SizedBox(height: 24),
                _buildFinancialCard(context, latestMember, totalPaid, pendingAmount),
                const SizedBox(height: 24),
                _buildSectionHeader('Payment History'),
                const SizedBox(height: 8),
                _buildPaymentHistory(context, memberPayments),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LogPaymentScreen(member: latestMember),
                ),
              );
            },
            icon: const Icon(Icons.payment),
            label: const Text('Log Payment'),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(BuildContext context, Member member, bool isActive) {
    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.grey[200],
          backgroundImage: member.photoPath != null
              ? (kIsWeb ? NetworkImage(member.photoPath!) : FileImage(File(member.photoPath!))) as ImageProvider
              : null,
          child: member.photoPath == null
              ? Text(member.name[0].toUpperCase(), style: const TextStyle(fontSize: 32))
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                member.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'ID: ${member.id}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isActive ? Colors.green : Colors.red,
                  ),
                ),
                child: Text(
                  isActive ? 'ACTIVE' : 'EXPIRED',
                  style: TextStyle(
                    color: isActive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context, Member member, DateTime expiryDate) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoRow(Icons.phone, 'Mobile', member.mobile),
            if (member.parentMobile != null && member.parentMobile!.isNotEmpty) ...[
              const Divider(),
              _buildInfoRow(Icons.phone_android, 'Parent Mobile', member.parentMobile!),
            ],
            const Divider(),
            _buildInfoRow(Icons.location_on, 'Address', member.address),
            if (member.college != null && member.college!.isNotEmpty) ...[
              const Divider(),
              _buildInfoRow(Icons.school, 'College/Work', member.college!),
            ],
            const Divider(),
            _buildInfoRow(Icons.access_time, 'Shift', '${member.shift} Shift'),
            const Divider(),
            _buildInfoRow(Icons.calendar_today, 'Joined', AppDateUtils.formatDate(member.joiningDate)),
            const Divider(),
            _buildInfoRow(Icons.event_busy, 'Expires', AppDateUtils.formatDate(expiryDate)),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialCard(BuildContext context, Member member, double totalPaid, double pendingAmount) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: pendingAmount > 0 ? Colors.orange.shade50 : Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Monthly Base Fee', style: TextStyle(color: Colors.grey)),
                Text(AppDateUtils.formatCurrency(member.feeAmount), style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Billed', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(AppDateUtils.formatCurrency(member.totalBilled), style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Paid', style: TextStyle(color: Colors.green)),
                Text(AppDateUtils.formatCurrency(totalPaid), style: const TextStyle(color: Colors.green)),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Pending Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                  AppDateUtils.formatCurrency(pendingAmount > 0 ? pendingAmount : 0),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: pendingAmount > 0 ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text('$label:', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
          ),
        ],
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

  Widget _buildPaymentHistory(BuildContext context, List<Payment> payments) {
    if (payments.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(
            child: Text('No payments recorded yet.', style: TextStyle(color: Colors.grey)),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final payment = payments[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.green,
              child: Icon(Icons.check, color: Colors.white),
            ),
            title: Text(AppDateUtils.formatCurrency(payment.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${AppDateUtils.formatDate(payment.paymentDate)} • ${payment.paymentMethod}'),
            trailing: payment.notes != null && payment.notes!.isNotEmpty 
              ? const Icon(Icons.note, color: Colors.grey)
              : null,
            onTap: payment.notes != null && payment.notes!.isNotEmpty 
              ? () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Payment Note'),
                      content: Text(payment.notes!),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                }
              : null,
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Member'),
        content: Text('Are you sure you want to delete ${member.name}? All associated payment records will also be removed. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Provider.of<AppProvider>(context, listen: false).deleteMember(member.id);
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Close detail screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Member deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
