import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '@env/environment';
import { API_ENDPOINTS } from '@app/core/constants/api-endpoints.constants';
import type { CategoryAdminDto } from '@app/core/interfaces/catalog.interfaces';
import type { CategoryRequest } from '@app/core/interfaces/admin-product.interfaces';

@Injectable({ providedIn: 'root' })
export class CategoryService {
  private readonly http = inject(HttpClient);
  private readonly base = environment.apiUrl;

  /** Liste des catégories (endpoint admin) — GET /api/admin/categories. */
  list(): Observable<CategoryAdminDto[]> {
    return this.http.get<CategoryAdminDto[]>(`${this.base}${API_ENDPOINTS.admin.categories}`);
  }

  create(payload: CategoryRequest): Observable<CategoryAdminDto> {
    return this.http.post<CategoryAdminDto>(
      `${this.base}${API_ENDPOINTS.admin.categories}`,
      payload,
    );
  }

  update(id: string, payload: CategoryRequest): Observable<CategoryAdminDto> {
    return this.http.put<CategoryAdminDto>(
      `${this.base}${API_ENDPOINTS.admin.category(id)}`,
      payload,
    );
  }

  remove(id: string): Observable<void> {
    return this.http.delete<void>(`${this.base}${API_ENDPOINTS.admin.category(id)}`);
  }
}
