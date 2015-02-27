#!/bin/bash
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
    echo "[git/docker] We are currently in a root Git directory."

    GIT_DOCKER_TYPE=$(git config --local docker.type)

    ## Update settings now that we have git repository...
    _REPOSITORY_NAME=$(basename $(git remote show -n origin | grep Fetch | cut -d: -f2-))

      ## strip '.git" from very end
    _REPOSITORY_NAME=${_REPOSITORY_NAME/%.git/}
    _HOSTNAME=${_REPOSITORY_NAME}

    _IMAGE_NAME=$( echo $(basename $(dirname ${GIT_WORK_TREE}))/$(basename ${GIT_WORK_TREE}) | tr "/" "/" | tr '[:upper:]' '[:lower:]' )
    _BRANCH=$(git --git-dir=${GIT_DIR} rev-parse --abbrev-ref HEAD)

    _CONTAINER_NAME=$( echo "${_HOSTNAME}.${_BRANCH}.git" | tr '[:upper:]' '[:lower:]' )


    _CONTAINER_ID=$(git config --local docker.meta.container)
    _RUNTIME_PATH=$(git config docker.paths.runtime)/$(echo -n $(md5sum <<< ${_CONTAINER_ID} | awk '{print $1}'));

    if [ -f "${GIT_WORK_TREE}/composer.json" ]; then
      echo " - We have a composer.json file."
    else
      echo " - We do not have a composer.json file."
    fi

    if [ -f ~/.git-docker/default.sh ]; then
      echo " - Custom Git/Docker directory found.";
    fi;

    echo " - Hostname: [${_HOSTNAME}] and [${_HOSTNAME/www./}].";
    echo " - Image Name: [${_IMAGE_NAME}].";
    echo " - Branch Name: [${_BRANCH}].";

    echo " - Container Name: [${_CONTAINER_NAME}].";

    if [ "x${GIT_DOCKER_TYPE}" = "x" ]; then
      echo " - Type is not set."
    else
      echo " - Type is set to [${GIT_DOCKER_TYPE}]."
    fi

    if [ "x${_CONTAINER_ID}" = "x" ]; then
      echo " - Container not found."
    else
      _CURRENT_WWW_PATH=$(docker inspect --format '{{ index .Volumes "/var/www" }}' ${_CONTAINER_ID})
      _PUBLIC_PORT=$(git config --local docker.meta.port)
      echo " - Active container found using ID [${_CONTAINER_ID}]."
      echo " - Public Port: [${_PUBLIC_PORT}].";
      echo " - Web Path: [${_CURRENT_WWW_PATH}].";
    fi


  else
    echo " - We are not in a root Git directory. (Be advised, we are not traversing, only checking existing location.)"
  fi

}


##export -f GitDockerInfo()