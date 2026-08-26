import { useEffect, useState } from "react";
import { Search } from "lucide-react";
import { useAuditLogs } from "@/hooks/useAuditLogs";
import { Layout } from "@/components/layout";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";

const ACTION_COLORS: Record<string, string> = {
  "tenant.create": "bg-green-500",
  "tenant.delete": "bg-red-500",
  "tenant.deactivate": "bg-red-500",
  "tenant.suspend": "bg-yellow-500",
  "tenant.activate": "bg-green-500",
  "settings.update": "bg-blue-500",
  "feature.toggle": "bg-blue-500",
  "invite.create": "bg-indigo-500",
  "invite.accept": "bg-green-500",
  "invite.revoke": "bg-gray-500",
};

function actionBadge(action: string) {
  return <Badge className={ACTION_COLORS[action] ?? "bg-gray-500"}>{action}</Badge>;
}

/** Audit Logs page — issue #219 2.3. Query the tenant audit trail. */
export default function AuditLogsPage() {
  const { result, loading, query } = useAuditLogs();
  const [search, setSearch] = useState("");
  const [action, setAction] = useState("");

  useEffect(() => {
    void query({ perPage: 25 }).catch(() => undefined);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const runFilter = (page = 1) => {
    void query({ perPage: 25, page, search: search || undefined, action: action || undefined }).catch(() => undefined);
  };

  const rows = result?.rows ?? [];

  return (
    <Layout>
      <div className="space-y-4 p-4 sm:space-y-6 sm:p-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold tracking-tight sm:text-3xl">Audit Logs</h1>
            <p className="text-muted-foreground">
              A record of sensitive tenant, settings, and invitation operations.
            </p>
          </div>
        </div>

        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-lg">Filters</CardTitle>
          </CardHeader>
          <CardContent className="grid gap-3 sm:flex sm:flex-wrap sm:items-end sm:gap-3">
            <div className="space-y-1.5">
              <Label>Search</Label>
              <Input
                placeholder="action or description…"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                onKeyDown={(e) => e.key === "Enter" && runFilter()}
                className="w-full sm:w-64"
              />
            </div>
            <div className="space-y-1.5">
              <Label>Action</Label>
              <Input
                placeholder="e.g. tenant.create"
                value={action}
                onChange={(e) => setAction(e.target.value)}
                onKeyDown={(e) => e.key === "Enter" && runFilter()}
                className="w-full sm:w-56"
              />
            </div>
            <Button onClick={() => runFilter()} className="w-full justify-center gap-1.5 sm:w-auto">
              <Search className="h-4 w-4" /> Apply
            </Button>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4 sm:p-6">
            {loading ? (
              <div className="space-y-2"><Skeleton className="h-10 w-full" /><Skeleton className="h-10 w-full" /></div>
            ) : rows.length === 0 ? (
              <p className="py-8 text-center text-muted-foreground">No audit entries found.</p>
            ) : (
              <>
                {/* ── Desktop table ── */}
                <div className="hidden overflow-x-auto md:block">
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead>When</TableHead>
                        <TableHead>Action</TableHead>
                        <TableHead>Entity</TableHead>
                        <TableHead>Tenant</TableHead>
                        <TableHead>Description</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {rows.map((r) => (
                        <TableRow key={r.id}>
                          <TableCell className="whitespace-nowrap text-xs text-muted-foreground">
                            {new Date(r.createdAt + (r.createdAt.includes("Z") ? "" : "Z")).toLocaleString()}
                          </TableCell>
                          <TableCell>{actionBadge(r.action)}</TableCell>
                          <TableCell className="text-sm">
                            {r.entityType ?? "—"}
                            {r.entityId ? ` #${r.entityId}` : ""}
                          </TableCell>
                          <TableCell className="text-sm">{r.targetTenantId ?? "platform"}</TableCell>
                          <TableCell className="text-sm text-muted-foreground">{r.description ?? "—"}</TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                </div>

                {/* ── Mobile card list ── */}
                <div className="space-y-3 md:hidden">
                  {rows.map((r) => (
                    <div key={r.id} className="rounded-lg border p-3">
                      <div className="flex items-start justify-between gap-2">
                        <div className="min-w-0">
                          <div className="text-xs text-muted-foreground">
                            {new Date(r.createdAt + (r.createdAt.includes("Z") ? "" : "Z")).toLocaleString()}
                          </div>
                          <div className="mt-1">{actionBadge(r.action)}</div>
                        </div>
                        <span className="shrink-0 rounded bg-muted px-1.5 py-0.5 font-mono text-[11px] text-muted-foreground">
                          T{r.targetTenantId ?? "—"}
                        </span>
                      </div>
                      <dl className="mt-2 space-y-1 text-sm">
                        <div className="flex gap-2">
                          <dt className="w-16 shrink-0 text-muted-foreground">Entity</dt>
                          <dd className="min-w-0 break-words">{r.entityType ?? "—"}{r.entityId ? ` #${r.entityId}` : ""}</dd>
                        </div>
                        <div className="flex gap-2">
                          <dt className="w-16 shrink-0 text-muted-foreground">Details</dt>
                          <dd className="min-w-0 break-words text-muted-foreground">{r.description ?? "—"}</dd>
                        </div>
                      </dl>
                    </div>
                  ))}
                </div>
              </>
            )}

            {result && result.totalPages > 1 && (
              <div className="mt-4 flex flex-col gap-2 sm:flex-row sm:items-center sm:gap-2">
                <Button variant="outline" size="sm" disabled={result.page <= 1} onClick={() => runFilter(result.page - 1)} className="w-full sm:w-auto">
                  Prev
                </Button>
                <span className="text-center text-sm text-muted-foreground sm:flex-1">
                  Page {result.page} of {result.totalPages}
                </span>
                <Button variant="outline" size="sm" disabled={result.page >= result.totalPages} onClick={() => runFilter(result.page + 1)} className="w-full sm:w-auto">
                  Next
                </Button>
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </Layout>
  );
}
