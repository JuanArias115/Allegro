import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { Router } from '@angular/router';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { AuthService } from '../../core/auth/auth.service';

@Component({
  selector: 'app-forbidden',
  imports: [MatButtonModule, MatIconModule],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div class="forbidden">
      <mat-icon>lock</mat-icon>
      <h1>Sin permisos</h1>
      <p>Tu cuenta no tiene acceso a esta sección. Si crees que es un error, contacta a un administrador.</p>
      <div class="forbidden__actions">
        <button mat-flat-button color="primary" (click)="goHome()">Ir al inicio</button>
        <button mat-stroked-button (click)="logout()">Cerrar sesión</button>
      </div>
    </div>
  `,
  styles: [
    `
      .forbidden {
        min-height: 100vh;
        display: grid;
        place-content: center;
        justify-items: center;
        text-align: center;
        gap: var(--sp-2);
        padding: var(--sp-5);
      }
      mat-icon {
        font-size: 56px;
        width: 56px;
        height: 56px;
        color: var(--c-primary);
      }
      h1 {
        margin: var(--sp-2) 0 0;
      }
      p {
        color: var(--c-muted);
        max-width: 420px;
      }
      .forbidden__actions {
        display: flex;
        gap: var(--sp-3);
        margin-top: var(--sp-3);
      }
    `,
  ],
})
export class Forbidden {
  private readonly auth = inject(AuthService);
  private readonly router = inject(Router);

  goHome(): void {
    void this.router.navigate(['/dashboard']);
  }
  async logout(): Promise<void> {
    await this.auth.logout();
    await this.router.navigate(['/login']);
  }
}
