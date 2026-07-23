include $(TOPDIR)/rules.mk

PKG_NAME:=qca-nss-ppe
PKG_RELEASE:=1
PKG_LICENSE:=ISC

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://git.codelinaro.org/clo/qsdk/oss/lklm/nss-ppe.git
PKG_SOURCE_DATE:=2026-07-19
PKG_SOURCE_VERSION:=87bb9b326dfe7ddafb2cc8bc588e74d552a2a9b5
PKG_MIRROR_HASH:=skip

PKG_BUILD_PARALLEL:=1
PKG_FLAGS:=nonshared

include $(INCLUDE_DIR)/kernel.mk
include $(INCLUDE_DIR)/package.mk

define KernelPackage/qca-nss-debug
  SECTION:=kernel
  CATEGORY:=Kernel modules
  SUBMENU:=Network Devices
  DEPENDS:=@TARGET_qualcommbe_ipq95xx
  TITLE:=Qualcomm NSS/PPE debug infrastructure
  FILES:=$(PKG_BUILD_DIR)/nss_debug/qca-nss-debug.ko
  AUTOLOAD:=$(call AutoLoad,30,qca-nss-debug)
endef

define KernelPackage/qca-nss-debug/Description
  Debug infrastructure used by the Qualcomm IPQ95xx PPE driver.
endef

define KernelPackage/qca-nss-ppe
  SECTION:=kernel
  CATEGORY:=Kernel modules
  SUBMENU:=Network Devices
  DEPENDS:=@TARGET_qualcommbe_ipq95xx +kmod-qca-ssdk +kmod-qca-nss-debug +kmod-nat46
  TITLE:=Qualcomm IPQ95xx PPE flow acceleration driver
  FILES:=$(PKG_BUILD_DIR)/drv/ppe_drv/qca-nss-ppe.ko
  AUTOLOAD:=$(call AutoLoad,31,qca-nss-ppe)
endef

define KernelPackage/qca-nss-ppe/Description
  Qualcomm QSDK PPE core and flow-rule driver for IPQ95xx.
endef

PPE_CFLAGS:= \
	-I$(STAGING_DIR)/usr/include/qca-ssdk \
	-I$(STAGING_DIR)/usr/include/qca-ssdk/fal \
	-I$(STAGING_DIR)/usr/include/qca-ssdk/init \
	-I$(STAGING_DIR)/usr/include/nat46 \
	-I$(PKG_BUILD_DIR)/nss_debug/exports

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include/qca-nss-debug
	$(CP) $(PKG_BUILD_DIR)/nss_debug/exports/* $(1)/usr/include/qca-nss-debug/
	$(INSTALL_DIR) $(1)/usr/include/qca-nss-ppe
	$(CP) $(PKG_BUILD_DIR)/exports/* $(1)/usr/include/qca-nss-ppe/
	$(CP) $(PKG_BUILD_DIR)/drv/exports/* $(1)/usr/include/qca-nss-ppe/
endef

define Build/Compile
	+$(KERNEL_MAKE) \
		M="$(PKG_BUILD_DIR)/nss_debug" \
		SoC="ipq95xx" \
		modules
	+$(KERNEL_MAKE) \
		M="$(PKG_BUILD_DIR)" \
		EXTRA_CFLAGS="$(PPE_CFLAGS)" \
		SoC="ipq95xx" \
		ppe-drv=y \
		modules
endef

$(eval $(call KernelPackage,qca-nss-debug))
$(eval $(call KernelPackage,qca-nss-ppe))
