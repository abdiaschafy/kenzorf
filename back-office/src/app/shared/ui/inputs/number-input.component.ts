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

/** Champ numérique — intégré Signal Forms via `FormValueControl<number | null>`. */
@Component({
  selector: 'kz-number-input',
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
      <div class="relative">
        <input
          [id]="id"
          type="number"
          [value]="value() ?? ''"
          [min]="minValue()"
          [step]="step()"
          [placeholder]="placeholder() ? (placeholder()! | translate) : ''"
          [disabled]="disabled()"
          [attr.aria-invalid]="showError() ? 'true' : null"
          [class]="inputClasses()"
          (input)="onInput($event)"
          (blur)="touched.set(true)"
        />
        @if (suffix()) {
          <span class="pointer-events-none absolute inset-y-0 right-3 flex items-center text-xs text-ink-400">
            {{ suffix() }}
          </span>
        }
      </div>
      @if (showError(); as err) {
        <p class="text-xs text-red-600" role="alert">{{ err.key | translate: err.params }}</p>
      }
    </div>
  `,
})
export class NumberInputComponent implements FormValueControl<number | null> {
  protected readonly id = `kz-number-${uid++}`;

  readonly value = model<number | null>(null);
  readonly errors = input<readonly ValidationError.WithOptionalFieldTree[]>([]);
  readonly disabled = input<boolean>(false);
  readonly touched = model<boolean>(false);

  readonly label = input<string>();
  readonly placeholder = input<string>();
  readonly minValue = input<number>(0);
  readonly step = input<number>(1);
  readonly suffix = input<string>();
  readonly requiredMark = input<boolean>(false);

  protected readonly showError = computed(() =>
    this.touched() ? firstErrorKey(this.errors() as unknown as UiValidationError[]) : null,
  );

  protected readonly inputClasses = computed(() => {
    const base =
      'h-10 w-full rounded-lg border bg-white px-3 text-sm text-ink-900 placeholder:text-ink-400 ' +
      'transition-colors focus:outline-none focus:ring-2 focus:ring-offset-1 disabled:bg-ink-50';
    const border = this.showError()
      ? 'border-red-400 focus:border-red-500 focus:ring-red-300'
      : 'border-ink-200 focus:border-ink-400 focus:ring-accent-300';
    return `${base} ${border} ${this.suffix() ? 'pr-12' : ''}`;
  });

  protected onInput(event: Event): void {
    const raw = (event.target as HTMLInputElement).value;
    this.value.set(raw === '' ? null : Number(raw));
  }
}
