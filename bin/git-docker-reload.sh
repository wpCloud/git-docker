#!/bin/sh
##
##
function GitDockerReload {
  echo " - Reloading Git repository."

  export _TAG=${1}
  export _PORT=${3}
  export _BRANCH=${4}

  if [ -f /etc/environment ]; then
    source /etc/environment
  fi

  if [ "x$(git config docker.paths.sources)" = "x" ]; then
    echo "Please set Docker Sources path. e.g. [git config --global docker.paths.sources /opt/sources]";
    return;
  fi;

  if [ "x$(git config docker.paths.storage)" = "x" ]; then
    echo "Please set Docker storage path. e.g. [git config --global docker.paths.storage /opt/storage]";
    return;
  fi;

  if [ -d ${PWD}/.git ]; then
    GIT_DIR=${PWD}/.git
    GIT_WORK_TREE=${PWD}
  else
    GIT_DIR=$(git config docker.paths.sources)"/${_TAG}/.git";
    GIT_WORK_TREE=$(git config docker.paths.sources)"/${_TAG}";
  fi

  ## Debug
  # echo " - GIT_DIR: ${GIT_DIR}"
  # echo " - GIT_WORK_TREE: ${GIT_WORK_TREE}"

  ## Clone or Fetch/Reset/Clean/Pull
  if [ ! -d ${GIT_DIR} ]; then
    echo " - Cloning to ${GIT_WORK_TREE}"
    git clone --quiet "git@github.com:${_TAG}.git" "${GIT_WORK_TREE}"
  else
    echo " - Refreshing Git repository <${GIT_WORK_TREE}>."
    git --git-dir=${GIT_DIR} --work-tree=${GIT_WORK_TREE} fetch --quiet
    git --git-dir=${GIT_DIR} --work-tree=${GIT_WORK_TREE} reset --quiet --hard
    git --git-dir=${GIT_DIR} --work-tree=${GIT_WORK_TREE} clean --quiet --force -d --exclude=wp-content/storage
    git --git-dir=${GIT_DIR} --work-tree=${GIT_WORK_TREE} pull  --quiet
  fi


}

