# 部署文档

## 拉取镜像
```shell
# 先拉镜像 防止一直卡着
docker pull sonatype/nexus3:latest
```

## 上传docker compose文件

```shell
rz docker-compose.yml
```

## 开端口

nexus 有三个端口需要开 
分别是管理端 8081 仓库端 8082 仓库代理 8083

两种方式

`ip+端口`

阿里云开启端口

`域名`

域名转发配置

申请域名-配置转发-申请证书-nginx配置
这里不赘述

参考文件
```  shell
nginx\conf\conf.d\push.lovestory.cyou.conf-http
nginx\conf\conf.d\push.lovestory.cyou.conf-https
nginx\conf\conf.d\registry.lovestory.cyou.conf-https
nginx\conf\conf.d\registry.lovestory.cyou-http
```


## 启动

```shell
docker compose up -d 
```

### 启动nexus需要先给目录权限否则启动不了

```shell
mkdir nexus-data
chown -R 200:200 nexus-data
```


## 调整 Nexus 基础配置
在创建仓库前，建议先对 Nexus 进行两项基础设置，这会直接影响后续 Docker 客户端的正常使用。

1. 启用匿名拉取（推荐）：为了允许团队成员无需登录即可拉取镜像，可以在左侧菜单 Security -> Anonymous 中勾选 Allow anonymous users to access the server，保存使配置生效。

2. 启用 Docker Bearer Token Realm：这是为了让 docker login 登录机制能正常运转。

登录后，在左侧菜单找到 Security -> Realms。

在右侧 Available 栏中找到 Docker Bearer Token Realm，点击中间的 > 按钮，将其移到左侧 Active 栏中，最后点击 Save 保存。

下面我们按步骤来创建三个仓库。

### 1. 创建 proxy 仓库 (拉取镜像)
新建仓库：点击左侧菜单 Repositories -> Repositories，然后点击右上角 Create repository，类型选择 docker (proxy)。

填写配置：

Name：填入 docker-proxy。

Remote storage：填入 https://registry-1.docker.io (Docker Hub官方源)。如果需要加速，也可以替换为其他镜像源（如阿里云镜像加速地址 https://<your-id>.mirror.aliyuncs.com）。

Docker Index：选择 Use Docker Hub。

> HTTP port(s) 这个不用填一般最后统一用group拉取

HTTP port(s)：分配给此仓库的端口，例如 8082。注意此端口不能与Nexus自身端口或系统其他端口冲突。

Allow anonymous docker pull：推荐勾选，免登录拉取。

保存：点击 Create repository 完成创建。

### 2. 创建 hosted 仓库 (推送镜像)
新建仓库：同样在 Repositories 界面，点击 Create repository，类型选择 docker (hosted)。

填写配置：

Name：填入 docker-hosted。

HTTP port(s)：分配给此仓库的端口，例如 8083。请确保该端口已开放且未被占用。

Allow anonymous docker pull：根据需求选择是否允许匿名拉取，通常托管仓库（用于推送）此项可不勾选。

Enable Docker V1 API：默认不勾选。

Deployment policy：选择 Allow redeploy 以允许覆盖推送相同标签的镜像。

保存：点击 Create repository 完成创建。

### 3. 创建 group 仓库 (统一入口)
为了方便使用，推荐创建一个 group 仓库将 proxy 和 hosted 组合起来，这样开发人员可以只用一个地址完成拉取和推送。

新建仓库：在 Repositories 界面，点击 Create repository，类型选择 docker (group)。

填写配置：

Name：填入 docker-group。

HTTP port(s)：分配给此仓库的端口，例如 8082。

Member repositories：在 Available 栏中，将刚才创建的 docker-hosted 和 docker-proxy 按顺序添加到 Members 栏中。注意：hosted 应在 proxy 之上，以便优先使用本地镜像。

保存：点击 Create repository 完成创建。

### 4. 客户端配置与验证
在客户端使用 docker-group (统一入口) 的地址进行拉取和推送。

#### 准备工作：处理 HTTP 协议警告
如果 Nexus 的端口没有配置 HTTPS，Docker 客户端默认会报错 server gave HTTP response to HTTPS client。需要修改 /etc/docker/daemon.json 文件（如没有则新建），将你的Nexus服务器IP和docker-group的端口（例如 8084）添加到 insecure-registries 列表中：

```json
{
"registry-mirrors": ["https://<your-mirror>"],
"insecure-registries": ["<your-nexus-ip>:8084"]
}
```
保存后，重启 Docker 服务使配置生效：

```bash
sudo systemctl daemon-reload
sudo systemctl restart docker
```
ai这么说 但是实际我操作完也拉不下来 docker 部署 是`DIND` 好像不吃这个配置


#### 拉取与推送验证
登录：首先登录你的 docker-group 仓库。系统会提示输入密码，你的 Nexus 密码即为 admin 用户的登录密码。

```bash
docker login <your-nexus-ip>:8082
```

拉取镜像 (测试 proxy 仓库)：执行以下命令，镜像将从 proxy 仓库拉取并自动缓存。

```bash
docker pull <your-nexus-ip>:8084/library/nginx:latest
```

推送镜像 (测试 hosted 仓库)：先给本地镜像打上标签，格式为 你的仓库地址/镜像名:标签。然后执行 docker push，镜像将被推送到 hosted 仓库中。

```
bash
docker tag nginx:latest <your-nexus-ip>:8084/my-nginx:latest
docker push <your-nexus-ip>:8084/my-nginx:latest
```

验证配置：返回 Nexus 管理界面，在 Repositories 中分别查看 docker-proxy 和 docker-hosted 的 Browse 页面。如果 docker-proxy 中存在刚才拉取的 nginx 镜像，且 docker-hosted 中存在推送的 my-nginx 镜像，则代表配置完全成功。