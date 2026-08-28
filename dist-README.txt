cnc-ddraw-ra2
=============
https://github.com/gitTerebi/cnc-ddraw-ra2

A fork of cnc-ddraw built for Red Alert 2, Yuri's Revenge and Mental Omega.
NOT a general-purpose cnc-ddraw build.

Playing anything else? Use upstream instead, it supports far more games and
actually gets updates:  https://github.com/FunkyFr3sh/cnc-ddraw

Nearly all of this code is FunkyFr3sh's. See LICENSE, which is unchanged.
This fork is about 600 lines on top of it.


Install
-------
Copy ddraw.dll, ddraw.ini and the Shaders folder into your game folder, the
one with gamemd.exe / game.exe in it.

Mental Omega: also set fixchilds=5 in Resources\cnc-ddraw.ini. The MO client
copies that file over ddraw.ini every time you save settings, which puts the
value back to its own default and breaks the menus again.

To uninstall, delete ddraw.dll. Keep a backup if you had another one.


What this fork adds
-------------------
1. fixchilds=5   (the reason this fork exists)

   RA2 and Yuri's Revenge draw their menus as real Win32 dialogs, laid out in
   800x600 units. Windows hit-tests the buttons at those raw offsets however
   the renderer scales the picture, so upscaling moves the art but leaves the
   click targets in the corner.

   Upstream handles this by giving up the upscale whenever a child window
   exists. That is the safe answer across the many games it supports, and it
   is why the RA2 menu shows up unscaled in the top-left.

   fixchilds=5 keeps the upscale and moves the input instead: the dialog is
   made transparent to hit-testing, clicks and mouse moves are remapped into
   dialog space, and posted to the control actually under the cursor. A CBT
   hook catches dialogs created after startup.

   Stock cnc-ddraw ignores the value 5 and silently falls back to its default,
   so if your menus are misaligned you are not running this build.

2. Multi-pass shader chains

   shader= accepts a pipe-separated list, up to 8 passes:

     shader=Shaders\xbrz\4xbrz.glsl|Shaders\sharpen\fast-sharpen.glsl

   Upstream supports two passes only (.glsl plus .glsl.pass1). A single path
   still behaves exactly as upstream does.

3. Borderless maximized mouse offset

   The OpenGL y-align hack added a row unconditionally, which offset the
   cursor in borderless maximized windows that do not cover the screen. It
   now applies only when the render area really does cover the display.

4. Screenshot on demand

   WM_APP+120 makes the renderer take a screenshot, so a script can grab a
   frame without touching the keyboard.


Also worth having
-----------------
ra2-hwcursor-wasd replaces the game's software-blitted mouse cursor with a
real Windows one, and adds optional WASD map scrolling:
https://github.com/gitTerebi/ra2-hwcursor-wasd


RA2Video.exe
------------
Optional. A small renderer and resolution picker for ddraw.ini. Run it from
the game folder, pick a resolution and renderer, save.

Worth having because the Mental Omega client's own settings screen does not
know fixchilds=5 exists, and rewrites ddraw.ini when you use it. RA2Video
writes the [ddraw], [game], [gamemd], [ra2] and [ra2md] sections and leaves
fixchilds alone.

MO also validates the game resolution against real display modes, so a
non-standard value gets reset to 800x600 on the next launch. Stick to the
listed modes.


Files
-----
ddraw.dll     the renderer
ddraw.ini     trimmed to RA2/YR, fixchilds=5 already set
Shaders\      upstream's shader pack, unmodified
RA2Video.exe  renderer/resolution picker, optional
LICENSE       MIT, FunkyFr3sh

32-bit only, matching the game. Not affiliated with or endorsed by EA.
Ships no game content.
