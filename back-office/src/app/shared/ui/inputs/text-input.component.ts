import {
  ChangeDetectionStrategy,
  Component,
  computed,
  input,
  model,
} from '@angular/core';
import type { FormValueControl, ValidationError } from '@angular/forms/signals';
import { TranslatePipe } from '@app/core/services/i18n/translate.pipe';
import { firstErrorKey, type UiValidationError } from '@app/core/utils/validation-error.util';
import type { TextInputType } from './input.types';

let uid = 0;

/**
 * Champ texte du kit — intégré Signal Forms via `FormValueControl<string>`.
 * Usage : `<kz-text-input [formField]="form.email" label="…" />`.
 */
@Component({
  selector: 'kz-text-input',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [TranslatePipe],
  template: `
    <div class="flex flex-col gap-1.5">
      @if (label()) {
        <label [for]="id" class="text-sm font-medium text-ink-700">
          {{ label()! | translate }}
          @if (requiredMark()) {
            <span class="text-red-500" aria-hidden="true">*</span>
          }
        </label>
      }
      <input
        [id]="id"
        [type]="type()"
        [value]="value()"
        [placeholder]="placeholder() ? (placeholder()! | translate) : ''"
        [disabled]="disabled()"
        [attr.autocomplete]="autocomplete()"
        [attr.aria-invalid]="showError() ? 'true' : null"
        [attr.aria-describedby]="showError() ? id + '-err' : null"
        [class]="inputClasses()"
        (input)="onInput($event)"
        (blur)="touched.set(true)"
      />
      @if (showError(); as err) {
        <p [id]="id + '-err'" class="text-xs text-red-600" role="alert">
          {{ err.key | translate: err.params }}
        </p>
      } @else if (hint()) {
        <p class="text-xs text-ink-400">{{ hint()! | translate }}</p>
      }
    </div>
  `,
})
export class TextInputComponent implements FormValueControl<string> {
  protected readonly id = `kz-input-${uid++}`;

  // FormValueControl contract
  readonly value = model<string>('');
  readonly errors = input<readonly ValidationError.WithOptionalFieldTree[]>([]);
  readonly disabled = input<boolean>(false);
  readonly touched = model<boolean>(false);

  // UI options
  readonly label = input<string>();
  readonly placeholder = input<string>();
  readonly hint = input<string>();
  readonly type = input<TextInputType>('text');
  readonly autocomplete = input<string>('off');
  readonly requiredMark = input<boolean>(false);

  protected readonly showError = computed(() => {
    if (!this.touched()) {
      return null;
    }
    return firstErrorKey(this.errors() as unknown as UiValidationError[]);
  });

  protected readonly inputClasses = computed(() => {
    const base =
      'h-10 w-full rounded-lg border bg-white px-3 text-sm text-ink-900 placeholder:text-ink-400 ' +
      'transition-colors focus:outline-none focus:ring-2 focus:ring-offset-1 disabled:bg-ink-50 disabled:text-ink-400';
    const border = this.showError()
      ? 'border-red-400 focus:border-red-500 focus:ring-red-300'
      : 'border-ink-200 focus:border-ink-400 focus:ring-accent-300';
    return `${base} ${border}`;
  });

  protected onInput(event: Event): void {
    this.value.set((event.target as HTMLInputElement).value);
  }
}
