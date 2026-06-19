import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '@env/environment';
import { API_ENDPOINTS } from '@app/core/constants/api-endpoints.constants';
import type { DashboardDto } from '@app/core/interfaces/dashboard.interfaces';

@Injectable({ providedIn: 'root' })
export class DashboardService {
  private readonly http = inject(HttpClient);
  private readonly base = environment.apiUrl;

  getDashboard(): Observable<DashboardDto> {
    return this.http.get<DashboardDto>(`${this.base}${API_ENDPOINTS.admin.dashboard}`);
  }
}
