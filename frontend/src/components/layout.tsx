import { ReactNode, useState, useEffect } from "react";
import { Link, useLocation } from "wouter";
import {
  FileText, Database, BarChart2, LayoutDashboard, ClipboardList,
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

/**
 * The house mark: a single knit stitch. The face of jersey fabric is nothing
 * but this V, repeated a few hundred thousand times per metre.
 */
function StitchMark({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 40 40" aria-hidden="true" className={cn("h-5 w-5 shrink-0", className)}>
      <path
        d="M7 11 Q 14 14 20 27 Q 26 14 33 11"
        fill="none"
        stroke="currentColor"
        strokeWidth="5"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}

function Wordmark({ collapsed = false }: { collapsed?: boolean }) {
  return (
    <span className="flex items-center gap-2.5">
      <StitchMark className="text-signal" />
      {!collapsed && (
        <span className="flex flex-col leading-none">
          <span className="text-[0.9375rem] font-semibold tracking-[0.12em] text-sidebar-accent-foreground">
            TKT
          </span>
          <span className="mt-1 text-[0.625rem] font-medium uppercase tracking-[0.16em] text-sidebar-foreground/55">
            Textiles
          </span>
        </span>
      )}
    </span>
  );
}

/** Stamped section divider inside the nav. */
function NavSection({ label }: { label: string }) {
  return (
    <div className="px-3 pt-5 pb-2 text-[0.625rem] font-semibold uppercase tracking-[0.16em] text-sidebar-foreground/55">
      {label}
    </div>
  );
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
  const dailyProductionActive = location.startsWith("/daily-production");
  const yarnReceiptsActive = location.startsWith("/yarn-receipts");

  return (
    <div className="min-h-[100dvh] w-full bg-background">
      {/* ── Desktop fixed sidebar — a dark bezel, so the light work area
             reads unmistakably as the work area. ───────────────────────── */}
      <aside
        className={cn(
          "hidden md:flex fixed inset-y-0 left-0 z-30 flex-col border-r border-sidebar-border",
          "bg-sidebar text-sidebar-foreground transition-[width] duration-200 print:hidden",
          collapsed ? "w-16" : "w-64"
        )}
      >
        {/* Sidebar header: wordmark + collapse toggle */}
        <div className={cn(
          "flex h-16 items-center border-b border-sidebar-border",
          collapsed ? "justify-center px-0" : "justify-between px-4"
        )}>
          {!collapsed && (
            <Link href="/dashboard" className="transition-opacity hover:opacity-80">
              <Wordmark />
            </Link>
          )}
          <button
            onClick={() => setCollapsed((c) => !c)}
            className="flex items-center justify-center rounded-md p-2 text-sidebar-foreground/60 transition-colors hover:bg-sidebar-accent hover:text-sidebar-accent-foreground"
            aria-label={collapsed ? "Expand sidebar" : "Collapse sidebar"}
            title={collapsed ? "Expand menu" : "Collapse menu"}
          >
            {collapsed ? <PanelLeftOpen className="h-5 w-5" /> : <PanelLeftClose className="h-5 w-5" />}
          </button>
        </div>

        {/* Sidebar nav */}
        <nav className="flex flex-1 flex-col overflow-y-auto px-2 pb-4">
          {!collapsed && <NavSection label="Overview" />}
          <div className={cn("flex flex-col gap-0.5", collapsed && "pt-2")}>
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
          </div>

          {!collapsed && <NavSection label="Daily Work" />}
          <div className={cn("flex flex-col gap-0.5", collapsed && "pt-1")}>
            <DesktopGroup
              label="Daily Operations"
              icon={ClipboardList}
              primary="/daily-production"
              active={dailyProductionActive || yarnReceiptsActive}
              collapsed={collapsed}
            >
              <SubItem
                href="/daily-production"
                label="Daily Production"
                active={isSubItemActive(location, "/daily-production")}
              />
              <SubItem
                href="/yarn-receipts"
                label="Yarn Receipts"
                active={isSubItemActive(location, "/yarn-receipts")}
              />
            </DesktopGroup>
            <DesktopGroup
              label="Transactions"
              icon={FileText}
              primary={TRANSACTIONS_PRIMARY}
              active={transactionsActive}
              collapsed={collapsed}
            >
              {transactionItems.map((item) => (
                <SubItem
                  key={item.href}
                  href={item.href}
                  label={item.label}
                  active={isSubItemActive(location, item.href)}
                />
              ))}
            </DesktopGroup>
          </div>

          {!collapsed && <NavSection label="Analysis" />}
          <div className={cn("flex flex-col gap-0.5", collapsed && "pt-1")}>
            <DesktopGroup
              label="Reports"
              icon={BarChart2}
              primary={REPORTS_PRIMARY}
              active={reportsActive}
              collapsed={collapsed}
            >
              {reportItems.map((item) => (
                <SubItem
                  key={item.href}
                  href={item.href}
                  label={item.label}
                  active={location.startsWith(item.href)}
                />
              ))}
            </DesktopGroup>
          </div>
        </nav>
      </aside>

      {/* ── Content column (offset by sidebar on desktop) ─────── */}
      <div className={cn(
        "flex min-h-[100dvh] flex-col transition-[margin] duration-200 print:ml-0",
        collapsed ? "md:ml-16" : "md:ml-64"
      )}>
        {/* Top bar — mobile hamburger + wordmark (hidden on desktop) */}
        <header className="sticky top-0 z-20 flex h-14 items-center gap-3 border-b border-sidebar-border bg-sidebar px-4 text-sidebar-foreground md:hidden print:hidden">
          <Sheet open={mobileOpen} onOpenChange={setMobileOpen}>
            <SheetTrigger asChild>
              <button
                className="flex items-center justify-center rounded-md p-2 -ml-1 text-sidebar-foreground/70 transition-colors hover:bg-sidebar-accent hover:text-sidebar-accent-foreground"
                aria-label="Open navigation menu"
              >
                <Menu className="h-5 w-5" />
              </button>
            </SheetTrigger>
            <SheetContent
              side="left"
              closeAriaLabel="Close menu"
              className="w-[280px] max-w-[85vw] border-sidebar-border bg-sidebar p-0 text-sidebar-foreground"
              // Backdrop click-to-dismiss: the Sheet is controlled by mobileOpen,
              // so an outside pointer-down must close it explicitly rather than
              // relying on the small menu toggle (issue #27).
              onPointerDownOutside={() => setMobileOpen(false)}
            >
              <SheetHeader className="border-b border-sidebar-border px-4 py-4 text-left">
                <SheetTitle asChild>
                  <div><Wordmark /></div>
                </SheetTitle>
              </SheetHeader>
              <nav className="flex flex-col px-2 pb-4">
                <NavSection label="Overview" />
                {navItems.map((item) => (
                  <Link key={item.href} href={item.href} onClick={() => setMobileOpen(false)}>
                    <span className={cn(
                      "flex items-center gap-3 rounded-md px-3 py-2.5 text-sm font-medium transition-colors",
                      isItemActive(location, item.href)
                        ? "selvedge bg-sidebar-accent text-sidebar-accent-foreground"
                        : "text-sidebar-foreground/70 hover:bg-sidebar-accent/60 hover:text-sidebar-accent-foreground"
                    )}>
                      <item.icon className="h-4 w-4" />
                      {item.label}
                    </span>
                  </Link>
                ))}

                <NavSection label="Daily Work" />
                <MobileGroup label="Daily Operations" icon={ClipboardList} active={dailyProductionActive || yarnReceiptsActive}>
                  <Link href="/daily-production" onClick={() => setMobileOpen(false)}>
                    <SubLabel label="Daily Production" active={isSubItemActive(location, "/daily-production")} />
                  </Link>
                  <Link href="/yarn-receipts" onClick={() => setMobileOpen(false)}>
                    <SubLabel label="Yarn Receipts" active={isSubItemActive(location, "/yarn-receipts")} />
                  </Link>
                </MobileGroup>
                <MobileGroup label="Transactions" icon={FileText} active={transactionsActive}>
                  {transactionItems.map((item) => (
                    <Link key={item.href} href={item.href} onClick={() => setMobileOpen(false)}>
                      <SubLabel label={item.label} active={isSubItemActive(location, item.href)} />
                    </Link>
                  ))}
                </MobileGroup>

                <NavSection label="Analysis" />
                <MobileGroup label="Reports" icon={BarChart2} active={reportsActive}>
                  {reportItems.map((item) => (
                    <Link key={item.href} href={item.href} onClick={() => setMobileOpen(false)}>
                      <SubLabel label={item.label} active={location.startsWith(item.href)} />
                    </Link>
                  ))}
                </MobileGroup>
              </nav>
            </SheetContent>
          </Sheet>

          <Link href="/dashboard" className="shrink-0 transition-opacity hover:opacity-80">
            <Wordmark />
          </Link>
        </header>

        <main className="flex-1 p-4 md:p-8 w-full max-w-7xl mx-auto print:p-0 print:max-w-none">
          {children}
        </main>
      </div>
    </div>
  );
}

// ── Shared sub-item label ─────────────────────────────────────
function SubLabel({ label, active }: { label: string; active: boolean }) {
  return (
    <span className={cn(
      "block rounded-md py-2 pl-3 pr-2 text-[0.8125rem] transition-colors",
      active
        ? "selvedge font-semibold text-sidebar-accent-foreground"
        : "text-sidebar-foreground/60 hover:text-sidebar-accent-foreground"
    )}>
      {label}
    </span>
  );
}

function SubItem({ href, label, active }: { href: string; label: string; active: boolean }) {
  return (
    <Link href={href}>
      <SubLabel label={label} active={active} />
    </Link>
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
          ? "selvedge bg-sidebar-accent text-sidebar-accent-foreground"
          : "text-sidebar-foreground/70 hover:bg-sidebar-accent/60 hover:text-sidebar-accent-foreground"
      )}>
        <Icon className="h-[1.125rem] w-[1.125rem] shrink-0" />
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
                ? "selvedge bg-sidebar-accent text-sidebar-accent-foreground"
                : "text-sidebar-foreground/70 hover:bg-sidebar-accent/60 hover:text-sidebar-accent-foreground"
            )}>
              <Icon className="h-[1.125rem] w-[1.125rem] shrink-0" />
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
            ? "text-sidebar-accent-foreground"
            : "text-sidebar-foreground/70 hover:bg-sidebar-accent/60 hover:text-sidebar-accent-foreground"
        )}
        aria-expanded={open}
      >
        <Icon className="h-[1.125rem] w-[1.125rem] shrink-0" />
        <span className="whitespace-nowrap">{label}</span>
        <ChevronDown className={cn("ml-auto h-4 w-4 opacity-50 transition-transform", open && "rotate-180")} />
      </button>
      {open && (
        <div className="ml-[1.4375rem] flex flex-col border-l border-sidebar-border pl-1.5">
          {children}
        </div>
      )}
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
            ? "text-sidebar-accent-foreground"
            : "text-sidebar-foreground/70 hover:bg-sidebar-accent/60 hover:text-sidebar-accent-foreground"
        )}
        aria-expanded={open}
      >
        <Icon className="h-4 w-4" />
        {label}
        <ChevronDown className={cn("ml-auto h-4 w-4 opacity-50 transition-transform", open && "rotate-180")} />
      </button>
      {open && (
        <div className="ml-[1.4375rem] flex flex-col border-l border-sidebar-border pl-1.5">
          {children}
        </div>
      )}
    </div>
  );
}
