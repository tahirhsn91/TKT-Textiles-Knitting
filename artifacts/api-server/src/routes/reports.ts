import { Router, type IRouter } from "express";
import { and, eq, gte, lte, sql } from "drizzle-orm";
import { db } from "@workspace/db";
import {
  transactionHeaderTable,
  transactionDetailTable,
  transactionTypeMasterTable,
  jobMasterTable,
  partyMasterTable,
  locationMasterTable,
  fabricTypeMasterTable,
  yarnTypeMasterTable,
  yarnCountMasterTable,
  yarnBrandMasterTable,
  uomMasterTable,
  machineMasterTable,
  machineOperatorMasterTable,
} from "@workspace/db";

const router: IRouter = Router();

router.get("/reports/data", async (req, res): Promise<void> => {
  const q = req.query as Record<string, string | undefined>;

  const conditions = [];

  if (q.dateFrom) conditions.push(gte(transactionHeaderTable.date, q.dateFrom));
  if (q.dateTo)   conditions.push(lte(transactionHeaderTable.date, q.dateTo));
  if (q.year)     conditions.push(sql`EXTRACT(YEAR  FROM ${transactionHeaderTable.date}) = ${parseInt(q.year)}`);
  if (q.month)    conditions.push(sql`EXTRACT(MONTH FROM ${transactionHeaderTable.date}) = ${parseInt(q.month)}`);

  if (q.transactionTypeId) conditions.push(eq(transactionHeaderTable.transactionTypeId, parseInt(q.transactionTypeId)));
  if (q.jobId)             conditions.push(eq(transactionHeaderTable.jobId, parseInt(q.jobId)));
  if (q.partyId)           conditions.push(eq(transactionHeaderTable.partyId, parseInt(q.partyId)));
  if (q.locationId)        conditions.push(eq(transactionHeaderTable.locationId, parseInt(q.locationId)));
  if (q.fabricTypeId)      conditions.push(eq(transactionHeaderTable.fabricTypeId, parseInt(q.fabricTypeId)));
  if (q.yarnTypeId)        conditions.push(eq(transactionDetailTable.yarnTypeId, parseInt(q.yarnTypeId)));
  if (q.yarnCountId)       conditions.push(eq(transactionDetailTable.yarnCountId, parseInt(q.yarnCountId)));
  if (q.yarnBrandId)       conditions.push(eq(transactionDetailTable.yarnBrandId, parseInt(q.yarnBrandId)));
  if (q.uomId)             conditions.push(eq(transactionDetailTable.uomId, parseInt(q.uomId)));
  if (q.machineId)         conditions.push(eq(transactionDetailTable.machineId, parseInt(q.machineId)));
  if (q.machineOperatorId) conditions.push(eq(transactionDetailTable.machineOperatorId, parseInt(q.machineOperatorId)));

  const rows = await db
    .select({
      headerId:             transactionHeaderTable.id,
      date:                 transactionHeaderTable.date,
      docNumber:            transactionHeaderTable.docNumber,
      sl:                   transactionHeaderTable.sl,
      gsm:                  transactionHeaderTable.gsm,
      transactionTypeName:   transactionTypeMasterTable.name,
      transactionTypeAction: transactionTypeMasterTable.action,
      jobName:              jobMasterTable.name,
      partyName:            partyMasterTable.name,
      locationName:         locationMasterTable.name,
      fabricTypeName:       fabricTypeMasterTable.name,
      detailId:             transactionDetailTable.id,
      quantity:             transactionDetailTable.quantity,
      netWt:                transactionDetailTable.netWt,
      yarnTypeName:         yarnTypeMasterTable.name,
      yarnCountName:        yarnCountMasterTable.name,
      yarnBrandName:        yarnBrandMasterTable.name,
      uomName:              uomMasterTable.name,
      machineName:          machineMasterTable.name,
      machineOperatorName:  machineOperatorMasterTable.name,
    })
    .from(transactionDetailTable)
    .innerJoin(transactionHeaderTable,        eq(transactionDetailTable.headerId,             transactionHeaderTable.id))
    .leftJoin(transactionTypeMasterTable,     eq(transactionHeaderTable.transactionTypeId,     transactionTypeMasterTable.id))
    .leftJoin(jobMasterTable,                 eq(transactionHeaderTable.jobId,                 jobMasterTable.id))
    .leftJoin(partyMasterTable,               eq(transactionHeaderTable.partyId,               partyMasterTable.id))
    .leftJoin(locationMasterTable,            eq(transactionHeaderTable.locationId,            locationMasterTable.id))
    .leftJoin(fabricTypeMasterTable,          eq(transactionHeaderTable.fabricTypeId,          fabricTypeMasterTable.id))
    .leftJoin(yarnTypeMasterTable,            eq(transactionDetailTable.yarnTypeId,            yarnTypeMasterTable.id))
    .leftJoin(yarnCountMasterTable,           eq(transactionDetailTable.yarnCountId,           yarnCountMasterTable.id))
    .leftJoin(yarnBrandMasterTable,           eq(transactionDetailTable.yarnBrandId,           yarnBrandMasterTable.id))
    .leftJoin(uomMasterTable,                 eq(transactionDetailTable.uomId,                 uomMasterTable.id))
    .leftJoin(machineMasterTable,             eq(transactionDetailTable.machineId,             machineMasterTable.id))
    .leftJoin(machineOperatorMasterTable,     eq(transactionDetailTable.machineOperatorId,     machineOperatorMasterTable.id))
    .where(conditions.length > 0 ? and(...conditions) : undefined)
    .orderBy(transactionHeaderTable.date, transactionHeaderTable.id, transactionDetailTable.id);

  res.json(rows);
});

export default router;
