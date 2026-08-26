import { ReactNode, useState, useEffect } from "react";
import { Link, useLocation } from "wouter";
import {
  FileText, Database, BarChart2, LayoutDashboard, ClipboardList, Wallet,
  ChevronDown, PanelLeftClose, PanelLeftOpen, Search, Settings,
  Factory, PackageCheck, Truck, HardHat, Wrench, Receipt, CalendarCheck,
} from "lucide-react";
import { cn } from "@/lib/utils";
import { useAuth } from "@/context/auth-context";
import { TopBar } from "@/components/top-bar";
import { Wordmark } from "@/components/wordmark";
import { BrandedWordmark, BrandedOrgLabel } from "@/components/branded-wordmark";
import { useSeedAllLookups } from "@/hooks/use-all-lookups";
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
} from "@/components/ui/sheet";
import { Input } from "@/components/ui/input";
import {
  Tooltip,
  TooltipContent,
  TooltipTrigger,
} from "@/components/ui/tooltip";

const navItems = [
  { href: "/dashboard",    label: "Dashboard",    icon: LayoutDashboard, module: "dashboard" },
  { href: "/masters",      label: "Master Data",  icon: Database,        module: "masters" },
];

// Bottom navigation (mobile) — the four entry points a floor operator reaches
// for most, surfaced as a thumb-friendly tab bar instead of burying them in
// the drawer. Mirrors the "Daily Work" group in the desktop sidebar.
const bottomNavItems = [
  { href: "/dashboard",        label: "Dashboard",        icon: LayoutDashboard, module: "dashboard" },
  { href: "/attendance",       label: "Attendance",       icon: CalendarCheck,   module: "dailyProduction" },
  { href: "/daily-production", label: "Daily Production", icon: Factory,        module: "dailyProduction" },
  { href: "/yarn-receipts",    label: "Yarn Receipt",     icon: PackageCheck,   module: "yarnReceipts" },
  { href: "/daily-deliveries", label: "Delivery",         icon: Truck,          module: "dailyDeliveries" },
];

const transactionItems = [
  { href: "/transactions",           label: "Yarn-Fabric Transactions", module: "transactions" },
];

const payrollItems = [
  { href: "/transactions/advances",             label: "Advances",             module: "payroll" },
  { href: "/transactions/monthly-salary-entry", label: "Payroll Maintenance",  module: "payroll" },
];

const reportItems = [
  { href: "/reports/yarn-balance",   label: "Yarn Balance Report",         module: "reports" },
  { href: "/reports/yarn-to-fabric", label: "Yarn to Fabric Movement Report", module: "reports" },
];

const invoicingItems = [
  { href: "/invoicing",    label: "Invoicing",    icon: Receipt,     module: "invoicing" },
];

// Mobile drawer: the groups and their items, so the drawer can render from
// config and auto-open the group holding the active route. Sub-item icons are
// chosen to make the long list scannable. Each item declares the RBAC module
// it needs so the drawer hides what the signed-in role can't open.
const mobileGroups = [
  {
    key: "daily",
    label: "Daily Work",
    icon: ClipboardList,
    activeFn: (loc: string) => loc.startsWith("/daily-production") || loc.startsWith("/yarn-receipts") || loc.startsWith("/daily-deliveries") || loc.startsWith("/attendance"),
    items: [
      { href: "/attendance",       label: "Attendance",         icon: CalendarCheck, module: "dailyProduction" },
      { href: "/daily-production", label: "Daily Production", icon: Factory,      module: "dailyProduction" },
      { href: "/yarn-receipts",    label: "Daily Yarn Receipt", icon: PackageCheck, module: "yarnReceipts" },
      { href: "/daily-deliveries", label: "Daily Delivery",    icon: Truck,        module: "dailyDeliveries" },
    ],
  },
  {
    key: "transactions",
    label: "Transactions & Payroll",
    icon: FileText,
    activeFn: (loc: string) => loc.startsWith("/transactions"),
    items: [
      { href: "/transactions",           label: "Yarn-Fabric Transactions", icon: FileText,  module: "transactions" },
      { href: "/transactions/advances",  label: "Advances",                icon: Wallet,    module: "payroll" },
      { href: "/transactions/monthly-salary-entry", label: "Payroll Maintenance", icon: Settings, module: "payroll" },
    ],
  },
  {
    key: "maintenance",
    label: "Maintenance",
    icon: Wrench,
    activeFn: (loc: string) => loc.startsWith("/maintenance"),
    items: [
      { href: "/maintenance/machine", label: "Machine Maintenance", icon: Factory, module: "maintenance" },
      { href: "/maintenance/factory", label: "Factory Maintenance",  icon: HardHat, module: "maintenance" },
    ],
  },
  {
    key: "reports",
    label: "Analysis",
    icon: BarChart2,
    activeFn: (loc: string) => loc.startsWith("/reports"),
    items: [
      { href: "/reports/yarn-balance",   label: "Yarn Balance Report",      icon: BarChart2, module: "reports" },
      { href: "/reports/yarn-to-fabric", label: "Yarn to Fabric Movement",   icon: Database,  module: "reports" },
    ],
  },
  {
    key: "invoicing",
    label: "Invoicing",
    icon: Receipt,
    activeFn: (loc: string) => loc.startsWith("/invoicing"),
    items: invoicingItems,
  },
];

// Mobile-only "Administration" group — the Users & Roles admin lives here so
// it shows in the phone drawer (the desktop sidebar places it as a flat item).
const adminItems = [
  { href: "/settings", label: "Users & Roles", icon: Settings, module: "users" },
];

// Primary route each collapsed group icon navigates to.
const TRANSACTIONS_PRIMARY = "/transactions";
const PAYROLL_PRIMARY = "/transactions/monthly-salary-entry";
const REPORTS_PRIMARY = "/reports/yarn-balance";
const MAINTENANCE_PRIMARY = "/maintenance/machine";
const INVOICING_PRIMARY = "/invoicing";

const LS_SIDEBAR_COLLAPSED = "sidebar-collapsed";

function isItemActive(location: string, href: string) {
  return location === href || location.startsWith(href + "/");
}
function isSubItemActive(location: string, href: string) {
  return href === "/transactions" ? location === href : location.startsWith(href);
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
  const [location, setLocation] = useLocation();
  const { can } = useAuth();
  // Load all master/lookup lists once and seed the per-list caches, so the
  // individual useList*Master hooks resolve from cache instead of N requests.
  // The Master Data page is the exception: it lazy-loads each tab on activation,
  // so we opt it out of the one-shot load-everything prefetch.
  useSeedAllLookups(!location.startsWith("/masters"));
  const [mobileOpen, setMobileOpen] = useState(false);
  const [collapsed, setCollapsed] = useState<boolean>(() => {
    try { return localStorage.getItem(LS_SIDEBAR_COLLAPSED) === "true"; } catch { return false; }
  });
  // Mobile drawer: search query + which accordion groups are expanded.
  const [mobileQuery, setMobileQuery] = useState("");
  const [mobileOpenGroups, setMobileOpenGroups] = useState<Set<string>>(
    () => new Set(mobileGroups.filter((g) => g.activeFn(location)).map((g) => g.key))
  );

  useEffect(() => {
    try { localStorage.setItem(LS_SIDEBAR_COLLAPSED, String(collapsed)); } catch {}
  }, [collapsed]);

  const payrollActive = location.startsWith("/transactions/monthly-salary-entry") || location.startsWith("/transactions/advances");
  const transactionsActive = location.startsWith("/transactions") && !payrollActive;
  const reportsActive = location.startsWith("/reports");
  const dailyProductionActive = location.startsWith("/daily-production");
  const attendanceActive = location.startsWith("/attendance");
  const yarnReceiptsActive = location.startsWith("/yarn-receipts");
  const dailyDeliveriesActive = location.startsWith("/daily-deliveries");
  const maintenanceActive = location.startsWith("/maintenance");
  const invoicingActive = location.startsWith("/invoicing");

  return (
    <div className="min-h-[100dvh] w-full bg-background">
      {/* Development-environment banner — a fixed red strip across the very
          top so nobody mistakes the dev stack for production. Vite strips
          this block out of production builds (import.meta.env.DEV is false
          there), so it can never ship. */}
      {import.meta.env.DEV && (
        <div className="fixed inset-x-0 top-0 z-[60] flex h-7 items-center justify-center gap-2 bg-red-600 px-4 text-center text-xs font-semibold uppercase tracking-[0.14em] text-white print:hidden">
          <span className="inline-block h-2 w-2 animate-pulse rounded-full bg-white/90" />
          Development environment
        </div>
      )}
      {/* ── Desktop fixed sidebar — a dark bezel, so the light work area
             reads unmistakably as the work area. ───────────────────────── */}
      <aside
        className={cn(
          "hidden md:flex fixed inset-y-0 left-0 z-30 flex-col border-r border-sidebar-border",
          "bg-sidebar text-sidebar-foreground transition-[width] duration-200 print:hidden",
          collapsed ? "w-16" : "w-64",
          import.meta.env.DEV && "top-7"
        )}
      >
        {/* Sidebar header: wordmark + collapse toggle */}
        <div className={cn(
          "flex h-14 items-center border-b border-sidebar-border shrink-0",
          collapsed ? "justify-center px-0" : "justify-between px-4"
        )}>
          {!collapsed && (
            <Link href="/dashboard" className="transition-opacity hover:opacity-80">
              <BrandedWordmark />
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
            {navItems.filter((item) => can(item.module)).map((item) => (
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

          {(can("dailyProduction") || can("yarnReceipts") || can("dailyDeliveries") || can("transactions") || can("payroll")) && !collapsed && <NavSection label="Daily Work" />}
          <div className={cn("flex flex-col gap-0.5", collapsed && "pt-1")}>
            {(can("dailyProduction") || can("yarnReceipts") || can("dailyDeliveries")) && (
            <DesktopGroup
              label="Daily Operations"
              icon={ClipboardList}
              primary="/daily-production"
              active={dailyProductionActive || attendanceActive || yarnReceiptsActive || dailyDeliveriesActive}
              collapsed={collapsed}
            >
              {can("dailyProduction") && (
              <SubItem
                href="/attendance"
                label="Attendance"
                active={isSubItemActive(location, "/attendance")}
              />
              )}
              {can("dailyProduction") && (
              <SubItem
                href="/daily-production"
                label="Daily Production"
                active={isSubItemActive(location, "/daily-production")}
              />
              )}
              {can("yarnReceipts") && (
              <SubItem
                href="/yarn-receipts"
                label="Daily Yarn Receipt"
                active={isSubItemActive(location, "/yarn-receipts")}
              />
              )}
              {can("dailyDeliveries") && (
              <SubItem
                href="/daily-deliveries"
                label="Daily Delivery"
                active={isSubItemActive(location, "/daily-deliveries")}
              />
              )}
            </DesktopGroup>
            )}
            {can("transactions") && (
            <DesktopGroup
              label="Transactions"
              icon={FileText}
              primary={TRANSACTIONS_PRIMARY}
              active={transactionsActive}
              collapsed={collapsed}
            >
              {transactionItems.filter((item) => can(item.module)).map((item) => (
                <SubItem
                  key={item.href}
                  href={item.href}
                  label={item.label}
                  active={isSubItemActive(location, item.href)}
                />
              ))}
            </DesktopGroup>
            )}
            {can("payroll") && (
            <DesktopGroup
              label="Payroll"
              icon={Wallet}
              primary={PAYROLL_PRIMARY}
              active={payrollActive}
              collapsed={collapsed}
            >
              {payrollItems.filter((item) => can(item.module)).map((item) => (
                <SubItem
                  key={item.href}
                  href={item.href}
                  label={item.label}
                  active={isSubItemActive(location, item.href)}
                />
              ))}
            </DesktopGroup>
            )}
          </div>

          {can("maintenance") && !collapsed && <NavSection label="Maintenance" />}
          <div className={cn("flex flex-col gap-0.5", collapsed && "pt-1")}>
            {can("maintenance") && (
            <DesktopGroup
              label="Maintenance"
              icon={Wrench}
              primary={MAINTENANCE_PRIMARY}
              active={maintenanceActive}
              collapsed={collapsed}
            >
              <SubItem
                href="/maintenance/machine"
                label="Machine Maintenance"
                active={isSubItemActive(location, "/maintenance/machine")}
              />
              <SubItem
                href="/maintenance/factory"
                label="Factory Maintenance"
                active={isSubItemActive(location, "/maintenance/factory")}
              />
            </DesktopGroup>
            )}
          </div>

          {can("reports") && !collapsed && <NavSection label="Analysis" />}
          <div className={cn("flex flex-col gap-0.5", collapsed && "pt-1")}>
            {can("reports") && (
            <DesktopGroup
              label="Reports"
              icon={BarChart2}
              primary={REPORTS_PRIMARY}
              active={reportsActive}
              collapsed={collapsed}
            >
              {reportItems.filter((item) => can(item.module)).map((item) => (
                <SubItem
                  key={item.href}
                  href={item.href}
                  label={item.label}
                  active={location.startsWith(item.href)}
                />
              ))}
            </DesktopGroup>
            )}
          </div>

          {!collapsed && <NavSection label="Invoicing" />}
          <div className={cn("flex flex-col gap-0.5", collapsed && "pt-1")}>
            {can("invoicing") && (
              <DesktopGroup
                label="Invoicing"
                icon={Receipt}
                primary={INVOICING_PRIMARY}
                active={invoicingActive}
                collapsed={collapsed}
              >
                {invoicingItems.map((item) => (
                  <SubItem
                    key={item.href}
                    href={item.href}
                    label={item.label}
                    active={isSubItemActive(location, item.href)}
                  />
                ))}
              </DesktopGroup>
            )}
            {can("users") && (
              <DesktopItem
                href="/settings"
                label="Users &amp; Roles"
                icon={Settings}
                active={isItemActive(location, "/settings")}
                collapsed={collapsed}
              />
            )}
          </div>
        </nav>
      </aside>

      {/* ── Content column (offset by sidebar on desktop) ─────── */}
      <div className={cn(
        "flex min-h-[100dvh] flex-col transition-[margin] duration-200 print:ml-0",
        collapsed ? "md:ml-16" : "md:ml-64",
        // Push the whole content column below the dev banner (same height as
        // the sidebar/header offsets above).
        import.meta.env.DEV && "pt-7"
      )}>
        {/* Global top bar — account dropdown (top-left): user/role, Users &
            Roles, Change Password, Sign out. Hamburger opens the nav drawer on
            mobile. */}
        <TopBar onMenuClick={() => setMobileOpen(true)} />

        {/* Mobile nav drawer (sheet) — controlled by the TopBar hamburger. */}
        <Sheet open={mobileOpen} onOpenChange={setMobileOpen}>
          <SheetContent
            side="left"
            closeAriaLabel="Close menu"
            className={cn(
              "flex w-[340px] max-w-[90vw] flex-col border-sidebar-border bg-sidebar p-0 text-sidebar-foreground z-50",
              import.meta.env.DEV && "top-7"
            )}
            // Backdrop click-to-dismiss: the Sheet is controlled by mobileOpen,
            // so an outside pointer-down must close it explicitly rather than
            // relying on the small menu toggle (issue #27).
            onPointerDownOutside={() => setMobileOpen(false)}
          >
            <SheetHeader className="flex items-center justify-between gap-3 border-b border-sidebar-border px-4 py-4">
              <SheetTitle asChild>
                <div><Wordmark /></div>
              </SheetTitle>
            </SheetHeader>

            {/* Search — filters the whole drawer so a long menu stays
                discoverable without scrolling. */}
            <div className="px-3 pt-3">
              <div className="relative">
                <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-sidebar-foreground/40" />
                <Input
                  type="search"
                  placeholder="Find a menu…"
                  value={mobileQuery}
                  onChange={(e) => setMobileQuery(e.target.value)}
                  className="h-11 border-sidebar-border bg-sidebar-accent/40 pl-9 text-sidebar-foreground placeholder:text-sidebar-foreground/40 focus-visible:ring-signal"
                />
              </div>
            </div>

            <nav className="flex flex-1 flex-col overflow-y-auto px-2 pb-4 pt-2">
              <MobileNavMenu
                location={location}
                query={mobileQuery}
                openGroups={mobileOpenGroups}
                setOpenGroups={setMobileOpenGroups}
                can={can}
                onNavigate={() => { setMobileOpen(false); setMobileQuery(""); }}
              />
            </nav>

            {/* Drawer footer — a quiet sign-off so the menu doesn't end
                abruptly and shows what build this is. */}
            <div className="flex items-center justify-between border-t border-sidebar-border px-4 py-3">
              <BrandedOrgLabel className="text-[0.625rem] font-semibold uppercase tracking-[0.16em] text-sidebar-foreground/40" />
              <span className="text-[0.625rem] text-sidebar-foreground/30">v{import.meta.env.PACKAGE_VERSION ?? "1.0.0"}</span>
            </div>
          </SheetContent>
        </Sheet>

        <main className="flex-1 p-4 pb-20 md:p-8 md:pb-8 w-full max-w-7xl mx-auto print:p-0 print:max-w-none">
          {children}
        </main>

        {/* ── Mobile bottom navigation — a fixed tab bar so the four most-used
               screens are a thumb-tap away (hidden on desktop / print). ── */}
        <BottomNav location={location} can={can} />
      </div>
    </div>
  );
}

// ── Mobile bottom navigation bar ────────────────────────────
function BottomNav({ location, can }: { location: string; can: (moduleId: string) => boolean }) {
  const visible = bottomNavItems.filter((item) => can(item.module));
  return (
    <nav
      className="fixed inset-x-0 bottom-0 z-30 border-t border-sidebar-border bg-sidebar text-sidebar-foreground md:hidden print:hidden"
      aria-label="Main navigation"
    >
      <div
        className="mx-auto grid max-w-7xl"
        style={{
          gridTemplateColumns: `repeat(${visible.length}, 1fr)`,
          paddingBottom: "env(safe-area-inset-bottom)",
        }}
      >
        {visible.map(({ href, label, icon: Icon }) => {
          const active = isItemActive(location, href);
          return (
            <Link key={href} href={href}>
              <span
                className={cn(
                  "selvedge-top flex flex-col items-center gap-1 pt-2 pb-2.5 text-[0.625rem] font-medium transition-colors",
                  active
                    ? "text-sidebar-accent-foreground"
                    : "text-sidebar-foreground/55 hover:text-sidebar-accent-foreground"
                )}
              >
                <Icon
                  className={cn("h-5 w-5", active ? "text-signal" : "opacity-80")}
                  strokeWidth={active ? 2.25 : 2}
                />
                {label}
              </span>
            </Link>
          );
        })}
      </div>
    </nav>
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
  const [open, setOpen] = useState(true);

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

// ── Mobile drawer menu ─────────────────────────────────────────
// Searchable, auto-expanding menu for the phone drawer. Top-level items
// (Overview) sit flat; the rest are accordion groups that open when active
// or when the search query matches something inside them, so the drawer
// stays compact instead of a giant wall of open sections.
function MobileNavMenu({
  location,
  query,
  openGroups,
  setOpenGroups,
  can,
  onNavigate,
}: {
  location: string;
  query: string;
  openGroups: Set<string>;
  setOpenGroups: React.Dispatch<React.SetStateAction<Set<string>>>;
  can: (moduleId: string) => boolean;
  onNavigate: () => void;
}) {
  const q = query.trim().toLowerCase();
  const matches = (label: string) => !q || label.toLowerCase().includes(q);

  // Only groups with at least one permitted item (matching the query) show.
  const visibleGroups = mobileGroups
    .map((g) => ({
      ...g,
      items: g.items.filter((i) => can(i.module) && matches(i.label)),
    }))
    .filter((g) => g.items.length > 0);

  // When typing, force-open any group that matched so results are visible.
  const effOpenGroups = q
    ? new Set(visibleGroups.map((g) => g.key))
    : openGroups;

  const toggleGroup = (key: string) =>
    setOpenGroups((prev) => {
      const next = new Set(prev);
      if (next.has(key)) next.delete(key); else next.add(key);
      return next;
    });

  return (
    <div className="flex flex-col gap-0.5">
      <NavSection label="Overview" />
      {navItems
        .filter((i) => can(i.module) && matches(i.label))
        .map((item) => (
          <Link key={item.href} href={item.href} onClick={onNavigate}>
            <span
              className={cn(
                "flex min-h-11 items-center gap-3 rounded-md px-3 py-2.5 text-sm font-medium transition-colors",
                isItemActive(location, item.href)
                  ? "selvedge bg-sidebar-accent text-sidebar-accent-foreground"
                  : "text-sidebar-foreground/70 hover:bg-sidebar-accent/60 hover:text-sidebar-accent-foreground"
              )}
            >
              <item.icon className="h-4 w-4 shrink-0" />
              {item.label}
            </span>
          </Link>
        ))}

      {visibleGroups.map((group) => {
        const groupActive = group.activeFn(location);
        const open = effOpenGroups.has(group.key);
        const Icon = group.icon;
        return (
          <div key={group.key} className="mt-1 flex flex-col">
            <NavSection label={group.label} />
            <button
              onClick={() => toggleGroup(group.key)}
              className={cn(
                "flex min-h-11 items-center gap-3 rounded-md px-3 py-2.5 text-sm font-medium transition-colors",
                groupActive
                  ? "text-sidebar-accent-foreground"
                  : "text-sidebar-foreground/70 hover:bg-sidebar-accent/60"
              )}
              aria-expanded={open}
            >
              <Icon className="h-4 w-4 shrink-0" />
              <span className="whitespace-nowrap">{group.label}</span>
              <ChevronDown
                className={cn("ml-auto h-4 w-4 opacity-50 transition-transform", open && "rotate-180")}
              />
            </button>
            {open && (
              <div className="ml-[1.4375rem] flex flex-col border-l border-sidebar-border pl-1.5">
                {group.items
                  .filter((i) => matches(i.label))
                  .map((item) => {
                    const active = isItemActive(location, item.href);
                    const ItemIcon = item.icon;
                    return (
                      <Link key={item.href} href={item.href} onClick={onNavigate}>
                        <span
                          className={cn(
                            "flex min-h-11 items-center gap-3 rounded-md pl-2 pr-3 py-2.5 text-[0.8125rem] transition-colors",
                            active
                              ? "selvedge font-semibold text-sidebar-accent-foreground"
                              : "text-sidebar-foreground/60 hover:text-sidebar-accent-foreground"
                          )}
                        >
                          <ItemIcon
                            className={cn("h-4 w-4 shrink-0", active ? "text-signal" : "opacity-60")}
                          />
                          {item.label}
                        </span>
                      </Link>
                    );
                  })}
              </div>
            )}
          </div>
        );
      })}

      {/* Administration — phone-only entry to Users & Roles (admin role). */}
      {can("users") && (
        <div className="mt-1 flex flex-col">
          <NavSection label="Administration" />
          {adminItems
            .filter((i) => can(i.module) && matches(i.label))
            .map((item) => {
              const active = isItemActive(location, item.href);
              const ItemIcon = item.icon;
              return (
                <Link key={item.href} href={item.href} onClick={onNavigate}>
                  <span
                    className={cn(
                      "flex min-h-11 items-center gap-3 rounded-md px-3 py-2.5 text-sm font-medium transition-colors",
                      active
                        ? "selvedge bg-sidebar-accent text-sidebar-accent-foreground"
                        : "text-sidebar-foreground/70 hover:bg-sidebar-accent/60 hover:text-sidebar-accent-foreground"
                    )}
                  >
                    <ItemIcon className="h-4 w-4 shrink-0" />
                    {item.label}
                  </span>
                </Link>
              );
            })}
        </div>
      )}
    </div>
  );
}
