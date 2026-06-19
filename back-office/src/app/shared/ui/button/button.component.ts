import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';
import type { ButtonSize, ButtonType, ButtonVariant } from './button.types';

const BASE =
  'inline-flex items-center justify-center gap-2 font-medium rounded-lg transition-colors ' +
  'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accent-500 focus-visible:ring-offset-2 ' +
  'disabled:opacity-50 disabled:cursor-not-allowed select-none whitespace-nowrap';

const VARIANTS: Record<ButtonVariant, string> = {
  primary: 'bg-ink-950 text-white hover:bg-ink-800 active:bg-ink-900',
  secondary: 'bg-ink-100 text-ink-900 hover:bg-ink-200 active:bg-ink-300',
  ghost: 'bg-transparent text-ink-700 hover:bg-ink-100',
  outline: 'bg-white text-ink-900 border border-ink-200 hover:bg-ink-50',
  danger: 'bg-red-600 text-white hover:bg-red-700 active:bg-red-800',
};

const SIZES: Record<ButtonSize, string> = {
  sm: 'h-8 px-3 text-sm',
  md: 'h-10 px-4 text-sm',
  lg: 'h-12 px-6 text-base',
};

@Component({
  selector: 'kz-button',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <button
      [type]="type()"
      [disabled]="disabled() || loading()"
      [class]="classes()"
      [attr.aria-busy]="loading() ? 'true' : null"
    >
      @if (loading()) {
        <svg
          class="h-4 w-4 animate-spin"
          viewBox="0 0 24 24"
          fill="none"
          aria-hidden="true"
        >
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v4a4 4 0 00-4 4H4z"></path>
        </svg>
      }
      <ng-content />
    </button>
  `,
})
export class ButtonComponent {
  readonly variant = input<ButtonVariant>('primary');
  readonly size = input<ButtonSize>('md');
  readonly type = input<ButtonType>('button');
  readonly disabled = input<boolean>(false);
  readonly loading = input<boolean>(false);
  readonly block = input<boolean>(false);

  protected readonly classes = computed(() =>
    [BASE, VARIANTS[this.variant()], SIZES[this.size()], this.block() ? 'w-full' : ''].join(' '),
  );
}
