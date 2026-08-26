import { lazy, Suspense } from "react";
import { Switch, Route, Router as WouterRouter, Redirect } from "wouter";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { Toaster } from "@/components/ui/toaster";
import { TooltipProvider } from "@/components/ui/tooltip";
import { ConfigurationProvider } from "@/context/config-context";
import { AuthProvider } from "@/context/auth-context";
import { BrandingApplier } from "@/components/branding-applier";
import { ProtectedRoute } from "@/components/protected-route";
import { TenantRequired } from "@/components/tenant-required";
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
const AdminTenantsPage = lazyRetry(() => import("@/pages/admin/tenants"));

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
            <ProtectedRoute moduleId="dashboard"><TenantRequired><DashboardPage /></TenantRequired></ProtectedRoute>
          </Route>
          <Route path="/transactions">
            <ProtectedRoute moduleId="transactions"><TenantRequired><TransactionList /></TenantRequired></ProtectedRoute>
          </Route>
          <Route path="/transactions/new">
            <ProtectedRoute moduleId="transactions"><TenantRequired><TransactionForm /></TenantRequired></ProtectedRoute>
          </Route>
          <Route path="/transactions/:id/edit">
            <ProtectedRoute moduleId="transactions"><TenantRequired><TransactionForm /></TenantRequired></ProtectedRoute>
          </Route>
          <Route path="/daily-production">
            <ProtectedRoute moduleId="dailyProduction"><TenantRequired><DailyProductionList /></TenantRequired></ProtectedRoute>
          </Route>
          <Route path="/attendance">
            <ProtectedRoute moduleId="dailyProduction"><TenantRequired><AttendancePage /></TenantRequired></ProtectedRoute>
          </Route>
          <Route path="/yarn-receipts">
            <ProtectedRoute moduleId="yarnReceipts"><TenantRequired><YarnReceiptList /></TenantRequired></ProtectedRoute>
          </Route>
          <Route path="/daily-deliveries">
            <ProtectedRoute moduleId="dailyDeliveries"><TenantRequired><DailyDeliveryList /></TenantRequired></ProtectedRoute>
          </Route>
          <Route path="/transactions/monthly-salary-entry/new">
            <ProtectedRoute moduleId="payroll"><TenantRequired><PayrollEntryPage /></TenantRequired></ProtectedRoute>
          </Route>
          <Route path="/transactions/monthly-salary-entry/:id/edit">
            <ProtectedRoute moduleId="payroll"><TenantRequired><PayrollEntryPage /></TenantRequired></ProtectedRoute>
          </Route>
          <Route path="/transactions/monthly-salary-entry">
            <ProtectedRoute moduleId="payroll"><TenantRequired><MonthlySalaryEntryPage /></TenantRequired></ProtectedRoute>
          </Route>
          <Route path="/transactions/advances">
            <ProtectedRoute moduleId="payroll"><TenantRequired><AdvancesPage /></TenantRequired></ProtectedRoute>
          </Route>
          <Route path="/masters">
            <ProtectedRoute moduleId="masters"><TenantRequired><MastersPage /></TenantRequired></ProtectedRoute>
          </Route>
          <Route path="/reports">
            <ProtectedRoute moduleId="reports"><TenantRequired><Redirect to="/reports/yarn-balance" /></TenantRequired></ProtectedRoute>
          </Route>
          <Route path="/reports/yarn-balance">
            <ProtectedRoute moduleId="reports"><TenantRequired><YarnBalancePage /></TenantRequired></ProtectedRoute>
          </Route>
          <Route path="/reports/yarn-to-fabric">
            <ProtectedRoute moduleId="reports"><TenantRequired><YarnToFabricPage /></TenantRequired></ProtectedRoute>
          </Route>
          <Route path="/maintenance/machine">
            <ProtectedRoute moduleId="maintenance"><TenantRequired><MachineMaintenancePage /></TenantRequired></ProtectedRoute>
          </Route>
          <Route path="/maintenance/factory">
            <ProtectedRoute moduleId="maintenance"><TenantRequired><FactoryMaintenancePage /></TenantRequired></ProtectedRoute>
          </Route>
          <Route path="/invoicing">
            <ProtectedRoute moduleId="invoicing"><TenantRequired><InvoicingPage /></TenantRequired></ProtectedRoute>
          </Route>
          <Route path="/settings">
            <ProtectedRoute moduleId="users"><TenantRequired><SettingsPage /></TenantRequired></ProtectedRoute>
          </Route>
          {/* /admin/tenants is platform-level — reachable without a tenant. */}
          <Route path="/admin/tenants">
            <ProtectedRoute><AdminTenantsPage /></ProtectedRoute>
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
        <BrandingApplier />
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
