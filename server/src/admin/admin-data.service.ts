import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, IsNull, Repository } from 'typeorm';
import { v4 as uuidv4 } from 'uuid';
import {
  Habit as HabitEntity,
  HabitRecord as HabitRecordEntity,
  HabitTemplate as HabitTemplateEntity,
  Inquiry as InquiryEntity,
  LegalDocument as LegalDocumentEntity,
  Notice as NoticeEntity,
  SystemConfig as SystemConfigEntity,
  User as UserEntity,
} from '../entities';
import type { LegalDocumentType } from '../entities/legal-document.entity';
import {
  DEFAULT_HABIT_TEMPLATES,
  reseedCategoryEn,
  reseedTemplateNameEn,
} from '../config/default-habit-templates';
import { PushService } from '../push/push.service';

export interface InquiryAdminDto {
  id: string;
  userId: string;
  userEmail: string | null;
  userDisplayName: string | null;
  subject: string;
  body: string;
  status: string;
  adminReply: string | null;
  repliedAt: string | null;
  userReadAt: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface HabitTemplateDto {
  id: string;
  name: string;
  nameEn?: string;
  category?: string;
  categoryEn?: string;
  goalType: string;
  numberDirection: 'gte' | 'lte';
  unit?: string;
  goalValue?: number | null;
  colorHex?: string;
  iconName?: string;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface NoticeDto {
  id: string;
  title: string;
  body: string;
  titleEn?: string;
  bodyEn?: string;
  publishedAt?: string;
  isNotice?: boolean;
  isPublic?: boolean;
  displayStartAt?: string;
  displayEndAt?: string;
  createdAt: string;
  updatedAt: string;
}

export interface LegalDocumentDto {
  id: string;
  type: LegalDocumentType;
  locale: string;
  version: number;
  title: string;
  content: string;
  effectiveFrom: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface AdminUserProgressSummaryDto {
  from: string;
  to: string;
  totalHabits: number;
  trackedHabitCount: number;
  totalRecords: number;
  completedRecords: number;
  completionRatePercent: number | null;
}

export interface AdminUserHabitProgressItemDto {
  id: string;
  name: string;
  category: string | null;
  goalType: string;
  numberDirection: 'gte' | 'lte';
  unit: string | null;
  goalValue: number | null;
  today: {
    hasRecord: boolean;
    value: number | null;
    completed: boolean;
  };
  summary30d: {
    totalRecords: number;
    completedRecords: number;
    completionRatePercent: number | null;
    latestValue: number | null;
  };
}

export interface AdminUserDetailDto {
  user: {
    id: string;
    email: string | null;
    authProvider: 'google' | 'apple' | 'kakao' | 'naver' | 'unknown';
    displayName: string | null;
    createdAt: string;
    isActive: boolean;
    deactivatedAt: string | null;
    deactivationReason: string | null;
    deactivatedBy: 'self' | 'admin' | null;
  };
  summary30d: AdminUserProgressSummaryDto;
  todaySummary: {
    date: string;
    totalHabits: number;
    recordedHabits: number;
    completedHabits: number;
    completionRatePercent: number | null;
  };
  habits: AdminUserHabitProgressItemDto[];
}

@Injectable()
export class AdminDataService {
  constructor(
    @InjectRepository(HabitTemplateEntity)
    private readonly templateRepo: Repository<HabitTemplateEntity>,
    @InjectRepository(HabitEntity)
    private readonly habitRepo: Repository<HabitEntity>,
    @InjectRepository(HabitRecordEntity)
    private readonly habitRecordRepo: Repository<HabitRecordEntity>,
    @InjectRepository(NoticeEntity)
    private readonly noticeRepo: Repository<NoticeEntity>,
    @InjectRepository(SystemConfigEntity)
    private readonly configRepo: Repository<SystemConfigEntity>,
    @InjectRepository(InquiryEntity)
    private readonly inquiryRepo: Repository<InquiryEntity>,
    @InjectRepository(UserEntity)
    private readonly userRepo: Repository<UserEntity>,
    @InjectRepository(LegalDocumentEntity)
    private readonly legalRepo: Repository<LegalDocumentEntity>,
    private readonly pushService: PushService,
  ) {}

  private dateKey(date: Date): string {
    return date.toISOString().slice(0, 10);
  }

  async getUserDetail(userId: string): Promise<AdminUserDetailDto | null> {
    const user = await this.userRepo.findOne({ where: { id: userId } });
    if (!user) return null;

    const habits = await this.habitRepo
      .createQueryBuilder('h')
      .where('h.userId = :userId', { userId })
      .andWhere('h.archivedAt IS NULL')
      .orderBy('h.createdAt', 'ASC')
      .getMany();
    const habitIds = habits.map((h) => h.id);
    const today = this.dateKey(new Date());
    const fromDate = new Date();
    fromDate.setDate(fromDate.getDate() - 29);
    const from = this.dateKey(fromDate);

    const records = habitIds.length
      ? await this.habitRecordRepo
          .createQueryBuilder('r')
          .where('r.habitId IN (:...habitIds)', { habitIds })
          .andWhere('r.recordDate BETWEEN :from AND :to', { from, to: today })
          .orderBy('r.recordDate', 'DESC')
          .addOrderBy('r.updatedAt', 'DESC')
          .getMany()
      : [];

    const todayByHabit = new Map<string, HabitRecordEntity>();
    const recordsByHabit = new Map<string, HabitRecordEntity[]>();
    for (const record of records) {
      const list = recordsByHabit.get(record.habitId) ?? [];
      list.push(record);
      recordsByHabit.set(record.habitId, list);
      if (record.recordDate === today && !todayByHabit.has(record.habitId)) {
        todayByHabit.set(record.habitId, record);
      }
    }

    let summaryTotalRecords = 0;
    let summaryCompletedRecords = 0;
    let trackedHabitCount = 0;
    let todayRecordedHabits = 0;
    let todayCompletedHabits = 0;

    const habitItems: AdminUserHabitProgressItemDto[] = habits.map((habit) => {
      const habitRecords = recordsByHabit.get(habit.id) ?? [];
      const totalRecords = habitRecords.length;
      const completedRecords = habitRecords.filter((r) => r.completed).length;
      const latestValue = habitRecords.length > 0 ? (habitRecords[0].value ?? null) : null;
      const todayRecord = todayByHabit.get(habit.id);
      const todayHasRecord = Boolean(todayRecord);
      const todayCompleted = todayRecord?.completed === true;
      const todayValue = todayRecord?.value ?? null;

      summaryTotalRecords += totalRecords;
      summaryCompletedRecords += completedRecords;
      if (totalRecords > 0) trackedHabitCount += 1;
      if (todayHasRecord) todayRecordedHabits += 1;
      if (todayCompleted) todayCompletedHabits += 1;

      return {
        id: habit.id,
        name: habit.name,
        category: habit.category,
        goalType: habit.goalType,
        numberDirection: habit.numberDirection === 'lte' ? 'lte' : 'gte',
        unit: habit.unit,
        goalValue: habit.goalValue,
        today: {
          hasRecord: todayHasRecord,
          value: todayValue,
          completed: todayCompleted,
        },
        summary30d: {
          totalRecords,
          completedRecords,
          completionRatePercent:
            totalRecords > 0 ? Math.round((completedRecords / totalRecords) * 100) : null,
          latestValue,
        },
      };
    });

    const totalHabits = habits.length;
    return {
      user: {
        id: user.id,
        email: user.email,
        authProvider:
          user.authProvider === 'google' ||
          user.authProvider === 'apple' ||
          user.authProvider === 'kakao' ||
          user.authProvider === 'naver'
            ? user.authProvider
            : 'unknown',
        displayName: user.displayName,
        createdAt: user.createdAt.toISOString(),
        isActive: user.isActive,
        deactivatedAt: user.deactivatedAt?.toISOString() ?? null,
        deactivationReason: user.deactivationReason ?? null,
        deactivatedBy: user.deactivatedBy ?? null,
      },
      summary30d: {
        from,
        to: today,
        totalHabits,
        trackedHabitCount,
        totalRecords: summaryTotalRecords,
        completedRecords: summaryCompletedRecords,
        completionRatePercent:
          summaryTotalRecords > 0
            ? Math.round((summaryCompletedRecords / summaryTotalRecords) * 100)
            : null,
      },
      todaySummary: {
        date: today,
        totalHabits,
        recordedHabits: todayRecordedHabits,
        completedHabits: todayCompletedHabits,
        completionRatePercent:
          totalHabits > 0 ? Math.round((todayCompletedHabits / totalHabits) * 100) : null,
      },
      habits: habitItems,
    };
  }

  private requireTemplateVisuals(colorHex?: string | null, iconName?: string | null): {
    colorHex: string;
    iconName: string;
  } {
    const normalizedColorHex = (colorHex ?? '').trim();
    const normalizedIconName = (iconName ?? '').trim();
    if (!normalizedColorHex) {
      throw new BadRequestException('colorHex is required');
    }
    if (!normalizedIconName) {
      throw new BadRequestException('iconName is required');
    }
    return { colorHex: normalizedColorHex, iconName: normalizedIconName };
  }

  async listTemplates(): Promise<HabitTemplateDto[]> {
    const list = await this.templateRepo.find({ order: { createdAt: 'ASC' } });
    return list.map((t) => ({
      id: t.id,
      name: t.name,
      nameEn: t.nameEn ?? undefined,
      category: t.category ?? undefined,
      categoryEn: t.categoryEn ?? undefined,
      goalType: t.goalType,
      numberDirection: t.numberDirection === 'lte' ? 'lte' : 'gte',
      unit: t.unit ?? undefined,
      goalValue: t.goalValue ?? undefined,
      colorHex: t.colorHex ?? undefined,
      iconName: t.iconName ?? undefined,
      isActive: t.isActive,
      createdAt: t.createdAt.toISOString(),
      updatedAt: t.updatedAt.toISOString(),
    }));
  }

  /** 템플릿·(미보관) 회원 습관에서 참조 중인 카테고리 이름 */
  async listHabitCategoriesInUse(): Promise<string[]> {
    const tpl = await this.templateRepo
      .createQueryBuilder('t')
      .select('DISTINCT t.category', 'c')
      .where('t.category IS NOT NULL')
      .andWhere("TRIM(t.category) <> ''")
      .getRawMany<{ c: string }>();
    const hab = await this.habitRepo
      .createQueryBuilder('h')
      .select('DISTINCT h.category', 'c')
      .where('h.archivedAt IS NULL')
      .andWhere('h.category IS NOT NULL')
      .andWhere("TRIM(h.category) <> ''")
      .getRawMany<{ c: string }>();
    const set = new Set<string>();
    for (const r of tpl) {
      if (r.c) set.add(String(r.c).trim());
    }
    for (const r of hab) {
      if (r.c) set.add(String(r.c).trim());
    }
    return [...set];
  }

  async createTemplate(body: Partial<HabitTemplateDto>): Promise<HabitTemplateDto> {
    const goalType = body.goalType ?? 'completion';
    const numberDirection = body.numberDirection === 'lte' ? 'lte' : 'gte';
    const goalValue =
      goalType === 'completion'
        ? null
        : body.goalValue != null && Number.isFinite(Number(body.goalValue))
          ? Number(body.goalValue)
          : null;
    const visuals = this.requireTemplateVisuals(body.colorHex, body.iconName);
    const t = this.templateRepo.create({
      id: `t-${uuidv4()}`,
      name: body.name!,
      nameEn: typeof body.nameEn === 'string' ? body.nameEn.trim() || null : null,
      category: body.category,
      categoryEn: typeof body.categoryEn === 'string' ? body.categoryEn.trim() || null : null,
      goalType,
      numberDirection,
      unit: body.unit?.trim() || null,
      goalValue,
      colorHex: visuals.colorHex,
      iconName: visuals.iconName,
      isActive: body.isActive ?? true,
    });
    await this.templateRepo.save(t);
    return {
      id: t.id,
      name: t.name,
      nameEn: t.nameEn ?? undefined,
      category: t.category ?? undefined,
      categoryEn: t.categoryEn ?? undefined,
      goalType: t.goalType,
      numberDirection: t.numberDirection === 'lte' ? 'lte' : 'gte',
      unit: t.unit ?? undefined,
      goalValue: t.goalValue ?? undefined,
      colorHex: t.colorHex ?? undefined,
      iconName: t.iconName ?? undefined,
      isActive: t.isActive,
      createdAt: t.createdAt.toISOString(),
      updatedAt: t.updatedAt.toISOString(),
    };
  }

  async updateTemplate(
    id: string,
    body: Partial<HabitTemplateDto>,
  ): Promise<HabitTemplateDto | undefined> {
    const t = await this.templateRepo.findOne({ where: { id } });
    if (!t) return undefined;
    if (body.name !== undefined) t.name = body.name;
    if (body.nameEn !== undefined) t.nameEn = body.nameEn?.trim() ? body.nameEn.trim() : null;
    if (body.category !== undefined) t.category = body.category ?? null;
    if (body.categoryEn !== undefined) t.categoryEn = body.categoryEn?.trim() ? body.categoryEn.trim() : null;
    if (body.goalType !== undefined) t.goalType = body.goalType;
    if (body.numberDirection !== undefined) {
      t.numberDirection = body.numberDirection === 'lte' ? 'lte' : 'gte';
    }
    if (body.unit !== undefined) t.unit = body.unit?.trim() ? body.unit.trim() : null;
    if (body.isActive !== undefined) t.isActive = body.isActive;
    if (body.colorHex !== undefined) t.colorHex = body.colorHex ?? null;
    if (body.iconName !== undefined) t.iconName = body.iconName ?? null;
    if (body.goalValue !== undefined) {
      t.goalValue =
        body.goalValue != null && Number.isFinite(Number(body.goalValue))
          ? Number(body.goalValue)
          : null;
    }
    const gt = t.goalType;
    if (gt === 'completion') t.goalValue = null;
    const visuals = this.requireTemplateVisuals(t.colorHex, t.iconName);
    t.colorHex = visuals.colorHex;
    t.iconName = visuals.iconName;
    await this.templateRepo.save(t);
    return {
      id: t.id,
      name: t.name,
      nameEn: t.nameEn ?? undefined,
      category: t.category ?? undefined,
      categoryEn: t.categoryEn ?? undefined,
      goalType: t.goalType,
      numberDirection: t.numberDirection === 'lte' ? 'lte' : 'gte',
      unit: t.unit ?? undefined,
      goalValue: t.goalValue ?? undefined,
      colorHex: t.colorHex ?? undefined,
      iconName: t.iconName ?? undefined,
      isActive: t.isActive,
      createdAt: t.createdAt.toISOString(),
      updatedAt: t.updatedAt.toISOString(),
    };
  }

  async deleteTemplate(id: string): Promise<boolean> {
    const result = await this.templateRepo.delete(id);
    return (result.affected ?? 0) > 0;
  }

  /** 기존 템플릿 전부 삭제 후 기본 예시 템플릿으로 다시 채움 */
  async reseedHabitTemplates(): Promise<{ inserted: number }> {
    await this.templateRepo.clear();
    for (const row of DEFAULT_HABIT_TEMPLATES) {
      const goalType = row.goalType;
      const numberDirection = row.numberDirection ?? 'gte';
      const goalValue =
        goalType === 'completion'
          ? null
          : row.goalValue != null && Number.isFinite(row.goalValue)
            ? row.goalValue
            : null;
      await this.templateRepo.save(
        this.templateRepo.create({
          id: `t-${uuidv4()}`,
          name: row.name,
          nameEn: reseedTemplateNameEn(row.name),
          category: row.category,
          categoryEn: row.category ? reseedCategoryEn(row.category) : null,
          goalType,
          numberDirection,
          unit: row.unit ?? null,
          goalValue,
          colorHex: row.colorHex ?? null,
          iconName: row.iconName ?? null,
          isActive: true,
        }),
      );
    }
    return { inserted: DEFAULT_HABIT_TEMPLATES.length };
  }

  async listNotices(): Promise<NoticeDto[]> {
    const nowMs = Date.now();
    const list = await this.noticeRepo.find({ order: { isNotice: 'DESC', createdAt: 'DESC' } });
    return list.map((n) => ({
      // 기간 밖이면 공개여부를 자동 N으로 표시한다.
      isPublic:
        n.isPublic &&
        (n.displayStartAt == null || n.displayStartAt.getTime() <= nowMs) &&
        (n.displayEndAt == null || n.displayEndAt.getTime() >= nowMs),
      id: n.id,
      title: n.title,
      body: n.body,
      titleEn: n.titleEn ?? undefined,
      bodyEn: n.bodyEn ?? undefined,
      publishedAt: n.publishedAt?.toISOString(),
      isNotice: n.isNotice,
      displayStartAt: n.displayStartAt?.toISOString(),
      displayEndAt: n.displayEndAt?.toISOString(),
      createdAt: n.createdAt.toISOString(),
      updatedAt: n.updatedAt.toISOString(),
    }));
  }

  async createNotice(body: {
    title: string;
    body: string;
    titleEn?: string;
    bodyEn?: string;
    publishedAt?: string;
    isNotice?: boolean;
    isPublic?: boolean;
    displayStartAt?: string;
    displayEndAt?: string;
  }): Promise<NoticeDto> {
    const displayStartAt = body.displayStartAt ? new Date(body.displayStartAt) : null;
    const displayEndAt = body.displayEndAt ? new Date(body.displayEndAt) : null;
    if (displayStartAt && displayEndAt && displayStartAt.getTime() > displayEndAt.getTime()) {
      throw new BadRequestException('displayStartAt must be before displayEndAt');
    }
    const n = this.noticeRepo.create({
      id: `n-${uuidv4()}`,
      title: body.title,
      body: body.body,
      titleEn: typeof body.titleEn === 'string' ? body.titleEn.trim() || null : null,
      bodyEn: typeof body.bodyEn === 'string' ? body.bodyEn.trim() || null : null,
      publishedAt: body.publishedAt ? new Date(body.publishedAt) : body.isPublic ? new Date() : null,
      isNotice: body.isNotice ?? true,
      isPublic: body.isPublic ?? false,
      displayStartAt,
      displayEndAt,
    });
    await this.noticeRepo.save(n);
    return {
      id: n.id,
      title: n.title,
      body: n.body,
      titleEn: n.titleEn ?? undefined,
      bodyEn: n.bodyEn ?? undefined,
      publishedAt: n.publishedAt?.toISOString(),
      isNotice: n.isNotice,
      isPublic: n.isPublic,
      displayStartAt: n.displayStartAt?.toISOString(),
      displayEndAt: n.displayEndAt?.toISOString(),
      createdAt: n.createdAt.toISOString(),
      updatedAt: n.updatedAt.toISOString(),
    };
  }

  async updateNotice(id: string, body: Partial<NoticeDto>): Promise<NoticeDto | undefined> {
    const n = await this.noticeRepo.findOne({ where: { id } });
    if (!n) return undefined;
    if (body.title != null) n.title = body.title;
    if (body.body != null) n.body = body.body;
    if (body.titleEn !== undefined) n.titleEn = body.titleEn?.trim() ? body.titleEn.trim() : null;
    if (body.bodyEn !== undefined) n.bodyEn = body.bodyEn?.trim() ? body.bodyEn.trim() : null;
    if (body.publishedAt !== undefined) {
      n.publishedAt = body.publishedAt ? new Date(body.publishedAt) : null;
    }
    if (body.isNotice !== undefined) n.isNotice = Boolean(body.isNotice);
    if (body.isPublic !== undefined) n.isPublic = Boolean(body.isPublic);
    if (body.displayStartAt !== undefined) {
      n.displayStartAt = body.displayStartAt ? new Date(body.displayStartAt) : null;
    }
    if (body.displayEndAt !== undefined) {
      n.displayEndAt = body.displayEndAt ? new Date(body.displayEndAt) : null;
    }
    if (
      n.displayStartAt &&
      n.displayEndAt &&
      n.displayStartAt.getTime() > n.displayEndAt.getTime()
    ) {
      throw new BadRequestException('displayStartAt must be before displayEndAt');
    }
    if (n.isPublic && n.publishedAt == null) {
      n.publishedAt = new Date();
    }
    await this.noticeRepo.save(n);
    return {
      id: n.id,
      title: n.title,
      body: n.body,
      titleEn: n.titleEn ?? undefined,
      bodyEn: n.bodyEn ?? undefined,
      publishedAt: n.publishedAt?.toISOString(),
      isNotice: n.isNotice,
      isPublic: n.isPublic,
      displayStartAt: n.displayStartAt?.toISOString(),
      displayEndAt: n.displayEndAt?.toISOString(),
      createdAt: n.createdAt.toISOString(),
      updatedAt: n.updatedAt.toISOString(),
    };
  }

  async deleteNotice(id: string): Promise<boolean> {
    const result = await this.noticeRepo.delete(id);
    return (result.affected ?? 0) > 0;
  }

  async getConfig(key: string): Promise<string | undefined> {
    const row = await this.configRepo.findOne({ where: { key } });
    return row?.value;
  }

  async getAllConfig(): Promise<Record<string, string>> {
    const rows = await this.configRepo.find();
    const out: Record<string, string> = {};
    for (const r of rows) out[r.key] = r.value;
    return out;
  }

  async setConfig(key: string, value: string): Promise<void> {
    let row = await this.configRepo.findOne({ where: { key } });
    if (!row) {
      row = this.configRepo.create({ key, value });
    } else {
      row.value = value;
    }
    await this.configRepo.save(row);
  }

  async patchConfig(body: Record<string, string>): Promise<void> {
    for (const [k, v] of Object.entries(body)) {
      await this.setConfig(k, typeof v === 'string' ? v : JSON.stringify(v));
    }
  }

  async listInquiries(): Promise<InquiryAdminDto[]> {
    const list = await this.inquiryRepo.find({
      where: { deletedAt: IsNull() },
      order: { createdAt: 'DESC' },
    });
    const userIds = [...new Set(list.map((i) => i.userId))];
    const users = userIds.length
      ? await this.userRepo.find({ where: { id: In(userIds) } })
      : [];
    const userMap = new Map(users.map((u) => [u.id, u]));
    return list.map((i) => {
      const u = userMap.get(i.userId);
      return {
        id: i.id,
        userId: i.userId,
        userEmail: u?.email ?? null,
        userDisplayName: u?.displayName ?? null,
        subject: i.subject,
        body: i.body,
        status: i.status,
        adminReply: i.adminReply ?? null,
        repliedAt: i.repliedAt?.toISOString() ?? null,
        userReadAt: i.userReadAt?.toISOString() ?? null,
        createdAt: i.createdAt.toISOString(),
        updatedAt: i.updatedAt.toISOString(),
      };
    });
  }

  async updateInquiryReply(
    id: string,
    body: { adminReply?: string; status?: string },
  ): Promise<InquiryAdminDto | undefined> {
    const i = await this.inquiryRepo.findOne({ where: { id, deletedAt: IsNull() } });
    if (!i) return undefined;
    const prevReply = i.adminReply?.trim() ?? '';
    const nextReply = body.adminReply != null ? body.adminReply.trim() : prevReply;
    const hasReplyChanged = body.adminReply != null && nextReply != prevReply;
    const shouldNotify = nextReply !== '' && hasReplyChanged;
    if (body.adminReply != null) {
      i.adminReply = body.adminReply;
      if ((body.adminReply as string).trim() !== '') {
        i.repliedAt = new Date();
        i.status = 'answered';
        i.userReadAt = null;
      } else {
        i.status = 'pending';
        i.repliedAt = null;
        i.userReadAt = null;
      }
    }
    if (body.status != null) i.status = body.status;
    await this.inquiryRepo.save(i);
    if (shouldNotify) {
      this.pushService.sendInquiryReplyNotification(i.userId, i.subject).catch((e: unknown) => {
        // eslint-disable-next-line no-console
        console.log('[AdminDataService] inquiry_reply push failed (1st)', {
          inquiryId: i.id,
          userId: i.userId,
          err: e instanceof Error ? e.message : String(e),
        });
        setTimeout(() => {
          this.pushService.sendInquiryReplyNotification(i.userId, i.subject).catch((e2: unknown) => {
            // eslint-disable-next-line no-console
            console.log('[AdminDataService] inquiry_reply push failed (retry)', {
              inquiryId: i.id,
              userId: i.userId,
              err: e2 instanceof Error ? e2.message : String(e2),
            });
          });
        }, 1500);
      });
    }
    const u = await this.userRepo.findOne({ where: { id: i.userId } });
    return {
      id: i.id,
      userId: i.userId,
      userEmail: u?.email ?? null,
      userDisplayName: u?.displayName ?? null,
      subject: i.subject,
      body: i.body,
      status: i.status,
      adminReply: i.adminReply ?? null,
      repliedAt: i.repliedAt?.toISOString() ?? null,
      userReadAt: i.userReadAt?.toISOString() ?? null,
      createdAt: i.createdAt.toISOString(),
      updatedAt: i.updatedAt.toISOString(),
    };
  }

  async softDeleteInquiry(id: string): Promise<boolean> {
    const i = await this.inquiryRepo.findOne({ where: { id, deletedAt: IsNull() } });
    if (!i) return false;
    i.deletedAt = new Date();
    await this.inquiryRepo.save(i);
    return true;
  }

  private toLegalDto(d: LegalDocumentEntity): LegalDocumentDto {
    return {
      id: d.id,
      type: d.type,
      locale: d.locale,
      version: d.version,
      title: d.title,
      content: d.content,
      effectiveFrom: d.effectiveFrom?.toISOString().slice(0, 10) ?? null,
      createdAt: d.createdAt.toISOString(),
      updatedAt: d.updatedAt.toISOString(),
    };
  }

  private async nextLegalVersion(type: LegalDocumentType): Promise<number> {
    const max = await this.legalRepo
      .createQueryBuilder('d')
      .select('MAX(d.version)', 'v')
      .where('d.type = :type', { type })
      .getRawOne<{ v: number | null }>();
    return (max?.v ?? 0) + 1;
  }

  async listLegalDocuments(
    type?: LegalDocumentType,
    locale: 'ko' | 'en' | 'all' = 'all',
  ): Promise<LegalDocumentDto[]> {
    const qb = this.legalRepo
      .createQueryBuilder('d')
      .orderBy('d.type', 'ASC')
      .addOrderBy('d.version', 'DESC')
      .addOrderBy('d.locale', 'ASC');
    if (type) qb.andWhere('d.type = :type', { type });
    if (locale !== 'all') qb.andWhere('d.locale = :locale', { locale });
    const list = await qb.getMany();
    return list.map((d) => this.toLegalDto(d));
  }

  async createLegalDocument(body: {
    type: LegalDocumentType;
    locale?: 'ko' | 'en';
    title?: string;
    content?: string;
    effectiveFrom?: string;
    titleKo?: string;
    contentKo?: string;
    titleEn?: string;
    contentEn?: string;
  }): Promise<LegalDocumentDto> {
    const pairRequested =
      body.contentKo !== undefined ||
      body.contentEn !== undefined ||
      body.titleKo !== undefined ||
      body.titleEn !== undefined;

    if (pairRequested) {
      const koContent = (body.contentKo ?? '').trim();
      if (!koContent) {
        throw new BadRequestException(
          'Korean body (contentKo) is required when creating a new version with bilingual fields.',
        );
      }
      const eff = body.effectiveFrom ? new Date(body.effectiveFrom) : null;
      const nextVersion = await this.nextLegalVersion(body.type);
      const koDoc = this.legalRepo.create({
        id: `legal-${uuidv4()}`,
        type: body.type,
        locale: 'ko',
        version: nextVersion,
        title: (body.titleKo ?? '').trim(),
        content: koContent,
        effectiveFrom: eff,
      });
      await this.legalRepo.save(koDoc);

      const enContent = (body.contentEn ?? '').trim();
      const enTitle = (body.titleEn ?? '').trim();
      if (enContent || enTitle) {
        const enDoc = this.legalRepo.create({
          id: `legal-${uuidv4()}`,
          type: body.type,
          locale: 'en',
          version: nextVersion,
          title: enTitle,
          content: enContent,
          effectiveFrom: eff,
        });
        await this.legalRepo.save(enDoc);
      }

      return this.toLegalDto(koDoc);
    }

    const loc = body.locale === 'en' ? 'en' : 'ko';
    const nextVersion = await this.nextLegalVersion(body.type);
    const doc = this.legalRepo.create({
      id: `legal-${uuidv4()}`,
      type: body.type,
      locale: loc,
      version: nextVersion,
      title: body.title ?? '',
      content: body.content ?? '',
      effectiveFrom: body.effectiveFrom ? new Date(body.effectiveFrom) : null,
    });
    await this.legalRepo.save(doc);
    return this.toLegalDto(doc);
  }

  async updateLegalDocumentVersion(
    type: LegalDocumentType,
    version: number,
    body: {
      effectiveFrom?: string | null;
      titleKo?: string;
      contentKo?: string;
      titleEn?: string;
      contentEn?: string;
    },
  ): Promise<void> {
    const ko = await this.legalRepo.findOne({ where: { type, locale: 'ko', version } });
    if (!ko) {
      throw new NotFoundException(`No Korean legal document for ${type} v${version}`);
    }

    let en = await this.legalRepo.findOne({ where: { type, locale: 'en', version } });

    if (body.effectiveFrom !== undefined) {
      const eff = body.effectiveFrom ? new Date(body.effectiveFrom) : null;
      ko.effectiveFrom = eff;
      if (en) en.effectiveFrom = eff;
    }
    if (body.titleKo !== undefined) ko.title = body.titleKo;
    if (body.contentKo !== undefined) ko.content = body.contentKo;
    await this.legalRepo.save(ko);

    if (body.titleEn !== undefined || body.contentEn !== undefined) {
      const enTitle = body.titleEn !== undefined ? body.titleEn : (en?.title ?? '');
      const enContent = body.contentEn !== undefined ? body.contentEn : (en?.content ?? '');
      const empty = !String(enTitle).trim() && !String(enContent).trim();
      if (en) {
        en.title = enTitle;
        en.content = enContent;
        if (empty) {
          await this.legalRepo.remove(en);
        } else {
          await this.legalRepo.save(en);
        }
      } else if (!empty) {
        await this.legalRepo.save(
          this.legalRepo.create({
            id: `legal-${uuidv4()}`,
            type,
            locale: 'en',
            version,
            title: enTitle,
            content: enContent,
            effectiveFrom: ko.effectiveFrom,
          }),
        );
      }
    } else if (body.effectiveFrom !== undefined && en) {
      await this.legalRepo.save(en);
    }
  }

  async updateLegalDocument(id: string, body: { title?: string; content?: string; effectiveFrom?: string | null }): Promise<LegalDocumentDto | undefined> {
    const doc = await this.legalRepo.findOne({ where: { id } });
    if (!doc) return undefined;
    if (body.title != null) doc.title = body.title;
    if (body.content != null) doc.content = body.content;
    if (body.effectiveFrom !== undefined) doc.effectiveFrom = body.effectiveFrom ? new Date(body.effectiveFrom) : null;
    await this.legalRepo.save(doc);
    return this.toLegalDto(doc);
  }

  async getLatestLegalDocument(type: LegalDocumentType): Promise<LegalDocumentDto | null> {
    const doc = await this.legalRepo.findOne({
      where: { type, locale: 'ko' },
      order: { version: 'DESC' },
    });
    if (!doc) return null;
    return this.toLegalDto(doc);
  }
}

