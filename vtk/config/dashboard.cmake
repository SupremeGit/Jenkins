# Tweaks for VTK Common Dashboard Script
#
# The main vtk_common.cmake script is checked out from git & copied to a build directory:
#    /data-ssd/data/development/src/vtk/build/dashboard/nightly/1/
# This script, 'dashboard.cmake', is placed alongside vtk_common.cmake
# It sets custom vars and then includes the public vtk_common cmake sctipt.
#
# Invoke manually or run a scheduled task (cron job) with a command line such as:
#   ctest -S /data-ssd/data/development/src/vtk/build/dashboard/nightly/1/dashboard.cmake -V

set(CTEST_SCRIPT_DIRECTORY ".")            #where to look for vtk_common.cmake
set(CTEST_CONFIGURATION_TYPE Debug)
set(CTEST_CMAKE_GENERATOR "Unix Makefiles")

set(CTEST_SITE        "$ENV{CTEST_DASHBOARD_SITE_NAME}")
set(CTEST_BUILD_NAME  "$ENV{CTEST_DASHBOARD_BUILD_NAME}")
set(CTEST_BUILD_FLAGS "$ENV{CTEST_DASHBOARD_BUILD_FLAGS}")
set(dashboard_no_test "$ENV{CTEST_DASHBOARD_NO_TEST}")
set(dashboard_model   "$ENV{CTEST_DASHBOARD_MODEL}")

#By default, source and build trees go in "../My Tests/" relative to your script location.
#Better locations:
#VTK git checkout goes under: CTEST_DASHBOARD_ROOT/dashboard_source_name
#Build goes under:            CTEST_DASHBOARD_ROOT/dashboard_binary_name
#Test Data goes under         CTEST_DASHBOARD_ROOT/dashboard_store_name

set(CTEST_DASHBOARD_ROOT  "$ENV{CTEST_DASHBOARD_ROOT}")         #Where to put source and build trees
set(dashboard_binary_name "$ENV{CTEST_DASHBOARD_BUILD_DIR}")    #Name of binary directory (VTK-build)
set(dashboard_source_name "$ENV{CTEST_DASHBOARD_VTK_GIT_DIR}")  #Name of source directory (VTK)
set(dashboard_store_name  "$ENV{CTEST_DASHBOARD_TESTDATA_DIR}") #Name of ExternalData store (Test-Data)
#set(dashboard_cache "buildconfig/CMakeCache-latest.txt")     #Initial CMakeCache.txt file content

#If CTEST_DASHBOARD_ROOT is not set explicitly above, then it gets set to:
#CTEST_DASHBOARD_ROOT "${CTEST_SCRIPT_DIRECTORY}/../${dashboard_root_name}
#set(dashboard_root_name "vtk")                                     #Change name of "My Tests" directory

#These look interesting:
# dashboard_do_superbuild   = True to do a superbuild dashboard.
# dashboard_git_url          = Custom git clone url
# dashboard_git_branch       = Custom remote branch to track
# dashboard_git_crlf         = Value of core.autocrlf for repository

#These are hardcoded into vtk_common.cmake, because "CTest delayed initialization is broken".
# will need to modify that script to change them:
#  set(CTEST_NIGHTLY_START_TIME "01:00:00 UTC")
#  set(CTEST_DROP_METHOD "http")
#  set(CTEST_DROP_SITE "open.cdash.org")
#  set(CTEST_DROP_LOCATION "/submit.php?project=VTK")
#  set(CTEST_DROP_SITE_CDASH TRUE)

#No good:
#set(CTEST_TEST_ARGS "CTEST_PARALLEL_LEVEL 4")  #No good.
#set(CTEST_TEST_ARGS "PARALLEL_LEVEL 4")        #No Good: ctest_test args (ex: PARALLEL_LEVEL 4)
#CMake Error at /data-ssd/data/development/src/vtk/build/dashboard/nightly/1/vtk_common.cmake:437 (ctest_test):
#  ctest_test called with unknown argument "PARALLEL_LEVEL 4".

#Custom vars are set, last thing we do is, include the rest:
include(${CTEST_SCRIPT_DIRECTORY}/vtk_common.cmake)

#################################################################
# The following variables may be set before including this script
# to configure it:
#
#   dashboard_model           = Nightly | Experimental | Continuous
#   dashboard_track           = Optional track to submit dashboard to
#   dashboard_branch_type     = master (default) | release
#   dashboard_disable_loop    = For continuous dashboards, disable loop.
#   dashboard_root_name       = Change name of "My Tests" directory
#   dashboard_source_name     = Name of source directory (VTK)
#   dashboard_binary_name     = Name of binary directory (VTK-build)
#   dashboard_cache           = Initial CMakeCache.txt file content
#   dashboard_cvs_tag         = CVS tag to checkout (ex: VTK-5-6)
#   dashboard_do_coverage     = True to enable coverage (ex: gcov)
#   dashboard_do_memcheck     = True to enable memcheck (ex: valgrind)
#   dashboard_do_superbuild   = True to do a superbuild dashboard.
#   dashboard_no_test         = True to not run the tests
#   CTEST_UPDATE_COMMAND      = path to svn command-line client
#   CTEST_BUILD_FLAGS         = build tool arguments (ex: -j2)
#   CTEST_DASHBOARD_ROOT      = Where to put source and build trees
#   CTEST_TEST_CTEST          = Whether to run long CTestTest* tests
#   CTEST_TEST_TIMEOUT        = Per-test timeout length
#   CTEST_TEST_ARGS           = ctest_test args (ex: PARALLEL_LEVEL 4)
#   CMAKE_MAKE_PROGRAM        = Path to "make" tool to use
#
# These variables may also be set dependent on dashboard_branch setting
# Applicable when dashboard_branch == master
#   dashboard_store_name      = Name of ExternalData store (ExternalData)
#   VTK_USE_LARGE_DATA        = True to enable tests using "large" data
#
# Options to configure builds from experimental git repository:
#   dashboard_git_url      = Custom git clone url
#   dashboard_git_branch   = Custom remote branch to track
#   dashboard_git_crlf     = Value of core.autocrlf for repository
#
# For Makefile generators the script may be executed from an
# environment already configured to use the desired compilers.
# Alternatively the environment may be set at the top of the script:
#
#   set(ENV{CC}  /path/to/cc)   # C compiler
#   set(ENV{CXX} /path/to/cxx)  # C++ compiler
#   set(ENV{FC}  /path/to/fc)   # Fortran compiler (optional)
#   set(ENV{LD_LIBRARY_PATH} /path/to/vendor/lib) # (if necessary)

#set(EnvironmentVariableName "$ENV{EnvironmentVariableName}"
##if (NOT "$ENV{EnvironmentVariableName}" STREQUAL "")
##    set(EnvironmentVariableName "$ENV{EnvironmentVariableName}" CACHE INTERNAL "Copied from environment variable")
##endif()
##message("EnvironmentVariableName = ${EnvironmentVariableName}")
