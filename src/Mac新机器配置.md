升级系统并重启


# 安装 [homebrew](https://brew.sh/zh-cn/) 

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

安装完成会跳出提示 需要把脚本写入环境
```bash
echo >> /Users/ks/.zprofile
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/ks/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

检查安装是否成功
```bash
brew help
```

# 安装命令行工具[iterm2](https://iterm2.com/)

```bash
brew install --cask iterm2
```

配置浮动窗口

- 打开iterm2 setting 
- 选择 一级Tab  `Keys` 二级Tab  `Hotkey`
- 单击`Create a hotkey window` 绑定快捷键 我是 `option+space`
- 勾选 Floating window
- 切换 一级Tab `Profiles` 调整工作空间 bash 以及外观设置 
  我是 上半屏占位50% 加上 50% 透明度 


# 安装[vscode](https://code.visualstudio.com/)

```bash
brew install --cask visual-studio-code
code 
```

如果不能直接命令行启动vscode 
需要在vscode的命令里绑定一下路径
打开command Palette `shift + command + p`
```bash
install code command in Path
```

可选 安装等宽字体[FiraCode](https://github.com/tonsky/FiraCode)

```bash
brew install font-fira-code
```


# 安装[git ](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)

```bash
git -v
# 有输出直接跳过下方步骤

brew install git 
git -v

brew upgrade git
git -v
```

配置用户名
```bash
git config --global user.name "name"
git config --global user.email "name@mail.com"
git config --list
```
项目里可以单独配置,去掉`--global`参数即可 项目里的配置优先级比全局的配置高


[配置公钥](https://git-scm.com/book/zh/v2/%E6%9C%8D%E5%8A%A1%E5%99%A8%E4%B8%8A%E7%9A%84-Git-%E7%94%9F%E6%88%90-SSH-%E5%85%AC%E9%92%A5)

```bash
cd ~/.ssh
ssh-keygen -o
cat id_ed25519.pub | pbcopy
# 添加仓库个人配置sshkey copy剪贴板中的公钥内容
```


# 安装[zsh](https://github.com/ohmyzsh/ohmyzsh/wiki/Installing-ZSH)

```bash
brew install zsh 
# 查看本地可用的shell
cat /etc/shells
## 设置zsh为默认shell 
chsh -s /bin/zsh 
## 检查是否安装成功
echo $SHELL
## 安装oh-my-zsh 
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

cd ~/.oh-my-zsh/plugins
## 安装高亮插件 
## https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/INSTALL.md
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

## 安装自动提示插件
## https://github.com/zsh-users/zsh-autosuggestions/blob/master/INSTALL.md
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

## 配置插件到配置文件
code ~/.zshrc
## 添加插件名 zsh-syntax-highlighting  zsh-autosuggestions
## plugins=( 
##    # other plugins...
##    zsh-autosuggestions
##    zsh-syntax-highlighting
##    git
##    sudo
##    Z
## )

绑定一些常用的插件

## 顺手把主题改了
## ZSH_THEME="half-life"

## 重启zsh 
source ~/.zshrc
```



# 安装[node](https://nodejs.org/en/download)

使用nvm安装
```bash
# Download and install nvm:
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

# Download and install Node.js:
nvm install 23

# Verify the Node.js version:
node -v # Should print "v23.6.1".
nvm current # Should print "v23.6.1".

# Download and install pnpm:
corepack enable pnpm

# Verify pnpm version:
pnpm -v

```

使用[vlota](https://volta.sh)安装
vlota和pnpm配合使用的时候
1. 不能全局安装`-g`
2. `launch.json`需要指定执行路径`runtimeExecutable`

```bash
curl https://get.volta.sh | bash
volta install node@23
volta install pnpm
pnpm -v

# 需要写一下bash配置
echo -e '\nexport PATH="$HOME/.volta/bin:$PATH"\n' >> ~/.zshrc
source ~/.zshrc

# 查看node工具链版本
volta list
# 指定node工具链版本
volta pin node@23
volta pin pnpm@10
```
非根目录的可以在`pakage.json`里直接拓展根目录的配置
```
  "volta": {
    "extends": "../package.json"
  }
```

配置完成后就能在指定`workspace`打开shell的时候自动切换到对应node工具链的版本了

# 其他实用软件


```bash
# 笔记工具
brew install --cask obsidian
# 分屏工具
brew install --cask rectangle
# 自动解压工具
brew install --cask the-unarchiver
# 好用的播放器
brew install --cask iina
# 鼠标滚轮反向
brew install --cask scroll-reverser
```


[alfred](https://www.alfredapp.com/)

[keycastr](https://github.com/keycastr/keycastr)

[obs](https://github.com/obsproject/obs-studio)

[kap](https://github.com/wulkano/Kap)

[tableplus](https://github.com/TablePlus/TablePlus)


# 系统配置
> 个人习惯

## 桌面与程序坞

置于屏幕上的位置 右侧 自动隐藏
关闭奇怪的窗口交互特效


触发角快捷键
右上 启动台
右下 桌面

## 键盘-功能键
将F1等键用作标准功能键

## 安装搜狗拼音 
键盘设置 所有输入法 删掉苹果自带的拼音输入法
搜狗偏好设置

常用:
默认中文 半角 简体
双拼+小鹤方案
勾选中文下使用英文标点

按键:
禁用所有状态切换
禁用所有快捷功能

高级:
禁用所有输入拓展以及下方所有设置

# 代理配置
参考[代理配置](src/%E4%BB%A3%E7%90%86%E9%85%8D%E7%BD%AE.md)


# shell工具
```bash
brew install ripgrep
brew install bat  
brew install eza
brew install fd
brew install zoxide
# echo 'eval "$(zoxide init zsh --cmd z)"' >> ~/.zshrc
```

[rg 用户指南](https://gitcode.gitcode.host/docs-cn/ripgrep-docs-cn/GUIDE.html)

[bat 用户指南](https://github.com/sharkdp/bat/blob/master/doc/README-zh.md)

[eza 用户指南](https://eza.rocks/)

[fd 用户指南](https://github.com/cha0ran/fd-zh?tab=readme-ov-file#how-to-use)