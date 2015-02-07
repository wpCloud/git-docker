#!/bin/sh
##
##
## @author potanin@UD
## @todo Only fetch passed TAG if not currently in git repository.

function GitDockerShell{
  ## echo "Starting Git Docker container."

  export _TAG=${1}
  export _PORT=${3}
  export _BRANCH=${4}

  if [ -f /etc/environment ]; then
    source /etc/environment
  fi

  if [ -d ${PWD}/.git ]; then
    ## echo " - You seem to be in a git repo.."
    export _GIT_DIR=${PWD}/.git
    export _WORK_TREE=${PWD}
  else

    if [[ ${_TAG} != "" ]]; then
      export _GIT_DIR=$(git config docker.paths.sources)"/${_TAG}/.git";
      export _WORK_TREE=$(git config docker.paths.sources)"/${_TAG}";
    else
      echo " - Not in a Git directory and no tag specified. Perhaps clone repository first?"
      return;
    fi

  fi

  _HOSTNAME=${2:-$(basename `git --git-dir=${_GIT_DIR} rev-parse --show-toplevel`)}
  _BRANCH=$(git --git-dir=${_GIT_DIR} rev-parse --abbrev-ref HEAD)
  _CONTAINER_NAME=${_HOSTNAME}.${_BRANCH}.git

  docker exec -it ${_CONTAINER_NAME} /bin/bash

}

