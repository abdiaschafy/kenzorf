import {
  ApplicationConfig,
  inject,
  provideAppInitializer,
  provideBrowserGlobalErrorListeners,
  provideZonelessChangeDetection,
} from '@angular/core';
import { provideRouter, withComponentInputBinding } from '@angular/router';
import { provideHttpClient, withInterceptors } from '@angular/common/http';
import { routes } from './app.routes';
import { tokenInterceptor } from '@app/core/interceptors/token.interceptor';
import { errorInterceptor } from '@app/core/interceptors/error.interceptor';
import { AuthService } from '@app/core/services/auth.service';

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideZonelessChangeDetection(),
    provideRouter(routes, withComponentInputBinding()),
    provideHttpClient(withInterceptors([tokenInterceptor, errorInterceptor])),
    // Durcissement E2 : l'access token n'est jamais persisté. Au démarrage, on
    // restaure la session via silent-refresh (refresh token en sessionStorage)
    // AVANT l'activation des guards, sinon une session valide serait perdue.
    provideAppInitializer(() => inject(AuthService).silentRefresh()),
  ],
};
