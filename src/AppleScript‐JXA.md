> 使用 JavaScript 编写 AppleScript，这实际上指的是 JavaScript for Automation (JXA)。

> JXA 是 Apple 在 OS X Yosemite (10.10) 引入的，允许开发者使用 JavaScript 来编写脚本，实现与 AppleScript 类似的系统自动化功能。


一个容易理解的例子
新建一个Chrome标签页并且跳到指定的URL

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

开启权限直接执行即可  第一行注释会告诉bin以何种方式执行这段代码 默认调用 `run` 函数
```bash
chmod +x script.js  
./script.js 
```
