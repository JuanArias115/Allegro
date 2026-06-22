import { ChangeDetectionStrategy, Component, input, output } from '@angular/core';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';

/** Skeleton de carga: bloques animados. `rows` controla cuántas líneas. */
@Component({
  selector: 'app-skeleton',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div class="sk" [style.height.px]="height()"></div>
    @for (r of rowsArray(); track r) {
      <div class="sk sk--row"></div>
    }
  `,
  styles: [
    `
      :host {
        display: block;
      }
      .sk {
        background: linear-gradient(90deg, #eee 25%, #f5f5f5 37%, #eee 63%);
        background-size: 400% 100%;
        animation: shimmer 1.3s ease infinite;
        border-radius: var(--r-sm);
      }
      .sk--row {
        height: 14px;
        margin-top: var(--sp-3);
      }
      @keyframes shimmer {
        0% {
          background-position: 100% 0;
        }
        100% {
          background-position: -100% 0;
        }
      }
    `,
  ],
})
export class SkeletonComponent {
  readonly height = input(120);
  readonly rows = input(0);
  protected rowsArray(): number[] {
    return Array.from({ length: this.rows() }, (_, i) => i);
  }
}

/** Estado vacío trabajado: icono, título y descripción. */
@Component({
  selector: 'app-empty-state',
  imports: [MatIconModule],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div class="empty">
      <mat-icon>{{ icon() }}</mat-icon>
      <p class="empty__title">{{ title() }}</p>
      @if (description()) {
        <p class="empty__desc">{{ description() }}</p>
      }
    </div>
  `,
  styles: [
    `
      .empty {
        text-align: center;
        padding: var(--sp-6) var(--sp-4);
        color: var(--c-muted);
      }
      mat-icon {
        font-size: 40px;
        width: 40px;
        height: 40px;
        color: var(--c-primary);
        opacity: 0.7;
      }
      .empty__title {
        font-weight: 600;
        color: var(--c-ink);
        margin: var(--sp-3) 0 var(--sp-1);
      }
      .empty__desc {
        margin: 0;
        font-size: 0.9rem;
      }
    `,
  ],
})
export class EmptyStateComponent {
  readonly icon = input('inbox');
  readonly title = input('No hay datos');
  readonly description = input<string | null>(null);
}

/** Estado de error con opción de reintentar. */
@Component({
  selector: 'app-error-state',
  imports: [MatIconModule, MatButtonModule],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div class="err">
      <mat-icon>error_outline</mat-icon>
      <p class="err__title">{{ title() }}</p>
      @if (description()) {
        <p class="err__desc">{{ description() }}</p>
      }
      <button mat-stroked-button (click)="retry.emit()">Reintentar</button>
    </div>
  `,
  styles: [
    `
      .err {
        text-align: center;
        padding: var(--sp-6) var(--sp-4);
        color: var(--c-muted);
      }
      mat-icon {
        font-size: 40px;
        width: 40px;
        height: 40px;
        color: var(--c-danger);
      }
      .err__title {
        font-weight: 600;
        color: var(--c-ink);
        margin: var(--sp-3) 0 var(--sp-1);
      }
      .err__desc {
        margin: 0 0 var(--sp-4);
        font-size: 0.9rem;
      }
    `,
  ],
})
export class ErrorStateComponent {
  readonly title = input('Ocurrió un error');
  readonly description = input<string | null>('No se pudo cargar la información.');
  readonly retry = output<void>();
}
