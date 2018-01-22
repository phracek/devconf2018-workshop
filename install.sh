#!/bin/bash

SCRIPTNAME="install.sh"

I_FEDORA="registry.fedoraproject.org/fedora"
I_MEMCACHED="modularitycontainers/memcached"
I_DOVECOT="modularitycontainers/dovecot"
I_HAPROXY="modularitycontainers/haproxy"
I_TESTTOOLS="container-test-tools"
IMAGES="$I_FEDORA $I_MEMCACHED $I_DOVECOT $I_HAPROXY"

PACKAGES="meta-test-family conu distgen source-to-image"

BASE="build"
BUILDDIR="$BASE/images"
RPMS="$BASE/rpms"

function pack_images(){
    mkdir -p $BUILDDIR
    for foo in $IMAGES; do
        docker pull $foo
    done

    echo "FROM docker.io/modularitycontainers/conu:dev

ENV PYTHONDONTWRITEBYTECODE=yes-please

RUN dnf install -y nmap-ncat make python2-pytest python3-pytest && \\
    pip2 install --user -r ./test-requirements.txt && \\
    pip3 install --user -r ./test-requirements.txt && \\
    dnf -y install dnf-plugins-core && \\
    dnf -y copr enable phracek/meta-test-family-devel && \\
    dnf -y install $PACKAGES
" > Dockerfile.$I_TESTTOOLS
    docker build --network host --tag=$I_TESTTOOLS -f ./Dockerfile.$I_TESTTOOLS .

    for foo in $IMAGES $I_TESTTOOLS; do
        echo "Saving $foo"
        docker image save $foo | gzip > $BUILDDIR/`basename $foo`.tar.gz
    done
    #docker run --net=host --rm -v /dev:/dev:ro -v /var/lib/docker:/var/lib/docker:ro --security-opt label=disable --cap-add SYS_ADMIN -ti -v /var/run/docker.sock:/var/run/docker.sock -v ${PWD}:/src -v ${PWD}/pytest-container.ini:/src/pytest.ini $(I_TESTTOOLS) make exec-test TEST_TARGET=$(TEST_TARGET)
}

function clean_images(){
    echo "Cleanup locally pulled images"
    docker image rm -f $IMAGES $I_TESTTOOLS
}

function download_gits(){
    echo "Download git repository zip files"
    curl -o $BASE/mtf.zip https://codeload.github.com/fedora-modularity/meta-test-family/zip/devel
    curl -o $BASE/conu.zip https://codeload.github.com/fedora-modularity/conu/zip/master
    curl -o $BASE/s2i.zip https://codeload.github.com/openshift/source-to-image/zip/master
    curl -o $BASE/distgen.zip https://codeload.github.com/devexp-db/distgen/zip/master
}

function download_rpms_locally(){
    mkdir -p $RPMS
    FEDORAS="26 27 rawhide"
    for VERS in $FEDORAS; do
        mkdir -p $RPMS/fedora$VERS
        INTDIR=`readlink -e $RPMS/fedora$VERS`
        sudo dnf -y install --disablerepo=* \
         --enablerepo=phracek-meta-test-family-devel \
         --enablerepo=avocado \
         --enablerepo=fedora \
         --enablerepo=updates \
         --installroot=$INTDIR --releasever=$VERS \
         --nogpgcheck --downloadonly --downloaddir=$INTDIR $PACKAGES
        createrepo -o $RPMS/fedora$VERS $RPMS/fedora$VERS
    done
}


function bootstrap(){
    pack_images
    clean_images
    download_gits
    download_rpms_locally
}

function install_packages(){
    sudo dnf -y install dnf-plugins-core
    sudo dnf -y copr enable phracek/meta-test-family-devel
    sudo dnf -y install $PACKAGES
}

function install_gits(){
    DEST=$1

    echo "Unpack git sources"
    for foo in $BASE/*.zip; do
        unzip $foo -d $DEST
    done
}

function import_images(){
    if [ ! -d "$BUILDDIR" ]; then
        echo "$BUILDDIR does not exist, you have to bootstrap it here (like: $SCRIPTNAME bootstrap)"
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
    cp $SCRIPTNAME $DEST
    install_gits $DEST

}

function usage(){
    echo "
____________________________________________________________________
USAGE:

    $SCRIPTNAME [install DIR|check_system] -
                it load docker files from tar.gz archives
                and copy git repositories and other stuff
                to your location
        DIR         - where to copy gits and rpms


  Other methods to use:
    install_gits DIR
    install_packages
    import_images
    bootstrap
    clean_images
"
}

function check_system(){
    if rpm -q docker; then
        echo "PASS: docker installed"
    else
        echo "FAIL: Docker is not installed (alternative system or cotainer env)"
    fi
    if [ -e  /var/run/docker.sock ]; then
        echo "PASS: docker is running"
    else
        echo "FAIL: docker is not running"
    fi
    if mtf --help 2>&1 >/dev/null; then
        echo "PASS: MTF package installed"
    else
        echo "FAIL: MTF package is not installed"
    fi
    if python -c "import moduleframework" ; then
        echo "PASS: MTF is installed as python package"
    else
        echo "FAIL: MTF not installed as python package"
    fi
    if python -c "import conu"; then
        echo "PASS: CONU is installed as python package"
    else
        echo "FAIL: CONU not installed as python package"
    fi
    if systemctl --version 2>&1 >/dev/null; then
        echo "PASS: you have system with systemd, you can test also nspawn containers"
    else
        echo "FAIL: system is missing"
    fi

}

function create_usb(){
    DISC=$1
    DEV=/dev/$DISC
    TEMPMOUNT=`mktemp -d`
    if [ -z "$DISC" ]; then
        echo "missing parameter where to put data (like sdb1)"
        exit 122
    fi
    IMNA=Fedora-Workstation-Live-x86_64-27-1.6.iso
    if [ ! -e $IMNA ]; then
        wget http://ftp.fi.muni.cz/pub/linux/fedora/linux/releases/27/Workstation/x86_64/iso/$IMNA
    fi
    sudo livecd-iso-to-disk --format --msdos --reset-mbr \
      --overlay-size-mb 4000 $IMNA $DEV
    sudo sync
    sudo partprobe
    sudo mount $DEV $TEMPMOUNT
    sudo cp -rf $SCRIPTNAME $BASE $TEMPMOUNT
    sudo umount $TEMPMOUNT
    rm -fr $TEMPMOUNT
}

METHOD=$1
if [ -z $METHOD ]; then
    echo "if you want to unpact git repos use install method as parameter try $SCRIPTNAME usage:"
    import_images
    install_packages

fi
shift
$METHOD $@
