import { ReactNode, useState, useEffect } from "react";
import { Link, useLocation } from "wouter";
import {
  Factory, FileText, Database, BarChart2, LayoutDashboard,
  ChevronDown, Menu, PanelLeftClose, PanelLeftOpen,
} from "lucide-react";
import { cn } from "@/lib/utils";
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
  SheetTrigger,
} from "@/components/ui/sheet";
import {
  Tooltip,
  TooltipContent,
  TooltipTrigger,
} from "@/components/ui/tooltip";

const navItems = [
  { href: "/dashboard",    label: "Dashboard",    icon: LayoutDashboard },
  { href: "/masters",      label: "Master Data",  icon: Database },
];

const transactionItems = [
  { href: "/transactions",           label: "Yarn-Fabric Transactions" },
  { href: "/transactions/monthly-salary-entry", label: "Payroll Maintenance" },
];

const reportItems = [
  { href: "/reports/yarn-balance",   label: "Yarn Balance Report" },
  { href: "/reports/yarn-to-fabric", label: "Yarn to Fabric Movement Report" },
];

// Primary route each collapsed group icon navigates to.
const TRANSACTIONS_PRIMARY = "/transactions";
const REPORTS_PRIMARY = "/reports/yarn-balance";

const LS_SIDEBAR_COLLAPSED = "sidebar-collapsed";

function isItemActive(location: string, href: string) {
  return location === href || location.startsWith(href + "/");
}
function isSubItemActive(location: string, href: string) {
  return href === "/transactions" ? location === href : location.startsWith(href);
}

export function Layout({ children }: { children: ReactNode }) {
  const [location] = useLocation();
  const [mobileOpen, setMobileOpen] = useState(false);
  const [collapsed, setCollapsed] = useState<boolean>(() => {
    try { return localStorage.getItem(LS_SIDEBAR_COLLAPSED) === "true"; } catch { return false; }
  });

  useEffect(() => {
    try { localStorage.setItem(LS_SIDEBAR_COLLAPSED, String(collapsed)); } catch {}
  }, [collapsed]);

  const transactionsActive = location.startsWith("/transactions");
  const reportsActive = location.startsWith("/reports");

  return (
    <div className="min-h-[100dvh] w-full bg-background">
      {/* ── Desktop fixed sidebar ─────────────────────────────── */}
      <aside
        className={cn(
          "hidden md:flex fixed inset-y-0 left-0 z-30 flex-col border-r bg-card transition-[width] duration-200 print:hidden",
          collapsed ? "w-16" : "w-64"
        )}
      >
        {/* Sidebar header: logo + collapse toggle */}
        <div className={cn(
          "flex h-14 items-center border-b",
          collapsed ? "justify-center px-0" : "justify-between px-4"
        )}>
          {!collapsed && (
            <Link href="/dashboard" className="flex items-center gap-2 font-semibold text-primary transition-colors hover:text-primary/80">
              <Factory className="h-5 w-5 shrink-0" />
              <span className="whitespace-nowrap">FactoryOps ERP</span>
            </Link>
          )}
          <button
            onClick={() => setCollapsed((c) => !c)}
            className="flex items-center justify-center rounded-md p-2 text-muted-foreground hover:bg-muted hover:text-foreground"
            aria-label={collapsed ? "Expand sidebar" : "Collapse sidebar"}
            title={collapsed ? "Expand menu" : "Collapse menu"}
          >
            {collapsed ? <PanelLeftOpen className="h-5 w-5" /> : <PanelLeftClose className="h-5 w-5" />}
          </button>
        </div>

        {/* Sidebar nav */}
        <nav className="flex flex-1 flex-col gap-1 overflow-y-auto p-2">
          {navItems.map((item) => (
            <DesktopItem
              key={item.href}
              href={item.href}
              label={item.label}
              icon={item.icon}
              active={isItemActive(location, item.href)}
              collapsed={collapsed}
            />
          ))}

          <DesktopGroup
            label="Transactions"
            icon={FileText}
            primary={TRANSACTIONS_PRIMARY}
            active={transactionsActive}
            collapsed={collapsed}
          >
            {transactionItems.map((item) => (
              <Link key={item.href} href={item.href}>
                <span className={cn(
                  "block rounded-md px-3 py-2 text-sm transition-colors",
                  isSubItemActive(location, item.href)
                    ? "font-semibold text-primary bg-primary/5"
                    : "text-muted-foreground hover:bg-muted hover:text-foreground"
                )}>
                  {item.label}
                </span>
              </Link>
            ))}
          </DesktopGroup>

          <DesktopGroup
            label="Reports"
            icon={BarChart2}
            primary={REPORTS_PRIMARY}
            active={reportsActive}
            collapsed={collapsed}
          >
            {reportItems.map((item) => (
              <Link key={item.href} href={item.href}>
                <span className={cn(
                  "block rounded-md px-3 py-2 text-sm transition-colors",
                  location.startsWith(item.href)
                    ? "font-semibold text-primary bg-primary/5"
                    : "text-muted-foreground hover:bg-muted hover:text-foreground"
                )}>
                  {item.label}
                </span>
              </Link>
            ))}
          </DesktopGroup>
        </nav>
      </aside>

      {/* ── Content column (offset by sidebar on desktop) ─────── */}
      <div className={cn(
        "flex min-h-[100dvh] flex-col transition-[margin] duration-200 print:ml-0",
        collapsed ? "md:ml-16" : "md:ml-64"
      )}>
        {/* Top bar — mobile hamburger + logo (hidden on desktop) */}
        <header className="sticky top-0 z-20 flex h-14 items-center gap-3 border-b bg-card px-4 shadow-sm md:hidden print:hidden">
          <Sheet open={mobileOpen} onOpenChange={setMobileOpen}>
            <SheetTrigger asChild>
              <button
                className="flex items-center justify-center rounded-md p-2 -ml-1 text-muted-foreground hover:bg-muted hover:text-foreground"
                aria-label="Open navigation menu"
              >
                <Menu className="h-5 w-5" />
              </button>
            </SheetTrigger>
            <SheetContent side="left" className="w-72 p-0">
              <SheetHeader className="border-b px-4 py-4 text-left">
                <SheetTitle className="flex items-center gap-2 text-primary">
                  <Factory className="h-5 w-5" />
                  FactoryOps ERP
                </SheetTitle>
              </SheetHeader>
              <nav className="flex flex-col gap-1 p-3">
                {navItems.map((item) => {
                  const active = isItemActive(location, item.href);
                  return (
                    <Link key={item.href} href={item.href} onClick={() => setMobileOpen(false)}>
                      <span className={cn(
                        "flex items-center gap-3 rounded-md px-3 py-2.5 text-sm font-medium transition-colors",
                        active
                          ? "bg-primary/10 text-primary"
                          : "text-muted-foreground hover:bg-muted hover:text-foreground"
                      )}>
                        <item.icon className="h-4 w-4" />
                        {item.label}
                      </span>
                    </Link>
                  );
                })}

                <MobileGroup label="Transactions" icon={FileText} active={transactionsActive}>
                  {transactionItems.map((item) => (
                    <Link key={item.href} href={item.href} onClick={() => setMobileOpen(false)}>
                      <span className={cn(
                        "block rounded-md px-3 py-2 text-sm transition-colors",
                        isSubItemActive(location, item.href)
                          ? "font-semibold text-primary"
                          : "text-muted-foreground hover:bg-muted hover:text-foreground"
                      )}>
                        {item.label}
                      </span>
                    </Link>
                  ))}
                </MobileGroup>

                <MobileGroup label="Reports" icon={BarChart2} active={reportsActive}>
                  {reportItems.map((item) => (
                    <Link key={item.href} href={item.href} onClick={() => setMobileOpen(false)}>
                      <span className={cn(
                        "block rounded-md px-3 py-2 text-sm transition-colors",
                        location.startsWith(item.href)
                          ? "font-semibold text-primary"
                          : "text-muted-foreground hover:bg-muted hover:text-foreground"
                      )}>
                        {item.label}
                      </span>
                    </Link>
                  ))}
                </MobileGroup>
              </nav>
            </SheetContent>
          </Sheet>

          <Link href="/dashboard" className="flex items-center gap-2 font-semibold text-primary transition-colors hover:text-primary/80 shrink-0">
            <Factory className="h-5 w-5" />
            <span className="whitespace-nowrap">FactoryOps ERP</span>
          </Link>
        </header>

        <main className="flex-1 p-4 md:p-6 w-full max-w-7xl mx-auto print:p-0 print:max-w-none">
          {children}
        </main>
      </div>
    </div>
  );
}

// ── Desktop single nav item ───────────────────────────────────
function DesktopItem({
  href, label, icon: Icon, active, collapsed,
}: {
  href: string;
  label: string;
  icon: React.ElementType;
  active: boolean;
  collapsed: boolean;
}) {
  const link = (
    <Link href={href}>
      <span className={cn(
        "flex items-center rounded-md text-sm font-medium transition-colors",
        collapsed ? "justify-center p-2.5" : "gap-3 px-3 py-2.5",
        active
          ? "bg-primary/10 text-primary"
          : "text-muted-foreground hover:bg-muted hover:text-foreground"
      )}>
        <Icon className="h-5 w-5 shrink-0" />
        {!collapsed && <span className="whitespace-nowrap">{label}</span>}
      </span>
    </Link>
  );

  if (!collapsed) return link;
  return (
    <Tooltip>
      <TooltipTrigger asChild>{link}</TooltipTrigger>
      <TooltipContent side="right">{label}</TooltipContent>
    </Tooltip>
  );
}

// ── Desktop group (expanded: accordion, collapsed: icon → primary route) ──
function DesktopGroup({
  label, icon: Icon, primary, active, collapsed, children,
}: {
  label: string;
  icon: React.ElementType;
  primary: string;
  active: boolean;
  collapsed: boolean;
  children: ReactNode;
}) {
  const [open, setOpen] = useState(active);

  // Auto-open when the section becomes active while expanded.
  useEffect(() => { if (active) setOpen(true); }, [active]);

  if (collapsed) {
    return (
      <Tooltip>
        <TooltipTrigger asChild>
          <Link href={primary}>
            <span className={cn(
              "flex items-center justify-center rounded-md p-2.5 text-sm font-medium transition-colors",
              active
                ? "bg-primary/10 text-primary"
                : "text-muted-foreground hover:bg-muted hover:text-foreground"
            )}>
              <Icon className="h-5 w-5 shrink-0" />
            </span>
          </Link>
        </TooltipTrigger>
        <TooltipContent side="right">{label}</TooltipContent>
      </Tooltip>
    );
  }

  return (
    <div className="flex flex-col">
      <button
        onClick={() => setOpen((o) => !o)}
        className={cn(
          "flex items-center gap-3 rounded-md px-3 py-2.5 text-sm font-medium transition-colors",
          active
            ? "bg-primary/10 text-primary"
            : "text-muted-foreground hover:bg-muted hover:text-foreground"
        )}
      >
        <Icon className="h-5 w-5 shrink-0" />
        <span className="whitespace-nowrap">{label}</span>
        <ChevronDown className={cn("ml-auto h-4 w-4 opacity-60 transition-transform", open && "rotate-180")} />
      </button>
      {open && <div className="ml-4 flex flex-col border-l pl-2">{children}</div>}
    </div>
  );
}

// ── Mobile drawer group ───────────────────────────────────────
function MobileGroup({
  label, icon: Icon, active, children,
}: {
  label: string;
  icon: React.ElementType;
  active: boolean;
  children: ReactNode;
}) {
  const [open, setOpen] = useState(active);
  return (
    <div className="flex flex-col">
      <button
        onClick={() => setOpen((o) => !o)}
        className={cn(
          "flex items-center gap-3 rounded-md px-3 py-2.5 text-sm font-medium transition-colors",
          active
            ? "bg-primary/10 text-primary"
            : "text-muted-foreground hover:bg-muted hover:text-foreground"
        )}
      >
        <Icon className="h-4 w-4" />
        {label}
        <ChevronDown className={cn("ml-auto h-4 w-4 opacity-60 transition-transform", open && "rotate-180")} />
      </button>
      {open && <div className="ml-4 flex flex-col border-l pl-2">{children}</div>}
    </div>
  );
}
