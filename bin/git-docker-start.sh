#!/bin/bash
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

  export _ORIGINAL_PWD=${PWD};

  if [[ ${GIT_WORK_TREE} != "" ]]; then
    cd ${GIT_WORK_TREE};
  fi;

  if [ -f /etc/environment ]; then
    source /etc/environment
  fi

  if [ "x$(git config --global docker.paths.runtime)" = "x" ]; then
    echo "Please set Docker runtime path. e.g. [git config --global docker.paths.runtime /opt/runtime]";
    return;
  fi;

  if [ "x$(git config docker.memory.limit)" = "x" ]; then
    echo "Please set Docker Memory Limit. e.g. [git config --global docker.memory.limit 6g]";
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
      if [[ ${GIT_DOCKER_SILENT} != true ]]; then echo "[git/docker] - Not in a Git directory and no tag specified. Perhaps clone repository first?."; fi;
      return;
    fi

  fi

  ## Global Variables Override
  GIT_DOCKER_TYPE=$(git config --local docker.type)

  if [ -f ~/.git-docker/${GIT_DOCKER_TYPE}.sh ]; then
    if [[ ${GIT_DOCKER_SILENT} != true ]]; then echo "[git/docker] Loading ~/.git-docker/${GIT_DOCKER_TYPE}.sh."; fi;
    source ~/.git-docker/${GIT_DOCKER_TYPE}.sh
  fi

  ## > combine "DiscoDonniePresents/www.discodonniepresents.com"
  export _TAG=$(basename $(dirname ${GIT_WORK_TREE}))/$(basename ${GIT_WORK_TREE});

  ## Update settings now that we have git repository...
  _REPOSITORY_NAME=$(basename $(git remote show -n origin | grep Fetch | cut -d: -f2-))

    ## strip '.git" from very end
  _REPOSITORY_NAME=${_REPOSITORY_NAME/%.git/}

  _HOSTNAME=${_REPOSITORY_NAME}
  _BRANCH=$(git --git-dir=${GIT_DIR} rev-parse --abbrev-ref HEAD)

  if [ "x$(git config --local docker.meta.name)" = "x" ]; then
    _CONTAINER_NAME=$( echo "${_HOSTNAME}.${_BRANCH}" | tr '[:upper:]' '[:lower:]' )
  else
    _CONTAINER_NAME=$(git config --local docker.meta.name);
  fi;

  ## strip first occurange of '.git"
  _CONTAINER_NAME="${_CONTAINER_NAME/.git/}"

  #if [ "x$(git config --global docker.annex)" == "x" ]; then
  #  _CONTAINER_NAME=$( echo "${_HOSTNAME}" | tr '[:upper:]' '[:lower:]' )
  #fi

  _GLOBAL_IMAGE_NAME=$( echo $(basename $(dirname ${GIT_WORK_TREE}))/$(basename ${GIT_WORK_TREE}) | tr "/" "/" | tr '[:upper:]' '[:lower:]' )
  _ORGANIZATION_NAME=$(basename $(dirname ${GIT_WORK_TREE}))
  _LOCAL_IMAGE_NAME=${_HOSTNAME}
  _CONTAINER_MEMORY_LIMIT=$(git config docker.memory.limit)

  ##_STORAGE_DIR=${_STORAGE_DIR}/\.git/shit}

  ## Create Storage
  if [ -d ${GIT_WORK_TREE} ]; then
    export _STORAGE_DIR=$(git config docker.paths.storage)"/${_ORGANIZATION_NAME}/${_REPOSITORY_NAME}";
    if [[ ${GIT_DOCKER_SILENT} != true ]]; then echo "[git/docker] Creating storage in <${_STORAGE_DIR}> and setting ownership to <${USER}>"; fi;
    mkdir -p ${_STORAGE_DIR}
    # nohup sudo chown -R ${USER} ${_STORAGE_DIR} >/dev/null 2>&1
  fi

  if [ ! -d "${GIT_WORK_TREE}/.git" ]; then
    echo "[] Not a git repository, exiting.";
    exit;
  fi;

  ## Get variables from existing container.
  _OLD_CONTAINER_ID=$(git config --local docker.meta.container)

  _PUBLISH_PORT=$(git config --local docker.meta.port)

  if [ "x${_PUBLISH_PORT}" = "x" ]; then
    _PORT=$(git config docker.meta.port);
    _PUBLISH_PORT="${COREOS_PRIVATE_IPV4}:${_PORT}";
  fi

  ## Strip out our address from "port" (for legacy)
  _PUBLISH_PORT="${_PUBLISH_PORT/${COREOS_PRIVATE_IPV4}:}"

  ## Try to get port from git setting.
  #if [ "x${_PORT}" != "x" ]; then
  #  _PORT=$(git config docker.meta.port);
  #fi

  #_RUNTIME_PATH=$(git config docker.paths.runtime)/$(echo -n $(md5sum <<< ${_CONTAINER_NAME} | awk '{print $1}'));

  #if [ "x${_RUNTIME_PATH}" != "x" ]; then
    # mkdir -p ${_RUNTIME_PATH};
    #echo " - Created container runtime path <${_RUNTIME_PATH}>."
    #git config --local docker.path.runtime="${_RUNTIME_PATH}"
  #fi

  ### echo "_STORAGE_DIR: ${_STORAGE_DIR}";
  ### echo "_ORGANIZATION_NAME: ${_ORGANIZATION_NAME}";
  ### echo "_GLOBAL_IMAGE_NAME: ${_GLOBAL_IMAGE_NAME}";
  ### echo "_REPOSITORY_NAME: ${_REPOSITORY_NAME}";
  ### echo "_OLD_CONTAINER_ID: ${_OLD_CONTAINER_ID}";
  ### echo "_CONTAINER_NAME: ${_CONTAINER_NAME}";
  ### echo "_PUBLISH_PORT: ${_PUBLISH_PORT}";
  ### echo "_RUNTIME_PATH: ${_RUNTIME_PATH}";
  ### echo "_RUNTIME_PATH: ${_CONTAINER_MEMORY_LIMIT}";

  ## Set Default.
  if [ "x$(git config --local docker.meta.privileged)" == "x" ]; then
    git config --local --replace-all docker.meta.privileged "false"
  fi

  ## Build / Rebuild
  ## @note we are silencing all errors so a failed build will not stop rocess...
  if [ -f "${GIT_WORK_TREE}/Dockerfile" ]; then
    echo " - Building image <${_HOSTNAME}:${_BRANCH}> from Dockerfile. (Be advised, we do not, yet, check if Dockerfile has changed since last build.)"
    docker build --tag=${_LOCAL_IMAGE_NAME}:${_BRANCH} --quiet=true ${GIT_WORK_TREE} >/dev/null 2>&1

    ## Remove Old Instance
    if [ "x${_OLD_CONTAINER_ID}" != "x" ]; then
      if [[ ${GIT_DOCKER_SILENT} != true ]]; then echo "[git/docker] Removing old container <${_OLD_CONTAINER_ID}>."; fi;
      docker rm -fv ${_CONTAINER_NAME} >/dev/null 2>&1
    else
      if [[ ${GIT_DOCKER_SILENT} != true ]]; then echo "[git/docker] No old container found."; fi;
    fi;

    ## Clone or Refresh
    GitDockerReload ${_TAG};

    ## Create New Instance
    if [[ ${GIT_DOCKER_SILENT} != true ]]; then echo "[git/docker] Starting server <${_HOSTNAME}.${_BRANCH}>."; fi;

    NEW_CONTAINER_ID=$(docker run -itd --restart=always \
      --name=${_CONTAINER_NAME} \
      --hostname=${_HOSTNAME} \
      --memory=${_CONTAINER_MEMORY_LIMIT} \
      --add-host=localhost:127.0.0.1 \
      --add-host=${_HOSTNAME/www./}:127.0.0.1 \
      --add-host=api.wpcloud.io:${COREOS_PRIVATE_IPV4} \
      --add-host=downloads.wpcloud.io:${COREOS_PRIVATE_IPV4} \
      --add-host=repository.wpcloud.io:${COREOS_PRIVATE_IPV4} \
      --add-host=controller.internal:${COREOS_PRIVATE_IPV4} \
      --publish=${_PUBLISH_PORT}:80 \
      --privileged=$(git config --local docker.meta.privileged) \
      --env=DOCKER_IMAGE=${_LOCAL_IMAGE_NAME}:${_BRANCH} \
      --env=DOCKER_CONTAINER=${_CONTAINER_NAME} \
      --env=GIT_BRANCH=${_BRANCH} \
      --volume=${_STORAGE_DIR}:/var/storage \
      --volume=${GIT_WORK_TREE}:/var/www \
      --workdir=/var/www \
      ${GIT_DOCKER_RUN_ARGS} ${_LOCAL_IMAGE_NAME}:${_BRANCH})

      git config --local --replace-all docker.meta.container ${NEW_CONTAINER_ID}

      if [ "x${GIT_DOCKER_SCRIPT_ON_START}" != "x" ]; then
        docker exec ${NEW_CONTAINER_ID} /bin/bash -c "${GIT_DOCKER_SCRIPT_ON_START}"  >/dev/null 2>&1;
      fi

  else

    ## Remove Old Instance
    if [ "x${_OLD_CONTAINER_ID}" != "x" ]; then
      if [[ ${GIT_DOCKER_SILENT} != true ]]; then echo "[git/docker] Removing old container <${_OLD_CONTAINER_ID}>."; fi;
      docker rm -fv ${_CONTAINER_NAME} >/dev/null 2>&1
    fi;

    ## Clone or Refresh
    GitDockerReload ${_TAG};

    _LOCAL_IMAGE_NAME=$(git config docker.meta.image)

    if [ "x${_LOCAL_IMAGE_NAME}" = "x" ]; then
      _LOCAL_IMAGE_NAME="wpcloud/site"
    fi;

    ## Create New "Dynamic" Instance
    ##
    if [[ ${GIT_DOCKER_SILENT} != true ]]; then echo "[git/docker] Starting container <${_CONTAINER_NAME}> using the <${_LOCAL_IMAGE_NAME}> image."; fi;

    ___RUN_COMMAND="docker run -itd --restart=always \
      --name=${_CONTAINER_NAME} \
      --hostname=${_HOSTNAME} \
      --memory=${_CONTAINER_MEMORY_LIMIT} \
      --add-host=localhost:127.0.0.1 \
      --add-host=${_HOSTNAME/www./}:127.0.0.1 \
      --add-host=api.wpcloud.io:${COREOS_PRIVATE_IPV4} \
      --publish=${_PUBLISH_PORT}:80 \
      --privileged=$(git config --local docker.meta.privileged) \
      --env=DOCKER_IMAGE=${_LOCAL_IMAGE_NAME}:${_BRANCH} \
      --env=DOCKER_CONTAINER=${_CONTAINER_NAME} \
      --env=GIT_BRANCH=${_BRANCH} \
      --volume=$(pwd):/var/www \
      --volume=${_STORAGE_DIR}:/var/storage \
      --workdir=/var/www \
      ${GIT_DOCKER_RUN_ARGS} ${_LOCAL_IMAGE_NAME}";

    NEW_CONTAINER_ID=$(${___RUN_COMMAND})

    if [ "x${GIT_DOCKER_SCRIPT_ON_START}" != "x" ]; then
      if [[ ${GIT_DOCKER_SILENT} != true ]]; then echo "[git/docker] Running the on-start command.."; fi;
      docker exec ${NEW_CONTAINER_ID} /bin/bash -c "${GIT_DOCKER_SCRIPT_ON_START}"  >/dev/null 2>&1;
    fi

    git config --local --replace-all docker.meta.container ${NEW_CONTAINER_ID}
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

  ## Record used port. Strip out the private IP.
  _PUBLISHED_PORT=$(docker port $(git config --local docker.meta.container) 80);
  _PUBLISHED_PORT=${_PUBLISHED_PORT/${COREOS_PRIVATE_IPV4}:/}

  ## Save published port to git config
  if [ "x${_PUBLISHED_PORT}" != "x" ]; then
    git config --replace-all docker.meta.port ${_PUBLISHED_PORT}
  fi;

  ## Save Docker Container PID to git config
  git config --replace-all docker.meta.pid $(docker inspect --format '{{ .State.Pid }}' $(git config docker.meta.container))

  ## Save actual Image information.
  git config --replace-all docker.image.name $(docker inspect --format '{{ .Config.Image }}' $(git config docker.meta.container))
  git config --replace-all docker.image.id $(docker inspect --format '{{ .Image }}' $(git config docker.meta.container))

  if [ "x${NEW_CONTAINER_ID}" != "x" ]; then
    if [[ ${GIT_DOCKER_SILENT} != true ]]; then echo "[git/docker] Server started with ID <${NEW_CONTAINER_ID}> for <${_CONTAINER_NAME}>, published to <${_PUBLISHED_PORT}> port."; fi;

    if [[ ${GIT_DOCKER_SILENT} = true ]]; then echo "[git/docker] Server started with ID <${NEW_CONTAINER_ID}> for <${_CONTAINER_NAME}>, published to <${_PUBLISHED_PORT}> port."; fi;

    if [ "x$(git config --local docker.meta.privileged)" = "false" ]; then
      if [[ ${GIT_DOCKER_SILENT} != true ]]; then echo "[git/docker] Using priviledged mode."; fi;
    fi

    ## git config --global docker.webhooks.slack T02C4SEGN/B03AGFH7E/2EPfLT2rglQsyGdvmnRpkf3p
    if [ "x$(git config docker.webhooks.slack)" != "x" ]; then

      if [[ ${GIT_DOCKER_VERBOSE} == true ]]; then echo "[git/docker] Posting WebHook to <Slack>."; fi;

      ##
      ##if [ "x${_OLD_CONTAINER_ID}" != "x" ]; then
      ##  curl -X POST --data-urlencode 'payload={"channel": "#delivery", "username": "'${_HOSTNAME}'", "text": "Container for ['${_BRANCH}'] branch on ['$(hostname -s)'.wpcloud.io] reloaded.", "icon_emoji": ":cloud:"}' "https://hooks.slack.com/services/$(git config docker.webhooks.slack)"  --silent >/dev/null
      ##else
      ##  curl -X POST --data-urlencode 'payload={"channel": "#delivery", "username": "'${_HOSTNAME}'", "text": "Container for ['${_BRANCH}'] branch started on ['$(hostname -s)'.wpcloud.io] using internal address [http://'$(docker port ${_CONTAINER_NAME} 80)'].", "icon_emoji": ":cloud:"}' "https://hooks.slack.com/services/$(git config docker.webhooks.slack)"  --silent >/dev/null
      ##fi

    fi

    ## git config --global docker.webhooks.wpcloud
    ## git config --global docker.webhooks.wpcloud https://api.wpcloud.io
    ## git config --global docker.wpcloud.token gpbevhqpubcamtsy
    ##
    ## https://api.wpcloud.io/application/v1/provision.jsonhttps://api.wpcloud.io/application/v1/provision.json?access-token=gpbevhqpubcamtsy
    #if [ "x$(git config docker.webhooks.wpcloud)" != "x" ]; then
    #  echo " - Posting WebHook to <api.wpCloud.io>."
    #  curl -H "Content-Type: application/json" -d '{ "_id": "'${NEW_CONTAINER_ID}'", "_type": "memoryLimit": "'{_CONTAINER_MEMORY_LIMIT}'", "container", "image": "'${_LOCAL_IMAGE_NAME}'", "name": "'${_CONTAINER_NAME}'", "branch": "'${_BRANCH}'", "hostname": "'$(hostname)'", "address": "'$(docker port ${_CONTAINER_NAME} 80)'"}' "$(git config docker.webhooks.wpcloud)/application/v1/provision.json?access-token=$(git config docker.wpcloud.token)" --silent >/dev/null
    #fi;

  fi

  cd ${_ORIGINAL_PWD};

}
