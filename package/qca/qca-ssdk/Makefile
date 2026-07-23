include $(TOPDIR)/rules.mk

PKG_NAME:=qca-ssdk
PKG_RELEASE:=3

PKG_LICENSE:=ISC
PKG_SOURCE_URL:=https://git.codelinaro.org/clo/qsdk/oss/lklm/qca-ssdk.git
PKG_SOURCE_PROTO:=git
PKG_SOURCE_DATE:=2026-07-19
PKG_SOURCE_VERSION:=717b74016b0c131575bcd81b9e039d3f7974b02a
PKG_MIRROR_HASH:=skip

PKG_FLAGS:=nonshared
PKG_BUILD_PARALLEL:=1
PKG_BUILD_FLAGS:=no-lto
PKG_BUILD_DEPENDS:=qca-nss-phy-headers

include $(INCLUDE_DIR)/kernel.mk
include $(INCLUDE_DIR)/package.mk

define KernelPackage/qca-ssdk
  SECTION:=kernel
  CATEGORY:=Kernel modules
  SUBMENU:=Network Devices
  TITLE:=Qualcom SSDK switch driver
  DEPENDS:=@TARGET_qualcommbe_ipq95xx
  FILES:=$(PKG_BUILD_DIR)/build/bin/qca-ssdk.ko
  AUTOLOAD:=$(call AutoLoad,30,qca-ssdk)
endef

define KernelPackage/qca-ssdk/Description
  Driver for Qualcomm Atheros switches.
endef

GCC_VERSION=$(shell echo "$(CONFIG_GCC_VERSION)" | sed 's/[^0-9.]*\([0-9.]*\).*/\1/')

LNX_CONFIG_OPTS = LNX_MAKEOPTS='$(KERNEL_MAKEOPTS) -j$(shell nproc)' MODULE_TYPE=KSLIB modules

EXTRA_CFLAGS:= \
	-fno-stack-protector \
	-Wno-missing-prototypes \
	-Wno-missing-declarations \
	-I$(STAGING_DIR)/usr/include

MAKE_FLAGS+= \
	TARGET_NAME=$(CONFIG_TARGET_NAME) \
	TOOL_PATH=$(TOOLCHAIN_DIR)/bin \
	SYS_PATH=$(LINUX_DIR) \
	TOOLPREFIX=$(TARGET_CROSS) \
	KVER=$(LINUX_VERSION) \
	ARCH=$(LINUX_KARCH) \
	TARGET_SUFFIX=$(CONFIG_TARGET_SUFFIX) \
	GCC_VERSION=$(GCC_VERSION) \
	EXTRA_CFLAGS="$(EXTRA_CFLAGS)" \
	BUILD_DATE="$(PKG_SOURCE_DATE)" \
	SoC=ipq95xx \
	SHELL="$(BASH)" \
	CHIP_TYPE=APPE \
	PTP_FEATURE=enable SWCONFIG_FEATURE=disable \
	ISISC_ENABLE=disable MHT_ENABLE=disable \
	IN_IGMP=FALSE IN_LEAKY=FALSE IN_RATE=FALSE \
	IN_COSMAP=FALSE IN_NAT=FALSE IN_INTERFACECONTROL=FALSE \
	IN_IP_MINI=TRUE \
	IN_AQUANTIA_PHY=FALSE IN_SFP_PHY=FALSE IN_SFP=FALSE \
	IN_QCA803X_PHY=FALSE IN_MP_PHY=FALSE \
	$(LNX_CONFIG_OPTS)

define Build/Compile
	+$(MAKE) $(PKG_JOBS) $(MAKE_FLAGS) -C $(PKG_BUILD_DIR)/mk $(LNX_CONFIG_OPTS)
endef

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include/qca-ssdk
	$(INSTALL_DIR) $(1)/usr/include/qca-ssdk/api
	$(INSTALL_DIR) $(1)/usr/include/qca-ssdk/ref
	$(INSTALL_DIR) $(1)/usr/include/qca-ssdk/fal
	$(INSTALL_DIR) $(1)/usr/include/qca-ssdk/sal
	$(INSTALL_DIR) $(1)/usr/include/qca-ssdk/init
	$(CP) -rf $(PKG_BUILD_DIR)/include/api/sw_ioctl.h $(1)/usr/include/qca-ssdk/api
	if [ -f $(PKG_BUILD_DIR)/include/ref/ref_vsi.h ]; then \
	$(CP) -rf $(PKG_BUILD_DIR)/include/ref/ref_vsi.h $(1)/usr/include/qca-ssdk/ref/; \
	fi
	if [ -f $(PKG_BUILD_DIR)/include/ref/ref_fdb.h ]; then \
	$(CP) -rf $(PKG_BUILD_DIR)/include/ref/ref_fdb.h $(1)/usr/include/qca-ssdk/ref/; \
	fi
	if [ -f $(PKG_BUILD_DIR)/include/ref/ref_port_ctrl.h ]; then \
	$(CP) -rf $(PKG_BUILD_DIR)/include/ref/ref_port_ctrl.h $(1)/usr/include/qca-ssdk/ref/; \
	fi
	if [ -f $(PKG_BUILD_DIR)/include/init/ssdk_init.h ]; then \
	$(CP) -rf $(PKG_BUILD_DIR)/include/init/ssdk_init.h $(1)/usr/include/qca-ssdk/init/; \
	fi
	if [ -f $(PKG_BUILD_DIR)/include/init/ssdk_netlink.h ]; then \
	$(CP) -rf $(PKG_BUILD_DIR)/include/init/ssdk_netlink.h $(1)/usr/include/qca-ssdk/init/; \
	fi
	$(CP) -rf $(PKG_BUILD_DIR)/include/fal $(1)/usr/include/qca-ssdk
	$(CP) -rf $(PKG_BUILD_DIR)/include/common/*.h $(1)/usr/include/qca-ssdk
	$(CP) -rf $(PKG_BUILD_DIR)/include/sal/os/linux/*.h $(1)/usr/include/qca-ssdk
	$(CP) -rf $(PKG_BUILD_DIR)/include/sal/os/*.h $(1)/usr/include/qca-ssdk
endef

$(eval $(call KernelPackage,qca-ssdk))
