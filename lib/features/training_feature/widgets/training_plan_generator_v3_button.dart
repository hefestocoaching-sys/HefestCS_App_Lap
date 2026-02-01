import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/domain/entities/exercise.dart';
import 'package:hcs_app_lap/domain/training_v3/engine/training_program_engine_v3.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/features/training_feature/providers/training_engine_v3_provider.dart';
import 'package:hcs_app_lap/utils/theme.dart';

/// Botón para generar plan con Motor V3 (ML-Ready)
///
/// Muestra:
/// - Estrategia actual (Rules/Hybrid/ML)
/// - Loading state durante generación
/// - Success/Error feedback
/// - Link a mlExampleId para tracking
class TrainingPlanGeneratorV3Button extends ConsumerWidget {
  final VoidCallback? onPlanGenerated;
  final List<Exercise> exercises;

  const TrainingPlanGeneratorV3Button({
    super.key,
    this.onPlanGenerated,
    required this.exercises,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientAsync = ref.watch(clientsProvider);
    final generationState = ref.watch(trainingPlanGenerationProvider);
    final strategy = ref.watch(decisionStrategyProvider);

    return clientAsync.when(
      data: (clientsData) {
        final client = clientsData.activeClient;

        if (client == null) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info de estrategia
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kCardColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kPrimaryColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.psychology, color: kPrimaryColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Motor V3 (ML-Ready)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Estrategia: ${strategy.name}',
                          style: TextStyle(
                            fontSize: 11,
                            color: kTextColorSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (strategy.isTrainable)
                    Chip(
                      label: const Text('ML', style: TextStyle(fontSize: 10)),
                      backgroundColor: Colors.purple.withOpacity(0.3),
                      padding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Botón principal
            ElevatedButton.icon(
              onPressed: generationState.isLoading
                  ? null
                  : () => _onGeneratePlan(context, ref, client),
              icon: generationState.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(
                generationState.isLoading
                    ? 'Generando Plan V3...'
                    : 'Generar Plan con IA/Ciencia',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Feedback de resultado
            if (generationState.result != null) ...[
              const SizedBox(height: 12),
              _buildResultFeedback(context, generationState.result!),
            ],

            // Error message
            if (generationState.error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        generationState.error!,
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Text('Error: $error'),
    );
  }

  Future<void> _onGeneratePlan(
    BuildContext context,
    WidgetRef ref,
    client,
  ) async {
    if (exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Catálogo de ejercicios vacío'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Generar plan
    await ref
        .read(trainingPlanGenerationProvider.notifier)
        .generatePlan(
          client: client,
          exercises: exercises,
          asOfDate: DateTime.now(),
        );

    final result = ref.read(trainingPlanGenerationProvider).result;
    if (result == null) {
      return;
    }

    // ignore: use_build_context_synchronously
    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Plan generado exitosamente (${result.strategyUsed})',
          ),
          backgroundColor: Colors.green,
        ),
      );

      onPlanGenerated?.call();
    } else {
      // Plan bloqueado (ej: readiness crítico)
      // ignore: use_build_context_synchronously
      _showBlockedDialog(context, result);
    }
  }

  Widget _buildResultFeedback(
    BuildContext context,
    TrainingProgramV3Result result,
  ) {
    if (result.isBlocked) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.block, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Plan Bloqueado',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              result.blockedReason ?? 'Razón desconocida',
              style: TextStyle(fontSize: 12, color: kTextColorSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Recomendaciones:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: kTextColorSecondary,
              ),
            ),
            ...result.readinessDecision.recommendations.map(
              (rec) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 11)),
                    Expanded(
                      child: Text(
                        rec,
                        style: TextStyle(
                          fontSize: 11,
                          color: kTextColorSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Plan exitoso
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Plan Generado',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildDecisionSummary(result),
          if (result.mlExampleId != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.link, size: 14, color: kTextColorSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'ID ML: ${result.mlExampleId!.substring(0, 16)}...',
                    style: TextStyle(
                      fontSize: 10,
                      color: kTextColorSecondary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDecisionSummary(TrainingProgramV3Result result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Decisiones del Motor:',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: kTextColorSecondary,
          ),
        ),
        const SizedBox(height: 4),
        _buildDecisionRow(
          'Volumen',
          '${(result.volumeDecision.adjustmentFactor * 100).toStringAsFixed(0)}%',
          result.volumeDecision.adjustmentFactor,
        ),
        _buildDecisionRow(
          'Readiness',
          result.readinessDecision.level.name,
          result.readinessDecision.score,
        ),
        _buildDecisionRow(
          'Confianza',
          '${(result.volumeDecision.confidence * 100).toStringAsFixed(0)}%',
          result.volumeDecision.confidence,
        ),
      ],
    );
  }

  Widget _buildDecisionRow(String label, String value, double metric) {
    Color color = Colors.grey;
    if (metric > 0.8) {
      color = Colors.green;
    } else if (metric > 0.6) {
      color = Colors.blue;
    } else if (metric > 0.4) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 2),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 11, color: kTextColorSecondary),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showBlockedDialog(
    BuildContext context,
    TrainingProgramV3Result result,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.orange, size: 28),
            const SizedBox(width: 12),
            const Text('Plan Bloqueado'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.blockedReason ?? 'No se pudo generar el plan.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              'Recomendaciones:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            ...result.readinessDecision.recommendations.map(
              (rec) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(
                      child: Text(rec, style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📊 Métricas Actuales:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Readiness: ${(result.readinessDecision.score * 100).toStringAsFixed(0)}% (${result.readinessDecision.level.name})',
                    style: const TextStyle(fontSize: 11),
                  ),
                  Text(
                    'Fatiga: ${(result.features.fatigueIndex * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 11),
                  ),
                  Text(
                    'Riesgo Overreaching: ${(result.features.overreachingRisk * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navegar a TrainingEvaluationTab para ajustar datos
            },
            child: const Text('Ajustar Datos'),
          ),
        ],
      ),
    );
  }
}
