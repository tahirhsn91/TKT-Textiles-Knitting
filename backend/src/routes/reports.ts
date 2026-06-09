import { Router, type IRouter } from "express";
import { and, eq, gte, lte, inArray, ilike, sql } from "drizzle-orm";
import { db } from "../db/index.js";
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
} from "../db/index.js";

const router: IRouter = Router();

router.get("/reports/data", async (req, res): Promise<void> => {
  const q = req.query as Record<string, string | undefined>;

  const conditions = [];

  if (q.dateFrom)   conditions.push(gte(transactionHeaderTable.date, q.dateFrom));
  if (q.dateTo)     conditions.push(lte(transactionHeaderTable.date, q.dateTo));
  if (q.year)       conditions.push(sql`EXTRACT(YEAR  FROM ${transactionHeaderTable.date}) = ${parseInt(q.year)}`);
  if (q.month)      conditions.push(sql`EXTRACT(MONTH FROM ${transactionHeaderTable.date}) = ${parseInt(q.month)}`);
  if (q.docNumber)  conditions.push(ilike(transactionHeaderTable.docNumber, `%${q.docNumber}%`));
  if (q.reference)  conditions.push(ilike(transactionHeaderTable.reference, `%${q.reference}%`));

  function ids(raw: string | undefined): number[] | null {
    if (!raw) return null;
    const parsed = raw.split(",").map((s) => parseInt(s.trim())).filter((n) => !isNaN(n));
    return parsed.length > 0 ? parsed : null;
  }

  const ttIds  = ids(q.transactionTypeId);
  const jobIds = ids(q.jobId);
  const pIds   = ids(q.partyId);
  const locIds = ids(q.locationId);
  const ftIds  = ids(q.fabricTypeId);
  const ytIds  = ids(q.yarnTypeId);
  const ycIds  = ids(q.yarnCountId);
  const ybIds  = ids(q.yarnBrandId);
  const uIds   = ids(q.uomId);
  const mIds   = ids(q.machineId);
  const moIds  = ids(q.machineOperatorId);

  if (ttIds)  conditions.push(ttIds.length === 1  ? eq(transactionHeaderTable.transactionTypeId, ttIds[0])  : inArray(transactionHeaderTable.transactionTypeId, ttIds));
  if (jobIds) conditions.push(jobIds.length === 1 ? eq(transactionHeaderTable.jobId, jobIds[0])            : inArray(transactionHeaderTable.jobId, jobIds));
  if (pIds)   conditions.push(pIds.length === 1   ? eq(transactionHeaderTable.partyId, pIds[0])            : inArray(transactionHeaderTable.partyId, pIds));
  if (locIds) conditions.push(locIds.length === 1 ? eq(transactionHeaderTable.locationId, locIds[0])       : inArray(transactionHeaderTable.locationId, locIds));
  if (ftIds)  conditions.push(ftIds.length === 1  ? eq(transactionHeaderTable.fabricTypeId, ftIds[0])      : inArray(transactionHeaderTable.fabricTypeId, ftIds));
  if (ytIds)  conditions.push(ytIds.length === 1  ? eq(transactionDetailTable.yarnTypeId, ytIds[0])        : inArray(transactionDetailTable.yarnTypeId, ytIds));
  if (ycIds)  conditions.push(ycIds.length === 1  ? eq(transactionDetailTable.yarnCountId, ycIds[0])       : inArray(transactionDetailTable.yarnCountId, ycIds));
  if (ybIds)  conditions.push(ybIds.length === 1  ? eq(transactionDetailTable.yarnBrandId, ybIds[0])       : inArray(transactionDetailTable.yarnBrandId, ybIds));
  if (uIds)   conditions.push(uIds.length === 1   ? eq(transactionDetailTable.uomId, uIds[0])              : inArray(transactionDetailTable.uomId, uIds));
  if (mIds)   conditions.push(mIds.length === 1   ? eq(transactionDetailTable.machineId, mIds[0])          : inArray(transactionDetailTable.machineId, mIds));
  if (moIds)  conditions.push(moIds.length === 1  ? eq(transactionDetailTable.machineOperatorId, moIds[0]) : inArray(transactionDetailTable.machineOperatorId, moIds));

  const rows = await db
    .select({
      headerId:             transactionHeaderTable.id,
      date:                 transactionHeaderTable.date,
      docNumber:            transactionHeaderTable.docNumber,
      reference:            transactionHeaderTable.reference,
      sl:                   transactionHeaderTable.sl,
      gsm:                  transactionHeaderTable.gsm,
      transactionTypeName:   transactionTypeMasterTable.name,
      transactionTypeAction: transactionTypeMasterTable.action,
      jobName:              jobMasterTable.name,
      partyName:            partyMasterTable.name,
      partyWastePercent:    partyMasterTable.wastePercent,
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
