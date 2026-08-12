/**
 * Hooks for FBR Digital Invoicing (issue #124).
 *
 * Wraps the invoicing + company-info endpoints with react-query + customFetch,
 * following the same pattern as use-unreconciled-nav. The invoicing flow is:
 *   pick a party with un-invoiced Fabric_Dispatch transactions → preview the
 *   aggregated items → enter per-KG rates → generate (draft) → post to FBR
 *   (manual) or delete (draft only).
 */
import { useQuery, useMutation, useQueryClient, type QueryKey } from "@tanstack/react-query";
import { customFetch, type ErrorType } from "@/vendor/api-client-react/custom-fetch";

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

export interface InvoiceDetail extends InvoiceListItem {
  items: InvoiceItemView[];
  transactionHeaderIds: number[];
}

// ─── Company info ────────────────────────────────────────────────────────

export const companyInfoQueryKey = "/api/masters/company-info" as const;

export function useListCompanyInfo() {
  return useQuery<CompanyInfo[], ErrorType<unknown>>({
    queryKey: [companyInfoQueryKey] as unknown as QueryKey,
    queryFn: () => customFetch<CompanyInfo[]>(companyInfoQueryKey, { method: "GET" }),
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
    queryFn: () => customFetch<UninvoicedParty[]>(`${invoicingKey}/parties`, { method: "GET" }),
    staleTime: 15_000,
  });
}

export function useInvoicePreview(partyId: number | null) {
  return useQuery<InvoicePreview, ErrorType<unknown>>({
    queryKey: [`${invoicingKey}/preview`, partyId] as unknown as QueryKey,
    queryFn: () => customFetch<InvoicePreview>(`${invoicingKey}/preview/${partyId}`, { method: "GET" }),
    enabled: partyId != null,
    staleTime: 15_000,
  });
}

export function useListInvoices() {
  return useQuery<InvoiceListItem[], ErrorType<unknown>>({
    queryKey: [invoicingKey] as unknown as QueryKey,
    queryFn: () => customFetch<InvoiceListItem[]>(invoicingKey, { method: "GET" }),
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
