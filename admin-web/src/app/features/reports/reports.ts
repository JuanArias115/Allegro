import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { CurrencyPipe } from '@angular/common';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { forkJoin } from 'rxjs';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import type { EChartsOption } from 'echarts';
import { ReportsService } from '../../core/api/reports.service';
import { monthRange } from '../../core/util/dates';
import { KpiCardComponent } from '../../shared/ui/kpi-card';
import { ChartComponent } from '../../shared/ui/chart';
import { SkeletonComponent, ErrorStateComponent } from '../../shared/ui/ui-states';
import type {
  OccupancyReport,
  PaymentsReport,
  ProductsReport,
  ReportSummary,
} from '../../core/models/models';

@Component({
  selector: 'app-reports',
  imports: [
    CurrencyPipe,
    ReactiveFormsModule,
    MatFormFieldModule,
    MatInputModule,
    MatButtonModule,
    MatIconModule,
    KpiCardComponent,
    ChartComponent,
    SkeletonComponent,
    ErrorStateComponent,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './reports.html',
  styleUrl: './reports.scss',
})
export class Reports {
  private readonly fb = inject(FormBuilder);
  private readonly api = inject(ReportsService);

  protected readonly loading = signal(false);
  protected readonly error = signal(false);
  protected readonly summary = signal<ReportSummary | null>(null);
  protected readonly occupancy = signal<OccupancyReport | null>(null);
  protected readonly payments = signal<PaymentsReport | null>(null);
  protected readonly products = signal<ProductsReport | null>(null);

  private readonly defaults = monthRange();
  protected readonly form = this.fb.nonNullable.group({
    from: [this.defaults.from, Validators.required],
    to: [this.defaults.to, Validators.required],
  });

  protected readonly occupancyChart = computed<EChartsOption>(() => {
    const occ = this.occupancy();
    const domes = occ?.domes ?? [];
    return {
      tooltip: { trigger: 'axis' },
      grid: { left: 40, right: 16, top: 24, bottom: 28 },
      xAxis: { type: 'category', data: domes.map((d) => d.domeName) },
      yAxis: { type: 'value', max: 100, axisLabel: { formatter: '{value}%' } },
      series: [
        {
          type: 'bar',
          data: domes.map((d) => +(d.occupancyRate * 100).toFixed(1)),
          itemStyle: { color: '#6a3df0', borderRadius: [6, 6, 0, 0] },
        },
      ],
    };
  });

  protected readonly paymentsChart = computed<EChartsOption>(() => {
    const pay = this.payments();
    const days = pay?.byDay ?? [];
    return {
      tooltip: { trigger: 'axis' },
      grid: { left: 60, right: 16, top: 24, bottom: 28 },
      xAxis: { type: 'category', data: days.map((d) => d.date) },
      yAxis: { type: 'value' },
      series: [
        {
          type: 'line',
          smooth: true,
          areaStyle: { color: 'rgba(31,170,107,0.15)' },
          lineStyle: { color: '#1faa6b' },
          itemStyle: { color: '#1faa6b' },
          data: days.map((d) => d.amount),
        },
      ],
    };
  });

  constructor() {
    this.run();
  }

  run(): void {
    if (this.form.invalid) return;
    const { from, to } = this.form.getRawValue();
    if (to <= from) {
      this.error.set(true);
      return;
    }
    this.loading.set(true);
    this.error.set(false);
    forkJoin({
      summary: this.api.summary(from, to),
      occupancy: this.api.occupancy(from, to),
      payments: this.api.payments(from, to),
      products: this.api.products(from, to),
    }).subscribe({
      next: (r) => {
        this.summary.set(r.summary);
        this.occupancy.set(r.occupancy);
        this.payments.set(r.payments);
        this.products.set(r.products);
        this.loading.set(false);
      },
      error: () => {
        this.error.set(true);
        this.loading.set(false);
      },
    });
  }

  exportCsv(): void {
    const { from, to } = this.form.getRawValue();
    this.api.exportCsv(from, to).subscribe((blob) => {
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `reporte_${from}_${to}.csv`;
      a.click();
      URL.revokeObjectURL(url);
    });
  }
}
