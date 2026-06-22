import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { MAT_DIALOG_DATA, MatDialogModule } from '@angular/material/dialog';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';

export interface ActivationLinkData {
  name: string | null;
  link: string;
}

/** Muestra el enlace de activación UNA vez para copiarlo y enviarlo (WhatsApp/correo). */
@Component({
  selector: 'app-activation-link',
  imports: [MatDialogModule, MatButtonModule, MatIconModule],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <h2 mat-dialog-title>Enlace de activación</h2>
    <mat-dialog-content>
      <p>
        Comparte este enlace con <strong>{{ data.name || 'el usuario' }}</strong> para que
        establezca su contraseña. Solo se muestra ahora; podrás regenerarlo después.
      </p>
      <div class="link">
        <code>{{ data.link }}</code>
        <button mat-icon-button (click)="copy()" aria-label="Copiar">
          <mat-icon>{{ copied() ? 'check' : 'content_copy' }}</mat-icon>
        </button>
      </div>
      @if (copied()) {
        <p class="ok">Enlace copiado.</p>
      }
    </mat-dialog-content>
    <mat-dialog-actions align="end">
      <button mat-flat-button color="primary" mat-dialog-close>Listo</button>
    </mat-dialog-actions>
  `,
  styles: [
    `
      .link {
        display: flex;
        align-items: center;
        gap: var(--sp-2);
        background: var(--c-surface-2);
        border: 1px solid var(--c-border);
        border-radius: var(--r-sm);
        padding: var(--sp-2) var(--sp-3);
      }
      code {
        flex: 1;
        word-break: break-all;
        font-size: 0.82rem;
      }
      .ok {
        color: var(--c-success);
        font-size: 0.85rem;
        margin: var(--sp-2) 0 0;
      }
    `,
  ],
})
export class ActivationLinkDialog {
  protected readonly data = inject<ActivationLinkData>(MAT_DIALOG_DATA);
  protected readonly copied = signal(false);

  copy(): void {
    void navigator.clipboard?.writeText(this.data.link).then(() => this.copied.set(true));
  }
}
