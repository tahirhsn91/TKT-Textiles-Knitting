import { Router, type IRouter } from "express";
import { requirePermission } from "../lib/auth.js";
import healthRouter from "./health.js";
import lookupsRouter from "./lookups.js";
import mastersRouter from "./masters.js";
import transactionsRouter from "./transactions.js";
import reportsRouter from "./reports.js";
import employeesRouter from "./employees.js";
import salaryEntriesRouter from "./salary-entries.js";
import dashboardRouter from "./dashboard.js";
import dailyProductionRouter from "./daily-production.js";
import yarnReceiptsRouter from "./yarn-receipts.js";
import dailyDeliveriesRouter from "./daily-deliveries.js";
import plausibilityRouter from "./plausibility.js";
import unreconciledNavRouter from "./unreconciled-nav.js";
import machineMaintenanceRouter from "./machine-maintenance.js";
import factoryMaintenanceRouter from "./factory-maintenance.js";
import machineAnalyticsRouter from "./machine-analytics.js";
import partyAnalyticsRouter from "./party-analytics.js";
import companyInfoRouter from "./company-info.js";
import invoicingRouter from "./invoicing.js";
import usersRouter from "./users.js";

const router: IRouter = Router();

// Public: health. Exempted from auth by the app.ts whitelist.
router.use(healthRouter);

// Lookups are universal reference data (party, machine, employee, yarn types,
// …) used by virtually every authenticated screen across all roles. They are
// NOT scoped to a single module, so they are mounted auth-only here (global
// requireAuth in app.ts already guards them) rather than behind a
// requirePermission gate — gating them under e.g. "masters" would 401 short
// any role that lacks that module (issue #135 regression).
router.use(lookupsRouter);

// Protected — each router defines its own full paths internally, so we gate it
// with a route-level permission middleware (no mount prefix). The module id is
// what the admin toggles in the permissions UI (issue #135). requireAuth is
// applied globally in app.ts; these guards only check route access.
router.use(requirePermission("masters"), mastersRouter);
router.use(requirePermission("transactions"), transactionsRouter);
router.use(requirePermission("reports"), reportsRouter);
router.use(requirePermission("employees"), employeesRouter);
router.use(requirePermission("payroll"), salaryEntriesRouter);
router.use(requirePermission("dashboard"), dashboardRouter);
router.use(requirePermission("dailyProduction"), dailyProductionRouter);
router.use(requirePermission("yarnReceipts"), yarnReceiptsRouter);
router.use(requirePermission("dailyDeliveries"), dailyDeliveriesRouter);
router.use(requirePermission("dashboard"), plausibilityRouter);
router.use(requirePermission("dashboard"), unreconciledNavRouter);
router.use(requirePermission("maintenance"), machineMaintenanceRouter);
router.use(requirePermission("maintenance"), factoryMaintenanceRouter);
router.use(requirePermission("dashboard"), machineAnalyticsRouter);
router.use(requirePermission("dashboard"), partyAnalyticsRouter);
router.use(requirePermission("companyInfo"), companyInfoRouter);
router.use(requirePermission("invoicing"), invoicingRouter);
// Users/RBAC admin — admin-only enforced inside the router (users.ts).
router.use(requirePermission("users"), usersRouter);

export default router;
