import { lazy, Suspense } from "react";
import { Switch, Route, Router as WouterRouter, Redirect } from "wouter";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { Toaster } from "@/components/ui/toaster";
import { TooltipProvider } from "@/components/ui/tooltip";
import { Skeleton } from "@/components/ui/skeleton";
import NotFound from "@/pages/not-found";
import DashboardPage from "@/pages/dashboard";

const TransactionList = lazy(() => import("@/pages/transactions"));
const TransactionForm = lazy(() => import("@/pages/transactions/form"));
const MonthlySalaryEntryPage = lazy(() => import("@/pages/transactions/monthly-salary-entry"));
const PayrollEntryPage = lazy(() => import("@/pages/transactions/payroll-entry"));
const MastersPage = lazy(() => import("@/pages/masters"));
const YarnBalancePage = lazy(() => import("@/pages/reports/index"));
const YarnToFabricPage = lazy(() => import("@/pages/reports/yarn-to-fabric"));

const queryClient = new QueryClient();

function RouteFallback() {
  return (
    <div className="space-y-4 p-8">
      <Skeleton className="h-8 w-64" />
      <Skeleton className="h-32 w-full" />
      <Skeleton className="h-32 w-full" />
    </div>
  );
}

function Router() {
  return (
    <Suspense fallback={<RouteFallback />}>
      <Switch>
        <Route path="/" component={() => <Redirect to="/dashboard" />} />
        <Route path="/dashboard" component={DashboardPage} />
        <Route path="/transactions" component={TransactionList} />
        <Route path="/transactions/new" component={TransactionForm} />
        <Route path="/transactions/:id/edit" component={TransactionForm} />
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
