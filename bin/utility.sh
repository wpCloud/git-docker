#!/bin/sh
## source /opt/sources/wpCloud/git-docker/bin/utility.sh
##
##
## GitDockerUpdateRemotes /opt/sources/UsabilityDynamics
##
function GitDockerUpdateRemotes {

  for d in ${1}/* ; do
    _NAME=$(basename ${d})

    cd ${d};

    if [ -d "${d}/.git" ]; then
      echo " - Scanning ${_NAME} - is git"
      ## git branch --set-upstream-to=origin/production production
      ## git push -u origin production --quiet
      ## git push --set-upstream origin production

    else
      echo " - Scanning ${_NAME} - is NOT git"

      git init --quiet --shared
      git config git.docker.createdBy true

      git remote add origin git@github.com:UsabilityDynamics/${_NAME}.git

      if [ ! -f ".gitignore" ]; then
        echo "node_modules" > .gitignore
        echo "error_log" > .gitignore
        echo "debug_log" > .gitignore
        echo "wp-content/uploads/*" >> .gitignore
        echo "wp-content/storage/*" >> .gitignore
      fi

      git checkout -b production

      git add . --all --ignore-errors
      git commit -m "Initial, autoated, commit from $(hostname). [ci skip]"  --quiet

      ## git branch -m production
      ## git branch --set-upstream-to=origin/production production
      ##git push --set-upstream origin production

      git push -u origin production

    fi

  done

}

##
## Useful to rebuilding all containers if a source image has changed, for instance.
##
## GitDockerRestartAll /opt/sources/UsabilityDynamics
function GitDockerRestartAll {

  for d in ${1}/* ; do
    _NAME=$(basename ${d})

    cd ${d};

    if [ -d "${d}/.git" ]; then
      git docker start
    fi

  done

}


##
##
##
function GitDockerStartAbstract {

  _CONTAINER_NAME=test.container
  _HOSTNAME=test.container

  docker run -itd --restart=always \
    --name=${_CONTAINER_NAME} \
    --hostname=${_HOSTNAME} \
    --add-host=api.wordpress.com:${COREOS_PRIVATE_IPV4} \
    --add-host=downloads.wordpress.com:${COREOS_PRIVATE_IPV4} \
    --add-host=controller.internal:${COREOS_PRIVATE_IPV4} \
    --publish=80 \
    --env=GIT_WORK_TREE=/var/www \
    --env=GIT_DIR=/opt/sources/${_CONTAINER_NAME} \
    --volume=/home/core/.ssh:/home/core/.ssh \
    --volume=${GIT_DIR}:/opt/sources/${_CONTAINER_NAME} \
    --volume=/var/www \
    --volume=/var/storage \
    --workdir=/var/www \
    wpcloud/site

}