import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { DatePipe } from '@angular/common';
import { forkJoin } from 'rxjs';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatDialog } from '@angular/material/dialog';
import { CatalogService } from '../../core/api/catalog.service';
import { ReservationsService } from '../../core/api/reservations.service';
import { SkeletonComponent, ErrorStateComponent } from '../../shared/ui/ui-states';
import { StatusChipComponent } from '../../shared/ui/status-chip';
import { DomeFormDialog } from './dome-form.dialog';
import { toIsoDate } from '../../core/util/dates';
import type { Dome, ReservationSummary } from '../../core/models/models';

interface DomeRow {
  dome: Dome;
  next: ReservationSummary | null;
  occupiedNow: boolean;
}

@Component({
  selector: 'app-domes',
  imports: [
    DatePipe,
    MatButtonModule,
    MatIconModule,
    SkeletonComponent,
    ErrorStateComponent,
    StatusChipComponent,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './domes.html',
  styleUrl: './domes.scss',
})
export class Domes {
  private readonly catalog = inject(CatalogService);
  private readonly reservations = inject(ReservationsService);
  private readonly dialog = inject(MatDialog);

  protected readonly loading = signal(true);
  protected readonly error = signal(false);
  private readonly domes = signal<Dome[]>([]);
  private readonly active = signal<ReservationSummary[]>([]);

  protected readonly rows = computed<DomeRow[]>(() => {
    const today = toIsoDate(new Date());
    return this.domes().map((dome) => {
      const forDome = this.active()
        .filter((r) => r.domeId === dome.id && r.checkOut > today)
        .sort((a, b) => a.checkIn.localeCompare(b.checkIn));
      const next = forDome[0] ?? null;
      const occupiedNow = forDome.some((r) => r.checkIn <= today && today < r.checkOut);
      return { dome, next, occupiedNow };
    });
  });

  constructor() {
    this.reload();
  }

  reload(): void {
    this.loading.set(true);
    this.error.set(false);
    forkJoin({
      domes: this.catalog.domes(false),
      active: this.reservations.list({ active: true }),
    }).subscribe({
      next: ({ domes, active }) => {
        this.domes.set(domes);
        this.active.set(active);
        this.loading.set(false);
      },
      error: () => {
        this.error.set(true);
        this.loading.set(false);
      },
    });
  }

  edit(dome: Dome): void {
    this.dialog
      .open(DomeFormDialog, { data: dome, width: '440px' })
      .afterClosed()
      .subscribe((r) => r && this.reload());
  }
}
