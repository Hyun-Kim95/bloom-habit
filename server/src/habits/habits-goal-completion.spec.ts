import {
  computeGoalCompleted,
  isHabitMissedForReminder,
  mergeNumericRecordValue,
} from './habits-goal-completion';

describe('computeGoalCompleted', () => {
  it('lte number: 0 and under goal are completed', () => {
    expect(computeGoalCompleted('number', 0, 5, 'lte')).toBe(true);
    expect(computeGoalCompleted('number', 3, 5, 'lte')).toBe(true);
    expect(computeGoalCompleted('number', 5, 5, 'lte')).toBe(true);
  });

  it('lte number: over goal is not completed', () => {
    expect(computeGoalCompleted('number', 6, 5, 'lte')).toBe(false);
  });

  it('gte number: at or above goal is completed', () => {
    expect(computeGoalCompleted('number', 5, 5, 'gte')).toBe(true);
    expect(computeGoalCompleted('number', 4, 5, 'gte')).toBe(false);
  });

  it('count uses gte semantics', () => {
    expect(computeGoalCompleted('count', 3, 3, 'gte')).toBe(true);
    expect(computeGoalCompleted('count', 2, 3, 'gte')).toBe(false);
  });
});

describe('isHabitMissedForReminder', () => {
  const lteHabit = {
    goalType: 'number',
    numberDirection: 'lte',
    goalValue: 5,
  };

  it('lte number: no record is not missed (implicit 0)', () => {
    expect(isHabitMissedForReminder(lteHabit, undefined)).toBe(false);
    expect(isHabitMissedForReminder(lteHabit, null)).toBe(false);
  });

  it('lte number: over goal is not missed (failed, not incomplete)', () => {
    expect(
      isHabitMissedForReminder(lteHabit, { value: 6, completed: false }),
    ).toBe(false);
  });

  it('lte number: at or under goal is not missed', () => {
    expect(
      isHabitMissedForReminder(lteHabit, { value: 3, completed: true }),
    ).toBe(false);
  });

  it('gte count: no record is missed', () => {
    expect(
      isHabitMissedForReminder(
        { goalType: 'count', numberDirection: 'gte', goalValue: 3 },
        undefined,
      ),
    ).toBe(true);
  });

  it('gte count: incomplete record is missed', () => {
    expect(
      isHabitMissedForReminder(
        { goalType: 'count', numberDirection: 'gte', goalValue: 3 },
        { value: 1, completed: false },
      ),
    ).toBe(true);
  });

  it('gte count: completed record is not missed', () => {
    expect(
      isHabitMissedForReminder(
        { goalType: 'count', numberDirection: 'gte', goalValue: 3 },
        { value: 3, completed: true },
      ),
    ).toBe(false);
  });
});

describe('mergeNumericRecordValue', () => {
  it('accumulates from zero when no existing value', () => {
    expect(mergeNumericRecordValue(null, 3)).toBe(3);
  });

  it('adds step to previous total', () => {
    expect(mergeNumericRecordValue(3, 2)).toBe(5);
  });

  it('lte goal: crossing limit marks failure via computeGoalCompleted', () => {
    const next = mergeNumericRecordValue(3, 3);
    expect(next).toBe(6);
    expect(computeGoalCompleted('number', next, 5, 'lte')).toBe(false);
  });
});
