import { ChangeDetectionStrategy, Component, input } from '@angular/core';
import type { NavIcon } from '@app/core/interfaces/navigation.interfaces';

/** Rend l'icône SVG correspondant à un identifiant de navigation. */
@Component({
  selector: 'kz-nav-icon',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <svg class="h-5 w-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" aria-hidden="true">
      @switch (name()) {
        @case ('dashboard') {
          <path stroke-linecap="round" stroke-linejoin="round" d="M4 13h6V4H4v9zm10 7h6v-9h-6v9zM4 20h6v-4H4v4zM14 4v4h6V4h-6z" />
        }
        @case ('products') {
          <path stroke-linecap="round" stroke-linejoin="round" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4" />
        }
        @case ('categories') {
          <path stroke-linecap="round" stroke-linejoin="round" d="M4 6h16M4 12h16M4 18h10" />
        }
        @case ('orders') {
          <path stroke-linecap="round" stroke-linejoin="round" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4" />
        }
        @case ('customers') {
          <path stroke-linecap="round" stroke-linejoin="round" d="M17 20h5v-2a4 4 0 00-3-3.87M9 20H4v-2a4 4 0 013-3.87m6-2.13a4 4 0 10-4-4 4 4 0 004 4zm6 0a3 3 0 10-2.5-4.66" />
        }
      }
    </svg>
  `,
})
export class NavIconComponent {
  readonly name = input.required<NavIcon>();
}
