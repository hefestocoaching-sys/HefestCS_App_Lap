import 'package:flutter/material.dart';
import 'package:hcs_app_lap/core/design/design_tokens.dart';
import 'package:hcs_app_lap/features/history_clinic_feature/widgets/clinic_section.dart';

/// DEMOSTRACIÓN INTERACTIVA - ClinicSection en Historia Clínica
///
/// Esta pantalla muestra cómo se vería Historia Clínica rediseñada
/// con el nuevo Design System 2026 y ClinicSection widgets
class HistoryClinicDemoScreen extends StatefulWidget {
  const HistoryClinicDemoScreen({super.key});

  @override
  State<HistoryClinicDemoScreen> createState() =>
      _HistoryClinicDemoScreenState();
}

class _HistoryClinicDemoScreenState extends State<HistoryClinicDemoScreen> {
  bool _isCompactMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historia Clínica - UI/UX 2026'),
        elevation: 0,
        backgroundColor: DesignTokens.primaryBlue,
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Tooltip(
                message: _isCompactMode
                    ? 'Cambiar a Normal'
                    : 'Cambiar a Compacto',
                child: GestureDetector(
                  onTap: () => setState(() => _isCompactMode = !_isCompactMode),
                  child: Icon(
                    _isCompactMode ? Icons.unfold_more : Icons.unfold_less,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.spaceLg),
        child: Column(
          spacing: DesignTokens.spaceLg,
          children: [
            // HEADER
            Container(
              padding: const EdgeInsets.all(DesignTokens.spaceMd),
              decoration: BoxDecoration(
                color: DesignTokens.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                border: Border.all(
                  color: DesignTokens.primaryBlue.withValues(alpha: 0.3),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Historia Clínica Rediseñada', style: DesignTokens.h3),
                  SizedBox(height: DesignTokens.spaceSm),
                  Text(
                    'Versión moderna con secciones expandibles, animaciones suaves y color coding por severidad',
                    style: DesignTokens.caption,
                  ),
                ],
              ),
            ),

            // ALERGIAS
            ClinicSection(
              title: 'Alergias e Intolerancias',
              icon: Icons.warning_rounded,
              bgColor: DesignTokens.allergyBg,
              accentColor: Colors.orange,
              expandedByDefault: !_isCompactMode,
              itemCount: 3,
              items: [
                ClinicSectionItem(
                  title: 'Penicilina',
                  subtitle: 'Reacción: Shock anafiláctico | Severidad: CRÍTICA',
                  indicatorColor: DesignTokens.getSeverityColor('CRÍTICA'),
                ),
                ClinicSectionItem(
                  title: 'Mariscos',
                  subtitle:
                      'Reacción: Hinchazón de labios y garganta | Severidad: SEVERA',
                  indicatorColor: DesignTokens.getSeverityColor('SEVERA'),
                ),
                ClinicSectionItem(
                  title: 'Látex',
                  subtitle: 'Reacción: Urticaria | Severidad: MODERADA',
                  indicatorColor: DesignTokens.getSeverityColor('MODERADA'),
                ),
              ],
            ),

            // ENFERMEDADES CRÓNICAS
            ClinicSection(
              title: 'Enfermedades Crónicas',
              icon: Icons.local_hospital,
              bgColor: DesignTokens.diseaseBg,
              accentColor: Colors.blue,
              expandedByDefault: !_isCompactMode,
              itemCount: 2,
              items: [
                ClinicSectionItem(
                  title: 'Hipertensión Arterial',
                  subtitle: 'Diagnosticada: 2019 | Controlada con medicación',
                  indicatorColor: DesignTokens.getSeverityColor('SEVERA'),
                ),
                ClinicSectionItem(
                  title: 'Diabetes Mellitus Tipo 2',
                  subtitle:
                      'Control metabólico: Adecuado | Últimas mediciones normales',
                  indicatorColor: DesignTokens.getSeverityColor('SEVERA'),
                ),
              ],
            ),

            // MEDICAMENTOS
            const ClinicSection(
              title: 'Medicamentos Activos',
              icon: Icons.medication,
              bgColor: DesignTokens.medicationBg,
              accentColor: Colors.green,
              expandedByDefault: true,
              itemCount: 4,
              items: [
                ClinicSectionItem(
                  title: 'Losartán 50mg',
                  subtitle:
                      'Frecuencia: 1 vez al día | Indicación: Hipertensión',
                  indicatorColor: Colors.green,
                ),
                ClinicSectionItem(
                  title: 'Metformina 850mg',
                  subtitle: 'Frecuencia: 2 veces al día | Indicación: Diabetes',
                  indicatorColor: Colors.green,
                ),
                ClinicSectionItem(
                  title: 'Atorvastatina 20mg',
                  subtitle: 'Frecuencia: 1 vez al día | Indicación: Colesterol',
                  indicatorColor: Colors.green,
                ),
                ClinicSectionItem(
                  title: 'Aspirina 100mg',
                  subtitle:
                      'Frecuencia: 1 vez al día | Indicación: Cardioprotección',
                  indicatorColor: Colors.green,
                ),
              ],
            ),

            // ANTECEDENTES QUIRÚRGICOS
            ClinicSection(
              title: 'Antecedentes Quirúrgicos',
              icon: Icons.healing,
              bgColor: DesignTokens.surgeryBg,
              accentColor: Colors.teal,
              expandedByDefault: !_isCompactMode,
              itemCount: 2,
              items: const [
                ClinicSectionItem(
                  title: 'Apendicectomía',
                  subtitle:
                      'Año: 2015 | Complicaciones: Ninguna | Estado: Cicatrizado',
                  indicatorColor: Colors.grey,
                ),
                ClinicSectionItem(
                  title: 'Cirugía de Menisco (Rodilla Derecha)',
                  subtitle: 'Año: 2020 | Complicaciones: Leve rigidez residual',
                  indicatorColor: Colors.grey,
                ),
              ],
            ),

            // ANTECEDENTES FAMILIARES
            ClinicSection(
              title: 'Antecedentes Familiares',
              icon: Icons.family_restroom,
              bgColor: const Color(0xFFE1F5FE),
              accentColor: Colors.indigo,
              expandedByDefault: !_isCompactMode,
              itemCount: 3,
              items: const [
                ClinicSectionItem(
                  title: 'Padre - Infarto de Miocardio',
                  subtitle: 'Edad de presentación: 58 años',
                  indicatorColor: Colors.red,
                ),
                ClinicSectionItem(
                  title: 'Madre - Diabetes Mellitus',
                  subtitle: 'Edad de presentación: 62 años',
                  indicatorColor: Colors.orange,
                ),
                ClinicSectionItem(
                  title: 'Hermano - Hipertensión',
                  subtitle: 'Edad de presentación: 52 años',
                  indicatorColor: Colors.orange,
                ),
              ],
            ),

            // INFORMACIÓN ADICIONAL
            Container(
              padding: const EdgeInsets.all(DesignTokens.spaceMd),
              decoration: BoxDecoration(
                color: DesignTokens.elevation2,
                borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '✨ Características de este rediseño:',
                    style: DesignTokens.h4,
                  ),
                  const SizedBox(height: DesignTokens.spaceMd),
                  _buildFeatureRow(
                    '📱 Interface Limpia',
                    'Solo muestra lo esencial, usuario expande a demanda',
                  ),
                  _buildFeatureRow(
                    '🎨 Color Coding',
                    'Cada sección con color propio para identificación rápida',
                  ),
                  _buildFeatureRow(
                    '🔴 Indicadores de Severidad',
                    'Barras de color que indican crítico/severo/moderado/leve',
                  ),
                  _buildFeatureRow(
                    '✨ Animaciones Suaves',
                    'Transiciones fluidas al expandir/colapsar (300ms)',
                  ),
                  _buildFeatureRow(
                    '♿ Accesible',
                    'WCAG AA compliant, buen contraste y navegación clara',
                  ),
                  _buildFeatureRow(
                    '🔐 Sin Breaking Changes',
                    'Solo cambios visuales, funcionalidad 100% intacta',
                  ),
                ],
              ),
            ),

            const SizedBox(height: DesignTokens.spaceLg),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spaceMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: DesignTokens.labelLarge),
                const SizedBox(height: DesignTokens.spaceSm),
                Text(description, style: DesignTokens.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
