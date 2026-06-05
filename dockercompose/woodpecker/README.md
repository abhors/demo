# 部署步骤

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