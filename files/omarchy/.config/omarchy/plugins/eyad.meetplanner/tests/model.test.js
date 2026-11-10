// Run: node --test tests/ (from the plugin folder)
const assert = require('node:assert/strict');
const {test} = require('node:test');
const Model = require('../Model.js');

const layout = {
  center: [{id: 'omarchy.clock'}, {id: 'omarchy.elsewhen', hour24: false, here: {name: 'Jeddah', zone: 'Asia/Riyadh'},
    cities: [{name: 'Riyadh', zone: 'Asia/Riyadh'}, {name: 'SF', zone: 'America/Los_Angeles'}, {zone: ''}, null]}],
  centerBegin: [{id: 'eyad.meetplanner', meetingMinutes: 30}],
};

test('finds entries in any bar section', () => {
  assert.equal(Model.layoutEntry(layout, 'omarchy.elsewhen').cities.length, 4);
  assert.equal(Model.layoutEntry(layout, 'eyad.meetplanner').meetingMinutes, 30);
  assert.deepEqual(Model.layoutEntry({right: ['omarchy.elsewhen']}, 'omarchy.elsewhen'), {});
  assert.equal(Model.layoutEntry(layout, 'missing'), null);
  assert.equal(Model.layoutEntry(null, 'missing'), null);
});

test('plans across Elsewhen cities with its clock format', () => {
  const plan = Model.plan({meetingMinutes: 30}, layout, true);
  assert.equal(plan.source, 'elsewhen');
  assert.deepEqual(plan.cities, [{label: 'Riyadh', zone: 'Asia/Riyadh'}, {label: 'SF', zone: 'America/Los_Angeles'}]);
  assert.deepEqual(plan.here, {name: 'Jeddah', zone: 'Asia/Riyadh'});
  assert.equal(plan.hour24, false);
  assert.equal(plan.meetingMinutes, 30);
});

test('own cities and settings win; bad values fall back', () => {
  const plan = Model.plan({cities: [{name: 'Tokyo', zone: 'Asia/Tokyo'}], hour24: true, meetingMinutes: 7, hours: []}, layout, false);
  assert.equal(plan.source, 'own');
  assert.deepEqual(plan.cities, [{label: 'Tokyo', zone: 'Asia/Tokyo'}]);
  assert.equal(plan.hour24, true);
  assert.equal(plan.meetingMinutes, 60);
  assert.deepEqual(plan.hours, {});
  assert.equal(Model.plan(null, null, false).source, 'none');
  assert.equal(Model.plan(null, null, false).hour24, false);
});

test('reads Elsewhen\'s older zones string', () => {
  assert.deepEqual(Model.elsewhenCities({zones: 'Los Angeles|America/Los_Angeles, Asia/Tokyo'}),
    [{label: 'Los Angeles', zone: 'America/Los_Angeles'}, {label: '', zone: 'Asia/Tokyo'}]);
});

const riyadh = {label: 'Riyadh', home: true, offsetMin: 180, abbr: '+03', periods: [], counts: true,
  workDays: [0, 1, 2, 3, 4], workStart: '09:00', workEnd: '17:00'};
const utc = {label: 'UTC', offsetMin: 0, abbr: 'UTC', periods: [], counts: false};

test('working hours and reference rows', () => {
  assert.equal(Model.isWorking(riyadh, Date.parse('2026-10-05T06:00:00Z')), true);   // Mon 09:00
  assert.equal(Model.isWorking(riyadh, Date.parse('2026-10-05T14:00:00Z')), false);  // Mon 17:00
  assert.equal(Model.isWorking(riyadh, Date.parse('2026-10-09T08:00:00Z')), false);  // Friday
  assert.equal(Model.isWorking(utc, Date.parse('2026-10-05T10:00:00Z')), false);
  const night = Object.assign({}, riyadh, {workStart: '22:00', workEnd: '06:00'});
  assert.equal(Model.isWorking(night, Date.parse('2026-10-08T23:00:00Z')), true); // Fri 02:00 after a Thu shift
});

test('cells mark local midnights and tint by working hours', () => {
  const dayStart = Date.parse('2026-10-04T21:00:00Z');
  assert.equal(Model.cell(0, dayStart, riyadh).isMidnight, true);
  assert.equal(Model.cell(9, dayStart, riyadh).tint, 'work');
  assert.equal(Model.cell(3, dayStart, utc).isMidnight, true);
  assert.equal(Model.cell(3, dayStart, utc).tint, 'night');
  assert.equal(Model.cellLabel(Model.cell(13, dayStart, riyadh), false), '1p');
  assert.equal(Model.cellLabel({hour: 9, minute: 30, isMidnight: false}, true), '09\n:30');
});

test('times, days, windows and copied text', () => {
  const at = Date.parse('2026-12-31T22:00:00Z');
  assert.equal(Model.timeLabel(at, 180, true), '01:00');
  assert.equal(Model.timeLabel(at, 180, false), '01:00 AM');
  assert.equal(Model.relativeDayLabel(at, -480, 180), 'Yesterday');
  assert.equal(Model.relativeDayLabel(Date.parse('2026-10-05T10:30:00Z'), 840, -720), '+2 days');
  const q = 15 * 60000;
  assert.deepEqual(Model.slotWindows([{start: 0, end: 4 * q}, {start: q, end: 5 * q}, {start: 8 * q, end: 12 * q}]),
    [{start: 0, lastStart: q, end: 5 * q}, {start: 8 * q, lastStart: 8 * q, end: 12 * q}]);
  assert.equal(Model.meetingText([riyadh, utc], Date.parse('2026-10-05T23:30:00Z'), 60, true),
    'Meeting: 2026-10-05 23:30 UTC (60 min)\nRiyadh: 2026-10-06 02:30 +03 – 03:30 +03\nUTC: 2026-10-05 23:30 UTC – 2026-10-06 00:30 UTC');
});
