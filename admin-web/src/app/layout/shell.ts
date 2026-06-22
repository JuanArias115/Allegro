import { ChangeDetectionStrategy, Component, computed, inject } from '@angular/core';
import { Router, RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import { MatSidenavModule } from '@angular/material/sidenav';
import { MatToolbarModule } from '@angular/material/toolbar';
import { MatListModule } from '@angular/material/list';
import { MatIconModule } from '@angular/material/icon';
import { MatButtonModule } from '@angular/material/button';
import { MatMenuModule } from '@angular/material/menu';
import { BreakpointObserver, Breakpoints } from '@angular/cdk/layout';
import { toSignal } from '@angular/core/rxjs-interop';
import { map } from 'rxjs';
import { AuthService } from '../core/auth/auth.service';
import type { Role } from '../core/models/models';

interface NavItem {
  label: string;
  icon: string;
  path: string;
  /** Rol mínimo. 'operator' = visible para ambos; 'admin' = solo admin. */
  min: Role;
}

const NAV: NavItem[] = [
  { label: 'Dashboard', icon: 'dashboard', path: '/dashboard', min: 'operator' },
  { label: 'Calendario', icon: 'calendar_month', path: '/calendario', min: 'operator' },
  { label: 'Reservas', icon: 'event_note', path: '/reservas', min: 'operator' },
  { label: 'Domos', icon: 'cabin', path: '/domos', min: 'admin' },
  { label: 'Productos', icon: 'sell', path: '/productos', min: 'operator' },
  { label: 'Usuarios', icon: 'group', path: '/usuarios', min: 'admin' },
  { label: 'Reportes', icon: 'insights', path: '/reportes', min: 'admin' },
  { label: 'Configuración', icon: 'settings', path: '/configuracion', min: 'admin' },
];

@Component({
  selector: 'app-shell',
  imports: [
    RouterOutlet,
    RouterLink,
    RouterLinkActive,
    MatSidenavModule,
    MatToolbarModule,
    MatListModule,
    MatIconModule,
    MatButtonModule,
    MatMenuModule,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './shell.html',
  styleUrl: './shell.scss',
})
export class Shell {
  private readonly auth = inject(AuthService);
  private readonly router = inject(Router);
  private readonly breakpoints = inject(BreakpointObserver);

  protected readonly user = this.auth.user;
  protected readonly isAdmin = this.auth.isAdmin;

  protected readonly isHandset = toSignal(
    this.breakpoints
      .observe([Breakpoints.Handset, Breakpoints.TabletPortrait])
      .pipe(map((r) => r.matches)),
    { initialValue: false },
  );

  protected readonly items = computed(() =>
    NAV.filter((i) => this.isAdmin() || i.min === 'operator'),
  );

  protected readonly initials = computed(() => {
    const u = this.user();
    const base = u?.name || u?.email || '?';
    return base.trim().charAt(0).toUpperCase();
  });

  async logout(): Promise<void> {
    await this.auth.logout();
    await this.router.navigate(['/login']);
  }
}
