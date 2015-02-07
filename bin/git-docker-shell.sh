#!/bin/sh
##
## git docker shell
##
## @author potanin@UD
## @todo Only fetch passed TAG if not currently in git repository.

function GitDockerShell {
  # echo "Starting Git Docker Shell."

  _TAG=${1}
  _PORT=${3}
  _BRANCH=${4}

  if [ -f /etc/environment ]; then
    source /etc/environment
  fi

  if [ -d ${PWD}/.git ]; then
    GIT_DIR=${PWD}/.git
    GIT_WORK_TREE=${PWD}
  else

    if [[ ${_TAG} != "" ]]; then
      echo " - Unknown tag specified."
      GIT_DIR=$(git config docker.paths.sources)"/${_TAG}/.git";
      GIT_WORK_TREE=$(git config docker.paths.sources)"/${_TAG}";
    else
      echo " - Not in a Git directory and no tag specified. Perhaps clone repository first?"
      return;
    fi

  fi

  if [ ! -d ${GIT_DIR} ]; then
    echo " - Unable to shell, ${GIT_DIR} is not a valid git directory."
    return;
  fi

  _HOSTNAME=${2:-$(basename `git --git-dir=${GIT_DIR} rev-parse --show-toplevel`)}
  _BRANCH=$(git --git-dir=${GIT_DIR} rev-parse --abbrev-ref HEAD)
  _CONTAINER_NAME=${_HOSTNAME}.${_BRANCH}.git

  echo " - Entering ${_CONTAINER_NAME} in ${GIT_DIR}."
  docker exec -it ${_CONTAINER_NAME} /bin/bash

}

