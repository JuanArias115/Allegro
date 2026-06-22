import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { MAT_DIALOG_DATA, MatDialogModule, MatDialogRef } from '@angular/material/dialog';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatButtonModule } from '@angular/material/button';
import { ReservationsService, type UpsertReservation } from '../../core/api/reservations.service';
import type { Dome, Reservation } from '../../core/models/models';

export interface ReservationFormData {
  reservation: Reservation | null;
  domes: Dome[];
}

@Component({
  selector: 'app-reservation-form',
  imports: [
    ReactiveFormsModule,
    MatDialogModule,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
    MatButtonModule,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './reservation-form.dialog.html',
})
export class ReservationFormDialog {
  private readonly fb = inject(FormBuilder);
  private readonly api = inject(ReservationsService);
  private readonly ref = inject(MatDialogRef<ReservationFormDialog>);
  protected readonly data = inject<ReservationFormData>(MAT_DIALOG_DATA);

  protected readonly saving = signal(false);
  protected readonly error = signal<string | null>(null);
  protected readonly isEdit = this.data.reservation !== null;
  private readonly r = this.data.reservation;

  protected readonly form = this.fb.nonNullable.group({
    guestName: [this.r?.guestName ?? '', [Validators.required, Validators.maxLength(120)]],
    phone: [this.r?.phone ?? '', [Validators.required, Validators.maxLength(40)]],
    domeId: [this.r?.domeId ?? '', Validators.required],
    checkIn: [this.r?.checkIn ?? '', Validators.required],
    checkOut: [this.r?.checkOut ?? '', Validators.required],
    guestCount: [this.r?.guestCount ?? 2, [Validators.required, Validators.min(1)]],
    lodgingPrice: [this.r?.lodgingPrice ?? 0, [Validators.required, Validators.min(0)]],
    notes: [this.r?.notes ?? ''],
  });

  save(): void {
    if (this.form.invalid || this.saving()) {
      this.form.markAllAsTouched();
      return;
    }
    const v = this.form.getRawValue();
    if (v.checkOut <= v.checkIn) {
      this.error.set('La fecha de salida debe ser posterior a la de llegada.');
      return;
    }
    this.saving.set(true);
    this.error.set(null);

    // Verifica disponibilidad (excluye la propia reserva al editar) antes de guardar.
    this.api
      .availability(v.domeId, v.checkIn, v.checkOut, this.r?.id)
      .subscribe({
        next: (av) => {
          if (!av.isAvailable) {
            this.saving.set(false);
            this.error.set(
              av.blockedRanges.length
                ? 'Esas fechas están bloqueadas para el domo.'
                : 'El domo ya tiene una reserva que se cruza con esas fechas.',
            );
            return;
          }
          this.persist(v);
        },
        error: () => this.persist(v), // si falla el chequeo, el backend igual valida
      });
  }

  private persist(v: ReturnType<typeof this.form.getRawValue>): void {
    const body: UpsertReservation = {
      guestName: v.guestName,
      phone: v.phone,
      domeId: v.domeId,
      checkIn: v.checkIn,
      checkOut: v.checkOut,
      guestCount: v.guestCount,
      lodgingPrice: v.lodgingPrice,
      notes: v.notes || null,
    };
    const op = this.isEdit ? this.api.update(this.r!.id, body) : this.api.create(body);
    op.subscribe({
      next: (res) => this.ref.close(res),
      error: (e) => {
        this.error.set(e?.error?.detail ?? 'No se pudo guardar la reserva.');
        this.saving.set(false);
      },
    });
  }

  cancel(): void {
    this.ref.close();
  }
}
