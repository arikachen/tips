
#bash build_rpm_centos.sh 2.8.0 3.10.0-327.22.2.el7.x86_64

ver=$1
kver=$2

if [ ! -f v${ver}.tar.gz ];then
    wget https://github.com/openvswitch/ovs/archive/v${ver}.tar.gz
fi

yum install automake  libtool openssl openssl-devel rpm-build kernel-devel-$kver kernel-headers-$kver selinux-policy-devel python-devel desktop-file-utils groff  graphviz python-twisted-core python-zope-interface libcap-ng-devel python-six python-sphinx

tar xvf v${ver}.tar.gz

mv ovs-$ver openvswitch-$ver
cd openvswitch-$ver
sh boot.sh
cp rhel/* /root/rpmbuild/SOURCES/
cd ..
tar cf /root/rpmbuild/SOURCES/openvswitch-${ver}.tar.gz openvswitch-${ver}/
cd openvswitch-$ver
./configure --prefix=/usr --sysconfdir=/etc --libdir=/usr/lib64 --enable-ssl --enable-shared
make dist

mod_dir=/lib/modules/$kver
if [ ! -d $mod_dir ];then
    mkdir -p $mod_dir
    cd $mod_dir
    ln -s /usr/src/kernels/$kver build
    cd -
fi

rpmbuild -bb --without check rhel/openvswitch-fedora.spec
rpmbuild -bb -D "kversion $kver" rhel/openvswitch-kmod-fedora.spec
