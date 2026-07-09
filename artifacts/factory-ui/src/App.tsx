import { Switch, Route, Router as WouterRouter, Redirect } from "wouter";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { Toaster } from "@/components/ui/toaster";
import { TooltipProvider } from "@/components/ui/tooltip";
import NotFound from "@/pages/not-found";
import TransactionList from "@/pages/transactions";
import TransactionForm from "@/pages/transactions/form";
import MonthlySalaryEntryPage from "@/pages/transactions/monthly-salary-entry";
import MastersPage from "@/pages/masters";
import YarnBalancePage from "@/pages/reports/index";
import YarnToFabricPage from "@/pages/reports/yarn-to-fabric";
import DashboardPage from "@/pages/dashboard";

const queryClient = new QueryClient();

function Router() {
  return (
    <Switch>
      <Route path="/" component={() => <Redirect to="/dashboard" />} />
      <Route path="/dashboard" component={DashboardPage} />
      <Route path="/transactions" component={TransactionList} />
      <Route path="/transactions/new" component={TransactionForm} />
      <Route path="/transactions/:id/edit" component={TransactionForm} />
      <Route path="/transactions/monthly-salary-entry" component={MonthlySalaryEntryPage} />
      <Route path="/masters" component={MastersPage} />
      <Route path="/reports" component={() => <Redirect to="/reports/yarn-balance" />} />
      <Route path="/reports/yarn-balance" component={YarnBalancePage} />
      <Route path="/reports/yarn-to-fabric" component={YarnToFabricPage} />
      <Route component={NotFound} />
    </Switch>
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
