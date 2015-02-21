#!/bin/sh
##
## ## Supported Command Line Arguments
## - Repository ID - The {OrganizationName}/{RepositoryName} GitHub-compatible identifier.
## - Branch - The branch to use, otherwise we default to current/default branch. If brench specified, we will switch to it on refresh/reload/start/build.
##
## ## Used Global Configurations
## git config docker.paths.sources
## git config docker.paths.storage
## git config docker.memory.limit
##
## ## Supported Git Environment Variables
## GIT_DIR
## GIT_WORK_TREE
## GIT_AUTHOR_NAME
## GIT_AUTHOR_EMAIL
## GIT_COMMITTER_NAME
## GIT_COMMITTER_EMAIL
##

## Setup Conditional Variables
export GIT_DOCKER_DIRECTORY="$(dirname $(readlink -f $0))"
export GIT_DOCKER_ACTION=${1}

echo "Running Git Docker."

## Include Bash Script Dependencies
if [ -f "${GIT_DOCKER_DIRECTORY}/git-docker-start.sh" ];    then  source "${GIT_DOCKER_DIRECTORY}/git-docker-start.sh";     fi
if [ -f "${GIT_DOCKER_DIRECTORY}/git-docker-stop.sh" ];     then  source "${GIT_DOCKER_DIRECTORY}/git-docker-stop.sh";      fi
if [ -f "${GIT_DOCKER_DIRECTORY}/git-docker-restart.sh" ];  then  source "${GIT_DOCKER_DIRECTORY}/git-docker-restart.sh";   fi
if [ -f "${GIT_DOCKER_DIRECTORY}/git-docker-reload.sh" ];   then  source "${GIT_DOCKER_DIRECTORY}/git-docker-reload.sh";    fi
if [ -f "${GIT_DOCKER_DIRECTORY}/git-docker-build.sh" ];    then  source "${GIT_DOCKER_DIRECTORY}/git-docker-build.sh";     fi
if [ -f "${GIT_DOCKER_DIRECTORY}/git-docker-info.sh" ];     then  source "${GIT_DOCKER_DIRECTORY}/git-docker-info.sh";      fi
if [ -f "${GIT_DOCKER_DIRECTORY}/git-docker-shell.sh" ];    then  source "${GIT_DOCKER_DIRECTORY}/git-docker-shell.sh";     fi
if [ -f "${GIT_DOCKER_DIRECTORY}/git-docker-create.sh" ];   then  source "${GIT_DOCKER_DIRECTORY}/git-docker-create.sh";      fi
if [ -f "${GIT_DOCKER_DIRECTORY}/git-docker-clean.sh" ];     then  source "${GIT_DOCKER_DIRECTORY}/git-docker-clean.sh";      fi
if [ -f "${GIT_DOCKER_DIRECTORY}/git-docker-list.sh" ];     then  source "${GIT_DOCKER_DIRECTORY}/git-docker-list.sh";      fi

## Route Actions.
if [[ ${GIT_DOCKER_ACTION} == "info" ]];      then GitDockerInfo      $2 $3;    fi;
if [[ ${GIT_DOCKER_ACTION} == "start" ]];     then GitDockerStart     $2 $3;    fi;
if [[ ${GIT_DOCKER_ACTION} == "create" ]];    then GitDockerCreate    $2;       fi;
if [[ ${GIT_DOCKER_ACTION} == "stop" ]];      then GitDockerStop      $2 $3;    fi;
if [[ ${GIT_DOCKER_ACTION} == "restart" ]];   then GitDockerRestart   $2 $3;    fi;
if [[ ${GIT_DOCKER_ACTION} == "reload" ]];    then GitDockerReload    $2 $3;    fi;
if [[ ${GIT_DOCKER_ACTION} == "build" ]];     then GitDockerBuild     $2 $3;    fi;
if [[ ${GIT_DOCKER_ACTION} == "shell" ]];     then GitDockerShell     $2 $3;    fi;
if [[ ${GIT_DOCKER_ACTION} == "list" ]];      then GitDockerList      $2 $3;    fi;
if [[ ${GIT_DOCKER_ACTION} == "clean" ]];     then GitDockerClean     $2 $3;    fi;

if [[ ${GIT_DOCKER_ACTION} == "" ]]; then
  echo "Please specify a command such as [info], [start] or [stop]. Showing [git docker info]."
  GitDockerInfo $2;
fi
