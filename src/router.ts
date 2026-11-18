
import { jsonResponse } from "./shared/http";
/**
 * نقطة استقبال طلبات النظام.
 * تستقبل طلب HTTP وتوجهه للمسار الداخلي المناسب.
 */
export async function handleRequest(request: Request): Promise<Response> {
  const url = new URL(request.url);

  if (url.pathname === "/api/health" && request.method === "GET") {
    return jsonResponse({
      status: "ok",
      service: "erp-core-api",
      version: "0.1.0",
      message: "ERP API is running",
    });
  }

  return jsonResponse(
    {
      error: "Not Found",
      path: url.pathname,
    },
    404,
  );
}
