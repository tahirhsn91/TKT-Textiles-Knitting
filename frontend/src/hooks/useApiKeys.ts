import { useState, useCallback } from "react";
import { customFetch } from "@/vendor/api-client-react/custom-fetch";

export interface ApiKey {
  id: number;
  label: string;
  keyHint: string;
  lastUsedAt: string | null;
  expiresAt: string | null;
  revokedAt: string | null;
  createdAt: string;
}

interface CreatedApiKey extends ApiKey {
  apiKey?: string; // shown once at creation
}

interface UseApiKeysReturn {
  keys: ApiKey[];
  loading: boolean;
  error: string | null;
  list: () => Promise<void>;
  create: (label: string, expiresAt?: string | null) => Promise<CreatedApiKey>;
  revoke: (id: number) => Promise<void>;
}

export const useApiKeys = (): UseApiKeysReturn => {
  const [keys, setKeys] = useState<ApiKey[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const list = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await customFetch<ApiKey[]>("/api/keys", { method: "GET" });
      setKeys(data ?? []);
    } catch (err) {
      setError("Failed to load API keys");
      throw err;
    } finally {
      setLoading(false);
    }
  }, []);

  const create = async (label: string, expiresAt?: string | null): Promise<CreatedApiKey> => {
    try {
      const created = await customFetch<CreatedApiKey>("/api/keys", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ label, expiresAt: expiresAt ?? null }),
      });
      setKeys((prev) => [...prev, { id: created.id, label: created.label, keyHint: created.keyHint, lastUsedAt: created.lastUsedAt ?? null, expiresAt: created.expiresAt ?? null, revokedAt: null, createdAt: created.createdAt }]);
      return created;
    } catch (err) {
      setError("Failed to create API key");
      throw err;
    }
  };

  const revoke = async (id: number) => {
    try {
      await customFetch(`/api/keys/${id}/revoke`, { method: "POST" });
      setKeys((prev) => prev.filter((k) => k.id !== id));
    } catch (err) {
      setError("Failed to revoke API key");
      throw err;
    }
  };

  return { keys, loading, error, list, create, revoke };
};
