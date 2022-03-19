#!/bin/sh
#
# pdfview.sh - displays the text in a PDF; relies on pdftotext from
#              xpdf (https://www.xpdfreader.com/pdftotext-man.html)
#              or poppler (https://github.com/freedesktop/poppler) 
# Copyright (c) 2022 Sriranga Veeraraghavan <ranga@calalum.org>. All 
# rights reserved.  See LICENSE.txt.

# default columns to for wrapping

COLS=75

# default programs

PGM_PDF2TXT=pdftotext
PGM_PDF2TXT_OPTS="-layout -nopgbrk"
PGM_FMT=fmt
PGM_FMT_OPTS="-s"
PGM_FOLD=fold
PGM_FOLD_OPTS="-s"

# global variables

FILE=
FORMATTER=
FORMATTER_OPTS=

# global functions

printUsage()
{
   echo "Usage: $0 [-c cols] [file]" 1>&2;
}

printError()
{
   echo "ERROR: $@" 1>&2;
}

# main

# check if the first argument is -c, and if so check
# if a valid number of columns were specified

if [ X"$1" = X"-c" ] ; then
   shift ; 
   if [ X"$1" = "X" ] ; then 
      printUsage;
      exit 1;
   fi
   if [ "$1" -eq "$1" > /dev/null 2>&1 ] ; then
      COLS="$1" ;
      shift;
   else
      printError "'$1' not a number."
      exit 1;
   fi
fi

# check to see if a file is provided

if [ X"$1" = "X" ] ; then
   printUsage;
   exit 1;
fi

FILE="$1"

if [ ! -r "$FILE" ] ; then 
   printError "'$FILE' does not exist, or is not readable." ;
   exit 1;
fi

# check to see if pdftotext is available

type "$PGM_PDF2TXT" > /dev/null 2>&1
if [ $? != 0 ] ; then
   printError "$PGM_PDF2TXT not found." ;
   exit 1;
fi

# determine which formatting program to use

if type "$PGM_FMT" > /dev/null 2>&1 ; then
   FORMATTER="$PGM_FMT" ; 
   FORMATTER_OPTS="$PGM_FMT_OPTS -w $COLS" ;
elif type "$PGM_FOLD" > /dev/null 2>&1 ; then
   FORMATTER="$PGM_FOLD" ;
   FORMATTER_OPTS="$PGM_FOLD_OPTS -w $COLS" ;
fi

# if a formatter is available, post process the output
# of pdftotext with it

if [ X"$FORMATTER" != "X" ] ; then
      "$PGM_PDF2TXT" $PGM_PDF2TXT_OPTS "$FILE" - | \
      LC_ALL=C "$FORMATTER" $FORMATTER_OPTS 
else
      "$PGM_PDF2TXT" $PGM_PDF2TXT_OPTS "$FILE" -
fi

exit $?

