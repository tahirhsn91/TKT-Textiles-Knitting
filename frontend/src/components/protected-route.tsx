import type { ReactNode } from "react";
import { useLocation } from "wouter";
import { useAuth } from "@/context/auth-context";
import { Layout } from "@/components/layout";

/**
 * Route-level permission guard (issue #135). Wraps a wouter Route component:
 *  - Unauthenticated (loading or no session) → redirect to /login, remembering
 *    where the user was headed so login can return there.
 *  - Authenticated but lacking the module permission → 403 screen.
 *  - Authenticated + allowed → render children.
 *
 * `moduleId` is the route key the admin toggles in the permissions matrix
 * (same key the backend requirePermission uses).
 */
export function ProtectedRoute({
  moduleId,
  children,
}: {
  moduleId: string;
  children: ReactNode;
}) {
  const { session, loading, isAuthenticated, can } = useAuth();
  const [, setLocation] = useLocation();

  // Still restoring the boot session — show nothing (or the layout skeleton).
  if (loading) {
    return (
      <Layout>
        <div className="h-32 animate-pulse rounded-lg bg-muted" />
      </Layout>
    );
  }

  if (!isAuthenticated) {
    // Remember the target so we can return after login.
    try {
      sessionStorage.setItem("tkt_redirect", window.location.pathname + window.location.search);
    } catch {
      /* ignore */
    }
    setLocation("/login");
    return null;
  }

  if (!can(moduleId)) {
    return (
      <Layout>
        <NotAuthorized moduleId={moduleId} />
      </Layout>
    );
  }

  return <>{children}</>;
}

/** 403 screen shown when an authenticated role cannot access a route. */
function NotAuthorized({ moduleId }: { moduleId: string }) {
  const [, setLocation] = useLocation();
  const { session } = useAuth();
  return (
    <div className="flex flex-col items-center justify-center gap-3 py-16 text-center">
      <p className="eyebrow">403 · Access denied</p>
      <h1 className="text-2xl font-semibold tracking-tight text-foreground">You don’t have access</h1>
      <p className="max-w-md text-sm text-muted-foreground">
        Your role ({session?.role.name ?? "—"}) doesn’t have permission to open{" "}
        <span className="font-medium text-foreground">“{moduleId}”</span>. Ask an admin to grant it.
      </p>
      <div className="mt-2 flex gap-3">
        <button
          onClick={() => setLocation("/dashboard")}
          className="rounded-md bg-foreground px-4 py-2 text-sm font-medium text-background hover:opacity-90"
        >
          Go to Dashboard
        </button>
      </div>
    </div>
  );
}

/** A public route (not behind auth) — used for /login. */
export function PublicRoute({ children }: { children: ReactNode }) {
  return <>{children}</>;
}
