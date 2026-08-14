import { useAuth } from "@/context/auth-context";

/**
 * Returns the currently logged-in user's display name so forms can auto-fill
 * the "Entered By" field (read-only) instead of letting the user type a name.
 */
export function useCurrentUserDisplayName(): string {
  const { session } = useAuth();
  return session?.user?.displayName?.trim() || session?.user?.username || "";
}
