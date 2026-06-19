import {
  ChangeDetectionStrategy,
  Component,
  computed,
  input,
  model,
} from '@angular/core';
import type { FormValueControl, ValidationError } from '@angular/forms/signals';
import { I18nService } from '@app/core/services/i18n/i18n.service';
import { TranslatePipe } from '@app/core/services/i18n/translate.pipe';
import { firstErrorKey, type UiValidationError } from '@app/core/utils/validation-error.util';
import type { SelectOption } from './select.types';
import { inject } from '@angular/core';

let uid = 0;

/** Liste déroulante — intégrée Signal Forms via `FormValueControl<string>`. */
@Component({
  selector: 'kz-select',
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
      <select
        [id]="id"
        [value]="value()"
        [disabled]="disabled()"
        [attr.aria-invalid]="showError() ? 'true' : null"
        [class]="selectClasses()"
        (change)="onChange($event)"
        (blur)="touched.set(true)"
      >
        @if (placeholder()) {
          <option value="" disabled>{{ placeholder()! | translate }}</option>
        }
        @for (opt of options(); track opt.value) {
          <option [value]="opt.value">{{ labelFor(opt) }}</option>
        }
      </select>
      @if (showError(); as err) {
        <p class="text-xs text-red-600" role="alert">{{ err.key | translate: err.params }}</p>
      }
    </div>
  `,
})
export class SelectComponent implements FormValueControl<string> {
  private readonly i18n = inject(I18nService);
  protected readonly id = `kz-select-${uid++}`;

  readonly value = model<string>('');
  readonly errors = input<readonly ValidationError.WithOptionalFieldTree[]>([]);
  readonly disabled = input<boolean>(false);
  readonly touched = model<boolean>(false);

  readonly label = input<string>();
  readonly placeholder = input<string>();
  readonly options = input.required<readonly SelectOption[]>();
  readonly requiredMark = input<boolean>(false);

  protected readonly showError = computed(() =>
    this.touched() ? firstErrorKey(this.errors() as unknown as UiValidationError[]) : null,
  );

  protected readonly selectClasses = computed(() => {
    const base =
      'h-10 w-full rounded-lg border bg-white px-3 text-sm text-ink-900 transition-colors ' +
      'focus:outline-none focus:ring-2 focus:ring-offset-1 disabled:bg-ink-50';
    const border = this.showError()
      ? 'border-red-400 focus:border-red-500 focus:ring-red-300'
      : 'border-ink-200 focus:border-ink-400 focus:ring-accent-300';
    return `${base} ${border}`;
  });

  protected labelFor(opt: SelectOption): string {
    return opt.rawLabel ? opt.labelKey : this.i18n.t(opt.labelKey as never);
  }

  protected onChange(event: Event): void {
    this.value.set((event.target as HTMLSelectElement).value);
  }
}
