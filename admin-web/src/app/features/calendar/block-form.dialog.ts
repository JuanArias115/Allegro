import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { MAT_DIALOG_DATA, MatDialogModule, MatDialogRef } from '@angular/material/dialog';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatButtonModule } from '@angular/material/button';
import { DomeBlocksService } from '../../core/api/dome-blocks.service';
import type { Dome } from '../../core/models/models';

@Component({
  selector: 'app-block-form',
  imports: [
    ReactiveFormsModule,
    MatDialogModule,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
    MatButtonModule,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './block-form.dialog.html',
})
export class BlockFormDialog {
  private readonly fb = inject(FormBuilder);
  private readonly api = inject(DomeBlocksService);
  private readonly ref = inject(MatDialogRef<BlockFormDialog>);
  protected readonly domes = inject<Dome[]>(MAT_DIALOG_DATA);

  protected readonly saving = signal(false);
  protected readonly error = signal<string | null>(null);

  protected readonly form = this.fb.nonNullable.group({
    domeId: ['', Validators.required],
    startDate: ['', Validators.required],
    endDate: ['', Validators.required],
    reason: ['', [Validators.required, Validators.maxLength(200)]],
  });

  save(): void {
    if (this.form.invalid || this.saving()) {
      this.form.markAllAsTouched();
      return;
    }
    const v = this.form.getRawValue();
    if (v.endDate <= v.startDate) {
      this.error.set('La fecha final debe ser posterior a la inicial.');
      return;
    }
    this.saving.set(true);
    this.error.set(null);
    this.api.create(v).subscribe({
      next: (b) => this.ref.close(b),
      error: (e) => {
        this.error.set(e?.error?.detail ?? 'No se pudo crear el bloqueo.');
        this.saving.set(false);
      },
    });
  }

  cancel(): void {
    this.ref.close();
  }
}
