import 'package:flutter/material.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:url_launcher/url_launcher.dart';

/// Modal detallado que muestra cálculos científicos para un músculo específico
class MuscleDetailModal extends StatefulWidget {
  final String muscleName;
  final int vme;
  final int vmr;
  final int vma;
  final int target;
  final Map<String, dynamic>? calculations;
  final Function(int vme, int vmr, String reason)? onOverrideApplied;

  const MuscleDetailModal({
    super.key,
    required this.muscleName,
    required this.vme,
    required this.vmr,
    required this.vma,
    required this.target,
    this.calculations,
    this.onOverrideApplied,
  });

  @override
  State<MuscleDetailModal> createState() => _MuscleDetailModalState();
}

class _MuscleDetailModalState extends State<MuscleDetailModal> {
  bool _showOverride = false;
  late TextEditingController _vmeController;
  late TextEditingController _vmrController;
  late TextEditingController _reasonController;

  @override
  void initState() {
    super.initState();
    _vmeController = TextEditingController(text: widget.vme.toString());
    _vmrController = TextEditingController(text: widget.vmr.toString());
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _vmeController.dispose();
    _vmrController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Container(
        width: 800,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: kPrimaryColor.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: kPrimaryColor.withValues(alpha: 0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildVolumeVisualization(),
                    const SizedBox(height: 24),
                    _buildCalculationBreakdown(),
                    const SizedBox(height: 24),
                    _buildScientificEvidence(),
                    const SizedBox(height: 24),
                    if (widget.calculations?['alerts'] != null)
                      _buildAlertsAndRecommendations(),
                    if (widget.calculations?['alerts'] != null)
                      const SizedBox(height: 24),
                    _buildManualOverride(),
                  ],
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kPrimaryColor.withValues(alpha: 0.2),
            kPrimaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kPrimaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.analytics, color: kPrimaryColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatMuscleName(widget.muscleName),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: kTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Detalles Científicos de Volumen',
                  style: TextStyle(fontSize: 14, color: kTextColorSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: kTextColorSecondary),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Cerrar',
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeVisualization() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withValues(alpha: 0.1),
            Colors.purple.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎯 VOLUMEN CALCULADO',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kPrimaryColor,
            ),
          ),
          const SizedBox(height: 20),

          // Rango visual
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildVolumeCard('VME\nMínimo', widget.vme, Colors.orange),
              _buildVolumeCard('VMA\nÓptimo', widget.vma, Colors.green),
              _buildVolumeCard('VMR\nMáximo', widget.vmr, Colors.red),
            ],
          ),

          const SizedBox(height: 24),

          // Slider visual
          LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth - 32;
              final position = widget.vmr > widget.vme
                  ? ((widget.target - widget.vme) / (widget.vmr - widget.vme)) *
                        maxWidth
                  : 0.0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${widget.vme}',
                        style: const TextStyle(
                          color: kTextColorSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${widget.vma}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${widget.vmr}',
                        style: const TextStyle(
                          color: kTextColorSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Stack(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.withValues(alpha: 0.3),
                              Colors.green.withValues(alpha: 0.5),
                              Colors.red.withValues(alpha: 0.3),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: position.clamp(0.0, maxWidth),
                        top: -4,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: kPrimaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.arrow_upward,
                        size: 16,
                        color: kPrimaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Target: ${widget.target} series',
                        style: const TextStyle(
                          color: kPrimaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kAppBarColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: kPrimaryColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getVolumeStatusMessage(),
                    style: const TextStyle(color: kTextColor, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeCard(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'series',
            style: TextStyle(color: kTextColorSecondary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationBreakdown() {
    final adjustments =
        widget.calculations?['adjustments'] as Map<String, dynamic>? ?? {};

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kAppBarColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🧮 CÁLCULO DETALLADO',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),

          _buildFactorRow(
            'Base (Nivel de entrenamiento):',
            '+${adjustments['base'] ?? widget.vme} series',
            'Volumen base según años de experiencia y nivel actual',
            icon: Icons.person,
          ),

          if (adjustments.isNotEmpty) ...[
            if (adjustments['gender'] != null)
              _buildFactorRow(
                'Ajuste por género:',
                _formatAdjustment(adjustments['gender']),
                'Diferencias fisiológicas en recuperación (Mujeres +1.5 VME, +3.0 VMR)',
                icon: Icons.wc,
                color: (adjustments['gender'] as num) > 0 ? Colors.pink : null,
              ),
            if (adjustments['sleep'] != null)
              _buildFactorRow(
                'Ajuste por sueño:',
                _formatAdjustment(adjustments['sleep']),
                '⚠️ Bajo sueño aumenta VME (más estímulo) pero reduce VMR (peor recuperación)',
                icon: Icons.bedtime,
                color: (adjustments['sleep'] as num) > 0 ? Colors.orange : null,
                isWarning: (adjustments['sleep'] as num) > 0,
              ),
          ] else ...[
            _buildFactorRow(
              'Sistema de ajustes:',
              'Automático',
              'Motor V3 aplica 11 factores Israetel (género, edad, altura, peso, sueño, estrés, experiencia, etc.)',
              icon: Icons.auto_awesome,
            ),
          ],

          const Divider(height: 32, color: kPrimaryColor),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'VME Final:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
              ),
              Text(
                '${widget.vme} series',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFactorRow(
    String label,
    String value,
    String explanation, {
    IconData? icon,
    Color? color,
    bool isWarning = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: color ?? kTextColorSecondary),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: kTextColorSecondary, fontSize: 13),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isWarning ? Colors.orange : (color ?? kTextColor),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: explanation,
            preferBelow: false,
            child: Icon(
              Icons.info_outline,
              size: 16,
              color: kPrimaryColor.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScientificEvidence() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withValues(alpha: 0.05),
            Colors.purple.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.school, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                '📚 EVIDENCIA CIENTÍFICA',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildStudyReference(
            'Schoenfeld et al. (2017)',
            'Meta-análisis: Dose-response relationship between weekly set volume and muscle mass gain',
            'Conclusión: 10-20 sets/semana = rango óptimo para hipertrofia',
            'https://pubmed.ncbi.nlm.nih.gov/28834797/',
          ),

          const SizedBox(height: 12),

          _buildStudyReference(
            'Burd et al. (2010)',
            'Low-load high volume resistance exercise stimulates muscle protein synthesis',
            'Conclusión: 3 series > 1 serie (síntesis proteica sostenida)',
            'https://pubmed.ncbi.nlm.nih.gov/20847704/',
          ),

          const SizedBox(height: 12),

          _buildStudyReference(
            'Israetel (Renaissance Periodization)',
            'Volume Landmarks for Muscle Growth',
            'Sistema de individualización por 11+ factores (MEV/MAV/MRV)',
            null,
          ),

          const SizedBox(height: 12),

          _buildStudyReference(
            'Hanssen et al. (2013)',
            'Lower limbs show higher myogenic potential',
            'Conclusión: Piernas requieren +20% volumen vs tren superior',
            'https://pubmed.ncbi.nlm.nih.gov/23442269/',
          ),
        ],
      ),
    );
  }

  Widget _buildStudyReference(
    String author,
    String title,
    String conclusion,
    String? url,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kAppBarColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  author,
                  style: const TextStyle(
                    color: kPrimaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              if (url != null)
                InkWell(
                  onTap: () => _launchURL(url),
                  child: const Row(
                    children: [
                      Icon(Icons.open_in_new, size: 14, color: Colors.blue),
                      SizedBox(width: 4),
                      Text(
                        'Ver estudio',
                        style: TextStyle(color: Colors.blue, fontSize: 11),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: kTextColor,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            conclusion,
            style: const TextStyle(color: kTextColorSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsAndRecommendations() {
    final alerts = widget.calculations?['alerts'] as List? ?? [];

    if (alerts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text(
                '⚠️  ALERTAS Y RECOMENDACIONES',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ...alerts.map((alert) {
            final message = alert is Map
                ? (alert['message'] ?? alert.toString())
                : alert.toString();
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                message,
                style: const TextStyle(color: kTextColor, fontSize: 12),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildManualOverride() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kAppBarColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit, color: kPrimaryColor, size: 20),
              const SizedBox(width: 8),
              const Text(
                '🔧 AJUSTE MANUAL (OVERRIDE)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),
              const Spacer(),
              Switch(
                value: _showOverride,
                onChanged: (value) {
                  setState(() => _showOverride = value);
                },
                activeThumbColor: kPrimaryColor,
              ),
            ],
          ),

          if (_showOverride) ...[
            const SizedBox(height: 16),
            const Text(
              'Si deseas ignorar el cálculo automático y establecer valores personalizados:',
              style: TextStyle(color: kTextColorSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _vmeController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: kTextColor),
                    decoration: InputDecoration(
                      labelText: 'VME (series)',
                      labelStyle: const TextStyle(color: kTextColorSecondary),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: kPrimaryColor.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: kPrimaryColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _vmrController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: kTextColor),
                    decoration: InputDecoration(
                      labelText: 'VMR (series)',
                      labelStyle: const TextStyle(color: kTextColorSecondary),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: kPrimaryColor.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: kPrimaryColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _reasonController,
              maxLines: 2,
              style: const TextStyle(color: kTextColor),
              decoration: InputDecoration(
                labelText: 'Razón del override (opcional)',
                labelStyle: const TextStyle(color: kTextColorSecondary),
                hintText:
                    'Ej: Cliente tiene lesión en hombro, reducir volumen...',
                hintStyle: TextStyle(
                  color: kTextColorSecondary.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: kPrimaryColor.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: kPrimaryColor),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _vmeController.text = widget.vme.toString();
                      _vmrController.text = widget.vmr.toString();
                      _reasonController.clear();
                    });
                  },
                  child: const Text('Restaurar Automático'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _applyOverride,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: kTextColor,
                  ),
                  child: const Text('Aplicar Override'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kAppBarColor.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: kTextColor),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  // Helpers
  String _formatMuscleName(String muscle) {
    final names = {
      'chest': 'PECHO',
      'lats': 'DORSALES',
      'midBack': 'ESPALDA MEDIA',
      'lowBack': 'LUMBAR',
      'traps': 'TRAPECIOS',
      'frontDelts': 'HOMBRO FRONTAL',
      'sideDelts': 'HOMBRO LATERAL',
      'rearDelts': 'HOMBRO POSTERIOR',
      'biceps': 'BÍCEPS',
      'triceps': 'TRÍCEPS',
      'quads': 'CUÁDRICEPS',
      'hamstrings': 'ISQUIOSURALES',
      'glutes': 'GLÚTEOS',
      'calves': 'GEMELOS',
      'abs': 'ABDOMINALES',
    };
    return names[muscle.toLowerCase()] ?? muscle.toUpperCase();
  }

  String _formatAdjustment(dynamic value) {
    if (value is num) {
      return value >= 0
          ? '+${value.toStringAsFixed(1)}'
          : value.toStringAsFixed(1);
    }
    return value.toString();
  }

  String _getVolumeStatusMessage() {
    if (widget.target < widget.vme) {
      return '⚠️ Target está por debajo del VME. Progreso será mínimo.';
    } else if (widget.target >= widget.vme && widget.target < widget.vma) {
      return 'Target está entre VME y VMA. Progreso subóptimo, puede aumentar.';
    } else if (widget.target >= widget.vma && widget.target < widget.vmr) {
      return '✅ Target está en zona óptima (VMA). Máxima hipertrofia esperada.';
    } else {
      return '🔴 Target está cerca o sobre VMR. Riesgo de overreaching.';
    }
  }

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _applyOverride() {
    final vme = int.tryParse(_vmeController.text);
    final vmr = int.tryParse(_vmrController.text);

    if (vme == null || vmr == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa valores numéricos válidos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (vme >= vmr) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('VME debe ser menor que VMR'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (widget.onOverrideApplied != null) {
      widget.onOverrideApplied!(vme, vmr, _reasonController.text);
    }

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Override aplicado: VME=$vme, VMR=$vmr'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

/*
import 'package:flutter/material.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:url_launcher/url_launcher.dart';

/// Modal detallado que muestra cálculos científicos para un músculo específico
class MuscleDetailModal extends StatefulWidget {
  final String muscleName;
  final int vme;
  final int vmr;
  final int vma;
  final int target;
  final Map<String, dynamic>? calculations;
  final Function(int vme, int vmr, String reason)? onOverrideApplied;

  const MuscleDetailModal({
    super.key,
    required this.muscleName,
    required this.vme,
    required this.vmr,
    required this.vma,
    required this.target,
    this.calculations,
    this.onOverrideApplied,
  });

  @override
  State<MuscleDetailModal> createState() => _MuscleDetailModalState();
}

class _MuscleDetailModalState extends State<MuscleDetailModal> {
  bool _showOverride = false;
  late TextEditingController _vmeController;
  late TextEditingController _vmrController;
  late TextEditingController _reasonController;

  @override
  void initState() {
    super.initState();
    _vmeController = TextEditingController(text: widget.vme.toString());
    _vmrController = TextEditingController(text: widget.vmr.toString());
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _vmeController.dispose();
    _vmrController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Container(
        width: 800,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: kPrimaryColor.withValues(alpha: 0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: kPrimaryColor.withValues(alpha: 0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildVolumeVisualization(),
                    const SizedBox(height: 24),
                    _buildCalculationBreakdown(),
                    const SizedBox(height: 24),
                    _buildScientificEvidence(),
                    const SizedBox(height: 24),
                    if (widget.calculations?['alerts'] != null)
                      _buildAlertsAndRecommendations(),
                    if (widget.calculations?['alerts'] != null)
                      const SizedBox(height: 24),
                    _buildManualOverride(),
                  ],
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kPrimaryColor.withValues(alpha: 0.2),
            kPrimaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kPrimaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.analytics, color: kPrimaryColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatMuscleName(widget.muscleName),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: kTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Detalles Científicos de Volumen',
                  style: TextStyle(
                    fontSize: 14,
                    color: kTextColorSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: kTextColorSecondary),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Cerrar',
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeVisualization() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withValues(alpha: 0.1),
            Colors.purple.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎯 VOLUMEN CALCULADO',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kPrimaryColor,
            ),
          ),
          const SizedBox(height: 20),

          // Rango visual
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildVolumeCard('VME\nMínimo', widget.vme, Colors.orange),
              _buildVolumeCard('VMA\nÓptimo', widget.vma, Colors.green),
              _buildVolumeCard('VMR\nMáximo', widget.vmr, Colors.red),
            ],
          ),

          const SizedBox(height: 24),

          // Slider visual
          LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth - 32;
              final position = widget.vmr > widget.vme
                  ? ((widget.target - widget.vme) / (widget.vmr - widget.vme)) *
                      maxWidth
                  : 0.0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${widget.vme}',
                        style: const TextStyle(
                          color: kTextColorSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${widget.vma}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${widget.vmr}',
                        style: const TextStyle(
                          color: kTextColorSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Stack(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.withValues(alpha: 0.3),
                              Colors.green.withValues(alpha: 0.5),
                              Colors.red.withValues(alpha: 0.3),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: position.clamp(0.0, maxWidth),
                        top: -4,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: kPrimaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.arrow_upward,
                        size: 16,
                        color: kPrimaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Target: ${widget.target} series',
                        style: const TextStyle(
                          color: kPrimaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kAppBarColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: kPrimaryColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getVolumeStatusMessage(),
                    style: const TextStyle(color: kTextColor, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeCard(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'series',
            style: TextStyle(
              color: kTextColorSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationBreakdown() {
    final adjustments =
        widget.calculations?['adjustments'] as Map<String, dynamic>? ?? {};

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kAppBarColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🧮 CÁLCULO DETALLADO',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),

          _buildFactorRow(
            'Base (Nivel de entrenamiento):',
            '+${adjustments['base'] ?? widget.vme} series',
            'Volumen base según años de experiencia y nivel actual',
            icon: Icons.person,
          ),

          if (adjustments.isNotEmpty) ...[
            if (adjustments['gender'] != null)
              _buildFactorRow(
                'Ajuste por género:',
                _formatAdjustment(adjustments['gender']),
                'Diferencias fisiológicas en recuperación (Mujeres +1.5 VME, +3.0 VMR)',
                icon: Icons.wc,
                color: (adjustments['gender'] as num) > 0 ? Colors.pink : null,
              ),
            if (adjustments['sleep'] != null)
              _buildFactorRow(
                'Ajuste por sueño:',
                _formatAdjustment(adjustments['sleep']),
                '⚠️ Bajo sueño aumenta VME (más estímulo) pero reduce VMR (peor recuperación)',
                icon: Icons.bedtime,
                color: (adjustments['sleep'] as num) > 0 ? Colors.orange : null,
                isWarning: (adjustments['sleep'] as num) > 0,
              ),
          ] else ...[
            _buildFactorRow(
              'Sistema de ajustes:',
              'Automático',
              'Motor V3 aplica 11 factores Israetel (género, edad, altura, peso, sueño, estrés, experiencia, etc.)',
              icon: Icons.auto_awesome,
            ),
          ],

          const Divider(height: 32, color: kPrimaryColor),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'VME Final:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
              ),
              Text(
                '${widget.vme} series',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFactorRow(
    String label,
    String value,
    String explanation, {
    IconData? icon,
    Color? color,
    bool isWarning = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: color ?? kTextColorSecondary),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: kTextColorSecondary, fontSize: 13),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isWarning ? Colors.orange : (color ?? kTextColor),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: explanation,
            preferBelow: false,
            child: Icon(
              Icons.info_outline,
              size: 16,
              color: kPrimaryColor.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScientificEvidence() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withValues(alpha: 0.05),
            Colors.purple.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.school, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                '📚 EVIDENCIA CIENTÍFICA',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildStudyReference(
            'Schoenfeld et al. (2017)',
            'Meta-análisis: Dose-response relationship between weekly set volume and muscle mass gain',
            'Conclusión: 10-20 sets/semana = rango óptimo para hipertrofia',
            'https://pubmed.ncbi.nlm.nih.gov/28834797/',
          ),

          const SizedBox(height: 12),

          _buildStudyReference(
            'Burd et al. (2010)',
            'Low-load high volume resistance exercise stimulates muscle protein synthesis',
            'Conclusión: 3 series > 1 serie (síntesis proteica sostenida)',
            'https://pubmed.ncbi.nlm.nih.gov/20847704/',
          ),

          const SizedBox(height: 12),

          _buildStudyReference(
            'Israetel (Renaissance Periodization)',
            'Volume Landmarks for Muscle Growth',
            'Sistema de individualización por 11+ factores (MEV/MAV/MRV)',
            null,
          ),

          const SizedBox(height: 12),

          _buildStudyReference(
            'Hanssen et al. (2013)',
            'Lower limbs show higher myogenic potential',
            'Conclusión: Piernas requieren +20% volumen vs tren superior',
            'https://pubmed.ncbi.nlm.nih.gov/23442269/',
          ),
        ],
      ),
    );
  }

  Widget _buildStudyReference(
    String author,
    String title,
    String conclusion,
    String? url,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kAppBarColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  author,
                  style: const TextStyle(
                    color: kPrimaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              if (url != null)
                InkWell(
                  onTap: () => _launchURL(url),
                  child: const Row(
                    children: [
                      Icon(Icons.open_in_new, size: 14, color: Colors.blue),
                      SizedBox(width: 4),
                      Text(
                        'Ver estudio',
                        style: TextStyle(color: Colors.blue, fontSize: 11),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: kTextColor,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            conclusion,
            style: const TextStyle(
              color: kTextColorSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsAndRecommendations() {
    final alerts = widget.calculations?['alerts'] as List? ?? [];

    if (alerts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text(
                '⚠️  ALERTAS Y RECOMENDACIONES',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ...alerts.map((alert) {
            final message = alert is Map
                ? (alert['message'] ?? alert.toString())
                : alert.toString();
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                message,
                style: const TextStyle(color: kTextColor, fontSize: 12),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildManualOverride() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kAppBarColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit, color: kPrimaryColor, size: 20),
              const SizedBox(width: 8),
              const Text(
                '🔧 AJUSTE MANUAL (OVERRIDE)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),
              const Spacer(),
              Switch(
                value: _showOverride,
                onChanged: (value) {
                  setState(() => _showOverride = value);
                },
                activeColor: kPrimaryColor,
              ),
            ],
          ),

          if (_showOverride) ...[
            const SizedBox(height: 16),
            const Text(
              'Si deseas ignorar el cálculo automático y establecer valores personalizados:',
              style: TextStyle(color: kTextColorSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _vmeController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: kTextColor),
                    decoration: InputDecoration(
                      labelText: 'VME (series)',
                      labelStyle: const TextStyle(color: kTextColorSecondary),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: kPrimaryColor.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: kPrimaryColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _vmrController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: kTextColor),
                    decoration: InputDecoration(
                      labelText: 'VMR (series)',
                      labelStyle: const TextStyle(color: kTextColorSecondary),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: kPrimaryColor.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: kPrimaryColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _reasonController,
              maxLines: 2,
              style: const TextStyle(color: kTextColor),
              decoration: InputDecoration(
                labelText: 'Razón del override (opcional)',
                labelStyle: const TextStyle(color: kTextColorSecondary),
                hintText:
                    'Ej: Cliente tiene lesión en hombro, reducir volumen...',
                hintStyle: TextStyle(
                  color: kTextColorSecondary.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: kPrimaryColor.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: kPrimaryColor),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _vmeController.text = widget.vme.toString();
                      _vmrController.text = widget.vmr.toString();
                      _reasonController.clear();
                    });
                  },
                  child: const Text('Restaurar Automático'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _applyOverride,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: kTextColor,
                  ),
                  child: const Text('Aplicar Override'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kAppBarColor.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: kTextColor),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  // Helpers
  String _formatMuscleName(String muscle) {
    final names = {
      'chest': 'PECHO',
      'lats': 'DORSALES',
      'midBack': 'ESPALDA MEDIA',
      'lowBack': 'LUMBAR',
      'traps': 'TRAPECIOS',
      'frontDelts': 'HOMBRO FRONTAL',
      'sideDelts': 'HOMBRO LATERAL',
      'rearDelts': 'HOMBRO POSTERIOR',
      'biceps': 'BÍCEPS',
      'triceps': 'TRÍCEPS',
      'quads': 'CUÁDRICEPS',
      'hamstrings': 'ISQUIOSURALES',
      'glutes': 'GLÚTEOS',
      'calves': 'GEMELOS',
      'abs': 'ABDOMINALES',
    };
    return names[muscle.toLowerCase()] ?? muscle.toUpperCase();
  }

  String _formatAdjustment(dynamic value) {
    if (value is num) {
      return value >= 0
          ? '+${value.toStringAsFixed(1)}'
          : value.toStringAsFixed(1);
    }
    return value.toString();
  }

  String _getVolumeStatusMessage() {
    if (widget.target < widget.vme) {
      return '⚠️ Target está por debajo del VME. Progreso será mínimo.';
    } else if (widget.target >= widget.vme && widget.target < widget.vma) {
      return 'Target está entre VME y VMA. Progreso subóptimo, puede aumentar.';
    } else if (widget.target >= widget.vma && widget.target < widget.vmr) {
      return '✅ Target está en zona óptima (VMA). Máxima hipertrofia esperada.';
    } else {
      return '🔴 Target está cerca o sobre VMR. Riesgo de overreaching.';
    }
  }

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _applyOverride() {
    final vme = int.tryParse(_vmeController.text);
    final vmr = int.tryParse(_vmrController.text);

    if (vme == null || vmr == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa valores numéricos válidos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (vme >= vmr) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('VME debe ser menor que VMR'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (widget.onOverrideApplied != null) {
      widget.onOverrideApplied!(vme, vmr, _reasonController.text);
    }

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Override aplicado: VME=$vme, VMR=$vmr'),
        backgroundColor: Colors.green,
      ),
    );
  }
}import 'package:flutter/material.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:url_launcher/url_launcher.dart';

/// Modal detallado que muestra cálculos científicos para un músculo específico
class MuscleDetailModal extends StatefulWidget {
  final String muscleName;
  final Map<String, dynamic> calculations;
  final Map<String, dynamic> trainingExtra;

  const MuscleDetailModal({
    super.key,
    required this.muscleName,
    required this.calculations,
    required this.trainingExtra,
  });

  @override
  State<MuscleDetailModal> createState() => _MuscleDetailModalState();
}

class _MuscleDetailModalState extends State<MuscleDetailModal> {
  bool _showOverride = false;
  late TextEditingController _vmeController;
  late TextEditingController _vmrController;
  late TextEditingController _reasonController;

  @override
  void initState() {
    super.initState();
    _vmeController = TextEditingController(
      text: widget.calculations['vme']?.toString() ?? '',
    );
    _vmrController = TextEditingController(
      text: widget.calculations['vmr']?.toString() ?? '',
    );
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _vmeController.dispose();
    _vmrController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Container(
        width: 800,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: kPrimaryColor.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: kPrimaryColor.withValues(alpha: 0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildVolumeVisualization(),
                    const SizedBox(height: 24),
                    _buildCalculationBreakdown(),
                    const SizedBox(height: 24),
                    _buildScientificEvidence(),
                    const SizedBox(height: 24),
                    _buildAlertsAndRecommendations(),
                    const SizedBox(height: 24),
                    _buildManualOverride(),
                  ],
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kPrimaryColor.withValues(alpha: 0.2),
            kPrimaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kPrimaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.analytics, color: kPrimaryColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatMuscleName(widget.muscleName),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: kTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Detalles Científicos de Volumen',
                  style: TextStyle(fontSize: 14, color: kTextColorSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: kTextColorSecondary),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Cerrar',
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeVisualization() {
    final vme = widget.calculations['vme'] as int? ?? 0;
    final vma = widget.calculations['vma'] as int? ?? 0;
    final vmr = widget.calculations['vmr'] as int? ?? 0;
    final target = widget.calculations['target'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withValues(alpha: 0.1),
            Colors.purple.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎯 VOLUMEN CALCULADO',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kPrimaryColor,
            ),
          ),
          const SizedBox(height: 20),

          // Rango visual
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildVolumeCard('VME\nMínimo', vme, Colors.orange),
              _buildVolumeCard('VMA\nÓptimo', vma, Colors.green),
              _buildVolumeCard('VMR\nMáximo', vmr, Colors.red),
            ],
          ),

          const SizedBox(height: 24),

          // Slider visual
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$vme',
                    style: const TextStyle(
                      color: kTextColorSecondary,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '$vma',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$vmr',
                    style: const TextStyle(
                      color: kTextColorSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.withValues(alpha: 0.3),
                          Colors.green.withValues(alpha: 0.5),
                          Colors.red.withValues(alpha: 0.3),
                        ],
                      ),
                    ),
                  ),
                  if (vmr > vme)
                    Positioned(
                      left:
                          ((target - vme) / (vmr - vme)) *
                          MediaQuery.of(context).size.width *
                          0.6,
                      top: -4,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: kPrimaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.arrow_upward,
                    size: 16,
                    color: kPrimaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Target: $target series',
                    style: const TextStyle(
                      color: kPrimaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kAppBarColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: kPrimaryColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getVolumeStatusMessage(target, vme, vma, vmr),
                    style: const TextStyle(color: kTextColor, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeCard(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'series',
            style: TextStyle(color: kTextColorSecondary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationBreakdown() {
    final adjustments =
        widget.calculations['adjustments'] as Map<String, dynamic>? ?? {};
    final baseVME = widget.calculations['baseVME'] as int? ?? 6;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kAppBarColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🧮 CÁLCULO DETALLADO',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),

          _buildFactorRow(
            'Base (Nivel de entrenamiento):',
            '+$baseVME series',
            'Volumen base según años de experiencia y nivel actual',
            icon: Icons.person,
          ),

          if (adjustments['gender'] != null)
            _buildFactorRow(
              'Ajuste por género:',
              _formatAdjustment(adjustments['gender']),
              adjustments['genderReason'] ??
                  'Diferencias fisiológicas en recuperación',
              icon: Icons.wc,
              color: adjustments['gender'] > 0 ? Colors.pink : null,
            ),

          if (adjustments['age'] != null)
            _buildFactorRow(
              'Ajuste por edad:',
              _formatAdjustment(adjustments['age']),
              adjustments['ageReason'] ??
                  'Capacidad de recuperación según edad',
              icon: Icons.cake,
            ),

          if (adjustments['height'] != null)
            _buildFactorRow(
              'Ajuste por altura:',
              _formatAdjustment(adjustments['height']),
              adjustments['heightReason'] ?? 'Mayor/menor palanca muscular',
              icon: Icons.height,
            ),

          if (adjustments['weight'] != null)
            _buildFactorRow(
              'Ajuste por peso:',
              _formatAdjustment(adjustments['weight']),
              adjustments['weightReason'] ?? 'Masa muscular total disponible',
              icon: Icons.monitor_weight,
            ),

          if (adjustments['sleep'] != null)
            _buildFactorRow(
              'Ajuste por sueño:',
              _formatAdjustment(adjustments['sleep']),
              adjustments['sleepReason'] ?? '⚠️ Bajo sueño afecta recuperación',
              icon: Icons.bedtime,
              color: adjustments['sleep'] > 0 ? Colors.orange : null,
              isWarning: adjustments['sleep'] > 0,
            ),

          if (adjustments['stress'] != null)
            _buildFactorRow(
              'Ajuste por estrés:',
              _formatAdjustment(adjustments['stress']),
              adjustments['stressReason'] ??
                  'Cortisol elevado afecta anabolismo',
              icon: Icons.psychology,
              color: adjustments['stress'] > 0 ? Colors.orange : null,
              isWarning: adjustments['stress'] > 0,
            ),

          if (adjustments['strength'] != null)
            _buildFactorRow(
              'Ajuste por nivel de fuerza:',
              _formatAdjustment(adjustments['strength']),
              adjustments['strengthReason'] ??
                  'Mayor fuerza = mayor capacidad de volumen',
              icon: Icons.fitness_center,
            ),

          if (adjustments['workCapacity'] != null)
            _buildFactorRow(
              'Capacidad de trabajo:',
              _formatAdjustment(adjustments['workCapacity']),
              adjustments['workCapacityReason'] ??
                  'Tolerancia histórica al volumen',
              icon: Icons.trending_up,
            ),

          if (adjustments['recovery'] != null)
            _buildFactorRow(
              'Recuperación histórica:',
              _formatAdjustment(adjustments['recovery']),
              adjustments['recoveryReason'] ??
                  'Velocidad de recuperación observada',
              icon: Icons.restore,
            ),

          if (adjustments['nutrition'] != null)
            _buildFactorRow(
              'Estado nutricional:',
              _formatAdjustment(adjustments['nutrition']),
              adjustments['nutritionReason'] ??
                  'Déficit/superávit calórico actual',
              icon: Icons.restaurant,
            ),

          if (adjustments['anabolics'] != null)
            _buildFactorRow(
              'Uso de anabólicos:',
              _formatAdjustment(adjustments['anabolics']),
              'Mayor capacidad de síntesis proteica y recuperación',
              icon: Icons.medication,
              color: Colors.purple,
            ),

          if (adjustments['muscleMultiplier'] != null)
            _buildFactorRow(
              'Multiplicador de grupo muscular:',
              '×${adjustments['muscleMultiplier']}',
              adjustments['muscleMultiplierReason'] ??
                  'Ajuste específico según tipo de músculo',
              icon: Icons.pie_chart,
              color: kPrimaryColor,
            ),

          const Divider(height: 32, color: kPrimaryColor),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'VME Final:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
              ),
              Text(
                '${widget.calculations['vme']} series',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFactorRow(
    String label,
    String value,
    String explanation, {
    IconData? icon,
    Color? color,
    bool isWarning = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: color ?? kTextColorSecondary),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: kTextColorSecondary, fontSize: 13),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isWarning ? Colors.orange : (color ?? kTextColor),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: explanation,
            preferBelow: false,
            child: Icon(
              Icons.info_outline,
              size: 16,
              color: kPrimaryColor.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScientificEvidence() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withValues(alpha: 0.05),
            Colors.purple.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.school, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                '📚 EVIDENCIA CIENTÍFICA',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildStudyReference(
            'Schoenfeld et al. (2017)',
            'Meta-análisis: Dose-response relationship between weekly set volume and muscle mass gain',
            'Conclusión: 10-20 sets/semana = rango óptimo para hipertrofia',
            'https://pubmed.ncbi.nlm.nih.gov/28834797/',
          ),

          const SizedBox(height: 12),

          _buildStudyReference(
            'Burd et al. (2010)',
            'Low-load high volume resistance exercise stimulates muscle protein synthesis',
            'Conclusión: 3 series > 1 serie (síntesis proteica sostenida)',
            'https://pubmed.ncbi.nlm.nih.gov/20847704/',
          ),

          const SizedBox(height: 12),

          _buildStudyReference(
            'Israetel (Renaissance Periodization)',
            'Volume Landmarks for Muscle Growth',
            'Sistema de individualización por 11+ factores (MEV/MAV/MRV)',
            null,
          ),

          const SizedBox(height: 12),

          _buildStudyReference(
            'Hanssen et al. (2013)',
            'Lower limbs show higher myogenic potential',
            'Conclusión: Piernas requieren +20% volumen vs tren superior',
            'https://pubmed.ncbi.nlm.nih.gov/23442269/',
          ),
        ],
      ),
    );
  }

  Widget _buildStudyReference(
    String author,
    String title,
    String conclusion,
    String? url,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kAppBarColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  author,
                  style: const TextStyle(
                    color: kPrimaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              if (url != null)
                InkWell(
                  onTap: () => _launchURL(url),
                  child: const Row(
                    children: [
                      Icon(Icons.open_in_new, size: 14, color: Colors.blue),
                      SizedBox(width: 4),
                      Text(
                        'Ver estudio',
                        style: TextStyle(color: Colors.blue, fontSize: 11),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: kTextColor,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            conclusion,
            style: const TextStyle(color: kTextColorSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsAndRecommendations() {
    final alerts = widget.calculations['alerts'] as List? ?? [];

    if (alerts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text(
                '⚠️  ALERTAS Y RECOMENDACIONES',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ...alerts.map((alert) => _buildAlertItem(alert)),
        ],
      ),
    );
  }

  Widget _buildAlertItem(Map<String, dynamic> alert) {
    final type = alert['type'] as String? ?? 'warning';
    final message = alert['message'] as String? ?? '';
    final recommendation = alert['recommendation'] as String? ?? '';

    final color = type == 'critical' ? Colors.red : Colors.orange;
    final icon = type == 'critical' ? Icons.error : Icons.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    color: kTextColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                if (recommendation.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '→ $recommendation',
                    style: const TextStyle(
                      color: kTextColorSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualOverride() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kAppBarColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit, color: kPrimaryColor, size: 20),
              const SizedBox(width: 8),
              const Text(
                '🔧 AJUSTE MANUAL (OVERRIDE)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),
              const Spacer(),
              Switch(
                value: _showOverride,
                onChanged: (value) {
                  setState(() => _showOverride = value);
                },
                activeThumbColor: kPrimaryColor,
              ),
            ],
          ),

          if (_showOverride) ...[
            const SizedBox(height: 16),
            const Text(
              'Si deseas ignorar el cálculo automático y establecer valores personalizados:',
              style: TextStyle(color: kTextColorSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _vmeController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: kTextColor),
                    decoration: InputDecoration(
                      labelText: 'VME (series)',
                      labelStyle: const TextStyle(color: kTextColorSecondary),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: kPrimaryColor.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: kPrimaryColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _vmrController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: kTextColor),
                    decoration: InputDecoration(
                      labelText: 'VMR (series)',
                      labelStyle: const TextStyle(color: kTextColorSecondary),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: kPrimaryColor.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: kPrimaryColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _reasonController,
              maxLines: 2,
              style: const TextStyle(color: kTextColor),
              decoration: InputDecoration(
                labelText: 'Razón del override (opcional)',
                labelStyle: const TextStyle(color: kTextColorSecondary),
                hintText:
                    'Ej: Cliente tiene lesión en hombro, reducir volumen...',
                hintStyle: TextStyle(
                  color: kTextColorSecondary.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: kPrimaryColor.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: kPrimaryColor),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _vmeController.text =
                          widget.calculations['vme']?.toString() ?? '';
                      _vmrController.text =
                          widget.calculations['vmr']?.toString() ?? '';
                      _reasonController.clear();
                    });
                  },
                  child: const Text('Restaurar Automático'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _applyOverride,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: kTextColor,
                  ),
                  child: const Text('Aplicar Override'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kAppBarColor.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  // Helpers
  String _formatMuscleName(String muscle) {
    final names = {
      'chest': 'PECHO',
      'lats': 'DORSALES',
      'midBack': 'ESPALDA MEDIA',
      'lowBack': 'LUMBAR',
      'traps': 'TRAPECIOS',
      'frontDelts': 'HOMBRO FRONTAL',
      'sideDelts': 'HOMBRO LATERAL',
      'rearDelts': 'HOMBRO POSTERIOR',
      'biceps': 'BÍCEPS',
      'triceps': 'TRÍCEPS',
      'quads': 'CUÁDRICEPS',
      'hamstrings': 'ISQUIOSURALES',
      'glutes': 'GLÚTEOS',
      'calves': 'GEMELOS',
      'abs': 'ABDOMINALES',
    };
    return names[muscle] ?? muscle.toUpperCase();
  }

  String _formatAdjustment(dynamic value) {
    if (value is num) {
      return value >= 0
          ? '+${value.toStringAsFixed(1)}'
          : value.toStringAsFixed(1);
    }
    return value.toString();
  }

  String _getVolumeStatusMessage(int target, int vme, int vma, int vmr) {
    if (target < vme) {
      return 'Target está por debajo del VME. Progreso será mínimo.';
    } else if (target >= vme && target < vma) {
      return 'Target está entre VME y VMA. Progreso subóptimo, puede aumentar.';
    } else if (target >= vma && target < vmr) {
      return '✅ Target está en zona óptima (VMA). Máxima hipertrofia esperada.';
    } else {
      return '⚠️ Target está cerca o sobre VMR. Riesgo de overreaching.';
    }
  }

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _applyOverride() {
    final vme = int.tryParse(_vmeController.text);
    final vmr = int.tryParse(_vmrController.text);

    if (vme == null || vmr == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa valores numéricos válidos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (vme >= vmr) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('VME debe ser menor que VMR'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.of(context).pop({
      'muscle': widget.muscleName,
      'vme': vme,
      'vmr': vmr,
      'reason': _reasonController.text,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Override aplicado: VME=$vme, VMR=$vmr'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
*/
