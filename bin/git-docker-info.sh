#!/bin/sh
##
##
function GitDockerInfo {
  ## echo "Git Container."

  export _TAG=${1}
  export _PORT=${3}
  export _BRANCH=${4}

  if [ -f /etc/environment ]; then
    source /etc/environment
  fi

  if [ "x$(git config docker.paths.runtime)" = "x" ]; then
    echo "Please set Docker runtime path. e.g. [git config --global docker.paths.runtime /opt/runtime]";
    return;
  fi;

  ## Try using current directory's .git subdirectory
  if [ "x${GIT_DIR}" = "x" ]; then
    GIT_DIR=${PWD}/.git
  fi

  ## Try using current directory
  if [ "x${GIT_WORK_TREE}" = "x" ]; then
    GIT_WORK_TREE=${PWD}
  fi

  if [ -d "${GIT_DIR}" ]; then
    echo " - We are currently in a root Git directory."

    _IMAGE_NAME=$( echo $(basename $(dirname ${GIT_WORK_TREE}))/$(basename ${GIT_WORK_TREE}) | tr "/" "/" | tr '[:upper:]' '[:lower:]' )
    _HOSTNAME=${2:-$(basename `git --git-dir=${GIT_DIR} rev-parse --show-toplevel`)}
    _BRANCH=$(git --git-dir=${GIT_DIR} rev-parse --abbrev-ref HEAD)

    _CONTAINER_NAME=${_HOSTNAME}.${_BRANCH}
    _CONTAINER_ID=$(docker ps | grep "${_CONTAINER_NAME}" |  awk '{print $1}')
    _CONTAINER_PATH=$(git config docker.paths.runtime)/$(echo -n $(md5sum <<< ${_CONTAINER_NAME} | awk '{print $1}'));

    if [ "x${_CONTAINER_PATH}" != "x" ]; then
      mkdir -p "$(git config docker.paths.runtime)/${_CONTAINER_PATH}";
    fi

    if [ -f "${GIT_WORK_TREE}/composer.json" ]; then
      echo " - We have a composer.json file."
    else
      echo " - We do not have a composer.json file."
    fi

    echo " - Image Name: [${_IMAGE_NAME}].";
    echo " - Branch Name: [${_BRANCH}].";
    echo " - Container Name: [${_CONTAINER_NAME}].";
    echo " - Runtime Container Path: [${_CONTAINER_PATH}].";

    if [ "x${_CONTAINER_ID}" = "x" ]; then
      echo " - Container not found."
    else
      _CURRENT_WWW_PATH=$(docker inspect --format '{{ index .Volumes "/var/www" }}' ${_CONTAINER_NAME})
      _PUBLIC_PORT=$(docker port ${_CONTAINER_NAME} 80)
      echo " - Active container found using ID [${_CONTAINER_ID}]."
      echo " - Public Port: [${_PUBLIC_PORT}].";
      echo " - Web Path: [${_CURRENT_WWW_PATH}].";
    fi


  else
    echo " - We are not in a root Git directory. (Be advised, we are not traversing, only checking existing location.)"
  fi

}


##export -f GitDockerInfo()