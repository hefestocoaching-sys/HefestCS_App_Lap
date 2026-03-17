import 'package:flutter/material.dart';
import 'package:hcs_app_lap/core/design/design_tokens.dart';
import 'package:hcs_app_lap/features/history_clinic_feature/widgets/clinic_section.dart';

/// EJEMPLO DE USO - ClinicSection Widget
/// Este archivo demuestra cómo usar el nuevo widget ClinicSection
/// en la pantalla de Historia Clínica
///
/// El widget es completamente modular y NO afecta la lógica existente

class ClinicSectionExample extends StatelessWidget {
  const ClinicSectionExample({super.key});

  @override
  Widget build(BuildContext context) {
    // ========== EJEMPLO 1: Sección de Alergias ==========
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.spaceLg),
      child: Column(
        spacing: DesignTokens.spaceLg,
        children: [
          // ALERGIAS
          ClinicSection(
            title: 'Alergias e Intolerancias',
            icon: Icons.warning_rounded,
            bgColor: DesignTokens.allergyBg,
            accentColor: Colors.orange,
            itemCount: 3,
            items: [
              ClinicSectionItem(
                title: 'Penicilina',
                subtitle: 'Reacción: Shock anafiláctico',
                indicatorColor: DesignTokens.getSeverityColor('CRÍTICA'),
                onTap: () {
                  // Editar alergia
                  debugPrint('Editar alergia: Penicilina');
                },
              ),
              ClinicSectionItem(
                title: 'Mariscos',
                subtitle: 'Reacción: Hinchazón de labios y garganta',
                indicatorColor: DesignTokens.getSeverityColor('SEVERA'),
              ),
              ClinicSectionItem(
                title: 'Látex',
                subtitle: 'Reacción: Urticaria',
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
            itemCount: 2,
            items: [
              ClinicSectionItem(
                title: 'Hipertensión Arterial',
                subtitle: 'Diagnosticada: 2019 | Medicada',
                indicatorColor: DesignTokens.getSeverityColor('SEVERA'),
              ),
              ClinicSectionItem(
                title: 'Diabetes Mellitus tipo 2',
                subtitle: 'Control metabólico: Adecuado',
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
            itemCount: 3,
            expandedByDefault: true,
            items: [
              ClinicSectionItem(
                title: 'Losartán',
                subtitle: '50mg - 1 vez al día',
                indicatorColor: Colors.green,
              ),
              ClinicSectionItem(
                title: 'Metformina',
                subtitle: '850mg - 2 veces al día',
                indicatorColor: Colors.green,
              ),
              ClinicSectionItem(
                title: 'Atorvastatina',
                subtitle: '20mg - 1 vez al día',
                indicatorColor: Colors.green,
              ),
            ],
          ),

          // ANTECEDENTES QUIRÚRGICOS
          const ClinicSection(
            title: 'Antecedentes Quirúrgicos',
            icon: Icons.healing,
            bgColor: DesignTokens.surgeryBg,
            accentColor: Colors.teal,
            itemCount: 1,
            items: [
              ClinicSectionItem(
                title: 'Apendicectomía',
                subtitle: 'Año: 2015 | Complicaciones: Ninguna',
                indicatorColor: Colors.grey,
              ),
            ],
          ),

          const SizedBox(height: DesignTokens.spaceLg),
        ],
      ),
    );
  }
}
