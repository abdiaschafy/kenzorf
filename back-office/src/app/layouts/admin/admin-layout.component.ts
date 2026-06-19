import { ChangeDetectionStrategy, Component, signal } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { SidebarComponent } from './sidebar.component';
import { TopbarComponent } from './topbar.component';

/** Shell du back-office : sidebar fixe (desktop) + drawer (mobile) + topbar + contenu. */
@Component({
  selector: 'kz-admin-layout',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterOutlet, SidebarComponent, TopbarComponent],
  template: `
    <div class="flex h-full">
      <!-- Sidebar desktop -->
      <div class="hidden lg:block">
        <kz-sidebar />
      </div>

      <!-- Drawer mobile -->
      @if (drawerOpen()) {
        <div class="fixed inset-0 z-40 lg:hidden">
          <div class="absolute inset-0 bg-ink-950/40" (click)="closeDrawer()" aria-hidden="true"></div>
          <div class="absolute inset-y-0 left-0 z-50 shadow-elevated">
            <kz-sidebar (navigate)="closeDrawer()" />
          </div>
        </div>
      }

      <!-- Colonne principale -->
      <div class="flex min-w-0 flex-1 flex-col">
        <kz-topbar (menuToggle)="toggleDrawer()" />
        <main class="kz-scrollbar flex-1 overflow-y-auto bg-ink-50 px-4 py-6 sm:px-6 lg:px-8">
          <div class="mx-auto w-full max-w-7xl">
            <router-outlet />
          </div>
        </main>
      </div>
    </div>
  `,
})
export class AdminLayoutComponent {
  protected readonly drawerOpen = signal(false);

  protected toggleDrawer(): void {
    this.drawerOpen.update((v) => !v);
  }

  protected closeDrawer(): void {
    this.drawerOpen.set(false);
  }
}
