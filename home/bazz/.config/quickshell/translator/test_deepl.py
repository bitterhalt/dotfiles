"""Offline tests: python -B -m unittest discover -s quickshell/translator."""

import io
import json
import unittest
import urllib.error
from unittest.mock import Mock

import deepl


class TranslationTests(unittest.TestCase):
    def request(self, data=None, response=None, key="test:fx"):
        self.opener = Mock()
        stream = io.BytesIO(json.dumps(response or {
            "translations": [{"text": "Translated", "detected_source_language": "FI"}]
        }).encode())
        self.opener.open.return_value = stream
        return deepl.translate(data or {"text": "Synthetic text", "source": "", "target": "EN-GB"},
                               key, self.opener)

    def test_auto_detection_and_free_endpoint(self):
        result = self.request()
        self.assertEqual(result, {"ok": True, "text": "Translated", "detected": "FI"})
        request = self.opener.open.call_args.args[0]
        self.assertEqual(request.full_url, "https://api-free.deepl.com/v2/translate")
        self.assertNotIn("source_lang", json.loads(request.data))
        self.assertEqual(request.get_header("Authorization"), "DeepL-Auth-Key test:fx")
        self.assertEqual(self.opener.open.call_args.kwargs["timeout"], 15)

    def test_pro_endpoint_unicode_and_explicit_source(self):
        self.request({"text": "ää\n日本語", "source": "FI", "target": "JA"}, key="test-pro")
        request = self.opener.open.call_args.args[0]
        self.assertEqual(request.full_url, "https://api.deepl.com/v2/translate")
        payload = json.loads(request.data)
        self.assertEqual(payload["text"], ["ää\n日本語"])
        self.assertEqual(payload["source_lang"], "FI")

    def test_invalid_requests_never_send(self):
        for data, key in [
            ({"text": "text", "target": "EN"}, ""),
            ({"text": " ", "target": "EN"}, "test:fx"),
            ({"text": "x" * 10001, "target": "EN"}, "test:fx"),
            ({"text": "text", "target": ""}, "test:fx"),
            ({"text": "text", "target": "EN\r\nHeader"}, "test:fx"),
        ]:
            with self.subTest(target=data["target"]):
                opener = Mock()
                with self.assertRaises(deepl.TranslationError):
                    deepl.translate(data, key, opener)
                opener.open.assert_not_called()

    def test_http_errors_do_not_echo_server_text(self):
        for status in (400, 403, 413, 429, 456, 500, 302):
            with self.subTest(status=status):
                opener = Mock()
                opener.open.side_effect = urllib.error.HTTPError(
                    "https://example.invalid", status, "private response", {}, None)
                with self.assertRaises(deepl.TranslationError) as result:
                    deepl.translate({"text": "input", "target": "EN-GB"}, "test:fx", opener)
                self.assertNotIn("private response", str(result.exception))

    def test_network_failure_is_sanitized(self):
        opener = Mock()
        opener.open.side_effect = urllib.error.URLError("private proxy details")
        with self.assertRaises(deepl.TranslationError) as result:
            deepl.translate({"text": "input", "target": "EN-GB"}, "test:fx", opener)
        self.assertNotIn("private proxy details", str(result.exception))

    def test_malformed_response(self):
        for response in ({"translations": []}, {"translations": [{"text": None}]}):
            with self.assertRaises(deepl.TranslationError):
                self.request(response=response)

    def test_response_limit(self):
        opener = Mock()
        opener.open.return_value = io.BytesIO(b"x" * (deepl.MAX_RESPONSE + 1))
        with self.assertRaises(deepl.TranslationError):
            deepl.translate({"text": "input", "target": "EN-GB"}, "test:fx", opener)

    def test_redirects_are_not_followed(self):
        self.assertIsNone(deepl.NoRedirect().redirect_request(
            None, None, 302, "redirect", {}, "https://other.invalid"))


if __name__ == "__main__":
    unittest.main()
