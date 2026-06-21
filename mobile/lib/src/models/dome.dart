class Dome {
  final String id;
  final String name;
  final String shortDescription;
  final int maxCapacity;
  final bool isActive;

  const Dome({
    required this.id,
    required this.name,
    required this.shortDescription,
    required this.maxCapacity,
    required this.isActive,
  });

  factory Dome.fromJson(Map<String, dynamic> json) => Dome(
    id: json['id'] as String,
    name: json['name'] as String,
    shortDescription: (json['shortDescription'] as String?) ?? '',
    maxCapacity: json['maxCapacity'] as int,
    isActive: json['isActive'] as bool,
  );
}
