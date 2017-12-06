#!/bin/sh
# build-vtk.sh 
VERSION="v2.0 01/12/2017" 
AUTHOR="John Sincock"

DEBUG=
#DEBUG=echo

usage () {
   echo
   echo "Get latest Visualisation Toolkit (VTK) update from Git, and configure/make/install as required."
   echo 
   echo
   echo "Usage > build-vtk.sh [options]"
   echo
   echo "      -h | --help    lists this usage information."
   echo "      -t | --test    echo the commands that will be executed."
   echo
   echo "      --clone        git clone."
   echo "      --pull         git pull."
   echo "      --status       lists files which git will pull."
   echo
   echo "      --configure    create/update build tree and (re-)configure."
   echo "      --make         (re-)make."
   echo "      --install      install."
   echo
   echo "      Use the current build, do not clean:"
   echo "      --current      re-use current build dir."
#  echo "      --ccnr         configure current build - without refresh (no check for new/stale links)."
   echo
   exit
}

ok=0 ; test=0 ;
clone=0 ; pull=0 ; status=0 ; 
configure=0 ; make=0 ; install=0 ;
cleanbuild=1 ;   #1=clean the current build tree & start afresh
#refresh=1 ;     #refresh/remove stale symlinks in current build tree
#usecurrent=0 ;  #build or make in PWD

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

	--current)    ok=1; cleanbuild=0; configure=1;; 
##	--ccnr)       ok=1; cleanbuild=0; configure=1;  refresh=0;;
	*)            ok=0 ; usage ;;
    esac;
done

if [ $ok -eq 0 ] ; then usage ; fi
echo

#########
export DISPLAY=0:1      #testing requires a display with nvidia openGL.
DATE="`date +%Y%m%d`"   #used to label cmakeCache and maybe build id
GIT_ID="nightly/1"      #dashboard configs go here. Build occurs in nightly/1/build subdir, as cmake cleans it. 
BUILD_ID=${GIT_ID}      #may switch to #BUILD_ID="nightly/${DATE}"

CI_DIR="/data-ssd/data/development/src/vtk"
#CONFIG_DIR="${CI_DIR}/config"
JENKINS_DIR="/data-ssd/data/development/src/github/jenkins"
CONFIG_DIR="${JENKINS_DIR}/vtk/config"

MODULE=vtk-master
GIT_DIRNAME=git
GIT_DIR="${CI_DIR}/${GIT_DIRNAME}"
GIT_LOG_DIR="${GIT_DIR}/z_logs"
GIT_SRC_DIR="${GIT_DIR}/${MODULE}"
CONFIG_ARCHIVE_DIR="${CI_DIR}/build/${MODULE}/config_archive"
BUILD_SUBDIR="build/${MODULE}/${BUILD_ID}"
BUILD_DIR="${CI_DIR}/${BUILD_SUBDIR}"
GIT_ROOT="https://gitlab.kitware.com/vtk/vtk.git"
#GIT_ROOT="git://vtk.org/VTK.git"
#GIT_VTKData_ROOT="git://vtk.org/VTKData.git"
#VTKData_GIT_DIR="${GIT_DIR}/VTKData"
#LOG_DIR="${CI_DIR}/build/${MODULE}/${BUILD_ID}/z_buildlog"
GIT_LOGFILE="${GIT_LOG_DIR}/git-vtk.log"

CORES=6               #number of cores to use for build
RELEASE_TAG=""        #RELEASE_TAG="-r blah"

#used to set this if i wanted to operate in PWD.
#if [ $usecurrent -eq 1 ] ; then 
#    BUILD_DIR="."
#fi

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

safedir () {
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
    if [ $cleanbuild -eq 1 ] ; then
	echo "Cleaning build dir <${BUILD_DIR}> :"
	safedir "${BUILD_DIR}"
	safe=$?
	if [[ "${safe}" -eq 1 ]] ; then
	    echo "Deleting build dir <${BUILD_DIR}> in 5 seconds:"
	    $DEBUG sleep 5
	    $DEBUG rm -Rvf "${BUILD_DIR}"   #If interactive, could use -I to wait for confirmation
	else
	    echo -e "Woah. Not safe to clean build dir <${BUILD_DIR}>\n"
	fi
    fi
    
    if [[ ! -d  "${BUILD_DIR}" ]] ; then
	echo "Creating build tree <${BUILD_DIR}> :"
	$DEBUG mkdir --parents "${BUILD_DIR}"
    #elif [[ $refresh -eq 1 ]] ; then   #i think cmake will update/refresh any existing build directory.
	#echo "Updating build tree : <${BUILD_DIR}> :"
	#$DEBUG cd "${BUILD_DIR}"
	#$DEBUG lndir "${GIT_SRC_DIR}"      # link to new files
	#echo "Removing stale links from build tree : <${BUILD_DIR}> :"
	#could use "cleanlinks" #from X11
	###$DEBUG find . -xtype l -exec rm '{}' \; # remove links pointing to non-existent files
    else
	echo "Build dir already exists."
    fi
    
    #restore our saved cmake config:
    #$DEBUG cp -vf "${CONFIG_DIR}/CMakeCache-current.txt" "${BUILD_DIR}/CMakeCache.txt"
    #$DEBUG cp -vf "${CONFIG_DIR}/CMakeCache-testing-on.txt" "${BUILD_DIR}/CMakeCache.txt"
    $DEBUG cp -vf "${CONFIG_DIR}/CMakeCache-testing-off.txt" "${BUILD_DIR}/CMakeCache.txt"
    
    $DEBUG cd "${BUILD_DIR}"
    #$DEBUG ccmake "${GIT_SRC_DIR}"    #interactive
    $DEBUG cmake "${GIT_SRC_DIR}"      #non-interactive, specify options on cmdline, or use pre-made config

    #save config for later:
    $DEBUG mkdir --parents "${CONFIG_ARCHIVE_DIR}"
    $DEBUG cp -vf "${BUILD_DIR}/CMakeCache.txt" "${CONFIG_ARCHIVE_DIR}/CMakeCache-${DATE}.txt"
    $DEBUG cp -vf "${BUILD_DIR}/CMakeCache.txt" "${CONFIG_DIR}/CMakeCache-latest.txt"
    
    #$DEBUG rm -vf "${CONFIG_DIR}/CMakeCache-latest.txt"
    #$DEBUG ln -s "${CONFIG_DIR}/CMakeCache-${DATE}.txt" "${CONFIG_DIR}/CMakeCache-latest.txt"

    echo "Configure for <${BUILD_DIR}> done."
}
make_build () {
    echo "Building <${BUILD_DIR}> :"
    if [[ -d  "${BUILD_DIR}" ]] ; then
	echo "Building with $CORES cores:"
	$DEBUG cd "${BUILD_DIR}"
	$DEBUG make -j$CORES 	#Simple build:
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
