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

  if [ -d ${PWD}/.git ]; then
    export _GIT_DIR=${PWD}/.git
    export _WORK_TREE=${PWD}
  else
    export _GIT_DIR=$(git config docker.paths.sources)"/${_TAG}/.git";
    export _WORK_TREE=$(git config docker.paths.sources)"/${_TAG}";
  fi

  ## Debug
  # echo " - _GIT_DIR: ${_GIT_DIR}"
  # echo " - _WORK_TREE: ${_WORK_TREE}"

  ## Clone or Fetch/Reset/Clean/Pull
  if [ ! -d ${_GIT_DIR} ]; then
    echo " - Cloning to /opt/sources/${_TAG}..."
    git clone --quiet "git@github.com:${_TAG}.git" "/opt/sources/${_TAG}"
  else
    echo " - Refreshing Git repository <${_WORK_TREE}>."
    git --git-dir=${_GIT_DIR} --work-tree=${_WORK_TREE} fetch --quiet
    git --git-dir=${_GIT_DIR} --work-tree=${_WORK_TREE} reset --quiet --hard
    git --git-dir=${_GIT_DIR} --work-tree=${_WORK_TREE} clean --quiet --force -d
    git --git-dir=${_GIT_DIR} --work-tree=${_WORK_TREE} pull  --quiet
  fi

}

