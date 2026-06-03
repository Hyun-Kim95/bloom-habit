/// Goal-type helpers for daily success and record UX (client-side).
library;

String normalizeGoalType(String? raw) {
  switch ((raw ?? '').trim().toLowerCase()) {
    case 'count':
      return 'count';
    case 'duration':
      return 'duration';
    case 'number':
      return 'number';
    default:
      return 'completion';
  }
}

bool isNumberLteGoal({
  required String? goalType,
  String? numberDirection,
}) {
  return normalizeGoalType(goalType) == 'number' &&
      numberDirection == 'lte';
}

/// Whether the habit day counts as successful for UI/stats.
bool isDaySuccessful({
  required String? goalType,
  String? numberDirection,
  double? goalValue,
  double? dayValue,
  bool? recordCompleted,
}) {
  final type = normalizeGoalType(goalType);
  final value = dayValue ?? 0;

  if (type == 'completion') {
    return recordCompleted == true;
  }

  if (type == 'number' && numberDirection == 'lte') {
    if (goalValue != null && goalValue.isFinite) {
      return value <= goalValue;
    }
    return recordCompleted ?? value == 0;
  }

  if (recordCompleted == true) return true;
  if (goalValue != null && goalValue.isFinite) {
    return value >= goalValue;
  }
  return false;
}

/// Whether the user can tap record again after a "success" UI state.
bool canRecordAfterSuccess({
  required String? goalType,
  String? numberDirection,
  double? goalValue,
  double? dayValue,
  bool? recordCompleted,
}) {
  if (isNumberLteGoal(goalType: goalType, numberDirection: numberDirection)) {
    return true;
  }
  if (normalizeGoalType(goalType) == 'completion') {
    return !isDaySuccessful(
      goalType: goalType,
      numberDirection: numberDirection,
      goalValue: goalValue,
      dayValue: dayValue,
      recordCompleted: recordCompleted,
    );
  }
  return !isDaySuccessful(
    goalType: goalType,
    numberDirection: numberDirection,
    goalValue: goalValue,
    dayValue: dayValue,
    recordCompleted: recordCompleted,
  );
}

/// Progress label prefix for number lte (e.g. "<= " in EN).
String goalProgressPrefix({
  required String? goalType,
  String? numberDirection,
  required String languageCode,
}) {
  if (!isNumberLteGoal(goalType: goalType, numberDirection: numberDirection)) {
    return '';
  }
  return languageCode == 'en' ? '<= ' : '<= ';
}
