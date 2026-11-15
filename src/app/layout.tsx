import "./globals.css";

import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Expense App",
  description: "Personal expense tracking",
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html lang="vi" className="h-full antialiased">
      <body className="flex min-h-full flex-col">{children}</body>
    </html>
  );
}
