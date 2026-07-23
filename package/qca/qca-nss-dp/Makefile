include $(TOPDIR)/rules.mk

PKG_NAME:=qca-nss-dp
PKG_RELEASE:=2

PKG_LICENSE:=ISC
PKG_SOURCE_URL:=https://git.codelinaro.org/clo/qsdk/oss/lklm/nss-dp.git
PKG_SOURCE_PROTO:=git
PKG_SOURCE_DATE:=2026-07-11
PKG_SOURCE_VERSION:=d1aa4f7e168c2040cc177a24cc3a13e83745ee0a
PKG_MIRROR_HASH:=skip

PKG_BUILD_PARALLEL:=1
PKG_FLAGS:=nonshared

include $(INCLUDE_DIR)/kernel.mk
include $(INCLUDE_DIR)/package.mk

define KernelPackage/qca-nss-dp
  SECTION:=kernel
  CATEGORY:=Kernel modules
  SUBMENU:=Network Devices
  DEPENDS:=@TARGET_qualcommbe_ipq95xx +kmod-qca-ssdk +kmod-qca-nss-ppe
  TITLE:=Qualcom NSS dataplane ethernet driver
  FILES:=$(PKG_BUILD_DIR)/qca-nss-dp.ko
  AUTOLOAD:=$(call AutoLoad,32,qca-nss-dp,1)
endef

define KernelPackage/qca-nss-dp/Description
  NSS dataplane ethernet driver for Qualcom SoCs.
endef

define Build/InstallDev
	mkdir -p $(1)/usr/include/qca-nss-dp
	$(CP) $(PKG_BUILD_DIR)/exports/* $(1)/usr/include/qca-nss-dp/
endef

EXTRA_CFLAGS+= \
	-I$(STAGING_DIR)/usr/include/qca-ssdk \
	-I$(STAGING_DIR)/usr/include/qca-nss-ppe

NSS_DP_HAL_DIR:=$(PKG_BUILD_DIR)/hal
define Build/Configure
	$(LN) $(NSS_DP_HAL_DIR)/soc_ops/ipq95xx/nss_ipq95xx.h \
		$(PKG_BUILD_DIR)/exports/nss_dp_arch.h
endef

define Build/Compile
	+$(KERNEL_MAKE) $(PKG_JOBS) \
		-C "$(LINUX_DIR)" \
		M="$(PKG_BUILD_DIR)" \
		EXTRA_CFLAGS="$(EXTRA_CFLAGS)" \
		SoC="ipq95xx" \
		dp-loopback=y \
		modules
endef

$(eval $(call KernelPackage,qca-nss-dp))
