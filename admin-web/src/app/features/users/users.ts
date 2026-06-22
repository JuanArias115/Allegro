import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { DatePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatMenuModule } from '@angular/material/menu';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatDialog } from '@angular/material/dialog';
import { UsersService } from '../../core/api/users.service';
import { ConfirmService } from '../../shared/ui/confirm.dialog';
import { SkeletonComponent, ErrorStateComponent, EmptyStateComponent } from '../../shared/ui/ui-states';
import { UserFormDialog, type UserFormResult } from './user-form.dialog';
import { ActivationLinkDialog } from './activation-link.dialog';
import type { AdminUser } from '../../core/models/models';

@Component({
  selector: 'app-users',
  imports: [
    DatePipe,
    FormsModule,
    MatButtonModule,
    MatIconModule,
    MatMenuModule,
    MatFormFieldModule,
    MatInputModule,
    SkeletonComponent,
    ErrorStateComponent,
    EmptyStateComponent,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './users.html',
  styleUrl: './users.scss',
})
export class Users {
  private readonly api = inject(UsersService);
  private readonly dialog = inject(MatDialog);
  private readonly confirm = inject(ConfirmService);

  protected readonly loading = signal(false);
  protected readonly error = signal(false);
  protected readonly users = signal<AdminUser[]>([]);
  protected readonly nextPageToken = signal<string | null>(null);
  protected query = '';

  constructor() {
    this.search();
  }

  search(): void {
    this.loading.set(true);
    this.error.set(false);
    this.api.list(this.query || undefined, undefined, 25).subscribe({
      next: (page) => {
        this.users.set(page.items);
        this.nextPageToken.set(page.nextPageToken);
        this.loading.set(false);
      },
      error: () => {
        this.error.set(true);
        this.loading.set(false);
      },
    });
  }

  loadMore(): void {
    const token = this.nextPageToken();
    if (!token) return;
    this.api.list(this.query || undefined, token, 25).subscribe({
      next: (page) => {
        this.users.update((cur) => [...cur, ...page.items]);
        this.nextPageToken.set(page.nextPageToken);
      },
    });
  }

  maskUid(uid: string): string {
    return uid.length <= 8 ? uid : `${uid.slice(0, 6)}…${uid.slice(-2)}`;
  }

  create(): void {
    this.dialog
      .open(UserFormDialog, { data: null, width: '440px' })
      .afterClosed()
      .subscribe((r: UserFormResult | undefined) => {
        if (r?.kind === 'created') {
          this.showLink(r.result.user.name, r.result.activationLink);
          this.search();
        }
      });
  }

  edit(user: AdminUser): void {
    this.dialog
      .open(UserFormDialog, { data: user, width: '440px' })
      .afterClosed()
      .subscribe((r: UserFormResult | undefined) => r && this.search());
  }

  toggleStatus(user: AdminUser): void {
    const disabling = !user.disabled;
    this.confirm
      .ask({
        title: disabling ? 'Bloquear usuario' : 'Reactivar usuario',
        message: disabling
          ? `¿Bloquear a ${user.email}? No podrá iniciar sesión hasta reactivarlo.`
          : `¿Reactivar a ${user.email}?`,
        confirmText: disabling ? 'Bloquear' : 'Reactivar',
        danger: disabling,
      })
      .subscribe((ok) => {
        if (!ok) return;
        this.api.setStatus(user.uid, disabling).subscribe({
          next: () => this.search(),
          error: (e) => alert(e?.error?.detail ?? 'No se pudo cambiar el estado.'),
        });
      });
  }

  revokeSessions(user: AdminUser): void {
    this.confirm
      .ask({
        title: 'Revocar sesiones',
        message: `¿Cerrar todas las sesiones activas de ${user.email}?`,
        confirmText: 'Revocar',
        danger: true,
      })
      .subscribe((ok) => {
        if (ok) this.api.revokeSessions(user.uid).subscribe();
      });
  }

  regenerateLink(user: AdminUser): void {
    this.api.activationLink(user.uid).subscribe({
      next: (r) => this.showLink(user.name, r.activationLink),
      error: (e) => alert(e?.error?.detail ?? 'No se pudo generar el enlace.'),
    });
  }

  private showLink(name: string | null, link: string): void {
    this.dialog.open(ActivationLinkDialog, { data: { name, link }, width: '460px' });
  }
}
