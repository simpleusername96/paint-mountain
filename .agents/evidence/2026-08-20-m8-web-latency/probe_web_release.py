"""Capture the local release-Web canvas through a task-owned Chrome CDP session."""

from __future__ import annotations

import base64
import argparse
import json
import subprocess
import tempfile
import time
import urllib.request
from pathlib import Path

import websocket
from websocket import WebSocketTimeoutException


CHROME = Path(r"C:\Program Files\Google\Chrome\Application\chrome.exe")
ROOT = Path(__file__).resolve().parent
URL = "http://127.0.0.1:13034/index.html?m8-cdp=1"


class Cdp:
    def __init__(self, url: str) -> None:
        self.socket = websocket.create_connection(url, timeout=2, origin="http://localhost")
        self.next_id = 1
        self.events: list[dict] = []

    def call(self, method: str, params: dict | None = None) -> dict:
        call_id = self.next_id
        self.next_id += 1
        self.socket.settimeout(20)
        self.socket.send(json.dumps({"id": call_id, "method": method, "params": params or {}}))
        while True:
            message = json.loads(self.socket.recv())
            if message.get("id") == call_id:
                if "error" in message:
                    raise RuntimeError(f"{method}: {message['error']}")
                self.socket.settimeout(2)
                return message.get("result", {})
            self.events.append(message)

    def pump(self, seconds: float) -> None:
        deadline = time.monotonic() + seconds
        while time.monotonic() < deadline:
            self.socket.settimeout(min(0.25, max(0.01, deadline - time.monotonic())))
            try:
                self.events.append(json.loads(self.socket.recv()))
            except (TimeoutError, WebSocketTimeoutException):
                pass
        self.socket.settimeout(2)

    def evaluate(self, expression: str) -> object:
        result = self.call(
            "Runtime.evaluate",
            {"expression": expression, "returnByValue": True, "awaitPromise": True},
        )
        return result.get("result", {}).get("value")

    def screenshot(self, name: str) -> None:
        result = self.call("Page.captureScreenshot", {"format": "png", "fromSurface": True})
        (ROOT / name).write_bytes(base64.b64decode(result["data"]))

    def click(self, x: float, y: float) -> None:
        common = {"x": x, "y": y, "button": "left", "clickCount": 1}
        self.call("Input.dispatchMouseEvent", {"type": "mousePressed", **common})
        self.pump(0.05)
        self.call("Input.dispatchMouseEvent", {"type": "mouseReleased", **common})

    def press_space(self) -> None:
        common = {
            "key": " ",
            "code": "Space",
            "windowsVirtualKeyCode": 32,
            "nativeVirtualKeyCode": 32,
        }
        self.call("Input.dispatchKeyEvent", {"type": "keyDown", **common})
        self.pump(0.05)
        self.call("Input.dispatchKeyEvent", {"type": "keyUp", **common})

    def press_tab(self) -> None:
        common = {
            "key": "Tab",
            "code": "Tab",
            "windowsVirtualKeyCode": 9,
            "nativeVirtualKeyCode": 9,
        }
        self.call("Input.dispatchKeyEvent", {"type": "keyDown", **common})
        self.pump(0.05)
        self.call("Input.dispatchKeyEvent", {"type": "keyUp", **common})

    def console_values(self) -> list[object]:
        values: list[object] = []
        for event in self.events:
            if event.get("method") != "Runtime.consoleAPICalled":
                continue
            args = event["params"].get("args", [])
            if args:
                values.append(args[0].get("value", args[0].get("description", "")))
        return values

    def marker_payloads(self) -> list[dict]:
        payloads: list[dict] = []
        for value in self.console_values():
            if not isinstance(value, str) or not value.startswith("{"):
                continue
            try:
                payload = json.loads(value)
            except json.JSONDecodeError:
                continue
            if "paint_mountain_marker" in payload:
                payloads.append(payload)
        return payloads

    def wait_for_marker(self, marker: str, timeout: float) -> dict:
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            for payload in reversed(self.marker_payloads()):
                if payload.get("paint_mountain_marker") == marker:
                    return payload
            self.pump(0.25)
        raise RuntimeError(f"Timed out waiting for marker: {marker}")

    def wait_for_stage_marker(self, marker: str, stage_id: str, timeout: float) -> dict:
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            for payload in reversed(self.marker_payloads()):
                if payload.get("paint_mountain_marker") == marker \
                        and payload.get("stage_id") == stage_id:
                    return payload
            self.pump(0.25)
        raise RuntimeError(f"Timed out waiting for {marker} on {stage_id}")


def wait_for_debug_port(profile: Path) -> int:
    port_file = profile / "DevToolsActivePort"
    for _ in range(100):
        if port_file.exists():
            return int(port_file.read_text(encoding="utf-8").splitlines()[0])
        time.sleep(0.1)
    raise RuntimeError("Chrome did not publish a DevTools port")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--scenario", choices=("standard", "burst", "apex"), default="standard")
    scenario = parser.parse_args().scenario
    with tempfile.TemporaryDirectory(prefix="paint-mountain-m8-") as profile_name:
        profile = Path(profile_name)
        process = subprocess.Popen(
            [
                str(CHROME),
                "--no-first-run",
                "--no-default-browser-check",
                "--remote-debugging-port=0",
                "--remote-allow-origins=*",
                "--disable-background-timer-throttling",
                "--disable-backgrounding-occluded-windows",
                "--disable-renderer-backgrounding",
                "--force-device-scale-factor=1",
                "--window-size=1280,720",
                "--window-position=0,0",
                f"--user-data-dir={profile}",
                "about:blank",
            ],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.PIPE,
            text=True,
        )
        cdp: Cdp | None = None
        try:
            port = wait_for_debug_port(profile)
            with urllib.request.urlopen(f"http://127.0.0.1:{port}/json/list") as response:
                targets = json.load(response)
            page = next(target for target in targets if target["type"] == "page")
            cdp = Cdp(page["webSocketDebuggerUrl"])
            cdp.call("Page.enable")
            cdp.call("Runtime.enable")
            cdp.call("Log.enable")
            cdp.call("Page.bringToFront")
            cdp.call("Page.navigate", {"url": URL})
            prepared = cdp.wait_for_marker("gameplay_prepared", 60.0)
            print("gameplay_prepared", prepared)
            cdp.pump(2.0)
            print("canvas", cdp.evaluate("(() => { const c=document.querySelector('canvas'); return c ? {width:c.width,height:c.height,rect:c.getBoundingClientRect().toJSON()} : null; })()"))
            cdp.screenshot(f"cdp-{scenario}-main-menu.png")
            if scenario == "standard":
                stage_id = "stage_01"
                cdp.click(155, 315)
            else:
                stage_id = "stage_02" if scenario == "burst" else "stage_03"
                cdp.click(155, 373)
                cdp.pump(1.0)
                cdp.screenshot(f"cdp-{scenario}-stage-select.png")
                if scenario == "burst":
                    cdp.click(500, 140)
                else:
                    cdp.click(175, 250)
                cdp.wait_for_stage_marker("artifact_ready", stage_id, 40.0)
                cdp.pump(1.0)
                cdp.screenshot(f"cdp-{scenario}-stage-selected.png")
                cdp.click(970, 565)
                cdp.wait_for_stage_marker("gameplay_visible", stage_id, 40.0)
            cdp.pump(2.0)
            cdp.screenshot(f"cdp-{scenario}-briefing.png")
            cdp.click(230, 527)
            cdp.pump(2.0)
            cdp.screenshot(f"cdp-{scenario}-aiming.png")
            if scenario == "apex":
                for _ in range(80):
                    cdp.click(996, 454)
                for _ in range(25):
                    cdp.click(1105, 454)
                cdp.pump(1.0)
            marker_start = len(cdp.marker_payloads())
            cdp.evaluate("""
                (() => {
                    window.__pmFrameSamples = [];
                    window.__pmFrameDone = false;
                    let previous = null;
                    const deadline = performance.now() + 12000;
                    const sample = timestamp => {
                        if (previous !== null) window.__pmFrameSamples.push(timestamp - previous);
                        previous = timestamp;
                        if (performance.now() < deadline) requestAnimationFrame(sample);
                        else window.__pmFrameDone = true;
                    };
                    requestAnimationFrame(sample);
                    return true;
                })()
            """)
            if scenario == "apex":
                cdp.click(640, 525)
            else:
                cdp.press_space()
            if scenario == "burst":
                cdp.pump(0.5)
                cdp.press_tab()
                cdp.pump(0.5)
                cdp.press_space()
            cdp.pump(13.0 if scenario == "burst" else 9.0)
            cdp.screenshot(f"cdp-{scenario}-after-fire.png")
            frame_samples = cdp.evaluate("window.__pmFrameSamples || []")
            sorted_frames = sorted(frame_samples)
            percentile = lambda fraction: sorted_frames[min(len(sorted_frames) - 1, int(len(sorted_frames) * fraction))]
            frame_summary = {
                "count": len(sorted_frames),
                "p95_ms": round(percentile(0.95), 2),
                "p99_ms": round(percentile(0.99), 2),
                "max_ms": round(max(sorted_frames), 2),
            }
            print(f"{scenario}_frames", frame_summary)
            scenario_markers = cdp.marker_payloads()[marker_start:]
            print(f"{scenario}_markers")
            for payload in scenario_markers:
                if payload.get("trace_id", 0) or payload.get("trace_ids"):
                    print(json.dumps(payload, sort_keys=True))
            evidence = {
                "scenario": scenario,
                "url": URL,
                "frame_summary": frame_summary,
                "markers": scenario_markers,
            }
            (ROOT / f"probe-{scenario}.json").write_text(
                json.dumps(evidence, indent=2, sort_keys=True),
                encoding="utf-8",
            )
            console_events = [event for event in cdp.events if event.get("method") == "Runtime.consoleAPICalled"]
            print("console_events", len(console_events))
            for event in console_events[-20:]:
                values = [item.get("value", item.get("description", "")) for item in event["params"].get("args", [])]
                print(event["params"].get("type"), values)
        finally:
            if cdp is not None:
                try:
                    cdp.call("Browser.close")
                except Exception:
                    pass
            process.wait(timeout=10)
            if process.returncode not in (0, None) and process.stderr is not None:
                print("chrome_stderr", process.stderr.read()[-4000:])


if __name__ == "__main__":
    main()
