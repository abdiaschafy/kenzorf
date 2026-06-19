import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { Router } from '@angular/router';
import { FormField, email, form, required, submit } from '@angular/forms/signals';
import { TranslatePipe } from '@app/core/services/i18n/translate.pipe';
import { LanguageSwitcherComponent } from '@app/shared/ui/layout/language-switcher.component';
import { TextInputComponent } from '@app/shared/ui/inputs/text-input.component';
import { ButtonComponent } from '@app/shared/ui/button/button.component';
import { AuthService } from '@app/core/services/auth.service';
import { ROUTE_SEGMENT } from '@app/core/constants/routes.constants';
import { USER_ROLE } from '@app/core/constants/role.constants';
import type { LoginRequest } from '@app/core/interfaces/auth.interfaces';
import type { ApiError } from '@app/core/interfaces/common.interfaces';
import { firstValueFrom } from 'rxjs';

@Component({
  selector: 'kz-login',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [FormField, TranslatePipe, LanguageSwitcherComponent, TextInputComponent, ButtonComponent],
  template: `
    <div class="flex min-h-full items-center justify-center bg-ink-50 px-4 py-12">
      <div class="w-full max-w-md">
        <div class="mb-6 flex justify-end">
          <kz-language-switcher />
        </div>

        <div class="rounded-2xl border border-ink-100 bg-white p-8 shadow-elevated">
          <div class="mb-8 text-center">
            <div class="mb-3 font-display text-3xl font-bold tracking-tight text-ink-950">KENZORF</div>
            <h1 class="text-lg font-semibold text-ink-900">{{ 'auth.login.title' | translate }}</h1>
            <p class="mt-1 text-sm text-ink-400">{{ 'auth.login.subtitle' | translate }}</p>
          </div>

          <form class="space-y-5" (submit)="onSubmit($event)">
            <kz-text-input
              [formField]="loginForm.email"
              type="email"
              autocomplete="username"
              [requiredMark]="true"
              label="auth.login.email"
              placeholder="auth.login.emailPlaceholder"
            />

            <kz-text-input
              [formField]="loginForm.password"
              type="password"
              autocomplete="current-password"
              [requiredMark]="true"
              label="auth.login.password"
              placeholder="auth.login.passwordPlaceholder"
            />

            @if (errorKey(); as key) {
              <p class="rounded-lg bg-red-50 px-3 py-2 text-sm text-red-700" role="alert">
                {{ key | translate }}
              </p>
            }

            <kz-button type="submit" [block]="true" [loading]="submitting()">
              {{ (submitting() ? 'auth.login.submitting' : 'auth.login.submit') | translate }}
            </kz-button>
          </form>
        </div>
      </div>
    </div>
  `,
})
export class LoginComponent {
  private readonly auth = inject(AuthService);
  private readonly router = inject(Router);

  protected readonly submitting = signal(false);
  protected readonly errorKey = signal<string | null>(null);

  private readonly model = signal<LoginRequest>({ email: '', password: '' });

  protected readonly loginForm = form(this.model, (path) => {
    required(path.email);
    email(path.email);
    required(path.password);
  });

  protected readonly invalid = computed(() => this.loginForm().invalid());

  protected async onSubmit(event: Event): Promise<void> {
    event.preventDefault();
    this.errorKey.set(null);

    await submit(this.loginForm, async () => {
      this.submitting.set(true);
      try {
        const res = await firstValueFrom(this.auth.login(this.model()));
        if (res.user.role !== USER_ROLE.Admin) {
          this.auth.clearSession();
          this.errorKey.set('auth.login.forbiddenRole');
          return undefined;
        }
        await this.router.navigate([`/${ROUTE_SEGMENT.Dashboard}`]);
        return undefined;
      } catch (err) {
        const apiError = err as ApiError;
        this.errorKey.set(
          apiError.status === 401 || apiError.status === 400
            ? 'auth.login.error'
            : (apiError.messageKey ?? 'error.unknown'),
        );
        return undefined;
      } finally {
        this.submitting.set(false);
      }
    });
  }
}
