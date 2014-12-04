anti-poison
=============

# Prevent DNS poison

* 这个是在 "https://github.com/hackgfw/openwrt-gfw-packages" 其中gfw-dns项目基础上简化而来。
* 原理简单来说就是: DNS投毒“抢先”把错误IP返回，正确的IP随后还是会返回。只要把这些“抢先”的IP丢弃掉，就可以正常解析地址了。

# 优点：
* 使用114等DNS，解析速度快
* 不用VPN就可以防止DNS投毒
* 安装后重启一次立即可用，原版可能需要较长初始化时间

# 缺点：
* 假IP地址列表可能会有变化，需要手工更新 /etc/config/anti-poison
* DNS地址需要根据网络情况自行修改（虽然用缺省的配置应该也能工作的不错） /etc/resolv2.conf
* gfw可能升级，目前的防毒原理可能失效
