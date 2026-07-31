/// A trainer / coach profile. In Phase 1 the trainer role reuses the same app
/// via role switching and gets a client roster.
class Trainer {
  const Trainer({
    required this.id,
    required this.fullName,
    required this.email,
    this.photoUrl,
    required this.certifications,
    required this.specialty,
    required this.bio,
    required this.clientIds,
    required this.avgResponseHours,
    required this.rating,
  });

  final String id;
  final String fullName;
  final String email;
  final String? photoUrl;
  final List<String> certifications;
  final String specialty;
  final String bio;
  final List<String> clientIds;
  final int avgResponseHours;
  final double rating;

  int get clientCount => clientIds.length;
}
