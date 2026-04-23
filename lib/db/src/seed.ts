import { drizzle } from "drizzle-orm/node-postgres";
import pg from "pg";
import * as schema from "./schema";
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
  machineOperatorMasterTable,
  transactionHeaderTable,
  transactionDetailTable,
} from "./schema";

const { Pool } = pg;

if (!process.env.DATABASE_URL) {
  throw new Error("DATABASE_URL must be set.");
}

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const db = drizzle(pool, { schema });

async function seed() {
  console.log("Seeding lookup tables...");

  const jobs = await db
    .insert(jobMasterTable)
    .values([
      { name: "Knitting Order", code: "KO" },
      { name: "Production Run", code: "PR" },
      { name: "Quality Check", code: "QC" },
      { name: "Dispatch Order", code: "DO" },
    ])
    .onConflictDoNothing()
    .returning();

  await db
    .insert(partyMasterTable)
    .values([
      { name: "Sunrise Textiles", code: "SUN" },
      { name: "Blue Star Fabrics", code: "BSF" },
      { name: "Apex Yarns Ltd", code: "AYL" },
      { name: "Global Knit Co", code: "GKC" },
    ])
    .onConflictDoNothing();

  const machines = await db
    .insert(machineMasterTable)
    .values([
      { name: "Flat Knitting Machine A", machineNumber: "M-001" },
      { name: "Flat Knitting Machine B", machineNumber: "M-002" },
      { name: "Circular Knitting Machine 1", machineNumber: "M-003" },
      { name: "Circular Knitting Machine 2", machineNumber: "M-004" },
    ])
    .onConflictDoNothing()
    .returning();

  const locations = await db
    .insert(locationMasterTable)
    .values([
      { name: "Production Floor A", code: "PFA" },
      { name: "Production Floor B", code: "PFB" },
      { name: "Warehouse", code: "WH" },
      { name: "Dispatch Bay", code: "DB" },
    ])
    .onConflictDoNothing()
    .returning();

  const yarnTypes = await db
    .insert(yarnTypeMasterTable)
    .values([
      { name: "Cotton", code: "COT" },
      { name: "Polyester", code: "PES" },
      { name: "Viscose", code: "VIS" },
      { name: "Nylon", code: "NYL" },
    ])
    .onConflictDoNothing()
    .returning();

  const yarnCounts = await db
    .insert(yarnCountMasterTable)
    .values([
      { name: "20s (20)", count: "20" },
      { name: "30s (30)", count: "30" },
      { name: "40s (40)", count: "40" },
      { name: "60s (60)", count: "60" },
    ])
    .onConflictDoNothing()
    .returning();

  const yarnBrands = await db
    .insert(yarnBrandMasterTable)
    .values([
      { name: "Vardhman", code: "VAR" },
      { name: "Nahar", code: "NAH" },
      { name: "Trident", code: "TRI" },
      { name: "Welspun", code: "WEL" },
    ])
    .onConflictDoNothing()
    .returning();

  const uoms = await db
    .insert(uomMasterTable)
    .values([
      { name: "Kilogram", abbreviation: "KG" },
      { name: "Gram", abbreviation: "GM" },
      { name: "Meter", abbreviation: "MTR" },
      { name: "Piece", abbreviation: "PCS" },
    ])
    .onConflictDoNothing()
    .returning();

  const fabricTypes = await db
    .insert(fabricTypeMasterTable)
    .values([
      { name: "Single Jersey", code: "SJ" },
      { name: "Rib", code: "RIB" },
      { name: "Interlock", code: "INT" },
      { name: "Pique", code: "PIQ" },
    ])
    .onConflictDoNothing()
    .returning();

  await db
    .insert(machineOperatorMasterTable)
    .values([
      { name: "Operator Alpha", code: "OPA" },
      { name: "Operator Beta", code: "OPB" },
      { name: "Operator Gamma", code: "OPG" },
      { name: "Operator Delta", code: "OPD" },
    ])
    .onConflictDoNothing();

  console.log("Seeding sample transaction...");

  // Always fetch current lookup IDs (inserts above may have conflicted with existing data)
  const allJobs = await db.select().from(jobMasterTable).limit(2);
  const allParties = await db.select().from(partyMasterTable).limit(1);
  const allLocations = await db.select().from(locationMasterTable).limit(1);
  const allYarnTypes = await db.select().from(yarnTypeMasterTable).limit(1);
  const allYarnCounts = await db.select().from(yarnCountMasterTable).limit(2);
  const allYarnBrands = await db.select().from(yarnBrandMasterTable).limit(1);
  const allUoms = await db.select().from(uomMasterTable).limit(1);
  const allFabricTypes = await db.select().from(fabricTypeMasterTable).limit(1);
  const allMachines = await db.select().from(machineMasterTable).limit(2);
  const allOperators = await db.select().from(machineOperatorMasterTable).limit(2);

  const existingHeaders = await db.select().from(transactionHeaderTable).limit(1);

  const jobKnitting = allJobs[0];
  const jobProduction = allJobs[1];
  const party1 = allParties[0];
  const loc1 = allLocations[0];
  const yarnCotton = allYarnTypes[0];
  const yc30 = allYarnCounts[1] ?? allYarnCounts[0];
  const yb1 = allYarnBrands[0];
  const uomKg = allUoms[0];
  const ft1 = allFabricTypes[0];
  const m1 = allMachines[0];
  const m2 = allMachines[1];
  const op1 = allOperators[0];
  const op2 = allOperators[1];

  if (
    existingHeaders.length === 0 &&
    jobKnitting &&
    loc1 &&
    party1 &&
    yarnCotton &&
    yc30 &&
    yb1 &&
    uomKg &&
    ft1
  ) {
    const [header] = await db
      .insert(transactionHeaderTable)
      .values({
        transactionTypeId: jobKnitting.id,
        date: "2024-01-15",
        docNumber: "DOC-001",
        jobId: jobProduction?.id ?? null,
        partyId: party1.id,
        locationId: loc1.id,
        yarnTypeId: yarnCotton.id,
        yarnCountId: yc30.id,
        yarnBrandId: yb1.id,
        uomId: uomKg.id,
        fabricTypeId: ft1.id,
        sl: 1,
        gsm: 160,
      })
      .returning();

    if (header && m1) {
      await db.insert(transactionDetailTable).values([
        {
          headerId: header.id,
          machineId: m1.id,
          machineOperatorId: op1?.id ?? null,
          quantity: "250.500",
          netWt: "248.750",
        },
        ...(m2 ? [{
          headerId: header.id,
          machineId: m2.id,
          machineOperatorId: op2?.id ?? null,
          quantity: "120.000",
          netWt: "119.500",
        }] : []),
      ]);
    }
  }

  console.log("Seed complete.");
  await pool.end();
}

seed().catch((err) => {
  console.error("Seed failed:", err);
  process.exit(1);
});
