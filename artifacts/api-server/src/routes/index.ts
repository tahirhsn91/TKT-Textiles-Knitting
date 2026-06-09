import { Router, type IRouter } from "express";
import healthRouter from "./health";
import lookupsRouter from "./lookups";
import mastersRouter from "./masters";
import transactionsRouter from "./transactions";
import reportsRouter from "./reports";
import operatorsRouter from "./operators";

const router: IRouter = Router();

router.use(healthRouter);
router.use(lookupsRouter);
router.use(mastersRouter);
router.use(transactionsRouter);
router.use(reportsRouter);
router.use(operatorsRouter);

export default router;
