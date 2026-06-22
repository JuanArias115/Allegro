import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { MAT_DIALOG_DATA, MatDialogModule, MatDialogRef } from '@angular/material/dialog';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSlideToggleModule } from '@angular/material/slide-toggle';
import { MatButtonModule } from '@angular/material/button';
import { CatalogService, type UpsertDome } from '../../core/api/catalog.service';
import type { Dome } from '../../core/models/models';

@Component({
  selector: 'app-dome-form',
  imports: [
    ReactiveFormsModule,
    MatDialogModule,
    MatFormFieldModule,
    MatInputModule,
    MatSlideToggleModule,
    MatButtonModule,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './dome-form.dialog.html',
})
export class DomeFormDialog {
  private readonly fb = inject(FormBuilder);
  private readonly catalog = inject(CatalogService);
  private readonly ref = inject(MatDialogRef<DomeFormDialog>);
  protected readonly data = inject<Dome>(MAT_DIALOG_DATA);

  protected readonly saving = signal(false);
  protected readonly error = signal<string | null>(null);

  protected readonly form = this.fb.nonNullable.group({
    name: [this.data.name, [Validators.required, Validators.maxLength(80)]],
    shortDescription: [this.data.shortDescription ?? '', Validators.maxLength(280)],
    maxCapacity: [this.data.maxCapacity, [Validators.required, Validators.min(1)]],
    isActive: [this.data.isActive],
  });

  save(): void {
    if (this.form.invalid || this.saving()) {
      this.form.markAllAsTouched();
      return;
    }
    this.saving.set(true);
    this.error.set(null);
    const body: UpsertDome = this.form.getRawValue();
    this.catalog.updateDome(this.data.id, body).subscribe({
      next: (d) => this.ref.close(d),
      error: (e) => {
        this.error.set(e?.error?.detail ?? 'No se pudo guardar el domo.');
        this.saving.set(false);
      },
    });
  }

  cancel(): void {
    this.ref.close();
  }
}
