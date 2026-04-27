String localizeHabitCategory(String value, String languageCode) {
  final trimmed = value.trim();
  if (trimmed.isEmpty || languageCode != 'en') return trimmed;
  return _categoryEnByKo[trimmed] ?? trimmed;
}

String localizeHabitUnit(String value, String languageCode) {
  final trimmed = value.trim();
  if (trimmed.isEmpty || languageCode != 'en') return trimmed;
  return _unitEnByKo[trimmed] ?? trimmed;
}

const Map<String, String> _categoryEnByKo = {
  '건강': 'Health',
  '운동': 'Exercise',
  '독서': 'Reading',
  '학습': 'Learning',
  '명상': 'Meditation',
  '취미': 'Hobby',
  '업무': 'Work',
  '생활': 'Life',
  '기타': 'Other',
};

const Map<String, String> _unitEnByKo = {
  '분': 'min',
  '시간': 'hour',
  '개': 'count',
  '걸음': 'steps',
  '점': 'points',
};
