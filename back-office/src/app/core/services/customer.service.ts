import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '@env/environment';
import { API_ENDPOINTS } from '@app/core/constants/api-endpoints.constants';
import { toHttpParams } from '@app/core/utils/http-params.util';
import type { Paged, PageQuery } from '@app/core/interfaces/common.interfaces';
import type { CustomerDto } from '@app/core/interfaces/customer.interfaces';

@Injectable({ providedIn: 'root' })
export class CustomerService {
  private readonly http = inject(HttpClient);
  private readonly base = environment.apiUrl;

  list(query: PageQuery & { search?: string }): Observable<Paged<CustomerDto>> {
    const params = toHttpParams({
      search: query.search,
      page: query.page,
      pageSize: query.pageSize,
    });
    return this.http.get<Paged<CustomerDto>>(`${this.base}${API_ENDPOINTS.admin.customers}`, {
      params,
    });
  }
}
