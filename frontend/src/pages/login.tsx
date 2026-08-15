import { useState, type FormEvent } from "react";
import { useLocation } from "wouter";
import { LogIn } from "lucide-react";
import { useAuth } from "@/context/auth-context";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent } from "@/components/ui/card";

/**
 * Login page (issue #135). Authenticates with username + password, stores the
 * returned bearer token, and redirects to the originally-requested route (or
 * /dashboard). Public — rendered outside the authenticated route guard.
 */
export default function LoginPage() {
  const { login } = useAuth();
  const [, setLocation] = useLocation();
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    if (!username.trim() || !password) {
      setError("Enter your username and password");
      return;
    }
    setError(null);
    setSubmitting(true);
    try {
      await login(username.trim(), password);
      // Return to where the user was headed (stored in sessionStorage by the
      // route guard), defaulting to the dashboard.
      const redirect = sessionStorage.getItem("tkt_redirect") || "/dashboard";
      sessionStorage.removeItem("tkt_redirect");
      setLocation(redirect);
    } catch (err) {
      setError(
        (err as { message?: string })?.message?.includes("status")
          ? "Invalid username or password"
          : "Could not sign in. Please try again.",
      );
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="flex min-h-[80vh] items-center justify-center px-4">
      <Card className="w-full max-w-sm">
        <CardContent className="space-y-5 pt-6">
          <div className="space-y-1 text-center">
            {/* Brand logo (light-tuned lockup — suited to the light card surface). */}
            <img
              src="/logo.png"
              alt="TKT Textiles"
              className="mx-auto mb-1 h-14 w-auto object-contain"
            />
            <p className="text-sm text-muted-foreground">Enter your credentials to continue</p>
          </div>

          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="space-y-1.5">
              <Label htmlFor="username">Username</Label>
              <Input
                id="username"
                autoComplete="username"
                placeholder="admin"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                disabled={submitting}
              />
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="password">Password</Label>
              <Input
                id="password"
                type="password"
                autoComplete="current-password"
                placeholder="••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                disabled={submitting}
              />
            </div>

            {error && (
              <p className="rounded-md border border-destructive/30 bg-destructive/5 px-3 py-2 text-sm text-destructive">
                {error}
              </p>
            )}

            <Button type="submit" className="w-full gap-2" disabled={submitting}>
              <LogIn className="h-4 w-4" />
              {submitting ? "Signing in…" : "Sign in"}
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
