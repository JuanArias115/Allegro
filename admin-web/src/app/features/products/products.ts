import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { CurrencyPipe } from '@angular/common';
import { forkJoin } from 'rxjs';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatSlideToggleModule } from '@angular/material/slide-toggle';
import { MatDialog } from '@angular/material/dialog';
import { CatalogService } from '../../core/api/catalog.service';
import { AuthService } from '../../core/auth/auth.service';
import { SkeletonComponent, ErrorStateComponent, EmptyStateComponent } from '../../shared/ui/ui-states';
import { ProductFormDialog, type ProductFormData } from './product-form.dialog';
import { CategoryFormDialog } from './category-form.dialog';
import type { Product, ProductCategory } from '../../core/models/models';

interface Group {
  category: ProductCategory;
  products: Product[];
}

@Component({
  selector: 'app-products',
  imports: [
    CurrencyPipe,
    MatButtonModule,
    MatIconModule,
    MatSlideToggleModule,
    SkeletonComponent,
    ErrorStateComponent,
    EmptyStateComponent,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './products.html',
  styleUrl: './products.scss',
})
export class Products {
  private readonly catalog = inject(CatalogService);
  private readonly auth = inject(AuthService);
  private readonly dialog = inject(MatDialog);

  protected readonly isAdmin = this.auth.isAdmin;
  protected readonly loading = signal(true);
  protected readonly error = signal(false);
  private readonly products = signal<Product[]>([]);
  private readonly categories = signal<ProductCategory[]>([]);

  /** Productos agrupados por categoría (orden por DisplayOrder; oculta vacías para operador). */
  protected readonly groups = computed<Group[]>(() => {
    const cats = [...this.categories()].sort(
      (a, b) => a.displayOrder - b.displayOrder || a.name.localeCompare(b.name),
    );
    const byCat = new Map<string, Product[]>();
    for (const p of this.products()) {
      const list = byCat.get(p.categoryId) ?? [];
      list.push(p);
      byCat.set(p.categoryId, list);
    }
    const showEmpty = this.isAdmin();
    return cats
      .map((c) => ({
        category: c,
        products: (byCat.get(c.id) ?? []).sort((a, b) => a.name.localeCompare(b.name)),
      }))
      .filter((g) => showEmpty || g.products.length > 0);
  });

  constructor() {
    this.reload();
  }

  reload(): void {
    this.loading.set(true);
    this.error.set(false);
    forkJoin({
      products: this.catalog.products(false),
      categories: this.isAdmin() ? this.catalog.allCategories() : this.catalog.activeCategories(),
    }).subscribe({
      next: ({ products, categories }) => {
        this.products.set(products);
        this.categories.set(categories);
        this.loading.set(false);
      },
      error: () => {
        this.error.set(true);
        this.loading.set(false);
      },
    });
  }

  openProduct(product: Product | null): void {
    const data: ProductFormData = { product, categories: this.categories() };
    this.dialog
      .open(ProductFormDialog, { data, width: '420px' })
      .afterClosed()
      .subscribe((result) => result && this.reload());
  }

  openCategory(category: ProductCategory | null): void {
    this.dialog
      .open(CategoryFormDialog, { data: category, width: '420px' })
      .afterClosed()
      .subscribe((result) => result && this.reload());
  }

  toggleProduct(p: Product): void {
    this.catalog
      .updateProduct(p.id, {
        name: p.name,
        categoryId: p.categoryId,
        currentPrice: p.currentPrice,
        isActive: !p.isActive,
        imageUrl: p.imageUrl,
      })
      .subscribe({ next: () => this.reload() });
  }
}
