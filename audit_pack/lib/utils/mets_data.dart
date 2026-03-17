// --- CLASE 1: NAF (NEAT) ACTUALIZADA ---
class NafRange {
  final String label;          // El título (ej. "Muy Sedentario")
  final String description;    // Tu descripción (ej. "Trabajo de escritorio...")
  final String context;        // El contexto científico (ej. "< 5,000 pasos")
  final List<double> factors;  // Tus factores (ej. [1.1, 1.2, 1.3])

  const NafRange({
    required this.label,
    required this.description,
    required this.context,
    required this.factors,
  });
}

// --- CLASE 2: EAT (ACTIVIDAD FÍSICA) ACTUALIZADA ---
class MetActivity {
  final String category;       // Ej: "Gimnasio"
  final String activityName;   // Ej: "Gimnasio Media Intensidad"
  final String userFeel;       // "Cómo se siente": "Rutina estándar de hipertrofia..."
  final String examples;       // "Ejemplos": "Rutina culturismo, superseries..."
  final List<double> metOptions; // ¡LA CLAVE! -> [5.0, 5.5, 6.0, 6.5, 7.0]

  const MetActivity({
    required this.category,
    required this.activityName,
    required this.userFeel,
    required this.examples,
    required this.metOptions,
  });
}


// --- BIBLIOTECA DE DATOS 1: NAF ---
// (Basado en tu imagen 'image_a53c46.png' y ajustado profesionalmente)
const List<NafRange> nafRanges = [
  NafRange(
    label: 'Muy Sedentario',
    description: 'Trabajo de escritorio, conduces a todos lados, pasas la mayor parte del día sentado.',
    context: 'Contexto: Generalmente < 5,000 pasos diarios.',
    factors: [1.1, 1.2, 1.3],
  ),
  NafRange(
    label: 'Poco Activo',
    description: 'Trabajo de escritorio, pero te mueves un poco, haces tareas domésticas ligeras.',
    context: 'Contexto: Aprox. 5,000 - 7,500 pasos diarios.',
    factors: [1.4, 1.5],
  ),
  NafRange(
    label: 'Activo',
    description: 'Tu trabajo implica estar de pie o caminar (profesor, vendedor) o eres una persona inquieta (alto NEAT).',
    context: 'Contexto: Aprox. 8,000 - 10,000 pasos diarios.',
    factors: [1.6, 1.7],
  ),
  NafRange(
    label: 'Muy Activo',
    description: 'Tu trabajo es físicamente demandante (construcción, agricultura, repartidor, mesero muy activo).',
    context: 'Contexto: > 12,000 pasos diarios, a menudo con carga.',
    factors: [1.8, 1.9],
  ),
];


// --- BIBLIOTECA DE DATOS 2: EAT (METs) ---
// (Fusión de tus dos imágenes de actividad 'image_a53be8.png' y 'image_a53bab.png')
const List<MetActivity> metLibrary = [
  // --- Gimnasio ---
  MetActivity(
    category: 'Gimnasio',
    activityName: 'Gimnasio Baja Intensidad',
    userFeel: 'Ideal para principiantes, calentamientos o recuperación. Peso ligero, descansos largos.',
    examples: 'Circuito de máquinas ligero, sentadillas sin peso, abdominales básicos.',
    metOptions: [2.5, 3.0, 3.5, 4.0, 4.5], // Rango de tus imágenes
  ),
  MetActivity(
    category: 'Gimnasio',
    activityName: 'Gimnasio Media Intensidad',
    userFeel: 'Rutina estándar de hipertrofia o resistencia. Pesos retadores, respiración agitada.',
    examples: 'Rutina culturismo, superseries, 8-12 reps.',
    metOptions: [5.0, 5.5, 6.0, 6.5, 7.0], // Rango de tus imágenes
  ),
  MetActivity(
    category: 'Gimnasio',
    activityName: 'Gimnasio Alta Intensidad',
    userFeel: 'Avanzados. Fuerza máxima o CrossFit. Pesos muy altos o descansos muy cortos.',
    examples: 'WOD CrossFit, levantamientos olímpicos, HIIT con pesas, drop sets.',
    metOptions: [7.5, 8.0, 8.5], // Rango de tus imágenes
  ),

  // --- Cardio ---
  MetActivity(
    category: 'Cardio',
    activityName: 'Cardio Baja Intensidad',
    userFeel: 'Puedes hablar sin problema. Esfuerzo suave y sostenible.',
    examples: 'Caminar rápido, bici recreativa en plano, elíptica suave.',
    metOptions: [3.0, 3.5, 4.0, 4.5], // Rango de tus imágenes
  ),
  MetActivity(
    category: 'Cardio',
    activityName: 'Cardio Media Intensidad',
    userFeel: 'Respiración acelerada, frases cortas. Sudor evidente. 30-60 min mantenibles.',
    examples: 'Jogging, spinning, subir escaleras a ritmo constante.',
    metOptions: [5.0, 5.5, 6.0, 6.5, 7.0, 7.5], // Rango de tus imágenes
  ),
  MetActivity(
    category: 'Cardio',
    activityName: 'Cardio Alta Intensidad',
    userFeel: 'No puedes hablar. Esfuerzo máximo, intervalos cortos, sensación de quedarse sin aire.',
    examples: 'Sprints, saltar cuerda rápido, burpees, intervals en bici/trotadora.',
    metOptions: [8.0, 9.0, 10.0], // Rango de tus imágenes
  ),

  // --- Deportes ---
  MetActivity(
    category: 'Deportes',
    activityName: 'Deporte Recreativo Baja',
    userFeel: 'Juego social, amistoso. Pausas frecuentes, esfuerzo bajo.',
    examples: 'Golf con carrito, voleibol playero casual, tenis en dobles.',
    metOptions: [3.0, 3.5, 4.0, 4.5], // Rango de tus imágenes
  ),
  MetActivity(
    category: 'Deportes',
    activityName: 'Deporte Amateur Media',
    userFeel: 'Movimiento constante, esfuerzo evidente, pero no competitivo al 100%.',
    examples: 'Cascarita de fútbol, básquet con amigos, pádel.',
    metOptions: [5.0, 5.5, 6.0, 6.5, 7.0, 7.5], // Rango de tus imágenes
  ),
  MetActivity(
    category: 'Deportes',
    activityName: 'Deporte Competitivo Alta',
    userFeel: 'Competición oficial. Sprints, saltos, cambios de dirección. Fatiga elevada.',
    examples: 'Fútbol oficial, básquet competitivo, squash, boxeo en ring.',
    metOptions: [8.0, 8.5, 9.0, 9.5, 10.0], // Rango de tus imágenes
  ),

  // --- Actividades Cotidianas ---
  MetActivity(
    category: 'Actividades Cotidianas',
    activityName: 'Cotidianas Baja',
    userFeel: 'Tareas diarias con mínimo esfuerzo.',
    examples: 'Cocinar, escritorio, lavar platos, doblar ropa.',
    metOptions: [1.5, 2.0, 2.5], // Rango de tus imágenes
  ),
  MetActivity(
    category: 'Actividades Cotidianas',
    activityName: 'Cotidianas Media',
    userFeel: 'Estar de pie, caminar o cargar objetos ligeros.',
    examples: 'Limpiar casa con energía, jardinería ligera, cargar bolsas, pasear perro.',
    metOptions: [3.0, 3.5, 4.0], // Rango de tus imágenes
  ),
  MetActivity(
    category: 'Actividades Cotidianas',
    activityName: 'Cotidianas Alta',
    userFeel: 'Esfuerzo físico notable, te deja cansado.',
    examples: 'Mudanza, palear tierra o nieve, carpintería pesada.',
    metOptions: [5.0, 6.0, 7.0], // Rango de tus imágenes
  ),
];