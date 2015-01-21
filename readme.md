git-docker
============

This script finds git repos within the given path that have unstaged changes and/or unpushed commits (in their currently checked-out branch).


Installation
------------

Use NPM to install module globally:
```
npm install --global UsabilityDynamics/git-docker
```

```
git clone git@github.com:UsabilityDynamics/git-docker.git /opt/sources/UsabilityDynamics/git-docker
ln -s /opt/sources/UsabilityDynamics/git-docker/bin/git-build ~/.bin
ln -s /opt/sources/UsabilityDynamics/git-docker/bin/git-run ~/.bin
ln -s /opt/sources/UsabilityDynamics/git-docker/bin/git-start ~/.bin
ln -s /opt/sources/UsabilityDynamics/git-docker/bin/git-docker ~/.bin
ln -s /opt/sources/UsabilityDynamics/git-docker/bin/git-container ~/.bin
```

Usage
-----
If a site/app repository has a Dockerfile it may be run. Additional settings may be stored in package.json or composer.json.

```sh
cd ./www.sample-site.com
git container build
git container start
```

```sh
git docker build
git docker create
```
