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
}
