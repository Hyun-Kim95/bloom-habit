export declare class Habit {
    id: string;
    userId: string;
    name: string;
    category: string | null;
    goalType: string;
    goalValue: number | null;
    startDate: string;
    colorHex: string | null;
    iconName: string | null;
    archivedAt: Date | null;
    createdAt: Date;
    updatedAt: Date;
}
