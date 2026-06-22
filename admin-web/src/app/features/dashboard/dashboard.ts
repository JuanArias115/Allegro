import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { CurrencyPipe, DatePipe } from '@angular/common';
import { RouterLink } from '@angular/router';
import { forkJoin, of } from 'rxjs';
import { catchError } from 'rxjs/operators';
import { ReservationsService } from '../../core/api/reservations.service';
import { ReportsService } from '../../core/api/reports.service';
import { AuthService } from '../../core/auth/auth.service';
import { monthRange } from '../../core/util/dates';
import { KpiCardComponent } from '../../shared/ui/kpi-card';
import { SkeletonComponent, ErrorStateComponent } from '../../shared/ui/ui-states';
import { StatusChipComponent } from '../../shared/ui/status-chip';
import type { ReportSummary, ReservationSummary, TodayState } from '../../core/models/models';

@Component({
  selector: 'app-dashboard',
  imports: [
    CurrencyPipe,
    DatePipe,
    RouterLink,
    KpiCardComponent,
    SkeletonComponent,
    ErrorStateComponent,
    StatusChipComponent,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './dashboard.html',
  styleUrl: './dashboard.scss',
})
export class Dashboard {
  private readonly reservations = inject(ReservationsService);
  private readonly reports = inject(ReportsService);
  private readonly auth = inject(AuthService);

  protected readonly isAdmin = this.auth.isAdmin;
  protected readonly loading = signal(true);
  protected readonly error = signal(false);
  protected readonly today = signal<TodayState | null>(null);
  protected readonly summary = signal<ReportSummary | null>(null);

  /** Alertas derivadas de datos reales: llegadas/salidas de hoy con saldo pendiente. */
  protected readonly alerts = computed(() => {
    const t = this.today();
    if (!t) return [];
    const out: { text: string; reservation: ReservationSummary }[] = [];
    for (const r of t.departures) {
      if (r.balance > 0) out.push({ text: 'Sale hoy con saldo pendiente', reservation: r });
    }
    for (const r of t.arrivals) {
      if (r.balance > 0) out.push({ text: 'Llega hoy con saldo pendiente', reservation: r });
    }
    return out;
  });

  constructor() {
    this.reload();
  }

  reload(): void {
    this.loading.set(true);
    this.error.set(false);
    const range = monthRange();
    const summary$ = this.isAdmin()
      ? this.reports.summary(range.from, range.to).pipe(catchError(() => of(null)))
      : of(null);

    forkJoin({
      today: this.reservations.today(),
      summary: summary$,
    }).subscribe({
      next: ({ today, summary }) => {
        this.today.set(today);
        this.summary.set(summary);
        this.loading.set(false);
      },
      error: () => {
        this.error.set(true);
        this.loading.set(false);
      },
    });
  }
}
