class MuscleTaxonomy {
  static const back = {'lats', 'upper_back', 'traps'};

  static const legs = {'quads', 'hamstrings', 'glutes', 'calves'};

  static const chest = {'chest'};

  static const shoulders = {
    'deltoide_anterior',
    'deltoide_lateral',
    'deltoide_posterior',
  };

  static const arms = {'biceps', 'triceps'};

  static const abs = {'abs'};

  static Set<String> expandGroup(String group) {
    switch (group) {
      case 'back':
        return back;
      case 'legs':
        return legs;
      case 'shoulders':
        return shoulders;
      case 'arms':
        return arms;
      case 'chest':
        return chest;
      case 'abs':
        return abs;
      default:
        return {};
    }
  }
}
