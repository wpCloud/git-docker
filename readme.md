* This is a git script, meaning that it can be called using `git docker`.
* When ran from within a dir repository directory, we check for existence of `Dockerfile` to determine if this repository can be ran using Docker.
* We additionally check for existence of `composer.json` for config.docker settings, such as the config.docker.port and config.docker.name to use for published port and Container nam, respectively.
* We automatically "refresh" git git repository by cleaning, resetting, fetching and pulling the current branch on `git docker restart` and `git docker reload` commands.
* The `git docker restart` and `git docker reload` commands will start the container if it does not exist.

Usage
-----
If a site/app repository has a Dockerfile it may be run. Additional settings may be stored in package.json or composer.json.

```sh
mkdir -p /opt/sources/UsabilityDynamics/www.sample-site.com
cd /opt/sources/UsabilityDynamics/www.sample-site.com
git docker start
```

```sh
git docker build
git docker create
git docker restart
git docker reload
git docker stop
```

Installation
------------

Use NPM to install module globally:
```
npm install --global UsabilityDynamics/git-docker
```

On CoreOS, or any other machine without Node installed, you may install this manually. We assume that the ~/.bin directory is added to the $PATH variable.
```
git clone git@github.com:UsabilityDynamics/git-docker.git /opt/sources/UsabilityDynamics/git-docker
ln -sf /opt/sources/UsabilityDynamics/git-docker/bin/git-docker ~/.bin
```

```
export PATH=$PATH:/home/core/.bin
git-docker info
```

Global Configuration
====================
Git Docker needs to know into which directories your Git repositories will be cloned.

* /opt/sources/{OrganizationName}/{RepositoryName} - Default for repositories. The internals are mounted to /var/www
* /opt/storage/{OrganizationName}/{RepositoryName} - Default for persistent storage. The internals are mounted to /var/storage

```
git config --global docker.paths.sources /opt/sources
git config --global docker.paths.storage /opt/storage
```

As you may be aware, you may view all global Git configurations like so:
```
git config -l
```