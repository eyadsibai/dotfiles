// Pure logic for the meeting planner. Times are UTC instants plus each row's
// offset periods from the helper; no Date-local calls, so every zone renders
// the same instant consistently.

var ELSEWHEN = "omarchy.elsewhen"
var WEEKDAYS = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
var MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

function clone(value) { return JSON.parse(JSON.stringify(value)) }

// A plain deep copy of an object, else {}. The host hands settings over as a
// wrapper whose nested lists fail Array.isArray.
function plainObject(value) {
  var copy = value && typeof value === "object" ? clone(value) : null
  return copy && typeof copy === "object" && !Array.isArray(copy) ? copy : {}
}

// The entry for widget `id` anywhere in a bar layout (left, centerBegin,
// center, centerEnd, right, ...), as a copy, or null when it is absent.
function layoutEntry(layout, id) {
  if (!layout || typeof layout !== "object") return null
  for (var section in layout) {
    var entries = layout[section]
    if (!entries || typeof entries.length !== "number") continue
    for (var i = 0; i < entries.length; i++) {
      var entry = entries[i]
      if (entry === id) return {}
      if (entry && typeof entry === "object" && entry.id === id) return plainObject(entry)
    }
  }
  return null
}

// Elsewhen's cities: `cities` [{name, zone}], or before its first write the
// older "Label|Zone, Zone" string in `zones`.
function elsewhenCities(entry) {
  entry = entry || {}
  var out = []
  if (Array.isArray(entry.cities) && entry.cities.length) {
    for (var c of entry.cities) {
      if (c && typeof c === "object" && typeof c.zone === "string" && c.zone.trim())
        out.push({label: String(c.name || "").trim(), zone: c.zone.trim()})
    }
    return out
  }
  for (var part of String(entry.zones || "").split(",")) {
    var fields = part.split("|").map(function(s) { return s.trim() })
    var zone = fields.length > 1 ? fields[1] : fields[0]
    if (zone) out.push({label: fields.length > 1 ? fields[0] : "", zone: zone})
  }
  return out
}

// Elsewhen's name for this machine's city, while it still matches the zone
// the helper reports; the helper falls back to the zone's own city.
function elsewhenHere(entry) {
  entry = entry || {}
  if (entry.here && typeof entry.here === "object" && typeof entry.here.name === "string")
    return {name: entry.here.name.trim(), zone: String(entry.here.zone || "")}
  return {name: String(entry.homeCity || "").trim(), zone: ""}
}

// Everything the planner needs from the bar: its own settings, and the cities
// from Elsewhen unless it lists its own. hour24 likewise falls back to
// Elsewhen's, then to `localeHour24`.
function plan(own, layout, localeHour24) {
  own = plainObject(own)
  var elsewhen = layoutEntry(layout, ELSEWHEN)
  var source = Array.isArray(own.cities) && own.cities.length ? "own" : elsewhen ? "elsewhen" : "none"
  var cities = source === "own" ? elsewhenCities({cities: own.cities})
    : source === "elsewhen" ? elsewhenCities(elsewhen) : []
  var here = elsewhenHere(source === "elsewhen" ? elsewhen : {})
  var hour24 = typeof own.hour24 === "boolean" ? own.hour24
    : elsewhen && typeof elsewhen.hour24 === "boolean" ? elsewhen.hour24 : localeHour24 !== false
  var minutes = Number(own.meetingMinutes)
  return {
    source: source,
    cities: cities,
    here: here,
    hour24: hour24,
    meetingMinutes: Number.isInteger(minutes) && minutes >= 15 && minutes <= 240 ? minutes : 60,
    hours: plainObject(own.hours)
  }
}

// The helper request for a plan: what changes the snapshot, nothing more.
function request(p) {
  return {cities: p.cities, here: p.here, hours: p.hours, meetingMinutes: p.meetingMinutes}
}

// Every Text that shows a configurable string uses Text.PlainText; this is a
// second guard for messages that reach the shell.
function plainText(value) {
  return String(value === null || value === undefined ? "" : value).replace(/[<>&]/g, "")
}

function pad2(n) { return (n < 10 ? "0" : "") + n }

function hour12(hour) {
  var h = hour % 12
  return h === 0 ? 12 : h
}

// Wall-clock fields of a UTC instant at a fixed offset.
function localFields(utcMs, offsetMin) {
  var d = new Date(utcMs + offsetMin * 60000)
  return {hour: d.getUTCHours(), minute: d.getUTCMinutes(), day: d.getUTCDate(), weekday: d.getUTCDay(), month: d.getUTCMonth()}
}

function localDay(instant, offsetMin) { return Math.floor((instant + offsetMin * 60000) / 86400000) }

// The offset period a row is in at `instant`.
function periodAt(zone, instant) {
  var period = {offsetMin: zone.offsetMin, abbr: zone.abbr || ""}
  for (var next of zone.periods || []) {
    if (next.start > instant) break
    period = next
  }
  return period
}
function offsetAt(zone, instant) { return periodAt(zone, instant).offsetMin }
function abbrAt(zone, instant) { return periodAt(zone, instant).abbr }

// "07:12", or "07:12 AM" on a 12-hour clock.
function timeLabel(utcMs, offsetMin, hour24) {
  var f = localFields(utcMs, offsetMin)
  if (hour24) return pad2(f.hour) + ":" + pad2(f.minute)
  return pad2(hour12(f.hour)) + ":" + pad2(f.minute) + (f.hour < 12 ? " AM" : " PM")
}

// A grid cell's hour: "13", or worldtimebuddy-short "1p" on a 12-hour clock.
function hourLabel(hour, hour24) {
  return hour24 ? String(hour) : hour12(hour) + (hour < 12 ? "a" : "p")
}

function dateLabel(utcMs, offsetMin) {
  var f = localFields(utcMs, offsetMin)
  return WEEKDAYS[f.weekday] + " " + f.day + " " + MONTHS[f.month]
}

// The calendar-day difference from home at the same instant.
function relativeDayLabel(instant, offsetMin, homeOffsetMin) {
  var difference = localDay(instant, offsetMin) - localDay(instant, homeOffsetMin)
  if (difference === 0) return ""
  if (difference === -1) return "Yesterday"
  if (difference === 1) return "Tomorrow"
  return (difference > 0 ? "+" : "−") + Math.abs(difference) + " days"
}

function parseTime(value, allowEnd) {
  if (typeof value !== "string" || !/^\d{2}:\d{2}$/.test(value)) return null
  var h = Number(value.slice(0, 2)), m = Number(value.slice(3))
  if (allowEnd && h === 24 && m === 0) return 1440
  return h < 24 && m < 60 ? h * 60 + m : null
}

// Whether a row's city is working at `instant`; rows that do not count
// toward the overlap (UTC, hours: false) never are.
function isWorking(zone, instant) {
  if (zone.counts === false || !Array.isArray(zone.workDays)) return false
  var f = localFields(instant, offsetAt(zone, instant))
  var minute = f.hour * 60 + f.minute
  var start = parseTime(zone.workStart, false), end = parseTime(zone.workEnd, true)
  if (start === null || end === null) return false
  if (start < end) return zone.workDays.indexOf(f.weekday) !== -1 && minute >= start && minute < end
  return (minute >= start && zone.workDays.indexOf(f.weekday) !== -1) || (minute < end && zone.workDays.indexOf((f.weekday + 6) % 7) !== -1)
}

// One grid cell: the row's local hour in home-day column `col`. `isMidnight`
// marks the column in which a local day starts; the home row's first column
// always opens the home day, even when DST skips its midnight.
function cell(col, dayStartUtcMs, zone) {
  var instant = dayStartUtcMs + col * 3600000
  var offset = offsetAt(zone, instant)
  var f = localFields(instant, offset)
  var previous = instant - 3600000
  return {
    hour: f.hour,
    minute: f.minute,
    isMidnight: col === 0 ? zone.home === true || (f.hour === 0 && f.minute === 0)
      : localDay(previous, offsetAt(zone, previous)) !== localDay(instant, offset),
    dayLabel: WEEKDAYS[f.weekday] + " " + f.day,
    tint: isWorking(zone, instant) ? "work" : f.hour >= 6 && f.hour < 23 ? "day" : "night"
  }
}

// A cell's text: the date where a local day starts, else the hour, with
// ":30"/":45" on a second line for rows offset by part of an hour.
function cellLabel(c, hour24) {
  if (c.isMidnight) return c.dayLabel.replace(" ", "\n")
  if (c.minute) return (hour24 ? pad2(c.hour) : hourLabel(c.hour, false)) + "\n:" + pad2(c.minute)
  return hourLabel(c.hour, hour24)
}

// Back-to-back meeting starts as windows: 16:00, 16:15 … 22:00 for a
// 60-minute meeting read as one "16:00–23:00" span.
function slotWindows(slots) {
  var windows = []
  for (var slot of slots || []) {
    var last = windows[windows.length - 1]
    if (last && slot.start <= last.lastStart + 15 * 60000) { last.lastStart = slot.start; last.end = slot.end }
    else windows.push({start: slot.start, lastStart: slot.start, end: slot.end})
  }
  return windows
}

function isoDate(instant, offsetMin) {
  return new Date(instant + offsetMin * 60000).toISOString().slice(0, 10)
}

// The meeting at `instant` as plain text: its UTC time, then each city's
// local start and end, with dates.
function meetingText(zones, instant, durationMinutes, hour24) {
  var end = instant + durationMinutes * 60000
  var lines = ["Meeting: " + new Date(instant).toISOString().slice(0, 16).replace("T", " ") + " UTC (" + durationMinutes + " min)"]
  for (var zone of zones) {
    if (zone.offsetMin === null || zone.offsetMin === undefined) continue
    var beginOffset = offsetAt(zone, instant), endOffset = offsetAt(zone, end)
    var beginDate = isoDate(instant, beginOffset), endDate = isoDate(end, endOffset)
    var abbr = abbrAt(zone, instant), endAbbr = abbrAt(zone, end)
    lines.push(zone.label + ": " + beginDate + " " + timeLabel(instant, beginOffset, hour24)
      + (abbr ? " " + abbr : "") + " – " + (beginDate === endDate ? "" : endDate + " ")
      + timeLabel(end, endOffset, hour24) + (endAbbr ? " " + endAbbr : ""))
  }
  return lines.join("\n")
}

if (typeof module !== "undefined") {
  module.exports = {
    clone: clone, plainObject: plainObject, layoutEntry: layoutEntry, elsewhenCities: elsewhenCities,
    elsewhenHere: elsewhenHere, plan: plan, request: request, plainText: plainText, pad2: pad2,
    localFields: localFields, periodAt: periodAt, offsetAt: offsetAt, abbrAt: abbrAt, timeLabel: timeLabel,
    hourLabel: hourLabel, dateLabel: dateLabel, relativeDayLabel: relativeDayLabel, parseTime: parseTime,
    isWorking: isWorking, cell: cell, cellLabel: cellLabel, slotWindows: slotWindows, meetingText: meetingText
  }
}
