/**
 * Pure helpers for the machine history audit trail.
 *
 * Every create/update/delete against machine_master writes a snapshot row into
 * machine_history (the machine's state AFTER the write) tagged with the action
 * and actor. These helpers build that snapshot from a machine_master row — kept
 * free of any DB import so they are unit-testable without a connection.
 */

export type MachineHistoryAction = "created" | "updated" | "deleted";

/**
 * Build the insert values for a machine_history row from a machine_master
 * snapshot (the row AFTER a create/update, or the row being deleted). Identity
 * (machine_id nullable, machine_number + name denormalized) plus the
 * needle/sinker fields and making rate are captured. Absent optional fields map
 * to null (not undefined) so the INSERT never trips on missing keys.
 */
export function machineHistoryValues(
  row: Record<string, unknown>,
  action: MachineHistoryAction,
  actor: string,
): Record<string, unknown> {
  return {
    machineId: (row.id ?? null) as number | null,
    machineNumber: String(row.machineNumber ?? ""),
    name: String(row.name ?? ""),
    makingRate: row.makingRate != null ? String(row.makingRate) : null,
    needleChangeDate: row.needleChangeDate || null,
    needleBrand: row.needleBrand || null,
    sinkerChangeDate: row.sinkerChangeDate || null,
    sinkerBrand: row.sinkerBrand || null,
    action,
    changedBy: actor,
  };
}
