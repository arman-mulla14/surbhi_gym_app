import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/member.dart';
import '../../models/payment.dart';
import '../../providers/app_provider.dart';

class LogPaymentScreen extends StatefulWidget {
  final Member member;

  const LogPaymentScreen({super.key, required this.member});

  @override
  State<LogPaymentScreen> createState() => _LogPaymentScreenState();
}

class _LogPaymentScreenState extends State<LogPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _paymentMethod = 'Cash';
  bool _extendMembership = false;
  double _renewalFee = 0;

  @override
  void initState() {
    super.initState();
    // Default to the member's fee amount if extending, or whatever is pending
    _renewalFee = widget.member.feeAmount;
    
    // Calculate pending to suggest an amount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      final memberPayments = provider.payments.where((p) => p.memberId == widget.member.id);
      final totalPaid = memberPayments.fold(0.0, (sum, p) => sum + p.amount);
      final pending = widget.member.totalBilled - totalPaid;
      
      if (pending > 0) {
        _amountController.text = pending.toString();
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _savePayment() {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text.trim());
      
      final payment = Payment(
        id: 'PAY${DateTime.now().millisecondsSinceEpoch}',
        memberId: widget.member.id,
        amount: amount,
        paymentDate: DateTime.now(),
        paymentMethod: _paymentMethod,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      final provider = Provider.of<AppProvider>(context, listen: false);
      
      // Save the payment
      provider.addPayment(payment);

      // Handle renewal
      if (_extendMembership) {
        final currentExpiry = widget.member.joiningDate.add(Duration(days: widget.member.membershipDuration));
        final isExpired = currentExpiry.isBefore(DateTime.now());
        
        // If expired, new joining date is today. If active, new joining date is the old expiry.
        final newJoiningDate = isExpired ? DateTime.now() : currentExpiry;
        
        final updatedMember = widget.member.copyWith(
          joiningDate: newJoiningDate,
          totalBilled: widget.member.totalBilled + _renewalFee,
        );
        provider.updateMember(updatedMember);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment logged successfully')),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Payment'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(child: Text(widget.member.name[0])),
              title: Text(widget.member.name),
              subtitle: Text('ID: ${widget.member.id}'),
            ),
            const Divider(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Payment Amount (₹)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.currency_rupee),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Amount is required';
                if (double.tryParse(value) == null) return 'Enter a valid number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _paymentMethod,
              decoration: const InputDecoration(labelText: 'Payment Method', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                DropdownMenuItem(value: 'Card', child: Text('Card/Bank Transfer')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _paymentMethod = value);
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes (Optional)', border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Extend Membership'),
              subtitle: const Text('Check this if this payment is for a new membership cycle.'),
              value: _extendMembership,
              onChanged: (val) {
                setState(() => _extendMembership = val);
                if (val && _amountController.text.isEmpty) {
                  _amountController.text = _renewalFee.toString();
                }
              },
            ),
            if (_extendMembership)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Membership will be extended by ${widget.member.membershipDuration} days. Total billed amount will increase by ₹$_renewalFee.',
                  style: TextStyle(color: Colors.grey[700], fontStyle: FontStyle.italic),
                ),
              ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _savePayment,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: const Text('Save Payment'),
            ),
          ],
        ),
      ),
    );
  }
}
