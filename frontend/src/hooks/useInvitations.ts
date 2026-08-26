import { useState, useCallback } from "react";
import { customFetch } from "@/vendor/api-client-react/custom-fetch";

export interface Invitation {
  id: number;
  email: string;
  role: string;
  status: "pending" | "accepted" | "revoked" | "expired";
  token?: string;
  expires_at?: string | null;
  created_at?: string | null;
}

interface UseInvitationsReturn {
  invitations: Invitation[];
  loading: boolean;
  error: string | null;
  list: () => Promise<void>;
  create: (email: string, role: string) => Promise<Invitation>;
  revoke: (token: string) => Promise<void>;
}

export const useInvitations = (): UseInvitationsReturn => {
  const [invitations, setInvitations] = useState<Invitation[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const list = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await customFetch<Invitation[]>("/api/invitations", { method: "GET" });
      setInvitations(data ?? []);
    } catch (err) {
      setError("Failed to load invitations");
      throw err;
    } finally {
      setLoading(false);
    }
  }, []);

  const create = async (email: string, role: string): Promise<Invitation> => {
    try {
      const invite = await customFetch<Invitation>("/api/invitations", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, role }),
      });
      setInvitations((prev) => [...prev, invite]);
      return invite;
    } catch (err) {
      setError("Failed to create invitation");
      throw err;
    }
  };

  const revoke = async (token: string) => {
    try {
      await customFetch(`/api/invitations/${token}/revoke`, { method: "POST" });
      setInvitations((prev) => prev.map((i) => (i.token === token ? { ...i, status: "revoked" } : i)));
    } catch (err) {
      setError("Failed to revoke invitation");
      throw err;
    }
  };

  return { invitations, loading, error, list, create, revoke };
};
