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

let uid = 0;

/** Zone de texte multi-lignes — intégrée Signal Forms. */
@Component({
  selector: 'kz-textarea',
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
      <textarea
        [id]="id"
        [rows]="rows()"
        [value]="value()"
        [placeholder]="placeholder() ? (placeholder()! | translate) : ''"
        [disabled]="disabled()"
        [attr.aria-invalid]="showError() ? 'true' : null"
        [attr.aria-describedby]="showError() ? id + '-err' : null"
        [class]="textareaClasses()"
        (input)="onInput($event)"
        (blur)="touched.set(true)"
      ></textarea>
      @if (showError(); as err) {
        <p [id]="id + '-err'" class="text-xs text-red-600" role="alert">
          {{ err.key | translate: err.params }}
        </p>
      }
    </div>
  `,
})
export class TextareaComponent implements FormValueControl<string> {
  protected readonly id = `kz-textarea-${uid++}`;

  readonly value = model<string>('');
  readonly errors = input<readonly ValidationError.WithOptionalFieldTree[]>([]);
  readonly disabled = input<boolean>(false);
  readonly touched = model<boolean>(false);

  readonly label = input<string>();
  readonly placeholder = input<string>();
  readonly rows = input<number>(4);
  readonly requiredMark = input<boolean>(false);

  protected readonly showError = computed(() =>
    this.touched() ? firstErrorKey(this.errors() as unknown as UiValidationError[]) : null,
  );

  protected readonly textareaClasses = computed(() => {
    const base =
      'w-full rounded-lg border bg-white px-3 py-2 text-sm text-ink-900 placeholder:text-ink-400 ' +
      'transition-colors focus:outline-none focus:ring-2 focus:ring-offset-1 disabled:bg-ink-50 resize-y';
    const border = this.showError()
      ? 'border-red-400 focus:border-red-500 focus:ring-red-300'
      : 'border-ink-200 focus:border-ink-400 focus:ring-accent-300';
    return `${base} ${border}`;
  });

  protected onInput(event: Event): void {
    this.value.set((event.target as HTMLTextAreaElement).value);
  }
}
