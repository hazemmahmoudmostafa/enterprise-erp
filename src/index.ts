
export default {
  async fetch(request: Request): Promise<Response> {
    const url = new URL(request.url);

    if (
      url.pathname === "/api/health" &&
      request.method === "GET"
    ) {
      return Response.json({
        status: "ok",
        service: "erp-core-api",
        version: "0.1.0"
      });
    }

    return Response.json(
      {
        error: "Not Found",
        path: url.pathname
      },
      { status: 404 }
    );
  }
};
