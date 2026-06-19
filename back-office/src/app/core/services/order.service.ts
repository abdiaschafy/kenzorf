import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '@env/environment';
import { API_ENDPOINTS } from '@app/core/constants/api-endpoints.constants';
import { toHttpParams } from '@app/core/utils/http-params.util';
import type { Paged } from '@app/core/interfaces/common.interfaces';
import type {
  AdminOrderDto,
  AdminOrderQuery,
  AdminOrderSummaryDto,
  UpdateOrderStatusRequest,
} from '@app/core/interfaces/order.interfaces';

@Injectable({ providedIn: 'root' })
export class OrderService {
  private readonly http = inject(HttpClient);
  private readonly base = environment.apiUrl;

  list(query: AdminOrderQuery): Observable<Paged<AdminOrderSummaryDto>> {
    const params = toHttpParams({
      status: query.status,
      search: query.search,
      page: query.page,
      pageSize: query.pageSize,
    });
    return this.http.get<Paged<AdminOrderSummaryDto>>(`${this.base}${API_ENDPOINTS.admin.orders}`, {
      params,
    });
  }

  get(id: string): Observable<AdminOrderDto> {
    return this.http.get<AdminOrderDto>(`${this.base}${API_ENDPOINTS.admin.order(id)}`);
  }

  updateStatus(id: string, payload: UpdateOrderStatusRequest): Observable<AdminOrderDto> {
    return this.http.put<AdminOrderDto>(`${this.base}${API_ENDPOINTS.admin.orderStatus(id)}`, payload);
  }
}
