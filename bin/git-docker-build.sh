#!/bin/bash
##
##
function GitDockerBuild {
  echo "Restart Git Container."

  export _TAG=${1}
  export _PORT=${3}
  export _BRANCH=${4}

  if [ -f /etc/environment ]; then
    source /etc/environment
  fi

}

