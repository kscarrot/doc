## base
```bash
git init
yarn init
tsc --init
yarn add typescript@latest
```

把`tsconfig.js`配置完成后,编写一个简单的ts文件,使用`tsc`编译测试一下,开发环境可以考虑生成map文件方便调试.通过`outDir`指定一个输出文件,然后把路径添加到`.gitignore`中.

## lint
[eslint-start-doc-here](https://github.com/typescript-eslint/typescript-eslint/blob/master/docs/getting-started/linting/README.md)

```bash
yarn add -D eslint typescript @typescript-eslint/parser @typescript-eslint/eslint-plugin
```
并按照文档编写`.eslintrc`文件
```json
{
  "root": true,
  "parser": "@typescript-eslint/parser",
  "plugins": ["@typescript-eslint"],
  "extends": [ "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
],
  "parserOptions": {
    "project": "./tsconfig.json"
  },
}

```
添加`.eslintignore`指定lint忽略的文件,然后测试eslint是否正常运行

  接着我们可以选择一些通用的eslint规则来加强约束,这里使用了[standard](https://github.com/standard/eslint-config-standard-with-typescript#readme)规则,按照文档安装插件
```bash
yarn add --dev  eslint@7 eslint-plugin-promise@4 eslint-plugin-import@2 eslint-plugin-node@11 @typescript-eslint/eslint-plugin@4 eslint-config-standard-with-typescript
```
并更新`.eslintrc`文件,最后配置代码格式化工具,这里选择[prettier](https://github.com/prettier/eslint-config-prettier#readme).
```bash
yarn add --dev prettier eslint-config-prettier
```

最后的`.eslintrc`:
```json
{
  "root": true,
  "parser": "@typescript-eslint/parser",
  "plugins": ["@typescript-eslint","prettier"],
  "extends": ["standard-with-typescript", "prettier"],
  "parserOptions": {
    "project": "./tsconfig.json"
  },
  "rules": {
    "prettier/prettier": "error"
  }
}
```

装完后文件入口爆黄色波浪线,需要在vscode编辑器右下把eslint点开.

## debug
为了方便debug,编写`lanunch.json`,这里填写文件的相对路径方便直接调试当前的单个文件.用pre钩子执行ts文件的编译,并通过输出的map文件把断点还原到ts中.
```json
{
  // 使用 IntelliSense 了解相关属性。
  // 悬停以查看现有属性的描述。
  // 欲了解更多信息，请访问: https://go.microsoft.com/fwlink/?linkid=830387
  "version": "0.2.0",
  "configurations": [
    {
      "type": "node",
      "request": "launch",
      "name": "ts-debug",
      "skipFiles": ["<node_internals>/**"],
      "program": "${workspaceFolder}/${relativeFile}",
      //不使用热更新debug需要开启此选项 否则在debug之前需要执行一次 ts-debug-task-watch
      "preLaunchTask": "ts-debug-task",
      "outFiles": ["${workspaceFolder}/dist/**/*.js"]
    }
  ]
}
```

preLaunchTask里执行的`task.json`:

```json
{
  // 有关 tasks.json 格式的文档，请参见
  // https://go.microsoft.com/fwlink/?LinkId=733558
  "version": "2.0.0",
  "tasks": [
    {
      "label": "ts-debug-task",
      "type": "shell",
      "command": "rm -rf dist  && tsc -t \"es5\" --sourceMap --module \"commonjs\"",
      "group": "build"
    },
    {
      "label": "ts-debug-task-watch",
      "type": "shell",
      "command": "rm -rf dist  && tsc -t \"es5\" --sourceMap --module \"commonjs\" -w",
      "group": "build"
    }
  ]
}
```

顺便弄一下用户配置 `setting.json`,我需要,ts使用当前工作区的ts避免和全局的ts出现版本冲突,然后保存自动格式化.

```json
{
  "typescript.tsdk": "node_modules/typescript/lib",
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.formatOnSave": true
}
```


打断点调试一下example执行效果.

## test
最后添加单元测试jest
```bash
yarn add --dev jest  @types/jest  babel-jest @babel/core @babel/preset-env @babel/preset-typescript
```

配置一下转换的规则`.babelrc`
```json
{
  "presets": [["@babel/preset-env", { "targets": { "node": "current" } }], "@babel/preset-typescript"]
}

```
编写一个简单的单元测试执行,pass.

## spport
> todo git hooks -> husky

## ci
> todo:这里使用github action

## monorepo
> todo 后续开发,方便周边工具链使用