# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=2

inherit eutils linux-mod cmake-utils

DESCRIPTION="Point-to-Point Tunnelling Protocol Client/Server for Linux"
SRC_URI="http://sourceforge.net/projects/accel-pptp/files/accel-pptp/${P}.tar.bz2"
HOMEPAGE="http://accel-pptp.sourceforge.net/"

SLOT="0"
LICENSE="GPL"
KEYWORDS="~amd64 ~x86"
IUSE="postgres debug l2tp shaper"

DEPEND=">=sys-libs/glibc-2.8
	dev-libs/openssl
	dev-libs/libaio
	l2tp? ( =dev-libs/libnl-9999 )
	shaper? ( =dev-libs/libnl-9999 )
	postgres? ( >=dev-db/postgresql-base-8.1 )"

RDEPEND="$DEPEND
         virtual/modutils"

BUILD_TARGETS="default"
BUILD_PARAMS="KDIR=${KERNEL_DIR}"
CONFIG_CHECK="PPP PPPOE"
MODULESD_PPTP_ALIASES=("net-pf-24 pptp")
PREFIX="/"
MODULE_NAMES="pptp(extra:${S}/driver/)"

src_prepare() {
	sed -i -e "/mkdir/d" "${S}/accel-pptpd/CMakeLists.txt"
	sed -i -e "/INSTALL/d" "${S}/driver/CMakeLists.txt"
}

src_configure() {
	if use debug; then
		mycmakeargs+=( "-DCMAKE_BUILD_TYPE=Debug" )
	fi

	if  use postgres; then
		mycmakeargs+=( "-DLOG_PGSQL=TRUE" )
	fi
	
	if use l2tp; then
		mycmakeargs+=( "-DL2TP=TRUE" )
	fi

	if use shaper; then
		mycmakeargs+=( "-DSHAPER=TRUE" )
	fi

	cmake-utils_src_configure
}

src_compile() {
	cmake-utils_src_compile
	
	cd ${S}/driver
	linux-mod_src_compile || die "failed to build driver"
}

src_install() {
	cmake-utils_src_install

	cd ${S}/driver
	linux-mod_src_install

	exeinto /etc/init.d
	newexe "${S}/contrib/gentoo/net-dialup/accel-pptp/files/pptpd-init" accel-pptpd

	insinto /etc/conf.d
	newins "${S}/contrib/gentoo/net-dialup/accel-pptp/files/pptpd-confd" accel-pptpd

	dodir /var/log/accel-pptp
	dodir /var/run/radattr
}
