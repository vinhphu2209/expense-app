import type { ReactElement, ReactNode } from "react";

import { cn } from "@/lib/utils";

export type SafeAreaShellProps = {
  children: ReactNode;
  className?: string;
};

/**
 * Full-viewport mobile container that respects iPhone safe areas and `dvh` height.
 */
export function SafeAreaShell({ children, className }: SafeAreaShellProps): ReactElement {
  return (
    <div
      className={cn(
        "flex min-h-dvh w-full flex-col overflow-x-hidden pt-safe pr-safe pb-safe pl-safe",
        className,
      )}
    >
      {children}
    </div>
  );
}
