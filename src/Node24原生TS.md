# 起因

在`bun`,`deno`等众多竞品的压力下

`Nodejs`也不得不加入了实验功能支持类型擦除直接跑`Typescript`文件了

这里接入一个`koa`项目记录一下原生跑`Typescript`需要做哪些改造

# 配置

首先是`pakage.json`

在原生支持之前,要使用`Typescript`有两个方法

1. 安装`ts-node`依赖,然后用`register`拉起入口文件
2. 安装构建工具,使用`nodemon`监控文件变动然后编译后实时重启

现在增加`--experimental-strip-types`的参数就可以直接启动`ts`文件了

`--watch`功能也能监听文件变化然后重启 替代了`nodemon`

```bash
node --watch --experimental-strip-types src/index.mts
```

然后项目直接就报错了,因为`ES`和`CommonJS`模块不兼容

需要手动指定后缀为`mts` 惯用的省略写法是错误的

```typescript
// main.mts
import { someFunction } from "./my-module.mts"; // 正确的方式

// import { someFunction } from './my-module'; // 错误：缺少扩展名
```

对应的`tsconfig.json`也要做相应的调整

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    /** 允许默认导入CommonJS模块 */
    "esModuleInterop": true,
    "strict": true,
    "skipLibCheck": true,
    /** 文件名大小写敏感 */
    "forceConsistentCasingInFileNames": true,
    /** 确保擦除后路径不会被改写 要求使用正确的导入语法 */
    "verbatimModuleSyntax": true,
    "sourceMap": false,
    /** allowImportingTsExtensions 必须配合使用 */
    "noEmit": true,
    /** 允许在导入时使用扩展名 */
    "allowImportingTsExtensions": true
  },
  "exclude": ["node_modules", "dist"]
}
```

改完之后启动会报错,也是经典的模块冲突问题

```bash
__dirname is not defined in ES module scope
```

在`ES`作用域内, `require`,`__dirname`,`__filename`等依赖`CommonJS`注入的变量是不存在的

需要使用`import.meta.url`这个实际以`file://`协议开头的路径来派生

```typescript
// 导入Node.js内置的'path'和'url'模块
import path from "node:path";
import { fileURLToPath } from "node:url";

// 1. 获取当前模块的文件名 (替代 __filename)
const __filename = fileURLToPath(import.meta.url);

// 2. 获取当前模块所在的目录名 (替代 __dirname)
const __dirname = path.dirname(__filename);

// 现在你就可以像以前一样使用 __filename 和 __dirname 了
console.log("Current file path (filename):", __filename);
console.log("Current directory path (dirname):", __dirname);

// 示例：拼接一个文件路径
const filePath = path.join(__dirname, "data", "file.json");
console.log("Constructed file path:", filePath);
```

也可以使用最新的`URL`标准来进行路径的读取

```typescript
import { readFile } from "node:fs/promises";

// 直接构造目标文件的URL，无需中间变量
const templateURL = new URL("./assets/template.html", import.meta.url);

// 直接使用这个URL对象！
// 现代Node.js的fs API可以直接接受URL对象作为路径参数。
try {
  const content = await readFile(templateURL, { encoding: "utf8" });
  console.log("文件内容:", content);
} catch (err) {
  console.error("读取文件失败:", err);
}

// 如果你需要一个字符串路径给旧的库使用
import { fileURLToPath } from "node:url";
const templatePathString = fileURLToPath(templateURL);
console.log("文件路径字符串:", templatePathString);
```

## 调试

没有 `sourceMap` 映射也可以直接调试 

修改`launch.json`打好断点直接`F5`就可以重启了

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "🚀 Debug SSE Server",
      "type": "node",
      "request": "launch",
      "program": "${workspaceFolder}/src/index.mts",
      "runtimeArgs": ["--experimental-strip-types"],
      "skipFiles": ["<node_internals>/**"],
      "console": "integratedTerminal",
      "env": {
        "NODE_ENV": "development"
      },
      "restart": true
    }
  ]
}
```

## 类型擦除

### 传统的 `TypeScript` 工作流

在 `Node24` 这个新特性出现之前，`NodeJS`只认识 `JavaScript`

工作流程通常是这样的：

#### 1. 编写 `TypeScript` 代码 (.ts)

代码里包含了类型注解，比如 `const name: string = "Alice";`F

#### 2.编译/转换 (Transpilation)

你需要一个工具（比如 `TypeScript` 编译器 `tsc` 或者 `ts-node`）来读取你的 `.ts` 文件\

- 类型检查：确保你的代码没有类型错误（比如把数字赋给字符串）

- 代码转换：把 TypeScript 代码转换成纯粹的 JavaScript 代码 (.js)。这个过程会擦除掉所有类型注解。

例如，`const name: string = "Alice";` 会被转换为 `const name = "Alice";`

#### 3. 运行 `JavaScript` 代码 (.js)

最后，你用 `node` 命令去运行那个转换后生成的 .js 文件。
这个流程的痛点：总有一个“编译”或“转换”的中间步骤。对于开发来说，这意味着更慢的启动速度和更复杂的工具配置

### 新的`Typescript`工作流

1.  **编写 TypeScript 代码 (`.ts`)**
2.  **直接运行**：`node --experimental-strip-types your-code.ts`

- `const name: string = "Alice";` : `Node.js` 把它看作 `const name = "Alice";`
- `interface User { name: string; }` : `Node.js` 直接把这整块都忽略掉，因为它在运行时不存在

但是`node`对`Typescript`的类型擦除(Strip)是有限的

对于枚举,命名空间,标准化前的装饰器规范以及类的访问符等需要转换的特性都不支持

```typescript
enum Color {
  Red,
  Green,
  Blue,
}
```

会被转换成

```javascript
var Color;
(function (Color) {
  Color[(Color["Red"] = 0)] = "Red";
  Color[(Color["Green"] = 1)] = "Green";
  Color[(Color["Blue"] = 2)] = "Blue";
})(Color || (Color = {}));
```

这里执行简单的擦除是不行的,转换过程中构建了一个新的对象

### 枚举的处理

创建一个普通对象,然后使用`as const`进行断言

```typescript
// 1. 定义一个普通的 JavaScript 对象，并使用 'as const'
export const Color = {
  Red: 0,
  Green: 1,
  Blue: 2,
} as const;

// 2. (可选) 如果你需要一个代表所有可能值的联合类型，可以这样做：
type ColorValue = (typeof Color)[keyof typeof Color]; // 这个类型现在是： 0 | 1 | 2

// --- 如何使用 ---

function paint(colorValue: ColorValue) {
  if (colorValue === Color.Red) {
    console.log("Painting in Red");
  }
  // ...
}

paint(Color.Green); // 正确，编辑器会提供 Red, Green, Blue 的自动补全
// paint(3); // 错误！Argument of type '3' is not assignable to parameter of type 'ColorValue'.
```

然后在`eslint`里禁用掉枚举特性

```javascript
// .eslintrc.js
module.exports = {
  root: true,
  parser: "@typescript-eslint/parser", // 指定 ESLint 解析器
  plugins: [
    "@typescript-eslint/eslint-plugin", // 指定 ESLint 插件
  ],
  extends: [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended", // 使用推荐的 TypeScript 规则
  ],
  rules: {
    // ↓↓↓ 这是禁用 enum 的关键规则 ↓↓↓
    "no-restricted-syntax": [
      "error", // 将此规则设为错误级别
      {
        selector: "TSEnumDeclaration",
        message:
          "Do not use enums. Use plain objects with 'as const' instead. It's more tree-shakeable and compatible with native Node.js ESM.",
      },
    ],
  },
};
```

> 也可以如法炮制其他的禁用功能 selector 可以在https://astexplorer.net/找到对应的节点
