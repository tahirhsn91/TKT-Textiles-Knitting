/**
 * Hooks for FBR Digital Invoicing (issue #124).
 *
 * Wraps the invoicing + company-info endpoints with react-query + customFetch,
 * following the same pattern as use-unreconciled-nav. The invoicing flow is:
 *   pick a party with un-invoiced Fabric_Dispatch transactions → preview the
 *   aggregated items → enter per-KG rates → generate (draft) → post to FBR
 *   (manual) or delete (draft only).
 */
import { useQuery, useMutation, useQueryClient, type QueryKey, type UseQueryOptions } from "@tanstack/react-query";
import { customFetch, type ErrorType } from "@/vendor/api-client-react/custom-fetch";
import { getListPartyMasterQueryKey } from "@workspace/api-client-react";

// ─── Types (mirror the backend responses) ────────────────────────────────

export interface CompanyInfo {
  id: number;
  name: string;
  ntnCnic: string;
  province: string;
  address: string;
  fbrSandboxToken?: string | null;
  fbrProductionToken?: string | null;
  isDefault: boolean;
}

export interface UninvoicedParty {
  partyId: number;
  partyName: string;
  transactionCount: number;
  totalNetWeight: string;
}

export interface InvoiceGroup {
  yarnTypeId: number;
  yarnTypeName: string | null;
  yarnCountId: number | null;
  yarnCountName: string | null;
  hsCode: string | null;
  uoM: string | null;
  productDescription: string | null;
  quantity: string;
  transactionHeaderIds: number[];
}

export interface InvoicePreview {
  partyId: number;
  groups: InvoiceGroup[];
  transactionHeaderIds: number[];
  totalNetWeight: string;
}

export interface InvoiceListItem {
  id: number;
  invoiceDate: string;
  companyId: number;
  companyName: string | null;
  partyId: number;
  partyName: string | null;
  status: "draft" | "posted";
  origin?: "fbr" | "local" | "manual";
  dueDays?: number | null;
  dueDate?: string | null;
  paidAmount?: number;
  outstanding?: number;
  overdue?: boolean;
  paid?: boolean;
  overpaid?: number;
  fbrInvoiceNumber: string | null;
  totalValue: string;
  totalTax: string;
  grandTotal: string;
  createdBy: string;
  createdAt: string;
  postedAt: string | null;
}

export interface InvoiceItemView {
  id: number;
  yarnTypeId: number;
  yarnTypeName: string | null;
  yarnCountId: number | null;
  yarnCountName: string | null;
  hsCode: string | null;
  uoM: string | null;
  productDescription: string | null;
  quantity: string;
  ratePerKg: string;
  valueExcludingTax: string;
  taxAmount: string;
  totalValue: string;
  saleType: string;
}

export interface InvoicePayment {
  id: number;
  invoiceId: number;
  amount: string;
  taxDeduction: string;
  paymentDate: string;
  method: string | null;
  reference: string | null;
  notes: string | null;
  paidBy: string;
  createdAt: string;
}

export interface InvoiceDetail extends InvoiceListItem {
  companyNtnCnic: string | null;
  companyAddress: string | null;
  companyProvince: string | null;
  partyNtnCnic: string | null;
  partyAddress: string | null;
  partyProvince: string | null;
  partyRegistrationType: string | null;
  items: InvoiceItemView[];
  transactionHeaderIds: number[];
  payments: InvoicePayment[];
  paidAmount: number;
  outstanding: number;
  dueDate: string | null;
  overdue: boolean;
  paid: boolean;
  overpaid: number;
  totalTaxDeduction: number;
}

// ─── Company info ────────────────────────────────────────────────────────

export const companyInfoQueryKey = "/api/masters/company-info" as const;

export function useListCompanyInfo() {
  return useQuery<CompanyInfo[], ErrorType<unknown>>({
    queryKey: [companyInfoQueryKey] as unknown as QueryKey,
    queryFn: ({ signal }) => customFetch<CompanyInfo[]>(companyInfoQueryKey, { method: "GET", signal }),
    staleTime: 30_000,
  });
}

export function useCreateCompanyInfo() {
  const qc = useQueryClient();
  return useMutation<CompanyInfo, ErrorType<unknown>, Omit<CompanyInfo, "id" | "isDefault">>({
    mutationFn: (body) => customFetch<CompanyInfo>(companyInfoQueryKey, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(body) }),
    onSuccess: () => qc.invalidateQueries({ queryKey: [companyInfoQueryKey] }),
  });
}

export function useUpdateCompanyInfo() {
  const qc = useQueryClient();
  return useMutation<CompanyInfo, ErrorType<unknown>, { id: number; body: Omit<CompanyInfo, "id" | "isDefault"> }>({
    mutationFn: ({ id, body }) => customFetch<CompanyInfo>(`${companyInfoQueryKey}/${id}`, { method: "PUT", headers: { "Content-Type": "application/json" }, body: JSON.stringify(body) }),
    onSuccess: () => qc.invalidateQueries({ queryKey: [companyInfoQueryKey] }),
  });
}

export function useSetDefaultCompany() {
  const qc = useQueryClient();
  return useMutation<CompanyInfo, ErrorType<unknown>, number>({
    mutationFn: (id) => customFetch<CompanyInfo>(`${companyInfoQueryKey}/${id}/default`, { method: "POST" }),
    onSuccess: () => qc.invalidateQueries({ queryKey: [companyInfoQueryKey] }),
  });
}

export function useDeleteCompanyInfo() {
  const qc = useQueryClient();
  return useMutation<void, ErrorType<unknown>, number>({
    mutationFn: (id) => customFetch<void>(`${companyInfoQueryKey}/${id}`, { method: "DELETE" }),
    onSuccess: () => qc.invalidateQueries({ queryKey: [companyInfoQueryKey] }),
  });
}

// ─── Invoicing ───────────────────────────────────────────────────────────

export const invoicingKey = "/api/invoicing" as const;

export function useUninvoicedParties() {
  return useQuery<UninvoicedParty[], ErrorType<unknown>>({
    queryKey: [`${invoicingKey}/parties`] as unknown as QueryKey,
    queryFn: ({ signal }) => customFetch<UninvoicedParty[]>(`${invoicingKey}/parties`, { method: "GET", signal }),
    staleTime: 15_000,
  });
}

export function useInvoicePreview(partyId: number | null) {
  return useQuery<InvoicePreview, ErrorType<unknown>>({
    queryKey: [`${invoicingKey}/preview`, partyId] as unknown as QueryKey,
    queryFn: ({ signal }) => customFetch<InvoicePreview>(`${invoicingKey}/preview/${partyId}`, { method: "GET", signal }),
    enabled: partyId != null,
    staleTime: 15_000,
  });
}

export interface LatestRate {
  key: string;
  ratePerKg: string;
  invoiceDate: string;
  invoiceId: number;
}

/** Latest per-line rate for a party (key = `${yarnTypeId}|${yarnCountId}`). */
export function useLatestRates(partyId: number | null) {
  return useQuery<LatestRate[], ErrorType<unknown>>({
    queryKey: [`${invoicingKey}/rates`, partyId] as unknown as QueryKey,
    queryFn: ({ signal }) => customFetch<LatestRate[]>(`${invoicingKey}/rates/${partyId}`, { method: "GET", signal }),
    enabled: partyId != null,
    staleTime: 30_000,
  });
}

export interface FutureInvoiceRow {
  partyId: number;
  partyName: string;
  yarnTypeId: number;
  yarnTypeName: string | null;
  yarnCountId: number | null;
  yarnCountName: string | null;
  hsCode: string | null;
  uoM: string | null;
  productDescription: string | null;
  quantity: string;
  ratePerKg: number | null;
  rateDate: string | null;
  value: number | null;
  tax: number | null;
  total: number | null;
}

/** All parties' un-invoiced deliveries valued at the latest rate. */
export function useFutureInvoices(options?: { query?: Partial<UseQueryOptions<FutureInvoiceRow[], ErrorType<unknown>>> }) {
  return useQuery<FutureInvoiceRow[], ErrorType<unknown>>({
    queryKey: [`${invoicingKey}/future`] as unknown as QueryKey,
    queryFn: ({ signal }) => customFetch<FutureInvoiceRow[]>(`${invoicingKey}/future`, { method: "GET", signal }),
    staleTime: 15_000,
    ...options?.query,
  });
}

export function useListInvoices() {
  return useQuery<InvoiceListItem[], ErrorType<unknown>>({
    queryKey: [invoicingKey] as unknown as QueryKey,
    queryFn: ({ signal }) => customFetch<InvoiceListItem[]>(invoicingKey, { method: "GET", signal }),
    staleTime: 15_000,
  });
}

export function useInvoiceDetail(invoiceId: number | null) {
  return useQuery<InvoiceDetail, ErrorType<unknown>>({
    queryKey: [`${invoicingKey}/detail`, invoiceId] as unknown as QueryKey,
    queryFn: ({ signal }) => customFetch<InvoiceDetail>(`${invoicingKey}/${invoiceId}`, { method: "GET", signal }),
    enabled: invoiceId != null,
    staleTime: 15_000,
  });
}

export interface GenerateInvoiceBody {
  partyId: number;
  createdBy: string;
  items: Array<{
    yarnTypeId: number;
    yarnCountId?: number | null;
    quantity: number;
    ratePerKg: number;
  }>;
}

export function useGenerateInvoice() {
  const qc = useQueryClient();
  return useMutation<InvoiceDetail, ErrorType<unknown>, GenerateInvoiceBody>({
    mutationFn: (body) => customFetch<InvoiceDetail>(`${invoicingKey}/generate`, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(body) }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [invoicingKey] });
      qc.invalidateQueries({ queryKey: [`${invoicingKey}/parties`] });
    },
  });
}

export function usePostInvoice() {
  const qc = useQueryClient();
  return useMutation<{ message: string; invoice: InvoiceDetail }, ErrorType<unknown>, number>({
    mutationFn: (id) => customFetch<{ message: string; invoice: InvoiceDetail }>(`${invoicingKey}/${id}/post`, { method: "POST" }),
    onSuccess: () => qc.invalidateQueries({ queryKey: [invoicingKey] }),
  });
}

export function useDeleteInvoice() {
  const qc = useQueryClient();
  return useMutation<void, ErrorType<unknown>, number>({
    mutationFn: (id) => customFetch<void>(`${invoicingKey}/${id}`, { method: "DELETE" }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [invoicingKey] });
      qc.invalidateQueries({ queryKey: [`${invoicingKey}/parties`] });
    },
  });
}

// ─── Edit draft invoice rates (issue: edit rates on drafts) ──────────────
// Update the per-KG rate of one or more items on a draft invoice. The backend
// recomputes item amounts + header totals and returns the refreshed detail.

export interface UpdateDraftRatesBody {
  items: { id: number; ratePerKg: number }[];
}

export function useUpdateDraftRates() {
  const qc = useQueryClient();
  return useMutation<InvoiceDetail, ErrorType<unknown>, { id: number; body: UpdateDraftRatesBody }>({
    mutationFn: ({ id, body }) =>
      customFetch<InvoiceDetail>(`${invoicingKey}/${id}/rates`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
      }),
    onSuccess: (_data, { id }) => {
      qc.invalidateQueries({ queryKey: [invoicingKey] });
      qc.invalidateQueries({ queryKey: [`${invoicingKey}/detail`, id] });
    },
  });
}

// ─── Payments (issue #189) ────────────────────────────────────────────────

export interface CreatePaymentBody {
  amount: number;
  taxDeduction: number;
  paymentDate: string;
  method?: string | null;
  reference?: string | null;
  notes?: string | null;
}

export function useCreatePayment() {
  const qc = useQueryClient();
  return useMutation<{ payment: InvoicePayment; invoice: InvoiceDetail }, ErrorType<unknown>, { id: number; body: CreatePaymentBody }>({
    mutationFn: ({ id, body }) =>
      customFetch<{ payment: InvoicePayment; invoice: InvoiceDetail }>(`${invoicingKey}/${id}/payments`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
      }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [invoicingKey] });
      qc.invalidateQueries({ queryKey: [`${invoicingKey}/receivables`] });
    },
  });
}

export function useDeletePayment() {
  const qc = useQueryClient();
  return useMutation<{ message: string; invoice: InvoiceDetail }, ErrorType<unknown>, { id: number; paymentId: number }>({
    mutationFn: ({ id, paymentId }) =>
      customFetch<{ message: string; invoice: InvoiceDetail }>(`${invoicingKey}/${id}/payments/${paymentId}`, {
        method: "DELETE",
      }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [invoicingKey] });
      qc.invalidateQueries({ queryKey: [`${invoicingKey}/receivables`] });
    },
  });
}

// ─── Receivables (issue #189) ─────────────────────────────────────────────

export interface ReceivablesParty {
  partyId: number;
  partyName: string;
  totalInvoiced: number;
  totalPaid: number;
  outstanding: number;
  totalTaxDeduction: number;
  aging: { current: number; b1_30: number; b31_60: number; b60: number };
}

export interface ReceivablesData {
  today: string;
  parties: ReceivablesParty[];
}

export function useReceivables(options?: { query?: Partial<UseQueryOptions<ReceivablesData, ErrorType<unknown>>> }) {
  return useQuery<ReceivablesData, ErrorType<unknown>>({
    queryKey: [`${invoicingKey}/receivables`] as unknown as QueryKey,
    queryFn: ({ signal }) => customFetch<ReceivablesData>(`${invoicingKey}/receivables`, { method: "GET", signal }),
    staleTime: 15_000,
    ...options?.query,
  });
}

// ─── Backdated invoice (issue #189) ───────────────────────────────────────

export interface ConfigurationItem {
  id: number;
  name: string;
  code: string;
  description: string | null;
  enabled: boolean;
}

/** Whether the allow-backdated-invoices toggle (0003) is enabled. */
export function useAllowBackdatedInvoices() {
  return useQuery<boolean, ErrorType<unknown>>({
    queryKey: ["config", "allow-backdated"] as unknown as QueryKey,
    queryFn: async ({ signal }) => {
      const rows = await customFetch<ConfigurationItem[]>("/api/masters/configuration", { method: "GET", signal });
      return rows.some((c) => c.code === "0003" && c.enabled);
    },
    staleTime: 30_000,
  });
}

export interface BackdatedItem {
  yarnTypeId: number;
  yarnCountId?: number | null;
  hsCode?: string | null;
  uoM?: string | null;
  productDescription?: string | null;
  quantity: number;
  ratePerKg: number;
}

export interface CreateBackdatedInvoiceBody {
  id: number;
  partyId: number;
  invoiceDate: string;
  fbrInvoiceNumber?: string | null;
  items: BackdatedItem[];
}

export function useCreateBackdatedInvoice() {
  const qc = useQueryClient();
  return useMutation<{ message: string; invoice: InvoiceDetail }, ErrorType<unknown>, CreateBackdatedInvoiceBody>({
    mutationFn: (body) =>
      customFetch<{ message: string; invoice: InvoiceDetail }>(`${invoicingKey}/backdated`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
      }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [invoicingKey] });
      qc.invalidateQueries({ queryKey: [`${invoicingKey}/receivables`] });
    },
  });
}

// ─── Party master (for backdated picker) ──────────────────────────────────
// NOTE: this intentionally reuses the generated party-master lookup key and
// endpoint. The old target (GET /api/masters/party) no longer exists in the
// backend — lookups were consolidated under /api/lookups/* — so the picker
// was silently empty (404). Reusing getListPartyMasterQueryKey() also makes
// this query resolve from the cache seeded by useSeedAllLookups, so the
// backdated dialog costs zero extra requests.
export interface PartyOption {
  id: number;
  name: string;
}

export function useListPartiesForInvoicing(options?: { query?: Partial<UseQueryOptions<PartyOption[], ErrorType<unknown>>> }) {
  return useQuery<PartyOption[], ErrorType<unknown>>({
    queryKey: getListPartyMasterQueryKey() as unknown as QueryKey,
    queryFn: ({ signal }) => customFetch<PartyOption[]>("/api/lookups/party-master", { method: "GET", signal }),
    staleTime: 60_000,
    ...options?.query,
  });
}
