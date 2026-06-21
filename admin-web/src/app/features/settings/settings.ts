import { ChangeDetectionStrategy, Component } from '@angular/core';
import { Placeholder } from '../placeholder';

@Component({
  selector: 'app-settings',
  imports: [Placeholder],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `<app-placeholder title="Configuración" icon="settings" />`,
})
export class Settings {}
