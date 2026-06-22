import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { MAT_DIALOG_DATA, MatDialogModule, MatDialogRef } from '@angular/material/dialog';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSlideToggleModule } from '@angular/material/slide-toggle';
import { MatButtonModule } from '@angular/material/button';
import { CatalogService, type UpsertCategory } from '../../core/api/catalog.service';
import type { ProductCategory } from '../../core/models/models';

@Component({
  selector: 'app-category-form',
  imports: [
    ReactiveFormsModule,
    MatDialogModule,
    MatFormFieldModule,
    MatInputModule,
    MatSlideToggleModule,
    MatButtonModule,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './category-form.dialog.html',
})
export class CategoryFormDialog {
  private readonly fb = inject(FormBuilder);
  private readonly catalog = inject(CatalogService);
  private readonly ref = inject(MatDialogRef<CategoryFormDialog>);
  protected readonly data = inject<ProductCategory | null>(MAT_DIALOG_DATA);

  protected readonly saving = signal(false);
  protected readonly error = signal<string | null>(null);
  protected readonly isEdit = this.data !== null;

  protected readonly form = this.fb.nonNullable.group({
    name: [this.data?.name ?? '', [Validators.required, Validators.maxLength(80)]],
    displayOrder: [this.data?.displayOrder ?? 0, [Validators.required, Validators.min(0)]],
    isActive: [this.data?.isActive ?? true],
  });

  save(): void {
    if (this.form.invalid || this.saving()) {
      this.form.markAllAsTouched();
      return;
    }
    this.saving.set(true);
    this.error.set(null);
    const body: UpsertCategory = this.form.getRawValue();
    const op = this.isEdit
      ? this.catalog.updateCategory(this.data!.id, body)
      : this.catalog.createCategory(body);

    op.subscribe({
      next: (c) => this.ref.close(c),
      error: (e) => {
        this.error.set(e?.error?.detail ?? 'No se pudo guardar la categoría.');
        this.saving.set(false);
      },
    });
  }

  cancel(): void {
    this.ref.close();
  }
}
