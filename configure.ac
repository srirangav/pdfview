dnl -*- Autoconf -*-
dnl Process this file with autoconf to produce a configure script.

AC_INIT([pdfview],[0.4.1],[ranga@calalum.org])

# We want to turn on warnings if we are using gcc and the user did
# not specify CFLAGS. The autoconf check for the C compiler sets the
# CFLAGS if gcc is used, so we will save it before we run that check.
#
# TODO: Enable caching of some results:
#       https://www.gnu.org/software/autoconf/manual/autoconf-2.67/html_node/Caching-Results.html
#

save_CFLAGS="$CFLAGS $OBJCFLAGS"

# use objective-c

AC_LANG_PUSH([Objective C])

# check for install

AC_PROG_INSTALL

CFLAGS="$save_CFLAGS $CFLAGS"

# check for source files

PGM_SRCS="pdfview.m"
AC_CONFIG_SRCDIR([$PGM_SRCS])

# Check basic types.

AC_C_CONST

# check for frameworks

LIBS="$LIBS -F /System/Library/PrivateFrameworks"

# check for AppKit

AC_MSG_CHECKING([for AppKit])
LIBS="$LIBS -framework AppKit"
AC_LINK_IFELSE([AC_LANG_PROGRAM([#import <AppKit/AppKit.h>], [
                [[NSFileManager defaultManager];]])
                ],[has_framework=1],[has_framework=0])
if test $has_framework = 0; then
  AC_MSG_ERROR([AppKit is required])
else
  AC_MSG_RESULT([yes])
fi

AC_MSG_CHECKING([for PDFKit])
LIBS="$LIBS -framework PDFKit"
AC_LINK_IFELSE([AC_LANG_PROGRAM([#import <PDFKit/PDFKit.h>], [
                [[[PDFDocument alloc] init];]])
                ],[has_framework=1],[has_framework=0])
if test $has_framework = 0; then
  AC_MSG_ERROR([AppKit is required])
else
  AC_MSG_RESULT([yes])
fi

# check for UTType

AC_MSG_CHECKING([for UTType])
SAVE_LIBS="$LIBS"
LIBS="$LIBS -framework UniformTypeIdentifiers"
AC_LINK_IFELSE([AC_LANG_PROGRAM([#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>], [
                [[UTType typeWithIdentifier: @"public.image"];]])
                ],[has_framework=1],[has_framework=0])
if test $has_framework = 0; then
    AC_MSG_RESULT([no])
    LIBS="$SAVE_LIBS"
else
    AC_MSG_RESULT([yes])
    CFLAGS="$CFLAGS -DHAVE_UTT"
fi

dnl TEST_AND_SET_CFLAG(flag, [program])
dnl
dnl This attempts to compile a program with a certain compiler flag.
dnl If no program is given, then the minimal program is compiled, and
dnl this tests just the validity of the compiler flag.
dnl
dnl based on: https://github.com/edrosten/autoconf_tutorial

define([TEST_AND_SET_CFLAG],[
    AC_MSG_CHECKING([if compiler flag $1 works])

    dnl Store the current CXXFLAGS
    save_CFLAGS="$OBJCFLAGS"

    dnl Append the flag of interest

    OBJCFLAGS="$OBJCFLAGS $1"

    dnl Create an M4 macro, "prog", which expands to a C program.
    dnl This should either be a default one or the one specified.
    dnl Note that macros are not local, but there is a stack so push
    dnl the definition on to the stack to prevent clobbering a definition
    dnl that might already exist.

    m4_if([$2],[],[pushdef(prog, [int main(){}])], [pushdef(prog, [$2])])

    flag_test=0

    dnl See if the compiler runs

    AC_COMPILE_IFELSE([AC_LANG_SOURCE([prog])], [flag_test=1],[flag_test=0])

    dnl De-clobber the "prog" macro

    popdef([prog])

    if test $flag_test = 1
    then
        AC_MSG_RESULT(yes)
    else
        AC_MSG_RESULT(no)
        dnl The flag doesn't work, so restore the old OBJCFLAGS
        OBJCFLAGS="$save_CFLAGS"
    fi
])

# test and set compiler flags
# based on:
# https://airbus-seclab.github.io/c-compiler-security/clang_compilation.html
# https://developers.redhat.com/articles/2022/06/02/use-compiler-flags-stack-protection-gcc-and-clang

TEST_AND_SET_CFLAG(-W)
TEST_AND_SET_CFLAG(-Wall)
TEST_AND_SET_CFLAG(-Wextra)
TEST_AND_SET_CFLAG(-Wpedantic)
TEST_AND_SET_CFLAG(-Werror)
#TEST_AND_SET_CFLAG(-Wformat=2)
#TEST_AND_SET_CFLAG(-Wformat-nonliteral)
TEST_AND_SET_CFLAG(-Wformat-overflow=2)
TEST_AND_SET_CFLAG(-Wformat-truncation=2)
TEST_AND_SET_CFLAG(-Wformat-security)
TEST_AND_SET_CFLAG(-Wformat-y2k)
TEST_AND_SET_CFLAG(-Wformat-signedness)
TEST_AND_SET_CFLAG(-Wtrampolines)
TEST_AND_SET_CFLAG(-Walloca)
TEST_AND_SET_CFLAG(-Wcast-qual)
TEST_AND_SET_CFLAG(-Wconversion)
TEST_AND_SET_CFLAG(-Wtraditional-conversion)
TEST_AND_SET_CFLAG(-Warith-conversion)
TEST_AND_SET_CFLAG(-Wstack-protector)
TEST_AND_SET_CFLAG(-Wstack-usage)
TEST_AND_SET_CFLAG(-Winfinite-recursion)
TEST_AND_SET_CFLAG(-Wnull-dereference)
TEST_AND_SET_CFLAG(-Wvla)
TEST_AND_SET_CFLAG(-Warray-bounds-pointer-arithmetic)
TEST_AND_SET_CFLAG(-Warray-bounds=2)
TEST_AND_SET_CFLAG(-Wimplicit-fallthrough)
TEST_AND_SET_CFLAG(-Wconditional-uninitialized)
TEST_AND_SET_CFLAG(-Wloop-analysis)
TEST_AND_SET_CFLAG(-Wshift-sign-overflow)
TEST_AND_SET_CFLAG(-Wshift-overflow=2)
TEST_AND_SET_CFLAG(-Wstringop-overflow=4)
TEST_AND_SET_CFLAG(-Wswitch-default)
TEST_AND_SET_CFLAG(-Wswitch-enum)
TEST_AND_SET_CFLAG(-Wtautological-constant-in-range-compare)
TEST_AND_SET_CFLAG(-Wcomma)
TEST_AND_SET_CFLAG(-Wassign-enum)
TEST_AND_SET_CFLAG(-Wbad-function-cast)
TEST_AND_SET_CFLAG(-Wfloat-equal)
TEST_AND_SET_CFLAG(-Wformat-type-confusion)
TEST_AND_SET_CFLAG(-Wpointer-arith)
TEST_AND_SET_CFLAG(-Widiomatic-parentheses)
TEST_AND_SET_CFLAG(-Wunreachable-code-aggressive)
TEST_AND_SET_CFLAG(-Wthread-safety)
TEST_AND_SET_CFLAG(-Wstrict-overflow=5)
TEST_AND_SET_CFLAG(-Wstrict-prototypes)
TEST_AND_SET_CFLAG(-Wmissing-declarations)
TEST_AND_SET_CFLAG(-Wmissing-prototypes)
TEST_AND_SET_CFLAG(-Wshadow)
TEST_AND_SET_CFLAG(-Wcast-align)
TEST_AND_SET_CFLAG(-Wjump-misses-init)
TEST_AND_SET_CFLAG(-Wunused)
TEST_AND_SET_CFLAG(-Wno-missing-braces)
TEST_AND_SET_CFLAG(-Werror=implicit-function-declaration)
TEST_AND_SET_CFLAG(-Wold-style-cast)
TEST_AND_SET_CFLAG(-Wlogical-op)
TEST_AND_SET_CFLAG(-Wduplicated-cond)
TEST_AND_SET_CFLAG(-Wduplicated-branches)
TEST_AND_SET_CFLAG(-Wundef)
TEST_AND_SET_CFLAG(-fstack-usage)
TEST_AND_SET_CFLAG(-fstack-protector-all)
TEST_AND_SET_CFLAG(-fstack-protector-strong)
TEST_AND_SET_CFLAG(-fstack-protector-explicit)
TEST_AND_SET_CFLAG(-mshstk)
TEST_AND_SET_CFLAG(-fsanitize=safe-stack)
# not supported on MacOSX
#TEST_AND_SET_CFLAG(-fsanitize=shadow-call-stack)
TEST_AND_SET_CFLAG(-fsanitize=cfi)
TEST_AND_SET_CFLAG(-fsanitize=memory)
TEST_AND_SET_CFLAG(-fsanitize=integer)
TEST_AND_SET_CFLAG(-fsanitize=address)
TEST_AND_SET_CFLAG(-fsanitize=thread)
TEST_AND_SET_CFLAG(-fsanitize=leak)
TEST_AND_SET_CFLAG(-fsanitize=undefined)
TEST_AND_SET_CFLAG(-fno-sanitize-recover=all)
TEST_AND_SET_CFLAG(-fcf-protection=full)
TEST_AND_SET_CFLAG(-fpic)
TEST_AND_SET_CFLAG(-fPIE)
TEST_AND_SET_CFLAG(-fstack-clash-protection)
TEST_AND_SET_CFLAG(-pedantic)
TEST_AND_SET_CFLAG(-pedantic-errors)
TEST_AND_SET_CFLAG(-D_FORTIFY_SOURCE=2)
TEST_AND_SET_CFLAG(-D_GLIBCXX_ASSERTIONS)
TEST_AND_SET_CFLAG(-fasynchronous-unwind-tables)
TEST_AND_SET_CFLAG(-fwrapv)
TEST_AND_SET_CFLAG(-flto)
TEST_AND_SET_CFLAG(-fsplit-stack)
TEST_AND_SET_CFLAG(-fstack-limit-register)
TEST_AND_SET_CFLAG(-fstack-limit-symbol)
TEST_AND_SET_CFLAG(-fno-stack-array)
TEST_AND_SET_CFLAG(-mbranch-protection=standard)

OBJCFLAGS="$OBJCFLAGS $CFLAGS"

dnl Process Makefile.in to create Makefile
AC_CONFIG_FILES([Makefile])
AC_SUBST([PGM_SRCS])
AC_OUTPUT

