include $(TOPDIR)/rules.mk

PKG_NAME:=qca-nss-ecm
PKG_RELEASE:=3
PKG_LICENSE:=ISC

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://git.codelinaro.org/clo/qsdk/oss/lklm/qca-nss-ecm.git
PKG_SOURCE_DATE:=2026-07-10
PKG_SOURCE_VERSION:=e978478f5dba749d412e144b8f3e7b152687d893
PKG_MIRROR_HASH:=skip

PKG_BUILD_PARALLEL:=1
PKG_FLAGS:=nonshared

include $(INCLUDE_DIR)/kernel.mk
include $(INCLUDE_DIR)/package.mk

define KernelPackage/qca-nss-ecm
  SECTION:=kernel
  CATEGORY:=Kernel modules
  SUBMENU:=Network Support
  DEPENDS:=@TARGET_qualcommbe_ipq95xx \
	+kmod-qca-nss-ppe \
	+kmod-nf-conntrack \
	+kmod-bonding \
	+kmod-ppp \
	+kmod-pppoe
  TITLE:=Qualcomm PPE Enhanced Connection Manager
  FILES:=$(PKG_BUILD_DIR)/ecm.ko $(PKG_BUILD_DIR)/examples/ecm_ae_select.ko
  KCONFIG:=CONFIG_BRIDGE_NETFILTER=y \
	CONFIG_NF_CONNTRACK_EVENTS=y \
	CONFIG_NF_CONNTRACK_DSCPREMARK_EXT=y
endef

define KernelPackage/qca-nss-ecm/Description
  Connection manager that programs eligible IPv4 and IPv6 flows into the
  Qualcomm IPQ95xx PPE. Marked and explicitly denied interfaces remain on the
  Linux software path.
endef

define KernelPackage/qca-nss-ecm/install
	$(INSTALL_DIR) $(1)/etc/firewall.d
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DIR) $(1)/etc/hotplug.d/iface
	$(INSTALL_DIR) $(1)/etc/hotplug.d/net
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_DIR) $(1)/etc/sysctl.d
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_DATA) ./files/qca-nss-ecm.firewall $(1)/etc/firewall.d/qca-nss-ecm
	$(INSTALL_BIN) ./files/qca-nss-ecm.init $(1)/etc/init.d/qca-nss-ecm
	$(INSTALL_BIN) ./files/ecm_dump.sh $(1)/usr/bin/
	$(INSTALL_BIN) ./files/disable_offloads.sh $(1)/usr/bin/
	$(INSTALL_DATA) ./files/qca-nss-ecm.uci $(1)/etc/config/ecm
	$(INSTALL_DATA) ./files/qca-nss-ecm.defaults $(1)/etc/uci-defaults/99-qca-nss-ecm
	$(INSTALL_DATA) ./files/qca-nss-ecm.sysctl $(1)/etc/sysctl.d/qca-nss-ecm.conf
	$(INSTALL_BIN) ./files/qca-nss-ecm.hotplug $(1)/etc/hotplug.d/iface/99-qca-nss-ecm
	$(INSTALL_BIN) ./files/qca-nss-ecm.hotplug $(1)/etc/hotplug.d/net/99-qca-nss-ecm
endef

ECM_CFLAGS:= \
	-I$(STAGING_DIR)/usr/include \
	-I$(STAGING_DIR)/usr/include/qca-nss-ppe \
	-Dint_pri=priority

ECM_MAKE_OPTS:= \
	ECM_FRONT_END_NSS_ENABLE=n \
	ECM_FRONT_END_SFE_ENABLE=n \
	ECM_FRONT_END_PPE_ENABLE=y \
	ECM_IPV6_ENABLE=y \
	ECM_NON_PORTED_SUPPORT_ENABLE=n \
	ECM_MULTICAST_ENABLE=n \
	ECM_INTERFACE_PPP_ENABLE=y \
	ECM_INTERFACE_PPPOE_ENABLE=y \
	ECM_INTERFACE_VLAN_ENABLE=y \
	ECM_INTERFACE_SKIP_ACCEL_ENABLE=y \
	ECM_CLASSIFIER_MARK_ENABLE=y \
	ECM_CLASSIFIER_DSCP_ENABLE=y \
	ECM_CLASSIFIER_PCC_ENABLE=y \
	ECM_BAND_STEERING_ENABLE=n

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include/qca-nss-ecm
	$(CP) $(PKG_BUILD_DIR)/exports/* $(1)/usr/include/qca-nss-ecm/
endef

define Build/Compile
	+$(KERNEL_MAKE) $(strip $(ECM_MAKE_OPTS)) \
		M="$(PKG_BUILD_DIR)" \
		EXTRA_CFLAGS="$(ECM_CFLAGS) -Wno-error=unused-function -Wno-error=missing-prototypes -Wno-unused-variable" \
		SoC="ipq95xx" \
		modules
endef

$(eval $(call KernelPackage,qca-nss-ecm))
