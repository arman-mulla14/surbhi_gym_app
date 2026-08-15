import 'package:flutter/material.dart';
import '../models/member.dart';
import '../models/payment.dart';
import '../models/gym_settings.dart';
import '../database/local_database.dart';

class AppProvider with ChangeNotifier {
  List<Member> _members = [];
  List<Payment> _payments = [];
  GymSettings _settings = GymSettings();

  List<Member> get members => _members;
  List<Payment> get payments => _payments;
  GymSettings get settings => _settings;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  Future<void> initData() async {
    try {
      _settings = await LocalDatabase.instance.readSettings();
      _members = await LocalDatabase.instance.readAllMembers();
      _payments = await LocalDatabase.instance.readAllPayments();
    } catch (e) {
      debugPrint("Error initializing data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Member operations
  Future<void> addMember(Member member) async {
    await LocalDatabase.instance.createMember(member);
    _members.insert(0, member);
    notifyListeners();
  }

  Future<void> updateMember(Member member) async {
    await LocalDatabase.instance.updateMember(member);
    final index = _members.indexWhere((m) => m.id == member.id);
    if (index != -1) {
      _members[index] = member;
      notifyListeners();
    }
  }

  Future<void> deleteMember(String id) async {
    await LocalDatabase.instance.deleteMember(id);
    _members.removeWhere((m) => m.id == id);
    _payments.removeWhere((p) => p.memberId == id);
    notifyListeners();
  }

  // Payment operations
  Future<void> addPayment(Payment payment) async {
    await LocalDatabase.instance.createPayment(payment);
    _payments.insert(0, payment);
    notifyListeners();
  }

  Future<void> deletePayment(String id) async {
    await LocalDatabase.instance.deletePayment(id);
    _payments.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  // Settings operations
  Future<void> updateSettings(GymSettings settings) async {
    await LocalDatabase.instance.updateSettings(settings);
    _settings = settings;
    notifyListeners();
  }
}
