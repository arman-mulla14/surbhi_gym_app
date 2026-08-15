class GymSettings {
  final String gymName;
  final String ownerName;
  final String phone;
  final String address;
  final int defaultMembershipDuration;
  final double defaultFee;
  final bool dueSoonAlerts;
  final bool overdueAlerts;
  final bool isDarkMode;

  GymSettings({
    this.gymName = 'Surbhi Gym',
    this.ownerName = 'Admin',
    this.phone = '',
    this.address = '',
    this.defaultMembershipDuration = 30,
    this.defaultFee = 1000.0,
    this.dueSoonAlerts = true,
    this.overdueAlerts = true,
    this.isDarkMode = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': 1, // Single row
      'gymName': gymName,
      'ownerName': ownerName,
      'phone': phone,
      'address': address,
      'defaultMembershipDuration': defaultMembershipDuration,
      'defaultFee': defaultFee,
      'dueSoonAlerts': dueSoonAlerts ? 1 : 0,
      'overdueAlerts': overdueAlerts ? 1 : 0,
      'isDarkMode': isDarkMode ? 1 : 0,
    };
  }

  factory GymSettings.fromMap(Map<String, dynamic> map) {
    return GymSettings(
      gymName: map['gymName'] as String? ?? 'Surbhi Gym',
      ownerName: map['ownerName'] as String? ?? 'Admin',
      phone: map['phone'] as String? ?? '',
      address: map['address'] as String? ?? '',
      defaultMembershipDuration: map['defaultMembershipDuration'] as int? ?? 30,
      defaultFee: (map['defaultFee'] as num?)?.toDouble() ?? 1000.0,
      dueSoonAlerts: map['dueSoonAlerts'] == 1,
      overdueAlerts: map['overdueAlerts'] == 1,
      isDarkMode: map['isDarkMode'] == 1,
    );
  }

  GymSettings copyWith({
    String? gymName,
    String? ownerName,
    String? phone,
    String? address,
    int? defaultMembershipDuration,
    double? defaultFee,
    bool? dueSoonAlerts,
    bool? overdueAlerts,
    bool? isDarkMode,
  }) {
    return GymSettings(
      gymName: gymName ?? this.gymName,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      defaultMembershipDuration: defaultMembershipDuration ?? this.defaultMembershipDuration,
      defaultFee: defaultFee ?? this.defaultFee,
      dueSoonAlerts: dueSoonAlerts ?? this.dueSoonAlerts,
      overdueAlerts: overdueAlerts ?? this.overdueAlerts,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }
}
