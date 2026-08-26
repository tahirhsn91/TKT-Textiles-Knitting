import { Router, type IRouter } from "express";
import { eq } from "drizzle-orm";
import { db } from "../db/index.js";
import { activeTenantId } from "../middleware/tenant-context.js";
import {
  transactionTypeMasterTable,
  jobMasterTable,
  partyMasterTable,
  machineMasterTable,
  locationMasterTable,
  yarnTypeMasterTable,
  yarnCountMasterTable,
  yarnBrandMasterTable,
  uomMasterTable,
  fabricTypeMasterTable,
  employeeMasterTable,
  departmentMasterTable,
} from "../db/index.js";
import {
  ListTransactionTypeMasterResponse,
  ListJobMasterResponse,
  ListPartyMasterResponse,
  ListMachineMasterResponse,
  ListLocationMasterResponse,
  ListYarnTypeMasterResponse,
  ListYarnCountMasterResponse,
  ListYarnBrandMasterResponse,
  ListUomMasterResponse,
  ListFabricTypeMasterResponse,
  ListEmployeeMasterResponse,
  ListDepartmentMasterResponse,
} from "../api-zod/index.js";

const router: IRouter = Router();

/**
 * GET /api/lookups/all — returns every lookup list in one request (issue #19).
 * Pages that need several master lists (most screens) can fetch this once
 * instead of firing N parallel lookup calls. Same shapes as the individual
 * endpoints, just batched under named keys. Auth-only route (the whole
 * lookups router is auth-gated), so it can't be nested behind a per-route
 * module permission.
 */
router.get("/lookups/all", async (req, res): Promise<void> => {
  const tenantId = activeTenantId(req);
  const [
    transactionTypes,
    jobs,
    parties,
    machines,
    locations,
    yarnTypes,
    yarnCounts,
    yarnBrands,
    uoms,
    fabricTypes,
    employees,
    departments,
  ] = await Promise.all([
    db.select().from(transactionTypeMasterTable).where(eq(transactionTypeMasterTable.tenantId, tenantId)).orderBy(transactionTypeMasterTable.name),
    db
      .select({
        id: jobMasterTable.id,
        name: jobMasterTable.name,
        code: jobMasterTable.code,
        partyId: jobMasterTable.partyId,
        partyName: partyMasterTable.name,
      })
      .from(jobMasterTable)
      .leftJoin(partyMasterTable, eq(jobMasterTable.partyId, partyMasterTable.id))
      .where(eq(jobMasterTable.tenantId, tenantId))
      .orderBy(partyMasterTable.name, jobMasterTable.name),
    db.select().from(partyMasterTable).where(eq(partyMasterTable.tenantId, tenantId)).orderBy(partyMasterTable.name),
    db.select().from(machineMasterTable).where(eq(machineMasterTable.tenantId, tenantId)).orderBy(machineMasterTable.name),
    db.select().from(locationMasterTable).where(eq(locationMasterTable.tenantId, tenantId)).orderBy(locationMasterTable.name),
    db.select().from(yarnTypeMasterTable).where(eq(yarnTypeMasterTable.tenantId, tenantId)).orderBy(yarnTypeMasterTable.name),
    db.select().from(yarnCountMasterTable).where(eq(yarnCountMasterTable.tenantId, tenantId)).orderBy(yarnCountMasterTable.name),
    db.select().from(yarnBrandMasterTable).where(eq(yarnBrandMasterTable.tenantId, tenantId)).orderBy(yarnBrandMasterTable.name),
    db.select().from(uomMasterTable).where(eq(uomMasterTable.tenantId, tenantId)).orderBy(uomMasterTable.name),
    db.select().from(fabricTypeMasterTable).where(eq(fabricTypeMasterTable.tenantId, tenantId)).orderBy(fabricTypeMasterTable.name),
    db.select().from(employeeMasterTable).where(eq(employeeMasterTable.tenantId, tenantId)).orderBy(employeeMasterTable.name),
    db.select().from(departmentMasterTable).where(eq(departmentMasterTable.tenantId, tenantId)).orderBy(departmentMasterTable.name),
  ]);

  res.json({
    transactionTypes,
    jobs,
    parties,
    machines,
    locations,
    yarnTypes,
    yarnCounts,
    yarnBrands,
    uoms,
    fabricTypes,
    employees,
    departments,
  });
});

router.get("/lookups/job-master", async (req, res): Promise<void> => {
  const tenantId = activeTenantId(req);
  const rows = await db
    .select({
      id:        jobMasterTable.id,
      name:      jobMasterTable.name,
      code:      jobMasterTable.code,
      partyId:   jobMasterTable.partyId,
      partyName: partyMasterTable.name,
    })
    .from(jobMasterTable)
    .leftJoin(partyMasterTable, eq(jobMasterTable.partyId, partyMasterTable.id))
    .where(eq(jobMasterTable.tenantId, tenantId))
    .orderBy(partyMasterTable.name, jobMasterTable.name);
  res.json(ListJobMasterResponse.parse(rows));
});

router.get("/lookups/party-master", async (req, res): Promise<void> => {
  const rows = await db.select().from(partyMasterTable).where(eq(partyMasterTable.tenantId, activeTenantId(req))).orderBy(partyMasterTable.name);
  res.json(ListPartyMasterResponse.parse(rows));
});

router.get("/lookups/machine-master", async (req, res): Promise<void> => {
  const rows = await db.select().from(machineMasterTable).where(eq(machineMasterTable.tenantId, activeTenantId(req))).orderBy(machineMasterTable.name);
  res.json(ListMachineMasterResponse.parse(rows));
});

router.get("/lookups/location-master", async (req, res): Promise<void> => {
  const rows = await db.select().from(locationMasterTable).where(eq(locationMasterTable.tenantId, activeTenantId(req))).orderBy(locationMasterTable.name);
  res.json(ListLocationMasterResponse.parse(rows));
});

router.get("/lookups/yarn-type-master", async (req, res): Promise<void> => {
  const rows = await db.select().from(yarnTypeMasterTable).where(eq(yarnTypeMasterTable.tenantId, activeTenantId(req))).orderBy(yarnTypeMasterTable.name);
  res.json(ListYarnTypeMasterResponse.parse(rows));
});

router.get("/lookups/yarn-count-master", async (req, res): Promise<void> => {
  const rows = await db.select().from(yarnCountMasterTable).where(eq(yarnCountMasterTable.tenantId, activeTenantId(req))).orderBy(yarnCountMasterTable.name);
  res.json(ListYarnCountMasterResponse.parse(rows));
});

router.get("/lookups/yarn-brand-master", async (req, res): Promise<void> => {
  const rows = await db.select().from(yarnBrandMasterTable).where(eq(yarnBrandMasterTable.tenantId, activeTenantId(req))).orderBy(yarnBrandMasterTable.name);
  res.json(ListYarnBrandMasterResponse.parse(rows));
});

router.get("/lookups/uom-master", async (req, res): Promise<void> => {
  const rows = await db.select().from(uomMasterTable).where(eq(uomMasterTable.tenantId, activeTenantId(req))).orderBy(uomMasterTable.name);
  res.json(ListUomMasterResponse.parse(rows));
});

router.get("/lookups/fabric-type-master", async (req, res): Promise<void> => {
  const rows = await db.select().from(fabricTypeMasterTable).where(eq(fabricTypeMasterTable.tenantId, activeTenantId(req))).orderBy(fabricTypeMasterTable.name);
  res.json(ListFabricTypeMasterResponse.parse(rows));
});

router.get("/lookups/employee-master", async (req, res): Promise<void> => {
  const rows = await db.select().from(employeeMasterTable).where(eq(employeeMasterTable.tenantId, activeTenantId(req))).orderBy(employeeMasterTable.name);
  res.json(ListEmployeeMasterResponse.parse(rows));
});

router.get("/lookups/transaction-type-master", async (req, res): Promise<void> => {
  const rows = await db.select().from(transactionTypeMasterTable).where(eq(transactionTypeMasterTable.tenantId, activeTenantId(req))).orderBy(transactionTypeMasterTable.name);
  res.json(ListTransactionTypeMasterResponse.parse(rows));
});

router.get("/lookups/department-master", async (req, res): Promise<void> => {
  const rows = await db.select().from(departmentMasterTable).where(eq(departmentMasterTable.tenantId, activeTenantId(req))).orderBy(departmentMasterTable.name);
  res.json(ListDepartmentMasterResponse.parse(rows));
});

export default router;
