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
## @author potanin@UD
## @todo Only fetch passed TAG if not currently in git repository.


function GitDockerStart {
  ## echo "Starting Git Docker container."

  function _GenerateHash {
   echo $(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
  }

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

  if [ "x$(git config docker.paths.runtime)" = "x" ]; then
    echo "Please set Docker runtime path. e.g. [git config --global docker.paths.runtime /opt/runtime]";
    return;
  fi;

  if [ "x$(git config docker.paths.storage)" = "x" ]; then
    echo "Please set Docker storage path. e.g. [git config --global docker.paths.storage /opt/storage]";
    return;
  fi;

  if [ "x$(git config docker.memory.limit)" = "x" ]; then
    echo "Please set Docker Memory Limit. e.g. [git config --global docker.memory.limit 2g]";
    return;
  fi;

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

  ## Clone or Refresh
  GitDockerReload ${_TAG};

  ## > combine "DiscoDonniePresents/www.discodonniepresents.com"
  export _TAG=$(basename $(dirname ${GIT_WORK_TREE}))/$(basename ${GIT_WORK_TREE});

  ## Update settings now that we have git repository...
  _REPOSITORY_NAME=$(basename $(git remote show -n origin | grep Fetch | cut -d: -f2-))
  _HOSTNAME=${_REPOSITORY_NAME}
  _BRANCH=$(git --git-dir=${GIT_DIR} rev-parse --abbrev-ref HEAD)
  _CONTAINER_NAME=$( echo "${_HOSTNAME}.${_BRANCH}.git" | tr '[:upper:]' '[:lower:]' )
  _GLOBAL_IMAGE_NAME=$( echo $(basename $(dirname ${GIT_WORK_TREE}))/$(basename ${GIT_WORK_TREE}) | tr "/" "/" | tr '[:upper:]' '[:lower:]' )
  _LOCAL_IMAGE_NAME=${_HOSTNAME}
  _CONTAINER_MEMORY_LIMIT=$(git config docker.memory.limit)

  ## Set Default Memory Limit
  # if [ "x${_CONTAINER_MEMORY_LIMIT}" != "x" ]; then
  #   _CONTAINER_MEMORY_LIMIT=2g
  # fi;

  ## Create Storage
  if [ -d ${GIT_WORK_TREE} ]; then
    export _STORAGE_DIR=$(git config docker.paths.storage)"/${_REPOSITORY_NAME}";
    echo " - Creating storage in <${_STORAGE_DIR}> and setting ownership to <${USER}>."
    mkdir -p ${_STORAGE_DIR}
    # nohup sudo chown -R ${USER} ${_STORAGE_DIR} >/dev/null 2>&1
  fi

  ## Get variables from existing container.
  _OLD_CONTAINER_ID=$(docker ps -a | grep "${_CONTAINER_NAME}" |  awk '{print $1}')

  ## echo $(docker ps -a | grep "${_CONTAINER_NAME}" |  awk '{print $1}')
  ## docker inspect --format '{{ .NetworkSettings.IPAddress }}' ${_CID}

  #
  # Commented for now
  # use _PUBLISH_PORT="${COREOS_PRIVATE_IPV4}:${_PORT}";
  # instead of condition below.
  #
  # Need to add condition which checks if container is active ( running )
  # Because if not, - _PUBLISH_PORT will be empty ( 0.0.0.0 ) and error will be caused.
  # peshkov@UD
  #
  #if [ "x${_OLD_CONTAINER_ID}" != "x" ]; then
  #  _PUBLISH_PORT=$(docker port ${_CONTAINER_NAME} 80)
  #else
  #  _PUBLISH_PORT="${COREOS_PRIVATE_IPV4}:${_PORT}";
  #fi

  #
  # ${_PORT} is always empty!
  # It's being got from:
  # export _PORT=${3}
  # at the beginning of script,
  # however I do not see how it's being passed to script.
  # git-docker.sh contains $2 $3 params for 'git docker start', but where they are from?
  #
  # peshkov@UD
  #
  _PUBLISH_PORT="${COREOS_PRIVATE_IPV4}:${_PORT}";

  _RUNTIME_PATH=$(git config docker.paths.runtime)/$(echo -n $(md5sum <<< ${_CONTAINER_NAME} | awk '{print $1}'));

  if [ "x${_RUNTIME_PATH}" != "x" ]; then
    mkdir -p ${_RUNTIME_PATH};
    echo " - Created container runtime path <${_RUNTIME_PATH}>."
  fi

  ## Build / Rebuild
  ## @note we are silencing all errors so a failed build will not stop rocess...
  if [ -f "${GIT_WORK_TREE}/Dockerfile" ]; then
    echo " - Building image <${_HOSTNAME}:${_BRANCH}> from Dockerfile. (Be advised, we do not, yet, check if Dockerfile has changed since last build.)"
    docker build --tag=${_LOCAL_IMAGE_NAME}:${_BRANCH} --quiet=true ${GIT_WORK_TREE} >/dev/null 2>&1

    ## Remove Old Instance
    if [ "x${_OLD_CONTAINER_ID}" != "x" ]; then
      echo " - Removing old container <${_OLD_CONTAINER_ID}>."
      docker rm -fv ${_CONTAINER_NAME} >/dev/null 2>&1
    else
      echo " - No old container found."
    fi;

    ## Create New Instance
    echo " - Starting server <${_HOSTNAME}.${_BRANCH}.git>."
    NEW_CONTAINER_ID=$(docker run -itd --restart=always \
      --name=${_CONTAINER_NAME} \
      --hostname=${_HOSTNAME} \
      --memory=${_CONTAINER_MEMORY_LIMIT} \
      --add-host=localhost:127.0.0.1 \
      --add-host=api.wordpress.com:${COREOS_PRIVATE_IPV4} \
      --add-host=downloads.wordpress.com:${COREOS_PRIVATE_IPV4} \
      --add-host=controller.internal:${COREOS_PRIVATE_IPV4} \
      --publish=${_PUBLISH_PORT}:80 \
      --env=DOCKER_IMAGE=${_LOCAL_IMAGE_NAME}:${_BRANCH} \
      --env=DOCKER_CONTAINER=${_CONTAINER_NAME} \
      --env=GIT_WORK_TREE=/var/www \
      --env=GIT_DIR=/var/www/.git \
      --volume=${_STORAGE_DIR}:/var/storage \
      --volume=${GIT_WORK_TREE}:/var/www \
      --workdir=/var/www \
      ${_LOCAL_IMAGE_NAME}:${_BRANCH})

  else

    ## Remove Old Instance
    if [ "x${_OLD_CONTAINER_ID}" != "x" ]; then
      echo " - Removing old container <${_OLD_CONTAINER_ID}>."
      docker rm -fv ${_CONTAINER_NAME} >/dev/null 2>&1
    fi;

    _LOCAL_IMAGE_NAME="wpcloud/site"

    ## Create New "Dynamic" Instance
    ## --volume=/home/core/.ssh:/home/core/.ssh \
    ##
    echo " - Starting container <${_CONTAINER_NAME}> using the <wpcloud/site> image."
    NEW_CONTAINER_ID=$(docker run -itd --restart=always \
      --name=${_CONTAINER_NAME} \
      --hostname=${_HOSTNAME} \
      --memory=${_CONTAINER_MEMORY_LIMIT} \
      --add-host=localhost:127.0.0.1 \
      --add-host=api.wordpress.com:${COREOS_PRIVATE_IPV4} \
      --add-host=downloads.wordpress.com:${COREOS_PRIVATE_IPV4} \
      --add-host=controller.internal:${COREOS_PRIVATE_IPV4} \
      --publish=${_PUBLISH_PORT}:80 \
      --env=DOCKER_IMAGE=${_LOCAL_IMAGE_NAME}:${_BRANCH} \
      --env=DOCKER_CONTAINER=${_CONTAINER_NAME} \
      --env=GIT_WORK_TREE=/var/www \
      --env=GIT_DIR=/opt/sources/${_CONTAINER_NAME} \
      --volume=${GIT_DIR}:/opt/sources/${_CONTAINER_NAME} \
      --volume=${GIT_WORK_TREE}:/var/www \
      --volume=${_STORAGE_DIR}:/var/storage \
      --workdir=/var/www \
      ${_LOCAL_IMAGE_NAME})

    ## @note Right now they are linked because we mount /var/www...
    ## echo " - Checking-out <${_BRANCH}> branch in container."
    ## docker exec ${NEW_CONTAINER_ID} git checkout ${_BRANCH}

    ## docker exec ${NEW_CONTAINER_ID} rm -rf /var/www/wp-content/uploads
    ## docker exec ${NEW_CONTAINER_ID} ln -sf /var/storage /var/www/wp-content/storage
    ## docker exec ${NEW_CONTAINER_ID} ln -sf /var/storage /var/www/wp-content/uploads
    ## docker exec ${NEW_CONTAINER_ID} sudo service apache2 start
    ## docker exec ${NEW_CONTAINER_ID} sudo service php5-fpm start
    ## docker exec ${NEW_CONTAINER_ID} sudo service newrelic-daemon stop

  fi

  ## Record used port.
  if [ "x${_PUBLISH_PORT}" != "x" ]; then
    git config docker.port = ${_PUBLISH_PORT}
  fi

  ## $(docker inspect --format '{{ .State.Pid }}' ${NEW_CONTAINER_ID}])

  if [ "x${NEW_CONTAINER_ID}" != "x" ]; then
    echo " - Server started with ID <${NEW_CONTAINER_ID}>."

    ## git config --global docker.webhooks.slack T02C4SEGN/B03AGFH7E/2EPfLT2rglQsyGdvmnRpkf3p
    if [ "x$(git config docker.webhooks.slack)" != "x" ]; then
      echo " - Posting WebHook to <Slack>."

      if [ "x${_OLD_CONTAINER_ID}" != "x" ]; then
        curl -X POST --data-urlencode 'payload={"channel": "#delivery", "username": "'${_HOSTNAME}'", "text": "Container for ['${_BRANCH}'] branch on ['$(hostname -s)'.wpcloud.io] reloaded.", "icon_emoji": ":cloud:"}' "https://hooks.slack.com/services/$(git config docker.webhooks.slack)"  --silent >/dev/null
      else
        curl -X POST --data-urlencode 'payload={"channel": "#delivery", "username": "'${_HOSTNAME}'", "text": "Container for ['${_BRANCH}'] branch started on ['$(hostname -s)'.wpcloud.io] using internal address [http://'$(docker port ${_CONTAINER_NAME} 80)'].", "icon_emoji": ":cloud:"}' "https://hooks.slack.com/services/$(git config docker.webhooks.slack)"  --silent >/dev/null
      fi

    fi

    ## git config --global docker.webhooks.wpcloud https://api.wpcloud.io
    ## git config --global docker.wpcloud.token gpbevhqpubcamtsy
    ##
    ## https://api.wpcloud.io/application/v1/provision.jsonhttps://api.wpcloud.io/application/v1/provision.json?access-token=gpbevhqpubcamtsy
    if [ "x$(git config docker.webhooks.wpcloud)" != "x" ]; then
      echo " - Posting WebHook to <api.wpCloud.io>."
      curl -H "Content-Type: application/json" -d '{ "_id": "'${NEW_CONTAINER_ID}'", "_type": "memoryLimit": "'{_CONTAINER_MEMORY_LIMIT}'", "container", "image": "'${_LOCAL_IMAGE_NAME}'", "name": "'${_CONTAINER_NAME}'", "branch": "'${_BRANCH}'", "hostname": "'$(hostname)'", "address": "'$(docker port ${_CONTAINER_NAME} 80)'"}' "$(git config docker.webhooks.wpcloud)/application/v1/provision.json?access-token=$(git config docker.wpcloud.token)" --silent >/dev/null
    fi;

  fi

}
