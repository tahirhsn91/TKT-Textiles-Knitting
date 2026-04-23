import { drizzle } from "drizzle-orm/node-postgres";
import pg from "pg";
import { eq } from "drizzle-orm";
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

  console.log("Seeding sample transaction...");

  const existingHeaders = await db.select().from(transactionHeaderTable).limit(1);

  const jobKnitting = jobs[0];
  const jobProduction = jobs[1];
  const party1 = await db.select().from(partyMasterTable).limit(1).then(r => r[0]);
  const machine1 = machines[0];
  const loc1 = locations[0];

  if (
    existingHeaders.length === 0 &&
    jobKnitting &&
    machine1 &&
    loc1 &&
    party1
  ) {
    const [header] = await db
      .insert(transactionHeaderTable)
      .values({
        transactionTypeId: jobKnitting.id,
        date: "2024-01-15",
        docNumber: "DOC-001",
        jobId: jobProduction?.id ?? null,
        partyId: party1.id,
        machineNumber: machine1.id,
        locationId: loc1.id,
      })
      .returning();

    const yarnCotton = yarnTypes[0];
    const yarnPoly = yarnTypes[1];
    const yc30 = yarnCounts[1];
    const yc40 = yarnCounts[2];
    const yb1 = yarnBrands[0];
    const yb2 = yarnBrands[1];
    const uomKg = uoms[0];
    const ft1 = fabricTypes[0];
    const ft2 = fabricTypes[1];

    if (header && yarnCotton && yarnPoly && yc30 && yc40 && yb1 && yb2 && uomKg && ft1 && ft2) {
      await db.insert(transactionDetailTable).values([
        {
          headerId: header.id,
          yarnTypeId: yarnCotton.id,
          yarnCountId: yc30.id,
          yarnBrandId: yb1.id,
          uomId: uomKg.id,
          fabricType: ft1.id,
          sl: 1,
          gsm: 160,
          quantity: "250.500",
          netWt: "248.750",
        },
        {
          headerId: header.id,
          yarnTypeId: yarnPoly.id,
          yarnCountId: yc40.id,
          yarnBrandId: yb2.id,
          uomId: uomKg.id,
          fabricType: ft2.id,
          sl: 2,
          gsm: 220,
          quantity: "120.000",
          netWt: "119.500",
        },
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
