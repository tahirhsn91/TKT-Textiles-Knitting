import { Router, type IRouter } from "express";
import healthRouter from "./health";
import lookupsRouter from "./lookups";
import mastersRouter from "./masters";
import transactionsRouter from "./transactions";
import reportsRouter from "./reports";
import operatorsRouter from "./operators";
import salaryEntriesRouter from "./salary-entries";
import dashboardRouter from "./dashboard";

const router: IRouter = Router();

router.use(healthRouter);
router.use(lookupsRouter);
router.use(mastersRouter);
router.use(transactionsRouter);
router.use(reportsRouter);
router.use(operatorsRouter);
router.use(salaryEntriesRouter);
router.use(dashboardRouter);

export default router;
