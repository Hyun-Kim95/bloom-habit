import 'package:bloom_habit/l10n/app_localizations.dart';

import '../../data/local/entity/local_habit.dart';

enum _PraiseCategory {
  health,
  exercise,
  reading,
  learning,
  meditation,
  hobby,
  work,
  life,
  none,
}

/// 카테고리 문자열(한·영)을 내부 키로 정규화.
_PraiseCategory _categoryKey(String? raw) {
  if (raw == null) return _PraiseCategory.none;
  final s = raw.trim().toLowerCase();
  if (s.isEmpty) return _PraiseCategory.none;

  switch (s) {
    case '건강':
    case 'health':
    case 'wellness':
      return _PraiseCategory.health;
    case '운동':
    case 'exercise':
    case 'fitness':
    case 'workout':
      return _PraiseCategory.exercise;
    case '독서':
    case 'reading':
      return _PraiseCategory.reading;
    case '학습':
    case 'learning':
    case 'study':
      return _PraiseCategory.learning;
    case '명상':
    case 'meditation':
    case 'mindfulness':
      return _PraiseCategory.meditation;
    case '취미':
    case 'hobby':
    case 'hobbies':
      return _PraiseCategory.hobby;
    case '업무':
    case 'work':
    case 'business':
      return _PraiseCategory.work;
    case '생활':
    case 'life':
    case 'lifestyle':
    case 'daily':
      return _PraiseCategory.life;
    default:
      return _PraiseCategory.none;
  }
}

/// 습관 완료 직후 보여 줄 짧은 칭찬 문구 (카테고리 우선, 없으면 목표 유형).
String completionPraiseMessage(AppLocalizations l10n, LocalHabit habit) {
  switch (_categoryKey(habit.category)) {
    case _PraiseCategory.health:
      return l10n.completionPraiseCategoryHealth;
    case _PraiseCategory.exercise:
      return l10n.completionPraiseCategoryExercise;
    case _PraiseCategory.reading:
      return l10n.completionPraiseCategoryReading;
    case _PraiseCategory.learning:
      return l10n.completionPraiseCategoryLearning;
    case _PraiseCategory.meditation:
      return l10n.completionPraiseCategoryMeditation;
    case _PraiseCategory.hobby:
      return l10n.completionPraiseCategoryHobby;
    case _PraiseCategory.work:
      return l10n.completionPraiseCategoryWork;
    case _PraiseCategory.life:
      return l10n.completionPraiseCategoryLife;
    case _PraiseCategory.none:
      break;
  }

  final gt = (habit.goalType ?? 'completion').toLowerCase().trim();
  switch (gt) {
    case 'count':
      return l10n.completionPraiseGoalCount;
    case 'duration':
      return l10n.completionPraiseGoalDuration;
    case 'number':
      return l10n.completionPraiseGoalNumber;
    default:
      return l10n.completionPraiseGoalCompletion;
  }
}
