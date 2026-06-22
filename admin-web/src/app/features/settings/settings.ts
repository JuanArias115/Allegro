import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { MatIconModule } from '@angular/material/icon';
import { AuthService } from '../../core/auth/auth.service';
import { runtimeConfig } from '../../core/config/runtime-config';

@Component({
  selector: 'app-settings',
  imports: [MatIconModule],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './settings.html',
  styleUrl: './settings.scss',
})
export class Settings {
  private readonly auth = inject(AuthService);
  protected readonly user = this.auth.user;
  protected readonly apiBaseUrl = runtimeConfig.apiBaseUrl;
  protected readonly firebaseProject = runtimeConfig.firebase.projectId;
}
