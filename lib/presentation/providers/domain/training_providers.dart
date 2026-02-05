// lib/presentation/providers/domain/training_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/domain/training_v3/services/motor_v3_orchestrator.dart';
import 'package:hcs_app_lap/domain/training_v3/models/user_profile.dart';

// ═══════════════════════════════════════════════════
// MOTOR V3 - PROVIDERS PRINCIPALES
// ═══════════════════════════════════════════════════

/// Motor V3 Orchestrator (científico puro)
final motorV3OrchestratorProvider = Provider<MotorV3Orchestrator>((ref) {
  return MotorV3Orchestrator();
});

// ═══════════════════════════════════════════════════
// GENERATION STATE
// ═══════════════════════════════════════════════════

/// Estados posibles de generación
class ProgramGenerationState {
  final bool isLoading;
  final Map<String, dynamic>? result;
  final String? error;

  const ProgramGenerationState({
    this.isLoading = false,
    this.result,
    this.error,
  });

  const ProgramGenerationState.idle() : this();
  const ProgramGenerationState.loading() : this(isLoading: true);
  ProgramGenerationState.success(Map<String, dynamic> result)
    : this(isLoading: false, result: result);
  ProgramGenerationState.error(String error)
    : this(isLoading: false, error: error);
}

/// StateNotifier para estado de generación
class ProgramGenerationNotifier extends Notifier<ProgramGenerationState> {
  @override
  ProgramGenerationState build() {
    return const ProgramGenerationState.idle();
  }

  void setLoading() {
    state = const ProgramGenerationState.loading();
  }

  void setSuccess(Map<String, dynamic> result) {
    state = ProgramGenerationState.success(result);
  }

  void setError(String error) {
    state = ProgramGenerationState.error(error);
  }

  void reset() {
    state = const ProgramGenerationState.idle();
  }
}

/// Provider para el estado de generación de programa
final programGenerationStateProvider =
    NotifierProvider<ProgramGenerationNotifier, ProgramGenerationState>(() {
      return ProgramGenerationNotifier();
    });

// ═══════════════════════════════════════════════════
// ACTIONS
// ═══════════════════════════════════════════════════

/// Genera un programa usando Motor V3
Future<void> generateProgramV3({
  required WidgetRef ref,
  required UserProfile userProfile,
  required String phase,
  required int durationWeeks,
}) async {
  // Set loading
  ref.read(programGenerationStateProvider.notifier).setLoading();

  try {
    // Usar orquestador científico puro (método estático)
    final result = await MotorV3Orchestrator.generateProgram(
      userProfile: userProfile,
      phase: phase,
      durationWeeks: durationWeeks,
    );

    // Set success
    ref.read(programGenerationStateProvider.notifier).setSuccess(result);
  } catch (e) {
    // Set error
    ref.read(programGenerationStateProvider.notifier).setError(e.toString());
  }
}
