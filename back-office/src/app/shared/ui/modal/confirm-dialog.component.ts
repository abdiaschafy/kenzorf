import { ChangeDetectionStrategy, Component, input, output } from '@angular/core';
import { TranslatePipe } from '@app/core/services/i18n/translate.pipe';
import { ButtonComponent } from '@app/shared/ui/button/button.component';
import { ModalComponent } from './modal.component';

/** Boîte de confirmation (suppression…) avec titre/message i18n et action destructive. */
@Component({
  selector: 'kz-confirm-dialog',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [TranslatePipe, ButtonComponent, ModalComponent],
  template: `
    <kz-modal [open]="open()" [titleKey]="titleKey()" (closed)="cancelled.emit()">
      <p class="text-sm text-ink-600">{{ messageKey() | translate: messageParams() }}</p>
      <ng-container modal-footer>
        <kz-button variant="outline" (click)="cancelled.emit()">
          {{ 'common.cancel' | translate }}
        </kz-button>
        <kz-button [variant]="danger() ? 'danger' : 'primary'" [loading]="loading()" (click)="confirmed.emit()">
          {{ confirmKey() | translate }}
        </kz-button>
      </ng-container>
    </kz-modal>
  `,
})
export class ConfirmDialogComponent {
  readonly open = input.required<boolean>();
  readonly titleKey = input<string>('common.confirm');
  readonly messageKey = input.required<string>();
  readonly messageParams = input<Record<string, string | number>>({});
  readonly confirmKey = input<string>('common.confirm');
  readonly danger = input<boolean>(false);
  readonly loading = input<boolean>(false);

  readonly confirmed = output<void>();
  readonly cancelled = output<void>();
}
