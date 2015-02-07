#!/bin/sh
##
## If within a Git directory:
## git docker start
##
## If outside of a Git directory you must specify the relative path and container name:
## git docker start UsabilityDynamics/www.sample-site.com
##
## git config docker.paths.sources
## git config docker.paths.storage
##
##
## RunDockerContainer DiscoDonniePresents/www.discodonniepresents.com   discodonniepresents.com   50800   develop
## RunDockerContainer DiscoDonniePresents/www.discodonniepresents.com   discodonniepresents.com   50840
## RunDockerContainer UsabilityDynamics/www.sample-site.com
## RunDockerContainer UsabilityDynamics/www.libertybellagents.com
##
##
## @author potanin@UD
## @todo Only fetch passed TAG if not currently in git repository.

function GitDockerStart {
  ## echo "Starting Git Docker container."

  export _TAG=${1}
  export _PORT=${3}
  export _BRANCH=${4}

  if [ -f /etc/environment ]; then
    source /etc/environment
  fi

  if [ -d ${PWD}/.git ]; then
    ## echo " - You seem to be in a git repo.."
    GIT_DIR=${PWD}/.git
    GIT_WORK_TREE=${PWD}
  else

    if [[ ${_TAG} != "" ]]; then
      GIT_DIR=$(git config docker.paths.sources)"/${_TAG}/.git";
      GIT_WORK_TREE=$(git config docker.paths.sources)"/${_TAG}";
    else
      echo " - Not in a Git directory and no tag specified. Perhaps clone repository first?"
      return;
    fi

  fi

  if [ $(git config docker.memory.limit) = "" ]; then
    echo "Please set Docker Memory Limit. e.g. [git config docker.memory.limit 2g]";
    return;
  fi;

  ## Clone or Refresh
  GitDockerReload ${_TAG};

  ## > combine "DiscoDonniePresents/www.discodonniepresents.com"
  export _TAG=$(basename $(dirname ${GIT_WORK_TREE}))/$(basename ${GIT_WORK_TREE});

  ## > lowercase "discodonniepresents/www.discodonniepresents.com"
  export _IMAGE_NAME=$( echo $(basename $(dirname ${GIT_WORK_TREE}))/$(basename ${GIT_WORK_TREE}) | tr "/" "/" | tr '[:upper:]' '[:lower:]' )

  ## Create Storage
  if [ ! -d ${GIT_WORK_TREE} ]; then
    export _STORAGE_DIR=$(git config docker.paths.storage)"/${_TAG}";
    echo "- Creating storage in <${_STORAGE_DIR}> and setting ownership to <${USER}>."
    chown -R ${USER} ${_STORAGE_DIR}
    mkdir -p ${_STORAGE_DIR}/media
  fi

  ## Update settings now that we have git repository...
  _HOSTNAME=${2:-$(basename `git --git-dir=${GIT_DIR} rev-parse --show-toplevel`)}
  _BRANCH=$(git --git-dir=${GIT_DIR} rev-parse --abbrev-ref HEAD)
  _CONTAINER_NAME=${_HOSTNAME}.${_BRANCH}.git

  ## Get variables from existing container.
  _CONTAINER_WWW_PATH=$(docker inspect --format '{{ index .Volumes "/var/www" }}' ${_CONTAINER_NAME})
  _CONTAINER_MEMORY_LIMIT=$(git config docker.memory.limit)

  ## Build / Rebuild
  ## @note we are silencing all errors so a failed build will not stop rocess...
  if [ -f "${GIT_WORK_TREE}/Dockerfile" ]; then

    echo " - Building Docker Image <${_IMAGE_NAME}:${_BRANCH}>. (Be advised, we do not, yet, check if Dockerfile has changed since last build.)"
    docker build --tag=${_IMAGE_NAME}:${_BRANCH} --quiet=true ${GIT_WORK_TREE} >/dev/null 2>&1

    ## Remove Old Instance
    echo " - Checking for and remvoing old container <${_CONTAINER_NAME}>."
    docker rm -fv ${_CONTAINER_NAME} >/dev/null 2>&1

    ## Create New Instance
    echo " - Starting server <${_HOSTNAME}.${_BRANCH}.git>."
    export CONTAINER_ID=$(docker run -itd --restart=always \
      --name=${_CONTAINER_NAME} \
      --hostname=${_HOSTNAME} \
      --memory=${_CONTAINER_MEMORY_LIMIT} \
      --add-host=api.wordpress.com:${COREOS_PRIVATE_IPV4} \
      --add-host=downloads.wordpress.com:${COREOS_PRIVATE_IPV4} \
      --add-host=controller.internal:${COREOS_PRIVATE_IPV4} \
      --publish=${COREOS_PRIVATE_IPV4}:${_PORT}:80 \
      --env=GITGIT_WORK_TREE=/var/www \
      --env=GIT_DIR=/home/core/${_HOSTNAME}.git \
      --volume=${GIT_WORK_TREE}:/var/www/wp-content/storage \
      --volume=${GIT_WORK_TREE}:/var/www \
      --workdir=${GIT_WORK_TREE} \
      ${_IMAGE_NAME}:${_BRANCH})

    echo " - Server started with ID <${CONTAINER_ID}>."

  else
    echo " - No Dockerfile in ${GIT_WORK_TREE}/Dockerfile"
  fi

}
