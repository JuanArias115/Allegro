import { ChangeDetectionStrategy, Component } from '@angular/core';
import { Placeholder } from '../placeholder';

@Component({
  selector: 'app-reservations',
  imports: [Placeholder],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `<app-placeholder title="Reservas" icon="event_note" />`,
})
export class Reservations {}
