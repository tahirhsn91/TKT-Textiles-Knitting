import { Router, type IRouter } from "express";
import { eq } from "drizzle-orm";
import { db } from "../db/index.js";
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
  machineOperatorMasterTable,
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
  ListMachineOperatorMasterResponse,
} from "../api-zod/index.js";

const router: IRouter = Router();

router.get("/lookups/job-master", async (_req, res): Promise<void> => {
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
    .orderBy(partyMasterTable.name, jobMasterTable.name);
  res.json(ListJobMasterResponse.parse(rows));
});

router.get("/lookups/party-master", async (_req, res): Promise<void> => {
  const rows = await db.select().from(partyMasterTable).orderBy(partyMasterTable.name);
  res.json(ListPartyMasterResponse.parse(rows));
});

router.get("/lookups/machine-master", async (_req, res): Promise<void> => {
  const rows = await db.select().from(machineMasterTable).orderBy(machineMasterTable.name);
  res.json(ListMachineMasterResponse.parse(rows));
});

router.get("/lookups/location-master", async (_req, res): Promise<void> => {
  const rows = await db.select().from(locationMasterTable).orderBy(locationMasterTable.name);
  res.json(ListLocationMasterResponse.parse(rows));
});

router.get("/lookups/yarn-type-master", async (_req, res): Promise<void> => {
  const rows = await db.select().from(yarnTypeMasterTable).orderBy(yarnTypeMasterTable.name);
  res.json(ListYarnTypeMasterResponse.parse(rows));
});

router.get("/lookups/yarn-count-master", async (_req, res): Promise<void> => {
  const rows = await db.select().from(yarnCountMasterTable).orderBy(yarnCountMasterTable.name);
  res.json(ListYarnCountMasterResponse.parse(rows));
});

router.get("/lookups/yarn-brand-master", async (_req, res): Promise<void> => {
  const rows = await db.select().from(yarnBrandMasterTable).orderBy(yarnBrandMasterTable.name);
  res.json(ListYarnBrandMasterResponse.parse(rows));
});

router.get("/lookups/uom-master", async (_req, res): Promise<void> => {
  const rows = await db.select().from(uomMasterTable).orderBy(uomMasterTable.name);
  res.json(ListUomMasterResponse.parse(rows));
});

router.get("/lookups/fabric-type-master", async (_req, res): Promise<void> => {
  const rows = await db.select().from(fabricTypeMasterTable).orderBy(fabricTypeMasterTable.name);
  res.json(ListFabricTypeMasterResponse.parse(rows));
});

router.get("/lookups/machine-operator-master", async (_req, res): Promise<void> => {
  const rows = await db.select().from(machineOperatorMasterTable).orderBy(machineOperatorMasterTable.name);
  res.json(ListMachineOperatorMasterResponse.parse(rows));
});

router.get("/lookups/transaction-type-master", async (_req, res): Promise<void> => {
  const rows = await db.select().from(transactionTypeMasterTable).orderBy(transactionTypeMasterTable.name);
  res.json(ListTransactionTypeMasterResponse.parse(rows));
});

export default router;
