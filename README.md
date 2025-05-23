#  Aspen Dev Environment

This is an Aspen-discovery Docker instance designed to make developing Aspen 
easier. 

Still in early stages and there are a number of improvements to be made

## Requirements

### Software

This project is self contained and all you need is:

- A text editor to tweak configuration files
- Docker ([install instructions](https://docs.docker.com/engine/install/))
- Docker Compose v2 ([install instructions](https://docs.docker.com/compose/install/linux/#install-using-the-repository))

Note: **Windows** and **macOS** users use [Docker Desktop](https://docs.docker.com/compose/install/compose-desktop/) which already ships Docker Compose v2.

## Setup

It is not a bad idea to organize your projects in a directory. For the purpose
of simplifying the instructions we pick `~/git` as the place in which to put
all the repository clones:

```shell
mkdir -p ~/git
export PROJECTS_DIR=~/git
```

* Clone the `aspen-dev-box` project:

```shell
cd $PROJECTS_DIR
git clone https://github.com/Aspen-Discovery/aspen-dev-box-image.git aspen-dev-box
```

* Clone the `aspen-discovery` project (skip and adjust the paths if you already have it):
-- I would recommend forking the below repository and cloning your fork for this.

```shell
cd $PROJECTS_DIR
git clone https://github.com/mdnoble73/aspen-discovery.git aspen-discovery
```

* Set some **mandatory** environment variables in your .bashrc:

```shell
echo "export PROJECTS_DIR=$PROJECTS_DIR" >> ~/.bashrc
echo 'export ASPEN_CLONE=$PROJECTS_DIR/aspen-discovery' >> ~/.bashrc
echo 'export ASPEN_DOCKER=$PROJECTS_DIR/aspen-dev-box'  >> ~/.bashrc
[ "$(uname)" == "Darwin" ] && echo 'export PATH=$PATH:$ASPEN_DOCKER/bin/darwin' >> ~/.bashrc
[ "$(uname)" == "Linux" ] && echo 'export PATH=$PATH:$ASPEN_DOCKER/bin/linux' >> ~/.bashrc
```

**Note:** you will need to log out and log back in (or start a new terminal window) for this to take effect.

* Now you can start up your devbox

```shell
cd $ASPEN_DOCKER
docker compose up
```

## USAGE:
This project exposes port 8083 and 8084: 

* `localhost:8083` will take you to the discovery page where you can interact with aspen-discovery

* `localhost:8084` will take you to the solr dashboard.

* Running `newSQL.sh` will update the DB setup file to the latest version contained within your aspen-discovery clone.

**LOGINS:**
Listed below are the default logins for both the Database and Aspen discovery interface

* Discovery:
```
Username: aspen_admin
Password: password
```
* Database:
```
Username: root
Password: aspen
Table: aspen
```
### DEBUGGING:
*IMPORTANT*
if on WSL please also place this in your .bashrc (or equivalent) and restart your shell as above
```
export WSL_IP=$(ip addr show eth0 | awk '/inet / {print $2}' | cut -d/ -f1)
```
You should also sym link your aspen clone to the default install location for production installs so the debugger can link files. 
Please open your IDE from this location if debugging.
```
sudo ln -s $ASPEN_CLONE /usr/local/aspen-discovery
```

An alternative to this is to setup path mappings in your debug configurations for your IDE. 
VSCode mappings are included in the repository and can be copied to the correct location with the below command:
```
cp $ASPEN_DOCKER/vscodedebugconfig.json $ASPEN_CLONE/.vscode/launch.json
```
