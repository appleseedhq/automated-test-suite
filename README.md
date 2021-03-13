# automated-test-suite

Scripts and utilities that run appleseed's functional test suite on Digital Ocean.

We use a dedicated server on Digital Ocean to run the appleseed test suite on each master build. Travis jobs take care of uploading the Linux build to our server.

## Setup

### Prepare the server

We deploy master builds on a dedicated server. We then use these builds to run the test suite.

We first need to add a specific user for deployment on the server:

```sh
sudo user add johnny
sudo passwd johnny
sudo mkdir -p /home/johnny
sudo chown -R johny:johnny/home/johnny
sudo usermod --shell /bin/bash johnny
```

The chosen password for johnny will be configured in Travis. Be sure to choose a safe password and never give sudo permissions to johnny.

### Deploy builds on the server

- [Travis deployment documentation](https://docs.travis-ci.com/user/deployment/)
- [Travis script deployment documentation](https://docs.travis-ci.com/user/deployment/script/)

Travis needs to know where to deploy and which user/password to use for `ssh`. Define the following variables in [appleseed Travis settings](https://travis-ci.org/github/appleseedhq/appleseed/settings):

- `DEPLOY_FOLDER`, where to deploy on the server. `last_master_build/` will deploy in `/home/johnny/last_master_build/`
- `DEPLOY_PASSWORD`, johnny password
- `DEPLOY_URL`, server name, IP address, or whatever we need to ssh to it
- `DEPLOY_USER`, simply `johnny`
- `DEPLOY_SSS_KEY`, public key of the server

To obtain the public key of the server, run the following:

```sh
ssh-keyscan SERVER_IP && ssh-keygen -F SERVER_IP
```

For more details, see `deploy` in `.travis.yml`.

### Run test scenes on the server 

First, install some dependencies:

```sh
apt-get install python-pip
pip install colorama
```

Then, fetch the required scripts.

```sh
cd /home/johnny
git clone git@github.com:appleseedhq/automated-test-suite.git
```

To automatically run these tests for new builds, we use `cron` to run this script every 24 hours. The `crontab` needs to be edited with a sudo user:

```sh
$ sudo crontab -u johnny -e
# m h  dom mon dow   command
0 0 * * * sh /home/johnny/atuomated-test-suite/run_tests.sh
```

### Show test scenes report online

We use a Docker container with `nginx:alpine`. First, prepare the www directory:

```sh
$ mkdir -p /home/johnny/automated-test-suite-www
```

Then as `root` or any user with docker rights, run the following:

```sh
sh /home/johnny/automated-test-suite/start_test_scenes_web_server.sh
```

