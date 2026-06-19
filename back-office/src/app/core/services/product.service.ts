import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '@env/environment';
import { API_ENDPOINTS } from '@app/core/constants/api-endpoints.constants';
import { toHttpParams } from '@app/core/utils/http-params.util';
import type { Paged, PageQuery } from '@app/core/interfaces/common.interfaces';
import type {
  AdminProductDto,
  AdminProductRequest,
  AdminProductSummaryDto,
  UploadResultDto,
} from '@app/core/interfaces/admin-product.interfaces';

@Injectable({ providedIn: 'root' })
export class ProductService {
  private readonly http = inject(HttpClient);
  private readonly base = environment.apiUrl;

  /** Liste paginée des produits (back-office) — GET /api/admin/products. */
  list(query: PageQuery & { search?: string }): Observable<Paged<AdminProductSummaryDto>> {
    const params = toHttpParams({
      search: query.search,
      page: query.page,
      pageSize: query.pageSize,
    });
    return this.http.get<Paged<AdminProductSummaryDto>>(
      `${this.base}${API_ENDPOINTS.admin.products}`,
      { params },
    );
  }

  get(id: string): Observable<AdminProductDto> {
    return this.http.get<AdminProductDto>(`${this.base}${API_ENDPOINTS.admin.product(id)}`);
  }

  create(payload: AdminProductRequest): Observable<AdminProductDto> {
    return this.http.post<AdminProductDto>(`${this.base}${API_ENDPOINTS.admin.products}`, payload);
  }

  update(id: string, payload: AdminProductRequest): Observable<AdminProductDto> {
    return this.http.put<AdminProductDto>(`${this.base}${API_ENDPOINTS.admin.product(id)}`, payload);
  }

  remove(id: string): Observable<void> {
    return this.http.delete<void>(`${this.base}${API_ENDPOINTS.admin.product(id)}`);
  }

  /** Upload d'une image (multipart) → { url }. */
  uploadImage(file: File): Observable<UploadResultDto> {
    const form = new FormData();
    form.append('file', file);
    return this.http.post<UploadResultDto>(`${this.base}${API_ENDPOINTS.admin.uploads}`, form);
  }
}
