// lib/features/training_feature/viewmodels/muscle_progression_dashboard_viewmodel.dart

import 'package:flutter/foundation.dart';
import 'package:hcs_app_lap/domain/training_v3/models/muscle_progression_tracker.dart';
import 'package:hcs_app_lap/domain/training_v3/repositories/muscle_progression_repository.dart';
import 'package:hcs_app_lap/domain/training_v3/services/weekly_progression_service.dart';

/// ViewModel for muscle progression dashboard
///
/// RESPONSIBILITIES:
/// - Display all muscle trackers
/// - Show progression summary
/// - Filter by phase/priority
/// - Export data
///
/// Version: 1.0.0
class MuscleProgressionDashboardViewModel extends ChangeNotifier {
  final WeeklyProgressionService _service;
  final MuscleProgressionRepository _repository;
  final String userId;

  MuscleProgressionDashboardViewModel({
    required WeeklyProgressionService service,
    required MuscleProgressionRepository repository,
    required this.userId,
  }) : _service = service,
       _repository = repository;

  // ═══════════════════════════════════════════════════════════════
  // STATE
  // ═══════════════════════════════════════════════════════════════

  /// All muscle trackers
  Map<String, MuscleProgressionTracker>? _allTrackers;
  Map<String, MuscleProgressionTracker>? get allTrackers => _allTrackers;

  /// Progression summary
  Map<String, dynamic>? _summary;
  Map<String, dynamic>? get summary => _summary;

  /// Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Error message
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Filter by phase
  ProgressionPhase? _filterPhase;
  ProgressionPhase? get filterPhase => _filterPhase;

  /// Filter by priority
  int? _filterPriority;
  int? get filterPriority => _filterPriority;

  /// Number of weeks to show in summary
  int _lastWeeks = 4;
  int get lastWeeks => _lastWeeks;

  // ═══════════════════════════════════════════════════════════════
  // PUBLIC METHODS
  // ═══════════════════════════════════════════════════════════════

  /// Load all data
  Future<void> loadData() async {
    if (userId.isEmpty) {
      _errorMessage = 'User ID not available';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Load trackers
      _allTrackers = await _repository.getAllTrackers(userId: userId);

      // Load summary
      _summary = await _service.getProgressionSummary(
        userId: userId,
        lastWeeks: _lastWeeks,
      );

      _isLoading = false;
      notifyListeners();

      debugPrint('[DashboardVM] Loaded ${_allTrackers?.length ?? 0} trackers');
    } catch (e, stackTrace) {
      _errorMessage = 'Error loading progression data: $e';
      _isLoading = false;

      debugPrint('[DashboardVM] Error: $e');
      debugPrint('[DashboardVM] Stack: $stackTrace');

      notifyListeners();
    }
  }

  /// Refresh data
  Future<void> refresh() => loadData();

  /// Set phase filter
  void setPhaseFilter(ProgressionPhase? phase) {
    _filterPhase = phase;
    notifyListeners();
  }

  /// Set priority filter
  void setPriorityFilter(int? priority) {
    _filterPriority = priority;
    notifyListeners();
  }

  /// Clear filters
  void clearFilters() {
    _filterPhase = null;
    _filterPriority = null;
    notifyListeners();
  }

  /// Set weeks to display
  void setLastWeeks(int weeks) {
    _lastWeeks = weeks;
    loadData();
  }

  /// Get filtered trackers
  Map<String, MuscleProgressionTracker> getFilteredTrackers() {
    if (_allTrackers == null) return {};

    Map<String, MuscleProgressionTracker> filtered = Map.from(_allTrackers!);

    // Filter by phase
    if (_filterPhase != null) {
      filtered.removeWhere(
        (muscle, tracker) => tracker.currentPhase != _filterPhase,
      );
    }

    // Filter by priority
    if (_filterPriority != null) {
      filtered.removeWhere(
        (muscle, tracker) => tracker.priority != _filterPriority,
      );
    }

    return filtered;
  }

  /// Get tracker for specific muscle
  MuscleProgressionTracker? getTrackerForMuscle(String muscle) {
    return _allTrackers?[muscle];
  }

  // ═══════════════════════════════════════════════════════════════
  // COMPUTED PROPERTIES
  // ═══════════════════════════════════════════════════════════════

  /// Total tracked muscles
  int get totalMuscles => _allTrackers?.length ?? 0;

  /// Muscles discovering
  int get musclesDiscovering {
    if (_allTrackers == null) return 0;
    return _allTrackers!.values
        .where((t) => t.currentPhase == ProgressionPhase.discovering)
        .length;
  }

  /// Muscles maintaining
  int get musclesMaintaining {
    if (_allTrackers == null) return 0;
    return _allTrackers!.values
        .where((t) => t.currentPhase == ProgressionPhase.maintaining)
        .length;
  }

  /// Muscles deloading
  int get musclesDeloading {
    if (_allTrackers == null) return 0;
    return _allTrackers!.values
        .where(
          (t) =>
              t.currentPhase == ProgressionPhase.deloading ||
              t.currentPhase == ProgressionPhase.microdeload,
        )
        .length;
  }

  /// Total weekly volume
  int get totalWeeklyVolume {
    if (_allTrackers == null) return 0;
    return _allTrackers!.values.fold(0, (sum, t) => sum + t.currentVolume);
  }

  /// Average volume per muscle
  double get averageVolumePerMuscle {
    if (_allTrackers == null || _allTrackers!.isEmpty) return 0;
    return totalWeeklyVolume / _allTrackers!.length;
  }

  /// Muscles with VMR discovered
  int get musclesWithVMR {
    if (_allTrackers == null) return 0;
    return _allTrackers!.values.where((t) => t.vmrDiscovered != null).length;
  }

  /// Has any filter active
  bool get hasActiveFilters => _filterPhase != null || _filterPriority != null;
}
