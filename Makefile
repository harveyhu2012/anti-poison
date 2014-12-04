#
# Copyright (C) 2014 anti-position
#
# This is free software, licensed under the GNU General Public License v3.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=anti-poison
PKG_VERSION:=0.1.0
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
PKG_BUILD_DEPENDS += +dnsmasq +firewall

include $(INCLUDE_DIR)/package.mk

define Package/anti-poison
  SECTION:=net
  CATEGORY:=Network
  DEPENDS += +iptables-mod-filter +iptables-mod-u32 +dnsmasq +firewall
  PKGARCH:=all
  TITLE:=Anti-Poisoning
  URL:=https://github.com/harveyhu2012/anti-poison
  MAINTAINER:=harveyhu2012 <harveyhu2012@gmail.com>
endef

define Package/anti-poison/description
  Prevent DNS poison
  For more information, please refer to https://github.com/harveyhu2012/anti-poison
endef

define Package/anti-poison/conffiles
/etc/config/anti-poison
/etc/resolv2.conf
endef

define Build/Compile
endef

define Package/anti-poison/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/$(PKG_NAME).init $(1)/etc/init.d/$(PKG_NAME)
	$(INSTALL_DIR) $(1)/etc/config
	$(CP) ./files/$(PKG_NAME).config $(1)/etc/config/$(PKG_NAME)
	$(INSTALL_DIR) $(1)/etc
	$(CP) ./files/resolv2.conf $(1)/etc/resolv2.conf
	$(INSTALL_DIR) $(1)/usr/lib/$(PKG_NAME)
	$(INSTALL_BIN) ./files/$(PKG_NAME).sh $(1)/usr/lib/$(PKG_NAME)/$(PKG_NAME).sh
endef

define Package/anti-poison/postinst
#!/bin/sh
chkdnsmasq=$$(grep ^all-servers $${IPKG_INSTROOT}/etc/dnsmasq.conf 2>/dev/null)
if [ -z "$$chkdnsmasq" ]; then
	echo "all-servers" >> $${IPKG_INSTROOT}/etc/dnsmasq.conf
fi
if [ $$(uci get dhcp.@dnsmasq[0].resolvfile)x != "/etc/resolv2.conf"x ]; then
	rvfilebak=$$(uci get dhcp.@dnsmasq[0].resolvfile)
	uci set dhcp.@dnsmasq[0].resolvfile='/etc/resolv2.conf'
	uci set dhcp.@dnsmasq[0].resolvfilebak=$$rvfilebak
	uci commit dhcp
fi
chkfirewall=$$(grep ". /var/anti.firewall.user" $${IPKG_INSTROOT}/etc/firewall.user 2>/dev/null)
if [ -z "$$chkfirewall" ]; then
	echo "[[ -s /var/anti.firewall.user ]] && . /var/anti.firewall.user" >> $${IPKG_INSTROOT}/etc/firewall.user
fi
/etc/init.d/anti-poison enable
sed -i '/net.netfilter.nf_conntrack_skip_filter.*=.*1/c\net.netfilter.nf_conntrack_skip_filter=0' $${IPKG_INSTROOT}/etc/sysctl.conf
exit 0
endef

define Package/anti-poison/postrm
#!/bin/sh
if [ -n "$$(uci get dhcp.@dnsmasq[0].resolvfilebak 2>/dev/null)" ]; then
	uci set dhcp.@dnsmasq[0].resolvfile=$$(uci get dhcp.@dnsmasq[0].resolvfilebak)
	uci set dhcp.@dnsmasq[0].resolvfilebak=''
	uci commit dhcp
fi
sed -i '/anti.firewall.user/d' $${IPKG_INSTROOT}/etc/firewall.user 2>/dev/null
exit 0
endef

$(eval $(call BuildPackage,anti-poison))
