// lib/features/training_feature/viewmodels/weekly_progression_viewmodel.dart

import 'package:flutter/foundation.dart';
import 'package:hcs_app_lap/domain/training_v3/models/exercise_log.dart';
import 'package:hcs_app_lap/domain/training_v3/models/muscle_decision.dart';
import 'package:hcs_app_lap/domain/training_v3/services/weekly_progression_service.dart';

/// ViewModel for weekly progression workflow
///
/// RESPONSIBILITIES:
/// - Manage weekly feedback collection
/// - Submit feedback and get decisions
/// - Navigate through weekly progression steps
///
/// WORKFLOW:
/// 1. User completes training week
/// 2. User fills weekly feedback form (per muscle)
/// 3. ViewModel submits to WeeklyProgressionService
/// 4. ViewModel receives decisions for all muscles
/// 5. ViewModel displays decisions to user
///
/// Version: 1.0.0
class WeeklyProgressionViewModel extends ChangeNotifier {
  final WeeklyProgressionService _service;
  final String userId;

  WeeklyProgressionViewModel({
    required WeeklyProgressionService service,
    required this.userId,
  }) : _service = service;

  // ═══════════════════════════════════════════════════════════════
  // STATE
  // ═══════════════════════════════════════════════════════════════

  /// Current week number
  int _currentWeekNumber = 1;
  int get currentWeekNumber => _currentWeekNumber;

  /// Week date range
  DateTime? _weekStart;
  DateTime? _weekEnd;
  DateTime? get weekStart => _weekStart;
  DateTime? get weekEnd => _weekEnd;

  /// Exercise logs collected this week
  final List<ExerciseLog> _exerciseLogs = [];
  List<ExerciseLog> get exerciseLogs => List.unmodifiable(_exerciseLogs);

  /// Feedback by muscle
  final Map<String, Map<String, dynamic>> _feedbackByMuscle = {};
  Map<String, Map<String, dynamic>> get feedbackByMuscle =>
      Map.unmodifiable(_feedbackByMuscle);

  /// Decisions received from service
  Map<String, MuscleDecision>? _decisions;
  Map<String, MuscleDecision>? get decisions => _decisions;

  /// Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Error message
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Submission state
  bool _isSubmitted = false;
  bool get isSubmitted => _isSubmitted;

  // ═══════════════════════════════════════════════════════════════
  // PUBLIC METHODS
  // ═══════════════════════════════════════════════════════════════

  /// Initialize for a new week
  void initializeWeek({
    required int weekNumber,
    required DateTime weekStart,
    required DateTime weekEnd,
  }) {
    _currentWeekNumber = weekNumber;
    _weekStart = weekStart;
    _weekEnd = weekEnd;
    _exerciseLogs.clear();
    _feedbackByMuscle.clear();
    _decisions = null;
    _isSubmitted = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Add an exercise log
  void addExerciseLog(ExerciseLog log) {
    _exerciseLogs.add(log);
    notifyListeners();
  }

  /// Remove an exercise log
  void removeExerciseLog(String logId) {
    _exerciseLogs.removeWhere((log) => log.id == logId);
    notifyListeners();
  }

  /// Update feedback for a specific muscle
  void updateMuscleFeedback(String muscle, Map<String, dynamic> feedback) {
    _feedbackByMuscle[muscle] = feedback;
    notifyListeners();
  }

  /// Get feedback for a muscle
  Map<String, dynamic>? getMuscleFeedback(String muscle) {
    return _feedbackByMuscle[muscle];
  }

  /// Check if feedback is complete for all muscles
  bool isFeedbackComplete(List<String> requiredMuscles) {
    for (final muscle in requiredMuscles) {
      if (!_feedbackByMuscle.containsKey(muscle)) {
        return false;
      }
    }
    return true;
  }

  /// Submit weekly feedback and process progression
  Future<bool> submitWeeklyProgression() async {
    if (userId.isEmpty) {
      _errorMessage = 'User ID not available';
      notifyListeners();
      return false;
    }

    if (_weekStart == null || _weekEnd == null) {
      _errorMessage = 'Week dates not initialized';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('[WeeklyProgressionVM] Submitting week $_currentWeekNumber');
      debugPrint('[WeeklyProgressionVM] Logs: ${_exerciseLogs.length}');
      debugPrint(
        '[WeeklyProgressionVM] Feedback: ${_feedbackByMuscle.keys.length} muscles',
      );

      final decisions = await _service.processWeeklyProgression(
        userId: userId,
        weekNumber: _currentWeekNumber,
        weekStart: _weekStart!,
        weekEnd: _weekEnd!,
        exerciseLogs: _exerciseLogs,
        userFeedbackByMuscle: _feedbackByMuscle,
      );

      _decisions = decisions;
      _isSubmitted = true;
      _isLoading = false;

      debugPrint(
        '[WeeklyProgressionVM] Decisions received: ${decisions.length}',
      );
      notifyListeners();

      return true;
    } catch (e, stackTrace) {
      _errorMessage = 'Error processing weekly progression: $e';
      _isLoading = false;

      debugPrint('[WeeklyProgressionVM] Error: $e');
      debugPrint('[WeeklyProgressionVM] Stack: $stackTrace');

      notifyListeners();
      return false;
    }
  }

  /// Get decision for a specific muscle
  MuscleDecision? getDecisionForMuscle(String muscle) {
    return _decisions?[muscle];
  }

  /// Reset for next week
  void resetForNextWeek() {
    _currentWeekNumber++;
    _exerciseLogs.clear();
    _feedbackByMuscle.clear();
    _decisions = null;
    _isSubmitted = false;
    _errorMessage = null;
    _weekStart = null;
    _weekEnd = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // COMPUTED PROPERTIES
  // ═══════════════════════════════════════════════════════════════

  /// Total exercise logs count
  int get totalLogsCount => _exerciseLogs.length;

  /// Muscles with feedback count
  int get musclesWithFeedbackCount => _feedbackByMuscle.length;

  /// Has any data
  bool get hasData => _exerciseLogs.isNotEmpty || _feedbackByMuscle.isNotEmpty;

  /// Can submit (has minimum data)
  bool get canSubmit =>
      _exerciseLogs.isNotEmpty && !_isLoading && !_isSubmitted;
}
