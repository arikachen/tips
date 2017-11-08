
#bash build_rpm_centos.sh 2.8.0 3.10.0-327.22.2.el7.x86_64

ver=$1
kver=$2

wget https://github.com/openvswitch/ovs/archive/v${ver}.tar.gz

yum install automake  libtool openssl-devel rpm-build kernel-devel selinux-policy-devel python-devel desktop-file-utils groff  graphviz python-twisted-core python-zope-interface libcap-ng-devel

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


rpmbuild -bb --without check rhel/openvswitch-fedora..spec
rpmbuild -bb -D "kversion $kversion" rhel/openvswitch-kmod-fedora.spec
