class FilterPreferences {
  int maxTuition = 100000;
  bool isPublic = true;
  bool isPrivate = true;
  double minAcceptanceRate = 0.0;
  String state = '';
  List<int> degreeTypes = [1, 2, 3];

  Map<String, dynamic> toMap() => {
    'maxNetCost': maxTuition,
    'isPublic': isPublic,
    'isPrivate': isPrivate,
    'minAcceptanceRate': minAcceptanceRate,
    'state': state,
    'degreeTypes': degreeTypes,
  };

  void updateFromMap(Map<String, dynamic> map) {
    maxTuition = (map['maxNetCost'] ?? 100000).toInt();
    isPublic = map['isPublic'] ?? true;
    isPrivate = map['isPrivate'] ?? true;
    minAcceptanceRate = (map['minAcceptanceRate'] ?? 0.0).toDouble();
    state = map['state'] ?? '';
    degreeTypes = List<int>.from(map['degreeTypes'] ?? [1, 2, 3]);
  }
}
