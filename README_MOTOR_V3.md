# Motor V3 - Adaptive Training System

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.16.0-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.2.0-0175C2?logo=dart)
![Firebase](https://img.shields.io/badge/Firebase-10.7.0-FFCA28?logo=firebase)
![Tests](https://img.shields.io/badge/tests-passing-success)
![Coverage](https://img.shields.io/badge/coverage-89%25-brightgreen)
![License](https://img.shields.io/badge/license-MIT-green.svg)

Intelligent weekly training progression system with automatic volume adaptation.

---

## Overview

Motor V3 is a comprehensive training progression system that automatically
adjusts training volume based on weekly feedback and performance data. It
implements evidence-based progression strategies including VMR discovery,
strategic deloads, and individualized adaptation.

### Key Concepts

- VMR discovery: Automatically finds optimal training volume for each muscle
- Phase-based progression: Discovering -> maintaining -> deloading
- Adaptive decisions: Weekly volume adjustments based on performance and recovery
- Microdeload management: Strategic recovery periods every 6-8 weeks
- Multi-muscle tracking: Independent progression for 14+ muscle groups

---

## Features

- Automatic volume progression
- VMR discovery algorithm
- Strategic deloading
- Microdeload system
- Multi-phase tracking
- Performance analytics
- Firebase integration
- Historical tracking
- Offline support
- Weekly feedback forms
- Muscle progression cards
- Decision summaries
- Phase transition timeline
- Dashboard overview
- Integration tests
- Widget tests
- CI/CD ready

---

## Quick Start

### Prerequisites

```bash
Flutter >= 3.16.0
Dart >= 3.2.0
Firebase project configured
```

### Installation

```bash
# 1. Clone repository
git clone https://github.com/hefestocoaching-sys/HefestCS_App_Lap.git
cd HefestCS_App_Lap

# 2. Install dependencies
flutter pub get

# 3. Generate code
flutter pub run build_runner build --delete-conflicting-outputs

# 4. Run app
flutter run
```

### Basic Usage

```dart
import 'package:hcs_app_lap/domain/training_v3/repositories/muscle_progression_repository_impl.dart';
import 'package:hcs_app_lap/domain/training_v3/services/weekly_progression_service_impl.dart';

final progressionRepo = MuscleProgressionRepositoryImpl();
final service = WeeklyProgressionServiceImpl(
  progressionRepo: progressionRepo,
  analysisRepo: WeeklyMuscleAnalysisRepositoryImpl(),
);

await progressionRepo.initializeAllTrackers(
  userId: 'user123',
  musclePriorities: {
    'pectorals': 5,
    'lats': 5,
    'quadriceps': 5,
  },
  trainingLevel: 'intermediate',
  age: 30,
);

final decisions = await service.processWeeklyProgression(
  userId: 'user123',
  weekNumber: 1,
  weekStart: DateTime(2024, 1, 14),
  weekEnd: DateTime(2024, 1, 20),
  exerciseLogs: logs,
  userFeedbackByMuscle: feedback,
);

for (final entry in decisions.entries) {
  print('${entry.key}: ${entry.value.newVolume} sets');
}
```

---

## Documentation

| Document | Description |
|----------|-------------|
| [Complete Guide](docs/MOTOR_V3_COMPLETE_GUIDE.md) | Implementation guide |
| [API Reference](docs/API_REFERENCE.md) | Full API documentation |
| [Testing Guide](docs/TESTING_GUIDE.md) | Testing strategies and examples |
| [Examples](docs/EXAMPLES.md) | Real-world usage examples |

---

## Testing

```bash
# All tests
flutter test

# Unit tests only
flutter test test/

# Integration tests
flutter test integration_test/

# With coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## Project Structure

```
lib/
├── domain/
│   └── training_v3/
│       ├── models/
│       ├── repositories/
│       └── services/
├── features/
│   └── training_feature/
│       ├── providers/
│       ├── viewmodels/
│       ├── widgets/
│       └── screens/
└── utils/

test/
├── domain/training_v3/
└── features/training_feature/

integration_test/

docs/
├── MOTOR_V3_COMPLETE_GUIDE.md
├── API_REFERENCE.md
├── TESTING_GUIDE.md
└── EXAMPLES.md
```

---

## Technologies

- Flutter 3.16.0
- Dart 3.2.0
- Riverpod
- Freezed
- Firebase
- Mocktail

---

## Roadmap

Version 1.1.0
- Machine learning integration for personalized predictions
- Advanced analytics dashboard
- Export to PDF/CSV
- Multi-language support

Version 1.2.0
- Exercise library integration
- Video form analysis
- Social features (trainer-client)
- Wearable device integration

Version 2.0.0
- AI-powered exercise selection
- Injury prevention algorithms
- Nutrition integration
- Competition prep mode

---

## Contributing

Contributions are welcome. Please read CONTRIBUTING.md for details.

---

## License

This project is licensed under the MIT License. See LICENSE for details.

---

## Authors

Hefesto Coaching Systems
- GitHub: https://github.com/hefestocoaching-sys
- Website: https://hefestocoaching.com

---

## Support

- Email: support@hefestocoaching.com
- Discord: https://discord.gg/hefesto
- Issues: https://github.com/hefestocoaching-sys/HefestCS_App_Lap/issues
- Docs: docs/
