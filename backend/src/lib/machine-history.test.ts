import { test } from "node:test";
import assert from "node:assert/strict";
import { machineHistoryValues } from "../lib/machine-history.js";

test("machineHistoryValues: captures the needle/sinker snapshot + identity + actor", () => {
  const row = {
    id: 42,
    machineNumber: "M-001",
    name: "Circular Knitting Machine 1",
    makingRate: "3.75",
    needleChangeDate: "2026-01-15",
    needleBrand: "Sigma",
    sinkerChangeDate: "2026-02-01",
    sinkerBrand: "Kohala",
  };
  const v = machineHistoryValues(row, "updated", "operator");
  assert.equal(v.machineId, 42);
  assert.equal(v.machineNumber, "M-001");
  assert.equal(v.name, "Circular Knitting Machine 1");
  assert.equal(v.makingRate, "3.75");
  assert.equal(v.needleChangeDate, "2026-01-15");
  assert.equal(v.needleBrand, "Sigma");
  assert.equal(v.sinkerChangeDate, "2026-02-01");
  assert.equal(v.sinkerBrand, "Kohala");
  assert.equal(v.action, "updated");
  assert.equal(v.changedBy, "operator");
});

test("machineHistoryValues: preserves a full snapshot even when a machine is deleted", () => {
  const v = machineHistoryValues(
    { id: 7, machineNumber: "M-099", name: "Machine 9", makingRate: "3.75" },
    "deleted",
    "system",
  );
  assert.equal(v.action, "deleted");
  assert.equal(v.machineId, 7);
  // Identity denormalized so history survives the hard delete (no join needed).
  assert.equal(v.machineNumber, "M-099");
  assert.equal(v.name, "Machine 9");
});

test("machineHistoryValues: absent optional fields map to null (not undefined)", () => {
  const v = machineHistoryValues({ id: 1, machineNumber: "M-1", name: "M1" }, "created", "admin");
  assert.equal(v.needleChangeDate, null);
  assert.equal(v.needleBrand, null);
  assert.equal(v.sinkerChangeDate, null);
  assert.equal(v.sinkerBrand, null);
  assert.equal(v.makingRate, null);
});

test("machineHistoryValues: all three actions are representable", () => {
  for (const action of ["created", "updated", "deleted"] as const) {
    const v = machineHistoryValues({ id: 1, machineNumber: "M-1", name: "M1" }, action, "u");
    assert.equal(v.action, action);
  }
});
