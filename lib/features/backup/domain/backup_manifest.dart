import 'dart:convert';

class BackupManifest {
  final String appName;
  final int schemaVersion;
  final DateTime createdAt;
  final int vehicleCount;
  final int fuelEntryCount;
  final int serviceEntryCount;
  final int expenseCount;
  final int documentCount;
  final String appVersion;

  const BackupManifest({
    this.appName = 'Fuel and Service Log',
    this.schemaVersion = 1,
    required this.createdAt,
    this.vehicleCount = 0,
    this.fuelEntryCount = 0,
    this.serviceEntryCount = 0,
    this.expenseCount = 0,
    this.documentCount = 0,
    this.appVersion = '1.0.0',
  });

  Map<String, dynamic> toMap() {
    return {
      'appName': appName,
      'schemaVersion': schemaVersion,
      'createdAt': createdAt.toIso8601String(),
      'vehicleCount': vehicleCount,
      'fuelEntryCount': fuelEntryCount,
      'serviceEntryCount': serviceEntryCount,
      'expenseCount': expenseCount,
      'documentCount': documentCount,
      'appVersion': appVersion,
    };
  }

  String toJson() => jsonEncode(toMap());

  factory BackupManifest.fromMap(Map<String, dynamic> map) {
    return BackupManifest(
      appName: map['appName'] as String? ?? 'Fuel and Service Log',
      schemaVersion: (map['schemaVersion'] as num?)?.toInt() ?? 1,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      vehicleCount: (map['vehicleCount'] as num?)?.toInt() ?? 0,
      fuelEntryCount: (map['fuelEntryCount'] as num?)?.toInt() ?? 0,
      serviceEntryCount: (map['serviceEntryCount'] as num?)?.toInt() ?? 0,
      expenseCount: (map['expenseCount'] as num?)?.toInt() ?? 0,
      documentCount: (map['documentCount'] as num?)?.toInt() ?? 0,
      appVersion: map['appVersion'] as String? ?? '1.0.0',
    );
  }

  factory BackupManifest.fromJson(String source) =>
      BackupManifest.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
