# 用户信息

```bash
# 设置全局用户名和邮箱
git config --global user.name "你的姓名"
git config --global user.email "你的邮箱@example.com"

# 设置当前仓库的用户信息（可选）
git config user.name "项目专用姓名"
git config user.email "项目专用邮箱@example.com"

# 设置mac凭证管理
git config --global credential.helper osxkeychain
```

## 注意事项

1. **全局配置**：使用 `--global` 影响所有仓库
2. **本地配置**：不使用 `--global` 只影响当前仓库
3. **配置优先级**：本地配置 > 全局配置 > 系统配置
4. **备份配置**：重要配置建议备份到版本控制中

一般配置自己 `github`的同邮箱 为全局邮箱

对于公司项目 单独设置专用的 `mail`和 `name`

# 常用

## 大小写

```bash
git config --global core.ignorecase false
```

**作用**：强制 Git 检查文件名大小写

建议直接写死区分大小写

不然发现的时候改起来要做远程的同步变更,非常恶心

## 自动变基

```bash
git config --global pull.rebase true
```

- **默认行为**：`git pull` 默认使用 `merge` 策略，会创建一个合并提交
- **rebase 行为**：使用 `rebase` 策略，会将本地提交重新应用到远程分支的最新提交之上
- **效果**：保持提交历史的线性，避免不必要的合并提交

## 自动存储

```bash
git config --global rebase.autoStash true
```

在拉取或变基时,如果工作区有未提交的更改,操作将被中止

`autoStash` 能在这些操作前自动将您的更改暂存起来,操作完成后再自动恢复

## 换行符处理

```bash
git config --global core.autocrlf input
```

此设置会在提交时将 `CRLF` 转换为 `LF`，但检出时不做转换

## 基础操作别名

常规别名 比如用 `git co` 来 代替 `git checkout` 可以少打一些字

```bash
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
```

## 复合操作

```bash
# git add 的反向操作
git config --global alias.unstage 'reset HEAD --'

# 只查看最近一次提交的日志
git config --global alias.last 'log -1 HEAD'

# 强制推送
git config --global alias.psf 'push --force-with-lease'
```

# 日志

```bash

# 日志带颜色输出
git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
# 让git log显示分支名和tag等装饰信息
git config --global log.decorate auto
# 使用7位的短哈希而不是40位长哈希
git config --global log.abbrevCommit true
```

# 钩子

- `pre-commit` 在`git commit` 执行前运行
  适合跑`Prettier`和`Linter`
- `pre-push` 在 `git push` 执行前运行
  适合跑测试和其他提交工作
- `commit-msg`
  可用于检查提交信息是否符合规范

# ignore

当需要忽略特定本地文件（如个人 IDE 配置、日志文件等）

但避免将这些规则提交到共享的 `.gitignore` 文件中时

可采用以下三种方案：

---

## 方案一：使用 `.git/info/exclude`（推荐方案）

Git 原生支持通过仓库本地路径 `.git/info/exclude` 配置忽略规则，该文件不会被纳入版本控制。

**优势：**

- 规则完全本地化，与项目 `.gitignore` 隔离
- 不会触发 `git add`/`git commit` 操作
- 无远程推送风险

**实施步骤：**

1. 在项目根目录打开 `.git/info/exclude`
2. 按 `.gitignore` 语法添加规则，例如：

   ```gitignore
   # 忽略日志文件
   *.log

   # 忽略本地配置文件
   local_config.json

   # 忽略 IDE 配置目录
   .idea/
   ```

3. 保存后规则立即生效，且仅作用于当前仓库

---

## 方案二：跳过 `.gitignore` 的变更追踪

当需要临时修改已被版本控制的 `.gitignore` 文件时，可通过索引控制实现本地修改隔离。

**实施步骤：**

```bash
# 禁用 .gitignore 变更检测
git update-index --skip-worktree .gitignore

# 恢复变更检测
git update-index --no-skip-worktree .gitignore
```

**注意事项：**

- 优势：支持直接修改 `.gitignore` 文件
- 风险：长期使用可能导致版本管理状态混淆
- 替代命令 `--assume-unchanged` 主要用于性能优化，非此场景推荐方案

---

## 方案三：全局忽略规则配置

适用于需跨项目忽略的通用文件（如系统文件 `.DS_Store`、`Thumbs.db` 或编辑器临时文件）。

**实施步骤：**

1. 创建全局规则文件：
   ```bash
   touch ~/.gitignore_global
   ```
2. 编辑规则内容：

   ```gitignore
   # 系统文件
   .DS_Store
   Thumbs.db

   # 编辑器文件
   *.swp
   .vscode/
   ```

3. 注册全局配置：
   ```bash
   git config --global core.excludesfile ~/.gitignore_global
   ```

---

## 方案对比与选型指南

| 方案                | 适用场景                         | 优势               | 注意事项           |
| ------------------- | -------------------------------- | ------------------ | ------------------ |
| `.git/info/exclude` | 项目专属本地规则                 | 无副作用，原生支持 | 仅限当前仓库生效   |
| `--skip-worktree`   | 临时隔离 `.gitignore` 修改       | 符合文件修改直觉   | 需主动管理索引状态 |
| 全局 `gitignore`    | 跨项目通用规则（如 OS/IDE 文件） | 配置一次永久生效   | 不适用项目特定规则 |
