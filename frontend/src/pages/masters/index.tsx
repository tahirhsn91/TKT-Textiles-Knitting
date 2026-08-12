import { useState } from "react";
import { useQueryClient } from "@tanstack/react-query";
import {
  useListTransactionTypeMasterCrud,
  useCreateTransactionTypeMaster,
  useUpdateTransactionTypeMaster,
  useDeleteTransactionTypeMaster,
  getListTransactionTypeMasterCrudQueryKey,
  getListTransactionTypeMasterQueryKey,
  useListJobMasterCrud,
  useCreateJobMaster,
  useUpdateJobMaster,
  useDeleteJobMaster,
  useListPartyMasterCrud,
  useCreatePartyMaster,
  useUpdatePartyMaster,
  useDeletePartyMaster,
  useListMachineMasterCrud,
  useCreateMachineMaster,
  useUpdateMachineMaster,
  useDeleteMachineMaster,
  useListLocationMasterCrud,
  useCreateLocationMaster,
  useUpdateLocationMaster,
  useDeleteLocationMaster,
  useListYarnTypeMasterCrud,
  useCreateYarnTypeMaster,
  useUpdateYarnTypeMaster,
  useDeleteYarnTypeMaster,
  useListYarnCountMasterCrud,
  useCreateYarnCountMaster,
  useUpdateYarnCountMaster,
  useDeleteYarnCountMaster,
  useListYarnBrandMasterCrud,
  useCreateYarnBrandMaster,
  useUpdateYarnBrandMaster,
  useDeleteYarnBrandMaster,
  useListUomMasterCrud,
  useCreateUomMaster,
  useUpdateUomMaster,
  useDeleteUomMaster,
  useListFabricTypeMasterCrud,
  useCreateFabricTypeMaster,
  useUpdateFabricTypeMaster,
  useDeleteFabricTypeMaster,
  useListEmployeeMasterCrud,
  useCreateEmployeeMaster,
  useUpdateEmployeeMaster,
  useDeleteEmployeeMaster,
  useListDepartmentMasterCrud,
  useCreateDepartmentMaster,
  useUpdateDepartmentMaster,
  useDeleteDepartmentMaster,
  useListConfigurationCrud,
  getListJobMasterCrudQueryKey,
  getListPartyMasterCrudQueryKey,
  getListMachineMasterCrudQueryKey,
  getListLocationMasterCrudQueryKey,
  getListYarnTypeMasterCrudQueryKey,
  getListYarnCountMasterCrudQueryKey,
  getListYarnBrandMasterCrudQueryKey,
  getListUomMasterCrudQueryKey,
  getListFabricTypeMasterCrudQueryKey,
  getListEmployeeMasterCrudQueryKey,
  getListDepartmentMasterCrudQueryKey,
  getListMachineMasterQueryKey,
  getListJobMasterQueryKey,
  getListPartyMasterQueryKey,
  getListLocationMasterQueryKey,
  getListYarnTypeMasterQueryKey,
  getListYarnCountMasterQueryKey,
  getListYarnBrandMasterQueryKey,
  getListUomMasterQueryKey,
  getListFabricTypeMasterQueryKey,
  getListEmployeeMasterQueryKey,
  getListDepartmentMasterQueryKey,
} from "@workspace/api-client-react";
import { X, Tag, Briefcase, Building2, Cog, MapPin, SwatchBook, Hash, BadgeCheck, Ruler, Layers, Users, Scissors, Settings2, Landmark } from "lucide-react";
import { useRef } from "react";
import { Layout } from "@/components/layout";
import { MasterTable } from "@/components/master-table";
import { Button } from "@/components/ui/button";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { MachineAnalyticsView } from "./machine-analytics";
import { PartyAnalyticsView } from "./party-analytics";
import { CompanyInfoSection } from "@/pages/company-info";
import { PartySection } from "./party-section";
import { cn } from "@/lib/utils";
import { useIsMobile } from "@/hooks/use-mobile";
import {
  Select,
  SelectContent,
  SelectGroup,
  SelectItem,
  SelectLabel,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";

// ─── Shared invalidation helper ────────────────────────────────────────────
function useInvalidateBoth() {
  const qc = useQueryClient();
  return (crudKey: readonly unknown[], lookupKey: readonly unknown[]) => {
    qc.invalidateQueries({ queryKey: [...crudKey] });
    qc.invalidateQueries({ queryKey: [...lookupKey] });
    void qc.refetchQueries({ queryKey: [...lookupKey], type: "all" });
  };
}

// ─── Page ──────────────────────────────────────────────────────────────────
// Each tab's data is fetched inside its own child component. Because Radix
// unmounts inactive TabsContent, a tab's list/CRUD queries only fire once the
// user actually navigates to that tab — not all at once on page load.
// ─── Tab metadata ──────────────────────────────────────────────────────────
// One source of truth for the 13 master-data tabs. Each carries an icon and a
// group so the menu strip can render a grouped rail instead of a flat wall of
// thirteen text pills — on a phone that is a horizontally scrollable icon rail,
// on desktop a sticky bar with hairline group separators.
const TABS = [
  { id: "transaction-type", label: "Transaction Type", short: "Trans. Type", icon: Tag, group: "Operations" },
  { id: "job",               label: "Job Types",       short: "Job Types",   icon: Briefcase, group: "Operations" },
  { id: "party",             label: "Parties",         short: "Parties",     icon: Building2, group: "Operations" },
  { id: "machine",           label: "Machines",        short: "Machines",    icon: Cog, group: "Operations" },
  { id: "location",          label: "Locations",       short: "Locations",   icon: MapPin, group: "Operations" },
  { id: "department",        label: "Departments",     short: "Depts",       icon: Layers, group: "Operations" },
  { id: "employee",          label: "Employees",       short: "Employees",   icon: Users, group: "Operations" },
  { id: "yarn-type",         label: "Yarn Type",       short: "Yarn Type",   icon: SwatchBook, group: "Yarn" },
  { id: "yarn-count",        label: "Yarn Count",      short: "Yarn Count",  icon: Hash, group: "Yarn" },
  { id: "yarn-brand",        label: "Yarn Brand",      short: "Yarn Brand",  icon: BadgeCheck, group: "Yarn" },
  { id: "uom",               label: "UOM",             short: "UOM",         icon: Ruler, group: "Yarn" },
  { id: "fabric-type",       label: "Fabric Type",     short: "Fabric",      icon: Scissors, group: "Product" },
  { id: "configuration",     label: "Configuration",   short: "Config",      icon: Settings2, group: "System" },
  { id: "company-info",      label: "Company Info",    short: "Company",     icon: Landmark, group: "System" },
];

const TAB_IDS = TABS.map((t) => t.id);
// Ordered distinct groups, in display order.
const TAB_GROUPS = Array.from(new Set(TABS.map((t) => t.group)));

export default function MastersPage() {
  // Active tab lives in the URL hash (#machines) so a refresh lands back on
  // the same tab and a tab is shareable/deep-linkable. Falls back to the
  // first tab when the hash is empty or unknown.
  const [activeTab, setActiveTab] = useState(() => {
    const fromHash = window.location.hash.replace(/^#\/?/, "");
    return TAB_IDS.includes(fromHash) ? fromHash : "transaction-type";
  });
  // The scrollable rail on mobile — scrolled so the active tab is always in
  // view after a change (or on first paint from a deep link / refresh).
  const railRef = useRef<HTMLDivElement>(null);

  const handleTabChange = (tab: string) => {
    setActiveTab(tab);
    window.location.hash = tab;
  };

  return (
    <Layout>
      <div className="flex flex-col gap-6">
        {/* Page header matches dashboard and daily production: eyebrow, then a
            1.75rem semibold title on a hairline rule. The previous
            text-3xl font-bold was the shadcn default and one of four different
            h1 treatments across the app. */}
        <header className="border-b pb-5">
          <p className="eyebrow">Reference data</p>
          <h1 className="mt-2 text-[1.75rem] font-semibold leading-none text-foreground">
            Master data
          </h1>
          <p className="mt-2 text-sm text-muted-foreground">
            The lookup tables every transaction, production entry and payroll run draws from.
          </p>
        </header>

        <Tabs value={activeTab} onValueChange={handleTabChange} defaultValue="transaction-type">
          {/* ── Layout: dropdown (mobile) or two-pane (desktop) ────────────
               Thirteen reference lists are too many for a horizontal tab bar —
               every single-row treatment either clipped, distributed, or
               wrapped awkwardly. So a desktop shows them all in a grouped
               vertical nav panel (mirroring the app's own dark-bezel
               sidebar), with the selected table content beside it. A phone
               gets a grouped dropdown instead. */}
          <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:gap-6">
            {/* ── Mobile: a grouped dropdown picker ──────────────────────── */}
            <div className="sm:hidden">
              <Select value={activeTab} onValueChange={handleTabChange}>
                <SelectTrigger className="h-11 w-full bg-sidebar text-sidebar-foreground ring-offset-sidebar">
                  <SelectValue placeholder="Select a master list">
                    {(() => {
                      const current = TABS.find((t) => t.id === activeTab);
                      if (!current) return null;
                      const Icon = current.icon;
                      return (
                        <span className="flex items-center gap-2">
                          <Icon className="h-4 w-4 text-signal" />
                          {current.label}
                        </span>
                      );
                    })()}
                  </SelectValue>
                </SelectTrigger>
                <SelectContent>
                  {TAB_GROUPS.map((group) => (
                    <SelectGroup key={group}>
                      <SelectLabel>{group}</SelectLabel>
                      {TABS.filter((t) => t.group === group).map((tab) => {
                        const Icon = tab.icon;
                        return (
                          <SelectItem key={tab.id} value={tab.id}>
                            <span className="flex items-center gap-2">
                              <Icon className="h-4 w-4 opacity-70" />
                              {tab.label}
                            </span>
                          </SelectItem>
                        );
                      })}
                    </SelectGroup>
                  ))}
                </SelectContent>
              </Select>
            </div>

            {/* ── Desktop: grouped vertical nav panel ──────────────────────
                 All 13 lists listed under category headers, exactly like the
                 app's sidebar: dark bezel, selvedge tick on the active row,
                 signal icon. Hidden on a phone (dropdown above takes over).
                 The Radix Tabs.List is the wrapper so every Trigger keeps its
                 RovingFocusGroup context. */}
            <TabsList
              className="hidden w-full shrink-0 flex-col items-stretch gap-0.5 rounded-lg border border-sidebar-border bg-sidebar p-2 shadow-sm sm:flex sm:w-60 sm:h-auto sm:justify-start"
              ref={railRef}
            >
              {TAB_GROUPS.map((group) => (
                <div key={group} className="contents">
                  <span
                    aria-hidden
                    className="px-3 pt-3 pb-1 text-[0.625rem] font-semibold uppercase tracking-[0.16em] text-sidebar-foreground/45"
                  >
                    {group}
                  </span>
                  {TABS.filter((t) => t.group === group).map((tab) => {
                    const active = activeTab === tab.id;
                    const Icon = tab.icon;
                    return (
                      <TabsTrigger
                        key={tab.id}
                        value={tab.id}
                        className={cn(
                          "flex min-h-9 items-center gap-2.5 rounded-md px-3 py-2 text-sm font-medium transition-colors",
                          active
                            ? "selvedge bg-sidebar-accent text-sidebar-accent-foreground [&_svg]:text-signal"
                            : "text-sidebar-foreground/70 hover:bg-sidebar-accent/60 hover:text-sidebar-accent-foreground"
                        )}
                      >
                        <Icon className="h-4 w-4 shrink-0" />
                        {tab.label}
                      </TabsTrigger>
                    );
                  })}
                </div>
              ))}
            </TabsList>

            {/* ── Content column ─────────────────────────────────────────── */}
            <div className="min-w-0 flex-1">
              <TabsContent value="transaction-type" className="mt-0"><TransactionTypeTab /></TabsContent>
              <TabsContent value="job" className="mt-0"><JobTab /></TabsContent>
              <TabsContent value="party" className="mt-0"><PartyTab /></TabsContent>
              <TabsContent value="machine" className="mt-0"><MachineTab /></TabsContent>
              <TabsContent value="location" className="mt-0"><LocationTab /></TabsContent>
              <TabsContent value="yarn-type" className="mt-0"><YarnTypeTab /></TabsContent>
              <TabsContent value="yarn-count" className="mt-0"><YarnCountTab /></TabsContent>
              <TabsContent value="yarn-brand" className="mt-0"><YarnBrandTab /></TabsContent>
              <TabsContent value="uom" className="mt-0"><UomTab /></TabsContent>
              <TabsContent value="fabric-type" className="mt-0"><FabricTypeTab /></TabsContent>
              <TabsContent value="department" className="mt-0"><DepartmentTab /></TabsContent>
              <TabsContent value="employee" className="mt-0"><EmployeeTab /></TabsContent>
              <TabsContent value="configuration" className="mt-0"><ConfigurationTab /></TabsContent>
              <TabsContent value="company-info" className="mt-0"><CompanyInfoSection /></TabsContent>
            </div>
          </div>
        </Tabs>
      </div>
    </Layout>
  );
}

// ─── Transaction Type ───────────────────────────────────────────────────────
function TransactionTypeTab() {
  const invalidateBoth = useInvalidateBoth();
  const { data, isLoading } = useListTransactionTypeMasterCrud();
  const create = useCreateTransactionTypeMaster();
  const update = useUpdateTransactionTypeMaster();
  const remove = useDeleteTransactionTypeMaster();
  const done = () => invalidateBoth(getListTransactionTypeMasterCrudQueryKey(), getListTransactionTypeMasterQueryKey());

  return (
    <MasterTable
      title="Transaction Types"
      description="Types of transactions (e.g. Receipt, Issue, Transfer). Used as a mandatory field on every transaction."
      fields={[
        { key: "name", label: "Name", placeholder: "e.g. Receipt" },
        { key: "code", label: "Code", placeholder: "e.g. REC" },
        { key: "action", label: "Action", placeholder: "e.g. IN" },
      ]}
      rows={data as never}
      isLoading={isLoading}
      onAdd={(d) => new Promise((res, rej) => create.mutate({ data: d as never }, { onSuccess: () => { done(); res(); }, onError: rej }))}
      onUpdate={(id, d) => new Promise((res, rej) => update.mutate({ id, data: d as never }, { onSuccess: () => { done(); res(); }, onError: rej }))}
      onDelete={(id) => new Promise((res, rej) => remove.mutate({ id }, { onSuccess: () => { done(); res(); }, onError: rej }))}
    />
  );
}

// ─── Job (depends on Party for filter + select options) ─────────────────────
function JobTab() {
  const invalidateBoth = useInvalidateBoth();
  const { data: jobs, isLoading } = useListJobMasterCrud();
  const { data: parties } = useListPartyMasterCrud();
  const create = useCreateJobMaster();
  const update = useUpdateJobMaster();
  const remove = useDeleteJobMaster();
  const done = () => invalidateBoth(getListJobMasterCrudQueryKey(), getListJobMasterQueryKey());

  const [jobPartyFilter, setJobPartyFilter] = useState<string>("");
  const filteredJobs = jobPartyFilter
    ? (jobs ?? []).filter((j) => String((j as { partyId?: number | null }).partyId ?? "") === jobPartyFilter)
    : (jobs ?? []);

  return (
    <>
      <div className="flex items-center gap-3 mb-4">
        <div className="flex flex-col gap-1">
          <span className="text-xs text-muted-foreground font-medium">Filter by Party</span>
          <div className="flex items-center gap-2">
            <Select value={jobPartyFilter || "__all__"} onValueChange={(v) => setJobPartyFilter(v === "__all__" ? "" : v)}>
              <SelectTrigger className="h-9 w-64">
                <SelectValue placeholder="All Parties" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="__all__">All Parties</SelectItem>
                {(parties ?? []).map((p) => (
                  <SelectItem key={p.id} value={String(p.id)}>{p.name}</SelectItem>
                ))}
              </SelectContent>
            </Select>
            {jobPartyFilter && (
              <Button variant="ghost" size="icon" className="h-9 w-9 text-muted-foreground hover:text-foreground" onClick={() => setJobPartyFilter("")} title="Clear filter">
                <X className="h-4 w-4" />
              </Button>
            )}
          </div>
        </div>
      </div>
      <MasterTable
        title="Job Types"
        description="Job types linked to a party. The combination of Party + Code must be unique."
        fields={[
          { key: "partyId", label: "Party", type: "select", displayKey: "partyName", placeholder: "Select party", options: (parties ?? []).map((p) => ({ value: String(p.id), label: p.name })) },
          { key: "name", label: "Job Type", placeholder: "e.g. Knitting Order" },
          { key: "code", label: "Code", placeholder: "e.g. KO" },
        ]}
        rows={filteredJobs as never}
        isLoading={isLoading}
        onAdd={(d) => new Promise((res, rej) => create.mutate({ data: { ...d, partyId: d.partyId ? Number(d.partyId) : null } as never }, { onSuccess: () => { done(); res(); }, onError: rej }))}
        onUpdate={(id, d) => new Promise((res, rej) => update.mutate({ id, data: { ...d, partyId: d.partyId ? Number(d.partyId) : null } as never }, { onSuccess: () => { done(); res(); }, onError: rej }))}
        onDelete={(id) => new Promise((res, rej) => remove.mutate({ id }, { onSuccess: () => { done(); res(); }, onError: rej }))}
      />
    </>
  );
}

// ─── Party ──────────────────────────────────────────────────────────────────
function PartyTab() {
  return (
    <Tabs defaultValue="list">
      <TabsList>
        <TabsTrigger value="list">List</TabsTrigger>
        <TabsTrigger value="analytics">Analytics</TabsTrigger>
      </TabsList>
      <TabsContent value="list" className="mt-4">
        <PartySection />
      </TabsContent>
      <TabsContent value="analytics" className="mt-4">
        <PartyAnalyticsView />
      </TabsContent>
    </Tabs>
  );
}

// ─── Machine ────────────────────────────────────────────────────────────────
function MachineTab() {
  const invalidateBoth = useInvalidateBoth();
  const { data, isLoading } = useListMachineMasterCrud();
  const create = useCreateMachineMaster();
  const update = useUpdateMachineMaster();
  const remove = useDeleteMachineMaster();
  const done = () => invalidateBoth(getListMachineMasterCrudQueryKey(), getListMachineMasterQueryKey());

  return (
    <Tabs defaultValue="list">
      <TabsList>
        <TabsTrigger value="list">List</TabsTrigger>
        <TabsTrigger value="analytics">Analytics</TabsTrigger>
      </TabsList>
      <TabsContent value="list" className="mt-4">
        <MasterTable
          title="Machines"
          description="Knitting machines on the production floor."
          fields={[
            { key: "name", label: "Name", placeholder: "e.g. Circular Knitting Machine 1" },
            { key: "machineNumber", label: "Machine Number", placeholder: "e.g. M-001" },
            { key: "makingRate", label: "Making Rate", placeholder: "3.75", type: "number", step: "0.01", defaultValue: "3.75" },
            { key: "needleChangeDate", label: "Needle Change Date", type: "date", defaultValue: new Date().toISOString().slice(0, 10) },
            { key: "needleBrand", label: "Needle Brand", placeholder: "e.g. Sigma", defaultValue: "Sigma" },
            { key: "sinkerChangeDate", label: "Sinker Change Date", type: "date", defaultValue: new Date().toISOString().slice(0, 10) },
            { key: "sinkerBrand", label: "Sinker Brand", placeholder: "e.g. Kohala", defaultValue: "Kohala" },
          ]}
          rows={data as never}
          isLoading={isLoading}
          onAdd={(d) => new Promise((res, rej) => create.mutate({ data: d as never }, { onSuccess: () => { done(); res(); }, onError: rej }))}
          onUpdate={(id, d) => new Promise((res, rej) => update.mutate({ id, data: d as never }, { onSuccess: () => { done(); res(); }, onError: rej }))}
          onDelete={(id) => new Promise((res, rej) => remove.mutate({ id }, { onSuccess: () => { done(); res(); }, onError: rej }))}
        />
      </TabsContent>
      <TabsContent value="analytics" className="mt-4">
        <MachineAnalyticsView />
      </TabsContent>
    </Tabs>
  );
}

// ─── Location ───────────────────────────────────────────────────────────────
function LocationTab() {
  const invalidateBoth = useInvalidateBoth();
  const { data, isLoading } = useListLocationMasterCrud();
  const create = useCreateLocationMaster();
  const update = useUpdateLocationMaster();
  const remove = useDeleteLocationMaster();
  const done = () => invalidateBoth(getListLocationMasterCrudQueryKey(), getListLocationMasterQueryKey());

  return (
    <MasterTable
      title="Locations"
      description="Physical locations within the factory."
      fields={[
        { key: "name", label: "Name", placeholder: "e.g. Production Floor A" },
        { key: "code", label: "Code", placeholder: "e.g. PFA" },
      ]}
      rows={data as never}
      isLoading={isLoading}
      onAdd={(d) => new Promise((res, rej) => create.mutate({ data: d as never }, { onSuccess: () => { done(); res(); }, onError: rej }))}
      onUpdate={(id, d) => new Promise((res, rej) => update.mutate({ id, data: d as never }, { onSuccess: () => { done(); res(); }, onError: rej }))}
      onDelete={(id) => new Promise((res, rej) => remove.mutate({ id }, { onSuccess: () => { done(); res(); }, onError: rej }))}
    />
  );
}

// ─── Yarn Type ──────────────────────────────────────────────────────────────
function YarnTypeTab() {
  const invalidateBoth = useInvalidateBoth();
  const { data, isLoading } = useListYarnTypeMasterCrud();
  const create = useCreateYarnTypeMaster();
  const update = useUpdateYarnTypeMaster();
  const remove = useDeleteYarnTypeMaster();
  const done = () => invalidateBoth(getListYarnTypeMasterCrudQueryKey(), getListYarnTypeMasterQueryKey());

  return (
    <MasterTable
      title="Yarn Types"
      description="Types of yarn used in production (e.g. Cotton, Polyester)."
      fields={[
        { key: "name", label: "Name", placeholder: "e.g. Cotton" },
        { key: "makeRate", label: "Make Rate", placeholder: "e.g. 12.50", type: "number", step: "any" },
        { key: "code", label: "Code", placeholder: "e.g. COT" },
        { key: "hsCode", label: "HS Code", placeholder: "e.g. 6001.2100" },
      ]}
      rows={data as never}
      isLoading={isLoading}
      onAdd={(d) => new Promise((res, rej) => create.mutate({ data: d as never }, { onSuccess: () => { done(); res(); }, onError: rej }))}
      onUpdate={(id, d) => new Promise((res, rej) => update.mutate({ id, data: d as never }, { onSuccess: () => { done(); res(); }, onError: rej }))}
      onDelete={(id) => new Promise((res, rej) => remove.mutate({ id }, { onSuccess: () => { done(); res(); }, onError: rej }))}
    />
  );
}

// ─── Yarn Count ─────────────────────────────────────────────────────────────
function YarnCountTab() {
  const invalidateBoth = useInvalidateBoth();
  const { data, isLoading } = useListYarnCountMasterCrud();
  const create = useCreateYarnCountMaster();
  const update = useUpdateYarnCountMaster();
  const remove = useDeleteYarnCountMaster();
  const done = () => invalidateBoth(getListYarnCountMasterCrudQueryKey(), getListYarnCountMasterQueryKey());

  return (
    <MasterTable
      title="Yarn Counts"
      description="Yarn count values (thickness/fineness)."
      fields={[
        { key: "name", label: "Name", placeholder: "e.g. 30s (30)" },
        { key: "count", label: "Count", placeholder: "e.g. 30" },
      ]}
      rows={data as never}
      isLoading={isLoading}
      onAdd={(d) => new Promise((res, rej) => create.mutate({ data: d as never }, { onSuccess: () => { done(); res(); }, onError: rej }))}
      onUpdate={(id, d) => new Promise((res, rej) => update.mutate({ id, data: d as never }, { onSuccess: () => { done(); res(); }, onError: rej }))}
      onDelete={(id) => new Promise((res, rej) => remove.mutate({ id }, { onSuccess: () => { done(); res(); }, onError: rej }))}
    />
  );
}

// ─── Yarn Brand ─────────────────────────────────────────────────────────────
function YarnBrandTab() {
  const invalidateBoth = useInvalidateBoth();
  const { data, isLoading } = useListYarnBrandMasterCrud();
  const create = useCreateYarnBrandMaster();
  const update = useUpdateYarnBrandMaster();
  const remove = useDeleteYarnBrandMaster();
  const done = () => invalidateBoth(getListYarnBrandMasterCrudQueryKey(), getListYarnBrandMasterQueryKey());

  return (
    <MasterTable
      title="Yarn Brands"
      description="Yarn manufacturer/brand names."
      fields={[
        { key: "name", label: "Name", placeholder: "e.g. Vardhman" },
        { key: "code", label: "Code", placeholder: "e.g. VAR" },
      ]}
      rows={data as never}
      isLoading={isLoading}
      onAdd={(d) => new Promise((res, rej) => create.mutate({ data: d as never }, { onSuccess: () => { done(); res(); }, onError: rej }))}
      onUpdate={(id, d) => new Promise((res, rej) => update.mutate({ id, data: d as never }, { onSuccess: () => { done(); res(); }, onError: rej }))}
      onDelete={(id) => new Promise((res, rej) => remove.mutate({ id }, { onSuccess: () => { done(); res(); }, onError: rej }))}
    />
  );
}

// ─── UOM ────────────────────────────────────────────────────────────────────
function UomTab() {
  const invalidateBoth = useInvalidateBoth();
  const { data, isLoading } = useListUomMasterCrud();
  const create = useCreateUomMaster();
  const update = useUpdateUomMaster();
  const remove = useDeleteUomMaster();
  const done = () => invalidateBoth(getListUomMasterCrudQueryKey(), getListUomMasterQueryKey());

  return (
    <MasterTable
      title="Units of Measure"
      description="Units used for measuring quantities and weights."
      fields={[
        { key: "name", label: "Name", placeholder: "e.g. Kilogram" },
        { key: "abbreviation", label: "Abbreviation", placeholder: "e.g. KG" },
      ]}
      rows={data as never}
      isLoading={isLoading}
      onAdd={(d) => new Promise((res, rej) => create.mutate({ data: d as never }, { onSuccess: () => { done(); res(); }, onError: rej }))}
      onUpdate={(id, d) => new Promise((res, rej) => update.mutate({ id, data: d as never }, { onSuccess: () => { done(); res(); }, onError: rej }))}
      onDelete={(id) => new Promise((res, rej) => remove.mutate({ id }, { onSuccess: () => { done(); res(); }, onError: rej }))}
    />
  );
}

// ─── Fabric Type ────────────────────────────────────────────────────────────
function FabricTypeTab() {
  const invalidateBoth = useInvalidateBoth();
  const { data, isLoading } = useListFabricTypeMasterCrud();
  const create = useCreateFabricTypeMaster();
  const update = useUpdateFabricTypeMaster();
  const remove = useDeleteFabricTypeMaster();
  const done = () => invalidateBoth(getListFabricTypeMasterCrudQueryKey(), getListFabricTypeMasterQueryKey());

  return (
    <MasterTable
      title="Fabric Types"
      description="Types of fabric produced (e.g. Single Jersey, Rib)."
      fields={[
        { key: "name", label: "Name", placeholder: "e.g. Single Jersey" },
        { key: "code", label: "Code", placeholder: "e.g. SJ" },
      ]}
      rows={data as never}
      isLoading={isLoading}
      onAdd={(d) => new Promise((res, rej) => create.mutate({ data: d as never }, { onSuccess: () => { done(); res(); }, onError: rej }))}
      onUpdate={(id, d) => new Promise((res, rej) => update.mutate({ id, data: d as never }, { onSuccess: () => { done(); res(); }, onError: rej }))}
      onDelete={(id) => new Promise((res, rej) => remove.mutate({ id }, { onSuccess: () => { done(); res(); }, onError: rej }))}
    />
  );
}

// ─── Department ─────────────────────────────────────────────────────────────
function DepartmentTab() {
  const invalidateBoth = useInvalidateBoth();
  const { data, isLoading } = useListDepartmentMasterCrud();
  const create = useCreateDepartmentMaster();
  const update = useUpdateDepartmentMaster();
  const remove = useDeleteDepartmentMaster();
  const done = () => invalidateBoth(getListDepartmentMasterCrudQueryKey(), getListDepartmentMasterQueryKey());

  return (
    <MasterTable
      title="Departments"
      description="Departments within the factory (e.g. Administration, Knitting Production, Security)."
      fields={[
        { key: "name", label: "Name", placeholder: "e.g. Knitting Production" },
        { key: "code", label: "Code", placeholder: "e.g. KNIT" },
      ]}
      rows={data as never}
      isLoading={isLoading}
      onAdd={(d) => new Promise((res, rej) => create.mutate({ data: d as never }, { onSuccess: () => { done(); res(); }, onError: rej }))}
      onUpdate={(id, d) => new Promise((res, rej) => update.mutate({ id, data: d as never }, { onSuccess: () => { done(); res(); }, onError: rej }))}
      onDelete={(id) => new Promise((res, rej) => remove.mutate({ id }, { onSuccess: () => { done(); res(); }, onError: rej }))}
    />
  );
}

// ─── Employee (depends on Department for select options) ─────────────────────
function EmployeeTab() {
  const invalidateBoth = useInvalidateBoth();
  const { data: employees, isLoading } = useListEmployeeMasterCrud();
  const { data: departments } = useListDepartmentMasterCrud();
  const create = useCreateEmployeeMaster();
  const update = useUpdateEmployeeMaster();
  const remove = useDeleteEmployeeMaster();
  const done = () => invalidateBoth(getListEmployeeMasterCrudQueryKey(), getListEmployeeMasterQueryKey());

  return (
    <MasterTable
      title="Employees"
      description="Employees assigned to machines during production runs."
      fields={[
        { key: "name", label: "Name", placeholder: "e.g. Employee Alpha" },
        { key: "code", label: "Code", placeholder: "e.g. OPA" },
        { key: "departmentId", label: "Department", type: "select", displayKey: "departmentName", placeholder: "Select department", options: (departments ?? []).map((d) => ({ value: String(d.id), label: d.name })) },
        { key: "baseSalary", label: "Base Salary", placeholder: "e.g. 15000.00", type: "number", step: "0.01" },
        { key: "overtimeRateHr", label: "Overtime Rate/Hr", placeholder: "e.g. 50.00", type: "number", step: "0.01" },
        { key: "attAllowance", label: "Att. Allowance", placeholder: "e.g. 500.00", type: "number", step: "0.01" },
        { key: "othAllowance", label: "Oth. Allowance", placeholder: "e.g. 200.00", type: "number", step: "0.01" },
        { key: "active", label: "Active", type: "checkbox", defaultValue: "true" },
      ]}
      rows={(employees ?? []).map((o) => ({
        ...o,
        departmentName: (departments ?? []).find((d) => d.id === (o as { departmentId?: number | null }).departmentId)?.name ?? null,
        active: String((o as { active?: boolean }).active ?? true),
      })) as never}
      isLoading={isLoading}
      onAdd={(d) => new Promise((res, rej) => create.mutate({ data: { ...d, departmentId: d.departmentId ? Number(d.departmentId) : null, active: d.active !== "false" } as never }, { onSuccess: () => { done(); res(); }, onError: rej }))}
      onUpdate={(id, d) => new Promise((res, rej) => update.mutate({ id, data: { ...d, departmentId: d.departmentId ? Number(d.departmentId) : null, active: d.active !== "false" } as never }, { onSuccess: () => { done(); res(); }, onError: rej }))}
      onDelete={(id) => new Promise((res, rej) => remove.mutate({ id }, { onSuccess: () => { done(); res(); }, onError: rej }))}
    />
  );
}

// ─── Configuration (read-only — managed via DB migration) ────────────────────
// System configuration is display-only: records are added/updated/deleted only
// through database migrations, so the table renders with no Add/Edit/Delete and
// the enabled flag shows as a locked toggle.
function ConfigurationTab() {
  const { data, isLoading } = useListConfigurationCrud();

  return (
    <MasterTable
      title="Configuration"
      description="System-wide settings that control daily operations. Configured via database migration and read-only in the app — records can't be added, edited or deleted here."
      readonly
      fields={[
        { key: "name", label: "Name" },
        { key: "code", label: "Code" },
        { key: "description", label: "Description" },
        { key: "enabled", label: "Enabled", type: "toggle" },
      ]}
      rows={data as never}
      isLoading={isLoading}
      onAdd={() => Promise.resolve()}
      onUpdate={() => Promise.resolve()}
      onDelete={() => Promise.resolve()}
    />
  );
}
