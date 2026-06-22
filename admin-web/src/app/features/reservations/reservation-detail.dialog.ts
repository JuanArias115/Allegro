import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { DecimalPipe } from '@angular/common';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { MAT_DIALOG_DATA, MatDialogModule, MatDialogRef } from '@angular/material/dialog';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { forkJoin } from 'rxjs';
import { ReservationsService } from '../../core/api/reservations.service';
import { CatalogService } from '../../core/api/catalog.service';
import { ConfirmService } from '../../shared/ui/confirm.dialog';
import type { Product, Reservation, ReservationStatus } from '../../core/models/models';

@Component({
  selector: 'app-reservation-detail',
  imports: [
    DecimalPipe,
    ReactiveFormsModule,
    MatDialogModule,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
    MatButtonModule,
    MatIconModule,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './reservation-detail.dialog.html',
  styleUrl: './reservation-detail.dialog.scss',
})
export class ReservationDetailDialog {
  private readonly fb = inject(FormBuilder);
  private readonly api = inject(ReservationsService);
  private readonly catalog = inject(CatalogService);
  private readonly confirm = inject(ConfirmService);
  private readonly ref = inject(MatDialogRef<ReservationDetailDialog, boolean>);
  private readonly id = inject<string>(MAT_DIALOG_DATA);

  protected readonly loading = signal(true);
  protected readonly reservation = signal<Reservation | null>(null);
  protected readonly products = signal<Product[]>([]);
  protected changed = false;

  protected readonly paymentForm = this.fb.nonNullable.group({
    amount: [0, [Validators.required, Validators.min(1)]],
    method: ['Cash' as const, Validators.required],
    note: [''],
  });

  protected readonly consumptionForm = this.fb.nonNullable.group({
    productId: ['', Validators.required],
    quantity: [1, [Validators.required, Validators.min(1)]],
  });

  constructor() {
    forkJoin({
      reservation: this.api.getById(this.id),
      products: this.catalog.products(true),
    }).subscribe(({ reservation, products }) => {
      this.reservation.set(reservation);
      this.products.set(products);
      this.loading.set(false);
    });
  }

  private apply(r: Reservation): void {
    this.reservation.set(r);
    this.changed = true;
  }

  addPayment(): void {
    if (this.paymentForm.invalid) return;
    const v = this.paymentForm.getRawValue();
    this.api
      .addPayment(this.id, { amount: v.amount, method: v.method, note: v.note || null })
      .subscribe((r) => {
        this.apply(r);
        this.paymentForm.reset({ amount: 0, method: 'Cash', note: '' });
      });
  }

  addConsumption(): void {
    if (this.consumptionForm.invalid) return;
    const v = this.consumptionForm.getRawValue();
    this.api.addConsumption(this.id, { productId: v.productId, quantity: v.quantity }).subscribe((r) => {
      this.apply(r);
      this.consumptionForm.reset({ productId: '', quantity: 1 });
    });
  }

  removeConsumption(consumptionId: string): void {
    this.api.removeConsumption(this.id, consumptionId).subscribe((r) => this.apply(r));
  }

  setStatus(status: ReservationStatus): void {
    this.api.changeStatus(this.id, status).subscribe((r) => this.apply(r));
  }

  cancel(): void {
    this.confirm
      .ask({
        title: 'Cancelar reserva',
        message: '¿Seguro que deseas cancelar esta reserva? Liberará las fechas del domo.',
        confirmText: 'Cancelar reserva',
        danger: true,
      })
      .subscribe((ok) => ok && this.setStatus('Cancelled'));
  }

  checkout(): void {
    this.confirm
      .ask({
        title: 'Cerrar reserva (checkout)',
        message: 'Se marcará como finalizada. ¿Continuar?',
        confirmText: 'Finalizar',
      })
      .subscribe((ok) => {
        if (ok) this.api.checkout(this.id, null).subscribe((r) => this.apply(r));
      });
  }

  close(): void {
    this.ref.close(this.changed);
  }
}
