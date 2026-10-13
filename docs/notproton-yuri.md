# RA2 / Yuri's Revenge on macOS Steam through NotProton

## Tested environment and source

- Native macOS Steam, with the Windows RA2/Yuri installation launched through NotProton.
- NotProton CrossOver 26.3.0.39832, Rosetta runner; Apple M1 Max.
- Source base: gitTerebi/cnc-ddraw-ra2 v1.1.0, commit `823fdd1feabec091ab14076181a4a6982a58166b`.
- Tested local DLL: clean MinGW-w64 build, `i686-w64-mingw32-gcc` 13.2.0.
- Tested DLL SHA-256: `25251269814b41fba6a719ba6e00f333e33ac78b99965ea15583f1dd14423c3a`.
- User confirmed successful enlarged menus and loading the same campaign save on 13 October 2026. This is one environment and one reported save-load test, not a general stability guarantee.

## Problem and investigation

The shipped Steam DirectDraw compatibility DLL caused the initial video-mode problem in the earlier Soju setup. Replacing it with cnc-ddraw and applying native DLL overrides allowed play. This fork's `fixchilds=5` enlarged menus and remapped their mouse input; standard `fixchilds=2` left menus small.

In Yuri's Revenge, selecting a campaign save with `fixchilds=5` hung. Wine logged `RtlpWaitForCriticalSection` timeouts. Reverting only Yuri's profiles to `fixchilds=2` allowed the same save to load. Saves were backed up and not altered.

A first attempt changed forwarded Static-control input from blocking `SendMessage` to queued `PostMessage`. The hang persisted; that change was reverted and is **not** included in this fork.

The successful change addresses window setup instead. The OpenGL render loop enumerated/subclassed menu windows and installed the child-input hook while holding `g_ddraw.cs`. Cross-thread window operations under Wine can wait for the GUI thread while that thread needs drawing work. This suggested a lock-order cycle, but a fully symbolized trace proving each edge was not obtained.

With `async_child_setup=true` and `fixchilds=5`, the renderer posts `WM_APP+121` to the game window. An atomic pending flag coalesces requests. The window procedure performs hook installation and child-window setup on the owning GUI thread and clears the pending flag. This avoids making those window operations from inside the renderer's drawing-lock region. The original input-forwarding code remains intact.

The option defaults to false, and the tested setup enables it only for `[gamemd]` and `[ra2md]`. Direct3D9 and GDI do not implement this opt-in scheduling path.

## Installation and backups

Close both games before replacing the shared renderer. Back up `ddraw.dll`, `ddraw.ini`, `RA2.INI`, `RA2MD.INI`, and campaign save files first. Preserve the original DLL rather than deleting it. Install the built `ddraw.dll` beside `game.exe` and `gamemd.exe`.

Use the snippets in `examples/notproton-ra2-yuri.ini` to merge settings into your existing files; the example is **not** a complete replacement INI. Keep game-specific options, audio settings, and the renderer's other profiles.

The final tested gameplay resolution was **1280×800**, matching a 16:10 laptop display and keeping the HUD readable. An earlier 1920×1080 setup was selectable but made the HUD too small. Keep fullscreen desktop scaling and aspect-ratio preservation enabled. The old fixed 3840×2160 renderer dimensions were inherited; fullscreen uses the actual desktop dimensions, so those numbers are not required in the example.

In both game INIs, enable `AllowHiResModes=yes`; advertise `1280x800` through `inject_resolution` in the corresponding renderer profiles. Disabling `[Intro] Play` skips the intro. This does not skip scripted in-mission effects.

## Wine prefix and native DLL overrides

Apply settings to the prefix actually used by Steam for app **2229850**, commonly:

```text
<Steam library>/steamapps/compatdata/2229850/pfx
```

Do not apply them to another Soju, Battle.net, or game prefix. Use that prefix's selected Wine runtime; changing registry files while Wine is running can be overwritten by wineserver.

Add per-executable values under `HKCU\Software\Wine\AppDefaults\<exe>\DllOverrides`:

| Executables | Library | Value |
| --- | --- | --- |
| game.exe, Ra2.exe, gamemd.exe, RA2MD.exe | ddraw | native,builtin |
| game.exe, Ra2.exe, gamemd.exe, RA2MD.exe | wsock32 | native |

The Steam installation already supplied `wsock32.dll` (IPXEmu). The native override uses that shipped LAN library; no replacement was needed. Preserve NotProton's own Steam bridge overrides.

## DPI and Retina

The session retained the user's requested 192 DPI:

```text
HKCU\Control Panel\Desktop: LogPixels = DWORD 192
HKCU\Software\Wine\Fonts: LogPixels = DWORD 192
HKCU\Software\Wine\Mac Driver: RetinaMode = string y
```

Set the Desktop value as well as Fonts; changing Fonts alone did not persist in the earlier setup. DPI and Retina are separate settings. These prefix-wide values affect both RA2 and Yuri, and 192 DPI is not required by the code fix.

The installed NotProton launch script resets Retina mode every launch unless `NOTPROTON_RETINA=1` is present. The RA2/Yuri Steam launch option used was:

```text
NOTPROTON_RETINA=1 %command%
```

Retina/DPI settings can influence menu sizing and rendering. Earlier reports of apparent double scaling were not conclusively diagnosed; this fork does not claim to fix every scaling issue.

## Building the DLL

Install a 32-bit MinGW-w64 compiler, its Windows resource compiler, and make. From the repository root:

```sh
make clean
make -j4 CC=i686-w64-mingw32-gcc WINDRES=i686-w64-mingw32-windres
file ddraw.dll
i686-w64-mingw32-objdump -p ddraw.dll
shasum -a 256 ddraw.dll
```

The output must be a PE32 **i386** DLL; a 64-bit DLL cannot be used by these games. The clean build succeeded locally. GCC emitted existing `strncpy` truncation warnings in `render_ogl.c`; no new build errors remained. A rebuild can have a different checksum because compiler versions, timestamps, and generated Git metadata affect the binary.

The upstream MSBuild route remains available, but this modification was tested with MinGW rather than MSVC.

## Verification and recovery

1. Launch Yuri's Revenge from native Steam through the selected NotProton tool.
2. Verify enlarged menus and aligned button clicks.
3. Select and load the same existing campaign save that previously hung.
4. Confirm gameplay remains at the selected resolution.

For a configuration fallback, close both games and set `fixchilds=2` in `[gamemd]` and `[ra2md]`. This loaded the campaign successfully in testing, but gives smaller menus. To undo the code change, restore the backed-up DLL and INI together while both games are closed. Never overwrite saves as part of a renderer rollback.

## Remaining limitations

- The slow time-machine effect in the first Allied mission was investigated but **not fixed or conclusively diagnosed**.
- Disabling `VideoBackBuffer` was considered, but was not applied or verified during this session.
- The precise deadlock mechanism remains a supported hypothesis rather than a complete debugger proof.
- Long play sessions, repeated loading/saving, other Wine runners, native Windows and Mental Omega need further testing.
- No upstream pull request has been submitted as part of preserving this personal fork.
