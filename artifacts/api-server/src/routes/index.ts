import { Router, type IRouter } from "express";
import healthRouter from "./health";
import lookupsRouter from "./lookups";
import transactionsRouter from "./transactions";

const router: IRouter = Router();

router.use(healthRouter);
router.use(lookupsRouter);
router.use(transactionsRouter);

export default router;
