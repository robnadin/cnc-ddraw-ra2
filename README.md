# cnc-ddraw-ra2

**A fork of [cnc-ddraw](https://github.com/FunkyFr3sh/cnc-ddraw) built for Red Alert 2
and Yuri's Revenge.** Not a general-purpose cnc-ddraw build.

If you play anything other than RA2 / YR / Mental Omega, **use
[upstream cnc-ddraw](https://github.com/FunkyFr3sh/cnc-ddraw) instead.** It supports far
more games, gets updates, and has actual testing behind it. This fork exists only
because RA2's menus needed something upstream deliberately does not do.

## What this fork adds

### `fixchilds=5` — menus stay clickable when upscaled

The reason this fork exists.

RA2 and Yuri's Revenge draw their menus as **real Win32 dialogs** (`#32770` with real
`Button` controls), laid out in game-resolution units. Windows hit-tests those buttons at
raw 800x600 offsets no matter how the renderer scales the picture, so upscaling moves the
art but leaves the click targets in the corner.

Upstream's `fixchilds` modes handle this by giving up the upscale whenever a child window
exists (`fixchilds=2` discards the viewport it just computed). That is the safe answer for
the many games it supports, and it is why the RA2 menu turns up unscaled in the top-left.

`fixchilds=5` keeps the upscale and moves the input instead. It marks the dialog
transparent to hit-testing, remaps clicks and mouse moves from screen space into dialog
space, and posts them to the control actually under the cursor, with `BM_SETSTATE` /
`BM_CLICK` so buttons still light up and press. The dialog layout is never touched —
resizing the dialogs is a dead end.

```ini
fixchilds=5
```

Set it in **both** `ddraw.ini` and `Resources\cnc-ddraw.ini`. The Mental Omega client
copies its bundled ini over `ddraw.ini` whenever you save settings, and its settings
screen does not know this value exists.

**Stock cnc-ddraw ignores `fixchilds=5` and silently falls back to its default**, so an
unpatched `ddraw.dll` reverts to broken click targets rather than failing loudly. If the
menus are misaligned, check you are actually running this build.

### Multi-pass shader chains

Upstream supports two shader passes. This fork accepts a `|`-separated chain and runs the
middle stages into intermediate FBOs, up to 6 of them:

```ini
shader=Shaders\xbrz\5xbrz.glsl|Shaders\sharpen\fast-sharpen.glsl|Shaders\crt\crt-lottes.glsl
```

A single path still behaves exactly as upstream, including the `.pass1` convention.

### Borderless maximized mouse offset

The OpenGL renderer's y-alignment hack added a row unconditionally, which offset the
cursor in borderless maximized windows that do not cover the screen. It now applies only
when the render target actually covers the display.

### Screenshot-on-demand

`WM_APP+120` makes the renderer take a screenshot, so an external script can grab a frame
without touching the keyboard. `tools/ra2shot.ps1` is the driver.

## Install

Download the zip from [Releases](../../releases) and drop `ddraw.dll`, `ddraw.ini` and
the `Shaders` folder into your game folder (the one with `gamemd.exe` / `game.exe`).
Then set `fixchilds=5` as described above.

Pairs well with
[ra2-hwcursor-wasd](https://github.com/gitTerebi/ra2-hwcursor-wasd), which replaces the
software-blitted mouse cursor with a real Windows one.

## Build

```
msbuild cnc-ddraw.vcxproj /p:Configuration=Release /p:Platform=Win32 /p:PlatformToolset=v143
```

Output is `bin\Release\ddraw.dll`. Upstream's `build.cmd` wants a `make` that is not
present here; MSBuild is the working path.

## Licence and credit

MIT, same as upstream. **Nearly all of this code is
[FunkyFr3sh's](https://github.com/FunkyFr3sh/cnc-ddraw)** — see `LICENSE`, which is
unchanged. This fork is about 600 lines on top of it.

Not affiliated with or endorsed by EA. Ships no game content.
