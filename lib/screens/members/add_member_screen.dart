import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/member.dart';
import '../../providers/app_provider.dart';
import '../../services/camera_service.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class AddMemberScreen extends StatefulWidget {
  final Member? member;

  const AddMemberScreen({super.key, this.member});

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();

  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _parentMobileController = TextEditingController();
  final _addressController = TextEditingController();
  final _collegeController = TextEditingController();
  final _feeAmountController = TextEditingController();

  String _shift = 'DAY';
  DateTime _joiningDate = DateTime.now();
  int _membershipDuration = 30; // 1 month default
  String? _photoPath;

  @override
  void initState() {
    super.initState();
    if (widget.member != null) {
      final m = widget.member!;
      _idController.text = m.id;
      _nameController.text = m.name;
      _mobileController.text = m.mobile;
      _parentMobileController.text = m.parentMobile ?? '';
      _addressController.text = m.address;
      _collegeController.text = m.college ?? '';
      _feeAmountController.text = m.feeAmount.toString();
      _shift = m.shift;
      _joiningDate = m.joiningDate;
      _membershipDuration = m.membershipDuration;
      _photoPath = m.photoPath;
    } else {
      // Auto-generate ID (simple fallback)
      _idController.text = 'SG${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _mobileController.dispose();
    _parentMobileController.dispose();
    _addressController.dispose();
    _collegeController.dispose();
    _feeAmountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _joiningDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _joiningDate) {
      setState(() {
        _joiningDate = picked;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final path = await CameraService.capturePhoto();
      if (path != null) {
        setState(() {
          _photoPath = path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  void _saveMember() {
    if (_formKey.currentState!.validate()) {
      final feeAmount = double.tryParse(_feeAmountController.text.trim()) ?? 0.0;
      final newMember = Member(
        id: _idController.text.trim(),
        name: _nameController.text.trim(),
        mobile: _mobileController.text.trim(),
        parentMobile: _parentMobileController.text.trim().isEmpty ? null : _parentMobileController.text.trim(),
        address: _addressController.text.trim(),
        college: _collegeController.text.trim().isEmpty ? null : _collegeController.text.trim(),
        shift: _shift,
        joiningDate: _joiningDate,
        membershipDuration: _membershipDuration,
        feeAmount: feeAmount,
        totalBilled: widget.member?.totalBilled ?? feeAmount,
        photoPath: _photoPath,
      );

      final provider = Provider.of<AppProvider>(context, listen: false);
      if (widget.member != null) {
        provider.updateMember(newMember);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member updated successfully')),
        );
      } else {
        provider.addMember(newMember);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member added successfully')),
        );
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.member != null ? 'Edit Member' : 'Add Member'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _photoPath != null
                          ? (kIsWeb ? NetworkImage(_photoPath!) : FileImage(File(_photoPath!))) as ImageProvider
                          : null,
                      child: _photoPath == null
                          ? const Icon(Icons.person, size: 50, color: Colors.grey)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _idController,
              decoration: const InputDecoration(labelText: 'Member ID', border: OutlineInputBorder()),
              validator: (value) => value == null || value.isEmpty ? 'ID is required' : null,
              readOnly: widget.member != null, // Don't allow changing ID for existing members
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Name is required';
                if (value.trim().length < 3) return 'Name must be at least 3 characters';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _mobileController,
              decoration: const InputDecoration(labelText: 'Mobile Number', border: OutlineInputBorder()),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Mobile is required';
                if (!RegExp(r'^\d{10}$').hasMatch(value.trim())) return 'Enter a valid 10-digit mobile number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _parentMobileController,
              decoration: const InputDecoration(labelText: 'Parent Mobile (Optional)', border: OutlineInputBorder()),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  if (!RegExp(r'^\d{10}$').hasMatch(value.trim())) return 'Enter a valid 10-digit mobile number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
              validator: (value) => value == null || value.isEmpty ? 'Address is required' : null,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _collegeController,
              decoration: const InputDecoration(labelText: 'College/Work (Optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _shift,
              decoration: const InputDecoration(labelText: 'Shift', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'DAY', child: Text('Day Shift')),
                DropdownMenuItem(value: 'NIGHT', child: Text('Night Shift')),
              ],
              onChanged: (value) {
                setState(() {
                  if (value != null) _shift = value;
                });
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Joining Date'),
              subtitle: Text("${_joiningDate.toLocal()}".split(' ')[0]),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _membershipDuration,
              decoration: const InputDecoration(labelText: 'Membership Duration', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 30, child: Text('1 Month (30 days)')),
                DropdownMenuItem(value: 90, child: Text('3 Months (90 days)')),
                DropdownMenuItem(value: 180, child: Text('6 Months (180 days)')),
                DropdownMenuItem(value: 365, child: Text('1 Year (365 days)')),
              ],
              onChanged: (value) {
                setState(() {
                  if (value != null) _membershipDuration = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _feeAmountController,
              decoration: const InputDecoration(labelText: 'Fee Amount (₹)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Fee Amount is required';
                final amount = double.tryParse(value.trim());
                if (amount == null || amount <= 0) return 'Enter a valid fee amount';
                return null;
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveMember,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: const Text('Save Member'),
            ),
          ],
        ),
      ),
    );
  }
}
