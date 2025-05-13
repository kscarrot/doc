系统设置->键盘->键盘快捷键->聚焦 取消勾选

设置 alfred hot key 为 `cmd + space`

当前键盘映射如下

- `cmd+space` alfred
- `opt+space` terminal iterm2 
- `ctl+space` 输入法切换 一个中文一个英文
- `opt+cmd+左右` tab 栏切换
- `ctl+opt+左右` 窗口分屏

## 页面跳转

> 一般网页的图标可以用 domain/favicon.ico 来拿例如 baidu.com/favicon.ico

```
# google搜索直接输入gs 顺位排第一可以不用设置

# 翻译成英文 快捷键 tse
https://translate.google.com/?hl=zh-cn&sl=auto&tl=en&text={query}&op=translate

# 翻译成中文 快捷键 tsz
https://translate.google.com/?hl=zh-cn&sl=auto&tl=zh-CN&text={query}&op=translate

# 百度搜索 快捷键 bds
https://www.baidu.com/s?ie=utf-8&wd={query}

# github搜索 快捷键 ghs
https://github.com/search?q={query}&type=repositories
```

## snippets

开启关键字自动展开的功能

### git 展开宏

```bash
# !gb 不想用gitcz的交互可以考虑 有时候要自定义一些操作比较方便
# 类似的还可以定义 git commit 之类的操作 通常用来 --no-verfiy 跳过本地的lint和ut 快速验证某些特性
git checkout -b feat/v2025{cursor}
```

### 字符串展开宏

`!im` 快速展开成 `xxxx@icloud.com`

同样的可以用来展开

常用账号 手机号 低安密码

### 文本模板宏

可以把常用的信息模板做成宏直接添加

比如展开变更审批邮件

```
To {clipboard},
	{curosr}
			Ks,{date:medium}
```

工作流就变成了剪贴发送对象到剪贴板

会自动填充到`clipboard`

模板展开的时候`{date}`会自动填上当天的日期

然后把光标正确填充到`{curosr}`位置

比较适合录入的信息同步 SOP 模板

比如 排期变更知会 发布变更知会 等

文本展开宏其实用输入法自带的自定义短语和可以做到,只是功能上会有确实

密码的话,现在网页端`chrome`支持预填充了 其实是可以考虑托管的

之前还有`1password`可以用 现在也没用了

## 剪贴板历史

- 勾选 `Text` : `7day` , `Images` : `24hours`
- hotkey 改为 `c`

可以记录近七天的文本和近一天的图片

放心大胆的重复`copy`,可以当做记忆缓存使用

## 工作流

### colors

匹配`#`开头 快速展示值对应的颜色

### [RecentDocuments](https://github.com/mpco/AlfredWorkflow-Recent-Documents)

快速筛选最近的 app,文件夹等

### [eudic 词典辅助](https://github.com/hanleylee/alfred-eudic-workflow)

匹配`e` 快速查阅欧陆词典 比`alfred`自带的词典好用

## 自定义工作流

> 使用 JavaScript 编写 AppleScript，这实际上指的是 JavaScript for Automation (JXA)。

> JXA 是 Apple 在 OS X Yosemite (10.10) 引入的，允许开发者使用 JavaScript 来编写脚本，实现与 AppleScript 类似的系统自动化功能。

一个容易理解的例子
新建一个 Chrome 标签页并且跳到指定的 URL

```bash
#!/usr/bin/env osascript -l JavaScript
function run() {
    // 指定要打开的 URL
    const url = "https://www.github.com";

    const chrome = Application("Google Chrome");
    const currentTabs = chrome.windows[0].tabs;
    currentTabs.push(new chrome.Tab({ url: url }));

    return `已在默认浏览器中打开 URL:${url}`;
}
```

开启权限直接执行即可 第一行注释会告诉 bin 以何种方式执行这段代码 默认调用 `run` 函数

```bash
chmod +x script.js
./script.js
```

然后在工作流新建一个触发器,绑定这个脚本就能实现了

如果需要额外的交互,可以`fork`官方的工具库[alfy](https://github.com/sindresorhus/alfy)进行魔改

```bash
npm install alfy
```

可以通过配置方便复用关键词过滤,列表展示,输入调用的交互

难度跟完成一个命令行工具差不多
