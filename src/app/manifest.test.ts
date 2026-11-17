import fs from "node:fs";
import path from "node:path";

import { describe, expect, it } from "vitest";

import manifest from "./manifest";

const PNG_SIGNATURE = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);

function readPngMetadata(relativePublicPath: string): {
  width: number;
  height: number;
  colorType: number;
} {
  const filePath = path.resolve(process.cwd(), "public", relativePublicPath.replace(/^\//, ""));
  const buffer = fs.readFileSync(filePath);
  expect(buffer.subarray(0, 8)).toEqual(PNG_SIGNATURE);

  return {
    width: buffer.readUInt32BE(16),
    height: buffer.readUInt32BE(20),
    colorType: buffer[25]!,
  };
}

describe("PWA manifest and icons", () => {
  it("returns standalone Vietnamese manifest metadata", () => {
    const data = manifest();

    expect(data.name).toBe("Quản lý chi tiêu");
    expect(data.short_name).toBe("Chi tiêu");
    expect(data.start_url).toBe("/");
    expect(data.scope).toBe("/");
    expect(data.display).toBe("standalone");
    expect(data.lang).toBe("vi");
    expect(data.icons?.length).toBeGreaterThanOrEqual(3);
  });

  it("references existing PNG icons matching declared dimensions", () => {
    const data = manifest();

    for (const icon of data.icons ?? []) {
      const [expectedW, expectedH] = String(icon.sizes).split("x").map(Number);
      const png = readPngMetadata(icon.src);

      expect(png.width).toBe(expectedW);
      expect(png.height).toBe(expectedH);
    }
  });

  it("provides an opaque 180x180 apple-touch-icon and source svg", () => {
    const appleIcon = readPngMetadata("/icons/apple-touch-icon.png");
    expect(appleIcon.width).toBe(180);
    expect(appleIcon.height).toBe(180);
    // Color type 2 (RGB) guarantees no alpha channel on iOS Home Screen icons.
    expect(appleIcon.colorType).toBe(2);

    const svgPath = path.resolve(process.cwd(), "public/icons/icon.svg");
    expect(fs.existsSync(svgPath)).toBe(true);
  });
});
