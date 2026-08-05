import { lazy, Suspense } from "react";
import { Switch, Route, Router as WouterRouter, Redirect } from "wouter";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { Toaster } from "@/components/ui/toaster";
import { TooltipProvider } from "@/components/ui/tooltip";
import {
  RouteErrorBoundary,
  SuspenseFallback,
} from "@/components/route-error-boundary";
import { lazyRetry } from "@/lib/lazy-retry";
import NotFound from "@/pages/not-found";
import DashboardPage from "@/pages/dashboard";

const TransactionList = lazyRetry(() => import("@/pages/transactions"));
const TransactionForm = lazyRetry(() => import("@/pages/transactions/form"));
const DailyProductionList = lazyRetry(() => import("@/pages/daily-production"));
const YarnReceiptList = lazyRetry(() => import("@/pages/yarn-receipts"));
const MonthlySalaryEntryPage = lazyRetry(() => import("@/pages/transactions/monthly-salary-entry"));
const PayrollEntryPage = lazyRetry(() => import("@/pages/transactions/payroll-entry"));
const MastersPage = lazyRetry(() => import("@/pages/masters"));
const YarnBalancePage = lazyRetry(() => import("@/pages/reports/index"));
const YarnToFabricPage = lazyRetry(() => import("@/pages/reports/yarn-to-fabric"));

const queryClient = new QueryClient();

function Router() {
  return (
    <RouteErrorBoundary>
      <Suspense fallback={<SuspenseFallback />}>
        <Switch>
          <Route path="/" component={() => <Redirect to="/dashboard" />} />
          <Route path="/dashboard" component={DashboardPage} />
          <Route path="/transactions" component={TransactionList} />
          <Route path="/transactions/new" component={TransactionForm} />
          <Route path="/transactions/:id/edit" component={TransactionForm} />
          <Route path="/daily-production" component={DailyProductionList} />
          <Route path="/yarn-receipts" component={YarnReceiptList} />
          <Route path="/transactions/monthly-salary-entry/new" component={PayrollEntryPage} />
          <Route path="/transactions/monthly-salary-entry/:id/edit" component={PayrollEntryPage} />
          <Route path="/transactions/monthly-salary-entry" component={MonthlySalaryEntryPage} />
          <Route path="/masters" component={MastersPage} />
          <Route path="/reports" component={() => <Redirect to="/reports/yarn-balance" />} />
          <Route path="/reports/yarn-balance" component={YarnBalancePage} />
          <Route path="/reports/yarn-to-fabric" component={YarnToFabricPage} />
          <Route component={NotFound} />
        </Switch>
      </Suspense>
    </RouteErrorBoundary>
  );
}

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <TooltipProvider>
        <WouterRouter base={import.meta.env.BASE_URL.replace(/\/$/, "")}>
          <Router />
        </WouterRouter>
        <Toaster />
      </TooltipProvider>
    </QueryClientProvider>
  );
}

export default App;
