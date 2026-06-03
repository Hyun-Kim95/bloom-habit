export type GoalType = 'completion' | 'count' | 'duration' | 'number';
export type NumberDirection = 'gte' | 'lte';

/** Daily value-based completion (number lte: start at 0 = success until value exceeds goal). */
export function computeGoalCompleted(
  goalType: GoalType,
  value: number,
  goalValue?: number | null,
  numberDirection: NumberDirection = 'gte',
): boolean {
  if (goalType === 'completion') return true;
  if (goalValue == null || !Number.isFinite(Number(goalValue))) {
    return value > 0;
  }
  const goal = Number(goalValue);
  if (goalType === 'number' && numberDirection === 'lte') {
    return value <= goal;
  }
  return value >= goal;
}

export function mergeNumericRecordValue(
  existingValue: number | null,
  incomingValue?: number,
): number {
  const step = Number.isFinite(Number(incomingValue)) ? Number(incomingValue) : 1;
  const prev = Number.isFinite(Number(existingValue)) ? Number(existingValue) : 0;
  return prev + step;
}
