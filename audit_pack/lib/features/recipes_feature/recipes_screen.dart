import 'package:flutter/material.dart';
import 'package:hcs_app_lap/utils/theme.dart';

/// Pantalla de gestión de Recetas
///
/// Placeholder mínimo con estética existente.
/// Constructor y listado de recetas (en construcción).
class RecipesScreen extends StatelessWidget {
  const RecipesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Recetas'),
        backgroundColor: kAppBarColor,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado
              const Text(
                'Constructor de Recetas',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Crea y administra recetas para tus planes de alimentación',
                style: TextStyle(fontSize: 14, color: kTextColorSecondary),
              ),
              const SizedBox(height: 32),

              // Contenido placeholder
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: kCardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withAlpha(20),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.menu_book_outlined,
                      size: 64,
                      color: const Color(0xFFAB47BC).withAlpha(150),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Módulo de recetas en construcción',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kTextColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Aquí podrás crear recetas personalizadas, calcular macronutrientes automáticamente y asignarlas a planes de alimentación.',
                      style: TextStyle(
                        fontSize: 14,
                        color: kTextColorSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Volver al Inicio'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFAB47BC),
                        side: const BorderSide(color: Color(0xFFAB47BC)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
