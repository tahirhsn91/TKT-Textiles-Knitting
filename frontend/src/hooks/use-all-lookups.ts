import { useEffect } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { customFetch } from "@/vendor/api-client-react/custom-fetch";
import {
  getListJobMasterQueryKey,
  getListPartyMasterQueryKey,
  getListMachineMasterQueryKey,
  getListLocationMasterQueryKey,
  getListYarnTypeMasterQueryKey,
  getListYarnCountMasterQueryKey,
  getListYarnBrandMasterQueryKey,
  getListUomMasterQueryKey,
  getListFabricTypeMasterQueryKey,
  getListEmployeeMasterQueryKey,
  getListTransactionTypeMasterQueryKey,
  getListDepartmentMasterQueryKey,
} from "@workspace/api-client-react";

/**
 * Response of GET /api/lookups/all — every lookup list batched into one
 * request (issue #19).
 */
export interface AllLookupsResponse {
  transactionTypes: unknown[];
  jobs: unknown[];
  parties: unknown[];
  machines: unknown[];
  locations: unknown[];
  yarnTypes: unknown[];
  yarnCounts: unknown[];
  yarnBrands: unknown[];
  uoms: unknown[];
  fabricTypes: unknown[];
  employees: unknown[];
  departments: unknown[];
}

/**
 * Fetch ALL lookup/master lists in a single request and seed each individual
 * lookup cache (via setQueryData) so the existing generated `useList*Master`
 * hooks resolve from cache instead of firing N parallel HTTP calls.
 *
 * Call this once at the app root (Layout). Returns richer data only as the
 * single aggregate query result — most screens keep using the per-list hook.
 */
export function useSeedAllLookups(enabled = true) {
  const queryClient = useQueryClient();

  const query = useQuery<AllLookupsResponse>({
    queryKey: ["/api/lookups/all"],
    queryFn: () => customFetch<AllLookupsResponse>("/api/lookups/all", { method: "GET" }),
    // The Master Data page lazy-loads each tab's data on activation, so it opts
    // out of the aggregate prefetch (issue #19 follow-up): pass enabled=false to
    // skip the one-shot load-everything call there.
    enabled,
    staleTime: 30 * 60 * 1000, // lookups change rarely — cache 30 min
    gcTime: 60 * 60 * 1000,
  });

  // Seed each individual lookup cache from the single aggregate response so the
  // existing generated useList*Master hooks resolve from cache (no N requests).
  useEffect(() => {
    const data = query.data;
    if (!data) return;
    queryClient.setQueryData(getListTransactionTypeMasterQueryKey(), data.transactionTypes);
    queryClient.setQueryData(getListJobMasterQueryKey(), data.jobs);
    queryClient.setQueryData(getListPartyMasterQueryKey(), data.parties);
    queryClient.setQueryData(getListMachineMasterQueryKey(), data.machines);
    queryClient.setQueryData(getListLocationMasterQueryKey(), data.locations);
    queryClient.setQueryData(getListYarnTypeMasterQueryKey(), data.yarnTypes);
    queryClient.setQueryData(getListYarnCountMasterQueryKey(), data.yarnCounts);
    queryClient.setQueryData(getListYarnBrandMasterQueryKey(), data.yarnBrands);
    queryClient.setQueryData(getListUomMasterQueryKey(), data.uoms);
    queryClient.setQueryData(getListFabricTypeMasterQueryKey(), data.fabricTypes);
    queryClient.setQueryData(getListEmployeeMasterQueryKey(), data.employees);
    queryClient.setQueryData(getListDepartmentMasterQueryKey(), data.departments);
  }, [query.data, queryClient]);

  return query;
}
