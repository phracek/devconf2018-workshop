#!/bin/bash

I_FEDORA="registry.fedoraproject.org/fedora"
I_MEMCACHED="modularitycontainers/memcached"
I_DOVECOT="modularitycontainers/dovecot"
I_HAPROXY="modularitycontainers/haproxy"
I_TESTTOOLS="container-test-tools"
IMAGES="$I_FEDORA $I_MEMCACHED $I_DOVECOT $I_HAPROXY"

BASE="build"
BUILDDIR="$BASE/images"
RPMS="$BASE/rpms"

function pack_images(){
    mkdir -p $BUILDDIR
    for foo in $IMAGES; do
        docker pull $foo
    done
    
    echo 'FROM docker.io/modularitycontainers/conu:dev

ENV PYTHONDONTWRITEBYTECODE=yes-please

RUN dnf install -y nmap-ncat make python2-pytest python3-pytest && \
    pip2 install --user -r ./test-requirements.txt && \
    pip3 install --user -r ./test-requirements.txt && \
    dnf -y install dnf-plugins-core && \
    dnf -y copr enable phracek/meta-test-family-devel && \
    dnf -y install meta-test-family
' > Dockerfile.$I_TESTTOOLS
    docker build --network host --tag=$I_TESTTOOLS -f ./Dockerfile.$I_TESTTOOLS .

    for foo in $IMAGES $I_TESTTOOLS; do
        echo "Saving $foo"
        docker image save $foo | gzip > $BUILDDIR/`basename $foo`.tar.gz
    done
    #docker run --net=host --rm -v /dev:/dev:ro -v /var/lib/docker:/var/lib/docker:ro --security-opt label=disable --cap-add SYS_ADMIN -ti -v /var/run/docker.sock:/var/run/docker.sock -v ${PWD}:/src -v ${PWD}/pytest-container.ini:/src/pytest.ini $(I_TESTTOOLS) make exec-test TEST_TARGET=$(TEST_TARGET)
    clean_images
}

function clean_images(){
    docker image rm -f $IMAGES $I_TESTTOOLS
}

function download_gits(){
    curl -o $BASE/mtf.zip https://codeload.github.com/fedora-modularity/meta-test-family/zip/devel
    curl -o $BASE/conu.zip https://codeload.github.com/fedora-modularity/conu/zip/master
}

function download_rpms(){
    mkdir -p $RPMS
    wget -r -np https://copr-be.cloud.fedoraproject.org/results/phracek/meta-test-family-devel/
    find copr-be.cloud.fedoraproject.org -name "*.rpm" -exec cp {} $RPMS \;
    createrepo -o $RPMS $RPMS
}


function bootstrap(){
    pack_images
    clean_images
    download_gits
    download_rpms
}

function install_packages(){
    sudo dnf -y install dnf-plugins-core
    sudo dnf -y copr enable phracek/meta-test-family-devel
    sudo dnf -y install meta-test-family conu

}
function install_gits(){
    echo "Unpack git sources"
    for foo in $BASE/*.zip; do
        unzip $foo -d $1
    done
}

function import_images(){
    if [ ! -d "$BUILDDIR" ]; then
        echo "$BUILDDIR does not exist, you have to bootstrap it here (like: $0 bootstrap)"
        usage
        exit 2
    fi
    echo "Loading docker images"
    for foo in $BUILDDIR/*.tar.gz; do
        echo "Loading $foo"
        zcat $foo | docker image load
    done
}

function install(){
    DEST=$1
    if [ -z "$DEST" ]; then
        echo "Missing directory name or is not directory"
        usage
        exit 1
    fi
    import_images
    mkdir -p "$DEST"

    echo "Copy related stuff to you directory"
    cp $0 $DEST
    install_gits

}

function usage(){
    echo "
____________________________________________________________________
USAGE:

    $0 install DIR - it load docker files from tar.gz archives
                           and copy git repositories and other stuff to your location
        DIR         - where to copy gits and rpms


  Other methods to use:
    install_gits DIR
    install_packages
    import_images
    bootstrap
    clean_images
"
}


METHOD=$1
if [ -z $METHOD ]; then
    echo "if you want to unpact git repos use install method as parameter try
    $O usage:"
    import_images
    install_packages

fi
shift
$METHOD $@
