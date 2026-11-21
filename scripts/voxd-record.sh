#!/usr/bin/env bash
#
# voxd-record.sh — toggle voxd dictation AND auto-resume media afterward.
#
# Why this exists:
#   `voxd --trigger-record` toggles recording (press to start, press again to
#   stop → transcribe → type). voxd itself never touches your media — but when
#   its microphone capture stream opens, the media player (Firefox/Chrome)
#   pauses itself, and because that's a real MPRIS pause (not a transparent
#   PipeWire cork) it does NOT auto-resume when the mic closes.
#
#   This wrapper snapshots which MPRIS players were Playing when recording
#   starts, then issues `playerctl play` to exactly those players once voxd's
#   mic capture stream disappears (i.e. recording stopped).
#
# Design:
#   - A lock dir makes the FIRST press (start) distinct from the SECOND (stop),
#     and guarantees exactly one background watcher per record cycle.
#   - The watcher waits for the capture stream to open, then to close, then
#     resumes — so media comes back the instant recording ends.
#
# Requires: playerctl (pacman -S playerctl). Degrades to a no-op resume if it's
# missing, so dictation itself is never broken.

set -u

RUNDIR="${XDG_RUNTIME_DIR:-/tmp}"
LOCKDIR="$RUNDIR/voxd-resume.lock"
SNAP="$RUNDIR/voxd-resume.players"

# True while a voxd (python) microphone capture stream is live. Idle baseline is
# zero recording streams, so this is unambiguous on this machine. If detection
# ever misses, widen the pattern below (e.g. add sounddevice|portaudio).
voxd_recording() {
    pactl list source-outputs 2>/dev/null | grep -qiE 'voxd|python'
}

# ---- background watcher mode ------------------------------------------------
if [ "${1:-}" = "--watch" ]; then
    # Wait for the capture stream to open (up to ~10s), then for it to close
    # (safety cap ~15 min so a stale lock always self-heals).
    for _ in $(seq 1 50);   do voxd_recording && break; sleep 0.2; done
    for _ in $(seq 1 4500); do voxd_recording || break; sleep 0.2; done

    # Recording is done — release the lock now so a fresh record cycle can start
    # even while we're still nursing playback back to life (below).
    rmdir "$LOCKDIR" 2>/dev/null || true

    # Bluetooth wrinkle: recording yanks the headset from A2DP (hi-fi playback,
    # no mic) into HFP (has a mic, no hi-fi). Switching back to A2DP afterward
    # glitches the stream and re-pauses the player ~2s AFTER the mic closes, so a
    # single resume doesn't stick. MPRIS Play() is a no-op on an already-playing
    # stream (it's Play, not Play/Pause — no toggle risk), so re-issue it every
    # 0.5s for ~8s to ride through the A2DP re-settle. Bail the instant a new
    # recording starts, so we never fight a fresh capture's intended pause.
    if command -v playerctl >/dev/null 2>&1 && [ -s "$SNAP" ]; then
        for _ in $(seq 1 16); do
            voxd_recording && break
            while read -r player; do
                [ -n "$player" ] && playerctl -p "$player" play 2>/dev/null || true
            done < "$SNAP"
            sleep 0.5
        done
    fi
    exit 0
fi

# ---- push-to-talk modes (hold key) -----------------------------------------
# --start only starts if idle; --stop only stops if recording. Keeps a
# press/release keybind pair from ever desyncing into "inverted" toggling.
MODE="${1:-}"
if [ "$MODE" = "--start" ] && [ -d "$LOCKDIR" ]; then exit 0; fi
if [ "$MODE" = "--stop" ]; then
    [ -d "$LOCKDIR" ] && voxd --trigger-record
    exit 0
fi

# ---- toggle press -----------------------------------------------------------
if mkdir "$LOCKDIR" 2>/dev/null; then
    # START: snapshot players that are Playing *now* (before the mic pauses
    # them), begin recording, then spawn the watcher to resume them later.
    : > "$SNAP"
    if command -v playerctl >/dev/null 2>&1; then
        playerctl -l 2>/dev/null | while read -r player; do
            [ "$(playerctl -p "$player" status 2>/dev/null)" = "Playing" ] \
                && printf '%s\n' "$player"
        done > "$SNAP"
    fi

    voxd --trigger-record
    setsid -f "$0" --watch >/dev/null 2>&1
else
    # STOP (a watcher is already mid-cycle): just toggle recording off; the
    # running watcher sees the stream close and resumes media.
    voxd --trigger-record
fi
