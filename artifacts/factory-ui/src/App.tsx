import { Switch, Route, Router as WouterRouter } from "wouter";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { Toaster } from "@/components/ui/toaster";
import { TooltipProvider } from "@/components/ui/tooltip";
import NotFound from "@/pages/not-found";
import TransactionList from "@/pages/transactions";
import TransactionForm from "@/pages/transactions/form";

const queryClient = new QueryClient();

function Router() {
  return (
    <Switch>
      <Route path="/" component={TransactionList} />
      <Route path="/transactions/new" component={TransactionForm} />
      <Route path="/transactions/:id/edit" component={TransactionForm} />
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
