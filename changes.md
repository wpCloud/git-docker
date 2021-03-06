#### 1.1.0
* Added support for GIT_WORK_TREE environment variable.
* Added processing of ~/.git-docker hooks.
* Added "docker.type" concept.

#### 1.0.5
* Added ability to silence output by adding [--silent] argument.
* Added ability to display extra debug messages by adding [--verbose] argument.
* Added ability to interact with arbitrary sources by passing the Organization/Name as an argument.

#### 1.0.4
* Improved [git docker shell] to be able to execute commands within a container if it exists.
* Added ability to set privileged mode via [docker.meta.privileged] option.
* Replaced /bin/sh with /bin/bash since we require bash functionality for most actions.

#### 1.0.3
* Improved the way hostnames are handled and added to containers. 
* Setup Docker Image name and ID to be stored in git config after a container starts in [docker.image.name] and [docker.image.id].

#### 1.0.2
* Added [git docker clean] command to remove all Git Config settings.
* Added automatic removal of .git from remote URL.
* The PID of container is recorded to docker.meta.pid.

#### 1.0.1
* Added container port storage to Git config.
* Increased default memory limit to 6g from 3g.