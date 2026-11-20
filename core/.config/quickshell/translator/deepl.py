#!/usr/bin/env python3
"""One bounded DeepL request; credentials stay in the process environment."""

import json
import os
import socket
import sys
import urllib.error
import urllib.request

MAX_INPUT = 10_000
MAX_RESPONSE = 512 * 1024


class TranslationError(Exception):
    pass


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        # Never forward the authorization header to a redirected destination.
        return None


def translate(data, key, opener=None):
    if not key:
        raise TranslationError("DEEPL_API is missing from the shell environment")
    text = data.get("text", "")
    source = data.get("source", "")
    target = data.get("target", "")
    if not isinstance(text, str) or not text.strip():
        raise TranslationError("Enter some text to translate")
    if len(text) > MAX_INPUT:
        raise TranslationError("Text exceeds the 10,000-character limit")
    for code in (source, target):
        if not isinstance(code, str) or len(code) > 16 or any(
            not ("A" <= char <= "Z" or char == "-") for char in code
        ):
            raise TranslationError("Invalid language selection")
    if not target:
        raise TranslationError("Select a target language")

    payload = {"text": [text], "target_lang": target, "preserve_formatting": True}
    if source:
        payload["source_lang"] = source
    body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
    if len(body) > 128 * 1024:
        raise TranslationError("Request is too large")

    host = "api-free.deepl.com" if key.endswith(":fx") else "api.deepl.com"
    request = urllib.request.Request(
        f"https://{host}/v2/translate",
        data=body,
        headers={
            "Authorization": f"DeepL-Auth-Key {key}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    opener = opener or urllib.request.build_opener(NoRedirect())
    try:
        with opener.open(request, timeout=15) as response:
            raw = response.read(MAX_RESPONSE + 1)
        if len(raw) > MAX_RESPONSE:
            raise TranslationError("DeepL returned too much data")
        result = json.loads(raw)["translations"][0]
        translated = result["text"]
        detected = result.get("detected_source_language", "")
        if not isinstance(translated, str) or len(translated) > 50_000:
            raise TranslationError("DeepL returned an invalid translation")
        if not isinstance(detected, str) or len(detected) > 16:
            detected = ""
        return {"ok": True, "text": translated, "detected": detected}
    except urllib.error.HTTPError as error:
        status = error.code
        error.close()
        messages = {
            400: "DeepL rejected the text or language selection",
            403: "DeepL rejected the API key or its permissions",
            413: "The translation request is too large",
            429: "DeepL is rate-limiting requests; try again shortly",
            456: "Your DeepL character quota has been reached",
        }
        raise TranslationError(messages.get(status, "DeepL is unavailable; try again later")) from None
    except (urllib.error.URLError, TimeoutError, socket.timeout):
        raise TranslationError("Could not reach DeepL; check your connection and try again") from None
    except (KeyError, IndexError, TypeError, ValueError):
        raise TranslationError("DeepL returned an invalid response") from None


def main():
    try:
        # Newline-framed stdin keeps text out of argv and avoids needing EOF.
        raw = sys.stdin.buffer.readline(128 * 1024 + 1)
        if len(raw) > 128 * 1024:
            raise TranslationError("Request is too large")
        data = json.loads(raw)
        if not isinstance(data, dict):
            raise TranslationError("Invalid translation request")
        result = translate(data, os.environ.get("DEEPL_API", "").strip())
    except TranslationError as error:
        result = {"ok": False, "error": str(error)}
    except (ValueError, OSError):
        # Do not expose exception details: they may contain request data.
        result = {"ok": False, "error": "Could not process the translation request"}
    print(json.dumps(result, ensure_ascii=False))
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
