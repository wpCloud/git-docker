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
  _CONTAINER_ID=$(git config --local docker.meta.container)

  if [ "x${_CONTAINER_ID}" = "x" ]; then
    echo " - Container does not appear to be running. Trying [git docker start] first.";
    return;
  fi;

  ## echo " - Entering ${_CONTAINER_ID} in ${GIT_DIR}."
  if [ "x$(git config --global user.email)" != "x" ]; then
    docker exec ${_CONTAINER_ID} git config --global user.email $(git config --global user.email)
  fi;

  if [ "x$(git config --global user.name)" != "x" ]; then
    docker exec ${_CONTAINER_ID} git config --global user.name $(git config --global user.name)
  fi;

  if [ "x$(git config --global push.default)" != "x" ]; then
    docker exec ${_CONTAINER_ID} git config --global push.default $(git config --global push.default)
  fi;

  ## Fix github key and config file location and permissions.
  if [ -f "${GIT_WORK_TREE}/wp-content/static/ssh/github.pem" ]; then
    docker exec ${_CONTAINER_ID} chmod 0600 /var/www/wp-content/static/ssh/github.pem

    if [ -f "${GIT_WORK_TREE}/wp-content/static/ssh/config"  ]; then
      ## echo "Fixing permissions for GitHub SSH key in <wp-content/static/ssh/github.pem>."
      docker exec ${_CONTAINER_ID} ln -sf /var/www/wp-content/static/ssh/config /home/core/.ssh
    fi;

  fi;

  docker exec -it ${_CONTAINER_ID} /bin/bash

}

