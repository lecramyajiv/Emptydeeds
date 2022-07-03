#!/bin/bash
#$Id: checkpkg,v 1.42 2019/03/04 22:46:26 eha Exp eha $
#
# ---------------------------------------------------------------------------
#
# Check a Slackware package or a build log for defects and irregularities.
#
# Either pass the path to a Slackware package as single argument if you want
# to verify that the package sticks to Slackware standards,
# or else pass "-l /path/to/build.log" as argument if you want to examine
# that log file for build and packaging errors.
#
# Author: Eric Hameleers <alien@slackware.com>
# ---------------------------------------------------------------------------

# Be quite silent by default:
VERBOSE=0

# By default the scripts checks packages, not log files:
CHECKLOG=0

# Command line parameter processing:
while getopts "hl:v" Option
do
  case $Option in
    h ) echo "Parameters are:"
        echo " <packagefile>   : Check a package for flaws"
        echo "  -h             : This help text"
        echo "  -l <logfile|-> : Check a log (file or stdin) instead of a package"
        exit
        ;;
    l ) FILE="${OPTARG}"
        CHECKLOG=1
        ;;
    v ) let VERBOSE=($VERBOSE+1)
        ;;
    * ) echo "** You passed an illegal switch to the program!"
        echo "** Run '$0 -h' for more help."
        exit
        ;;   # DEFAULT
  esac
done

# End of option parsing.
shift $(($OPTIND - 1))
#  $1 now references the first non option item supplied on the command line
#  if one exists.
# ---------------------------------------------------------------------------

if [ -n "$1" ]; then
  FILE="$1"
fi

if [ -z "$FILE" ]; then
  echo "** You must supply a filename!"
  exit 1
elif [ "$FILE" = "-" ]; then
  echo  "** Reading input from STDIN"
elif [ ! -f "$FILE" ]; then
  echo  "** Can not open file '$FILE' for examination!"
  exit 1
fi

# Return a package name that has been stripped of the dirname portion
# and any of the valid extensions (only):
pkgbase() {
  PKGEXT=$(echo $1 | rev | cut -f 1 -d . | rev)
  case $PKGEXT in
  'tgz' )
    PKGRETURN=$(basename $1 .tgz)
    ;;
  'tbz' )
    PKGRETURN=$(basename $1 .tbz)
    ;;
  'tlz' )
    PKGRETURN=$(basename $1 .tlz)
    ;;
  'txz' )
    PKGRETURN=$(basename $1 .txz)
    ;;
  *)
    echo "++ Unsupported package extension (allowed are tgz,tbz,tlz,txz)."
    PKGRETURN=$(basename $1)
    ;;
  esac
  echo $PKGRETURN
}

check_log() {
  LOGFILE=$1
  grep -E -nT "aborted!|[[:space:]]too[[:space:]]old|FAIL|[[:space:]]hunk[[:space:]]ignored|[^A-Z]Error[[:space:]]|[^A-Z]ERROR[[:space:]]|Error:|error:|errors[[:space:]]occurred|parser[[:space:]]error|ved[[:space:]]symbol|ndefined[[:space:]]reference[[:space:]]to|ost[[:space:]]recent[[:space:]]call[[:space:]]first|ot[[:space:]]found|annot[[:space:]]find[[:space:]]-l|make:[[:space:]]\*\*\*[[:space:]]No[[:space:]]|kipping[[:space:]]patch|skipping[[:space:]]incompatible[[:space:]]|t[[:space:]]seem[[:space:]]to[[:space:]]find[[:space:]]a[[:space:]]patch|t[[:space:]]find[[:space:]]file[[:space:]]to[[:space:]]patch|[[:space:]]not[[:space:]]supported|^Usage:[[:space:]]|option[[:space:]]requires[[:space:]]|memory[[:space:]]exhausted|cannot[[:space:]]stat[[:space:]]|SlackBuild:[[:space:]]line|No[[:space:]]such[[:space:]]file|[Uu]nrecognised[[:space:]]xattr|[Uu]nknown[[:space:]]option|[Ss]egmentation[[:space:]]fault|unrecognized[[:space:]]options|unable[[:space:]]to[[:space:]]create[[:space:]]an[[:space:]]executable|space[[:space:]]left|No[[:space:]]rule[[:space:]]to[[:space:]]make[[:space:]]target|unfinished[[:space:]]jobs|[Tt]raceback[[:space:]]|[Ff]ailed[[:space:]]to[[:space:]]build" $LOGFILE
  grep "install " $LOGFILE | grep -v "checking for " | grep -v -E "(/tmp/|/tmp/build/|/tmp/SBo|/mnt/hd/build/)(package-|tmp)" | grep -E " /(usr|etc|var|home)/" | grep -v " ./"
}

check_pkg() {
  PKG=$1
  if [ -f $PKG ]; then
    unset PKGARCH PKGTOP PKGNONROOT PKGBADPERM PKGDESC PKGMAN PKGLOCAL PKGLIB
    unset PKGETC PKGINFO1 PKGINFO2 PKGMAN PKGMANGZ PKGSHDOC PKGLA
    unset PKGLOCAL PKGLIB PKGBIN PKGSBIN
    echo "++ Checking package '$(basename $PKG)' (no news is good news):"
    PKGBASE=$(pkgbase $PKG)
    PKGARCH=$(echo $PKGBASE |rev |cut -f2 -d- |rev)
    PKGSHORTNAME=$(echo $PKGBASE |rev |cut -f4- -d- |rev)
    # Count number of segments in the package basename:
    INDEX=1
    while [ ! "$(echo $PKGBASE | cut -f $INDEX -d -)" = "" ]; do
      INDEX=$(expr $INDEX + 1)
    done
    INDEX=$(expr $INDEX - 1) # don't include the null value
    # If we have less than four segments we have an invalid package name:
    if [ $INDEX -lt 4 ]; then
       echo "++ Package name not according to spec."
    else
      if ! echo $PKGARCH |grep -q -E "(x86_64|i?86|arm|fw|noarch)" ; then
        echo "++ Package ARCH not detected - potential problem in package name."
      fi
    fi
    if [ "$PKGARCH" = "x86_64" ]; then
      LIBDIRSUFFIX="64"
    else
      LIBDIRSUFFIX=""
    fi
    # Several checks on package content:
    TMP_PKGLST=$(mktemp -t checkpkg_XXXXXX)
    tar tvf $PKG > $TMP_PKGLST
    PKGTOP="$(cat $TMP_PKGLST | head -1 | grep -v "^drwxr-xr-x root/root")"
    [ -z "$PKGTOP" ] || echo -e "++ Top directory is wrong:\n$PKGTOP"
    PKGROOTFILES="$(cat $TMP_PKGLST |tr -s ' ' |cut -d' ' -f6- |cut -d/ -f1 |sort | uniq)"
    for ROOTFILE in $PKGROOTFILES ; do
      case $ROOTFILE in
      .|bin|boot|dev|etc|home|install|lib*|opt|run|sbin|srv|usr|var)
        ;;
      *)
        echo "++ File/directory not allowed in package root: $ROOTFILE" ;;
      esac
    done
    PKGNONROOT="$(cat $TMP_PKGLST | grep -v root/root)"
    [ -z "$PKGNONROOT" ] || echo -e "++ Files not owned by root:\n$PKGNONROOT"
    PKGBADPERM="$(cat $TMP_PKGLST | grep -- ---)"
    [ -z "$PKGBADPERM" ] || echo -e "++ Files with strange perms:\n$PKGBADPERM"
    TEMPDIR=$(mktemp -p /tmp -d checkpkg.XXXXXX)
    # We do not mention an absent doinst.sh but complain about slack-desc:
    tar -C $TEMPDIR -xf $PKG install/doinst.sh 2>/dev/null
    tar -C $TEMPDIR -xf $PKG install/slack-desc
    if [ $? -ne 0 ]; then
      echo "++ No slack-desc found."
    else
      PKGDESC=$(grep "^${PKGSHORTNAME}:" $TEMPDIR/install/slack-desc |wc -l)
      [ $PKGDESC -ne 11 ] && echo "++ slack-desc has $PKGDESC lines that start with '${PKGSHORTNAME}:' (should be 11)."
      BINLINK=$(grep 'cd usr/bin ; ln -sf ' $TEMPDIR/install/doinst.sh 2>/dev/null |wc -l)
      SBINLINK=$(grep 'cd usr/sbin ; ln -sf ' $TEMPDIR/install/doinst.sh 2>/dev/null |wc -l)
      if [ -n "$(grep "^${PKGSHORTNAME}:  *$" $TEMPDIR/install/slack-desc)" ]; then echo "++ slack-desc contains empty lines with spaces." ; fi
      DESCLONG=0
      cat $TEMPDIR/install/slack-desc | grep "^${PKGSHORTNAME}:" | while read LINE ; do if [ $(echo $LINE | sed "s/^${PKGSHORTNAME}//" |wc -c) -gt 80 ]; then DESCLONG=1 ; fi ;  done
      [ $DESCLONG -eq 1 ] && echo "++ slack-desc contains lines >80 characters."
    fi
    rm -rf $TEMPDIR
    PKGETC="$(cat $TMP_PKGLST | grep usr/etc)"
    [ -z "$PKGETC" ] || echo -e "++ etc directory '/usr/etc' found."
    PKGINFO1="$(cat $TMP_PKGLST | grep usr/info/dir)"
    [ -z "$PKGINFO1" ] || echo -e "++ info file '/usr/info/dir' found."
    PKGINFO2="$(cat $TMP_PKGLST | grep usr/share/info/dir)"
    [ -z "$PKGINFO2" ] || echo -e "++ info file '/usr/share/info/dir' found."
    PKGMAN="$(cat $TMP_PKGLST | grep usr/share/man)"
    [ -z "$PKGMAN" ] || echo -e "++ man directory '/usr/share/man' found."
    PKGMANGZ="$(cat $TMP_PKGLST | grep -E '^-.* usr/man' | grep -Ev '.gz$')"
    [ -z "$PKGMANGZ" ] || echo -e "++ Uncompressed man pages found."
    PKGSHDOC="$(cat $TMP_PKGLST | grep usr/share/doc/)"
    [ -z "$PKGSHDOC" ] || echo -e "++ Directory '/usr/share/doc/' found."
    PKGLA="$(cat $TMP_PKGLST | grep -E 'lib'${LIBDIRSUFFIX}'/[^/]*\.la$')"
    [ -z "$PKGLA" ] || echo -e "++ Libdir .la file(s) found."
    PKGLOCAL="$(cat $TMP_PKGLST | grep usr/local/)"
    [ -z "$PKGLOCAL" ] || echo -e "++ Directory '/usr/local/' found."
    PKGBIN="$(cat $TMP_PKGLST | grep -E " usr/bin/.*$" | wc -l)"
    if [ $PKGBIN -eq 1 ]; then
       echo -e "++ Empty directory '/usr/bin/' found."
       if [ $BINLINK -gt 0 ]; then
         echo "++ However doinst.sh installs symlinks in /usr/bin/ ."
       fi
    fi
    PKGSBIN="$(cat $TMP_PKGLST | grep -E " usr/sbin/.*$" | wc -l)"
    if [ $PKGSBIN -eq 1 ]; then
      echo -e "++ Empty directory '/usr/sbin/' found."
       if [ $SBINLINK -gt 0 ]; then
         echo "++ However doinst.sh installs symlinks in /usr/sbin/ ."
       fi
    fi

    # For 64bit only:
    if [ "$PKGARCH" = "x86_64" ]; then
      PKGLIB="$(cat $TMP_PKGLST | grep usr/lib/)"
      [ -z "$PKGLIB" ] || echo -e "++ Found '/usr/lib/' in 64bit package."
    fi

    # Cleanup:
    rm -f $TMP_PKGLST
  else
    echo "++ NO package '$(basename $PKG)' was found!"
  fi
}

# Check for anomalies:
if [ $CHECKLOG -eq 1 ]; then
  if [ "$FILE" = "-" ]; then
    echo "++ Checking log from STDIN (no news is good news):"
  else
    echo "++ Checking logfile '$(basename $FILE)' (no news is good news):"
  fi
  check_log "$FILE"
else
  check_pkg "$FILE"
fi
