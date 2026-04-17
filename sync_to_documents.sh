#!/bin/bash
# 同步项目到 Documents 目录
rsync -av --delete \
  --exclude '.git' \
  --exclude '.godot' \
  ~/WorkSpace/open-MOChai/ ~/storage/shared/Documents/open-MOChai/
echo "同步完成: $(date)"
