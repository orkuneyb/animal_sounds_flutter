"""Serves the sound review page on this computer only.

Usage (from the project root):
    python scripts/sounds/review_server.py          then open http://127.0.0.1:8765

The page lists every animal of animal-sound-research/sounds_manifest.json
with its picture, its sound and its source. A decision made on the page
(approved / rejected / research again / pending, with an optional note) is
saved in animal-sound-research/reviews.json. The server listens on
127.0.0.1 only, reads pictures from assets/animal_images and sounds from the
research folder, and writes nothing but reviews.json.
"""
import datetime
import http.server
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
BASE = ROOT / "animal-sound-research"
PORT = 8765
STATUSES = {"pending", "approved", "rejected", "research_again"}
NAME = re.compile(r"^[a-z_]+$")


def manifest() -> list:
    return json.loads((BASE / "sounds_manifest.json").read_text(encoding="utf-8"))


def reviews() -> dict:
    path = BASE / "reviews.json"
    return json.loads(path.read_text(encoding="utf-8")) if path.exists() else {}


class Handler(http.server.BaseHTTPRequestHandler):
    def send(self, code: int, body: bytes, kind: str) -> None:
        self.send_response(code)
        self.send_header("Content-Type", kind)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self) -> None:
        path = self.path.split("?")[0]
        if path == "/":
            return self.send(200, (BASE / "review" / "index.html").read_bytes(), "text/html; charset=utf-8")
        if path == "/data":
            saved = reviews()
            rows = manifest()
            for row in rows:
                row["review_status"] = saved.get(row["animal_id"], {}).get("status", "pending")
                row["review_note"] = saved.get(row["animal_id"], {}).get("note", "")
            return self.send(200, json.dumps(rows, ensure_ascii=False).encode("utf-8"), "application/json")
        image = re.fullmatch(r"/image/([a-z_]+)\.png", path)
        if image:
            target = ROOT / "assets" / "animal_images" / f"{image.group(1)}.png"
            if target.is_file():
                return self.send(200, target.read_bytes(), "image/png")
        sound = re.fullmatch(r"/sound/(processed|needs-review)/([a-z_]+)\.mp3", path)
        if sound:
            target = BASE / sound.group(1) / f"{sound.group(2)}.mp3"
            if target.is_file():
                return self.send(200, target.read_bytes(), "audio/mpeg")
        self.send(404, b"not found", "text/plain")

    def do_POST(self) -> None:
        if self.path != "/review" or self.headers.get("Origin") not in (
                None, f"http://127.0.0.1:{PORT}", f"http://localhost:{PORT}"):
            return self.send(403, b"refused", "text/plain")
        try:
            length = int(self.headers.get("Content-Length", "0"))
            body = json.loads(self.rfile.read(min(length, 4000)).decode("utf-8"))
            animal, status = body["animal_id"], body["status"]
            note = str(body.get("note", ""))[:500]
        except (ValueError, KeyError, TypeError):
            return self.send(400, b"bad request", "text/plain")
        known = {row["animal_id"] for row in manifest()}
        if not isinstance(animal, str) or not NAME.match(animal) or animal not in known or status not in STATUSES:
            return self.send(400, b"unknown animal or status", "text/plain")
        saved = reviews()
        if status == "pending" and not note:
            saved.pop(animal, None)
        else:
            saved[animal] = {"status": status, "note": note,
                             "decided": datetime.datetime.now().isoformat(timespec="seconds")}
        (BASE / "reviews.json").write_text(json.dumps(saved, ensure_ascii=False, indent=1) + "\n",
                                           encoding="utf-8", newline="\n")
        self.send(200, b'{"ok":true}', "application/json")

    def log_message(self, *args) -> None:
        pass


def main() -> int:
    server = http.server.ThreadingHTTPServer(("127.0.0.1", PORT), Handler)
    print(f"Ses kontrol sayfası: http://127.0.0.1:{PORT}  (durdurmak için Ctrl+C)", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    return 0


if __name__ == "__main__":
    sys.exit(main())
