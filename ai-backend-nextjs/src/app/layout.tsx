import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Local AI Chat API",
  description: "Minimal streaming chat backend"
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="zh-CN"><body>{children}</body></html>;
}
