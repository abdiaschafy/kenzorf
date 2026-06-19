import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { rxResource } from '@angular/core/rxjs-interop';
import { firstValueFrom } from 'rxjs';
import { TranslatePipe } from '@app/core/services/i18n/translate.pipe';
import { PageHeaderComponent } from '@app/shared/ui/layout/page-header.component';
import { CardComponent } from '@app/shared/ui/card/card.component';
import { ButtonComponent } from '@app/shared/ui/button/button.component';
import { SpinnerComponent } from '@app/shared/ui/feedback/spinner.component';
import { ErrorStateComponent } from '@app/shared/ui/feedback/error-state.component';
import { EmptyStateComponent } from '@app/shared/ui/feedback/empty-state.component';
import { ModalComponent } from '@app/shared/ui/modal/modal.component';
import { ConfirmDialogComponent } from '@app/shared/ui/modal/confirm-dialog.component';
import { TextInputComponent } from '@app/shared/ui/inputs/text-input.component';
import { TextareaComponent } from '@app/shared/ui/inputs/textarea.component';
import { NumberInputComponent } from '@app/shared/ui/inputs/number-input.component';
import { CheckboxComponent } from '@app/shared/ui/inputs/checkbox.component';
import { BadgeComponent } from '@app/shared/ui/badge/badge.component';
import { CategoryService } from '@app/core/services/category.service';
import { NotificationService } from '@app/core/services/notification.service';
import type { CategoryAdminDto } from '@app/core/interfaces/catalog.interfaces';
import type { CategoryRequest } from '@app/core/interfaces/admin-product.interfaces';
import { CategoryFormModel, emptyCategoryForm } from './category-form.model';

@Component({
  selector: 'kz-categories',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [
    TranslatePipe,
    PageHeaderComponent,
    CardComponent,
    ButtonComponent,
    SpinnerComponent,
    ErrorStateComponent,
    EmptyStateComponent,
    ModalComponent,
    ConfirmDialogComponent,
    TextInputComponent,
    TextareaComponent,
    NumberInputComponent,
    CheckboxComponent,
    BadgeComponent,
  ],
  template: `
    <kz-page-header titleKey="categories.title" subtitleKey="categories.subtitle">
      <kz-button (click)="openCreate()">
        <svg class="h-4 w-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
          <path stroke-linecap="round" d="M12 5v14M5 12h14" />
        </svg>
        {{ 'categories.new' | translate }}
      </kz-button>
    </kz-page-header>

    <kz-card [bodyPadding]="false">
      @if (resource.isLoading()) {
        <kz-spinner />
      } @else if (resource.status() === 'error') {
        <kz-error-state (retry)="resource.reload()" />
      } @else if ((resource.value() ?? []).length === 0) {
        <kz-empty-state titleKey="categories.empty.title" descriptionKey="categories.empty.description">
          <kz-button (click)="openCreate()">{{ 'categories.new' | translate }}</kz-button>
        </kz-empty-state>
      } @else {
        <div class="overflow-x-auto">
          <table class="w-full text-sm">
            <thead>
              <tr class="border-b border-ink-100 text-left text-xs uppercase tracking-wide text-ink-400">
                <th class="px-4 py-3 font-medium">{{ 'categories.col.name' | translate }}</th>
                <th class="px-4 py-3 font-medium">{{ 'categories.col.slug' | translate }}</th>
                <th class="px-4 py-3 font-medium">{{ 'categories.col.order' | translate }}</th>
                <th class="px-4 py-3 font-medium">{{ 'categories.col.products' | translate }}</th>
                <th class="px-4 py-3 font-medium">{{ 'categories.col.status' | translate }}</th>
                <th class="px-4 py-3 text-right font-medium">{{ 'common.actions' | translate }}</th>
              </tr>
            </thead>
            <tbody>
              @for (category of resource.value() ?? []; track category.id) {
                <tr class="border-b border-ink-50 last:border-0 hover:bg-ink-50/60">
                  <td class="px-4 py-3 font-medium text-ink-900">{{ category.name }}</td>
                  <td class="px-4 py-3 font-mono text-xs text-ink-500">{{ category.slug }}</td>
                  <td class="px-4 py-3 text-ink-700">{{ category.displayOrder }}</td>
                  <td class="px-4 py-3 text-ink-700">{{ category.productCount }}</td>
                  <td class="px-4 py-3">
                    <kz-badge
                      [tone]="category.isActive ? 'success' : 'neutral'"
                      [labelKey]="category.isActive ? 'categories.status.active' : 'categories.status.inactive'"
                    />
                  </td>
                  <td class="px-4 py-3">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        type="button"
                        class="rounded-lg p-1.5 text-ink-500 hover:bg-ink-100 hover:text-ink-900"
                        [attr.aria-label]="'common.edit' | translate"
                        (click)="openEdit(category)"
                      >
                        <svg class="h-4 w-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true">
                          <path stroke-linecap="round" stroke-linejoin="round" d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7m-1.5-9.5a2.12 2.12 0 013 3L12 16l-4 1 1-4 8.5-8.5z" />
                        </svg>
                      </button>
                      <button
                        type="button"
                        class="rounded-lg p-1.5 text-ink-500 hover:bg-red-50 hover:text-red-600"
                        [attr.aria-label]="'common.delete' | translate"
                        (click)="askDelete(category)"
                      >
                        <svg class="h-4 w-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true">
                          <path stroke-linecap="round" stroke-linejoin="round" d="M3 6h18M8 6V4a1 1 0 011-1h6a1 1 0 011 1v2m2 0v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6h14z" />
                        </svg>
                      </button>
                    </div>
                  </td>
                </tr>
              }
            </tbody>
          </table>
        </div>
      }
    </kz-card>

    <!-- Modale créer / éditer -->
    <kz-modal [open]="formOpen()" [titleKey]="editing() ? 'categories.edit' : 'categories.new'" (closed)="closeForm()">
      <div class="space-y-4">
        <kz-text-input
          [value]="form().name"
          (valueChange)="patch('name', $event)"
          [requiredMark]="true"
          label="categories.name"
          placeholder="categories.namePlaceholder"
        />
        <kz-text-input [value]="form().slug" (valueChange)="patch('slug', $event)" label="categories.slug" hint="productForm.slugHint" />
        <kz-textarea [value]="form().description" (valueChange)="patch('description', $event)" [rows]="3" label="categories.description" />
        <kz-text-input [value]="form().imageUrl" (valueChange)="patch('imageUrl', $event)" label="categories.imageUrl" />
        <kz-number-input
          [value]="form().displayOrder"
          (valueChange)="patch('displayOrder', $event)"
          label="categories.displayOrder"
          hint="categories.displayOrderHint"
          [minValue]="0"
        />
        <kz-checkbox [checked]="form().isActive" (checkedChange)="patch('isActive', $event)" label="categories.isActive" />
        @if (formError()) {
          <p class="rounded-lg bg-red-50 px-3 py-2 text-sm text-red-700" role="alert">{{ 'error.validation' | translate }}</p>
        }
      </div>
      <ng-container modal-footer>
        <kz-button variant="outline" (click)="closeForm()">{{ 'common.cancel' | translate }}</kz-button>
        <kz-button [loading]="saving()" (click)="save()">{{ 'common.save' | translate }}</kz-button>
      </ng-container>
    </kz-modal>

    <kz-confirm-dialog
      [open]="!!pendingDelete()"
      titleKey="categories.deleteConfirm.title"
      messageKey="categories.deleteConfirm.message"
      [messageParams]="{ name: pendingDelete()?.name ?? '' }"
      confirmKey="common.delete"
      [danger]="true"
      [loading]="deleting()"
      (confirmed)="confirmDelete()"
      (cancelled)="pendingDelete.set(null)"
    />
  `,
})
export class CategoriesComponent {
  private readonly categoryService = inject(CategoryService);
  private readonly notifications = inject(NotificationService);

  protected readonly resource = rxResource({
    stream: () => this.categoryService.list(),
  });

  protected readonly formOpen = signal(false);
  protected readonly editing = signal<CategoryAdminDto | null>(null);
  protected readonly form = signal<CategoryFormModel>(emptyCategoryForm());
  protected readonly saving = signal(false);
  protected readonly formError = signal(false);

  protected readonly pendingDelete = signal<CategoryAdminDto | null>(null);
  protected readonly deleting = signal(false);

  protected patch<K extends keyof CategoryFormModel>(key: K, value: CategoryFormModel[K]): void {
    this.form.update((f) => ({ ...f, [key]: value }));
  }

  protected openCreate(): void {
    this.editing.set(null);
    this.form.set(emptyCategoryForm());
    this.formError.set(false);
    this.formOpen.set(true);
  }

  protected openEdit(category: CategoryAdminDto): void {
    this.editing.set(category);
    this.form.set({
      name: category.name,
      slug: category.slug,
      description: category.description ?? '',
      imageUrl: category.imageUrl ?? '',
      displayOrder: category.displayOrder,
      isActive: category.isActive,
    });
    this.formError.set(false);
    this.formOpen.set(true);
  }

  protected closeForm(): void {
    this.formOpen.set(false);
  }

  protected async save(): Promise<void> {
    const data = this.form();
    if (!data.name.trim()) {
      this.formError.set(true);
      return;
    }
    const payload: CategoryRequest = {
      name: data.name.trim(),
      slug: data.slug.trim() || undefined,
      description: data.description.trim() || undefined,
      imageUrl: data.imageUrl.trim() || undefined,
      displayOrder: data.displayOrder ?? 0,
      isActive: data.isActive,
    };
    this.saving.set(true);
    try {
      const target = this.editing();
      if (target) {
        await firstValueFrom(this.categoryService.update(target.id, payload));
      } else {
        await firstValueFrom(this.categoryService.create(payload));
      }
      this.notifications.success('categories.saved');
      this.formOpen.set(false);
      this.resource.reload();
    } catch {
      this.notifications.error('error.unknown');
    } finally {
      this.saving.set(false);
    }
  }

  protected askDelete(category: CategoryAdminDto): void {
    this.pendingDelete.set(category);
  }

  protected async confirmDelete(): Promise<void> {
    const target = this.pendingDelete();
    if (!target) {
      return;
    }
    this.deleting.set(true);
    try {
      await firstValueFrom(this.categoryService.remove(target.id));
      this.notifications.success('categories.deleted');
      this.pendingDelete.set(null);
      this.resource.reload();
    } catch {
      this.notifications.error('error.unknown');
    } finally {
      this.deleting.set(false);
    }
  }
}
