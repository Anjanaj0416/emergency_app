enum EmergencyType {
  ambulance,
  police,
  fire,
}

extension EmergencyTypeExtension on EmergencyType {
  String get value {
    switch (this) {
      case EmergencyType.ambulance:
        return 'ambulance';
      case EmergencyType.police:
        return 'police';
      case EmergencyType.fire:
        return 'fire';
    }
  }

  String get displayName {
    switch (this) {
      case EmergencyType.ambulance:
        return 'Ambulance';
      case EmergencyType.police:
        return 'Police';
      case EmergencyType.fire:
        return 'Fire Department';
    }
  }
}
