* This is a git script, meaning that it can be called using `git docker`.
* When ran from within a dir repository directory, we check for existence of `Dockerfile` to determine if this repository can be ran using Docker.
* We additionally check for existence of `composer.json` for config.docker settings, such as the config.docker.port and config.docker.name to use for published port and Container nam, respectively.
* We automatically "refresh" git git repository by cleaning, resetting, fetching and pulling the current branch on `git docker restart` and `git docker reload` commands.
* The `git docker restart` and `git docker reload` commands will start the container if it does not exist.

### Concepts

- Single end-point for all CoreOs machines to trigger Git Docker commands.
- Clone repository if does not exist, otherwise reset/pull/clean.
- Create /opt/storage directories automatically if they don't exist.
- Rebuild image when Dockerfile changes.
- Create container with branch/sha information environment variable / name / etc.
- Allow CircleCI to call via SSH and not fail on any recoverable step to avoid CCI deployment from failing.


### Usage
If a site/app repository has a Dockerfile it may be run. Additional settings may be stored in package.json or composer.json.

```sh
mkdir -p /opt/sources/UsabilityDynamics/www.sample-site.com
cd /opt/sources/UsabilityDynamics/www.sample-site.com
git docker start
```

```sh
git docker start
git docker stop
git docker restart
git docker reload
git docker build
git docker info
git docker shell - When ran from a Git/Docker directory, will start shell within the running container.
```

### Installation

Use NPM to install module globally:
```
npm install --global UsabilityDynamics/git-docker
```

On CoreOS, or any other machine without Node installed, you may install this manually. We assume that the ~/.bin directory is added to the $PATH variable.
```
git clone git@github.com:UsabilityDynamics/git-docker.git /opt/sources/wpCloud/git-docker
ln -sf /opt/sources/wpCloud/git-docker/bin/git-docker.sh ~/.bin/git-docker
```

```
export PATH=$PATH:/home/core/.bin
git-docker info
```

###  Global Configuration
Git Docker needs to know into which directories your Git repositories will be cloned.

* /opt/sources/{OrganizationName}/{RepositoryName} - Default for repositories. The internals are mounted to /var/www
* /opt/storage/{OrganizationName}/{RepositoryName} - Default for persistent storage. The internals are mounted to /var/storage

```
git config --global docker.paths.sources /opt/sources
git config --global docker.paths.sources /opt/sources
git config --global docker.memory.limit 2g
```

As you may be aware, you may view all global Git configurations like so:
```
git config -l
```


### Accessing Volume Mount


sudo su 
cd /var/lib/docker/vfs/dir/ae81fffd2207d5ccad75d8f153eab548a4c8e84921187ac1b3bc8146eb1794ff
su core
