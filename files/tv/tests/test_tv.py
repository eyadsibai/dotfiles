"""Offline regression tests: python3 -B -m unittest discover -s tests -v."""

import contextlib
import io
import json
import os
from pathlib import Path
import runpy
import shutil
import socket
import subprocess
import sys
import tempfile
import time
import unittest
from unittest.mock import patch
import wave


ROOT = Path(__file__).resolve().parents[1]
CHECK = ROOT / ".local/bin/tv-check"
TV = ROOT / ".local/bin/tv"
LUA = ROOT / ".config/mpv/tv/tv.lua"


class Fixture(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="tv-test-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.home = self.root / "home"
        self.home.mkdir()
        self.state = self.root / "state" / "tv"
        self.config = self.root / "config" / "tv"
        self.config.mkdir(parents=True)
        self.playlist = self.config / "tv.m3u"
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.run_dir = self.root / "run"
        self.env = dict(os.environ, HOME=str(self.home), XDG_CONFIG_HOME=str(self.config.parent),
                        XDG_STATE_HOME=str(self.state.parent), XDG_RUNTIME_DIR=str(self.run_dir), TV_M3U="",
                        TV_FONT="",
                        PATH=str(self.bin) + os.pathsep + os.environ["PATH"], TV_TEST_DEAD="[]")
        self.write_playlist(self.playlist, ["A", "B", "C"])
        self.executable("ffprobe", f"#!{sys.executable}\n" + '''
import json, os, pathlib, sys, time
if marker := os.environ.get("TV_TEST_MARKER"):
    pathlib.Path(marker).touch()
    deadline = time.monotonic() + 10
    while not pathlib.Path(os.environ["TV_TEST_RELEASE"]).exists():
        if time.monotonic() > deadline:
            sys.exit(2)
        time.sleep(0.01)
if sys.argv[-1].rsplit("/", 1)[-1] in json.loads(os.environ["TV_TEST_DEAD"]):
    print("unavailable", file=sys.stderr)
    sys.exit(1)
print(json.dumps({"streams": [{"codec_type": "video", "codec_name": "h264", "width": 1280, "height": 720}]}))
''')

    def executable(self, name, text):
        path = self.bin / name
        path.write_text(text)
        path.chmod(0o755)

    def write_playlist(self, path, names):
        path.write_text("#EXTM3U\n" + "".join(
            f'#EXTINF:-1 group-title="Test",{name}\nhttps://example.invalid/{name}\n' for name in names))

    def urls(self, path):
        return [s for s in path.read_text().splitlines() if s and not s.startswith("#")]

    def check(self, *args, playlist=None, dead=(), expected=0):
        proc = subprocess.run(
            [sys.executable, str(CHECK), "-p", str(playlist or self.playlist), "--no-retry", "--json", *args],
            env=dict(self.env, TV_TEST_DEAD=json.dumps(dead)), capture_output=True, text=True, timeout=15, check=False)
        self.assertEqual(proc.returncode, expected, proc.stderr)
        return json.loads(proc.stdout)

    def load_checker(self):
        with patch.dict(os.environ, self.env, clear=True):
            return runpy.run_path(str(CHECK), run_name="tv_check_test")["main"].__globals__

    def invoke(self, module, *args):
        output, errors = io.StringIO(), io.StringIO()
        with patch.dict(os.environ, self.env, clear=True), \
                patch.object(sys, "argv", [str(CHECK), "-p", str(self.playlist), "--no-retry", "--json", *args]), \
                contextlib.redirect_stdout(output), contextlib.redirect_stderr(errors):
            return module["main"]()


class CheckerTests(Fixture):
    def setUp(self):
        super().setUp()
        self.playing = self.state / "playing.m3u"

    def names(self, path):
        return [url.rsplit("/", 1)[-1] for url in self.urls(path)]

    def sync(self, playlist=None):
        proc = subprocess.run([sys.executable, str(CHECK), "-p", str(playlist or self.playlist), "--sync"],
                              env=self.env, capture_output=True, text=True, timeout=15, check=False)
        self.assertEqual(proc.returncode, 0, proc.stderr)
        return Path(proc.stdout.strip())

    def test_prune_and_revive_require_two_runs_and_never_write_the_playlist(self):
        original = self.playlist.read_text().replace(
            "https://example.invalid/A", "#EXTVLCOPT:http-referrer=https://example.invalid/\nhttps://example.invalid/A")
        self.playlist.write_text(original)
        self.assertEqual(self.check("--prune", dead=["A"])["pruned"], [])
        result = self.check("--prune", dead=["A"])
        self.assertEqual(result["pruned"], ["https://example.invalid/A"])
        self.assertEqual(result["playing"], str(self.playing))
        self.assertEqual(self.names(self.playing), ["B", "C"])
        self.assertEqual(self.names(self.state / "offline.m3u"), ["A"])
        self.assertEqual(self.check("--revive")["revived"], [])
        self.assertEqual(self.check("--revive")["revived"], ["https://example.invalid/A"])
        # Back at its place in the playlist, with its headers.
        self.assertEqual(self.names(self.playing), ["A", "B", "C"])
        self.assertIn("#EXTVLCOPT:http-referrer=https://example.invalid/", self.playing.read_text())
        self.assertEqual(self.urls(self.state / "offline.m3u"), [])
        self.assertEqual(self.playlist.read_text(), original)

    def test_combined_prune_and_revive(self):
        self.check("--prune", "--prune-after=1", dead=["A"])
        result = self.check("--prune", "--prune-after=1", "--revive", "--revive-after=1", dead=["B"])
        self.assertEqual(result["pruned"], ["https://example.invalid/B"])
        self.assertEqual(result["revived"], ["https://example.invalid/A"])
        self.assertEqual(self.names(self.playing), ["A", "C"])
        self.assertEqual(self.names(self.state / "offline.m3u"), ["B"])

    def test_sync_picks_up_playlist_edits_and_keeps_pruned_channels_out(self):
        self.assertEqual(self.sync(), self.playing)
        self.assertEqual(self.names(self.playing), ["A", "B", "C"])
        self.check("--prune", "--prune-after=1", dead=["A"])
        self.write_playlist(self.playlist, ["A", "C", "Added"])
        self.sync()
        self.assertEqual(self.names(self.playing), ["C", "Added"])
        self.assertIn("Generated by tv-check", self.playing.read_text())

    def test_pruned_channels_removed_from_the_playlist_are_ignored(self):
        self.check("--prune", "--prune-after=1", dead=["A"])
        self.write_playlist(self.playlist, ["B", "C"])
        result = self.check("--revive", "--revive-after=1")
        self.assertEqual(result["offline"], [])
        self.assertEqual(result["revived"], [])
        self.assertEqual(self.names(self.playing), ["B", "C"])

    def test_custom_playlist_cannot_revive_default_playlist_channels(self):
        self.check("--prune", "--prune-after=1", dead=["A"])
        other = self.root / "other.m3u"
        self.write_playlist(other, ["Other", "A"])
        result = self.check("--revive", "--revive-after=1", playlist=other)
        self.assertEqual(result["revived"], [])
        self.assertEqual(self.names(Path(result["playing"])), ["Other", "A"])
        self.assertEqual(self.names(self.state / "offline.m3u"), ["A"])
        self.assertEqual(self.names(self.playing), ["B", "C"])

    def test_custom_archives_are_isolated_and_symlink_aliases_share_them(self):
        other = self.root / "other.m3u"
        self.write_playlist(other, ["D", "E", "F"])
        playing = Path(self.check("--prune", "--prune-after=1", playlist=other, dead=["D"])["playing"])
        self.assertEqual(playing.parent.parent, self.state / "playlists")
        self.assertEqual(self.names(playing), ["E", "F"])
        self.assertEqual(self.check("--revive", "--revive-after=1")["revived"], [])
        alias = self.root / "alias.m3u"
        alias.symlink_to(other)
        result = self.check("--revive", "--revive-after=1", playlist=alias)
        self.assertEqual(result["revived"], ["https://example.invalid/D"])
        self.assertEqual(self.names(playing), ["D", "E", "F"])
        self.assertTrue(alias.is_symlink())

    def test_probing_another_playlist_preserves_existing_health(self):
        self.check(dead=["A"])
        other = self.root / "other.m3u"
        self.write_playlist(other, ["Other"])
        self.check(playlist=other)
        health = json.loads((self.state / "health.json").read_text())
        self.assertEqual(health["https://example.invalid/A"]["fails"], 1)

    def test_existing_default_archive_works_with_stow_symlink(self):
        target = self.root / "stowed.m3u"
        self.write_playlist(self.playlist, ["A", "Archived", "B"])
        original = self.playlist.read_text()
        self.playlist.rename(target)
        self.playlist.symlink_to(target)
        self.state.mkdir(parents=True)
        self.write_playlist(self.state / "offline.m3u", ["Archived"])
        self.assertEqual(self.names(self.sync()), ["A", "B"])
        result = self.check("--revive", "--revive-after=1")
        self.assertEqual(result["revived"], ["https://example.invalid/Archived"])
        self.assertEqual(self.names(self.playing), ["A", "Archived", "B"])
        self.assertTrue(self.playlist.is_symlink())
        self.assertEqual(target.read_text(), original)

    def test_network_guard_and_protected_channels(self):
        self.assertEqual(self.check("--prune", "--prune-after=1", dead=["A", "B"], expected=1)["pruned"], [])
        self.assertEqual(self.names(self.playing), ["A", "B", "C"])
        self.write_playlist(self.playlist, ["A [Not 24/7]", "B", "C"])
        self.assertEqual(self.check("--prune", "--prune-after=1", dead=["A [Not 24/7]"])["pruned"], [])

    def test_overlapping_run_is_rejected_before_probing(self):
        marker, release = self.root / "started", self.root / "release"
        proc = subprocess.Popen(
            [sys.executable, str(CHECK), "-p", str(self.playlist), "--prune", "--prune-after=1", "--no-retry", "--json"],
            env=dict(self.env, TV_TEST_MARKER=str(marker), TV_TEST_RELEASE=str(release), TV_TEST_DEAD='["A"]'),
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        try:
            deadline = time.monotonic() + 5
            while not marker.exists() and proc.poll() is None and time.monotonic() < deadline:
                time.sleep(0.01)
            self.assertTrue(marker.exists(), "first checker did not reach probe")
            second = subprocess.run(
                [sys.executable, str(CHECK), "-p", str(self.playlist), "--prune", "--prune-after=1", "--no-retry"],
                env=dict(self.env, TV_TEST_DEAD='["B"]'), capture_output=True, text=True, timeout=5, check=False)
            self.assertNotEqual(second.returncode, 0)
            self.assertIn("already running", second.stderr)
            # The launcher's --sync doesn't wait for a whole check.
            self.assertEqual(self.names(self.sync()), ["A", "B", "C"])
        finally:
            release.touch()
            stdout, stderr = proc.communicate(timeout=15)
        self.assertEqual(proc.returncode, 0, stderr)
        self.assertEqual(json.loads(stdout)["pruned"], ["https://example.invalid/A"])
        self.assertEqual(self.names(self.playing), ["B", "C"])

    def edit_during_probe(self, module, edit):
        original_probe = module["run_probes"]

        def edit_then_probe(*args):
            edit()
            original_probe(*args)

        module["run_probes"] = edit_then_probe

    def test_playlist_edit_during_probe_is_kept(self):
        module = self.load_checker()
        self.edit_during_probe(module, lambda: self.write_playlist(self.playlist, ["A", "B", "C", "Added"]))
        self.env["TV_TEST_DEAD"] = '["A"]'
        self.assertEqual(self.invoke(module, "--prune", "--prune-after=1"), 0)
        self.assertEqual(self.names(self.playlist), ["A", "B", "C", "Added"])
        self.assertEqual(self.names(self.playing), ["B", "C", "Added"])

    def test_playlist_edit_during_probe_only_run_still_records_health(self):
        module = self.load_checker()
        self.edit_during_probe(module, lambda: self.write_playlist(self.playlist, ["A", "B", "C", "Added"]))
        self.env["TV_TEST_DEAD"] = '["A"]'
        self.assertEqual(self.invoke(module, "--dead", "--offline"), 0)
        health = json.loads((self.state / "health.json").read_text())
        self.assertEqual(health["https://example.invalid/A"]["fails"], 1)

    def test_manual_archive_edit_during_probe_is_not_overwritten(self):
        module = self.load_checker()
        self.edit_during_probe(module, lambda: self.write_playlist(self.state / "offline.m3u", ["B"]))
        self.env["TV_TEST_DEAD"] = '["A"]'
        self.assertNotEqual(self.invoke(module, "--prune", "--prune-after=1"), 0)
        self.assertEqual(self.names(self.state / "offline.m3u"), ["B"])

    def test_failed_offline_write_leaves_the_channel_list_alone(self):
        self.sync()
        module = self.load_checker()
        write = module["atomic_write"]

        def fail_offline(path, text):
            if path.name == "offline.m3u":
                raise OSError("simulated full disk")
            write(path, text)

        module["atomic_write"] = fail_offline
        self.env["TV_TEST_DEAD"] = '["A"]'
        self.assertNotEqual(self.invoke(module, "--prune", "--prune-after=1"), 0)
        self.assertEqual(self.names(self.playing), ["A", "B", "C"])

    def test_failed_channel_list_write_is_repaired_by_the_next_sync(self):
        self.sync()
        module = self.load_checker()
        write = module["atomic_write"]

        def fail_playing(path, text):
            if path.name == "playing.m3u":
                raise OSError("simulated full disk")
            write(path, text)

        module["atomic_write"] = fail_playing
        self.env["TV_TEST_DEAD"] = '["A"]'
        self.assertNotEqual(self.invoke(module, "--prune", "--prune-after=1"), 0)
        self.assertEqual(self.names(self.state / "offline.m3u"), ["A"])
        self.sync()
        self.assertEqual(self.names(self.playing), ["B", "C"])

    def test_resolved_channels_are_probed_through_their_signed_link(self):
        source = self.root / "signed.m3u"
        source.write_text("#EXTM3U\n#EXTINF:-1,R\nhttps://example.invalid/R?token=1\n")
        self.playlist.write_text(
            f'#EXTM3U\n#EXTINF:-1 tv-resolve="{source.as_uri()}" group-title="Test",R\nhttps://example.invalid/R\n'
            f'#EXTINF:-1 tv-resolve="{source.as_uri()}" group-title="Test",S\nhttps://example.invalid/S\n')
        # The fake ffprobe fails "R" but not "R?token=1", so R is live only if it was resolved.
        channels = {c["url"]: c for c in self.check(dead=["R"])["channels"]}
        self.assertTrue(channels["https://example.invalid/R"]["live"])
        self.assertFalse(channels["https://example.invalid/S"]["live"])
        self.assertIn("no signed link", channels["https://example.invalid/S"]["detail"])


class LauncherTests(Fixture):
    def setUp(self):
        super().setUp()
        self.executable("mpv", '#!/bin/sh\nprintf "%s\\n" "$@"\n')
        self.write_playlist(self.playlist, [str(n) for n in range(1, 13)])
        # Not installed unless a test installs it, whatever this machine has.
        self.uosc = self.root / "share/mpv/scripts/uosc"
        self.fonts = self.root / "share/mpv/fonts"
        self.mpv_config = self.config.parent / "mpv"
        self.env["TV_UOSC"] = str(self.uosc)

    def launch(self, *args):
        return subprocess.run([str(TV), *args], env=self.env, capture_output=True, text=True, timeout=5, check=False)

    def launch_args(self):
        proc = self.launch()
        self.assertEqual(proc.returncode, 0, proc.stderr)
        return proc.stdout.splitlines()

    def touch(self, path):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.touch()

    def test_installed_uosc_is_loaded_for_tv_with_its_fonts(self):
        self.touch(self.uosc / "main.lua")
        self.touch(self.fonts / "uosc_icons.otf")
        args = self.launch_args()
        for arg in [f"--script={self.uosc}", "--osc=no", "--osd-bar=no", f"--osd-fonts-dir={self.fonts}"]:
            self.assertIn(arg, args)

    def test_uosc_autoloaded_by_mpv_config_is_not_loaded_twice(self):
        self.touch(self.uosc / "main.lua")
        self.touch(self.fonts / "uosc_icons.otf")
        for script in ["uosc.lua", "uosc/main.lua"]:
            with self.subTest(script=script):
                shutil.rmtree(self.mpv_config, ignore_errors=True)
                self.touch(self.mpv_config / "scripts" / script)
                args = self.launch_args()
                self.assertFalse([a for a in args if a.startswith("--script=") or a.startswith("--osc")], args)
                # Its icon font is missing from the mpv config, so the package's is used.
                self.assertIn(f"--osd-fonts-dir={self.fonts}", args)
        self.touch(self.mpv_config / "fonts/uosc_icons.otf")
        self.assertFalse([a for a in self.launch_args() if a.startswith("--osd-fonts-dir=")])

    def test_without_uosc_mpv_keeps_its_own_osc(self):
        args = self.launch_args()
        self.assertFalse([a for a in args if a.startswith(("--script=", "--osc", "--osd-"))], args)

    def test_bar_shows_the_playing_channel_and_nothing_once_tv_is_gone(self):
        now = self.run_dir / "tv" / "now.json"
        now.parent.mkdir(parents=True)
        now.write_text(json.dumps({"pid": os.getpid(), "text": "󰔂 3 Film"}))
        proc = self.launch("--bar")
        self.assertEqual((proc.returncode, json.loads(proc.stdout)["text"]), (0, "󰔂 3 Film"), proc.stderr)
        gone = subprocess.Popen(["true"])
        gone.wait()
        now.write_text(json.dumps({"pid": gone.pid, "text": "stale"}))
        proc = self.launch("--bar")
        self.assertEqual((proc.returncode, proc.stdout), (0, ""), proc.stderr)

    def test_ctl_checks_its_action_and_needs_a_running_tv(self):
        proc = self.launch("--ctl", "menu")
        self.assertNotEqual(proc.returncode, 0)
        self.assertIn("isn't running", proc.stderr)
        proc = self.launch("--ctl", "explode")
        self.assertIn("usage: tv --ctl", proc.stderr)

    def test_player_gets_a_control_socket_and_the_chosen_font(self):
        self.env["TV_FONT"] = "Test Mono"
        args = self.launch_args()
        self.assertIn(f"--input-ipc-server={self.run_dir}/tv/mpv.sock", args)
        self.assertIn("--osd-font=Test Mono", args)

    def test_pip_opens_a_muted_corner_tv_with_its_own_socket(self):
        proc = self.launch("--pip", "3")
        self.assertEqual(proc.returncode, 0, proc.stderr)
        args = proc.stdout.splitlines()
        for arg in (f"--input-ipc-server={self.run_dir}/tv/pip.sock", "--wayland-app-id=mpv-tv-pip",
                    "--mute=yes", "--script-opts-append=tv-pip=yes", "--playlist-start=2"):
            self.assertIn(arg, args)

    def test_pip_switches_an_open_corner_tv_instead_of_starting_another(self):
        sock = self.run_dir / "tv" / "pip.sock"
        sock.parent.mkdir(parents=True)
        server = socket.socket(socket.AF_UNIX)
        server.bind(str(sock))
        server.listen(1)
        self.addCleanup(server.close)
        proc = self.launch("--pip", "5")
        self.assertEqual((proc.returncode, proc.stdout), (0, ""), proc.stderr)   # mpv not started
        conn, _ = server.accept()
        with conn:
            message = json.loads(conn.recv(4096))
        self.assertEqual(message, {"command": ["script-message", "tv-play", "5"]})

    def test_bar_pip_reads_the_corner_tvs_state(self):
        state = self.run_dir / "tv"
        state.mkdir(parents=True)
        (state / "pip.json").write_text(json.dumps({"pid": os.getpid(), "number": 12}))
        proc = self.launch("--bar", "--pip")
        self.assertEqual(json.loads(proc.stdout)["number"], 12, proc.stderr)
        self.assertEqual(self.launch("--bar").stdout, "")

    def test_leading_zero_numbers_are_decimal(self):
        for value, index in [("08", 7), ("09", 8), ("010", 9), ("00012", 11)]:
            with self.subTest(value=value):
                proc = self.launch(value)
                self.assertEqual(proc.returncode, 0, proc.stderr)
                self.assertEqual(proc.stderr, "")
                self.assertIn(f"--playlist-start={index}", proc.stdout.splitlines())

    def test_out_of_range_numbers_do_not_launch_player(self):
        for value in ["0", "000", "013", "999999999999999999999999999999"]:
            with self.subTest(value=value):
                proc = self.launch(value)
                self.assertNotEqual(proc.returncode, 0)
                self.assertEqual(proc.stdout, "")

    def test_pruned_channels_are_left_out_of_the_numbering(self):
        self.state.mkdir(parents=True)
        self.write_playlist(self.state / "offline.m3u", ["3"])
        proc = self.launch("3")
        self.assertEqual(proc.returncode, 0, proc.stderr)
        lines = proc.stdout.splitlines()
        self.assertIn("--playlist=" + str(self.state / "playing.m3u"), lines)
        self.assertIn("--playlist-start=2", lines)
        self.assertEqual(self.urls(self.state / "playing.m3u")[2], "https://example.invalid/4")
        listed = self.launch("--list").stdout.splitlines()
        self.assertEqual([line.split()[-1] for line in listed], [str(n) for n in range(1, 13) if n != 3])

    def test_resume_reads_xdg_state_directory(self):
        self.state.mkdir(parents=True)
        (self.state / "last").write_text("https://example.invalid/8\n")
        proc = self.launch()
        self.assertEqual(proc.returncode, 0, proc.stderr)
        self.assertIn("--playlist-start=7", proc.stdout.splitlines())


@unittest.skipUnless(shutil.which("mpv"), "mpv is needed for Lua integration tests")
class PlayerTests(Fixture):
    def setUp(self):
        super().setUp()
        self.audio = self.root / "audio.wav"
        with wave.open(str(self.audio), "wb") as output:
            output.setnchannels(1)
            output.setsampwidth(2)
            output.setframerate(8000)
            output.writeframes(bytes(1600))
        self.playlist.write_text(f"#EXTM3U\n#EXTINF:-1,Local\n{self.audio}\n")

    def play(self, options="", env=None, extra=()):
        return subprocess.run(
            ["mpv", "--no-config", "--vo=null", "--ao=null", "--msg-level=all=warn,tv=info", "--script=" + str(LUA),
             "--script-opts=tv-reload_on_eof=no" + options, "--playlist=" + str(self.playlist), *extra],
            env=env or self.env, capture_output=True, text=True, timeout=10, check=False)

    def test_channel_keys_are_bound_without_input_conf(self):
        second = self.root / "second.wav"
        shutil.copy(self.audio, second)
        self.playlist.write_text(f"#EXTM3U\n#EXTINF:-1,One\n{self.audio}\n#EXTINF:-1,Two\n{second}\n")
        probe = self.root / "probe.lua"
        probe.write_text("""
local pressed = false
mp.register_event('file-loaded', function()
    if pressed then return end
    pressed = true
    for _, b in ipairs(mp.get_property_native('input-bindings')) do
        if b.cmd:find('tv/', 1, true) then print('binding ' .. b.key .. ' ' .. b.cmd) end
    end
    mp.commandv('keypress', 'PGDWN')
end)
-- playlist-pos passes through -1 while switching, so wait for the new channel.
mp.observe_property('playlist-pos', 'number', function(_, pos)
    if pressed and pos == 1 then
        print('now at 1')
        mp.command('quit')
    end
end)
mp.add_timeout(5, function() mp.command('quit') end)
""")
        proc = self.play(extra=("--pause", "--script=" + str(probe), "--msg-level=all=warn,tv=info,probe=info"))
        self.assertEqual(proc.returncode, 0, proc.stderr)
        # "[probe] binding PGUP [nonscalable ]script-binding tv/tv-prev": mpv 0.37 has no "nonscalable".
        bound = {words[2]: words[-1] for words in map(str.split, proc.stdout.splitlines())
                 if len(words) > 3 and words[:2] == ["[probe]", "binding"]}
        for key, name in (("PGUP", "tv-prev"), ("PGDWN", "tv-next"), ("/", "tv-search"),
                          ("Shift+ENTER", "tv-search-alt"), ("-", "tv-volume-down"), ("+", "tv-volume-up"),
                          ("M", "tv-toggle-mute")):
            self.assertEqual(bound.get(key), f"tv/{name}", key)
        self.assertIn("now at 1", proc.stdout)

    def script(self, name, text):
        path = self.root / name
        path.write_text(text)
        return "--script=" + str(path)

    def open_channel_menu(self, *extra):
        """Plays the playlist and opens the channel menu the way the c key does. mpv idles
        after the short test file so the menu can open; the fake menu script quits it."""
        driver = self.script("driver.lua", "mp.register_event('file-loaded', function()\n"
                             "    mp.commandv('script-binding', 'tv/tv-channels')\nend)\n")
        proc = self.play(extra=["--idle=yes", driver, *extra])
        self.assertEqual(proc.returncode, 0, proc.stdout + proc.stderr)

    def fake_uosc(self, out):
        """A stand-in uosc that saves the menu it is asked to open, then quits mpv."""
        return self.script("uosc.lua", "mp.register_script_message('open-menu', function(json)\n"
                           f"    local f = io.open({json.dumps(str(out))}, 'w')\n"
                           "    f:write(json) f:close() mp.command('quit')\nend)\n")

    def test_channel_menu_goes_to_uosc_by_category(self):
        second = self.root / "audio2.wav"
        shutil.copy(self.audio, second)
        self.playlist.write_text(f'#EXTM3U\n#EXTINF:-1 group-title="IPTV - News",One (1080p)\n{self.audio}\n'
                                 f'#EXTINF:-1 group-title="English - Kids",Two [Geo-blocked]\n{second}\n')
        menu = self.root / "menu.json"
        self.open_channel_menu(self.fake_uosc(menu))
        data = json.loads(menu.read_text())
        groups = [(g["title"], g["hint"], [(c["title"], c["hint"]) for c in g["items"]]) for g in data["items"]]
        self.assertEqual(groups, [
            ("↺ Recent", "1", [("One", "News  ·  1")]),
            ("News", "1", [("One", "1")]),
            ("Kids & Family", "1", [("Two", "geo-blocked  ·  2")]),
        ])
        self.assertEqual(data["selected_index"], 2)   # the playing channel's category
        self.assertEqual(data["callback"], ["tv", "menu-event"])

    def test_star_from_the_menu_marks_and_lists_the_channel(self):
        url = str(self.audio)
        self.playlist.write_text(f'#EXTM3U\n#EXTINF:-1 group-title="IPTV - News",One\n{url}\n')
        menu = self.root / "menu.json"
        event = json.dumps({"type": "key", "key": "ctrl+s", "selected_item": {"value": url}})
        driver = self.script("star.lua", "mp.register_event('file-loaded', function()\n"
                             f"    mp.commandv('script-message-to', 'tv', 'menu-event', {json.dumps(event)})\n"
                             "    mp.commandv('script-binding', 'tv/tv-channels')\nend)\n")
        proc = self.play(extra=["--idle=yes", driver, self.fake_uosc(menu)])
        self.assertEqual(proc.returncode, 0, proc.stdout + proc.stderr)
        self.assertEqual((self.state / "favorites").read_text(), url + "\n")
        first = json.loads(menu.read_text())["items"][0]
        self.assertEqual((first["title"], [c["title"] for c in first["items"]]), ("★ Favorites", ["★ One"]))

    def test_now_json_is_written_while_playing_and_removed_on_quit(self):
        self.playlist.write_text(f'#EXTM3U\n#EXTINF:-1 group-title="English - Movies",Film (720p)\n{self.audio}\n')
        now = self.run_dir / "tv" / "now.json"
        probe = self.script("now.lua", "mp.register_event('file-loaded', function()\n"
                            "  mp.add_timeout(0.2, function()\n"
                            f"    local f = io.open({json.dumps(str(now))}) print('now ' .. f:read('*a')) f:close()\n"
                            "    mp.command('quit')\n  end)\nend)\n")
        proc = self.play(extra=["--idle=yes", probe, "--msg-level=all=warn,tv=info,now=info"])
        self.assertEqual(proc.returncode, 0, proc.stdout + proc.stderr)
        line = next(x for x in proc.stdout.splitlines() if x.startswith("[now] now "))
        data = json.loads(line.removeprefix("[now] now "))
        self.assertEqual((data["number"], data["name"], data["category"], data["language"]),
                         (1, "Film", "Movies", "English"))
        self.assertFalse(now.exists())

    def test_channel_menu_without_uosc_opens_mpv_playlist_picker(self):
        options = subprocess.run(["mpv", "--list-options"], capture_output=True, text=True, check=False).stdout
        if "--load-select " not in options:
            self.skipTest("mpv before 0.39 has no select.lua to fall back to")
        picked = self.root / "picked"
        self.open_channel_menu("--load-select=no",
                               self.script("select.lua", "mp.add_key_binding(nil, 'select-playlist', function()\n"
                                           f"    io.open({json.dumps(str(picked))}, 'w'):close()\n"
                                           "    mp.command('quit')\nend)\n"))
        self.assertTrue(picked.exists())

    def test_mute_messages_set_rather_than_toggle(self):
        # Binding names double as script messages: a key binding named tv-mute once
        # turned "mute the other TV" into a toggle, so a second "a" unmuted it.
        probe = self.script("mute.lua", "mp.register_event('file-loaded', function()\n"
                            "  mp.commandv('script-message', 'tv-mute')\n"
                            "  mp.commandv('script-message', 'tv-mute')\n"
                            "  mp.add_timeout(0.3, function()\n"
                            "    print('mute ' .. tostring(mp.get_property_bool('mute')))\n"
                            "    mp.commandv('script-message', 'tv-unmute')\n"
                            "    mp.commandv('script-message', 'tv-unmute')\n"
                            "    mp.add_timeout(0.3, function()\n"
                            "      print('mute ' .. tostring(mp.get_property_bool('mute'))) mp.command('quit')\n"
                            "    end)\n  end)\nend)\n")
        proc = self.play(extra=["--idle=yes", probe, "--msg-level=all=warn,tv=info,mute=info"])
        self.assertEqual(proc.returncode, 0, proc.stdout + proc.stderr)
        states = [x.split()[-1] for x in proc.stdout.splitlines() if x.startswith("[mute] mute ")]
        self.assertEqual(states, ["true", "false"])

    def test_corner_tv_leaves_the_main_tvs_state_alone(self):
        pip = self.run_dir / "tv" / "pip.json"
        probe = self.script("pip.lua", "mp.register_event('file-loaded', function()\n"
                            "  mp.add_timeout(0.2, function()\n"
                            f"    local f = io.open({json.dumps(str(pip))}) print('pip ' .. f:read('*a')) f:close()\n"
                            "    mp.command('quit')\n  end)\nend)\n")
        proc = self.play(",tv-pip=yes", extra=["--idle=yes", probe, "--msg-level=all=warn,tv=info,pip=info"])
        self.assertEqual(proc.returncode, 0, proc.stdout + proc.stderr)
        self.assertIn("[pip] pip {", proc.stdout)
        self.assertFalse((self.state / "last").exists())
        self.assertFalse((self.state / "recent").exists())
        self.assertFalse((self.run_dir / "tv" / "now.json").exists())
        self.assertFalse(pip.exists())   # removed on quit

    def test_remember_channel_uses_xdg_state(self):
        proc = self.play()
        self.assertEqual(proc.returncode, 0, proc.stderr)
        self.assertTrue((self.state / "last").is_file())
        self.assertEqual((self.state / "last").read_text(), str(self.audio) + "\n")
        self.assertFalse((self.home / ".local/state/tv/last").exists())

    def test_health_is_read_from_xdg_state(self):
        missing = str(self.root / "missing.wav")
        self.playlist.write_text(f"#EXTM3U\n#EXTINF:-1,Missing\n{missing}\n{self.audio}\n")
        self.state.mkdir(parents=True)
        (self.state / "health.json").write_text(json.dumps({missing: {"fails": 0}}))
        proc = self.play()
        self.assertIn("retrying once", proc.stdout + proc.stderr)
        # mpv can return 3 when an earlier playlist entry failed, even after playback succeeds.
        self.assertIn(proc.returncode, (0, 3), proc.stdout + proc.stderr)
        self.assertEqual((self.state / "last").read_text(), str(self.audio) + "\n")

    def test_resolved_channel_plays_signed_link_and_remembers_playlist_url(self):
        stale = f"{self.audio}?expired"
        source = self.root / "signed.m3u"
        source.write_text(f"#EXTM3U\n{self.audio}\n")
        self.playlist.write_text(f'#EXTM3U\n#EXTINF:-1 tv-resolve="{source.as_uri()}",Signed\n{stale}\n')
        proc = self.play()
        self.assertEqual(proc.returncode, 0, proc.stdout + proc.stderr)
        self.assertEqual((self.state / "last").read_text(), stale + "\n")

    def test_empty_xdg_state_falls_back_and_explicit_script_option_wins(self):
        proc = self.play(env=dict(self.env, XDG_STATE_HOME=""))
        self.assertEqual(proc.returncode, 0, proc.stderr)
        self.assertEqual((self.home / ".local/state/tv/last").read_text(), str(self.audio) + "\n")
        custom = self.root / "custom-last"
        proc = self.play(",tv-state_file=" + str(custom))
        self.assertEqual(proc.returncode, 0, proc.stderr)
        self.assertEqual(custom.read_text(), str(self.audio) + "\n")


if __name__ == "__main__":
    unittest.main()
