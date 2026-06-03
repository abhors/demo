# Woodpecker CI 流水线说明

## 概述

[Woodpecker CI](https://woodpecker-ci.org/) 是一款轻量级、开源的持续集成/持续部署(CI/CD)工具，本项目使用它来实现代码的自动化构建、Docker 镜像打包及远程部署。

项目中有 **两套流水线配置方案**，二者互斥，可根据实际需求选用其中一套：

| 方案 | 配置文件 | 适用场景 |
|------|---------|---------|
| 单文件流水线 | `.woodpecker.yaml`（项目根目录） | 单节点部署，快速上手 |
| 多文件流水线 | `.woodpecker1/` 目录 | 多节点集群部署，流水线拆分与复用 |

---

## 一、外部依赖

流水线正常运行需要以下前置条件：

| 依赖项 | 用途 | 说明 |
|--------|------|------|
| Woodpecker Server + Agent | CI 引擎 | 需要在服务器上部署 Woodpecker 服务端和至少一个 Agent |
| Docker | 镜像构建与运行 | Agent 所在机器需安装 Docker，用于构建镜像和运行容器 |
| 阿里云 ACR（容器镜像仓库） | 存储 Docker 镜像 | `registry.cn-zhangjiakou.aliyuncs.com/abhors/demo` |
| Maven 缓存卷 | 加速构建 | `/tmp/maven-cache:/root/.m2`，避免每次下载依赖 |
| SSH 免密/密码登录 | 远程部署 | 目标服务器需开放 22 端口并具备 Docker 环境 |
| Woodpecker Secrets | 凭据管理 | 在 Woodpecker 面板中配置密钥 |

### 必需的 Secrets

| Secret 名称 | 说明 |
|-------------|------|
| `aliyun_acr_username` | 阿里云容器镜像仓库用户名 |
| `aliyun_acr_password` | 阿里云容器镜像仓库密码 |
| `136_ssh_host` | 136 服务器 IP 地址 |
| `136_ssh_user` | 136 服务器 SSH 用户名 |
| `136_ssh_password` | 136 服务器 SSH 密码 |
| `114_ssh_host` | 114 服务器 IP 地址（集群部署时使用） |
| `114_ssh_user` | 114 服务器 SSH 用户名（集群部署时使用） |
| `114_ssh_password` | 114 服务器 SSH 密码（集群部署时使用） |

---

## 二、`.woodpecker.yaml` — 单文件流水线（根目录）

### 作用

定义一条完整的 CI/CD 流水线，包含 **构建 → 镜像打包推送 → 远程部署** 三个阶段，每次向 `master` 分支推送代码时自动触发。

### 执行流程

```
Git Push (master 分支)
       │
       ▼
┌──────────────────────────────┐
│  Step 1: Java 构建            │
│  Maven 3.9.6 + JDK 17        │
│  mvn clean package -DskipTests│
│  挂载 /tmp/maven-cache 缓存   │
└─────────────┬────────────────┘
              │
              ▼
┌──────────────────────────────┐
│  Step 2: 镜像构建与推送       │
│  使用 plugin-docker-buildx    │
│  构建 Docker 镜像并推送至      │
│  阿里云 ACR 镜像仓库           │
│  触发条件: push 事件           │
└─────────────┬────────────────┘
              │
              ▼
┌──────────────────────────────┐
│  Step 3: 远程终端部署         │
│  SSH 连接到 136 服务器         │
│  docker login → stop → rm    │
│  → pull → run (端口 8080)    │
│  触发条件: push 事件           │
└──────────────────────────────┘
```

### 触发条件

| Step | 事件 | 分支 |
|------|------|------|
| Java 构建 | `push`, `pull_request` | `master` |
| 镜像构建与推送 | `push` | `master` |
| 远程终端部署 | `push` | `master` |

> **注意**：`pull_request` 事件仅触发构建步骤，不会执行镜像推送和部署，确保 PR 的安全性。

---

## 三、`.woodpecker1/` 目录 — 多文件流水线

### 作用

将流水线拆分为 **构建** 和 **部署** 两个独立文件，借助 Woodpecker 的 `depends_on` 机制实现流水线编排。部署阶段使用 `matrix` 矩阵策略，支持同时向多台服务器（136 和 114）批量部署。

### 文件结构

```
.woodpecker1/
├── build.yaml    # 构建流水线：Maven 编译 + Docker 镜像构建推送
├── deploy.yaml   # 部署流水线：SSH 连接集群节点，拉取镜像并启动容器
└── README.md     # 本说明文档
```

### 3.1 `build.yaml` — 构建流水线

包含两个步骤，负责代码编译和镜像制作：

```
┌──────────────────────────────┐
│  Step 1: Java 构建            │
│  Maven 3.9.6 + JDK 17        │
│  mvn clean package -DskipTests│
└─────────────┬────────────────┘
              │
              ▼
┌──────────────────────────────┐
│  Step 2: 镜像构建与推送       │
│  构建 Docker 镜像 → 推送 ACR  │
│  触发: push/pull_request/manual│
└──────────────────────────────┘
```

#### 依赖关系

`deploy.yaml` 依赖 `build.yaml`：通过 `depends_on: [build]` 声明，确保只有构建成功后才会触发部署。

### 3.2 `deploy.yaml` — 集群部署流水线

使用 **Matrix 矩阵策略**，对两台服务器并行执行部署：

```
          build.yaml 构建成功
                 │
                 ▼
    ┌─────────────────────────┐
    │  Matrix 矩阵并行执行      │
    ├─────────────────────────┤
    │  节点A: 136 服务器        │
    │  SSH → login → pull      │
    │  → stop → rm → run       │
    ├─────────────────────────┤
    │  节点B: 114 服务器        │
    │  SSH → login → pull      │
    │  → stop → rm → run       │
    └─────────────────────────┘
```

每个节点的 Secret 通过 `${SECRET_NODE_IP}` 等变量动态注入，实现配置复用。

### 3.3 执行流程总览

```
┌──────────────────────────────────────────────────────┐
│  触发条件: push / pull_request / manual → master 分支  │
└──────────────────────┬───────────────────────────────┘
                       │
                       ▼
              ┌────────────────┐
              │  build.yaml    │
              │  Step 1: 构建   │
              │  Step 2: 推送   │
              └───────┬────────┘
                      │ depends_on
                      ▼
              ┌────────────────┐
              │  deploy.yaml   │
              │  Matrix 并行:   │
              │  136 ← → 114   │
              └────────────────┘
```

### 3.4 与单文件方案的区别

| 特性 | `.woodpecker.yaml` | `.woodpecker1/` |
|------|-------------------|-----------------|
| 文件数量 | 1 个 | 2 个（build + deploy） |
| 部署节点 | 单节点（136） | 多节点集群（136 + 114） |
| 流水线复用 | 否 | 是（build 可被多条流水线依赖） |
| 并行部署 | 否 | 是（Matrix 并行） |
| 手动触发 | 不支持 | 支持（`manual` 事件） |

---

## 四、关键镜像说明

流水线中使用了以下 Docker 镜像，均通过国内镜像加速拉取：

| 镜像 | 用途 |
|------|------|
| `docker.m.daocloud.io/library/maven:3.9.6-eclipse-temurin-17` | Maven 编译环境（JDK 17） |
| `docker.m.daocloud.io/woodpeckerci/plugin-docker-buildx:latest` | Docker Buildx 构建插件 |
| `appleboy/drone-ssh` | SSH 远程执行插件 |
| `registry.cn-zhangjiakou.aliyuncs.com/abhors/demo:latest` | 最终产出的应用镜像 |
| `registry.cn-zhangjiakou.aliyuncs.com/abhors/ibm-semeru-runtimes:open-17-jre` | 运行时基础镜像（Dockerfile 中定义） |

---

## 五、常见问题

**Q: 为什么有两套流水线配置？**

A: `.woodpecker.yaml` 是早期单节点方案，`.woodpecker1/` 是升级后的多文件集群方案。两者不会同时生效（Woodpecker 会优先读取根目录的 `.woodpecker.yaml`，若不存在则扫描子目录中的流水线文件）。

**Q: Maven 缓存卷的作用？**

A: 将宿主机 `/tmp/maven-cache` 挂载到容器的 `/root/.m2`，确保每次构建复用已下载的 Maven 依赖，大幅缩短构建时间。

**Q: 如何添加新的集群节点？**

A: 在 `deploy.yaml` 的 `matrix.include` 中添加新的节点配置，并在 Woodpecker Secrets 中创建对应的 `{name}_ssh_host`、`{name}_ssh_user`、`{name}_ssh_password` 密钥即可。
