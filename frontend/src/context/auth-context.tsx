import { createContext, useContext, useEffect, useState, type ReactNode } from "react";
import { useQueryClient } from "@tanstack/react-query";
import { customFetch, setAuthTokenGetter } from "@/vendor/api-client-react/custom-fetch";
import { setUnauthorizedHandler, setTenantIdGetter } from "@/lib/http-client";
import { useLocation } from "wouter";

// ─── Auth API shapes (mirror the backend responses, issue #135) ─────────────

export interface AuthUser {
  id: number;
  username: string;
  displayName: string;
  employeeId: number | null;
}

export interface AuthRole {
  id: number;
  name: string;
  isAdmin: boolean;
  /** The super-admin role is platform-global (issue #219). */
  isSuperAdmin?: boolean;
}

export interface AuthSession {
  user: AuthUser;
  role: AuthRole;
  /** The user's home tenant (null for platform super-admins). */
  tenantId: number | null;
  permissions: string[]; // moduleIds this role can access; ["*"] = admin (all routes)
}

const TOKEN_KEY = "tkt_auth_token";
// Persist the super-admin's selected active tenant across reloads.
const ACTIVE_TENANT_KEY = "tkt_active_tenant";

/** Read the bearer token from localStorage (safe getter — never throws). */
export function getStoredToken(): string | null {
  try {
    return localStorage.getItem(TOKEN_KEY);
  } catch {
    return null;
  }
}

function storeToken(token: string | null): void {
  try {
    if (token) localStorage.setItem(TOKEN_KEY, token);
    else localStorage.removeItem(TOKEN_KEY);
  } catch {
    /* storage unavailable — session proceeds in-memory only */
  }
}

type AuthContextValue = {
  /** The auth session, or null when not authenticated / still restoring. */
  session: AuthSession | null;
  /** True while the boot `GET /api/auth/me` is still resolving. */
  loading: boolean;
  login: (username: string, password: string) => Promise<AuthSession>;
  logout: () => void;
  /** True when the current role may access the moduleId route. */
  can: (moduleId: string) => boolean;
  /** True while the user is fully authenticated (session loaded). */
  isAuthenticated: boolean;
  /** True when the signed-in user holds the platform super-admin role. */
  isSuperAdmin: boolean;
  /**
   * The active tenant id for the current session. For tenant users this is
   * their home tenant. For super-admins it is the tenant they selected in the
   * tenant switcher (null until one is chosen — the UI blocks tenant-scoped
   * screens until then, issue #219 Q3b).
   */
  activeTenantId: number | null;
  /**
   * Switch the super-admin's active tenant context. Tenant-scoped data and
   * APIs follow via the X-Tenant-Id header; caches are cleared on switch
   * (issue #219 Q3d). No-op for non-super-admins (they cannot switch).
   */
  switchTenant: (tenantId: number) => void;
};

const AuthContext = createContext<AuthContextValue | null>(null);

/**
 * Global auth provider (issue #135). Holds the resolved session, keeps the
 * `customFetch` bearer getter in sync with the stored token, and restores the
 * session on boot via GET /api/auth/me.
 */
export function AuthProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<AuthSession | null>(null);
  const [loading, setLoading] = useState(true);
  const [activeTenantId, setActiveTenantId] = useState<number | null>(null);
  const queryClient = useQueryClient();
  const [, setLocation] = useLocation();

  // Keep the customFetch bearer getter in sync whenever the token changes.
  useEffect(() => {
    setAuthTokenGetter(() => getStoredToken());
    return () => setAuthTokenGetter(null);
  }, []);

  // Keep the API client's active-tenant getter in sync with auth context, so
  // every request carries the X-Tenant-Id header for the current context.
  useEffect(() => {
    return setTenantIdGetter(() => activeTenantId);
  }, [activeTenantId]);

  // App-wide auth middleware: when an API call returns 401 Unauthorized (an
  // expired/invalid bearer token), log the user out and redirect to /login.
  // The Axios interceptor in src/lib/http-client.ts invokes this handler via
  // setUnauthorizedHandler (and skips the /api/auth/login call itself, so
  // invalid credentials still surface as a normal login-page error).
  useEffect(() => {
    const runLogoutAndRedirect = () => {
      // Drop the stored token + in-memory session (logout).
      storeToken(null);
      setSession(null);
      // Remember where the user was so login can return there.
      try {
        sessionStorage.setItem(
          "tkt_redirect",
          window.location.pathname + window.location.search,
        );
      } catch {
        /* ignore */
      }
      setLocation("/login");
    };
    return setUnauthorizedHandler(runLogoutAndRedirect);
  }, [setLocation]);

  // Restore the session on boot (and when the token changes).
  useEffect(() => {
    let cancelled = false;
    const token = getStoredToken();
    if (!token) {
      setSession(null);
      setLoading(false);
      return;
    }
    customFetch<AuthSession>("/api/auth/me", { method: "GET" })
      .then((s) => {
        if (cancelled) return;
        setSession(s);
        // Establish active tenant: super-admin restores their last selection
        // (or null → blocked until they pick), tenant users use their home tenant.
        const restored = s.role.isSuperAdmin
          ? (() => {
              try { const v = localStorage.getItem(ACTIVE_TENANT_KEY); return v ? Number(v) : null; } catch { return null; }
            })()
          : s.tenantId;
        setActiveTenantId(restored);
      })
      .catch(() => {
        storeToken(null);
        if (!cancelled) setSession(null);
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, []);

  const login = async (username: string, password: string): Promise<AuthSession> => {
    const data = await customFetch<{ token: string } & AuthSession>("/api/auth/login", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ username, password }),
    });
    const sess: AuthSession = {
      user: data.user,
      role: data.role,
      tenantId: data.tenantId,
      permissions: data.permissions,
    };
    storeToken(data.token);
    setSession(sess);
    setActiveTenantId(sess.role.isSuperAdmin ? null : sess.tenantId);
    return sess;
  };

  const logout = () => {
    storeToken(null);
    setSession(null);
    setActiveTenantId(null);
    try { localStorage.removeItem(ACTIVE_TENANT_KEY); } catch { /* ignore */ }
  };

  /** Switch the super-admin's active tenant (no token re-issue — header only). */
  const switchTenant = (tenantId: number) => {
    setActiveTenantId((prev) => {
      if (prev === tenantId) return prev; // no-op if unchanged
      // Clear all cached query data so the previous tenant's data is never
      // shown under the new tenant context (issue #219 Q3d).
      queryClient.clear();
      return tenantId;
    });
    try { localStorage.setItem(ACTIVE_TENANT_KEY, String(tenantId)); } catch { /* ignore */ }
  };

  const can = (moduleId: string): boolean => {
    if (!session) return false;
    if (session.role.isAdmin || session.role.isSuperAdmin) return true;
    return session.permissions.includes(moduleId);
  };

  const isSuperAdmin = session?.role.isSuperAdmin ?? false;

  const value: AuthContextValue = {
    session,
    loading,
    login,
    logout,
    can,
    isAuthenticated: session != null,
    isSuperAdmin,
    activeTenantId,
    switchTenant,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

/** Access the auth context. Throws outside the provider. */
export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within an AuthProvider");
  return ctx;
}
