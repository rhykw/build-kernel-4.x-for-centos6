#
# build kernerl 4.x
#
PWD=$(shell pwd)

KERNEL_VER=4.1.1
KERNEL_ARC=x86_64

KERNEL_BUILD_HOST=
KERNEL_BUILD_USER=
KERNEL_LOCAL_VER=
KERNEL_CONFIG=$(PWD)/centos6_kernel-$(KERNEL_VER).config
KERNEL_CONFIG_MASTER=$(PWD)/centos6_kernel-4.x.y.config
KERNEL_URL=https://www.kernel.org/pub/linux/kernel/v4.x/linux-$(KERNEL_VER).tar.xz
KERNEL_URL_V3=https://www.kernel.org/pub/linux/kernel/v3.x/linux-$(KERNEL_VER).tar.xz
KERNEL_URL_MAINLINE=https://www.kernel.org/pub/linux/kernel/v4.x/testing/linux-$(KERNEL_VER).tar.xz
BUILD_DIR=$(PWD)/build/linux-$(KERNEL_VER)
THREAD=1

# use ccache
HOSTCXX=g++
CC=gcc

# check and rename rpm for rc version: 4.2-rc2 to 4.2.0_rc2
KERNEL_RPM_VER=$(subst -,.0_,$(KERNEL_VER))

all: build-kernel

build-kernel: setup
	cd ~/rpmbuild/SOURCES/linux-$(KERNEL_VER) && test -f $(KERNEL_CONFIG) || cp $(KERNEL_CONFIG_MASTER) $(KERNEL_CONFIG)
	cd ~/rpmbuild/SOURCES/linux-$(KERNEL_VER) && test -z $(KERNEL_LOCAL_VER) || sed -i "s/^CONFIG_LOCALVERSION=.*/CONFIG_LOCALVERSION=\"$(KERNEL_LOCAL_VER)\"/" $(KERNEL_CONFIG)
	cd ~/rpmbuild/SOURCES/linux-$(KERNEL_VER) && \
		cp $(KERNEL_CONFIG) ./.config && \
		make olddefconfig && \
		KBUILD_BUILD_HOST=$(KERNEL_BUILD_HOST) KBUILD_BUILD_USER=$(KERNEL_BUILD_USER) USE_CCACHE=1 CCACHE_DIR=~/.ccache make -j$(THREAD) HOSTCXX="$(HOSTCXX)" CC="$(CC)" rpm
	mkdir -p $(BUILD_DIR) && mv ~/rpmbuild/RPMS/$(KERNEL_ARC)/kernel*-$(KERNEL_RPM_VER)$(KERNEL_LOCAL_VER)-?.$(KERNEL_ARC).rpm $(BUILD_DIR)/.

setup:
	mkdir -p ~/rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
	cd ~/rpmbuild/SOURCES/ && test -f linux-$(KERNEL_VER).tar.xz || wget $(KERNEL_URL) || wget $(KERNEL_URL_V3) || wget $(KERNEL_URL_MAINLINE)
	cd ~/rpmbuild/SOURCES/ && test -d linux-$(KERNEL_VER) || tar xvf linux-$(KERNEL_VER).tar.xz

clean:
	-rm -rf $(BUILD_DIR) $(KERNEL_CONFIG)
	cd ~/rpmbuild/SOURCES/linux-$(KERNEL_VER) && make clean && make mrproper
