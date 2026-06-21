import { ChangeDetectionStrategy, Component } from '@angular/core';
import { Placeholder } from '../placeholder';

@Component({
  selector: 'app-users',
  imports: [Placeholder],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `<app-placeholder title="Usuarios" icon="group" />`,
})
export class Users {}
