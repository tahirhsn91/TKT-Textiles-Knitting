import { useAuth } from "@/context/auth-context";
import { useBranding } from "@/hooks/useBranding";

/**
 * BrandingApplier — issue #219 1.2 white-labeling.
 *
 * Loads the active tenant's branding once the user is authenticated and a
 * tenant context is selected, applying its CSS variables and document title
 * app-wide (via the useBranding hook's side effects). Renders nothing.
 *
 * Fire-and-forget: the fetch is gated on isAuthenticated && activeTenantId so
 * it never fires on the login page or before a tenant is chosen.
 */
export function BrandingApplier() {
  const { isAuthenticated, activeTenantId } = useAuth();
  const enabled = isAuthenticated && activeTenantId != null;
  useBranding(enabled);
  return null;
}
