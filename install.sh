#!/bin/bash

SCRIPTNAME="install.sh"

I_FEDORA="registry.fedoraproject.org/fedora:27"
I_NGINX="docker.io/centos/nginx-112-centos7"
I_MEMCACHED="modularitycontainers/memcached"
#I_TESTTOOLS="container-test-tools"
IMAGES="$I_FEDORA $I_NGINX $I_MEMCACHED"

PACKAGES="meta-test-family python3-conu python2-conu distgen source-to-image"

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
    #docker build --network host --tag=$I_TESTTOOLS -f ./Dockerfile.$I_TESTTOOLS .

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
         --enablerepo=ttomecek-conu \
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
    if [ ! -e /usr/share/moduleframework ]; then
        sudo dnf -y install dnf-plugins-core
        sudo dnf -y copr enable phracek/meta-test-family-devel
        sudo dnf -y copr enable ttomecek/conu
        sudo dnf -y install $PACKAGES
     fi
}

function install_gits(){
    DEST=$1

    echo "Unpack git sources"
    for foo in $BASE/*.zip; do
        unzip $foo -d $DEST
    done
}

function import_images(){
    if [ ! -e /var/run/docker.sock ]; then
        sudo systemctl start docker
    fi
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

function bootstrap_iso(){
    # https://fedoraproject.org/wiki/How_to_create_and_use_a_Live_CD
    sudo dnf -y install livecd-tools spin-kickstarts
    echo "
repo --name=phracekcopr --baseurl=https://copr-be.cloud.fedoraproject.org/results/phracek/meta-test-family-devel/fedora-26-x86_64/
repo --name=tomecekcopr --baseurl=https://copr-be.cloud.fedoraproject.org/results/ttomecek/conu/fedora-26-x86_64/

%include /usr/share/spin-kickstarts/fedora-live-workstation.ks

%packages
# Make sure to sync any additions / removals done here with
# workstation-product-environment in comps
@base-x
@core
@firefox
@fonts
@gnome-desktop
@guest-desktop-agents
@hardware-support
@libreoffice
@multimedia
@networkmanager-submodules
@printing
@workstation-product

# Branding for the installer
fedora-productimg-workstation

meta-test-family
distgen
source-to-image
python2-conu
python3-conu


%end

%post --nochroot
set -x
mkdir -p \$INSTALL_ROOT/opt/$BASE
cp -rf `pwd`/$BUILDDIR \$INSTALL_ROOT/opt/$BASE/
cp -rf `pwd`/$BASE/*.zip \$INSTALL_ROOT/opt/$BASE/
cp -rf `pwd`/install.sh \$INSTALL_ROOT/opt
%end
" > customized.ks

     sudo livecd-creator --verbose --config=customized.ks --cache=/var/cache/live

}

function create_usb(){
    set -x
    DISC=$1
    DEV=/dev/$DISC
    TEMPMOUNT=`mktemp -d`
    if [ -z "$DISC" ]; then
        echo "missing parameter where to put data (like sdb1)"
        exit 122
    fi
    sudo umount $DEV
    IMNA=`ls livecd-customized*|tail -1`
    if [ -z "$IMNA" ]; then
        bootstrap_iso
        IMNA=`ls livecd-customized*|tail -1`
    fi
    sudo livecd-iso-to-disk --format --reset-mbr $IMNA $DEV
    # --overlay-size-mb 1000
    sudo sync
    sudo partprobe
    sudo mount $DEV $TEMPMOUNT
    sudo cp -rf $SCRIPTNAME $BASE $TEMPMOUNT
    sudo umount $TEMPMOUNT
    rm -fr $TEMPMOUNT
}

function install(){
    DEST=$1
    if [ -z "$DEST" ]; then
        echo "Missing directory name or is not directory"
        usage
        exit 1
    fi
    install_packages
    import_images
    mkdir -p "$DEST"

    echo "Copy related stuff to you directory"
    cp $SCRIPTNAME $DEST
    install_gits $DEST

}

METHOD=$1
if [ -z $METHOD ]; then
    echo "if you want to unpact git repos use install method as parameter try $SCRIPTNAME usage:"
    install_packages
    import_images

fi
shift
$METHOD $@
