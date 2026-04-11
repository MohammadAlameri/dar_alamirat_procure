class Branch {
  final String id;
  final String name;
  final String? nameAr;
  final String? code;
  final String? address;
  final String? phone;
  final bool isActive;

  Branch({
    required this.id,
    required this.name,
    this.nameAr,
    this.code,
    this.address,
    this.phone,
    this.isActive = true,
  });
}
