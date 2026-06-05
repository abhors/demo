#!/bin/bash
# 启动nexus需要先给目录权限否则启动不了
mkdir nexus-data
chown -R 200:200 nexus-data
