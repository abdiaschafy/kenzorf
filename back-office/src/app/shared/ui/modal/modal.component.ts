import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  effect,
  inject,
  input,
  output,
} from '@angular/core';
import { TranslatePipe } from '@app/core/services/i18n/translate.pipe';

/**
 * Modale générique pilotée par `open` (signal).
 * Slots : contenu par défaut + `[modal-footer]`. Émet `closed` au backdrop/Escape.
 */
@Component({
  selector: 'kz-modal',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [TranslatePipe],
  template: `
    @if (open()) {
      <div
        class="fixed inset-0 z-50 flex items-center justify-center p-4"
        role="dialog"
        aria-modal="true"
        [attr.aria-label]="titleKey() ? (titleKey()! | translate) : null"
        (keydown.escape)="closed.emit()"
      >
        <div
          class="absolute inset-0 bg-ink-950/40 backdrop-blur-sm"
          (click)="closed.emit()"
          aria-hidden="true"
        ></div>
        <div
          class="relative z-10 w-full max-w-lg rounded-xl bg-white shadow-elevated"
          (click)="$event.stopPropagation()"
        >
          @if (titleKey()) {
            <header class="border-b border-ink-100 px-5 py-4">
              <h2 class="text-base font-semibold text-ink-900">{{ titleKey()! | translate }}</h2>
            </header>
          }
          <div class="px-5 py-4">
            <ng-content />
          </div>
          <footer class="flex justify-end gap-2 border-t border-ink-100 px-5 py-4">
            <ng-content select="[modal-footer]" />
          </footer>
        </div>
      </div>
    }
  `,
})
export class ModalComponent {
  private readonly host: ElementRef<HTMLElement> = inject(ElementRef);

  readonly open = input.required<boolean>();
  readonly titleKey = input<string>();
  readonly closed = output<void>();

  constructor() {
    effect(() => {
      const isOpen = this.open();
      if (isOpen) {
        queueMicrotask(() => {
          const root = this.host.nativeElement;
          const focusable = root.querySelector<HTMLElement>('button, [href], input, select, textarea');
          focusable?.focus();
        });
      }
    });
  }
}
