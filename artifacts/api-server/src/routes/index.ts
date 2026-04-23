import { Router, type IRouter } from "express";
import healthRouter from "./health";
import lookupsRouter from "./lookups";
import mastersRouter from "./masters";
import transactionsRouter from "./transactions";

const router: IRouter = Router();

router.use(healthRouter);
router.use(lookupsRouter);
router.use(mastersRouter);
router.use(transactionsRouter);

export default router;
