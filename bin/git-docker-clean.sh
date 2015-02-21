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


function GitDockerClean {

  ## echo "Starting Git Docker container."

  git config --local --unset docker.meta.port
  git config --local --unset docker.meta.pid
  git config --local --unset docker.meta.container
  git config --local --unset docker.memory.limit

}