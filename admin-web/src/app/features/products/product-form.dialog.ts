import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { MAT_DIALOG_DATA, MatDialogModule, MatDialogRef } from '@angular/material/dialog';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatSlideToggleModule } from '@angular/material/slide-toggle';
import { MatButtonModule } from '@angular/material/button';
import { CatalogService, type UpsertProduct } from '../../core/api/catalog.service';
import type { Product, ProductCategory } from '../../core/models/models';

export interface ProductFormData {
  product: Product | null;
  categories: ProductCategory[];
}

@Component({
  selector: 'app-product-form',
  imports: [
    ReactiveFormsModule,
    MatDialogModule,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
    MatSlideToggleModule,
    MatButtonModule,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './product-form.dialog.html',
})
export class ProductFormDialog {
  private readonly fb = inject(FormBuilder);
  private readonly catalog = inject(CatalogService);
  private readonly ref = inject(MatDialogRef<ProductFormDialog>);
  protected readonly data = inject<ProductFormData>(MAT_DIALOG_DATA);

  protected readonly saving = signal(false);
  protected readonly error = signal<string | null>(null);
  protected readonly isEdit = this.data.product !== null;

  protected readonly form = this.fb.nonNullable.group({
    name: [this.data.product?.name ?? '', [Validators.required, Validators.maxLength(120)]],
    categoryId: [this.data.product?.categoryId ?? '', Validators.required],
    currentPrice: [this.data.product?.currentPrice ?? 0, [Validators.required, Validators.min(0)]],
    isActive: [this.data.product?.isActive ?? true],
  });

  save(): void {
    if (this.form.invalid || this.saving()) {
      this.form.markAllAsTouched();
      return;
    }
    this.saving.set(true);
    this.error.set(null);
    const body: UpsertProduct = { ...this.form.getRawValue(), imageUrl: null };
    const op = this.isEdit
      ? this.catalog.updateProduct(this.data.product!.id, body)
      : this.catalog.createProduct(body);

    op.subscribe({
      next: (p) => this.ref.close(p),
      error: (e) => {
        this.error.set(e?.error?.detail ?? 'No se pudo guardar el producto.');
        this.saving.set(false);
      },
    });
  }

  cancel(): void {
    this.ref.close();
  }
}
