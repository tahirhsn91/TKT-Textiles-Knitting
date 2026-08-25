import { Router, type IRouter } from "express";
import { requireAnyPermission, requirePermission } from "../lib/auth.js";
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
import attendanceRouter from "./attendance.js";
import adminRouter from "./admin-routes.js";

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

// Protected — each router defines its own full (absolute) paths internally, so
// each is mounted at the root (router.use(subRouter)) and its routes match their
// own prefixes. The permission guard is mounted separately with a path prefix so
// it ONLY runs for requests hitting that router — mounting the guard with
// router.use(guard, subRouter) and no path applied the permission check to EVERY
// request and 403'd any role missing a single module (issue #135 regression).
// The module id is what the admin toggles in the permissions UI; requireAuth is
// applied globally in app.ts, these guards only check route access.
router.use("/masters", requirePermission("masters"));
router.use(mastersRouter);
router.use("/transactions", requirePermission("transactions"));
router.use(transactionsRouter);
router.use("/reports", requirePermission("reports"));
router.use(reportsRouter);
// Employees router serves advances + payroll-summary, which the frontend
// treats under BOTH "employees" (Employees page tabs) and "payroll" (the
// standalone Advances page and monthly salary entry). Allow either module so a
// payroll-only role isn't 403'd on routes the UI already lets it open.
router.use("/employees", requireAnyPermission("employees", "payroll"));
router.use(employeesRouter);
router.use("/salary-entries", requirePermission("payroll"));
router.use(salaryEntriesRouter);
router.use("/dashboard", requirePermission("dashboard"));
router.use(dashboardRouter);
router.use("/daily-production", requirePermission("dailyProduction"));
router.use(dailyProductionRouter);
router.use("/yarn-receipts", requirePermission("yarnReceipts"));
router.use(yarnReceiptsRouter);
router.use("/daily-deliveries", requirePermission("dailyDeliveries"));
router.use(dailyDeliveriesRouter);
router.use(["/validate", "/plausibility"], requirePermission("dashboard"));
router.use(plausibilityRouter);
router.use("/daily-ops", requirePermission("dashboard"));
router.use(unreconciledNavRouter);
router.use("/maintenance/machine", requirePermission("maintenance"));
router.use(machineMaintenanceRouter);
router.use("/maintenance/factory", requirePermission("maintenance"));
router.use(factoryMaintenanceRouter);
router.use("/machine-analytics", requirePermission("dashboard"));
router.use(machineAnalyticsRouter);
router.use("/party-analytics", requirePermission("dashboard"));
router.use(partyAnalyticsRouter);
router.use("/masters/company-info", requirePermission("companyInfo"));
router.use(companyInfoRouter);
router.use("/invoicing", requirePermission("invoicing"));
router.use(invoicingRouter);
// Users/RBAC admin — admin-only enforced inside the router (users.ts).
router.use("/users", requirePermission("users"));
router.use("/users", usersRouter);
// Attendance — lives under Daily Operations and feeds payroll.
router.use("/attendance", requirePermission("dailyProduction"));
router.use(attendanceRouter);

// Admin routes — super-admin only (requireSuperAdmin is enforced inside admin-routes.ts)
router.use("/admin", adminRouter);

export default router;
