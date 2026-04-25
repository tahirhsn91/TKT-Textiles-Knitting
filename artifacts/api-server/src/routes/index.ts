import { Router, type IRouter } from "express";
import healthRouter from "./health";
import lookupsRouter from "./lookups";
import mastersRouter from "./masters";
import transactionsRouter from "./transactions";
import reportsRouter from "./reports";

const router: IRouter = Router();

router.use(healthRouter);
router.use(lookupsRouter);
router.use(mastersRouter);
router.use(transactionsRouter);
router.use(reportsRouter);

export default router;
