class InterviewHelpContent {
  final String label;
  final String shortHelp;
  final String modalTitle;
  final String meaning;
  final String howToAnswer;
  final List<String> examples;
  final String volumeImpact;
  final String commonMistake;

  const InterviewHelpContent({
    required this.label,
    required this.shortHelp,
    required this.modalTitle,
    required this.meaning,
    required this.howToAnswer,
    required this.examples,
    required this.volumeImpact,
    required this.commonMistake,
  });
}

class InterviewHelpCatalog {
  InterviewHelpCatalog._();

  static const String trainingMonths = 'trainingMonths';
  static const String heightCm = 'heightCm';
  static const String weightKg = 'weightKg';
  static const String ageYears = 'ageYears';
  static const String strengthLevelClass = 'strengthLevelClass';
  static const String workCapacityScore = 'workCapacityScore';
  static const String recoveryHistoryScore = 'recoveryHistoryScore';
  static const String externalRecoverySupport = 'externalRecoverySupport';
  static const String programNoveltyClass = 'programNoveltyClass';
  static const String externalPhysicalStressLevel =
      'externalPhysicalStressLevel';
  static const String nonPhysicalStressLevel2 = 'nonPhysicalStressLevel2';
  static const String restQuality2 = 'restQuality2';
  static const String dietHabitsClass = 'dietHabitsClass';
  static const String usesAnabolics = 'usesAnabolics';
  static const String injuryRegion = 'injuryRegion';
  static const String injuryPattern = 'injuryPattern';
  static const String backFocus = 'backFocus';

  static const Map<String, InterviewHelpContent> byKey = {
    heightCm: InterviewHelpContent(
      label: 'Estatura',
      shortHelp: 'Ingresa la estatura actual del atleta en centímetros.',
      modalTitle: 'Estatura',
      meaning:
          'Sirve para contextualizar la antropometría general del asesorado.',
      howToAnswer:
          'Escribe la estatura actual, no una estimación antigua o una talla de referencia.',
      examples: [
        '172 cm medidos recientemente.',
        '180 cm como valor actual confirmado.',
      ],
      volumeImpact:
          'Forma parte del contexto antropométrico que ayuda a individualizar el volumen.',
      commonMistake:
          'Usar una altura estimada o desactualizada de forma automática.',
    ),
    weightKg: InterviewHelpContent(
      label: 'Peso actual',
      shortHelp: 'Ingresa el peso corporal actual en kilogramos.',
      modalTitle: 'Peso corporal actual',
      meaning:
          'Refleja el estado corporal actual y ayuda a contextualizar la tolerancia al volumen.',
      howToAnswer:
          'Usa el peso actual más representativo del momento presente.',
      examples: [
        '78.4 kg hoy por la mañana.',
        '91 kg en la fase actual del atleta.',
      ],
      volumeImpact:
          'El peso forma parte del ajuste global junto con otras variables de recuperación y carga.',
      commonMistake:
          'Registrar un peso de hace varias semanas que ya no representa el contexto real.',
    ),
    ageYears: InterviewHelpContent(
      label: 'Edad',
      shortHelp: 'Ingresa la edad actual del atleta en años.',
      modalTitle: 'Edad actual',
      meaning:
          'La edad ayuda a contextualizar recuperación, tolerancia al estrés y respuesta al volumen.',
      howToAnswer: 'Escribe la edad real al momento de la evaluación.',
      examples: ['22 años', '37 años'],
      volumeImpact:
          'La edad participa en el ajuste global del volumen mínimo y máximo recuperable.',
      commonMistake:
          'Usar una edad aproximada o redondeada cuando ya no es correcta.',
    ),
    trainingMonths: InterviewHelpContent(
      label: 'Tiempo entrenando',
      shortHelp:
          'Captura el tiempo real y consistente que llevas entrenando fuerza.',
      modalTitle: 'Tiempo entrenando consistentemente',
      meaning:
          'Indica cuánta experiencia continua tiene el atleta con entrenamiento de fuerza estructurado.',
      howToAnswer:
          'Usa el tiempo que realmente acumula con continuidad. Si hubo pausas largas o periodos sin entrenar, no los sumes como experiencia activa.',
      examples: [
        '8 meses entrenando sin interrupciones.',
        '2 años de fuerza con una práctica estable y regular.',
        '4 años totales pero con varios parones largos: captura solo la continuidad real.',
      ],
      volumeImpact:
          'Define el nivel detectado y la base global de volumen. Menos experiencia suele mover el rango inicial hacia abajo.',
      commonMistake:
          'Contar años totales de vida deportiva aunque no hayan sido de fuerza continua.',
    ),
    strengthLevelClass: InterviewHelpContent(
      label: 'Nivel de fuerza actual',
      shortHelp:
          'Selecciona la fuerza actual que mejor describa el rendimiento real del atleta.',
      modalTitle: 'Nivel de fuerza actual',
      meaning:
          'Resume qué tan fuerte es el atleta hoy respecto a la población con la que trabajas.',
      howToAnswer:
          'Elige la opción que mejor refleje su fuerza actual, no su potencial ni su mejor momento histórico.',
      examples: [
        'Baja: aún no mueve cargas relevantes o su fuerza relativa es claramente baja.',
        'Media: fuerza funcional para entrenar, sin destacar de forma clara.',
        'Alta: destaca frente a la media de su contexto.',
        'Muy alta: fuerza sobresaliente, cercana a nivel avanzado o competitivo.',
      ],
      volumeImpact:
          'A mayor fuerza actual, normalmente mayor capacidad para tolerar trabajo efectivo y progresar con más carga de volumen.',
      commonMistake:
          'Elegir la categoría por ego o por un levantamiento aislado en vez del perfil general.',
    ),
    workCapacityScore: InterviewHelpContent(
      label: 'Capacidad de trabajo',
      shortHelp:
          'Evalúa cuánto volumen total puede sostener con calidad durante una sesión o una semana.',
      modalTitle: 'Capacidad de trabajo',
      meaning:
          'Describe la capacidad de tolerar trabajo antes de que el rendimiento caiga de forma clara.',
      howToAnswer:
          '1 es muy poca tolerancia al volumen. 5 es alta tolerancia y buena estabilidad bajo carga acumulada.',
      examples: [
        '1: se fatiga rápido y cae el rendimiento con pocas series.',
        '3: tolera una dosis media de trabajo sin colapsar.',
        '5: sostiene bastante trabajo sin perder calidad técnica o rendimiento.',
      ],
      volumeImpact:
          'Modula el rango de volumen que el atleta puede absorber antes de que aparezca fatiga excesiva.',
      commonMistake:
          'Confundir capacidad de trabajo con ganas de entrenar o con resistencia cardiovascular general.',
    ),
    recoveryHistoryScore: InterviewHelpContent(
      label: 'Historial de recuperación',
      shortHelp:
          'Resume cómo suele recuperarse el atleta de forma sostenida en ciclos previos.',
      modalTitle: 'Historial de recuperación',
      meaning:
          'Mide el patrón real de recuperación que ha mostrado en el tiempo, no cómo se siente hoy por una semana aislada.',
      howToAnswer:
          '1 significa que suele recuperarse mal. 5 significa que históricamente recupera muy bien y estabiliza rápido.',
      examples: [
        '1: acumula fatiga y molestias con facilidad.',
        '3: recuperación promedio, sin sorpresas grandes.',
        '5: se adapta rápido, tolera bloques duros y suele volver fresco.',
      ],
      volumeImpact:
          'Ayuda a ajustar cuánta carga semanal puede sostener sin que el progreso se estanque.',
      commonMistake:
          'Basarse solo en el último entrenamiento o en una semana atípica.',
    ),
    externalRecoverySupport: InterviewHelpContent(
      label: 'Apoyo externo para recuperación',
      shortHelp:
          'Indica si el atleta cuenta con soporte real que mejore su recuperación.',
      modalTitle: 'Apoyo externo para la recuperación',
      meaning:
          'Refleja si existen recursos externos que ayuden a recuperar mejor entre sesiones.',
      howToAnswer:
          'Marca Sí si hay apoyo constante y útil. Marca No si no hay soporte relevante o es muy irregular.',
      examples: [
        'Sí: fisioterapia regular, masaje de recuperación, contexto laboral favorable, descanso estructurado.',
        'No: no existe apoyo externo consistente o no cambia de forma real la recuperación.',
      ],
      volumeImpact:
          'Un mejor soporte externo puede sostener una dosis de volumen algo mayor o más estable.',
      commonMistake:
          'Marcar Sí por tener una sesión ocasional de masaje o por una intención que no ocurre de forma real.',
    ),
    programNoveltyClass: InterviewHelpContent(
      label: 'Novedad del programa',
      shortHelp:
          'Mide qué tan nuevo será este programa respecto a lo que el atleta ya conoce.',
      modalTitle: 'Novedad del programa',
      meaning:
          'Cuanto más nuevo sea el programa, más adaptación necesita el atleta para manejarlo con seguridad y eficacia.',
      howToAnswer:
          'Nulo si casi replica lo que hace hoy. Alto si cambia bastante ejercicios, estructura o estímulo.',
      examples: [
        'Nulo: prácticamente el mismo esquema que ya domina.',
        'Bajo: algunos cambios, pero el patrón general es similar.',
        'Alto: nuevo reparto, nuevos estímulos y adaptación clara requerida.',
      ],
      volumeImpact:
          'Programas más nuevos suelen pedir más prudencia al inicio y menos agresividad en la dosis total.',
      commonMistake:
          'Confundir novedad con dificultad técnica aislada de un solo ejercicio.',
    ),
    externalPhysicalStressLevel: InterviewHelpContent(
      label: 'Desgaste físico externo',
      shortHelp: 'Evalúa la fatiga física que proviene de fuera del gimnasio.',
      modalTitle: 'Desgaste físico externo',
      meaning:
          'Considera trabajo físico, deporte adicional, muchas horas de pie, caminatas largas o carga física diaria.',
      howToAnswer:
          'Elige el nivel que represente la carga física real que acompaña al entrenamiento.',
      examples: [
        'Nulo: vida diaria poco exigente físicamente.',
        'Intermedio: varias horas activas o demandas físicas regulares.',
        'Alto: trabajo físico pesado o doble carga frecuente.',
      ],
      volumeImpact:
          'Más desgaste físico externo reduce la capacidad de absorber volumen de gimnasio sin acumular fatiga.',
      commonMistake:
          'Subestimar el trabajo físico diario solo porque no ocurre dentro del gimnasio.',
    ),
    nonPhysicalStressLevel2: InterviewHelpContent(
      label: 'Estrés no físico',
      shortHelp: 'Mide la carga mental y emocional de las últimas semanas.',
      modalTitle: 'Estrés no físico reciente',
      meaning:
          'Incluye trabajo mental, familia, estudio, presión personal, problemas económicos o estrés sostenido.',
      howToAnswer:
          'Bajo si el entorno es estable. Promedio si hay tensión constante tolerable. Alto si el estrés está claramente elevando la carga global.',
      examples: [
        'Bajo: semana tranquila y estable.',
        'Promedio: algunas obligaciones, pero manejables.',
        'Alto: mucha presión, sueño alterado o sensación de saturación frecuente.',
      ],
      volumeImpact:
          'El estrés mental alto reduce la recuperación global aunque el atleta no haga más trabajo físico.',
      commonMistake:
          'Responder por orgullo y no por la carga real de las últimas semanas.',
    ),
    restQuality2: InterviewHelpContent(
      label: 'Descanso y sueño',
      shortHelp: 'Valora qué tan reparador ha sido el descanso reciente.',
      modalTitle: 'Descanso y sueño recientes',
      meaning:
          'No se trata solo de horas dormidas. Importa la calidad real del sueño y si el atleta despierta recuperado.',
      howToAnswer:
          'Bajo si el descanso es malo o irregular. Promedio si cumple de forma aceptable. Alto si el sueño es consistente y restaurador.',
      examples: [
        'Bajo: despertares frecuentes, pocas horas o sueño poco reparador.',
        'Promedio: cumple, pero no destaca por calidad.',
        'Alto: duerme bien, se levanta funcional y con energía estable.',
      ],
      volumeImpact:
          'Un descanso mejor permite sostener más trabajo y recuperarse con menos coste adaptativo.',
      commonMistake:
          'Confundir cantidad de horas con calidad real del descanso.',
    ),
    dietHabitsClass: InterviewHelpContent(
      label: 'Estado energético',
      shortHelp:
          'Selecciona si el atleta está en superávit, mantenimiento o déficit.',
      modalTitle: 'Estado energético actual',
      meaning:
          'Describe el contexto energético actual de la dieta y su impacto sobre recuperación y rendimiento.',
      howToAnswer:
          'Elige la opción que mejor refleje la tendencia real de las últimas semanas, no una excepción puntual.',
      examples: [
        'Superávit alto: está comiendo claramente por encima de mantenimiento.',
        'Mantenimiento: entra y sale de mantenimiento sin un sesgo marcado.',
        'Déficit alto: restricción energética clara y sostenida.',
      ],
      volumeImpact:
          'El déficit sostenido suele bajar la tolerancia al volumen; el superávit puede sostener algo más de trabajo.',
      commonMistake:
          'Marcar mantenimiento cuando en realidad existe una fase de corte o ganancia muy clara.',
    ),
    usesAnabolics: InterviewHelpContent(
      label: 'Uso de anabólicos',
      shortHelp: 'Indica si existe uso actual de anabólicos.',
      modalTitle: 'Uso actual de anabólicos',
      meaning:
          'Es una variable de contexto que cambia la recuperación, la tolerancia al volumen y el coste de fatiga.',
      howToAnswer:
          'Marca Sí solo si existe uso actual. Si no existe, marca No.',
      examples: [
        'Sí: uso activo y actual.',
        'No: no hay uso actual, aunque haya habido en el pasado.',
      ],
      volumeImpact:
          'Puede elevar la tolerancia al volumen y la velocidad de recuperación, por lo que altera el rango recomendado.',
      commonMistake:
          'Responder según rumores, histórico lejano o intención futura.',
    ),
    injuryRegion: InterviewHelpContent(
      label: 'Región lesionada',
      shortHelp:
          'Marca una o más regiones que tengan molestia activa o historial relevante.',
      modalTitle: 'Región con molestia o lesión activa',
      meaning:
          'Sirve para registrar dónde aparece la molestia y condicionar la selección de patrones que más suelen molestar.',
      howToAnswer:
          'Selecciona solo las regiones que realmente deben considerarse en la programación actual.',
      examples: [
        'Hombro y muñeca si ambas zonas condicionan el entrenamiento.',
        'Rodilla si la molestia aparece sobre todo con sentadillas o zancadas.',
      ],
      volumeImpact:
          'Permite adaptar la selección de ejercicios y evitar agravar zonas sensibles.',
      commonMistake:
          'Marcar zonas por antecedente lejano que hoy no influyen en la programación.',
    ),
    injuryPattern: InterviewHelpContent(
      label: 'Patrón que molesta',
      shortHelp:
          'Selecciona el patrón que más suele provocar molestia en la región marcada.',
      modalTitle: 'Patrón principal que suele molestar',
      meaning:
          'Ayuda a identificar qué movimientos conviene vigilar o modular en el programa.',
      howToAnswer:
          'Elige el patrón que más consistentemente produce molestias, no el más dramático de una sola sesión.',
      examples: [
        'Hombro: empuje vertical si overhead press suele molestar.',
        'Rodilla: flexión profunda si las sentadillas profundas son el problema.',
        'Espalda baja: bisagra de cadera o carga axial si son los detonantes.',
      ],
      volumeImpact:
          'No cambia el volumen global por sí solo, pero sí condiciona qué ejercicios y rangos son más seguros.',
      commonMistake:
          'Elegir el patrón por el movimiento que más odio genera, no por el que realmente dispara el dolor.',
    ),
    backFocus: InterviewHelpContent(
      label: 'Enfoque de espalda',
      shortHelp:
          'Define si el énfasis de espalda irá más hacia dorsal o hacia espalda alta.',
      modalTitle: 'Enfoque de espalda',
      meaning:
          'Permite afinar la prioridad interna cuando la espalda forma parte de los músculos principales o secundarios.',
      howToAnswer:
          'Elige dorsal si el énfasis va más a ancho y tirón. Elige espalda alta si el foco va más a retracción y parte superior.',
      examples: [
        'Dorsal para un programa con más jalones y énfasis en amplitud.',
        'Espalda alta para un programa más orientado a remos y control escapular.',
      ],
      volumeImpact:
          'No cambia el volumen total por sí solo, pero sí la distribución del trabajo dentro de la espalda.',
      commonMistake:
          'Elegir el enfoque por gusto personal sin relación con el objetivo del bloque.',
    ),
  };
}
