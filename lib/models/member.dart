class Member {
  final String id; // e.g. SG001
  final String name;
  final String mobile;
  final String? parentMobile;
  final String address;
  final String? college;
  final String shift; // DAY or NIGHT
  final DateTime joiningDate;
  final int membershipDuration; // in days
  final double feeAmount; // Base fee
  final double totalBilled; // Cumulative billed amount
  final String? photoPath;

  Member({
    required this.id,
    required this.name,
    required this.mobile,
    this.parentMobile,
    required this.address,
    this.college,
    required this.shift,
    required this.joiningDate,
    required this.membershipDuration,
    required this.feeAmount,
    required this.totalBilled,
    this.photoPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'mobile': mobile,
      'parentMobile': parentMobile,
      'address': address,
      'college': college,
      'shift': shift,
      'joiningDate': joiningDate.toIso8601String(),
      'membershipDuration': membershipDuration,
      'feeAmount': feeAmount,
      'totalBilled': totalBilled,
      'photoPath': photoPath,
    };
  }

  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      id: map['id'] as String,
      name: map['name'] as String,
      mobile: map['mobile'] as String,
      parentMobile: map['parentMobile'] as String?,
      address: map['address'] as String,
      college: map['college'] as String?,
      shift: map['shift'] as String,
      joiningDate: DateTime.parse(map['joiningDate'] as String),
      membershipDuration: map['membershipDuration'] as int,
      feeAmount: (map['feeAmount'] as num).toDouble(),
      totalBilled: map['totalBilled'] != null ? (map['totalBilled'] as num).toDouble() : (map['feeAmount'] as num).toDouble(),
      photoPath: map['photoPath'] as String?,
    );
  }

  Member copyWith({
    String? id,
    String? name,
    String? mobile,
    String? parentMobile,
    String? address,
    String? college,
    String? shift,
    DateTime? joiningDate,
    int? membershipDuration,
    double? feeAmount,
    double? totalBilled,
    String? photoPath,
  }) {
    return Member(
      id: id ?? this.id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      parentMobile: parentMobile ?? this.parentMobile,
      address: address ?? this.address,
      college: college ?? this.college,
      shift: shift ?? this.shift,
      joiningDate: joiningDate ?? this.joiningDate,
      membershipDuration: membershipDuration ?? this.membershipDuration,
      feeAmount: feeAmount ?? this.feeAmount,
      totalBilled: totalBilled ?? this.totalBilled,
      photoPath: photoPath ?? this.photoPath,
    );
  }
}
