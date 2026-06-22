import { ChangeDetectionStrategy, Component, input } from '@angular/core';
import { MatIconModule } from '@angular/material/icon';

/**
 * Página base reutilizable mientras se construye cada módulo (Bloque 6).
 * Mantiene la estructura visual (título + tarjeta) para no romper la navegación.
 */
@Component({
  selector: 'app-placeholder',
  imports: [MatIconModule],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <section class="app-page">
      <h1 class="app-page__title">{{ title() }}</h1>
      <div class="card">
        <mat-icon>{{ icon() }}</mat-icon>
        <div>
          <p class="card__title">Módulo en construcción</p>
          <p class="card__desc">
            Esta sección se conectará con el backend en el siguiente bloque.
          </p>
        </div>
      </div>
    </section>
  `,
  styles: [
    `
      .card {
        display: flex;
        gap: var(--sp-4);
        align-items: center;
        background: var(--c-surface);
        border: 1px solid var(--c-border);
        border-radius: var(--r-lg);
        padding: var(--sp-5);
        box-shadow: var(--shadow-1);
      }
      mat-icon {
        font-size: 36px;
        width: 36px;
        height: 36px;
        color: var(--c-primary);
      }
      .card__title {
        font-weight: 600;
        margin: 0;
      }
      .card__desc {
        color: var(--c-muted);
        margin: 2px 0 0;
      }
    `,
  ],
})
export class Placeholder {
  readonly title = input('Sección');
  readonly icon = input('construction');
}
