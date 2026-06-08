# 部署步骤


## 拉取镜像
```shell
# 先拉镜像 防止一直卡着
docker pull woodpeckerci/woodpecker-server:v3
docker pull woodpeckerci/woodpecker-agent:v3
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
`nginx\conf\conf.d\woodpecker.lovestory.cyou.conf-https`

## 上传docker compose文件

```shell
rz docker-compose.yml
```

## 启动

```shell
docker compose up -d 
```

## 配置

先改配置

``` properties
# server
# 用户名
WOODPECKER_ADMIN=abhors
# 秘钥 随机生成就行固定位数 用于server agent通信用
WOODPECKER_AGENT_SECRET=2f26c6a0e97e00c65a9e89fc39a95be532c19cb600c53fa555eada297c3569cb
# 是否启用gitea
WOODPECKER_GITEA=true
# gitea地址
WOODPECKER_GITEA_URL=https://gitea.lovestory.cyou
# 上一步 创建gitea的应用的秘钥
# gitea client
WOODPECKER_GITEA_CLIENT=718dc249-2edc-4edd-8bc9-06ba569c2007
# gitea secret
WOODPECKER_GITEA_SECRET=gto_zovinkqbrekitnhoiez5376dhzkccvz7253ndyaxqjq2gcb2okdq

```

```properties
# agent
# 一定要加白名单 否则会因为宿主机权限问题 无法拉取镜像
WOODPECKER_PLUGINS_PRIVILEGED=*,plugins/docker,docker.io/plugins/docker,plugins/docker:latest
```


# 启动
```shell

# 直接启动就行
docker compose up -d

# 如果要重新部署 记得清空卷数据 否则之前的数据可能会影响 之前的部署记录 登录等
#volumes:
#  woodpecker-server-data:
#  woodpecker-agent-config:
 
docker volumes rm woodpecker-server-data woodpecker-agent-config 
   
```

# 创建 CI/CD 管理文件

有两种方式用于流水线部署

1 `.woodpecker.yaml` 文件

2 `.woodpecker` 文件夹

优先单文件 使用文件夹就是可以分步骤 多版本构建 多机器部署

非常灵活 全看自己发挥 详细使用看官网 这里不赘述

<a href="https://woodpecker-ci.org/">官网链接</a>

# 添加项目

点击添加项目

然后就能看到 `gitea` 的仓库列表 

添加你想添加的项目


# 修改项目配置 

管理用户点击界面右上角的 ⚙️
选择仓库
找到要修改的项目

```text

受信任

□   网络

    流水线容器可以获得网络权限，例如更改 DNS。

□   卷

    流水线容器允许被挂载卷。

□   安全

    流水线容器可以获得安全权限。
```

这三个都勾选上 然后才可以正常拉取镜像 