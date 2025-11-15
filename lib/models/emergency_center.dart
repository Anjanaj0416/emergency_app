class EmergencyCenter {
  final String id;
  final String name;
  final String phone;
  final double lat;
  final double lng;
  final String? googleLink;

  EmergencyCenter({
    required this.id,
    required this.name,
    required this.phone,
    required this.lat,
    required this.lng,
    this.googleLink,
  });

  factory EmergencyCenter.fromJson(Map<String, dynamic> json) {
    return EmergencyCenter(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? json['stationName'] ?? json['centerName'] ?? '',
      phone: json['phone'] ?? '',
      lat: (json['lat'] ?? 0.0).toDouble(),
      lng: (json['lng'] ?? 0.0).toDouble(),
      googleLink: json['googleLink'] ?? json['googleMapsLink'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'lat': lat,
      'lng': lng,
      'googleLink': googleLink,
    };
  }
}
