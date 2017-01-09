#!/usr/bin/env bash

if [[ ! ${BASH_VERSION} =~ ^4 ]]; then
  echo "Invalid version: ${BASH_VERSION}"
  exit 32
fi

# change directory to the script directory
cd "$(dirname "$0")"
SCRIPT_DIR=$(pwd)

# allow exiting from inside functions
set -e

## Status helpers

function displayHelp
{
  cat<<EOF
Usage: dockerMyLife.sh [OPTIONS]

Options:

Optional:
(-b|--based-on)=image             Specify the docker image to base the image off of; defaults to "greyltc/archlinux-aur"
(-d|--docker-file)=path           Path of the partial Dockerfile (no FROM statement) to use; defaults to "./example/Dockerfile"
(-h|--help)                       Display this help and exit
(-i|--image-name)=name            Specify the name to use for the docker image; defaults to "docker-life"
(-o|--output-dir)=dir             Specify the output folder; defaults to "docker-life"
(-r|--root)=container-dir         Specify the location to mount the host root; defaults to /host/root
(-s|--session-name)=name          Specify the name to use for the running docker session; defaults to "docker-life"
(-w|--working-dir)=dir            Specify the working folder; defaults to "docker-life"
(-x|--execute)=program            Specify the program to execute when starting the image, typically the shell; defaults to "zsh"

Arguments after -- will be passed to "docker build"
EOF
}

INVALID_OPTION=64
UNKNOWN_OPTION=92

function emptyRequiredOption
{
  echo "Empty required option: \"${@}\""
  displayHelp
  exit ${INVALID_OPTION}
}

function invalidOption
{
  echo "Invalid option: \"${@}\""
  displayHelp
  exit ${INVALID_OPTION}
}

function notAFileOption
{
  echo "Not a file: \"${@}\""
  displayHelp
  exit ${INVALID_OPTION}
}

function unknownOption
{
  echo "Unknown option: \"${@}\""
  displayHelp
  exit ${UNKNOWN_OPTION}
}

## Option parsing

BASED_ON="greyltc/archlinux-aur"
DOCKER_FILE="./example/Dockerfile"
IMAGE_NAME="docker-life"
OUTPUT_DIR="docker-life"
HOST_ROOT="/host/root"
SESSION_NAME="docker-life"
WORKING_DIR="docker-life"
EXEC="zsh"

function checkOptionValue
{
  OPT_VAL=${1}
  if [[ "${OPT_VAL}" == "" || ${OPT_VAL} =~ ^- ]]; then
    invalidOption ${OPT_VAL}
  fi
}

function checkFileOptionValue
{
  OPT_VAL=${1}
  checkOptionValue "${OPT_VAL}"
  if [[ ! -f "${OPT_VAL}" ]]; then
    notAFileOption ${OPT_VAL}
  fi
}

while [[ $# -gt 0 ]]; do
  OPT=${1}
  case ${OPT} in
    -b=*|--based-on=*)
      BASED_ON=${OPT#*=}
      checkOptionValue ${BASED_ON}
    ;;
    -d=*|--docker-file=*)
      DOCKER_FILE=${OPT#*=}
      checkFileOptionValue ${BASED_ON}
    ;;
    -h|--help)
      displayHelp
      exit 0
    ;;
    -i=*|--image-name=*)
      IMAGE_NAME=${OPT#*=}
      checkOptionValue ${IMAGE_NAME}
    ;;
    -o=*|--output-dir=*)
      OUTPUT_DIR=${OPT#*=}
      checkOptionValue ${OUTPUT_DIR}
    ;;
    -r=*|--root=*)
      HOST_ROOT=${OPT#*=}
      checkOptionValue
    ;;
    -s=*|--session-name=*)
      SESSION_NAME=${OPT#*=}
      checkOptionValue ${SESSION_NAME}
    ;;
    -w=*|--working-dir=*)
      WORKING_DIR=${OPT#*=}
      checkOptionValue ${WORKING_DIR}
    ;;
    -x=*|--execute=*)
      EXEC=${OPT#*=}
      checkOptionValue ${EXEC}
    ;;
    --)
      shift
      break
    ;;
    *)
      unknownOption ${OPT}
    ;;
  esac
  shift
done

IMAGE_FILE_NAME=${IMAGE_NAME}.tar

## Initialization

INVALID_PROCESS_REGEX="\<\(grep\|firefox\|crom\(e\|ium\)\)\>"

function printUnixLaunchScript
{
  cat<<EOF
#!/usr/bin/env bash
HAS_DOCKER=\$(ps aux | grep -v "${INVALID_PROCESS_REGEX}" | grep "\\<dockerd\\>")
if [[ "\${HAS_DOCKER}" == "" ]];  then
  if [[ "\$(which docker)" == "" ]]; then
    echo "Please run scripts/install-(arch|generic-unix).sh" before starting
    exit 1
  fi
  which systemctl &> /dev/null
  MISSING_SYSTEMD=\$?
  which service &> /dev/null
  MISSING_SERVICE=\$?
  if [[ \${MISSING_SYSTEMD} -eq 0 ]]; then
    sudo systemctl start docker
  elif [[ \${MISSING_SERVICE} -eq 0 ]]; then
    sudo service docker start
  elif [[ -f /etc/init.d/docker ]]; then
    sudo /etc/init.d/docker start
  fi
fi
docker load -i ./${IMAGE_FILE_NAME}
docker run -v /:${HOST_ROOT} --name ${SESSION_NAME} --rm -i -t ${IMAGE_NAME} ${EXEC}
EOF
}

function printOsxLaunchScript
{
  cat<<EOF
#!/usr/bin/env bash
cd "\$(dirname "\$0")"
HAS_DOCKER=\$(ps aux | grep -v "${INVALID_PROCESS_REGEX}" | grep "\\<Docker\\\$")
if [[ "\${HAS_DOCKER}" == "" ]]; then
  ./osx/Docker.app/Contents/MacOS/Docker &
  disown
  echo "Run the script again after the daemon has launched."
else
  echo "Reading from media..."
  docker load -i ./${IMAGE_FILE_NAME}
  docker run -v /:${HOST_ROOT} --name ${SESSION_NAME} --rm -i -t ${IMAGE_NAME} ${EXEC}
fi
EOF
}

function printWindowsLaunchScript
{
  cat<<EOF
echo ensure the docker daemon is running
pause
start docker load -i ${IMAGE_FILE_NAME} & docker run -v C:\\:${HOST_ROOT} --name ${SESSION_NAME} --rm -i -t ${IMAGE_NAME} ${EXEC}
EOF
}

echo "Building image ${IMAGE_NAME}"
if [[ ! -f "${WORKING_DIR}/${IMAGE_FILE_NAME}" ]]; then
  docker pull ${BASED_ON}

  mkdir -p ${WORKING_DIR}
  echo "FROM ${BASED_ON}" > ${WORKING_DIR}/Dockerfile
  cat ${DOCKER_FILE} >> ${WORKING_DIR}/Dockerfile
  cd ${WORKING_DIR}
  docker build ${@} -t ${IMAGE_NAME} .
else
  echo "Image already exists; remove ${WORKING_DIR}/${IMAGE_NAME} to re-build"
fi

cd ${SCRIPT_DIR}
mkdir -p ${OUTPUT_DIR}
cd ${OUTPUT_DIR}
echo "Saving image to ${IMAGE_FILE_NAME}"
if [[ ! -f "${IMAGE_FILE_NAME}" ]]; then
  # wait for the image to not be marked as busy
  sleep 1
  docker save -o ${IMAGE_FILE_NAME} ${IMAGE_NAME}
else
  echo "File already exists; remove ${IMAGE_FILE_NAME} to re-save image"
fi

echo "Downloading docker installers"
mkdir -p installers
cd installers
if [[ ! -f Docker.dmg ]]; then
	wget https://download.docker.com/mac/stable/Docker.dmg
  7z x Docker.dmg Docker/Docker.app
  mkdir -p ../osx
  mv Docker/Docker.app ../osx
  rm -rf Docker
else
	echo "Mac docker installer already downloaded; remove ${OUTPUT_DIR}/installers/Docker.dmg to re-download"
fi
if [[ ! -f InstallDocker.msi ]]; then
	wget https://download.docker.com/win/stable/InstallDocker.msi
else
	echo "Windows docker installer already downloaded; remove ${OUTPUT_DIR}/installers/InstallDocker.msi to re-download"
fi
echo "Copying script-based installers"
cp ${SCRIPT_DIR}/scripts/install-* .

echo "Generating scripts"
cd ${SCRIPT_DIR}
cd ${WORKING_DIR}
printUnixLaunchScript > unix.sh
printOsxLaunchScript > osx.sh
printWindowsLaunchScript > windows.bat
chmod a+x unix.sh osx.sh
