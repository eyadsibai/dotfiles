#!/usr/bin/env python3
"""One home day of hour columns for a list of cities, and the meeting slots
that fit every city's working hours. Offline, from the system tzdata."""

import json
import math
import os
import re
import sys
from datetime import datetime, time, timedelta, timezone
from functools import cache
from pathlib import Path
from zoneinfo import ZoneInfo

UTC = timezone.utc
MINUTE_MS = 60_000
LOCALTIME = "/etc/localtime"
ZONEINFO = Path("/usr/share/zoneinfo")
ZONE_ID = re.compile(r"[A-Za-z0-9_+-]+(?:/[A-Za-z0-9_+-]+)*")
ZERO_ZONES = {"UTC", "UCT", "GMT", "GMT0", "GMT+0", "GMT-0", "Greenwich", "Universal", "Zulu"}
MAX_CITIES = 32


def zone_file(path):
    # Named like timedatectl's link target: the part after the last /zoneinfo/.
    resolved = os.path.realpath(path)
    name = resolved.rpartition("/zoneinfo/")[2] if "/zoneinfo/" in resolved else ""
    with open(resolved, "rb") as stream:
        return name, ZoneInfo.from_file(stream, key=name or None)


def local_zone():
    # As glibc reads it: TZ without one leading ':', else /etc/localtime.
    configured = os.environ.get("TZ", "").removeprefix(":")
    if configured:
        try:
            return zone_file(Path(configured)) if configured.startswith("/") else (configured, ZoneInfo(configured))
        except Exception:
            pass  # A POSIX rule such as UTC0 names no file: read the system zone instead.
    if not os.path.lexists(LOCALTIME):
        return "UTC", UTC  # As glibc and systemd do.
    return zone_file(LOCALTIME)


# tzdata's backward-compatibility names (US/Pacific, Asia/Calcutta) and their
# zones, so a city listed under an old name still matches the system clock.
@cache
def legacy_links():
    try:
        listed = {line.split("\t")[2] for tab in ("zone1970.tab", "zone.tab")
                  for line in (ZONEINFO / tab).read_text(encoding="utf-8").splitlines() if line and line[0] != "#"}
        links = [line.split() for line in (ZONEINFO / "tzdata.zi").read_text(encoding="utf-8").splitlines()
                 if line.startswith("L ")]
        return {link: target for _, target, link in links if link not in listed}
    except (OSError, ValueError, IndexError):
        return {}


def canonical(name):
    name, links, seen = re.sub(r"^(posix|right)/", "", name), legacy_links(), set()
    while name in links and name not in seen:
        seen.add(name)
        name = links[name]
    return name


def city_of(name):
    return name.split("/")[-1].replace("_", " ") or "Home"


def is_reference(name):
    # UTC and the Etc/GMT±N zones are clocks, not places: nobody works there.
    return name.removeprefix("Etc/") in ZERO_ZONES or re.fullmatch(r"Etc/GMT[+-]\d+", name) is not None


def minutes(value, end=False):
    parts = value.split(":") if isinstance(value, str) else []
    if len(parts) != 2 or any(len(p) != 2 or not p.isdigit() for p in parts):
        raise ValueError("working hours must be HH:MM")
    hour, minute = map(int, parts)
    if end and (hour, minute) == (24, 0):
        return 1440
    if not (hour < 24 and minute < 60):
        raise ValueError("working hours must be HH:MM")
    return hour * 60 + minute


def default_days(zone):
    return [0, 1, 2, 3, 4] if zone == "Asia/Riyadh" else [1, 2, 3, 4, 5]


def schedule(spec, zone):
    """(days, start, end) in minutes, or None for a city that never works.
    `spec` is the city's entry in the `hours` setting: missing for defaults,
    false to leave the city out of the overlap."""
    if spec is False or (spec is None and is_reference(zone)):
        return None
    spec = {} if spec is None or spec is True else spec
    if not isinstance(spec, dict):
        raise ValueError("hours must be an object or false")
    days = spec.get("days", default_days(zone))
    if not isinstance(days, list) or any(type(d) is not int or not 0 <= d <= 6 for d in days):
        raise ValueError("days must be weekday numbers, 0 (Sunday) to 6")
    start, end = minutes(spec.get("start", "09:00")), minutes(spec.get("end", "17:00"), end=True)
    if start == end:
        raise ValueError("working start and end must differ")
    return days, start, end


def working(local, hours):
    days, start, end = hours
    day = (local.weekday() + 1) % 7  # Sunday = 0, as in the settings.
    minute = local.hour * 60 + local.minute
    if start < end:
        return day in days and start <= minute < end
    # An overnight shift belongs to the day on which it starts.
    return (minute >= start and day in days) or (minute < end and (day - 1) % 7 in days)


def offset(local):
    return int(local.utcoffset().total_seconds() // 60)


def hhmm(value):
    return f"{value // 60:02d}:{value % 60:02d}"


def rows_for(request, system_name):
    """The cities to show, in order, with exactly one home: the first city on
    the system's timezone, or the system's own city put first."""
    cities = request.get("cities")
    cities = cities if isinstance(cities, list) else []
    rows, seen = [], set()
    for city in cities:
        zone = city.get("zone") if isinstance(city, dict) else None
        if not isinstance(zone, str) or not ZONE_ID.fullmatch(zone):
            continue
        label = city.get("label")
        label = label.strip() if isinstance(label, str) and label.strip() else city_of(zone)
        if (zone, label) in seen:
            continue
        seen.add((zone, label))
        rows.append({"label": label, "zone": zone, "home": False})
        if len(rows) == MAX_CITIES:
            break
    # Elsewhen's name for this machine's city, while it is for this zone.
    here = request.get("here")
    here = here if isinstance(here, dict) else {}
    name, zone = here.get("name"), here.get("zone")
    here = name.strip() if isinstance(name, str) and (not zone or (isinstance(zone, str)
                                                                  and canonical(zone) == system_name)) else ""
    home = next((row for row in rows if system_name and canonical(row["zone"]) == system_name), None)
    if home is None and system_name:
        home = {"label": here or city_of(system_name), "zone": system_name, "home": False}
        rows.insert(0, home)
    if home is not None:
        home["home"] = True
    return rows


def snapshot(request):
    if not isinstance(request, dict):
        raise ValueError("The request must be an object.")
    now_ms = request.get("nowMs", datetime.now(UTC).timestamp() * 1000)
    if not isinstance(now_ms, (int, float)) or not math.isfinite(now_ms):
        raise ValueError("Invalid clock timestamp.")
    now = datetime.fromtimestamp(now_ms / 1000, UTC)
    errors = []
    duration = request.get("meetingMinutes", 60)
    if type(duration) is not int or not 15 <= duration <= 240:
        errors.append("meetingMinutes must be 15 to 240.")
        duration = 60
    try:
        system_name, system_zone = local_zone()
        system_name = canonical(system_name)
    except Exception as error:
        raise ValueError(f"Could not read the system timezone: {error}") from error
    hours = request.get("hours")
    hours = hours if isinstance(hours, dict) else {}

    rows, tzs, schedules = [], [], []
    for row in rows_for(request, system_name):
        try:
            tz = system_zone if row["home"] else ZoneInfo(row["zone"])
        except Exception:
            errors.append(f"Unknown timezone: {row['zone']}")
            continue
        try:
            plan = schedule(hours.get(row["zone"]), row["zone"])
        except ValueError as error:
            errors.append(f"hours for {row['zone']}: {error}; using the defaults.")
            plan = schedule(None, row["zone"])
        rows.append(row)
        tzs.append(tz)
        schedules.append(plan)
    if not any(row["home"] for row in rows):
        # The system zone is a file with no name: show it on its own.
        rows.insert(0, {"label": "Home", "zone": "", "home": True})
        tzs.insert(0, system_zone)
        schedules.insert(0, schedule(None, ""))

    home_zone = tzs[next(i for i, row in enumerate(rows) if row["home"])]
    home_date = now.astimezone(home_zone).date()
    start = datetime.combine(home_date, time(), home_zone).astimezone(UTC)
    end = datetime.combine(home_date + timedelta(days=1), time(), home_zone).astimezone(UTC)
    start_ms, end_ms = int(start.timestamp() * 1000), int(end.timestamp() * 1000)
    minute_count = int((end - start).total_seconds() // 60)
    # A copied meeting can end after midnight; cover that horizon too.
    instants = [start + timedelta(minutes=i) for i in range(minute_count + duration + 1)]
    common = [True] * minute_count
    for row, tz, plan in zip(rows, tzs, schedules):
        local_now = now.astimezone(tz)
        row.update(offsetMin=offset(local_now), abbr=local_now.tzname(), periods=[])
        if plan is None:
            row["counts"] = False
        else:
            row.update(counts=True, workDays=plan[0], workStart=hhmm(plan[1]), workEnd=hhmm(plan[2]))
        last = None
        for i, moment in enumerate(instants):
            local = moment.astimezone(tz)
            state = (offset(local), local.tzname())
            if state != last:
                row["periods"].append({"start": start_ms + i * MINUTE_MS, "offsetMin": state[0], "abbr": state[1]})
                last = state
            if plan is not None and i < minute_count:
                common[i] = common[i] and working(local, plan)
    # Prefix sums check every minute of a meeting, across DST changes too.
    busy = [0]
    for free in common:
        busy.append(busy[-1] + (not free))
    first = max(0, math.ceil((now_ms - start_ms) / (15 * MINUTE_MS)) * 15)
    slots = [{"start": start_ms + i * MINUTE_MS, "end": start_ms + (i + duration) * MINUTE_MS}
             for i in range(first, minute_count - duration + 1, 15) if busy[i + duration] == busy[i]]
    columns = [{"start": start_ms + i * MINUTE_MS, "minutes": min(60, minute_count - i),
                "working": all(common[i:min(i + 60, minute_count)])}
               for i in range(0, minute_count, 60)]
    return {"systemTz": system_name, "dayStart": start_ms, "dayEnd": end_ms, "meetingMinutes": duration,
            "zones": rows, "columns": columns, "slots": slots, "errors": errors}


def encode(result):
    # Bytes, so no locale can break the output.
    return json.dumps(result, ensure_ascii=False).encode("utf-8", "backslashreplace") + b"\n"


def main():
    try:
        output = encode(snapshot(json.loads(sys.stdin.buffer.read().decode("utf-8"))))
    except Exception as error:  # The panel always gets one JSON object to show.
        output = encode({"errors": [str(error) or type(error).__name__], "zones": [], "slots": []})
    sys.stdout.buffer.write(output)


if __name__ == "__main__":
    main()
