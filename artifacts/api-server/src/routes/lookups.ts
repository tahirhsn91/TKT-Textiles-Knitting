import { Router, type IRouter } from "express";
import { db } from "@workspace/db";
import {
  jobMasterTable,
  partyMasterTable,
  machineMasterTable,
  locationMasterTable,
  yarnTypeMasterTable,
  yarnCountMasterTable,
  yarnBrandMasterTable,
  uomMasterTable,
  fabricTypeMasterTable,
} from "@workspace/db";
import {
  ListJobMasterResponse,
  ListPartyMasterResponse,
  ListMachineMasterResponse,
  ListLocationMasterResponse,
  ListYarnTypeMasterResponse,
  ListYarnCountMasterResponse,
  ListYarnBrandMasterResponse,
  ListUomMasterResponse,
  ListFabricTypeMasterResponse,
} from "@workspace/api-zod";

const router: IRouter = Router();

router.get("/lookups/job-master", async (_req, res): Promise<void> => {
  const rows = await db.select().from(jobMasterTable).orderBy(jobMasterTable.name);
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

export default router;
