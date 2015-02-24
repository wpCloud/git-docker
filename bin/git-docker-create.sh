#!/bin/bash
## Create Working Environment
##
## git docker create git@github.com:DiscoDonniePresents/www.discodonniepresents.com.git
##
## www.discodonniepresents.com.git  - 247M
## www.discodonniepresents.com      - 737M
##
function GitDockerCreate {
  ## echo "Git Container."

  if [ "x$(git config docker.paths.sources)" = "x" ]; then
    echo "Please set Docker Sources path. e.g. [git config --global docker.paths.sources /opt/sources]";
    return;
  fi;

  ## git clone ${1} --bare --no-hardlinks $(git config docker.paths.sources)/
  cd $(git config docker.paths.sources);
  time git clone ${1} --bare --no-hardlinks --shared

}


##export -f GitDockerInfo()