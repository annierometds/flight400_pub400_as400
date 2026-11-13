#!/QOpenSys/usr/bin/sh
# ---------------------------------------------------------------------------
# build.sh - build Flight400 into one of your PUB400 libraries
#
#   usage:  sh build.sh MYLIB            (source + compile + data)
#           sh build.sh MYLIB compile    (source + compile only)
#           sh build.sh MYLIB data       (reload data only)
#
# Run it on PUB400 over SSH (port 2222) from the folder that holds this file.
# ---------------------------------------------------------------------------
LIB=$(echo "$1" | tr '[:lower:]' '[:upper:]')
WHAT=${2:-all}
HERE=$(cd "$(dirname "$0")" && pwd)
SYS=/QOpenSys/usr/bin/system

if [ -z "$LIB" ]; then
  echo "usage: sh build.sh MYLIB [all|compile|data]"
  echo "Your PUB400 libraries are named after your user profile, e.g. ${LOGNAME}1"
  exit 1
fi

if ! $SYS "CHKOBJ OBJ(QSYS/$LIB) OBJTYPE(*LIB)" >/dev/null 2>&1; then
  echo "Library $LIB not found (or not yours). Pick one of your own PUB400 libraries."
  exit 1
fi

srctype() {
  case "$1" in
    rpg) echo RPG;; rpgle) echo RPGLE;; sqlrpgle) echo SQLRPGLE;;
    clp) echo CLP;; clle) echo CLLE;; cmd) echo CMD;; dspf) echo DSPF;;
    pf) echo PF;; lf) echo LF;; mnudds) echo MNUDDS;; mnucmd) echo MNUCMD;;
    sql) echo SQL;; *) echo TXT;;
  esac
}

showlog() {
  $SYS "CPYTOIMPF FROMFILE($LIB/FLBLOG) TOSTMF('$HERE/$1') MBROPT(*REPLACE) STMFCCSID(1208) RCDDLM(*LF) DTAFMT(*DLM) STRDLM(*NONE)" >/dev/null 2>&1
  if [ -f "$HERE/$1" ]; then
    grep -i '^FAILED' "$HERE/$1"
    tail -1 "$HERE/$1"
    echo "(full log: $HERE/$1)"
  else
    echo "Could not read $LIB/FLBLOG - see your job log."
  fi
}

if [ "$WHAT" = "all" ] || [ "$WHAT" = "compile" ]; then
  echo "== 1/3  Creating source files in $LIB and loading members"
  for dir in "$HERE"/src/*; do
    SF=$(basename "$dir")
    LEN=92; [ "$SF" = "QRPGLESRC" ] && LEN=112
    $SYS "CRTSRCPF FILE($LIB/$SF) RCDLEN($LEN) CCSID(37) TEXT('Flight400')" >/dev/null 2>&1
    for f in "$dir"/*; do
      b=$(basename "$f"); MBR=${b%.*}; EXT=${b##*.}
      if $SYS "CPYFRMSTMF FROMSTMF('$f') TOMBR('/QSYS.LIB/$LIB.LIB/$SF.FILE/$MBR.MBR') MBROPT(*REPLACE) STMFCCSID(1208) DBFCCSID(*FILE) ENDLINFMT(*ALL)" >/dev/null 2>&1; then
        $SYS "CHGPFM FILE($LIB/$SF) MBR($MBR) SRCTYPE($(srctype $EXT))" >/dev/null 2>&1
      else
        echo "   could not copy $SF/$MBR"
      fi
    done
    echo "   $SF done"
  done

  echo "== 2/3  Compiling the build program FLBUILD"
  $SYS "CRTBNDCL PGM($LIB/FLBUILD) SRCFILE($LIB/QCLPSRC) SRCMBR(FLBUILD) REPLACE(*YES)" || {
    echo "FLBUILD did not compile - check the messages above."; exit 1; }

  echo "== 3/3  Creating files, programs and menus (takes a few minutes)"
  $SYS "CALL PGM($LIB/FLBUILD) PARM('$LIB' 'COMPILE')" >/dev/null 2>&1
  showlog build-compile.log
fi

if [ "$WHAT" = "all" ] || [ "$WHAT" = "data" ]; then
  echo "== Loading seed data and generating FLIGHTS / CUSTOMERS (can take 10+ minutes)"
  $SYS "CALL PGM($LIB/FLBUILD) PARM('$LIB' 'DATA')" >/dev/null 2>&1
  showlog build-data.log
fi

echo
echo "Next: sign on with a 5250 session and run"
echo "   ADDLIBLE $LIB"
echo "   GO $LIB/FRSMAIN"
