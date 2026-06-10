/**
 * Import parkings from prisma/data/parkings.csv
 * Columns: X (longitude), Y (latitude), Z, Name, 24, EasyPay
 *
 * Run: npm run prisma:import-parkings
 * Requires: DATABASE_URL, Postgres up (npm run db from repo root)
 */
import { PrismaClient } from '@prisma/client';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const prisma = new PrismaClient();

const DEFAULT_CAPACITY = 20;
const DEFAULT_ZONE = 'leopark_lviv';

/** Minimal RFC 4180-style parser for quoted fields. */
function parseCsv(text: string): string[][] {
  const rows: string[][] = [];
  let row: string[] = [];
  let field = '';
  let i = 0;
  let inQuotes = false;

  while (i < text.length) {
    const ch = text[i]!;

    if (inQuotes) {
      if (ch === '"') {
        if (text[i + 1] === '"') {
          field += '"';
          i += 2;
          continue;
        }
        inQuotes = false;
        i += 1;
        continue;
      }
      field += ch;
      i += 1;
      continue;
    }

    if (ch === '"') {
      inQuotes = true;
      i += 1;
      continue;
    }
    if (ch === ',') {
      row.push(field);
      field = '';
      i += 1;
      continue;
    }
    if (ch === '\r') {
      i += 1;
      continue;
    }
    if (ch === '\n') {
      row.push(field);
      if (row.some((c) => c.length > 0)) {
        rows.push(row);
      }
      row = [];
      field = '';
      i += 1;
      continue;
    }
    field += ch;
    i += 1;
  }

  if (field.length > 0 || row.length > 0) {
    row.push(field);
    if (row.some((c) => c.length > 0)) {
      rows.push(row);
    }
  }

  return rows;
}

function emptyToNull(s: string | undefined): string | null {
  const t = s?.trim();
  return t && t.length > 0 ? t : null;
}

async function main() {
  const csvPath =
    process.env.PARKINGS_CSV?.trim() || join(__dirname, 'data', 'parkings.csv');
  const raw = readFileSync(csvPath, 'utf8');
  const rows = parseCsv(raw);

  if (rows.length < 2) {
    throw new Error(`CSV empty or missing data: ${csvPath}`);
  }

  const header = rows[0]!.map((h) => h.trim());
  const idx = (name: string) => header.indexOf(name);
  const xIdx = idx('X');
  const yIdx = idx('Y');
  const zIdx = idx('Z');
  const nameIdx = idx('Name');
  const pay24Idx = idx('24');
  const easyPayIdx = idx('EasyPay');

  if ([xIdx, yIdx, zIdx, nameIdx].some((i) => i < 0)) {
    throw new Error(`CSV must have X, Y, Z, Name columns. Got: ${header.join(', ')}`);
  }

  const data = rows.slice(1).map((cols) => {
    const longitude = Number(cols[xIdx]!.trim());
    const latitude = Number(cols[yIdx]!.trim());
    const altitude = Number(cols[zIdx]!.trim() || '0');
    const name = cols[nameIdx]!.trim().replace(/\s+/g, ' ');

    if (!Number.isFinite(longitude) || !Number.isFinite(latitude)) {
      throw new Error(`Invalid coordinates for "${name}"`);
    }
    if (!name) {
      throw new Error('Empty Name in CSV row');
    }

    return {
      name,
      longitude,
      latitude,
      altitude: Number.isFinite(altitude) ? Math.trunc(altitude) : 0,
      pay24: pay24Idx >= 0 ? emptyToNull(cols[pay24Idx]) : null,
      easyPay: easyPayIdx >= 0 ? emptyToNull(cols[easyPayIdx]) : null,
      capacity: DEFAULT_CAPACITY,
      zone: DEFAULT_ZONE,
    };
  });

  console.log(`Parsed ${data.length} rows from ${csvPath}`);

  const deleted = await prisma.parking.deleteMany({});
  console.log(`Cleared ${deleted.count} existing parkings`);

  const result = await prisma.parking.createMany({ data });
  console.log(`Inserted ${result.count} parkings (X→longitude, Y→latitude)`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
