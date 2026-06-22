import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { DatePipe } from '@angular/common';
import { forkJoin } from 'rxjs';
import { MatButtonModule } from '@angular/material/button';
import { MatButtonToggleModule } from '@angular/material/button-toggle';
import { MatIconModule } from '@angular/material/icon';
import { MatDialog } from '@angular/material/dialog';
import { ReservationsService } from '../../core/api/reservations.service';
import { DomeBlocksService } from '../../core/api/dome-blocks.service';
import { CatalogService } from '../../core/api/catalog.service';
import { SkeletonComponent, ErrorStateComponent } from '../../shared/ui/ui-states';
import { ReservationDetailDialog } from '../reservations/reservation-detail.dialog';
import { BlockFormDialog } from './block-form.dialog';
import { monthRangeOf, toIsoDate } from '../../core/util/dates';
import type { Dome, DomeBlock, ReservationSummary } from '../../core/models/models';

interface DayCell {
  date: string;
  day: number;
  inMonth: boolean;
  isToday: boolean;
  events: ReservationSummary[];
  blocks: DomeBlock[];
}

@Component({
  selector: 'app-calendar',
  imports: [
    DatePipe,
    MatButtonModule,
    MatButtonToggleModule,
    MatIconModule,
    SkeletonComponent,
    ErrorStateComponent,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './calendar.html',
  styleUrl: './calendar.scss',
})
export class Calendar {
  private readonly api = inject(ReservationsService);
  private readonly blocksApi = inject(DomeBlocksService);
  private readonly catalog = inject(CatalogService);
  private readonly dialog = inject(MatDialog);

  protected readonly loading = signal(true);
  protected readonly error = signal(false);
  protected readonly view = signal<'mes' | 'agenda'>('mes');
  protected readonly year = signal(new Date().getFullYear());
  protected readonly month = signal(new Date().getMonth()); // 0-11

  private readonly reservations = signal<ReservationSummary[]>([]);
  private readonly blocks = signal<DomeBlock[]>([]);
  private readonly domes = signal<Dome[]>([]);

  protected readonly weekDays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  protected readonly monthLabel = computed(() =>
    new Date(this.year(), this.month(), 1).toLocaleDateString('es-CO', {
      month: 'long',
      year: 'numeric',
    }),
  );

  /** Reservas no canceladas del mes, ordenadas por llegada (para agenda). */
  protected readonly agenda = computed(() =>
    this.reservations()
      .filter((r) => r.status !== 'Cancelled')
      .sort((a, b) => a.checkIn.localeCompare(b.checkIn)),
  );

  /** Grilla de 6 semanas comenzando en lunes. */
  protected readonly weeks = computed<DayCell[][]>(() => {
    const first = new Date(this.year(), this.month(), 1);
    const offset = (first.getDay() + 6) % 7; // lunes = 0
    const start = new Date(this.year(), this.month(), 1 - offset);
    const today = toIsoDate(new Date());
    const res = this.reservations().filter((r) => r.status !== 'Cancelled');

    const weeks: DayCell[][] = [];
    for (let w = 0; w < 6; w++) {
      const row: DayCell[] = [];
      for (let d = 0; d < 7; d++) {
        const date = new Date(start.getFullYear(), start.getMonth(), start.getDate() + w * 7 + d);
        const iso = toIsoDate(date);
        row.push({
          date: iso,
          day: date.getDate(),
          inMonth: date.getMonth() === this.month(),
          isToday: iso === today,
          events: res.filter((r) => r.checkIn <= iso && iso < r.checkOut),
          blocks: this.blocks().filter((b) => b.startDate <= iso && iso < b.endDate),
        });
      }
      weeks.push(row);
    }
    return weeks;
  });

  constructor() {
    this.catalog.domes(false).subscribe((d) => this.domes.set(d));
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.error.set(false);
    const range = monthRangeOf(this.year(), this.month());
    forkJoin({
      reservations: this.api.list({ from: range.from, to: range.to }),
      blocks: this.blocksApi.list(undefined, range.from, range.to),
    }).subscribe({
      next: ({ reservations, blocks }) => {
        this.reservations.set(reservations);
        this.blocks.set(blocks);
        this.loading.set(false);
      },
      error: () => {
        this.error.set(true);
        this.loading.set(false);
      },
    });
  }

  prevMonth(): void {
    const m = this.month() - 1;
    if (m < 0) {
      this.month.set(11);
      this.year.update((y) => y - 1);
    } else this.month.set(m);
    this.load();
  }

  nextMonth(): void {
    const m = this.month() + 1;
    if (m > 11) {
      this.month.set(0);
      this.year.update((y) => y + 1);
    } else this.month.set(m);
    this.load();
  }

  openReservation(r: ReservationSummary): void {
    this.dialog
      .open(ReservationDetailDialog, { data: r.id, width: '560px' })
      .afterClosed()
      .subscribe((changed) => changed && this.load());
  }

  blockDates(): void {
    this.dialog
      .open(BlockFormDialog, { data: this.domes().filter((d) => d.isActive), width: '420px' })
      .afterClosed()
      .subscribe((b) => b && this.load());
  }

  removeBlock(b: DomeBlock): void {
    this.blocksApi.remove(b.id).subscribe(() => this.load());
  }
}
