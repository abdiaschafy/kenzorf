import {
  ChangeDetectionStrategy,
  Component,
  computed,
  effect,
  inject,
  input,
  signal,
} from '@angular/core';
import { Router, RouterLink } from '@angular/router';
import { rxResource } from '@angular/core/rxjs-interop';
import { firstValueFrom } from 'rxjs';
import { TranslatePipe } from '@app/core/services/i18n/translate.pipe';
import { PageHeaderComponent } from '@app/shared/ui/layout/page-header.component';
import { CardComponent } from '@app/shared/ui/card/card.component';
import { ButtonComponent } from '@app/shared/ui/button/button.component';
import { SpinnerComponent } from '@app/shared/ui/feedback/spinner.component';
import { ErrorStateComponent } from '@app/shared/ui/feedback/error-state.component';
import { TextInputComponent } from '@app/shared/ui/inputs/text-input.component';
import { TextareaComponent } from '@app/shared/ui/inputs/textarea.component';
import { NumberInputComponent } from '@app/shared/ui/inputs/number-input.component';
import { SelectComponent } from '@app/shared/ui/inputs/select.component';
import { CheckboxComponent } from '@app/shared/ui/inputs/checkbox.component';
import { ProductService } from '@app/core/services/product.service';
import { CategoryService } from '@app/core/services/category.service';
import { NotificationService } from '@app/core/services/notification.service';
import { GENDER_VALUES, GENDER_LABEL_KEY } from '@app/core/constants/catalog.constants';
import { ROUTE_SEGMENT } from '@app/core/constants/routes.constants';
import type { SelectOption } from '@app/shared/ui/inputs/select.types';
import type {
  ProductFormModel,
  ProductImageForm,
  ProductVariantForm,
} from './product-form.model';
import {
  dtoToForm,
  emptyImage,
  emptyProductForm,
  emptyVariant,
  formToRequest,
} from './product-form.util';

@Component({
  selector: 'kz-product-form',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [
    RouterLink,
    TranslatePipe,
    PageHeaderComponent,
    CardComponent,
    ButtonComponent,
    SpinnerComponent,
    ErrorStateComponent,
    TextInputComponent,
    TextareaComponent,
    NumberInputComponent,
    SelectComponent,
    CheckboxComponent,
  ],
  template: `
    <kz-page-header [titleKey]="isEdit() ? 'products.edit' : 'products.new'">
      <a [routerLink]="listLink" class="text-sm font-medium text-ink-500 hover:text-ink-900">
        ← {{ 'common.back' | translate }}
      </a>
    </kz-page-header>

    @if (loading()) {
      <kz-spinner />
    } @else if (loadError()) {
      <kz-error-state (retry)="reload()" />
    } @else {
      <form class="space-y-6" (submit)="onSubmit($event)">
        <!-- Général -->
        <kz-card titleKey="productForm.section.general">
          <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
            <kz-text-input
              [value]="model().name"
              (valueChange)="patch('name', $event)"
              [requiredMark]="true"
              label="productForm.name"
              placeholder="productForm.namePlaceholder"
            />
            <kz-text-input
              [value]="model().slug"
              (valueChange)="patch('slug', $event)"
              label="productForm.slug"
              placeholder="productForm.slugPlaceholder"
              hint="productForm.slugHint"
            />
            <kz-select
              [value]="model().categoryId"
              (valueChange)="patch('categoryId', $event)"
              [requiredMark]="true"
              label="productForm.category"
              placeholder="productForm.categoryPlaceholder"
              [options]="categoryOptions()"
            />
            <kz-select
              [value]="model().gender"
              (valueChange)="patchGender($event)"
              [requiredMark]="true"
              label="productForm.gender"
              [options]="genderOptions"
            />
          </div>
          <div class="mt-4 space-y-4">
            <kz-text-input
              [value]="model().shortDescription"
              (valueChange)="patch('shortDescription', $event)"
              label="productForm.shortDescription"
            />
            <kz-textarea
              [value]="model().description"
              (valueChange)="patch('description', $event)"
              [rows]="4"
              label="productForm.description"
            />
            <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
              <kz-text-input
                [value]="model().material"
                (valueChange)="patch('material', $event)"
                label="productForm.material"
              />
              <kz-text-input
                [value]="model().careInstructions"
                (valueChange)="patch('careInstructions', $event)"
                label="productForm.careInstructions"
              />
            </div>
          </div>
          <div class="mt-4 flex flex-wrap gap-6">
            <kz-checkbox [checked]="model().isActive" (checkedChange)="patch('isActive', $event)" label="productForm.isActive" />
            <kz-checkbox [checked]="model().isFeatured" (checkedChange)="patch('isFeatured', $event)" label="productForm.isFeatured" />
          </div>
        </kz-card>

        <!-- Prix -->
        <kz-card titleKey="productForm.section.pricing">
          <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
            <kz-number-input
              [value]="model().basePrice"
              (valueChange)="patch('basePrice', $event)"
              [requiredMark]="true"
              label="productForm.basePrice"
              suffix="FCFA"
            />
            <kz-number-input
              [value]="model().compareAtPrice"
              (valueChange)="patch('compareAtPrice', $event)"
              label="productForm.compareAtPrice"
              suffix="FCFA"
            />
          </div>
        </kz-card>

        <!-- Images -->
        <kz-card titleKey="productForm.section.images">
          <kz-button card-actions type="button" variant="outline" size="sm" (click)="addImage()">
            {{ 'productForm.addImage' | translate }}
          </kz-button>

          @if (images().length === 0) {
            <p class="py-3 text-sm text-ink-400">{{ 'productForm.image.empty' | translate }}</p>
          } @else {
            <div class="space-y-3">
              @for (image of images(); track $index) {
                <div class="grid grid-cols-1 items-end gap-3 rounded-lg border border-ink-100 p-3 md:grid-cols-[1fr_1fr_auto_auto_auto]">
                  <kz-text-input [value]="image.url" (valueChange)="patchImage($index, 'url', $event)" label="productForm.image.url" />
                  <kz-text-input [value]="image.altText" (valueChange)="patchImage($index, 'altText', $event)" label="productForm.image.altText" />
                  <kz-number-input [value]="image.displayOrder" (valueChange)="patchImageOrder($index, $event)" label="productForm.image.order" [minValue]="0" />
                  <div class="pb-2">
                    <kz-checkbox [checked]="image.isPrimary" (checkedChange)="setPrimaryImage($index)" label="productForm.image.primary" />
                  </div>
                  <button
                    type="button"
                    class="mb-1 rounded-lg p-2 text-ink-400 hover:bg-red-50 hover:text-red-600"
                    [attr.aria-label]="'productForm.image.remove' | translate"
                    (click)="removeImage($index)"
                  >
                    <svg class="h-4 w-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true">
                      <path stroke-linecap="round" d="M6 6l12 12M18 6L6 18" />
                    </svg>
                  </button>
                </div>
              }
            </div>
          }
        </kz-card>

        <!-- Variantes -->
        <kz-card titleKey="productForm.section.variants">
          <kz-button card-actions type="button" variant="outline" size="sm" (click)="addVariant()">
            {{ 'productForm.addVariant' | translate }}
          </kz-button>

          @if (variants().length === 0) {
            <p class="py-3 text-sm text-ink-400">{{ 'productForm.variant.empty' | translate }}</p>
          } @else {
            <div class="space-y-3">
              @for (variant of variants(); track $index) {
                <div class="grid grid-cols-2 items-end gap-3 rounded-lg border border-ink-100 p-3 lg:grid-cols-[1.2fr_0.8fr_1fr_0.8fr_0.9fr_0.8fr_auto]">
                  <kz-text-input [value]="variant.sku" (valueChange)="patchVariant($index, 'sku', $event)" label="productForm.variant.sku" />
                  <kz-text-input [value]="variant.size" (valueChange)="patchVariant($index, 'size', $event)" label="productForm.variant.size" />
                  <kz-text-input [value]="variant.color" (valueChange)="patchVariant($index, 'color', $event)" label="productForm.variant.color" />
                  <kz-text-input [value]="variant.colorHex" (valueChange)="patchVariant($index, 'colorHex', $event)" label="productForm.variant.colorHex" />
                  <kz-number-input [value]="variant.price" (valueChange)="patchVariantNumber($index, 'price', $event)" label="productForm.variant.price" />
                  <kz-number-input [value]="variant.stockQuantity" (valueChange)="patchVariantNumber($index, 'stockQuantity', $event)" label="productForm.variant.stock" [minValue]="0" />
                  <button
                    type="button"
                    class="mb-1 rounded-lg p-2 text-ink-400 hover:bg-red-50 hover:text-red-600"
                    [attr.aria-label]="'productForm.variant.remove' | translate"
                    (click)="removeVariant($index)"
                  >
                    <svg class="h-4 w-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true">
                      <path stroke-linecap="round" d="M6 6l12 12M18 6L6 18" />
                    </svg>
                  </button>
                </div>
              }
            </div>
          }
        </kz-card>

        @if (formError(); as key) {
          <p class="rounded-lg bg-red-50 px-3 py-2 text-sm text-red-700" role="alert">{{ key | translate }}</p>
        }

        <div class="flex items-center justify-end gap-3">
          <a [routerLink]="listLink"><kz-button type="button" variant="outline">{{ 'common.cancel' | translate }}</kz-button></a>
          <kz-button type="submit" [loading]="saving()">{{ 'common.save' | translate }}</kz-button>
        </div>
      </form>
    }
  `,
})
export class ProductFormComponent {
  private readonly productService = inject(ProductService);
  private readonly categoryService = inject(CategoryService);
  private readonly notifications = inject(NotificationService);
  private readonly router = inject(Router);

  /** Param de route (via withComponentInputBinding). Absent en création. */
  readonly id = input<string>();

  protected readonly listLink = `/${ROUTE_SEGMENT.Products}`;

  protected readonly genderOptions: readonly SelectOption[] = GENDER_VALUES.map((g) => ({
    value: g,
    labelKey: GENDER_LABEL_KEY[g],
  }));

  protected readonly model = signal<ProductFormModel>(emptyProductForm());
  protected readonly images = signal<ProductImageForm[]>([]);
  protected readonly variants = signal<ProductVariantForm[]>([emptyVariant()]);

  protected readonly saving = signal(false);
  protected readonly formError = signal<string | null>(null);

  protected readonly isEdit = computed(() => !!this.id());

  private readonly categoriesResource = rxResource({
    stream: () => this.categoryService.list(),
  });

  protected readonly categoryOptions = computed<SelectOption[]>(() =>
    (this.categoriesResource.value() ?? []).map((c) => ({
      value: c.id,
      labelKey: c.name,
      rawLabel: true,
    })),
  );

  private readonly productResource = rxResource({
    params: () => this.id(),
    stream: ({ params }) => this.productService.get(params as string),
  });

  protected readonly loading = computed(
    () => this.categoriesResource.isLoading() || (this.isEdit() && this.productResource.isLoading()),
  );

  protected readonly loadError = computed(
    () =>
      this.categoriesResource.status() === 'error' ||
      (this.isEdit() && this.productResource.status() === 'error'),
  );

  constructor() {
    // Hydrate le formulaire dès que le produit est chargé (mode édition).
    effect(() => {
      const product = this.productResource.value();
      if (product) {
        const { model, images, variants } = dtoToForm(product);
        this.model.set(model);
        this.images.set(images);
        this.variants.set(variants.length ? variants : [emptyVariant()]);
      }
    });
  }

  protected reload(): void {
    this.categoriesResource.reload();
    if (this.isEdit()) {
      this.productResource.reload();
    }
  }

  // --- Patch helpers (mises à jour immuables, compatibles OnPush/zoneless) ---

  protected patch<K extends keyof ProductFormModel>(key: K, value: ProductFormModel[K]): void {
    this.model.update((m) => ({ ...m, [key]: value }));
  }

  protected patchGender(value: string): void {
    this.model.update((m) => ({ ...m, gender: value as ProductFormModel['gender'] }));
  }

  protected patchImage(index: number, key: 'url' | 'altText', value: string): void {
    this.images.update((list) => list.map((img, i) => (i === index ? { ...img, [key]: value } : img)));
  }

  protected patchImageOrder(index: number, value: number | null): void {
    this.images.update((list) =>
      list.map((img, i) => (i === index ? { ...img, displayOrder: value ?? 0 } : img)),
    );
  }

  protected patchVariant(index: number, key: 'sku' | 'size' | 'color' | 'colorHex', value: string): void {
    this.variants.update((list) => list.map((v, i) => (i === index ? { ...v, [key]: value } : v)));
  }

  protected patchVariantNumber(index: number, key: 'price' | 'stockQuantity', value: number | null): void {
    this.variants.update((list) => list.map((v, i) => (i === index ? { ...v, [key]: value } : v)));
  }

  protected addImage(): void {
    this.images.update((list) => [...list, emptyImage(list.length)]);
  }

  protected removeImage(index: number): void {
    this.images.update((list) => list.filter((_, i) => i !== index));
  }

  protected setPrimaryImage(index: number): void {
    this.images.update((list) => list.map((img, i) => ({ ...img, isPrimary: i === index })));
  }

  protected addVariant(): void {
    this.variants.update((list) => [...list, emptyVariant()]);
  }

  protected removeVariant(index: number): void {
    this.variants.update((list) => list.filter((_, i) => i !== index));
  }

  protected async onSubmit(event: Event): Promise<void> {
    event.preventDefault();
    this.formError.set(null);

    const validationKey = this.validate();
    if (validationKey) {
      this.formError.set(validationKey);
      return;
    }

    const payload = formToRequest(this.model(), this.images(), this.variants());
    this.saving.set(true);
    try {
      const editId = this.id();
      if (editId) {
        await firstValueFrom(this.productService.update(editId, payload));
      } else {
        await firstValueFrom(this.productService.create(payload));
      }
      this.notifications.success('products.saved');
      await this.router.navigate([this.listLink]);
    } catch {
      this.notifications.error('error.unknown');
    } finally {
      this.saving.set(false);
    }
  }

  private validate(): string | null {
    const m = this.model();
    if (!m.name.trim() || !m.description.trim() || !m.categoryId || !m.gender || m.basePrice === null) {
      return 'error.validation';
    }
    if (this.images().length === 0 || this.images().some((img) => !img.url.trim())) {
      return 'productForm.validation.imagesRequired';
    }
    if (
      this.variants().length === 0 ||
      this.variants().some((v) => !v.sku.trim() || !v.size.trim() || !v.color.trim())
    ) {
      return 'productForm.validation.variantsRequired';
    }
    return null;
  }
}
