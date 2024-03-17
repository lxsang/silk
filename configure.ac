# initialise autoconf and set up some basic information about the program we’re packaging
AC_INIT([silk], [0.2.0], [xsang.le@gmail.com])

# We’re going to use automake for this project
# [subdir-objects] if needed
AM_INIT_AUTOMAKE([subdir-objects])

# dependencies
# C compiler
AC_PROG_CC
# libtool for linking
AC_PROG_LIBTOOL


# check if sqlite3 header exists
has_sqlite=no
AC_CHECK_HEADER([sqlite3.h],[
    AC_DEFINE([USE_DB], [1],[Use sqlite3])
    has_sqlite=yes
    # check if the library exists
],[])
AC_CHECK_LIB([sqlite3],[sqlite3_open],[],[
    if test "$has_sqlite" = "yes"; then
        AC_MSG_ERROR([Unable to find sqlite3 shared library])
    fi
])

# check for lm
AC_CHECK_LIB([m],[cos],[],[
    AC_MSG_ERROR([unable to find libm])
])

# check for libreadline
#AC_CHECK_HEADER([readline/readline.h],[],[
#    AC_MSG_ERROR([unable to find libreadline headers])
#])

#AC_CHECK_LIB([readline],[read_history],[],[
#    AC_MSG_ERROR([unable to find libreadline])
#])

AC_DEFINE([_GNU_SOURCE], [1],[Use GNU source])
# AC_CANONICAL_HOST is needed to access the 'host_os' variable    

AC_CANONICAL_HOST
build_linux=no
build_windows=no
build_mac=no
# Detect the target system
case "${host_os}" in
    linux*)
        AC_DEFINE([LINUX], [1],[Linux system])
        build_linux=yes
        ;;
    darwin*)
        build_mac=yes
        AC_DEFINE([MACOS], [1],[MacOS system])
        ;;
    *)
        AC_MSG_ERROR(["OS $host_os is not supported"])
        ;;
esac

if test "$build_linux" = "yes"; then
    AC_CHECK_LIB([crypt],[crypt],[],[
        AC_MSG_ERROR([unable to find libcrypt])
    ])
fi

# case for window:
# cygwin*|mingw*)
#    build_windows=yes
#    ;;
# Pass the conditionals to automake
AM_CONDITIONAL([HAS_DB], [test "$has_sqlite" = "yes"])
AM_CONDITIONAL([LINUX], [test "$build_linux" = "yes"])
AM_CONDITIONAL([WINDOWS], [test "$build_windows" = "yes"])
AM_CONDITIONAL([OSX], [test "$build_mac" = "yes"])
# find all config files
AC_CONFIG_FILES([
    Makefile 
    modules/Makefile
])

# AC_SUBST([my_CPPFLAGS]) pass my_CPPFLAGS to the makefile.am
# output the script:
AC_OUTPUT
