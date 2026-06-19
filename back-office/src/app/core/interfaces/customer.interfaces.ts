/**
 * Client côté admin (spec : CustomerDto, paginé via GET /admin/customers).
 * La spec ne fige pas tous les champs ; on retient l'identité + métriques usuelles.
 */
export interface CustomerDto {
  readonly id: string;
  readonly firstName: string;
  readonly lastName: string;
  readonly email: string;
  readonly phoneNumber?: string;
  readonly orderCount?: number;
  readonly totalSpent?: number;
  readonly currency?: string;
  readonly createdAt?: string;
}
