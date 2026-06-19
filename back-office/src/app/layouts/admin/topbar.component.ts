import { ChangeDetectionStrategy, Component, inject, output } from '@angular/core';
import { Router } from '@angular/router';
import { TranslatePipe } from '@app/core/services/i18n/translate.pipe';
import { LanguageSwitcherComponent } from '@app/shared/ui/layout/language-switcher.component';
import { AuthService } from '@app/core/services/auth.service';
import { ROUTE_SEGMENT } from '@app/core/constants/routes.constants';

/** Barre supérieure : bouton menu (mobile), langue, identité et déconnexion. */
@Component({
  selector: 'kz-topbar',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [TranslatePipe, LanguageSwitcherComponent],
  template: `
    <header class="flex h-16 items-center justify-between gap-4 border-b border-ink-100 bg-white/80 px-4 backdrop-blur sm:px-6">
      <button
        type="button"
        class="rounded-lg p-2 text-ink-600 hover:bg-ink-100 lg:hidden"
        [attr.aria-label]="'nav.openMenu' | translate"
        (click)="menuToggle.emit()"
      >
        <svg class="h-5 w-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
          <path stroke-linecap="round" d="M4 6h16M4 12h16M4 18h16" />
        </svg>
      </button>

      <div class="flex flex-1 items-center justify-end gap-3">
        <kz-language-switcher />

        @if (auth.user(); as user) {
          <div class="flex items-center gap-3">
            <div class="hidden text-right sm:block">
              <p class="text-sm font-medium leading-tight text-ink-900">{{ user.firstName }} {{ user.lastName }}</p>
              <p class="text-xs leading-tight text-ink-400">{{ user.email }}</p>
            </div>
            <div
              class="flex h-9 w-9 items-center justify-center rounded-full bg-ink-950 text-xs font-semibold text-white"
              aria-hidden="true"
            >
              {{ auth.initials() }}
            </div>
          </div>

          <button
            type="button"
            class="rounded-lg border border-ink-200 px-3 py-1.5 text-sm font-medium text-ink-700 hover:bg-ink-50"
            (click)="logout()"
          >
            {{ 'auth.logout' | translate }}
          </button>
        }
      </div>
    </header>
  `,
})
export class TopbarComponent {
  protected readonly auth = inject(AuthService);
  private readonly router = inject(Router);

  readonly menuToggle = output<void>();

  protected logout(): void {
    this.auth.logout().subscribe({
      next: () => this.redirectToLogin(),
      error: () => this.redirectToLogin(),
    });
  }

  private redirectToLogin(): void {
    void this.router.navigate([`/${ROUTE_SEGMENT.Login}`]);
  }
}
