import fs from "node:fs";
import path from "node:path";
import { randomBytes } from "node:crypto";
import multer from "multer";

/**
 * Uploads crate (issue #219 1.2) — tenant asset uploads (logo, favicon).
 *
 * Files are stored on disk under UPLOAD_DIR and served by the backend at
 * /api/uploads (see app.ts). The stored file URL is written back into the
 * branding config (logo_url / favicon_url) so the existing Branding read path
 * (which renders logo_url) works unchanged.
 */

export const UPLOAD_DIR =
  process.env.UPLOAD_DIR ??
  (process.env.NODE_ENV === "production" ? "/app/uploads" : "./uploads");

/** Ensure the upload directory exists (idempotent). */
export function ensureUploadDir(): void {
  fs.mkdirSync(UPLOAD_DIR, { recursive: true });
}

/** Allowed image mime types. */
const IMAGE_MIME: Record<string, string> = {
  "image/png": ".png",
  "image/jpeg": ".jpg",
  "image/jpg": ".jpg",
  "image/webp": ".webp",
  "image/svg+xml": ".svg",
  "image/gif": ".gif",
  "image/x-icon": ".ico",
};

/** Sanitize an original filename to a safe basename (no path/control chars). */
function safeBaseName(name: string): string {
  return path.basename(name).replace(/[^\w.\-]/g, "_");
}

/**
 * Multer disk-storage uploader for a single image file field.
 * Rejects non-image types; limits file size to 2MB.
 */
export function imageUploader(fieldName: string) {
  const storage = multer.diskStorage({
    destination: (_req, _file, cb) => {
      ensureUploadDir();
      cb(null, UPLOAD_DIR);
    },
    filename: (_req, file, cb) => {
      const ext = (IMAGE_MIME[file.mimetype] ?? path.extname(safeBaseName(file.originalname))) || "";
      const base = safeBaseName(file.originalname).replace(/\.[^.]+$/, "") || "asset";
      cb(null, `${base}-${randomBytes(6).toString("hex")}${ext}`);
    },
  });

  return multer({
    storage,
    limits: { fileSize: 2 * 1024 * 1024 }, // 2MB
    fileFilter: (_req, file, cb) => {
      if (IMAGE_MIME[file.mimetype]) cb(null, true);
      else cb(new Error("Only image files are allowed (png/jpg/webp/svg/gif/ico)"));
    },
  }).single(fieldName);
}

/** True if the given error is a multer/busboy file error worth a 4xx. */
export function isUploadError(err: unknown): boolean {
  return (
    (err instanceof Error && (err as Error & { code?: string }).code === "LIMIT_FILE_SIZE") ||
    (err instanceof Error && err.message?.toLowerCase().includes("image"))
  );
}

/** Public URL path for a stored file name. */
export function publicAssetUrl(filename: string): string {
  return `/api/uploads/${filename}`;
}
