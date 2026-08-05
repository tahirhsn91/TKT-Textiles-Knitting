import { Router, type IRouter } from "express";
import healthRouter from "./health.js";
import lookupsRouter from "./lookups.js";
import mastersRouter from "./masters.js";
import transactionsRouter from "./transactions.js";
import reportsRouter from "./reports.js";
import operatorsRouter from "./operators.js";
import salaryEntriesRouter from "./salary-entries.js";
import dashboardRouter from "./dashboard.js";
import dailyProductionRouter from "./daily-production.js";
import yarnReceiptsRouter from "./yarn-receipts.js";
import dailyDeliveriesRouter from "./daily-deliveries.js";

const router: IRouter = Router();

router.use(healthRouter);
router.use(lookupsRouter);
router.use(mastersRouter);
router.use(transactionsRouter);
router.use(reportsRouter);
router.use(operatorsRouter);
router.use(salaryEntriesRouter);
router.use(dashboardRouter);
router.use(dailyProductionRouter);
router.use(yarnReceiptsRouter);
router.use(dailyDeliveriesRouter);

export default router;
