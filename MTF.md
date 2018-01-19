# [MTF](https://github.com/fedora-modularity/meta-test-family)

We'll be working on testing containers in docker or in OpenShift

```
git clone https://github.com/container-images/memcached
```

## Prepare environment for testing

You can prepare docker environment by yours, like installation docker, OpenShift, etc.
or `MTF` can do it instead of you

### Setup docker environment

Just call command:
```
sudo MODULE=docker mtf-env-set
```

The command installs `docker` and starts it.

### Setup [OpenShift](https://www.openshift.com) environment

Just call command:
```
sudo MODULE=openshift mtf-env-set
```

The command installs `openshift` package called `origin` and starts command `oc cluster up`:

## Create test for testing container

Before testing container we need Python test suite for `memcached` container.

Several tests are mentioned here [examples](https://github.com/fedora-modularity/meta-test-family/tree/devel/examples).

### Short test for memcached

Basic [example](/memcached.py) for memcached container.

### Configuration file for MTF

Basic [config.yaml](/config.yaml) file for testing.

## Run tests with MTF

For running MTF test call script `mtf`.

### Run tests in docker environment

For running tests, run a command:
```
sudo MODULE=docker mtf memcached.py
```

### Run tests in OpenShift environment
For running tests, run a command:
```
sudo MODULE=openshift mtf memcached.py
```

