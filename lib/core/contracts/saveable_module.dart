abstract class SaveableModule {
  Future<void> saveIfDirty();
  void resetDrafts();
}
