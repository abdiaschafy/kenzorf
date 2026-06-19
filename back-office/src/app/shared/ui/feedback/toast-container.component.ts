import { ChangeDetectionStrategy, Component, computed, inject } from '@angular/core';
import { NotificationService } from '@app/core/services/notification.service';
import { TranslatePipe } from '@app/core/services/i18n/translate.pipe';
import type { ToastTone } from '@app/core/interfaces/notification.interfaces';

const TONE_CLASSES: Record<ToastTone, string> = {
  success: 'border-emerald-200 bg-emerald-50 text-emerald-800',
  error: 'border-red-200 bg-red-50 text-red-800',
  info: 'border-ink-200 bg-white text-ink-800',
};

/** Pile de notifications toast (coin bas-droite). Lit la file du NotificationService. */
@Component({
  selector: 'kz-toast-container',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [TranslatePipe],
  template: `
    <div class="pointer-events-none fixed bottom-4 right-4 z-[60] flex w-full max-w-sm flex-col gap-2">
      @for (toast of toasts(); track toast.id) {
        <div
          class="pointer-events-auto flex items-start justify-between gap-3 rounded-lg border px-4 py-3 shadow-elevated"
          [class]="toneClass(toast.tone)"
          role="status"
        >
          <p class="text-sm font-medium">{{ toast.messageKey | translate: (toast.params ?? {}) }}</p>
          <button
            type="button"
            class="text-current opacity-60 hover:opacity-100"
            [attr.aria-label]="'common.close' | translate"
            (click)="dismiss(toast.id)"
          >
            <svg class="h-4 w-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
              <path stroke-linecap="round" d="M6 6l12 12M18 6L6 18" />
            </svg>
          </button>
        </div>
      }
    </div>
  `,
})
export class ToastContainerComponent {
  private readonly notifications = inject(NotificationService);
  protected readonly toasts = computed(() => this.notifications.toasts());

  protected toneClass(tone: ToastTone): string {
    return TONE_CLASSES[tone];
  }

  protected dismiss(id: number): void {
    this.notifications.dismiss(id);
  }
}
