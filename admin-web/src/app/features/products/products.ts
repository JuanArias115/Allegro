import { ChangeDetectionStrategy, Component } from '@angular/core';
import { Placeholder } from '../placeholder';

@Component({
  selector: 'app-products',
  imports: [Placeholder],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `<app-placeholder title="Productos y categorías" icon="sell" />`,
})
export class Products {}
