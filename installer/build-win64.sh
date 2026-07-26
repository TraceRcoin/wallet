#!/usr/bin/env bash
# Cross-compile Tracercoin Core Win64 binaries on the Linux build droplet.
# Detached long-running job. Progress -> /root/win64-build.log ; stage markers -> /root/win64-build.stage
set -x
# Self-log with a plain redirect (reliable under systemd-run / any launcher).
exec >> /root/win64-build.log 2>&1
stage(){ echo "$1" > /root/win64-build.stage; echo "===== STAGE: $1 ($(date -u +%H:%M:%S)) ====="; }

REPO=/root/tracercoin
JOBS=$(nproc)

stage "apt: install mingw + build deps"
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y build-essential g++-mingw-w64-x86-64 mingw-w64 \
  autoconf automake libtool pkg-config bsdmainutils curl git python3 zip unzip dos2unix \
  cmake patch bison xsltproc || { stage "FAIL apt"; exit 1; }

stage "normalize CRLF line endings (repo was checked out with Windows line endings)"
# config.guess/config.sub/*.sh with CRLF break exec ('/bin/sh^M: file not found'); autoconf inputs too.
find "$REPO" -type f \( -name "*.sh" -o -name "config.guess" -o -name "config.sub" \
  -o -name "*.m4" -o -name "*.ac" -o -name "*.in" -o -name "*.mk" -o -name "Makefile*" \) \
  -print0 | xargs -0 dos2unix -q 2>/dev/null || true
chmod +x "$REPO/depends/config.guess" "$REPO/depends/config.sub" "$REPO/autogen.sh" 2>/dev/null || true

stage "select posix mingw threads"
update-alternatives --set x86_64-w64-mingw32-gcc /usr/bin/x86_64-w64-mingw32-gcc-posix || true
update-alternatives --set x86_64-w64-mingw32-g++ /usr/bin/x86_64-w64-mingw32-g++-posix || true

cd "$REPO" || { stage "FAIL no repo"; exit 1; }

stage "build depends (Qt/Boost/BDB for mingw) — LONG"
make -C depends HOST=x86_64-w64-mingw32 -j"$JOBS" || { stage "FAIL depends"; exit 1; }

stage "autogen + configure"
./autogen.sh || { stage "FAIL autogen"; exit 1; }
CONFIG_SITE="$REPO/depends/x86_64-w64-mingw32/share/config.site" \
  ./configure --prefix=/ --disable-tests --disable-bench --with-incompatible-bdb \
  || { stage "FAIL configure"; exit 1; }

stage "make — LONG"
make -j"$JOBS" || { stage "FAIL make"; exit 1; }

stage "collect + normalize exe names"
OUT=/root/win64-release
rm -rf "$OUT"; mkdir -p "$OUT"
cd "$REPO/src"
for f in qt/*-qt.exe;   do [ -f "$f" ] && cp "$f" "$OUT/tracercoin-qt.exe"; done
for f in *d.exe;        do [ -f "$f" ] && cp "$f" "$OUT/tracercoind.exe"; done
for f in *-cli.exe;     do [ -f "$f" ] && cp "$f" "$OUT/tracercoin-cli.exe"; done
for f in *-tx.exe;      do [ -f "$f" ] && cp "$f" "$OUT/tracercoin-tx.exe"; done
for f in *-wallet.exe;  do [ -f "$f" ] && cp "$f" "$OUT/tracercoin-wallet.exe"; done
# strip to shrink
x86_64-w64-mingw32-strip "$OUT"/*.exe 2>/dev/null || true
ls -la "$OUT"
stage "DONE ($(ls "$OUT"/*.exe 2>/dev/null | wc -l) exes)"
