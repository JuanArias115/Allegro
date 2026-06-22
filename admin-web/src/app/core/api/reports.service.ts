import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService } from './api.service';
import type {
  OccupancyReport,
  PaymentsReport,
  ProductsReport,
  ReportSummary,
} from '../models/models';

@Injectable({ providedIn: 'root' })
export class ReportsService {
  private readonly api = inject(ApiService);

  summary(from: string, to: string): Observable<ReportSummary> {
    return this.api.get<ReportSummary>('/api/admin/reports/summary', { from, to });
  }

  occupancy(from: string, to: string): Observable<OccupancyReport> {
    return this.api.get<OccupancyReport>('/api/admin/reports/occupancy', { from, to });
  }

  payments(from: string, to: string): Observable<PaymentsReport> {
    return this.api.get<PaymentsReport>('/api/admin/reports/payments', { from, to });
  }

  products(from: string, to: string): Observable<ProductsReport> {
    return this.api.get<ProductsReport>('/api/admin/reports/products', { from, to });
  }

  exportCsv(from: string, to: string): Observable<Blob> {
    return this.api.getBlob('/api/admin/reports/export.csv', { from, to });
  }
}
