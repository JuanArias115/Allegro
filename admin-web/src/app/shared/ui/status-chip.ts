import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';
import type { ReservationStatus } from '../../core/models/models';

const LABELS: Record<ReservationStatus, string> = {
  Confirmed: 'Confirmada',
  CheckedIn: 'Hospedada',
  Completed: 'Finalizada',
  Cancelled: 'Cancelada',
};

/** Etiqueta visual del estado de una reserva. */
@Component({
  selector: 'app-status-chip',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `<span class="chip" [class]="'chip--' + status().toLowerCase()">{{ label() }}</span>`,
  styles: [
    `
      .chip {
        display: inline-block;
        padding: 2px 10px;
        border-radius: 999px;
        font-size: 0.78rem;
        font-weight: 600;
        line-height: 1.5;
      }
      .chip--confirmed {
        background: var(--c-info-weak);
        color: var(--c-info);
      }
      .chip--checkedin {
        background: var(--c-success-weak);
        color: var(--c-success);
      }
      .chip--completed {
        background: #eee;
        color: var(--c-completed);
      }
      .chip--cancelled {
        background: var(--c-danger-weak);
        color: var(--c-danger);
      }
    `,
  ],
})
export class StatusChipComponent {
  readonly status = input.required<ReservationStatus>();
  protected readonly label = computed(() => LABELS[this.status()]);
}
