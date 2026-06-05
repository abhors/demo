# 部署步骤

## 拉取镜像
```shell
# 先拉镜像 防止一直卡着
docker pull gitea/gitea:1.21.7
```

## 开端口

两种方式

`ip+端口`

阿里云开启端口

`域名`

域名转发配置

申请域名-配置转发-申请证书-nginx配置
这里不赘述

参考文件
`nginx\conf\conf.d\gitea.lovestory.cyou.conf-https`

## 上传docker compose文件

```shell
rz docker-compose.yml
```

## 启动

```shell
docker compose up -d 
```

## 创建用户 

不设默认用户
第一个用户就是管理员

> 好像不能用 `admin` 是保留用户 

## 创建钩子

系统的和用户的都行 
注意保存秘钥

f1d20058-b8e7-4dee-861c-d772777e24bb
gto_ysiwdncq6qt6cqicbaneyz54ewfaiq2zwadnhkfnnsv5oltglt2a

# 创建仓库



#  推送项目