import { ReactNode } from "react";
import { Link } from "wouter";
import { Factory, Menu } from "lucide-react";

export function Layout({ children }: { children: ReactNode }) {
  return (
    <div className="min-h-[100dvh] flex w-full flex-col bg-background">
      <header className="sticky top-0 z-10 flex h-14 items-center gap-4 border-b bg-card px-6 shadow-sm">
        <Link href="/" className="flex items-center gap-2 font-semibold text-primary transition-colors hover:text-primary/80">
          <Factory className="h-5 w-5" />
          <span>FactoryOps ERP</span>
        </Link>
      </header>
      <main className="flex-1 p-4 md:p-6 w-full max-w-7xl mx-auto">
        {children}
      </main>
    </div>
  );
}
