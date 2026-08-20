import { lazy, Suspense } from "react";
import { Switch, Route, Router as WouterRouter, Redirect } from "wouter";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { Toaster } from "@/components/ui/toaster";
import { TooltipProvider } from "@/components/ui/tooltip";
import { ConfigurationProvider } from "@/context/config-context";
import { AuthProvider } from "@/context/auth-context";
import { ProtectedRoute } from "@/components/protected-route";
import {
  RouteErrorBoundary,
  SuspenseFallback,
} from "@/components/route-error-boundary";
import { lazyRetry } from "@/lib/lazy-retry";
import NotFound from "@/pages/not-found";
import LoginPage from "@/pages/login";

// Dashboard is the heaviest page (7 data hooks, Recharts, charts) — lazy-load
// it like the other heavy screens so the initial bundle doesn't include it.
const DashboardPage = lazyRetry(() => import("@/pages/dashboard"));

const TransactionList = lazyRetry(() => import("@/pages/transactions"));
const TransactionForm = lazyRetry(() => import("@/pages/transactions/form"));
const DailyProductionList = lazyRetry(() => import("@/pages/daily-production"));
const YarnReceiptList = lazyRetry(() => import("@/pages/yarn-receipts"));
const DailyDeliveryList = lazyRetry(() => import("@/pages/daily-deliveries"));
const MonthlySalaryEntryPage = lazyRetry(() => import("@/pages/transactions/monthly-salary-entry"));
const AdvancesPage = lazyRetry(() => import("@/pages/transactions/advances"));
const PayrollEntryPage = lazyRetry(() => import("@/pages/transactions/payroll-entry"));
const MastersPage = lazyRetry(() => import("@/pages/masters"));
const YarnBalancePage = lazyRetry(() => import("@/pages/reports/index"));
const YarnToFabricPage = lazyRetry(() => import("@/pages/reports/yarn-to-fabric"));
const MachineMaintenancePage = lazyRetry(() => import("@/pages/maintenance/machine-maintenance"));
const FactoryMaintenancePage = lazyRetry(() => import("@/pages/maintenance/factory-maintenance"));
const AttendancePage = lazyRetry(() => import("@/pages/attendance"));
const InvoicingPage = lazyRetry(() => import("@/pages/invoicing"));
const SettingsPage = lazyRetry(() => import("@/pages/settings"));

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      // Master/lookup data changes rarely; skip re-fetch for 5 minutes to stop
      // the app from hammering the API on every navigation. Mutations already
      // invalidate their affected queries, so a long staleTime is safe. (issue #15)
      staleTime: 5 * 60 * 1000,
      // Keep cached data around a while so returning to a screen is instant.
      gcTime: 30 * 60 * 1000,
      retry: 2,
    },
  },
});

function Router() {
  return (
    <RouteErrorBoundary>
      <Suspense fallback={<SuspenseFallback />}>
        <Switch>
          <Route path="/login" component={LoginPage} />
          <Route path="/">
            <ProtectedRoute moduleId="dashboard">
              <Redirect to="/dashboard" />
            </ProtectedRoute>
          </Route>
          <Route path="/dashboard">
            <ProtectedRoute moduleId="dashboard"><DashboardPage /></ProtectedRoute>
          </Route>
          <Route path="/transactions">
            <ProtectedRoute moduleId="transactions"><TransactionList /></ProtectedRoute>
          </Route>
          <Route path="/transactions/new">
            <ProtectedRoute moduleId="transactions"><TransactionForm /></ProtectedRoute>
          </Route>
          <Route path="/transactions/:id/edit">
            <ProtectedRoute moduleId="transactions"><TransactionForm /></ProtectedRoute>
          </Route>
          <Route path="/daily-production">
            <ProtectedRoute moduleId="dailyProduction"><DailyProductionList /></ProtectedRoute>
          </Route>
          <Route path="/attendance">
            <ProtectedRoute moduleId="dailyProduction"><AttendancePage /></ProtectedRoute>
          </Route>
          <Route path="/yarn-receipts">
            <ProtectedRoute moduleId="yarnReceipts"><YarnReceiptList /></ProtectedRoute>
          </Route>
          <Route path="/daily-deliveries">
            <ProtectedRoute moduleId="dailyDeliveries"><DailyDeliveryList /></ProtectedRoute>
          </Route>
          <Route path="/transactions/monthly-salary-entry/new">
            <ProtectedRoute moduleId="payroll"><PayrollEntryPage /></ProtectedRoute>
          </Route>
          <Route path="/transactions/monthly-salary-entry/:id/edit">
            <ProtectedRoute moduleId="payroll"><PayrollEntryPage /></ProtectedRoute>
          </Route>
          <Route path="/transactions/monthly-salary-entry">
            <ProtectedRoute moduleId="payroll"><MonthlySalaryEntryPage /></ProtectedRoute>
          </Route>
          <Route path="/transactions/advances">
            <ProtectedRoute moduleId="payroll"><AdvancesPage /></ProtectedRoute>
          </Route>
          <Route path="/masters">
            <ProtectedRoute moduleId="masters"><MastersPage /></ProtectedRoute>
          </Route>
          <Route path="/reports">
            <ProtectedRoute moduleId="reports"><Redirect to="/reports/yarn-balance" /></ProtectedRoute>
          </Route>
          <Route path="/reports/yarn-balance">
            <ProtectedRoute moduleId="reports"><YarnBalancePage /></ProtectedRoute>
          </Route>
          <Route path="/reports/yarn-to-fabric">
            <ProtectedRoute moduleId="reports"><YarnToFabricPage /></ProtectedRoute>
          </Route>
          <Route path="/maintenance/machine">
            <ProtectedRoute moduleId="maintenance"><MachineMaintenancePage /></ProtectedRoute>
          </Route>
          <Route path="/maintenance/factory">
            <ProtectedRoute moduleId="maintenance"><FactoryMaintenancePage /></ProtectedRoute>
          </Route>
          <Route path="/invoicing">
            <ProtectedRoute moduleId="invoicing"><InvoicingPage /></ProtectedRoute>
          </Route>
          <Route path="/settings">
            <ProtectedRoute moduleId="users"><SettingsPage /></ProtectedRoute>
          </Route>
          <Route component={NotFound} />
        </Switch>
      </Suspense>
    </RouteErrorBoundary>
  );
}

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <ConfigurationProvider>
          <TooltipProvider>
            <WouterRouter base={import.meta.env.BASE_URL.replace(/\/$/, "")}>
              <Router />
            </WouterRouter>
            <Toaster />
          </TooltipProvider>
        </ConfigurationProvider>
      </AuthProvider>
    </QueryClientProvider>
  );
}

export default App;
