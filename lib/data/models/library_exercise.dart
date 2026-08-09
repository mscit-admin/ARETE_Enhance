/// An exercise from the shared catalogue (GET /api/app/exercises).
class LibraryExercise {
  const LibraryExercise({
    required this.id,
    required this.name,
    this.nameAr = '',
    this.muscleGroup = '',
    this.category = '',
    this.level = '',
    this.equipment = '',
    this.targetMuscles = const [],
    this.videoUrl = '',
    this.imageUrl = '',
  });

  final String id;
  final String name;
  final String nameAr;
  final String muscleGroup;
  final String category; // 'gym' | 'calisthenics'
  final String level;
  final String equipment;
  final List<String> targetMuscles;
  final String videoUrl;
  final String imageUrl;

  /// Best display name for the given text direction.
  String label(bool arabic) => (arabic && nameAr.isNotEmpty) ? nameAr : name;

  factory LibraryExercise.fromJson(Map<String, dynamic> j) => LibraryExercise(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        nameAr: j['nameAr'] as String? ?? '',
        muscleGroup: j['muscleGroup'] as String? ?? '',
        category: j['category'] as String? ?? '',
        level: j['level'] as String? ?? '',
        equipment: j['equipment'] as String? ?? '',
        targetMuscles:
            (j['targetMuscles'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        videoUrl: j['videoUrl'] as String? ?? '',
        imageUrl: j['imageUrl'] as String? ?? '',
      );
}
