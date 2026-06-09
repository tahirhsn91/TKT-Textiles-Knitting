import { ReactNode } from "react";
import { Link, useLocation } from "wouter";
import { Factory, FileText, Database, BarChart2, Users, LayoutDashboard } from "lucide-react";
import { cn } from "@/lib/utils";

const navItems = [
  { href: "/dashboard", label: "Dashboard", icon: LayoutDashboard },
  { href: "/transactions", label: "Transactions", icon: FileText },
  { href: "/masters", label: "Master Data", icon: Database },
  { href: "/reports", label: "Reports", icon: BarChart2 },
  { href: "/operators", label: "Operators", icon: Users },
];

export function Layout({ children }: { children: ReactNode }) {
  const [location] = useLocation();

  return (
    <div className="min-h-[100dvh] flex w-full flex-col bg-background">
      <header className="sticky top-0 z-10 flex h-14 items-center gap-6 border-b bg-card px-6 shadow-sm">
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
        </nav>
      </header>
      <main className="flex-1 p-4 md:p-6 w-full max-w-7xl mx-auto">
        {children}
      </main>
    </div>
  );
}
