# 配置
## 全局配置与同步

## task

## launch

## snippets


# 插件

## ProjectManger
在侧边栏实现了多个项目的流程切换
`code ./workspace` 的图形化拓展实现
支持重命名,分组 配置文件结构简单 可以组内同步配置

## Code Spell Checker
避免拼写手滑弄出奇怪的单词 最后再返工改一堆变量的情况
对于特定缩写,可以在`setting.sjon`里`cSpell.words`搜集消除检查 比如`pinia` 
对领域词汇的沉淀会有所帮助

## Better Comments /TODO TREE

* 注释里的感叹号行首整行染红,TODO行首整行染黄 实用小功能

* TODO TREE 
在push之前自行review的时候可以避免漏掉实现 
比起全局搜TODO会更加友好


## i18n Ally
多语言的拯救者
给开发提供了单语言的组件还原体验
直接呈现指定语种的文本

## TS/JS postfix completion
后缀展开 比起 `alfred` 和 `vscode`的 `snippets` 会更加直观

最高频场景
1. `<expression>.if` `<expression>.not`

`response.data.if/` => `if(response.data){ / }` 展开并移动光标位置
`isValid.not` => `!isValid` 用语义替代光标移动

2. `<expression>.const` `<expression>.return`
`reqOption.const` =  `const = reqOption`
`response.data.return` =  `return response.data`

3. `<expression>.log`
调试的时候非常常用
和`alfred`相互配合 相性比较好
简单变量直接.log就行
复杂点多变量的可以用`alfred`的模板展开
清空剪贴板 移动光标复制要debug的变量
然后调用宏即可

```
console.log('clipboard1',clipboard1 )
console.log('clipboard2',clipboard2 )
```

## Polacode
部分配置逻辑需要分享给非coding的时候
使用图片分享可以比 code mirror 提供更好的高亮和样式 以及更加方便批注

## indent-rainbow
即使时缩进没那么重要的语言 
用起来也挺好的

## gitLens
git的拓展

## draw.io
简单易用的流程图绘制软件
原地绘图

## vscode-icons
会特殊标注常见文件的图标
比如把
`package.json` 从一堆`.json`文件中高亮出来
给 `typings` `utils` `router` `i18n` 等提供更好的文件夹样式展示
