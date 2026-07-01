import 'package:flutter_riverpod/flutter_riverpod.dart';

class HistoryClinicViewModel {
  const HistoryClinicViewModel();
}

final historyClinicVmProvider = Provider.autoDispose<HistoryClinicViewModel>(
  (ref) => const HistoryClinicViewModel(),
);
