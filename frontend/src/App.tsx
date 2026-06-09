import { Switch, Route, Router as WouterRouter, Redirect } from "wouter";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { Toaster } from "@/components/ui/toaster";
import { TooltipProvider } from "@/components/ui/tooltip";
import NotFound from "@/pages/not-found";
import TransactionList from "@/pages/transactions";
import TransactionForm from "@/pages/transactions/form";
import MastersPage from "@/pages/masters";
import ReportsPage from "@/pages/reports";
import OperatorsPage from "@/pages/operators";
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
      <Route path="/masters" component={MastersPage} />
      <Route path="/reports" component={ReportsPage} />
      <Route path="/operators" component={OperatorsPage} />
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
