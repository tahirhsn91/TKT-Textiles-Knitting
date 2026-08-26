import { Router, type IRouter } from "express";
import { requireAnyPermission, requirePermission } from "../lib/auth.js";
import { resolveTenant } from "../middleware/tenant-context.js";
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
import brandingRouter from "./branding-routes.js";
import configurationRouter from "./configuration-routes.js";
import invitationsRouter from "./invitations-routes.js";
import auditLogsRouter from "./audit-logs-routes.js";
// Temporarily disabled due to TypeScript compilation issues with Knex-based services
// import adminRouter from "./admin-routes.js";
// import authRoutesRouter from "./auth-routes.js";
// import brandingRoutesRouter from "./branding-routes.js";
// import configurationRoutesRouter from "./configuration-routes.js";

const router: IRouter = Router();

// Public: health. Exempted from auth by the app.ts whitelist.
router.use(healthRouter);

// Platform-level super-admin routes (tenant management, tenant switching).
// These are global and must NOT go through resolveTenant (which would 428 a
// super-admin who has not yet selected an active tenant). requireSuperAdmin
// guards them internally.
router.use("/admin", adminRouter);

// Lookups are universal reference data (party, machine, employee, yarn types,
// …) used by virtually every authenticated screen across all roles. They are
// NOT scoped to a single module, so they are mounted auth-only here (global
// requireAuth in app.ts already guards them) rather than behind a
// requirePermission gate — gating them under e.g. "masters" would 401 short
// any role that lacks that module (issue #135 regression).
// NOTE: lookups data is tenant-scoped (issue #219 Q5b), so this router MUST be
// mounted AFTER resolveTenant — otherwise req.tenantId is unset and
// activeTenantId() throws (500 on every /lookups/* call).

// Resolve the active tenant context for every authenticated request (issue
// #219). Runs after global requireAuth (app.ts). Sets req.tenantId and blocks
// cross-tenant access / inactive tenants. Super-admins select a tenant via the
// X-Tenant-Id header (428 if none); tenant users are bound to their home tenant.
router.use(resolveTenant);

// Lookups router — tenant-scoped, mounted after resolveTenant.
router.use(lookupsRouter);

// Branding — tenant-scoped (issue #219 1.2 white-labeling). Serves the active
// tenant's branding package + allows updating the branding config.
router.use("/branding", brandingRouter);

// Configuration & Settings — tenant-scoped (issue #219 1.3). Company settings,
// feature flags, and a configuration summary.
router.use("/configuration", configurationRouter);

// User invitations — tenant-scoped (issue #219 1.4). Invite people to the
// active tenant, manage/resend/revoke invites, accept to create the user.
router.use("/invitations", invitationsRouter);

// Audit logs — tenant-scoped query of the audit trail (issue #219 2.3).
router.use("/audit-logs", auditLogsRouter);

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
router.use("/users", requirePermission("users"), usersRouter);
// Attendance — lives under Daily Operations and feeds payroll.
router.use("/attendance", requirePermission("dailyProduction"), attendanceRouter);

// Temporarily disabled due to TypeScript compilation issues with Knex-based services
// Admin routes — super-admin only (requireSuperAdmin is enforced inside admin-routes.ts)
// router.use("/admin", adminRouter);

// Auth routes — authentication, sessions, 2FA, invitations
// router.use("/auth", authRoutesRouter);

// Branding routes — tenant-specific branding and themes
// TODO: Enable after multer is added to dependencies
// router.use("/branding", brandingRoutesRouter);

// Configuration routes — tenant settings, feature flags, integrations
// router.use("/configuration", configurationRoutesRouter);

export default router;
