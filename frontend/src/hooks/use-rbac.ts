import { useQuery, useMutation, useQueryClient, type QueryKey } from "@tanstack/react-query";
import { customFetch, type ErrorType } from "@/vendor/api-client-react/custom-fetch";
import type { AuthRole, AuthUser } from "@/context/auth-context";

// ─── Types (mirror the backend /api/users responses) ────────────────────────

export interface UserView {
  id: number;
  username: string;
  displayName: string;
  roleId: number;
  roleName: string;
  employeeId: number | null;
  isActive: boolean;
}

export interface RoleView {
  id: number;
  name: string;
  isAdmin: boolean;
}

export interface RolePermissions {
  roleId: number;
  role: string;
  isAdmin: boolean;
  permissions: string[];
}

const usersKey = "/api/users" as const;

/** List roles (GET /api/users/roles). */
export function useListRoles() {
  return useQuery<RoleView[], ErrorType<unknown>>({
    queryKey: [`${usersKey}/roles`] as unknown as QueryKey,
    queryFn: () => customFetch<RoleView[]>(`${usersKey}/roles`, { method: "GET" }),
  });
}

/** Full role × route permission matrix (GET /api/users/permissions). */
export function useRolePermissions() {
  return useQuery<RolePermissions[], ErrorType<unknown>>({
    queryKey: [`${usersKey}/permissions`] as unknown as QueryKey,
    queryFn: () => customFetch<RolePermissions[]>(`${usersKey}/permissions`, { method: "GET" }),
  });
}

/** List users (GET /api/users). */
export function useListUsers() {
  return useQuery<UserView[], ErrorType<unknown>>({
    queryKey: [usersKey] as unknown as QueryKey,
    queryFn: () => customFetch<UserView[]>(usersKey, { method: "GET" }),
  });
}

export interface CreateUserBody {
  username: string;
  displayName: string;
  password: string;
  roleId: number;
  employeeId?: number | null;
  isActive?: boolean;
}

/** Create a user (POST /api/users). */
export function useCreateUser() {
  const qc = useQueryClient();
  return useMutation<UserView, ErrorType<unknown>, CreateUserBody>({
    mutationFn: (body) =>
      customFetch<UserView>(usersKey, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(body) }),
    onSuccess: () => qc.invalidateQueries({ queryKey: [usersKey] }),
  });
}

export interface UpdateUserBody {
  displayName?: string;
  roleId?: number;
  employeeId?: number | null;
  isActive?: boolean;
}

/** Update a user (PATCH /api/users/:id). */
export function useUpdateUser() {
  const qc = useQueryClient();
  return useMutation<UserView, ErrorType<unknown>, { id: number; body: UpdateUserBody }>({
    mutationFn: ({ id, body }) =>
      customFetch<UserView>(`${usersKey}/${id}`, { method: "PATCH", headers: { "Content-Type": "application/json" }, body: JSON.stringify(body) }),
    onSuccess: () => qc.invalidateQueries({ queryKey: [usersKey] }),
  });
}

/** Reset a user's password (PUT /api/users/:id/password). */
export function useResetPassword() {
  const qc = useQueryClient();
  return useMutation<{ ok: boolean }, ErrorType<unknown>, { id: number; password: string }>({
    mutationFn: ({ id, password }) =>
      customFetch<{ ok: boolean }>(`${usersKey}/${id}/password`, { method: "PUT", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ password }) }),
    onSuccess: () => qc.invalidateQueries({ queryKey: [usersKey] }),
  });
}

/** Delete a user (DELETE /api/users/:id). Admin-only, enforced server-side. */
export function useDeleteUser() {
  const qc = useQueryClient();
  return useMutation<{ ok: boolean }, ErrorType<unknown>, { id: number }>({
    mutationFn: ({ id }) =>
      customFetch<{ ok: boolean }>(`${usersKey}/${id}`, { method: "DELETE" }),
    onSuccess: () => qc.invalidateQueries({ queryKey: [usersKey] }),
  });
}

/** Replace a role's permission set (PUT /api/users/permissions). */
export function useSavePermissions() {
  const qc = useQueryClient();
  return useMutation<{ ok: boolean }, ErrorType<unknown>, { roleId: number; permissions: string[] }>({
    mutationFn: ({ roleId, permissions }) =>
      customFetch<{ ok: boolean }>(`${usersKey}/permissions`, { method: "PUT", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ roleId, permissions }) }),
    onSuccess: () => qc.invalidateQueries({ queryKey: [`${usersKey}/permissions`] }),
  });
}

// ─── Self-service password change (PUT /api/auth/password) ───────────────

export interface ChangePasswordBody {
  currentPassword: string;
  newPassword: string;
}

/** Change the signed-in user's own password. Session token stays valid. */
export function useChangePassword() {
  return useMutation<{ ok: boolean }, ErrorType<unknown>, ChangePasswordBody>({
    mutationFn: (body) =>
      customFetch<{ ok: boolean }>("/api/auth/password", {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
      }),
  });
}

// Convenience: reuse the auth role type for created roles where compatible.
export type { AuthRole, AuthUser };
