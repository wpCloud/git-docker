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

### Setting Git Config

Check settings, either locally within a repo or globally outside of an existing repo.
```
git config docker.meta.image
```

Set some defaults globally:
```
git config --global docker.meta.image wpcloud/site:0.4.7
git config --global docker.meta.image wpcloud/site:latest
```

### Available Config Options

* docker.meta.port - e.g. "10.10.48.156:49155"
* docker.meta.image - e.g. "wpcloud/site:0.4.7" or "wpcloud/site:latest"
* docker.memory.limit - e.g. "8g"

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
## Automation

http://content.screencast.com/users/AndyPotanin/folders/Jing/media/3463dad2-3291-4584-8042-f0e222eb1bac/00000168.png

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
git config --global docker.paths.runtime /opt/runtime
git config --global docker.paths.storage /opt/storage
git config --global docker.memory.limit 3g
```

As you may be aware, you may view all global Git configurations like so:
```
git config -l
```
