#!/bin/sh
# Build executables for Ada mode.
#    build.sh <other gprbuild options>
#    e.g. 'build.sh -j0' : use all available processors to compile
#         'build.sh -wn' : treat warnings as warnings.
#         'build.sh -vh' : Verbose output (high verbosity)
#
# See install.sh for install

# As of gnat pro 21, gnat_util is no longer provided or required
echo 'with "gnat_util"; abstract project check is end check;' > check.gpr
gprbuild -P check.gpr > /dev/null 2>&1
if test $? -eq 0 ; then
    HAVE_GNAT_UTIL=yes
else
    HAVE_GNAT_UTIL=no
fi

# support for libadalang is still experimental
args=`echo -DHAVE_LIBADALANG="no" -DELPA="yes" -DHAVE_GNAT_UTIL=$HAVE_GNAT_UTIL ada_mode_wisi_parse.gpr.gp ada_mode_wisi_parse.gpr`

echo "gnatprep " $args
gnatprep $args

if [ -d ../wisi-4.0.? ]; then
    WISI_DIR=`ls -d ../wisi-4.0.?`
fi

args=`echo -DELPA="yes" $WISI_DIR/wisi.gpr.gp $WISI_DIR/wisi.gpr`
echo "gnatprep " $args
gnatprep $args

# We don't add WISI_DIR to GPR_PROJECT_PATH because the user may have
# already set GPR_PROJECT_PATH.

# Allow running build.sh again, since it often fails the first time.
#  - Run gprclean, to allow changing compilers and other drastic things

gprclean -r -P ada_mode_wisi_parse.gpr -aP$WISI_DIR

gprbuild -p -j8 -P $WISI_DIR/wisi.gpr wisitoken-bnf-generate

# We generate the Ada LR1 parse table .txt file here, because it is too
# large to keep in ELPA. The code generated by wisitoken-bnf-generate
# is in ELPA, because it requires the re2c tool, which we don't expect
# users to have installed. The LR1 parse table for gpr is in the Ada
# code, so we don't need to generate that here.
echo "generate Ada LR1 parse table"
$WISI_DIR/wisitoken-bnf-generate --task_count 1 ada_annex_p.wy

gprbuild -p -j8 -P ada_mode_wisi_parse.gpr -aP $WISI_DIR "$@"

# end of file
