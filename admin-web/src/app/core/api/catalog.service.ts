import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService } from './api.service';
import type { Dome, Product, ProductCategory } from '../models/models';

export interface UpsertDome {
  name: string;
  shortDescription: string;
  maxCapacity: number;
  isActive: boolean;
}

export interface UpsertProduct {
  name: string;
  categoryId: string;
  currentPrice: number;
  isActive: boolean;
  imageUrl: string | null;
}

export interface UpsertCategory {
  name: string;
  displayOrder: number;
  isActive: boolean;
}

@Injectable({ providedIn: 'root' })
export class CatalogService {
  private readonly api = inject(ApiService);

  // ----- Domos -----
  domes(onlyActive = false): Observable<Dome[]> {
    return this.api.get<Dome[]>('/api/domes', { onlyActive });
  }
  updateDome(id: string, body: UpsertDome): Observable<Dome> {
    return this.api.put<Dome>(`/api/domes/${id}`, body);
  }

  // ----- Productos -----
  products(onlyActive = false): Observable<Product[]> {
    return this.api.get<Product[]>('/api/products', { onlyActive });
  }
  createProduct(body: UpsertProduct): Observable<Product> {
    return this.api.post<Product>('/api/products', body);
  }
  updateProduct(id: string, body: UpsertProduct): Observable<Product> {
    return this.api.put<Product>(`/api/products/${id}`, body);
  }

  // ----- Categorías -----
  activeCategories(): Observable<ProductCategory[]> {
    return this.api.get<ProductCategory[]>('/api/product-categories');
  }
  allCategories(): Observable<ProductCategory[]> {
    return this.api.get<ProductCategory[]>('/api/admin/product-categories');
  }
  createCategory(body: UpsertCategory): Observable<ProductCategory> {
    return this.api.post<ProductCategory>('/api/admin/product-categories', body);
  }
  updateCategory(id: string, body: UpsertCategory): Observable<ProductCategory> {
    return this.api.put<ProductCategory>(`/api/admin/product-categories/${id}`, body);
  }
}
