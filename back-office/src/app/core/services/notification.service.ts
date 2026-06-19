import { Injectable, signal } from '@angular/core';
import type { Toast, ToastTone } from '@app/core/interfaces/notification.interfaces';

/** File de notifications toast (clés i18n uniquement). Auto-dismiss après délai. */
@Injectable({ providedIn: 'root' })
export class NotificationService {
  private readonly _toasts = signal<Toast[]>([]);
  private nextId = 1;

  readonly toasts = this._toasts.asReadonly();

  success(messageKey: string, params?: Record<string, string | number>): void {
    this.push('success', messageKey, params);
  }

  error(messageKey: string, params?: Record<string, string | number>): void {
    this.push('error', messageKey, params);
  }

  info(messageKey: string, params?: Record<string, string | number>): void {
    this.push('info', messageKey, params);
  }

  dismiss(id: number): void {
    this._toasts.update((list) => list.filter((t) => t.id !== id));
  }

  private push(tone: ToastTone, messageKey: string, params?: Record<string, string | number>): void {
    const id = this.nextId++;
    const toast: Toast = { id, tone, messageKey, params };
    this._toasts.update((list) => [...list, toast]);
    setTimeout(() => this.dismiss(id), 4500);
  }
}
