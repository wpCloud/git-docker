#!/bin/bash
##
##
function GitDockerReload {

  export _TAG=${1}
  export _PORT=${3}
  export _BRANCH=${4}

  if [ -f /etc/environment ]; then
    source /etc/environment
  fi

  if [[ ${GIT_DOCKER_VERBOSE} == true ]]; then echo "[git/docker] Reloading Git repository"; fi;

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
    if [[ ${GIT_DOCKER_SILENT} != true ]]; then echo "[git/docker] Not in a Git repository, clone first."; fi;
    ## git clone --quiet "git@github.com:${_TAG}.git" "${GIT_WORK_TREE}"
    exit;
  else
    if [[ ${GIT_DOCKER_SILENT} != true ]]; then echo "[git/docker] Refreshing Git repository <${GIT_WORK_TREE}>."; fi;
    git --git-dir=${GIT_DIR} --work-tree=${GIT_WORK_TREE} fetch --quiet
    git --git-dir=${GIT_DIR} --work-tree=${GIT_WORK_TREE} reset --quiet --hard
    git --git-dir=${GIT_DIR} --work-tree=${GIT_WORK_TREE} clean --quiet --force -d ${GIT_DOCKER_CLEAN_ARGS}
    git --git-dir=${GIT_DIR} --work-tree=${GIT_WORK_TREE} pull  --quiet
  fi

}

