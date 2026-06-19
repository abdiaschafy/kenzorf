/** Rôles applicatifs — KENZORF mono-tenant : `Customer` et `Admin`. */
export const USER_ROLE = {
  Customer: 'Customer',
  Admin: 'Admin',
} as const;

export type UserRole = (typeof USER_ROLE)[keyof typeof USER_ROLE];
