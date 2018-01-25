# Testing and maintaining containers

Cook books for DevConf2018 - workshop


## Agenda

 * [MTF](/MTF.md)
 * [conu](/conu.md)
 * [best practices](http://docs.projectatomic.io/container-best-practices/)
 * [distgen](/distgen.md)
 * [source-to-image](/source-to-image.md) + containerized services

## Using data stored on USB key
 * It contains:
   * Live USB
 * gzipped container images
   * ``build/images``
 * RPM packages for Fedora 26.27, rawhide
   * ``build/rpms``
 * zipped git repositories
   * ``build/*.zip``
 * main script is ``./install.sh`` call it with ``usage`` param, to see what you can use

```
build
├── conu.zip
├── distgen.zip
├── images
│   ├── fedora:27.tar.gz
│   ├── memcached.tar.gz
│   └── nginx-112-centos7.tar.gz
├── mtf.zip
├── rpms
│   ├── fedora26
│   ├── fedora27
│   └── fedorarawhide
└── s2i.zip
install.sh
```

#### As live CD/USB
 * it contains preinstalled packages ``s2i, distgen, conu, mtf``
 * other stuff are located in ``/opt/`` directory
 * call(/click) ``./install.sh`` there to import docker images

#### As data source
 * mount the disc, there is ``./install.sh`` script what will help you to deploy it on your machine
 * ``./install.sh install DIRECTORY`` it unpack zipped git repositories to selected location


#### Example how to use MTF inside this USB key
```
export DOCKERFILE=/usr/share/moduleframework/examples/testing-module/Dockerfile
export MODULE=docker
mtf --url=docker=registry.fedoraproject.org/fedora:27 -l

```