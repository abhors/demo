#!/bin/bash
# deploy.sh
set -e

REGISTRY="registry.cn-zhangjiakou.aliyuncs.com"
IMAGE_NAME="${REGISTRY}/abhors/demo:latest"
CONTAINER_NAME="demo-app"

echo "=========================================="
echo " 🚀 开始远程部署: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="

# 1. 拉取最新镜像 (前提：你已经在服务器上手动执行过一次 docker login 保持登录状态)
echo "👉 正在拉取最新镜像..."
docker pull $IMAGE_NAME

# 2. 清理旧容器
echo "👉 正在清理旧容器..."
docker stop $CONTAINER_NAME 2>/dev/null || true
docker rm $CONTAINER_NAME 2>/dev/null || true

# 3. 启动新容器（带内存限制）
echo "👉 正在启动新容器..."
docker run -d \
  --name $CONTAINER_NAME \
  -p 8080:8080 \
  --memory="1.2g" \
  --restart always \
  $IMAGE_NAME

# 4. 清理残留的旧镜像
echo "👉 清理历史构建残留..."
docker image prune -f

echo "=========================================="
echo " 🎉 部署成功！"
echo "=========================================="