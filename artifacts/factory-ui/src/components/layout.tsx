import { ReactNode } from "react";
import { Link, useLocation } from "wouter";
import { Factory, FileText, Database, BarChart2, Users, LayoutDashboard, ChevronDown } from "lucide-react";
import { cn } from "@/lib/utils";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";

const navItems = [
  { href: "/dashboard",    label: "Dashboard",    icon: LayoutDashboard },
  { href: "/masters",      label: "Master Data",  icon: Database },
  { href: "/operators",    label: "Operators",    icon: Users },
];

const transactionItems = [
  { href: "/transactions",           label: "Yarn-Fabric Transactions" },
  { href: "/transactions/monthly-salary-entry", label: "Monthly Salary Entry" },
];

const reportItems = [
  { href: "/reports/yarn-balance",   label: "Yarn Balance Report" },
  { href: "/reports/yarn-to-fabric", label: "Yarn to Fabric Movement Report" },
];

export function Layout({ children }: { children: ReactNode }) {
  const [location] = useLocation();
  const transactionsActive = location.startsWith("/transactions");
  const reportsActive = location.startsWith("/reports");

  return (
    <div className="min-h-[100dvh] flex w-full flex-col bg-background">
      <header className="sticky top-0 z-10 flex h-14 items-center gap-6 border-b bg-card px-6 shadow-sm print:hidden">
        <Link href="/dashboard" className="flex items-center gap-2 font-semibold text-primary transition-colors hover:text-primary/80 shrink-0">
          <Factory className="h-5 w-5" />
          <span>FactoryOps ERP</span>
        </Link>

        <nav className="flex items-center gap-1">
          {navItems.map((item) => {
            const active = location === item.href || location.startsWith(item.href + "/");
            return (
              <Link key={item.href} href={item.href}>
                <span className={cn(
                  "flex items-center gap-2 px-3 py-1.5 rounded-md text-sm font-medium transition-colors",
                  active
                    ? "bg-primary/10 text-primary"
                    : "text-muted-foreground hover:text-foreground hover:bg-muted"
                )}>
                  <item.icon className="h-4 w-4" />
                  {item.label}
                </span>
              </Link>
            );
          })}

          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <button className={cn(
                "flex items-center gap-2 px-3 py-1.5 rounded-md text-sm font-medium transition-colors outline-none",
                transactionsActive
                  ? "bg-primary/10 text-primary"
                  : "text-muted-foreground hover:text-foreground hover:bg-muted"
              )}>
                <FileText className="h-4 w-4" />
                Transactions
                <ChevronDown className="h-3.5 w-3.5 opacity-60" />
              </button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="start" className="w-64">
              {transactionItems.map((item) => (
                <DropdownMenuItem key={item.href} asChild>
                  <Link href={item.href}>
                    <span className={cn(
                      "w-full cursor-pointer text-sm",
                      (item.href === "/transactions" ? location === item.href : location.startsWith(item.href))
                        ? "font-semibold text-primary"
                        : ""
                    )}>
                      {item.label}
                    </span>
                  </Link>
                </DropdownMenuItem>
              ))}
            </DropdownMenuContent>
          </DropdownMenu>

          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <button className={cn(
                "flex items-center gap-2 px-3 py-1.5 rounded-md text-sm font-medium transition-colors outline-none",
                reportsActive
                  ? "bg-primary/10 text-primary"
                  : "text-muted-foreground hover:text-foreground hover:bg-muted"
              )}>
                <BarChart2 className="h-4 w-4" />
                Reports
                <ChevronDown className="h-3.5 w-3.5 opacity-60" />
              </button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="start" className="w-60">
              {reportItems.map((item) => (
                <DropdownMenuItem key={item.href} asChild>
                  <Link href={item.href}>
                    <span className={cn(
                      "w-full cursor-pointer text-sm",
                      location.startsWith(item.href) ? "font-semibold text-primary" : ""
                    )}>
                      {item.label}
                    </span>
                  </Link>
                </DropdownMenuItem>
              ))}
            </DropdownMenuContent>
          </DropdownMenu>
        </nav>
      </header>
      <main className="flex-1 p-4 md:p-6 w-full max-w-7xl mx-auto print:p-0 print:max-w-none">
        {children}
      </main>
    </div>
  );
}
