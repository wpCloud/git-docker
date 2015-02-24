#!/bin/bash
##
## git docker shell
## git docker shell composer.phar validate
## git docker shell git status
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
  _CONTAINER_ID=$(git config --local docker.meta.container)

  if [ "x${_CONTAINER_ID}" = "x" ]; then
    echo " - Container does not appear to be running. Trying [git docker start] first.";
    return;
  fi;

  ## echo " - Entering ${_CONTAINER_ID} in ${GIT_DIR}."
  if [ "x$(git config --global user.email)" != "x" ]; then
    docker exec ${_CONTAINER_ID} git config --global  --replace-all user.email $(git config --global user.email)
  fi;

  if [ "x$(git config --global user.name)" != "x" ]; then
    docker exec ${_CONTAINER_ID} git config --global --replace-all  user.name $(git config --global user.name)
  fi;

  if [ "x$(git config --global push.default)" != "x" ]; then
    docker exec ${_CONTAINER_ID} git config --global --replace-all  push.default $(git config --global push.default)
  fi;

  if [ "x$1" != "x" ]; then
    docker exec -i ${_CONTAINER_ID} $@
  else
    echo "Starting terminal ${_CONTAINER_ID}."
    docker exec -it ${_CONTAINER_ID} /bin/bash
  fi;

}

