import { ChangeDetectionStrategy, Component, input, output } from '@angular/core';
import { RouterLink, RouterLinkActive } from '@angular/router';
import { TranslatePipe } from '@app/core/services/i18n/translate.pipe';
import { NAV_GROUPS } from '@app/core/constants/navigation.constants';
import { NavIconComponent } from './nav-icon.component';

/** Barre latérale de navigation du back-office (marque + groupes de liens). */
@Component({
  selector: 'kz-sidebar',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink, RouterLinkActive, TranslatePipe, NavIconComponent],
  template: `
    <aside class="flex h-full w-64 flex-col border-r border-ink-100 bg-white">
      <div class="flex h-16 items-center gap-2 border-b border-ink-100 px-6">
        <span class="font-display text-xl font-bold tracking-tight text-ink-950">KENZORF</span>
        <span class="rounded bg-accent-100 px-1.5 py-0.5 text-[10px] font-semibold uppercase tracking-wide text-accent-700">
          Admin
        </span>
      </div>

      <nav class="kz-scrollbar flex-1 overflow-y-auto px-3 py-4">
        @for (group of navGroups; track group.labelKey) {
          <div class="mb-5">
            <p class="px-3 pb-1.5 text-[11px] font-semibold uppercase tracking-wider text-ink-400">
              {{ group.labelKey | translate }}
            </p>
            <ul class="space-y-0.5">
              @for (item of group.items; track item.path) {
                <li>
                  <a
                    [routerLink]="item.path"
                    routerLinkActive="bg-ink-950 text-white hover:bg-ink-900"
                    [routerLinkActiveOptions]="{ exact: false }"
                    class="flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium text-ink-600 transition-colors hover:bg-ink-100"
                    (click)="navigate.emit()"
                  >
                    <kz-nav-icon [name]="item.icon" />
                    {{ item.labelKey | translate }}
                  </a>
                </li>
              }
            </ul>
          </div>
        }
      </nav>

      <div class="border-t border-ink-100 px-4 py-3 text-[11px] text-ink-400">KENZORF · {{ year }}</div>
    </aside>
  `,
})
export class SidebarComponent {
  protected readonly navGroups = NAV_GROUPS;
  protected readonly year = new Date().getFullYear();

  /** Réservé à un usage futur (afficher/replier en mobile). */
  readonly collapsed = input<boolean>(false);
  readonly navigate = output<void>();
}
