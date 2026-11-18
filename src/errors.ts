
export type ErrorCode =
  | "VALIDATION_ERROR"
  | "UNAUTHORIZED"
  | "FORBIDDEN"
  | "NOT_FOUND"
  | "CONFLICT"
  | "INTERNAL_SERVER_ERROR";

export class AppError extends Error {
  public readonly code: ErrorCode;
  public readonly statusCode: number;
  public readonly details?: unknown;

  constructor(
    message: string,
    code: ErrorCode,
    statusCode: number,
    details?: unknown
  ) {
    super(message);

    this.name = "AppError";
    this.code = code;
    this.statusCode = statusCode;
    this.details = details;

    Object.setPrototypeOf(this, AppError.prototype);
  }
}

export function validationError(
  message: string,
  details?: unknown
): AppError {
  return new AppError(
    message,
    "VALIDATION_ERROR",
    400,
    details
  );
}

export function unauthorizedError(
  message: string = "Authentication required"
): AppError {
  return new AppError(
    message,
    "UNAUTHORIZED",
    401
  );
}

export function forbiddenError(
  message: string = "Permission denied"
): AppError {
  return new AppError(
    message,
    "FORBIDDEN",
    403
  );
}

export function notFoundError(
  message: string = "Resource not found"
): AppError {
  return new AppError(
    message,
    "NOT_FOUND",
    404
  );
}

export function conflictError(
  message: string,
  details?: unknown
): AppError {
  return new AppError(
    message,
    "CONFLICT",
    409,
    details
  );
}

export function internalServerError(
  message: string = "An unexpected error occurred"
): AppError {
  return new AppError(
    message,
    "INTERNAL_SERVER_ERROR",
    500
  );
}
