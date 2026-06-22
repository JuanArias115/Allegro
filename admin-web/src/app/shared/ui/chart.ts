import {
  ChangeDetectionStrategy,
  Component,
  DestroyRef,
  ElementRef,
  afterNextRender,
  effect,
  inject,
  input,
  viewChild,
} from '@angular/core';
import * as echarts from 'echarts';

/** Envoltura ligera de Apache ECharts. Recibe la opción y redibuja de forma reactiva. */
@Component({
  selector: 'app-chart',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `<div #host class="chart"></div>`,
  styles: [
    `
      .chart {
        width: 100%;
        height: 300px;
      }
    `,
  ],
})
export class ChartComponent {
  readonly option = input.required<echarts.EChartsOption>();
  private readonly host = viewChild.required<ElementRef<HTMLDivElement>>('host');
  private chart?: echarts.ECharts;

  constructor() {
    const destroyRef = inject(DestroyRef);
    const onResize = () => this.chart?.resize();

    afterNextRender(() => {
      this.chart = echarts.init(this.host().nativeElement);
      this.chart.setOption(this.option());
      window.addEventListener('resize', onResize);
    });

    effect(() => {
      const opt = this.option();
      this.chart?.setOption(opt, true);
    });

    destroyRef.onDestroy(() => {
      window.removeEventListener('resize', onResize);
      this.chart?.dispose();
    });
  }
}
