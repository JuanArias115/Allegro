import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { CurrencyPipe, DatePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatDialog } from '@angular/material/dialog';
import { ReservationsService, type ReservationFilter } from '../../core/api/reservations.service';
import { CatalogService } from '../../core/api/catalog.service';
import { SkeletonComponent, ErrorStateComponent, EmptyStateComponent } from '../../shared/ui/ui-states';
import { StatusChipComponent } from '../../shared/ui/status-chip';
import { ReservationFormDialog, type ReservationFormData } from './reservation-form.dialog';
import { ReservationDetailDialog } from './reservation-detail.dialog';
import type { Dome, ReservationStatus, ReservationSummary } from '../../core/models/models';

@Component({
  selector: 'app-reservations',
  imports: [
    CurrencyPipe,
    DatePipe,
    FormsModule,
    MatButtonModule,
    MatIconModule,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
    SkeletonComponent,
    ErrorStateComponent,
    EmptyStateComponent,
    StatusChipComponent,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './reservations.html',
  styleUrl: './reservations.scss',
})
export class Reservations {
  private readonly api = inject(ReservationsService);
  private readonly catalog = inject(CatalogService);
  private readonly dialog = inject(MatDialog);

  protected readonly loading = signal(true);
  protected readonly error = signal(false);
  protected readonly items = signal<ReservationSummary[]>([]);
  protected readonly domes = signal<Dome[]>([]);

  protected text = '';
  protected domeId = '';
  protected status: ReservationStatus | '' = '';

  constructor() {
    this.catalog.domes(false).subscribe((d) => this.domes.set(d));
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.error.set(false);
    const filter: ReservationFilter = {
      domeId: this.domeId || undefined,
      status: this.status || undefined,
    };
    const text = this.text.trim();
    if (text) {
      if (/^[0-9+\s-]+$/.test(text)) filter.phone = text;
      else filter.name = text;
    }
    this.api.list(filter).subscribe({
      next: (list) => {
        this.items.set(list);
        this.loading.set(false);
      },
      error: () => {
        this.error.set(true);
        this.loading.set(false);
      },
    });
  }

  newReservation(): void {
    const data: ReservationFormData = { reservation: null, domes: this.domes().filter((d) => d.isActive) };
    this.dialog
      .open(ReservationFormDialog, { data, width: '640px' })
      .afterClosed()
      .subscribe((r) => r && this.load());
  }

  openDetail(r: ReservationSummary): void {
    this.dialog
      .open(ReservationDetailDialog, { data: r.id, width: '560px' })
      .afterClosed()
      .subscribe((changed) => changed && this.load());
  }
}
