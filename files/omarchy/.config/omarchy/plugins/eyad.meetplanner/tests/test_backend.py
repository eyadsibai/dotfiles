"""The helper: home detection, working hours, overlap slots, DST days.

Run: python3 -m unittest discover -s tests (from the plugin folder)."""

import importlib.util
import json
import os
import subprocess
import sys
import unittest
from datetime import datetime
from pathlib import Path
from unittest.mock import patch

BACKEND = Path(__file__).resolve().parents[1] / "backend.py"
SPEC = importlib.util.spec_from_file_location("backend", BACKEND)
backend = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(backend)


def ms(iso):
    return int(datetime.fromisoformat(iso).timestamp() * 1000)


def city(zone, name=""):
    return {"label": name, "zone": zone}


class Backend(unittest.TestCase):
    def setUp(self):
        environment = patch.dict(os.environ, TZ="Asia/Riyadh")
        environment.start()
        self.addCleanup(environment.stop)

    def run_snapshot(self, cities, now="2026-10-05T06:00:00+00:00", **request):
        return backend.snapshot(dict(cities=cities, nowMs=ms(now), **request))

    def test_home_is_the_city_on_the_system_zone(self):
        result = self.run_snapshot([city("America/Los_Angeles", "SF"), city("Asia/Riyadh", "Riyadh")])
        self.assertEqual([(z["label"], z["home"]) for z in result["zones"]], [("SF", False), ("Riyadh", True)])
        self.assertEqual(result["systemTz"], "Asia/Riyadh")

    def test_home_is_added_first_when_no_city_is_on_the_system_zone(self):
        result = self.run_snapshot([city("Europe/Istanbul")], here={"name": "Jeddah", "zone": "Asia/Riyadh"})
        self.assertEqual([(z["label"], z["home"]) for z in result["zones"]], [("Jeddah", True), ("Istanbul", False)])

    def test_here_for_another_zone_is_ignored(self):
        result = self.run_snapshot([], here={"name": "Paris", "zone": "Europe/Paris"})
        self.assertEqual(result["zones"][0]["label"], "Riyadh")

    def test_legacy_zone_names_match_the_system_zone(self):
        with patch.dict(os.environ, TZ="America/Los_Angeles"):
            result = self.run_snapshot([city("US/Pacific", "SF")])
        self.assertEqual(len(result["zones"]), 1)
        self.assertTrue(result["zones"][0]["home"])

    def test_utc_is_a_reference_row_outside_the_overlap(self):
        result = self.run_snapshot([city("Asia/Riyadh"), city("Etc/UTC", "UTC")])
        utc = result["zones"][1]
        self.assertFalse(utc["counts"])
        self.assertNotIn("workDays", utc)
        # Riyadh alone works Sun-Thu 09-17; Monday 2026-10-05 09:00 AST is 06:00Z.
        self.assertEqual(result["slots"][0]["start"], ms("2026-10-05T06:00:00+00:00"))

    def test_overlap_respects_every_city(self):
        result = self.run_snapshot([city("Asia/Riyadh"), city("Europe/London")], meetingMinutes=60)
        # London works 09-17 BST = 08-16Z, Riyadh 06-14Z: shared 08-14Z.
        starts = [s["start"] for s in result["slots"]]
        self.assertEqual(starts[0], ms("2026-10-05T08:00:00+00:00"))
        self.assertEqual(starts[-1], ms("2026-10-05T13:00:00+00:00"))

    def test_custom_and_disabled_hours(self):
        hours = {"Europe/London": {"days": [1, 2, 3, 4, 5], "start": "12:00", "end": "20:00"}, "Asia/Tokyo": False}
        result = self.run_snapshot([city("Asia/Riyadh"), city("Europe/London"), city("Asia/Tokyo")], hours=hours)
        self.assertEqual(result["slots"][0]["start"], ms("2026-10-05T11:00:00+00:00"))
        self.assertFalse(result["zones"][2]["counts"])
        self.assertEqual(result["errors"], [])

    def test_bad_hours_fall_back_to_defaults_with_a_message(self):
        result = self.run_snapshot([city("Asia/Riyadh"), city("Europe/London")], hours={"Europe/London": {"start": "9am"}})
        self.assertIn("hours for Europe/London", result["errors"][0])
        self.assertEqual(result["zones"][1]["workStart"], "09:00")

    def test_unknown_and_malformed_cities(self):
        result = self.run_snapshot([city("America/Nowhere"), city("../etc/passwd"), "x", city("Asia/Riyadh")])
        self.assertEqual([z["zone"] for z in result["zones"]], ["Asia/Riyadh"])
        self.assertEqual(result["errors"], ["Unknown timezone: America/Nowhere"])

    def test_dst_days_have_23_and_25_columns(self):
        with patch.dict(os.environ, TZ="America/New_York"):
            self.assertEqual(len(self.run_snapshot([], now="2026-03-08T12:00:00+00:00")["columns"]), 23)
            self.assertEqual(len(self.run_snapshot([], now="2026-11-01T12:00:00+00:00")["columns"]), 25)

    def test_slots_start_from_now(self):
        result = self.run_snapshot([city("Asia/Riyadh")], now="2026-10-05T10:05:00+00:00")
        self.assertEqual(result["slots"][0]["start"], ms("2026-10-05T10:15:00+00:00"))

    def test_bad_duration_reports_and_uses_an_hour(self):
        result = self.run_snapshot([], meetingMinutes=5)
        self.assertEqual(result["meetingMinutes"], 60)
        self.assertTrue(result["errors"])

    def test_cli_always_answers_json(self):
        for payload in (b"not json", json.dumps({"cities": [city("Europe/Paris")]}).encode()):
            out = subprocess.run([sys.executable, BACKEND], input=payload, capture_output=True, check=True)
            self.assertIsInstance(json.loads(out.stdout), dict)


if __name__ == "__main__":
    unittest.main()
