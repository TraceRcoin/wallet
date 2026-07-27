# Reverse-engineering: litecoin-0.21.5.5-win64-setup.exe → Tracercoin installer

Source analyzed: `C:\Users\Quantumkid1\Downloads\litecoin-0.21.5.5-win64-setup.exe`
(19,121,080 bytes). Extracted tree: `C:\XTKRecall\tracercoin-installer\litecoin-extract\`.

## 1. What kind of installer it is
- **Nullsoft Scriptable Install System (NSIS)**, solid-LZMA compressed, MUI2 wizard,
  64-bit only. Confirmed via 7-Zip's NSIS handler (signature `Nullsoft Inst`).
- Extractable with 7-Zip (`7z x`), which recovers the full payload file tree. The
  embedded `uninstall.exe.nsis` is the **compiled** uninstaller (binary, not readable
  source) — so the human-readable build logic comes from the source template, not the
  exe. That template is `share/setup.nsi.in`, and Tracercoin already has it.

## 2. Payload layout the installer lays down
Installed under `%ProgramFiles%\Litecoin` (`$PROGRAMFILES64\Litecoin`):
```
<install dir>\
  litecoin-qt.exe        32,084,496   GUI wallet (root)
  COPYING.txt                 1,195   license (renamed from COPYING)
  readme.txt                    816   from doc/README_windows.txt
  uninstall.exe                       generated at install time
  daemon\
    litecoind.exe        12,705,792   full node daemon
    litecoin-cli.exe      1,974,784   RPC client
    litecoin-tx.exe       3,189,248   tx tool
    litecoin-wallet.exe   7,859,200   wallet tool
  doc\                                 recursive copy of source doc\ (minus Makefile*)
```
`$PLUGINSDIR` (nsDialogs.dll, StartMenu.dll, System.dll) is NSIS runtime scaffolding,
not shipped to the install dir.

## 3. What the installer DOES (from share/setup.nsi.in)
- **Pages:** Welcome → Directory → Start-Menu folder → Install → Finish (offers to
  launch the GUI). Uninstaller: Confirm → Uninstall.
- **Start-menu shortcuts:** main wallet; a **testnet** shortcut (`-testnet`); Uninstall.
- **Registry (HKCU):**
  - `SOFTWARE\<Name>` → `Path`, `StartMenuGroup`, `Components\Main=1`.
  - `...\Uninstall\<Name>` → DisplayName/Version/Publisher/URLInfoAbout/DisplayIcon/
    UninstallString + NoModify/NoRepair (Add-or-Remove-Programs entry).
- **Registry (HKCR):** a **URI protocol handler** so `litecoin:` links open the wallet
  (`URL Protocol`, DefaultIcon, `shell\open\command "<qt>" "%1"`).
- **.onInit** refuses to run on 32-bit Windows; sets 64-bit registry view.
- **Uninstaller** deletes the files/dirs, both shortcuts, the HKCR protocol key, and the
  HKCU keys; cleans `debug.log`/`db.log`; removes empty dirs.

## 4. How the exe is built (the pipeline)
1. Cross-compile the Win64 binaries (Gitian/guix or `depends` + `--host=x86_64-w64-mingw32`).
2. `configure` substitutes `share/setup.nsi.in` → `share/setup.nsi`, filling
   `@PACKAGE_NAME@`, `@BITCOIN_*_NAME@`, `@CLIENT_VERSION_*@`, `@PACKAGE_URL@`, etc.
3. `make deploy` runs **`makensis share/setup.nsi`** → `litecoin-0.21.5.5-win64-setup.exe`.

## 5. KEY FINDING — canonical source is already rebranded; C-drive copy is stale
There are TWO local source trees, and they are NOT the same:
- **`E:\Tracercoin\blockchain` — CANONICAL, already fully rebranded to Tracercoin.**
  `configure.ac`: `AC_INIT([Tracercoin Core], …, [tracercoin], [https://tracercoin.org/])`,
  all five `BITCOIN_*_NAME=tracercoin*`, `COPYRIGHT_HOLDERS_SUBSTITUTION = Tracercoin Core`,
  bug URL `github.com/Tracerfx123/blockchain/issues`. Newer (07/19), git repo with local
  work (build-docker.sh, doc/build-prerequisites.md, genesis outputs).
- **`C:\XTKRecall\tracercoin-core` — STALE snapshot, still Litecoin-branded** (git tag
  `v0.21.5.5`, 07/16). Do not build from this for a Tracercoin release; refresh it from E
  or treat as reference only.

So `configure.ac` rebranding is DONE in the canonical tree. The only thing autoconf
substitution could NOT fix was four hard-coded "Litecoin" literals in the template
`share/setup.nsi.in` (they aren't `@variables@`). **Those are now fixed (2026-07-22)** in
`E:\Tracercoin\blockchain\share\setup.nsi.in`:
- `InstallDir $PROGRAMFILES64\Litecoin` → `\Tracercoin`
- `DisplayIcon $INSTDIR\litecoin-qt.exe` → `$INSTDIR\@BITCOIN_GUI_NAME@@EXEEXT@`
- `"URL:Litecoin"` → `"URL:Tracercoin"`
- `$SMSTARTUP\Litecoin.lnk` → `$SMSTARTUP\Tracercoin.lnk`
Verified: no `litecoin` literals remain in that file. So a normal build from E now emits a
fully Tracercoin-branded installer automatically.

~~Still cosmetic-only leftover: `share/pixmaps` art~~ **✅ DONE (2026-07-26):** Tracercoin
branding art generated from the brand avatar (TFX emblem) by `make-brand-art.py` →
`brand\tracercoin.ico` (16–256 multi-res), `brand\nsis-wizard.bmp` (164×314),
`brand\nsis-header.bmp` (150×57). The standalone `tracercoin-setup.nsi` now points at
`${BRANDDIR}` for all icon/bitmap defines (no more `bitcoin.ico`), and the canonical
E-tree `share\pixmaps\{bitcoin.ico,nsis-wizard.bmp,nsis-header.bmp}` were overwritten with
the Tracercoin art so a normal `make deploy` emits a fully branded installer.

The standalone `tracercoin-setup.nsi` in this folder remains useful as a **package-only**
path (build an installer from pre-built, Tracercoin-renamed exes without the full autoconf
pipeline), but the canonical path is now just a normal `make deploy` from the E tree.

## 6. Deliverable in this folder
`tracercoin-setup.nsi` — the Tracercoin-branded, fully-resolved NSIS script (every
`@autoconf@` variable filled, all "Litecoin" leftovers corrected to Tracercoin, install
dir `Program Files\Tracercoin`, `tracercoin:` URI handler). Build with:
```
makensis tracercoin-setup.nsi
# or point at custom locations:
makensis /DSRCDIR=<tracercoin-core> /DRELEASE=<folder with built .exe files> tracercoin-setup.nsi
```

## 7. BLOCKER before an installer can actually be produced
There are **no Windows Tracercoin binaries yet** — `tracercoin-qt.exe` and the four
daemon tools must be cross-compiled first (the chain builds on the Linux droplet; see
[[project_tracercoin_build_droplet]]). Until those exist, `makensis` has nothing to
package. Path: build Win64 exes → drop into a `release\` folder → `makensis
tracercoin-setup.nsi`. `makensis` itself is not yet confirmed installed on this machine
(NSIS ships with `makensis.exe`; install NSIS or use the one bundled with the build env).

## Quick facts for reuse
- Tool to peek any NSIS installer: `"C:\Program Files\7-Zip\7z.exe" l|x <setup>.exe`.
- The readable build script is always the source `share/setup.nsi.in`, never the exe.
- Version is 0.21.5.5 (major.minor.revision.build = 0.21.5.5) per `configure.ac`.
