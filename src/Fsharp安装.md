# Fsharp 安装与调试

## 安装

查看[官方安装引导](https://dotnet.microsoft.com/zh-cn/learn/languages/fsharp-hello-world-tutorial/install)
要求安装[dotnet SDK](https://dotnet.microsoft.com/zh-cn/download)

检查是否安装成功

```bash
dotnet --version
```

出错的话可能是因为 PATH 的绑定位置有问题
重新绑定一下安装目录 `/usr/local/share/dotnet`，可能因为安装环境有所区别

```bash
sudo ln -s /usr/local/share/dotnet/dotnet /usr/local/bin/
```

编辑器配合插件 [Ionide for F#](https://ionide.io/)，可以看到类型和推导的 hint。调试还需要装 C# 扩展（`coreclr` 调试器由它提供）。

## 运行

工程和单文件是两条路。

Haskell 里用 `runghc` 直接跑一个文件、用工程工具跑项目。F# 对应的是：

- 工程：`.fs` + `.fsproj`，`dotnet run`
- 单文件：`.fsx`，脱离工程约束，`dotnet fsi`

### 工程

```bash
dotnet new console -lang F# -o MyFSharpApp
cd MyFSharpApp
dotnet run
```

会默认写一个文件：

```fsharp
// Program.fs
printfn "Hello from F#"
```

### 脚本

```bash
dotnet fsi hello.fsx
```

```fsharp
// hello.fsx
printfn "Hello from F#"
```

`.fsx` 方便试代码，但断点调试比较麻烦，需要调试时用工程。

## 调试

对上面的 console 工程：

1. 用 VS Code / Cursor 打开 `MyFSharpApp` 目录（要能看到 `.fsproj`）
2. 在 `Program.fs` 行号左侧打断点
3. `F5` 启动调试；没有 `launch.json` 时选 `.NET Core Launch (console)`，让它生成配置

生成后大致是：

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": ".NET Core Launch (console)",
      "type": "coreclr",
      "request": "launch",
      "preLaunchTask": "build",
      "program": "${workspaceFolder}/bin/Debug/net8.0/MyFSharpApp.dll",
      "args": [],
      "cwd": "${workspaceFolder}",
      "console": "internalConsole",
      "stopAtEntry": false
    }
  ]
}
```

`program` 里的 `net8.0` 和 dll 名要和本机 SDK、工程名一致，对不上就先 `dotnet build` 看输出目录。

脚本想调试时，把内容挪进 `Program.fs` 再 `F5`。临时看值用 `printfn "%A" x` 就够了。
