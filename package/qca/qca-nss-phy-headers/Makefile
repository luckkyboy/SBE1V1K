include $(TOPDIR)/rules.mk

PKG_NAME:=qca-nss-phy-headers
PKG_RELEASE:=1
PKG_LICENSE:=ISC

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://git.codelinaro.org/clo/qsdk/oss/lklm/qca-nss-phy.git
PKG_SOURCE_DATE:=2026-07-03
PKG_SOURCE_VERSION:=16eec6ac35820cb67af59223e8b4c2dba7179655
PKG_MIRROR_HASH:=skip

include $(INCLUDE_DIR)/package.mk

define Package/qca-nss-phy-headers
  SECTION:=devel
  CATEGORY:=Development
  TITLE:=Qualcomm NSS PHY development headers
  BUILDONLY:=1
  HIDDEN:=1
endef

define Package/qca-nss-phy-headers/Description
  Header-only build dependency used by the QSDK 14 SSDK. The vendor PHY
  modules are intentionally not installed because SBE1V1K uses upstream
  QCA8075 and RTL8261N PHY drivers.
endef

define Build/Compile
endef

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include/qca-nss-phy
	$(CP) $(PKG_BUILD_DIR)/nss_ext/*.h $(1)/usr/include/qca-nss-phy/
	$(CP) $(PKG_BUILD_DIR)/linux_std/*.h $(1)/usr/include/qca-nss-phy/
	$(CP) $(PKG_BUILD_DIR)/linux_std/clock/*.h $(1)/usr/include/qca-nss-phy/
	$(CP) $(PKG_BUILD_DIR)/linux_std/mdio_ahb/*.h $(1)/usr/include/qca-nss-phy/
endef

$(eval $(call BuildPackage,qca-nss-phy-headers))
