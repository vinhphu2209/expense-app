import type { Metadata, Viewport } from "next";
import { Geist } from "next/font/google";
import type { ReactElement } from "react";

import { cn } from "@/lib/utils";

import "./globals.css";

const geist = Geist({ subsets: ["latin", "vietnamese"], variable: "--font-sans" });

export const metadata: Metadata = {
  title: {
    default: "Chi tiêu",
    template: "%s | Chi tiêu",
  },
  description: "Theo dõi chi tiêu và ngân sách cá nhân",
  applicationName: "Chi tiêu",
  appleWebApp: {
    capable: true,
    title: "Chi tiêu",
    statusBarStyle: "default",
  },
  formatDetection: {
    telephone: false,
  },
  icons: {
    icon: [
      { url: "/icons/icon-192.png", sizes: "192x192", type: "image/png" },
      { url: "/icons/icon-512.png", sizes: "512x512", type: "image/png" },
    ],
    apple: [{ url: "/icons/apple-touch-icon.png", sizes: "180x180", type: "image/png" }],
  },
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  viewportFit: "cover",
  themeColor: [
    { media: "(prefers-color-scheme: light)", color: "#ffffff" },
    { media: "(prefers-color-scheme: dark)", color: "#171717" },
  ],
};

export default function RootLayout({ children }: LayoutProps<"/">): ReactElement {
  return (
    <html lang="vi" className={cn("h-full antialiased", "font-sans", geist.variable)}>
      <body className="flex min-h-dvh flex-col">{children}</body>
    </html>
  );
}
