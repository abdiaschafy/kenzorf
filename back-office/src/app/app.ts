import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { I18nService } from '@app/core/services/i18n/i18n.service';
import { ToastContainerComponent } from '@app/shared/ui/feedback/toast-container.component';

@Component({
  selector: 'app-root',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterOutlet, ToastContainerComponent],
  template: `
    <router-outlet />
    <kz-toast-container />
  `,
})
export class App {
  // Initialise la locale (applique <html lang>) au démarrage.
  private readonly i18n = inject(I18nService);

  constructor() {
    this.i18n.setLocale(this.i18n.locale());
  }
}
