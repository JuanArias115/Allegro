import { ChangeDetectionStrategy, Component, input } from '@angular/core';
import { MatIconModule } from '@angular/material/icon';

type Tone = 'primary' | 'success' | 'warning' | 'danger' | 'info';

/** Tarjeta de indicador con jerarquía visual clara (icono + valor + etiqueta). */
@Component({
  selector: 'app-kpi-card',
  imports: [MatIconModule],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div class="kpi" [class]="'kpi--' + tone()">
      <div class="kpi__icon"><mat-icon>{{ icon() }}</mat-icon></div>
      <div class="kpi__body">
        <div class="kpi__value">{{ value() }}</div>
        <div class="kpi__label">{{ label() }}</div>
        @if (hint()) {
          <div class="kpi__hint">{{ hint() }}</div>
        }
      </div>
    </div>
  `,
  styles: [
    `
      .kpi {
        display: flex;
        gap: var(--sp-3);
        align-items: center;
        background: var(--c-surface);
        border: 1px solid var(--c-border);
        border-radius: var(--r-lg);
        padding: var(--sp-4);
        box-shadow: var(--shadow-1);
      }
      .kpi__icon {
        width: 44px;
        height: 44px;
        border-radius: var(--r-md);
        display: grid;
        place-items: center;
        flex: none;
      }
      .kpi__icon mat-icon {
        color: #fff;
      }
      .kpi--primary .kpi__icon {
        background: var(--c-primary);
      }
      .kpi--success .kpi__icon {
        background: var(--c-success);
      }
      .kpi--warning .kpi__icon {
        background: var(--c-warning);
      }
      .kpi--danger .kpi__icon {
        background: var(--c-danger);
      }
      .kpi--info .kpi__icon {
        background: var(--c-info);
      }
      .kpi__value {
        font-size: 1.5rem;
        font-weight: 800;
        line-height: 1.1;
      }
      .kpi__label {
        color: var(--c-ink-soft);
        font-size: 0.85rem;
        margin-top: 2px;
      }
      .kpi__hint {
        color: var(--c-muted);
        font-size: 0.78rem;
        margin-top: 2px;
      }
    `,
  ],
})
export class KpiCardComponent {
  readonly icon = input('insights');
  readonly value = input<string | number | null>('—');
  readonly label = input('');
  readonly hint = input<string | null>(null);
  readonly tone = input<Tone>('primary');
}
