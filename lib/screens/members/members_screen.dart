import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../utils/date_utils.dart';
import '../../widgets/member_avatar.dart';
import 'add_member_screen.dart';
import 'member_detail_screen.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  String _searchQuery = '';
  
  // Filter & Sort State
  String _paymentFilter = 'All'; // All, Paid, Unpaid
  String _expiryFilter = 'All'; // All, Expiring Soon, Expired
  String _sortBy = 'Name'; // Name, Expiry Date

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Filter & Sort', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const Divider(),
                  const Text('Payment Status', style: TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 8,
                    children: ['All', 'Paid', 'Unpaid'].map((status) {
                      return ChoiceChip(
                        label: Text(status),
                        selected: _paymentFilter == status,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _paymentFilter = status);
                            setModalState(() {});
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Expiry Status', style: TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 8,
                    children: ['All', 'Expiring Soon', 'Expired'].map((status) {
                      return ChoiceChip(
                        label: Text(status),
                        selected: _expiryFilter == status,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _expiryFilter = status);
                            setModalState(() {});
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Sort By', style: TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 8,
                    children: ['Name', 'Expiry Date'].map((sort) {
                      return ChoiceChip(
                        label: Text(sort),
                        selected: _sortBy == sort,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _sortBy = sort);
                            setModalState(() {});
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Members'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or mobile',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
        ),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          final now = DateTime.now();
          
          var members = provider.members.where((m) {
            // Search filter
            final matchesSearch = m.name.toLowerCase().contains(_searchQuery) || 
                                  m.mobile.contains(_searchQuery);
            if (!matchesSearch) return false;
            
            // Payment filter
            if (_paymentFilter != 'All') {
              final memberPayments = provider.payments.where((p) => p.memberId == m.id);
              final totalPaid = memberPayments.fold(0.0, (sum, p) => sum + p.amount);
              final pending = m.totalBilled - totalPaid;
              
              if (_paymentFilter == 'Paid' && pending > 0) return false;
              if (_paymentFilter == 'Unpaid' && pending <= 0) return false;
            }
            
            // Expiry filter
            if (_expiryFilter != 'All') {
              final expiryDate = m.joiningDate.add(Duration(days: m.membershipDuration));
              final daysLeft = expiryDate.difference(now).inDays;
              
              if (_expiryFilter == 'Expired' && daysLeft >= 0) return false;
              if (_expiryFilter == 'Expiring Soon' && (daysLeft < 0 || daysLeft > 10)) return false;
            }
            
            return true;
          }).toList();
          
          // Apply Sorting
          members.sort((a, b) {
            if (_sortBy == 'Name') {
              return a.name.compareTo(b.name);
            } else {
              final expiryA = a.joiningDate.add(Duration(days: a.membershipDuration));
              final expiryB = b.joiningDate.add(Duration(days: b.membershipDuration));
              return expiryA.compareTo(expiryB);
            }
          });

          if (members.isEmpty) {
            return const Center(
              child: Text('No members found'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              final expiryDate = member.joiningDate.add(Duration(days: member.membershipDuration));
              final daysLeft = expiryDate.difference(DateTime.now()).inDays;
              
              Widget? statusBadge;
              if (daysLeft < 0) {
                statusBadge = Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                  child: const Text('Expired', style: TextStyle(color: Colors.white, fontSize: 10)),
                );
              } else if (daysLeft <= 10) {
                statusBadge = Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(10)),
                  child: Text('$daysLeft days left', style: const TextStyle(color: Colors.white, fontSize: 10)),
                );
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12.0),
                child: ListTile(
                  leading: MemberAvatar(member: member),
                  title: Row(
                    children: [
                      Expanded(child: Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                      if (statusBadge != null) statusBadge,
                    ],
                  ),
                  subtitle: Text('${member.mobile}\nJoined: ${AppDateUtils.formatDate(member.joiningDate)}'),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MemberDetailScreen(member: member),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddMemberScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Member'),
      ),
    );
  }
}
