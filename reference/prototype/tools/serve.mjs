/* سيرفر محلي بسيط لخدمة التطبيق على http://127.0.0.1:5180
   الاستخدام:  node tools/serve.mjs [--no-open] [--port=5180]
*/
import http from "node:http";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { spawn } from "node:child_process";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const args = process.argv.slice(2);
const openBrowser = !args.includes("--no-open");
const portArg = args.find((a) => a.startsWith("--port="));
let port = portArg ? Number(portArg.split("=")[1]) : 5180;

const MIME = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".svg": "image/svg+xml",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".webp": "image/webp",
  ".ico": "image/x-icon",
  ".woff2": "font/woff2",
  ".txt": "text/plain; charset=utf-8",
  ".md": "text/markdown; charset=utf-8"
};

const server = http.createServer(async (req, res) => {
  try {
    const url = new URL(req.url || "/", "http://localhost");
    let pathname = decodeURIComponent(url.pathname);
    if (pathname === "/") pathname = "/index.html";

    const filePath = path.join(root, pathname);
    if (!filePath.startsWith(root + path.sep) && filePath !== root) {
      res.writeHead(403, { "Content-Type": "text/plain; charset=utf-8" });
      res.end("403");
      return;
    }

    const data = await readFile(filePath);
    res.writeHead(200, {
      "Content-Type": MIME[path.extname(filePath).toLowerCase()] || "application/octet-stream",
      "Cache-Control": "no-cache"
    });
    res.end(data);
  } catch {
    res.writeHead(404, { "Content-Type": "text/plain; charset=utf-8" });
    res.end("404 — not found");
  }
});

server.on("error", () => {});

function start(p) {
  port = p;
  server.once("error", (err) => {
    if (err.code === "EADDRINUSE" && p < 5200) {
      start(p + 1);
      return;
    }
    console.error("تعذّر تشغيل السيرفر:", err.message);
    process.exit(1);
  });
  server.listen(p, "127.0.0.1", () => {
    const url = `http://127.0.0.1:${port}/`;
    console.log("");
    console.log("  خُطوة — تعلّم الإنجليزية بالعربية");
    console.log("  ---------------------------------");
    console.log("  افتح المتصفح على:  " + url);
    console.log("  لإيقاف السيرفر:    Ctrl + C");
    console.log("");
    launch(url);
  });
}

function launch(url) {
  if (!openBrowser) return;
  try {
    if (process.platform === "win32") {
      spawn("cmd", ["/c", "start", "", url], { stdio: "ignore", detached: true, windowsHide: true }).unref();
    } else if (process.platform === "darwin") {
      spawn("open", [url], { stdio: "ignore", detached: true }).unref();
    } else {
      spawn("xdg-open", [url], { stdio: "ignore", detached: true }).unref();
    }
  } catch {
    /* لم نتمكن من فتح المتصفح تلقائيًا — الرابط مطبوع أعلاه */
  }
}

start(port);
