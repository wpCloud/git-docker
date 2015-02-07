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

  if [ -d "${PWD}/.git" ]; then
    echo " - We are currently in a root Git directory."

    if [ -d ${PWD}/.git ]; then
      GIT_DIR=${PWD}/.git
      GIT_WORK_TREE=${PWD}
    fi

    _IMAGE_NAME=$( echo $(basename $(dirname ${GIT_WORK_TREE}))/$(basename ${GIT_WORK_TREE}) | tr "/" "/" | tr '[:upper:]' '[:lower:]' )
    _HOSTNAME=${2:-$(basename `git --git-dir=${GIT_DIR} rev-parse --show-toplevel`)}
    _BRANCH=$(git --git-dir=${GIT_DIR} rev-parse --abbrev-ref HEAD)
    _CONTAINER_NAME=${_HOSTNAME}.${_BRANCH}.git
    ## _CURRENT_WWW_PATH=$(docker inspect --format '{{ index .Volumes "/var/www" }}' ${_CONTAINER_NAME})

    echo " - _IMAGE_NAME: ${_IMAGE_NAME}";
    echo " - _CONTAINER_NAME: ${_CONTAINER_NAME}";
    ## echo " - _CURRENT_WWW_PATH: ${_CURRENT_WWW_PATH}";

  else
    echo " - We are not in a root Git directory. (Be advised, we are not traversing, only checking existing location.)"
  fi

  if [ -f "${PWD}/composer.json" ]; then
    echo " - We have a composer.json file."
    ##echo $( cat ${PWD}/composer.json | jsawk -a 'this.config.docker' );
  else
    echo " - We do not have a composer.json file."
  fi

}


##export -f GitDockerInfo()