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
  useListMachineOperatorMasterCrud,
  useCreateMachineOperatorMaster,
  useUpdateMachineOperatorMaster,
  useDeleteMachineOperatorMaster,
  useListDepartmentMasterCrud,
  useCreateDepartmentMaster,
  useUpdateDepartmentMaster,
  useDeleteDepartmentMaster,
  getListJobMasterCrudQueryKey,
  getListPartyMasterCrudQueryKey,
  getListMachineMasterCrudQueryKey,
  getListLocationMasterCrudQueryKey,
  getListYarnTypeMasterCrudQueryKey,
  getListYarnCountMasterCrudQueryKey,
  getListYarnBrandMasterCrudQueryKey,
  getListUomMasterCrudQueryKey,
  getListFabricTypeMasterCrudQueryKey,
  getListMachineOperatorMasterCrudQueryKey,
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
  getListMachineOperatorMasterQueryKey,
  getListDepartmentMasterQueryKey,
} from "@workspace/api-client-react";
import { X } from "lucide-react";
import { Layout } from "@/components/layout";
import { MasterTable } from "@/components/master-table";
import { Button } from "@/components/ui/button";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";

export default function MastersPage() {
  const qc = useQueryClient();

  const invalidateBoth = (crudKey: readonly unknown[], lookupKey: readonly unknown[]) => {
    qc.invalidateQueries({ queryKey: [...crudKey] });
    qc.invalidateQueries({ queryKey: [...lookupKey] });
    void qc.refetchQueries({ queryKey: [...lookupKey], type: "all" });
  };

  // ── Transaction Type ─────────────────────────────────────────────────────
  const { data: txTypes, isLoading: txTypesLoading } = useListTransactionTypeMasterCrud();
  const createTxType = useCreateTransactionTypeMaster();
  const updateTxType = useUpdateTransactionTypeMaster();
  const deleteTxType = useDeleteTransactionTypeMaster();

  // ── Job ──────────────────────────────────────────────────────────────────
  const { data: jobs, isLoading: jobsLoading } = useListJobMasterCrud();
  const createJob = useCreateJobMaster();
  const updateJob = useUpdateJobMaster();
  const deleteJob = useDeleteJobMaster();
  const [jobPartyFilter, setJobPartyFilter] = useState<string>("");
  const filteredJobs = jobPartyFilter
    ? (jobs ?? []).filter((j) => String((j as { partyId?: number | null }).partyId ?? "") === jobPartyFilter)
    : (jobs ?? []);

  // ── Party ────────────────────────────────────────────────────────────────
  const { data: parties, isLoading: partiesLoading } = useListPartyMasterCrud();
  const createParty = useCreatePartyMaster();
  const updateParty = useUpdatePartyMaster();
  const deleteParty = useDeletePartyMaster();

  // ── Machine ──────────────────────────────────────────────────────────────
  const { data: machines, isLoading: machinesLoading } = useListMachineMasterCrud();
  const createMachine = useCreateMachineMaster();
  const updateMachine = useUpdateMachineMaster();
  const deleteMachine = useDeleteMachineMaster();

  // ── Location ─────────────────────────────────────────────────────────────
  const { data: locations, isLoading: locationsLoading } = useListLocationMasterCrud();
  const createLocation = useCreateLocationMaster();
  const updateLocation = useUpdateLocationMaster();
  const deleteLocation = useDeleteLocationMaster();

  // ── Yarn Type ────────────────────────────────────────────────────────────
  const { data: yarnTypes, isLoading: yarnTypesLoading } = useListYarnTypeMasterCrud();
  const createYarnType = useCreateYarnTypeMaster();
  const updateYarnType = useUpdateYarnTypeMaster();
  const deleteYarnType = useDeleteYarnTypeMaster();

  // ── Yarn Count ───────────────────────────────────────────────────────────
  const { data: yarnCounts, isLoading: yarnCountsLoading } = useListYarnCountMasterCrud();
  const createYarnCount = useCreateYarnCountMaster();
  const updateYarnCount = useUpdateYarnCountMaster();
  const deleteYarnCount = useDeleteYarnCountMaster();

  // ── Yarn Brand ───────────────────────────────────────────────────────────
  const { data: yarnBrands, isLoading: yarnBrandsLoading } = useListYarnBrandMasterCrud();
  const createYarnBrand = useCreateYarnBrandMaster();
  const updateYarnBrand = useUpdateYarnBrandMaster();
  const deleteYarnBrand = useDeleteYarnBrandMaster();

  // ── UOM ──────────────────────────────────────────────────────────────────
  const { data: uoms, isLoading: uomsLoading } = useListUomMasterCrud();
  const createUom = useCreateUomMaster();
  const updateUom = useUpdateUomMaster();
  const deleteUom = useDeleteUomMaster();

  // ── Fabric Type ──────────────────────────────────────────────────────────
  const { data: fabricTypes, isLoading: fabricTypesLoading } = useListFabricTypeMasterCrud();
  const createFabricType = useCreateFabricTypeMaster();
  const updateFabricType = useUpdateFabricTypeMaster();
  const deleteFabricType = useDeleteFabricTypeMaster();

  // ── Department ───────────────────────────────────────────────────────────
  const { data: departments, isLoading: departmentsLoading } = useListDepartmentMasterCrud();
  const createDepartment = useCreateDepartmentMaster();
  const updateDepartment = useUpdateDepartmentMaster();
  const deleteDepartment = useDeleteDepartmentMaster();

  // ── Machine Operator ─────────────────────────────────────────────────────
  const { data: operators, isLoading: operatorsLoading } = useListMachineOperatorMasterCrud();
  const createOperator = useCreateMachineOperatorMaster();
  const updateOperator = useUpdateMachineOperatorMaster();
  const deleteOperator = useDeleteMachineOperatorMaster();

  return (
    <Layout>
      <div className="flex flex-col gap-4">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Master Data</h1>
          <p className="text-muted-foreground mt-1">Manage all lookup tables used across the system.</p>
        </div>

        <Tabs defaultValue="transaction-type">
          <TabsList className="flex-wrap h-auto gap-1">
            <TabsTrigger value="transaction-type">Transaction Type</TabsTrigger>
            <TabsTrigger value="job">Job Types</TabsTrigger>
            <TabsTrigger value="party">Parties</TabsTrigger>
            <TabsTrigger value="machine">Machines</TabsTrigger>
            <TabsTrigger value="location">Locations</TabsTrigger>
            <TabsTrigger value="yarn-type">Yarn Type</TabsTrigger>
            <TabsTrigger value="yarn-count">Yarn Count</TabsTrigger>
            <TabsTrigger value="yarn-brand">Yarn Brand</TabsTrigger>
            <TabsTrigger value="uom">UOM</TabsTrigger>
            <TabsTrigger value="fabric-type">Fabric Type</TabsTrigger>
            <TabsTrigger value="department">Departments</TabsTrigger>
            <TabsTrigger value="operator">Operators</TabsTrigger>
          </TabsList>

          <TabsContent value="transaction-type" className="mt-4">
            <MasterTable
              title="Transaction Types"
              description="Types of transactions (e.g. Receipt, Issue, Transfer). Used as a mandatory field on every transaction."
              fields={[
                { key: "name", label: "Name", placeholder: "e.g. Receipt" },
                { key: "code", label: "Code", placeholder: "e.g. REC" },
                { key: "action", label: "Action", placeholder: "e.g. IN" },
              ]}
              rows={txTypes as never}
              isLoading={txTypesLoading}
              onAdd={(data) => new Promise((res, rej) =>
                createTxType.mutate({ data: data as never }, {
                  onSuccess: () => { invalidateBoth(getListTransactionTypeMasterCrudQueryKey(), getListTransactionTypeMasterQueryKey()); res(); },
                  onError: (e) => rej(e),
                })
              )}
              onUpdate={(id, data) => new Promise((res, rej) =>
                updateTxType.mutate({ id, data: data as never }, {
                  onSuccess: () => { invalidateBoth(getListTransactionTypeMasterCrudQueryKey(), getListTransactionTypeMasterQueryKey()); res(); },
                  onError: (e) => rej(e),
                })
              )}
              onDelete={(id) => new Promise((res, rej) =>
                deleteTxType.mutate({ id }, {
                  onSuccess: () => { invalidateBoth(getListTransactionTypeMasterCrudQueryKey(), getListTransactionTypeMasterQueryKey()); res(); },
                  onError: (e) => rej(e),
                })
              )}
            />
          </TabsContent>

          <TabsContent value="job" className="mt-4">
            {/* Party filter */}
            <div className="flex items-center gap-3 mb-4">
              <div className="flex flex-col gap-1">
                <span className="text-xs text-muted-foreground font-medium">Filter by Party</span>
                <div className="flex items-center gap-2">
                  <Select
                    value={jobPartyFilter || "__all__"}
                    onValueChange={(v) => setJobPartyFilter(v === "__all__" ? "" : v)}
                  >
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
                    <Button
                      variant="ghost"
                      size="icon"
                      className="h-9 w-9 text-muted-foreground hover:text-foreground"
                      onClick={() => setJobPartyFilter("")}
                      title="Clear filter"
                    >
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
                {
                  key: "partyId",
                  label: "Party",
                  type: "select",
                  displayKey: "partyName",
                  placeholder: "Select party",
                  options: (parties ?? []).map((p) => ({ value: String(p.id), label: p.name })),
                },
                { key: "name", label: "Job Type", placeholder: "e.g. Knitting Order" },
                { key: "code", label: "Code", placeholder: "e.g. KO" },
              ]}
              rows={filteredJobs as never}
              isLoading={jobsLoading}
              onAdd={(data) => new Promise((res, rej) =>
                createJob.mutate({ data: { ...data, partyId: data.partyId ? Number(data.partyId) : null } as never }, {
                  onSuccess: () => { invalidateBoth(getListJobMasterCrudQueryKey(), getListJobMasterQueryKey()); res(); },
                  onError: (e) => rej(e),
                })
              )}
              onUpdate={(id, data) => new Promise((res, rej) =>
                updateJob.mutate({ id, data: { ...data, partyId: data.partyId ? Number(data.partyId) : null } as never }, {
                  onSuccess: () => { invalidateBoth(getListJobMasterCrudQueryKey(), getListJobMasterQueryKey()); res(); },
                  onError: (e) => rej(e),
                })
              )}
              onDelete={(id) => new Promise((res, rej) =>
                deleteJob.mutate({ id }, {
                  onSuccess: () => { invalidateBoth(getListJobMasterCrudQueryKey(), getListJobMasterQueryKey()); res(); },
                  onError: (e) => rej(e),
                })
              )}
            />
          </TabsContent>

          <TabsContent value="party" className="mt-4">
            <MasterTable
              title="Parties"
              description="Business parties (customers, suppliers, contractors)."
              fields={[
                { key: "name", label: "Name", placeholder: "e.g. Sunrise Textiles" },
                { key: "code", label: "Code", placeholder: "e.g. SUN" },
                { key: "wastePercent", label: "Waste%", placeholder: "1.00", type: "number", step: "any" },
              ]}
              rows={parties as never}
              isLoading={partiesLoading}
              onAdd={(data) => new Promise((res, rej) =>
                createParty.mutate({ data: data as never }, {
                  onSuccess: () => { invalidateBoth(getListPartyMasterCrudQueryKey(), getListPartyMasterQueryKey()); res(); },
                  onError: (e) => rej(e),
                })
              )}
              onUpdate={(id, data) => new Promise((res, rej) =>
                updateParty.mutate({ id, data: data as never }, {
                  onSuccess: () => { invalidateBoth(getListPartyMasterCrudQueryKey(), getListPartyMasterQueryKey()); res(); },
                  onError: (e) => rej(e),
                })
              )}
              onDelete={(id) => new Promise((res, rej) =>
                deleteParty.mutate({ id }, {
                  onSuccess: () => { invalidateBoth(getListPartyMasterCrudQueryKey(), getListPartyMasterQueryKey()); res(); },
                  onError: (e) => rej(e),
                })
              )}
            />
          </TabsContent>

          <TabsContent value="machine" className="mt-4">
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
              rows={machines as never}
              isLoading={machinesLoading}
              onAdd={(data) => new Promise((res, rej) =>
                createMachine.mutate({ data: data as never }, {
                  onSuccess: () => { invalidateBoth(getListMachineMasterCrudQueryKey(), getListMachineMasterQueryKey()); res(); },
                  onError: (e) => rej(e),
                })
              )}
              onUpdate={(id, data) => new Promise((res, rej) =>
                updateMachine.mutate({ id, data: data as never }, {
                  onSuccess: () => { invalidateBoth(getListMachineMasterCrudQueryKey(), getListMachineMasterQueryKey()); res(); },
                  onError: (e) => rej(e),
                })
              )}
              onDelete={(id) => new Promise((res, rej) =>
                deleteMachine.mutate({ id }, {
                  onSuccess: () => { invalidateBoth(getListMachineMasterCrudQueryKey(), getListMachineMasterQueryKey()); res(); },
                  onError: (e) => rej(e),
                })
              )}
            />
          </TabsContent>

          <TabsContent value="location" className="mt-4">
            <MasterTable
              title="Locations"
              description="Physical locations within the factory."
              fields={[
                { key: "name", label: "Name", placeholder: "e.g. Production Floor A" },
                { key: "code", label: "Code", placeholder: "e.g. PFA" },
              ]}
              rows={locations as never}
              isLoading={locationsLoading}
              onAdd={(data) => new Promise((res, rej) =>
                createLocation.mutate({ data: data as never }, {
                  onSuccess: () => { invalidateBoth(getListLocationMasterCrudQueryKey(), getListLocationMasterQueryKey()); res(); },
                  onError: (e) => rej(e),
                })
              )}
              onUpdate={(id, data) => new Promise((res, rej) =>
                updateLocation.mutate({ id, data: data as never }, {
                  onSuccess: () => { invalidateBoth(getListLocationMasterCrudQueryKey(), getListLocationMasterQueryKey()); res(); },
                  onError: (e) => rej(e),
                })
              )}
              onDelete={(id) => new Promise((res, rej) =>
                deleteLocation.mutate({ id }, {
                  onSuccess: () => { invalidateBoth(getListLocationMasterCrudQueryKey(), getListLocationMasterQueryKey()); res(); },
                  onError: (e) => rej(e),
                })
              )}
            />
          </TabsContent>

          <TabsContent value="yarn-type" className="mt-4">
            <MasterTable
              title="Yarn Types"
              description="Types of yarn used in production (e.g. Cotton, Polyester)."
              fields={[
                { key: "name", label: "Name", placeholder: "e.g. Cotton" },
                { key: "makeRate", label: "Make Rate", placeholder: "e.g. 12.50", type: "number", step: "any" },
                { key: "code", label: "Code", placeholder: "e.g. COT" },
              ]}
              rows={yarnTypes as never}
              isLoading={yarnTypesLoading}
              onAdd={(data) => new Promise((res, rej) =>
                createYarnType.mutate({ data: data as never }, {
                  onSuccess: () => { invalidateBoth(getListYarnTypeMasterCrudQueryKey(), getListYarnTypeMasterQueryKey()); res(); },
                  onError: (e) => rej(e),
                })
              )}
              onUpdate={(id, data) => new Promise((res, rej) =>
                updateYarnType.mutate({ id, data: data as never }, {
                  onSuccess: () => { invalidateBoth(getListYarnTypeMasterCrudQueryKey(), getListYarnTypeMasterQueryKey()); res(); },
                  onError: (e) => rej(e),
                })
              )}
              onDelete={(id) => new Promise((res, rej) =>
                deleteYarnType.mutate({ id }, {
                  onSuccess: () => { invalidateBoth(getListYarnTypeMasterCrudQueryKey(), getListYarnTypeMasterQueryKey()); res(); },
                  onError: (e) => rej(e),
                })
              )}
            />
          </TabsContent>

          <TabsContent value="yarn-count" className="mt-4">
            <MasterTable
              title="Yarn Counts"
              description="Yarn count values (thickness/fineness)."
              fields={[
                { key: "name", label: "Name", placeholder: "e.g. 30s (30)" },
                { key: "count", label: "Count", placeholder: "e.g. 30" },
              ]}
              rows={yarnCounts as never}
              isLoading={yarnCountsLoading}
              onAdd={(data) => new Promise((res, rej) =>
                createYarnCount.mutate({ data: data as never }, {
                  onSuccess: () => { invalidateBoth(getListYarnCountMasterCrudQueryKey(), getListYarnCountMasterQueryKey()); res(); },
                  onError: (e) => rej(e),
                })
              )}
              onUpdate={(id, data) => new Promise((res, rej) =>
                updateYarnCount.mutate({ id, data: data as never }, {
                  onSuccess: () => { invalidateBoth(getListYarnCountMasterCrudQueryKey(), getListYarnCountMasterQueryKey()); res(); },
                  onError: (e) => rej(e),
                })
              )}
              onDelete={(id) => new Promise((res, rej) =>
                deleteYarnCount.mutate({ id }, {
                  onSuccess: () => { invalidateBoth(getListYarnCountMasterCrudQueryKey(), getListYarnCountMasterQueryKey()); res(); },
                  onError: (e) => rej(e),
                })
              )}
            />
          </TabsContent>

          <TabsContent value="yarn-brand" className="mt-4">
            <MasterTable
              title="Yarn Brands"
              description="Yarn manufacturer/brand names."
              fields={[
                { key: "name", label: "Name", placeholder: "e.g. Vardhman" },
                { key: "code", label: "Code", placeholder: "e.g. VAR" },
              ]}
              rows={yarnBrands as never}
              isLoading={yarnBrandsLoading}
              onAdd={(data) => new Promise((res, rej) =>
                createYarnBrand.mutate({ data: data as never }, {
                  onSuccess: () => { invalidateBoth(getListYarnBrandMasterCrudQueryKey(), getListYarnBrandMasterQueryKey()); res(); },
                  onError: (e) => rej(e),
                })
              )}
              onUpdate={(id, data) => new Promise((res, rej) =>
                updateYarnBrand.mutate({ id, data: data as never }, {
                  onSuccess: () => { invalidateBoth(getListYarnBrandMasterCrudQueryKey(), getListYarnBrandMasterQueryKey()); res(); },
                  onError: (e) => rej(e),
                })
              )}
              onDelete={(id) => new Promise((res, rej) =>
                deleteYarnBrand.mutate({ id }, {
                  onSuccess: () => { invalidateBoth(getListYarnBrandMasterCrudQueryKey(), getListYarnBrandMasterQueryKey()); res(); },
                  onError: (e) => rej(e),
                })
              )}
            />
          </TabsContent>

          <TabsContent value="uom" className="mt-4">
            <MasterTable
              title="Units of Measure"
              description="Units used for measuring quantities and weights."
              fields={[
                { key: "name", label: "Name", placeholder: "e.g. Kilogram" },
                { key: "abbreviation", label: "Abbreviation", placeholder: "e.g. KG" },
              ]}
              rows={uoms as never}
              isLoading={uomsLoading}
              onAdd={(data) => new Promise((res, rej) =>
                createUom.mutate({ data: data as never }, {
                  onSuccess: () => { invalidateBoth(getListUomMasterCrudQueryKey(), getListUomMasterQueryKey()); res(); },
                  onError: (e) => rej(e),
                })
              )}
              onUpdate={(id, data) => new Promise((res, rej) =>
                updateUom.mutate({ id, data: data as never }, {
                  onSuccess: () => { invalidateBoth(getListUomMasterCrudQueryKey(), getListUomMasterQueryKey()); res(); },
                  onError: (e) => rej(e),
                })
              )}
              onDelete={(id) => new Promise((res, rej) =>
                deleteUom.mutate({ id }, {
                  onSuccess: () => { invalidateBoth(getListUomMasterCrudQueryKey(), getListUomMasterQueryKey()); res(); },
                  onError: (e) => rej(e),
                })
              )}
            />
          </TabsContent>

          <TabsContent value="fabric-type" className="mt-4">
            <MasterTable
              title="Fabric Types"
              description="Types of fabric produced (e.g. Single Jersey, Rib)."
              fields={[
                { key: "name", label: "Name", placeholder: "e.g. Single Jersey" },
                { key: "code", label: "Code", placeholder: "e.g. SJ" },
              ]}
              rows={fabricTypes as never}
              isLoading={fabricTypesLoading}
              onAdd={(data) => new Promise((res, rej) =>
                createFabricType.mutate({ data: data as never }, {
                  onSuccess: () => { invalidateBoth(getListFabricTypeMasterCrudQueryKey(), getListFabricTypeMasterQueryKey()); res(); },
                  onError: (e) => rej(e),
                })
              )}
              onUpdate={(id, data) => new Promise((res, rej) =>
                updateFabricType.mutate({ id, data: data as never }, {
                  onSuccess: () => { invalidateBoth(getListFabricTypeMasterCrudQueryKey(), getListFabricTypeMasterQueryKey()); res(); },
                  onError: (e) => rej(e),
                })
              )}
              onDelete={(id) => new Promise((res, rej) =>
                deleteFabricType.mutate({ id }, {
                  onSuccess: () => { invalidateBoth(getListFabricTypeMasterCrudQueryKey(), getListFabricTypeMasterQueryKey()); res(); },
                  onError: (e) => rej(e),
                })
              )}
            />
          </TabsContent>

          <TabsContent value="department" className="mt-4">
            <MasterTable
              title="Departments"
              description="Departments within the factory (e.g. Administration, Knitting Production, Security)."
              fields={[
                { key: "name", label: "Name", placeholder: "e.g. Knitting Production" },
                { key: "code", label: "Code", placeholder: "e.g. KNIT" },
              ]}
              rows={departments as never}
              isLoading={departmentsLoading}
              onAdd={(data) => new Promise((res, rej) =>
                createDepartment.mutate({ data: data as never }, {
                  onSuccess: () => { invalidateBoth(getListDepartmentMasterCrudQueryKey(), getListDepartmentMasterQueryKey()); res(); },
                  onError: (e) => rej(e),
                })
              )}
              onUpdate={(id, data) => new Promise((res, rej) =>
                updateDepartment.mutate({ id, data: data as never }, {
                  onSuccess: () => { invalidateBoth(getListDepartmentMasterCrudQueryKey(), getListDepartmentMasterQueryKey()); res(); },
                  onError: (e) => rej(e),
                })
              )}
              onDelete={(id) => new Promise((res, rej) =>
                deleteDepartment.mutate({ id }, {
                  onSuccess: () => { invalidateBoth(getListDepartmentMasterCrudQueryKey(), getListDepartmentMasterQueryKey()); res(); },
                  onError: (e) => rej(e),
                })
              )}
            />
          </TabsContent>

          <TabsContent value="operator" className="mt-4">
            <MasterTable
              title="Machine Operators"
              description="Operators assigned to machines during production runs."
              fields={[
                { key: "name", label: "Name", placeholder: "e.g. Operator Alpha" },
                { key: "code", label: "Code", placeholder: "e.g. OPA" },
                {
                  key: "departmentId",
                  label: "Department",
                  type: "select",
                  displayKey: "departmentName",
                  placeholder: "Select department",
                  options: (departments ?? []).map((d) => ({ value: String(d.id), label: d.name })),
                },
                { key: "baseSalary", label: "Base Salary", placeholder: "e.g. 15000.00", type: "number", step: "0.01" },
                { key: "overtimeRateHr", label: "Overtime Rate/Hr", placeholder: "e.g. 50.00", type: "number", step: "0.01" },
                { key: "attAllowance", label: "Att. Allowance", placeholder: "e.g. 500.00", type: "number", step: "0.01" },
                { key: "othAllowance", label: "Oth. Allowance", placeholder: "e.g. 200.00", type: "number", step: "0.01" },
              ]}
              rows={(operators ?? []).map((o) => ({
                ...o,
                departmentName: (departments ?? []).find((d) => d.id === (o as { departmentId?: number | null }).departmentId)?.name ?? null,
              })) as never}
              isLoading={operatorsLoading}
              onAdd={(data) => new Promise((res, rej) =>
                createOperator.mutate({ data: { ...data, departmentId: data.departmentId ? Number(data.departmentId) : null } as never }, {
                  onSuccess: () => { invalidateBoth(getListMachineOperatorMasterCrudQueryKey(), getListMachineOperatorMasterQueryKey()); res(); },
                  onError: (e) => rej(e),
                })
              )}
              onUpdate={(id, data) => new Promise((res, rej) =>
                updateOperator.mutate({ id, data: { ...data, departmentId: data.departmentId ? Number(data.departmentId) : null } as never }, {
                  onSuccess: () => { invalidateBoth(getListMachineOperatorMasterCrudQueryKey(), getListMachineOperatorMasterQueryKey()); res(); },
                  onError: (e) => rej(e),
                })
              )}
              onDelete={(id) => new Promise((res, rej) =>
                deleteOperator.mutate({ id }, {
                  onSuccess: () => { invalidateBoth(getListMachineOperatorMasterCrudQueryKey(), getListMachineOperatorMasterQueryKey()); res(); },
                  onError: (e) => rej(e),
                })
              )}
            />
          </TabsContent>
        </Tabs>
      </div>
    </Layout>
  );
}
