#!/bin/bash
# 同步项目到 Documents 目录（只同步有变化的文件）
# rsync -c 使用校验和比较，确保只传输真正变化的文件
rsync -avc --delete \
  --exclude '.git' \
  --exclude '.godot' \
  ~/WorkSpace/open-MOChai/ ~/storage/shared/Documents/open-MOChai/
echo "同步完成: $(date)"
