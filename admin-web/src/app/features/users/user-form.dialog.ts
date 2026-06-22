import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { MAT_DIALOG_DATA, MatDialogModule, MatDialogRef } from '@angular/material/dialog';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatButtonModule } from '@angular/material/button';
import { UsersService } from '../../core/api/users.service';
import type { AdminUser, CreateUserResult, Role } from '../../core/models/models';

export type UserFormResult =
  | { kind: 'created'; result: CreateUserResult }
  | { kind: 'updated'; user: AdminUser };

@Component({
  selector: 'app-user-form',
  imports: [
    ReactiveFormsModule,
    MatDialogModule,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
    MatButtonModule,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './user-form.dialog.html',
})
export class UserFormDialog {
  private readonly fb = inject(FormBuilder);
  private readonly users = inject(UsersService);
  private readonly ref = inject(MatDialogRef<UserFormDialog, UserFormResult>);
  protected readonly data = inject<AdminUser | null>(MAT_DIALOG_DATA);

  protected readonly saving = signal(false);
  protected readonly error = signal<string | null>(null);
  protected readonly isEdit = this.data !== null;

  protected readonly form = this.fb.nonNullable.group({
    name: [this.data?.name ?? '', [Validators.required, Validators.maxLength(120)]],
    email: [this.data?.email ?? '', [Validators.required, Validators.email]],
    role: [(this.data?.role ?? 'operator') as Role, Validators.required],
  });

  constructor() {
    if (this.isEdit) this.form.controls.email.disable();
  }

  save(): void {
    if (this.form.invalid || this.saving()) {
      this.form.markAllAsTouched();
      return;
    }
    this.saving.set(true);
    this.error.set(null);
    const { name, email, role } = this.form.getRawValue();

    if (this.isEdit) {
      this.users.update(this.data!.uid, { name, role }).subscribe({
        next: (user) => this.ref.close({ kind: 'updated', user }),
        error: (e) => this.fail(e),
      });
    } else {
      this.users.create(name, email, role).subscribe({
        next: (result) => this.ref.close({ kind: 'created', result }),
        error: (e) => this.fail(e),
      });
    }
  }

  private fail(e: { error?: { detail?: string } }): void {
    this.error.set(e?.error?.detail ?? 'No se pudo guardar el usuario.');
    this.saving.set(false);
  }

  cancel(): void {
    this.ref.close();
  }
}
