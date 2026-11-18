export function jsonResponse(
  data: unknown,
  status: number = 200
): Response {
  return Response.json(data, {
    status: status
  });
}
