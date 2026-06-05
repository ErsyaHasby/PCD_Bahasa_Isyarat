class FeatureSet {
  final List<double> landmarkVector;
  final List<double> geometricFeatures;
  final int handCount;
  final bool useZ;

  int get landmarkDim => useZ ? 126 : 84;

  FeatureSet({
    required this.landmarkVector,
    required this.geometricFeatures,
    required this.handCount,
    this.useZ = true,
  });

  List<double> get combined => [...landmarkVector, ...geometricFeatures];

  Map<String, dynamic> toMap() => {
        'landmark_vector': landmarkVector,
        'geometric_features': geometricFeatures,
        'hand_count': handCount,
        'use_z': useZ,
        'dim': landmarkDim,
      };
}
