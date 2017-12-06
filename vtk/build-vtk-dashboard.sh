#!/bin/sh
# build-vtk-dashboard.sh 
VERSION="v2.0 01/12/2017" 
AUTHOR="John Sincock"

#set -x
DEBUG=
#DEBUG=echo

usage () {
   echo
   echo "Get latest Visualisation Toolkit (VTK) dashboard update from Git, and use it to configure/make/install VTK as required."
   echo 
   echo
   echo "Usage > build-vtk-dashboard.sh [options]"
   echo
   echo "      -h | --help   Lists this usage information."
   echo "      -t | --test   Echo the commands that will be executed."
   echo
   echo "      --clone       Git clone the dashboard repo."
   echo "      --pull        Git pull the dashboard repo."
   echo "      --status      Lists files which git will pull."
   echo
   echo "      --configure   Prepare build tree with dashboard cmake files."
   echo "      --make        Run ctest to build and test."
   echo "      --install     Install."
   echo
#   echo "      Use the current build, do not clean:"
#   echo "      --noclean     Do not clean current build dir. Currently does not work. Cmake cleans it anyway."
#   echo
   exit
}

ok=0 ; test=0 ;
clone=0 ; pull=0 ; status=0 ; 
configure=0 ; make=0 ; install=0 ;
#cleanbuild=1 ; refresh=1 ; usecurrent=0 ;

for arg in "$@"
do
    case ${arg} in    #switches for this shell script begin with '--'
	-h)           ok=1; usage;;
	--help)       ok=1; usage;;
	-t)           test=1; DEBUG=echo ; echo -e "\nTest mode on.";;
	--test)       test=1; DEBUG=echo ; echo -e "\nTest mode on.";;

	--clone)      ok=1; clone=1;;
	--pull)       ok=1; pull=1;;
	--status)     ok=1; status=1;; 

	--configure)  ok=1; configure=1;;
	--make)       ok=1; make=1;;
	--install)    ok=1; install=1;;

	#--noclean)    cleanbuild=0;; 
	*)            ok=0 ; usage ;;
    esac;
done

if [ $ok -eq 0 ] ; then usage ; fi
echo

#export DISPLAY=0:1      #testing requires a display with nvidia openGL.
export DISPLAY=:2      #testing requires a display with nvidia openGL.

DATE="`date +%Y%m%d`"   #used to label cmakeCache and maybe build id
GIT_ID="nightly/1"      #dashboard configs go here. Build occurs in nightly/1/build subdir, as cmake cleans it. 
BUILD_ID=${GIT_ID}      #may switch to #BUILD_ID="nightly/${DATE}"

CI_DIR="/data-ssd/data/development/src/vtk"
#CONFIG_DIR="${CI_DIR}/config"
JENKINS_DIR="/data-ssd/data/development/src/github/jenkins"
CONFIG_DIR="${JENKINS_DIR}/vtk/config"

MODULE=dashboard
GIT_DIRNAME=git
GIT_DIR="${CI_DIR}/${GIT_DIRNAME}"
GIT_LOG_DIR="${GIT_DIR}/z_logs"
GIT_SRC_DIR="${GIT_DIR}/${MODULE}"
BUILD_SUBDIR="build/${MODULE}/${BUILD_ID}"
BUILD_DIR="${CI_DIR}/${BUILD_SUBDIR}"
GIT_ROOT="https://gitlab.kitware.com/vtk/vtk.git"
#LOG_DIR="${CI_DIR}/build/${MODULE}/${BUILD_ID}/z_buildlog"
GIT_LOGFILE="${GIT_LOG_DIR}/git-vtk-dashboard.log"

export CTEST_DASHBOARD_BUILD_FLAGS="-j6"                    #use 6 cores to use for build
export CTEST_DASHBOARD_SITE_NAME="il-duce.homunculoid.com"
export CTEST_DASHBOARD_BUILD_NAME="f26-x64-nvidia_384.98-jenkins"

#False *enables*  testing:
#Note: testing does not work by default over vnc, maybe tweak mesa to fix this, otherwise, requires nvidia.
export CTEST_DASHBOARD_NO_TEST="True"
#export CTEST_DASHBOARD_NO_TEST="False"  

#export CTEST_DASHBOARD_MODEL="Nightly"         #does do git update
#export CTEST_DASHBOARD_MODEL="Continuous"      #(like nightly but loops and runs every 5 mins or so)
export CTEST_DASHBOARD_MODEL="Experimental"     #does not do git update! so we can do that in jenkins. perfect!

#By default, source and build trees go in "../My Tests/" relative to your script location.
#Better locations:
#VTK git checkout goes under: CTEST_DASHBOARD_ROOT/dashboard_source_name
#Build goes under:            CTEST_DASHBOARD_ROOT/dashboard_binary_name
#Test Data goes under         CTEST_DASHBOARD_ROOT/dashboard_store_name

#export CTEST_DASHBOARD_ROOT="${GIT_DIR}"                       #Where to put source and build trees
export CTEST_DASHBOARD_ROOT="${CI_DIR}"                         #Where to put source and build trees

#cmake cleans the build dir (dashboard_binary_name dir),
#so our dashboard configs go in ${BUILD_SUBDIR} and cmake builds in ${BUILD_SUBDIR}/build:
export CTEST_DASHBOARD_BUILD_DIR="${BUILD_SUBDIR}/build"        #Name of binary directory (default VTK-build)
export CTEST_DASHBOARD_VTK_GIT_DIR="${GIT_DIRNAME}/vtk-master"  #Name of source directory (VTK)
export CTEST_DASHBOARD_TESTDATA_DIR="${GIT_DIRNAME}/Test-Data"  #Name of ExternalData store (Test-Data)

git_clone () {
    echo "Cloning into <${GIT_SRC_DIR}>:"
    $DEBUG mkdir --parents "${GIT_SRC_DIR}"
    $DEBUG cd "${GIT_SRC_DIR}"
    $DEBUG git init                                         | tee --append "${GIT_LOGFILE}"
    $DEBUG git remote add -t dashboard origin "${GIT_ROOT}" | tee --append "${GIT_LOGFILE}"
    $DEBUG git pull origin                                  | tee --append "${GIT_LOGFILE}"
}

git_runcmd () {
    gitcmd="$1"
    msg="$2"
    echo "$msg"
    $DEBUG cd "${GIT_SRC_DIR}"
    $DEBUG git $gitcmd 2>&1 | tee --append "${GIT_LOGFILE}"
}
git_pull () {
    git_runcmd "pull" "Updating <${GIT_SRC_DIR}>:"
}
git_status () {
    git_runcmd "status" "Status of <${GIT_SRC_DIR}>:"
}

safe_dir () {
    somedir=$1
    echo "Testing <$somedir> :"
    safe=0
    if [[ -d  "${somedir}" && "m${somedir}" != "m/" ]] ; then
	echo -e "Safe.\n"
	safe=1
    else
	echo -e "UNSAFE!\n"
    fi
    return $safe
}

configure_build () {
    echo "Configuring <${BUILD_DIR}> :"
    
    if [[ ! -d  "${BUILD_DIR}" ]] ; then
	echo "Creating build tree <${BUILD_DIR}> :"
	$DEBUG mkdir --parents "${BUILD_DIR}"
    else
	echo "Build dir already exists."
    fi

    echo "Copying dashboard configs into <${BUILD_DIR}>:"
    #copy the basic dashboard config into place from the dashboard git checkout:
    #$DEBUG cp -vf "${GIT_DIR}/vtk_common.cmake" "${BUILD_DIR}/"      #open.cdash.org
    $DEBUG cp -vf "${CONFIG_DIR}/vtk_common.cmake" "${BUILD_DIR}/"    #homunculoid.com
    
    #restore our customised dashboard cmake config:
    $DEBUG cp -vf "${CONFIG_DIR}/dashboard.cmake" "${BUILD_DIR}/"

    echo "Configure for <${BUILD_DIR}> done."
}

make_build () {
    echo "Building <${BUILD_DIR}> :"

    if [[ -d  "${BUILD_DIR}" ]] ; then
	#trying to avoid cleaning build dir here will be pointless until we can stop cmake cleaning it.
	#if [ $cleanbuild -eq 1 ] ; then
	#    echo "Cleaning build dir <${DASHBOARD_BUILD_DIR}> :"
	#    safedir "${DASHBOARD_BUILD_DIR}"
	#    safe=$?
	#    if [[ "${safe}" -eq 1 ]] ; then
	#	echo "Deleting build dir <${DASHBOARD_BUILD_DIR}> in 5 seconds:"
	#	$DEBUG sleep 5
	#	$DEBUG rm -Rvf "${DASHBOARD_BUILD_DIR}"   #FIXME should wait for confirmation
	#    else
	#	echo -e "Woah. Not safe to clean build dir <${DASHBOARD_BUILD_DIR}>\n"
	#    fi
	#fi

	#echo "Building with $CORES cores:"
	echo "Building VTK dashboards:"
	$DEBUG cd "${BUILD_DIR}"

	#Build and submit dashboards:
	$DEBUG ctest -S "${BUILD_DIR}/dashboard.cmake" -V

        #--build-noclean

	#old method for DART:
	#echo "Proftpd must be running when the submit occurs."
	##$DEBUG proftpd
	#$DEBUG cd "${BUILD_DIR}"

	#Dart doesn't work for experimental builds
	#make Experimental
	#make ExperimentalSubmit

	#Standard builds:
	#$DEBUG make NightlyStart
	#$DEBUG make NightlyBuild
	#$DEBUG make NightlyTest
	
        #echo "Proftpd must be running for this next step:"
        ##echo "Build files with same name (ie same date) must not already exist in /home/ftp/incoming."
        ##$DEBUG /etc/init.d/proftpd start
	#$DEBUG make NightlySubmit
	#$DEBUG make NightlyDashboardStart
	#$DEBUG make NightlyDashboardEnd
    else
	echo "Have not configured <${BUILD_DIR}>. It does not exist. Cannot build."
    fi
}
install_build () {
    echo "Installing <${BUILD_DIR}> :"
    if [[ -d  "${BUILD_DIR}" ]] ; then
	echo "Running make install in <${BUILD_DIR}> :"
	$DEBUG cd "${BUILD_DIR}"
	$DEBUG make install
    else
	echo "Have not configured <${BUILD_DIR}>. It does not exist. Cannot install."
    fi
}

test_safedir () {
    safedir ""
    safedir "/"
    safedir "/data-ssd/data/development/src/vtk/"
}

function git_stuff () {
    if [[ $clone     -eq 1 ]] ; then git_clone       ; fi
    if [[ $pull      -eq 1 ]] ; then git_pull        ; fi
    if [[ $status    -eq 1 ]] ; then git_status      ; fi
}
function build_stuff () {
    if [[ $configure -eq 1 ]] ; then configure_build ; fi
    if [[ $make      -eq 1 ]] ; then make_build      ; fi
    if [[ $install   -eq 1 ]] ; then install_build   ; fi
}

#test_safedir
git_stuff
build_stuff
echo
