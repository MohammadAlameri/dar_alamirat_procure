class AppConfig {
  final String? androidVersion;
  final String? iosVersion;
  final String? androidStoreUrl;
  final String? iosStoreUrl;
  final bool forceUpdate;
  final bool maintenanceMode;
  final String? maintenanceMessageAr;
  final String? maintenanceMessageEn;

  AppConfig({
    this.androidVersion,
    this.iosVersion,
    this.androidStoreUrl,
    this.iosStoreUrl,
    required this.forceUpdate,
    required this.maintenanceMode,
    this.maintenanceMessageAr,
    this.maintenanceMessageEn,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      androidVersion: json['android_version'],
      iosVersion: json['ios_version'],
      androidStoreUrl: json['android_store_url'],
      iosStoreUrl: json['ios_store_url'],
      forceUpdate: json['force_update'] ?? false,
      maintenanceMode: json['maintenance_mode'] ?? false,
      maintenanceMessageAr: json['maintenance_message_ar'],
      maintenanceMessageEn: json['maintenance_message_en'],
    );
  }
}
