import { ChangeDetectionStrategy, Component, input, model } from '@angular/core';
import type { FormCheckboxControl } from '@angular/forms/signals';
import { TranslatePipe } from '@app/core/services/i18n/translate.pipe';

let uid = 0;

/** Case à cocher — intégrée Signal Forms via `FormCheckboxControl`. */
@Component({
  selector: 'kz-checkbox',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [TranslatePipe],
  template: `
    <label [for]="id" class="flex cursor-pointer items-center gap-2.5 select-none">
      <input
        [id]="id"
        type="checkbox"
        [checked]="checked()"
        [disabled]="disabled()"
        class="h-4 w-4 rounded border-ink-300 text-ink-950 focus:ring-2 focus:ring-accent-300 focus:ring-offset-1"
        (change)="onChange($event)"
      />
      @if (label()) {
        <span class="text-sm text-ink-700">{{ label()! | translate }}</span>
      }
    </label>
  `,
})
export class CheckboxComponent implements FormCheckboxControl {
  protected readonly id = `kz-checkbox-${uid++}`;

  readonly checked = model<boolean>(false);
  readonly disabled = input<boolean>(false);
  readonly label = input<string>();

  protected onChange(event: Event): void {
    this.checked.set((event.target as HTMLInputElement).checked);
  }
}
