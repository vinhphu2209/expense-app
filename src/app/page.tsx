import type { ReactElement } from "react";

import { SafeAreaShell } from "@/components/pwa/safe-area-shell";

export default function HomePage(): ReactElement {
  return (
    <SafeAreaShell>
      <header className="border-b px-4 py-3">
        <p className="text-sm font-medium text-muted-foreground">Quản lý chi tiêu</p>
        <h1 className="text-lg font-semibold">Chi tiêu — đang xây dựng</h1>
      </header>
      <main className="flex flex-1 flex-col items-center justify-center gap-3 px-4 py-6 text-center">
        <p className="text-base font-medium">Ứng dụng đã sẵn sàng cài đặt trên iPhone</p>
        <p className="max-w-xs text-sm text-muted-foreground">
          Mở bằng Safari → Chia sẻ → Thêm vào Màn hình chính để sử dụng ở chế độ toàn màn hình.
        </p>
      </main>
    </SafeAreaShell>
  );
}
