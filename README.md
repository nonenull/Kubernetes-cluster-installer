# 年代久远，过时 已废弃

# Kubernetes-cluster-installer
自制的便捷安装 k8s 集群 的shell脚本

## 测试环境说明
```
系统为 centos 7

#cat /etc/os-release
NAME="CentOS Linux"
VERSION="7 (Core)"
ID="centos"
ID_LIKE="rhel fedora"
VERSION_ID="7"
PRETTY_NAME="CentOS Linux 7 (Core)"
ANSI_COLOR="0;31"
CPE_NAME="cpe:/o:centos:centos:7"
HOME_URL="https://www.centos.org/"
BUG_REPORT_URL="https://bugs.centos.org/"

CENTOS_MANTISBT_PROJECT="CentOS-7"
CENTOS_MANTISBT_PROJECT_VERSION="7"
REDHAT_SUPPORT_PRODUCT="centos"
REDHAT_SUPPORT_PRODUCT_VERSION="7"
```

## 使用方式
    0. cd xxx/Kubernetes-cluster-installer
    1. 将需要安装的机器, 根据etc/hosts所示规则, 写入其中. etc/hosts 的规则为  {ip} {role}, 此处需要注意的是所有IP都需要做好ssh免密证书登录.
    2. 配置好bin/目录下各个依赖目录VERSION文件, 执行./get_bin.sh 自动获取相应的二进制包并解压
    3. 第二步完成后, 执行 ./install.sh 可开始安装 (如果仅需要安装一部分, 则注释相应的函数即可)
    注: 正式使用建议再安装一个 ingress

## 目录说明
    Kubernetes-cluster-installer
        |
        | -- bin    存放二进制包目录
           | -- calico  k8s网络插件
           | -- cfssl   生成tls证书用
           | -- etcd    etcd kv数据库
           | -- kubernetes  k8s目录
           |
        | -- etc    配置目录
           | -- calico  存放calico配置文件
           | -- ssl     存放证书模板
           | -- systemd 存放systemd 服务模板
           | -- hosts   k8s主机配置文件
           |
        | -- src    代码目录
           | -- config.sh       代码公共配置文件
           | -- hosts.sh        根据 etc/hosts文件生成正式hosts文件并同步至各主机
           | -- init.sh         初始化各主机
           | -- kubernetes.sh   安装 k8s 套件
           | -- log.sh          日志函数
           | -- ssl.sh          生成 tls 证书
           | -- systemd.sh      生成 k8s 套件的systemd文件
           |
        | -- tmp    临时目录
