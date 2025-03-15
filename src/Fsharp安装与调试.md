# 安装

查看[官方安装引导](https://dotnet.microsoft.com/zh-cn/learn/languages/fsharp-hello-world-tutorial/install)
要求安装[dotnet SDK](https://dotnet.microsoft.com/zh-cn/download)

检查是否安装成功

```bash
dotnet --version
```

出错的话可能是因为 bash 的绑定位置有问题
重新绑定一下安装目录 `/usr/local/share/dotnet`可能因为安装环境有所区别

```bash
sudo ln -s /usr/local/share/dotnet/dotnet /usr/local/bin/
```

使用命令行初始化一个 workspace

```bash
dotnet new console -lang F# -o MyFSharpApp
```

会默认写一个文件

```fsharp
// Program.fs
printfn "Hello from F#"
```

执行即可

```bash
dotnet run
```

如果是脚本文件的话 可以使用 `.fsx` 后缀 脱离工程文件的约束 单文件执行

配合插件[Ionide for F#](https://ionide.io/)
可以看到类型和推导的 hint

# 调试

在`haskell`中
我们会用`runghc`来直接运行一个文件
用 `cargo run`来执行一个项目

在`F#`中 只需要将文件的后缀命名为`fsx`就可以直接执行了
但是直接调试一个 fsx 比较麻烦

这里介绍一下怎么调试一个`fs`工程
