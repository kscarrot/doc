#!/bin/bash

# 源目录和目标目录
SOURCE_DIR="/Users/ks/Code/doc"

DEST_DIR="/Users/ks/Documents/笔记双向/jl-doc/技术文档"
LOG_FILE="./sync_docs.log"

# 获取当前时间
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# 记录开始时间到日志
echo "=== 同步开始于: $TIMESTAMP ===" >> "$LOG_FILE"

# 检查源目录是否存在
if [ ! -d "$SOURCE_DIR" ]; then
    echo "错误: 源目录 $SOURCE_DIR 不存在!" | tee -a "$LOG_FILE"
    exit 1
fi

# 检查目标目录是否存在，如果不存在则创建
if [ ! -d "$DEST_DIR" ]; then
    echo "目标目录不存在，正在创建..." | tee -a "$LOG_FILE"
    mkdir -p "$DEST_DIR"
fi

# 使用rsync进行同步
# -a: 归档模式，保持所有文件属性
# -v: 显示详细信息
# -h: 人类可读的格式
# --delete: 删除目标目录中源目录没有的文件
rsync -avh --delete "$SOURCE_DIR/" "$DEST_DIR/" 2>> "$LOG_FILE"

echo "同步完成!" | tee -a "$LOG_FILE"
echo "=== 同步结束于: $(date '+%Y-%m-%d %H:%M:%S') ===" >> "$LOG_FILE"
echo "----------------------------------------" >> "$LOG_FILE" 