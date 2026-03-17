// lib/features/training_feature/screens/weekly_progression_demo_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/features/training_feature/providers/weekly_progression_provider.dart';
import 'package:hcs_app_lap/features/training_feature/providers/muscle_progression_tracker_provider.dart';
import 'package:hcs_app_lap/features/training_feature/widgets/weekly_feedback_form.dart';
import 'package:hcs_app_lap/features/training_feature/widgets/muscle_progression_card.dart';
import 'package:hcs_app_lap/features/training_feature/widgets/weekly_decision_summary.dart';
import 'package:hcs_app_lap/features/training_feature/widgets/phase_transition_indicator.dart';
import 'package:hcs_app_lap/domain/training_v3/models/exercise_log.dart';
import 'package:hcs_app_lap/domain/training_v3/models/set_log.dart';
import 'package:hcs_app_lap/utils/theme.dart';

/// Demo screen showcasing complete weekly progression workflow
///
/// FEATURES:
/// 1. Dashboard with all muscle trackers
/// 2. Weekly feedback forms
/// 3. Decision summary after submission
/// 4. Phase transition history
///
/// WORKFLOW:
/// Step 1: View current muscle status
/// Step 2: Fill weekly feedback
/// Step 3: Submit and get decisions
/// Step 4: Review decisions and apply
///
/// Version: 1.0.0
class WeeklyProgressionDemoScreen extends ConsumerStatefulWidget {
  const WeeklyProgressionDemoScreen({super.key});

  @override
  ConsumerState<WeeklyProgressionDemoScreen> createState() =>
      _WeeklyProgressionDemoScreenState();
}

class _WeeklyProgressionDemoScreenState
    extends ConsumerState<WeeklyProgressionDemoScreen> {
  int _currentStep = 0;
  final List<String> _targetMuscles = [
    'pectorals',
    'lats',
    'quadriceps',
    'hamstrings',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDemo();
    });
  }

  Future<void> _initializeDemo() async {
    final viewModel = ref.read(weeklyProgressionViewModelProvider);
    viewModel.initializeWeek(
      weekNumber: 1,
      weekStart: DateTime.now().subtract(const Duration(days: 7)),
      weekEnd: DateTime.now(),
    );

    _addDemoLogs();
  }

  void _addDemoLogs() {
    final viewModel = ref.read(weeklyProgressionViewModelProvider);

    final demoLogs = [
      ExerciseLog(
        id: 'demo_log_1',
        exerciseId: 'bench_press',
        exerciseName: 'Bench Press',
        plannedPrescriptionId: 'demo_bench_press',
        plannedSets: 4,
        sets: [
          _buildSet(1, 80, 10, 8.0),
          _buildSet(2, 80, 10, 8.5),
          _buildSet(3, 80, 9, 9.0),
          _buildSet(4, 80, 8, 9.0),
        ],
        plannedRir: 2,
        averageRpe: 8.6,
        completed: true,
      ),
      ExerciseLog(
        id: 'demo_log_2',
        exerciseId: 'lat_pulldown',
        exerciseName: 'Lat Pulldown',
        plannedPrescriptionId: 'demo_lat_pulldown',
        plannedSets: 4,
        sets: [
          _buildSet(1, 70, 12, 8.0),
          _buildSet(2, 70, 12, 8.5),
          _buildSet(3, 70, 11, 8.5),
          _buildSet(4, 70, 10, 9.0),
        ],
        plannedRir: 2,
        averageRpe: 8.5,
        completed: true,
      ),
      ExerciseLog(
        id: 'demo_log_3',
        exerciseId: 'squat',
        exerciseName: 'Squat',
        plannedPrescriptionId: 'demo_squat',
        plannedSets: 5,
        sets: [
          _buildSet(1, 100, 8, 8.5),
          _buildSet(2, 100, 8, 8.5),
          _buildSet(3, 100, 7, 9.0),
          _buildSet(4, 100, 7, 9.0),
          _buildSet(5, 100, 6, 9.5),
        ],
        plannedRir: 1,
        averageRpe: 9.0,
        completed: true,
      ),
      ExerciseLog(
        id: 'demo_log_4',
        exerciseId: 'leg_curl',
        exerciseName: 'Leg Curl',
        plannedPrescriptionId: 'demo_leg_curl',
        plannedSets: 4,
        sets: [
          _buildSet(1, 50, 12, 8.0),
          _buildSet(2, 50, 12, 8.0),
          _buildSet(3, 50, 11, 8.5),
          _buildSet(4, 50, 10, 9.0),
        ],
        plannedRir: 2,
        averageRpe: 8.4,
        completed: true,
      ),
    ];

    for (final log in demoLogs) {
      viewModel.addExerciseLog(log);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(weeklyProgressionViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Progression Demo'),
        backgroundColor: kPrimaryColor,
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: IndexedStack(
              index: _currentStep,
              children: [
                _buildStep1Dashboard(),
                _buildStep2FeedbackForms(),
                _buildStep3DecisionSummary(),
                _buildStep4History(),
              ],
            ),
          ),
          _buildNavigationButtons(viewModel),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: kAppBarColor,
      child: Row(
        children: [
          _buildStepIndicator(0, 'Dashboard', Icons.dashboard),
          _buildStepDivider(),
          _buildStepIndicator(1, 'Feedback', Icons.edit_note),
          _buildStepDivider(),
          _buildStepIndicator(2, 'Decisions', Icons.analytics),
          _buildStepDivider(),
          _buildStepIndicator(3, 'History', Icons.history),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, IconData icon) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isActive
                  ? kPrimaryColor
                  : isCompleted
                  ? Colors.green
                  : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check : icon,
              color: isActive || isCompleted ? Colors.white : Colors.grey[600],
              size: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isActive ? kPrimaryColor : Colors.grey[600],
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStepDivider() {
    return Container(
      width: 20,
      height: 2,
      color: Colors.grey[300],
      margin: const EdgeInsets.only(bottom: 20),
    );
  }

  Widget _buildStep1Dashboard() {
    final dashboardViewModel = ref.watch(
      muscleProgressionDashboardViewModelProvider,
    );

    return RefreshIndicator(
      onRefresh: () async {
        await dashboardViewModel.refresh();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Muscle Progression Dashboard',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Track your weekly volume progression for each muscle group',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          _buildDashboardStats(dashboardViewModel),
          const SizedBox(height: 24),
          if (dashboardViewModel.allTrackers != null) ...[
            for (final entry in dashboardViewModel.allTrackers!.entries)
              MuscleProgressionCard(
                muscle: entry.key,
                tracker: entry.value,
                onTap: () {
                  _showMuscleDetails(entry.key, entry.value);
                },
              ),
          ] else
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No trackers found. Initialize your program first.',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDashboardStats(dashboardViewModel) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Muscles',
            '${dashboardViewModel.totalMuscles}',
            Icons.fitness_center,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Weekly Volume',
            '${dashboardViewModel.totalWeeklyVolume}',
            Icons.bar_chart,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'With VMR',
            '${dashboardViewModel.musclesWithVMR}',
            Icons.flag,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showMuscleDetails(String muscle, tracker) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              Text(
                muscle.toUpperCase(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildDetailRow(
                'Current Volume',
                '${tracker.currentVolume} sets',
              ),
              _buildDetailRow('Current Phase', tracker.currentPhase.toString()),
              _buildDetailRow(
                'Weeks in Phase',
                '${tracker.weekInCurrentPhase + 1}',
              ),
              _buildDetailRow('Priority', '${tracker.priority}'),
              if (tracker.vmrDiscovered != null)
                _buildDetailRow('VMR', '${tracker.vmrDiscovered} sets'),
              const SizedBox(height: 24),
              const Text(
                'Landmarks',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildDetailRow('VME', '${tracker.landmarks.vme} sets'),
              _buildDetailRow('VOP', '${tracker.landmarks.vop} sets'),
              _buildDetailRow('MRV', '${tracker.landmarks.vmr} sets'),
              const SizedBox(height: 24),
              if (tracker.phaseTimeline.isNotEmpty) ...[
                const Text(
                  'Phase History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                PhaseTransitionIndicator(
                  transitions: tracker.phaseTimeline,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2FeedbackForms() {
    final viewModel = ref.watch(weeklyProgressionViewModelProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Weekly Feedback',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Provide feedback for each muscle group trained this week',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kPrimaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: kPrimaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Completed: ${viewModel.musclesWithFeedbackCount}/${_targetMuscles.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        for (final muscle in _targetMuscles)
          WeeklyFeedbackForm(
            muscle: muscle,
            initialFeedback: viewModel.getMuscleFeedback(muscle),
            onFeedbackChanged: (feedback) {
              viewModel.updateMuscleFeedback(muscle, feedback);
            },
          ),
      ],
    );
  }

  Widget _buildStep3DecisionSummary() {
    final viewModel = ref.watch(weeklyProgressionViewModelProvider);

    if (viewModel.decisions == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.pending_actions, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No decisions yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Submit your weekly feedback to get decisions',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        WeeklyDecisionSummary(
          decisions: viewModel.decisions!,
          weekNumber: viewModel.currentWeekNumber,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.green),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Decisions have been applied to your trackers. '
                  'Review the changes and continue to next week.',
                  style: TextStyle(color: Colors.grey[800]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep4History() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: kPrimaryColor),
            SizedBox(height: 16),
            Text(
              'History View',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'View your progression history across multiple weeks',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            Text(
              'This feature will show charts and timelines of your muscle progression.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(viewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentStep--;
                  });
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _currentStep == 3
                  ? null
                  : () async {
                      if (_currentStep == 1) {
                        final success = await viewModel
                            .submitWeeklyProgression();
                        if (success && mounted) {
                          setState(() {
                            _currentStep++;
                          });
                        } else if (!success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                viewModel.errorMessage ?? 'Failed to submit',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } else {
                        setState(() {
                          _currentStep++;
                        });
                      }
                    },
              icon: viewModel.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.arrow_forward),
              label: Text(_getNextButtonLabel()),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getNextButtonLabel() {
    switch (_currentStep) {
      case 0:
        return 'Fill Feedback';
      case 1:
        return 'Submit & Get Decisions';
      case 2:
        return 'View History';
      case 3:
        return 'Finish';
      default:
        return 'Next';
    }
  }
}

SetLog _buildSet(int number, double weight, int reps, double rpe) {
  return SetLog.fromRpe(
    setNumber: number,
    weight: weight,
    reps: reps,
    rpe: rpe,
    completedAt: DateTime.now(),
  );
}
