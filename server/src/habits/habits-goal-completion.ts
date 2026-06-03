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

type MissedReminderHabit = {
  goalType: string;
  numberDirection: string;
  goalValue: number | null;
};

type MissedReminderRecord = {
  value: number | null;
  completed: boolean;
};

/**
 * Whether a habit should appear in end-of-day "incomplete habit" reminders.
 * Number lte: no record (implicit 0) and over-limit failures are not "incomplete".
 */
export function isHabitMissedForReminder(
  habit: MissedReminderHabit,
  record: MissedReminderRecord | null | undefined,
): boolean {
  const goalType = (habit.goalType ?? 'completion').trim().toLowerCase() as GoalType;
  const numberDirection = (habit.numberDirection ?? 'gte').trim().toLowerCase() as NumberDirection;

  if (goalType === 'number' && numberDirection === 'lte') {
    if (!record) {
      if (habit.goalValue != null && Number.isFinite(Number(habit.goalValue))) {
        return false;
      }
      return true;
    }
    const value = Number(record.value ?? 0);
    if (
      habit.goalValue != null &&
      Number.isFinite(Number(habit.goalValue)) &&
      value > Number(habit.goalValue)
    ) {
      return false;
    }
    return !computeGoalCompleted(goalType, value, habit.goalValue, numberDirection);
  }

  if (record?.completed) return false;
  return true;
}
