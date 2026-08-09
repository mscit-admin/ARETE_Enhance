import 'package:flutter/foundation.dart';

import '../data/api/api_client.dart';
import '../data/models/library_exercise.dart';

/// Loads the shared exercise catalogue with optional filters. Backs the
/// exercise picker used when a coach builds a plan.
class ExerciseLibraryController extends ChangeNotifier {
  ExerciseLibraryController(this._client);

  final ApiClient _client;

  List<LibraryExercise> _items = [];
  bool _loading = false;
  String? _error;

  List<LibraryExercise> get items => _items;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load({String category = '', String query = ''}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    final params = <String>[];
    if (category.isNotEmpty) params.add('category=${Uri.encodeQueryComponent(category)}');
    if (query.isNotEmpty) params.add('query=${Uri.encodeQueryComponent(query)}');
    final qs = params.isEmpty ? '' : '?${params.join('&')}';
    try {
      final j = await _client.get('/api/app/exercises$qs') as Map<String, dynamic>;
      _items = (j['rows'] as List)
          .map((e) => LibraryExercise.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Failed to load exercises';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Create a custom exercise. Returns the created exercise, or null on error
  /// (the message is exposed via [error]).
  Future<LibraryExercise?> create({
    required String name,
    String nameAr = '',
    String muscleGroup = '',
    String category = '',
    String level = '',
    String equipment = '',
    bool shareWithTrainees = false,
  }) async {
    try {
      final j = await _client.post('/api/app/exercises', {
        'name': name,
        if (nameAr.isNotEmpty) 'nameAr': nameAr,
        if (muscleGroup.isNotEmpty) 'muscleGroup': muscleGroup,
        if (category.isNotEmpty) 'category': category,
        if (level.isNotEmpty) 'level': level,
        if (equipment.isNotEmpty) 'equipment': equipment,
        if (shareWithTrainees) 'visibility': 'coach_shared',
      }, auth: true) as Map<String, dynamic>;
      final ex = LibraryExercise.fromJson(j['exercise'] as Map<String, dynamic>);
      _items = [ex, ..._items];
      _error = null;
      notifyListeners();
      return ex;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }

  /// Delete one of the caller's own custom exercises.
  Future<String?> deleteExercise(String id) async {
    try {
      await _client.delete('/api/app/exercises/$id', auth: true);
      _items = _items.where((e) => e.id != id).toList();
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}
