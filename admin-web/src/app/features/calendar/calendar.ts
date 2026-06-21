import { ChangeDetectionStrategy, Component } from '@angular/core';
import { Placeholder } from '../placeholder';

@Component({
  selector: 'app-calendar',
  imports: [Placeholder],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `<app-placeholder title="Calendario" icon="calendar_month" />`,
})
export class Calendar {}
