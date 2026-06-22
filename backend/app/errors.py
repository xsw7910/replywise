from dataclasses import dataclass

from fastapi import FastAPI
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse


@dataclass
class ApiException(Exception):
    code: str
    message: str
    status_code: int
    field: str | None = None


def _body(code: str, message: str, field: str | None = None) -> dict:
    error: dict[str, str] = {"code": code, "message": message}
    if field is not None:
        error["field"] = field
    return {"error": error}


def install_error_handlers(app: FastAPI) -> None:
    @app.exception_handler(ApiException)
    async def handle_api_exception(_, error: ApiException) -> JSONResponse:
        return JSONResponse(
            status_code=error.status_code,
            content=_body(error.code, error.message, error.field),
        )

    @app.exception_handler(RequestValidationError)
    async def handle_validation_error(_, error: RequestValidationError) -> JSONResponse:
        first = error.errors()[0] if error.errors() else {}
        location = first.get("loc", ())
        field = str(location[-1]) if location else None
        return JSONResponse(
            status_code=400,
            content=_body("VALIDATION_ERROR", "Invalid request data", field),
        )

