#!/usr/bin/env python3
"""Minimal local backend for the English learning app.

The server intentionally uses only Python's standard library so v0.3 can run
without package installation. It protects OPENAI_API_KEY from the iOS app and
offers mock responses when the key is not configured.
"""

from __future__ import annotations

import base64
import json
import os
import tempfile
import urllib.error
import urllib.request
import uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any


HOST = os.getenv("HOST", "127.0.0.1")
PORT = int(os.getenv("PORT", "8765"))
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "")
TRANSCRIBE_MODEL = os.getenv("OPENAI_TRANSCRIBE_MODEL", "gpt-4o-transcribe")
FEEDBACK_MODEL = os.getenv("OPENAI_FEEDBACK_MODEL", "gpt-4.1-mini")
MOCK_MODE = os.getenv("MOCK_MODE", "auto").lower()


def should_mock() -> bool:
    return MOCK_MODE == "true" or (MOCK_MODE == "auto" and not OPENAI_API_KEY)


def json_response(handler: BaseHTTPRequestHandler, status: int, payload: dict[str, Any]) -> None:
    body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
    handler.send_response(status)
    handler.send_header("Content-Type", "application/json; charset=utf-8")
    handler.send_header("Content-Length", str(len(body)))
    handler.end_headers()
    handler.wfile.write(body)


def read_json(handler: BaseHTTPRequestHandler) -> dict[str, Any]:
    length = int(handler.headers.get("Content-Length", "0"))
    if length <= 0:
        return {}
    raw = handler.rfile.read(length)
    return json.loads(raw.decode("utf-8"))


def multipart_body(fields: dict[str, str], file_field: str, file_name: str, file_bytes: bytes) -> tuple[bytes, str]:
    boundary = f"----EnglishLearningBoundary{uuid.uuid4().hex}"
    parts: list[bytes] = []

    for name, value in fields.items():
        parts.append(f"--{boundary}\r\n".encode("utf-8"))
        parts.append(f'Content-Disposition: form-data; name="{name}"\r\n\r\n'.encode("utf-8"))
        parts.append(value.encode("utf-8"))
        parts.append(b"\r\n")

    parts.append(f"--{boundary}\r\n".encode("utf-8"))
    parts.append(
        (
            f'Content-Disposition: form-data; name="{file_field}"; filename="{file_name}"\r\n'
            "Content-Type: audio/m4a\r\n\r\n"
        ).encode("utf-8")
    )
    parts.append(file_bytes)
    parts.append(b"\r\n")
    parts.append(f"--{boundary}--\r\n".encode("utf-8"))
    return b"".join(parts), boundary


def openai_request(path: str, payload: bytes, content_type: str) -> dict[str, Any]:
    request = urllib.request.Request(
        f"https://api.openai.com{path}",
        data=payload,
        method="POST",
        headers={
            "Authorization": f"Bearer {OPENAI_API_KEY}",
            "Content-Type": content_type,
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            return json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as error:
        detail = error.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"OpenAI API error {error.code}: {detail}") from error


def transcribe_audio(audio_base64: str, file_name: str) -> dict[str, Any]:
    if should_mock():
        return {
            "text": "I was about to grab some coffee. Do you want anything?",
            "model": "mock-transcribe",
            "mock": True,
        }

    audio_bytes = base64.b64decode(audio_base64)
    body, boundary = multipart_body(
        fields={"model": TRANSCRIBE_MODEL},
        file_field="file",
        file_name=file_name or "recording.m4a",
        file_bytes=audio_bytes,
    )
    result = openai_request("/v1/audio/transcriptions", body, f"multipart/form-data; boundary={boundary}")
    return {
        "text": result.get("text", ""),
        "model": TRANSCRIBE_MODEL,
        "mock": False,
    }


def speaking_feedback(transcript: str, target: str) -> dict[str, Any]:
    if should_mock():
        return {
            "clarity": 82,
            "fluency": 76,
            "completeness": 88,
            "naturalness": 73,
            "summary": "整体能表达清楚，但可以更自然地使用 want me to 和 text you。",
            "suggestions": [
                "保持 I was about to + 动词原形。",
                "把 I can text her 改成 I can text you，更符合对话对象。",
                "复述时补一句 Do you want me to grab one for you? 增加互动感。",
            ],
            "missed_keywords": ["anything", "want me to"],
            "model": "mock-feedback",
            "mock": True,
        }

    prompt = {
        "task": "Score an English speaking practice attempt for a Chinese adult learner.",
        "target_sentence": target,
        "transcript": transcript,
        "return_json_shape": {
            "clarity": "0-100 integer",
            "fluency": "0-100 integer",
            "completeness": "0-100 integer",
            "naturalness": "0-100 integer",
            "summary": "short Chinese summary",
            "suggestions": ["3 concrete Chinese suggestions"],
            "missed_keywords": ["important missing words or chunks"],
        },
    }
    payload = json.dumps(
        {
            "model": FEEDBACK_MODEL,
            "input": [
                {
                    "role": "system",
                    "content": "You are an English speaking coach. Return strict JSON only.",
                },
                {"role": "user", "content": json.dumps(prompt, ensure_ascii=False)},
            ],
            "text": {
                "format": {
                    "type": "json_schema",
                    "name": "speaking_feedback",
                    "schema": {
                        "type": "object",
                        "additionalProperties": False,
                        "properties": {
                            "clarity": {"type": "integer"},
                            "fluency": {"type": "integer"},
                            "completeness": {"type": "integer"},
                            "naturalness": {"type": "integer"},
                            "summary": {"type": "string"},
                            "suggestions": {"type": "array", "items": {"type": "string"}},
                            "missed_keywords": {"type": "array", "items": {"type": "string"}},
                        },
                        "required": [
                            "clarity",
                            "fluency",
                            "completeness",
                            "naturalness",
                            "summary",
                            "suggestions",
                            "missed_keywords",
                        ],
                    },
                    "strict": True,
                }
            },
        },
        ensure_ascii=False,
    ).encode("utf-8")
    result = openai_request("/v1/responses", payload, "application/json")
    text = result.get("output_text", "")
    feedback = json.loads(text)
    feedback["model"] = FEEDBACK_MODEL
    feedback["mock"] = False
    return feedback


class Handler(BaseHTTPRequestHandler):
    server_version = "EnglishLearningBackend/0.3"

    def do_GET(self) -> None:
        if self.path == "/health":
            json_response(self, 200, {"ok": True, "mock": should_mock()})
            return
        json_response(self, 404, {"error": "Not found"})

    def do_POST(self) -> None:
        try:
            if self.path == "/speech/transcribe":
                payload = read_json(self)
                result = transcribe_audio(
                    audio_base64=payload.get("audio_base64", ""),
                    file_name=payload.get("file_name", "recording.m4a"),
                )
                json_response(self, 200, result)
                return

            if self.path == "/speaking/score":
                payload = read_json(self)
                result = speaking_feedback(
                    transcript=payload.get("transcript", ""),
                    target=payload.get("target", ""),
                )
                json_response(self, 200, result)
                return

            json_response(self, 404, {"error": "Not found"})
        except Exception as error:  # noqa: BLE001 - keep local prototype resilient.
            json_response(self, 500, {"error": str(error), "mock": should_mock()})

    def log_message(self, format: str, *args: Any) -> None:
        print(f"{self.address_string()} - {format % args}")


def main() -> None:
    server = ThreadingHTTPServer((HOST, PORT), Handler)
    print(f"Backend listening on http://{HOST}:{PORT} (mock={should_mock()})")
    server.serve_forever()


if __name__ == "__main__":
    main()

