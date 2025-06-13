# 模块划分

入口是`lib/router.js`

`lib`文件夹下有`router.js`和`layer.js`两个文件,`layer`被`router`引用

依赖非常少,仅仅依赖 `http-errors`,`koa-compose`,`path-to-regexp` 三个包

`koa-compose`在`koa`的阅读里有介绍过

`path-to-regexp`是一个用来处理路由上的动态参数的辅助库

```javascript
const fn = match("/:foo/:bar");

fn("/test/route");
//=> { path: '/test/route', params: { foo: 'test', bar: 'route' } }
```

# Layer

```typescript
        constructor(
            path: string | RegExp,
            methods: string[],
            middleware: Router.IMiddleware,
            opts?: ILayerOptions
        );
```

`Layer` 接受三个参数

`methods` 是支持的 `HTTP` 方法数组

```javascript
for (const method of methods) {
  const l = this.methods.push(method.toUpperCase());
  if (this.methods[l - 1] === "GET") this.methods.unshift("HEAD");
}
```

- 自动将方法名转换为大写形式（如 'get' -> 'GET'）
- 当添加 `GET` 方法时，自动在方法列表开头添加 `HEAD` 方法，符合 `HTTP` 规范

然后使用`path-to-regexp`提供的方法将路由转换为对应的正则表达式,接着提供一些便捷的操作方法

- `match(path)`: 检查路径是否匹配
- `params(path, captures, params)`: 解析 URL 参数
- `captures(path)`: 获取正则匹配的捕获组
- `url(params, options)`: 生成 URL
- `param(param, fn)`: 添加参数中间件
- `setPrefix(prefix)`: 设置路由前缀

# Router

## constructor

除了常规的值初始化以外,这里有个工厂模式的优化,比较有意思的可以学习一下:

```javascript
if (!(this instanceof Router)) return new Router(opts);
```

- 如果直接调用 `Router()`，会自动返回 `new Router()` 的实例
- 如果使用 `new Router()`，则正常创建实例

## use

查看一下`use`的类型

```typescript
    use(...middleware: Array<Router.IMiddleware<StateT, CustomT>>): Router<StateT, CustomT>;
    use(
        path: string | string[] | RegExp,
        ...middleware: Array<Router.IMiddleware<StateT, CustomT>>
    ): Router<StateT, CustomT>;
```

接受中间件,也接受`path`+中间件的处理

```javascript
if (Array.isArray(middleware[0]) && typeof middleware[0][0] === "string") {
  const arrPaths = middleware[0];
  for (const p of arrPaths) {
    router.use.apply(router, [p, ...middleware.slice(1)]);
  }

  return this;
}
```

如果是`string[]`的 path 会被重新绑定

```javascript
// 这样调用
router.use(["/path1", "/path2"], middleware1, middleware2);

// 会被转换成
router.use("/path1", middleware1, middleware2);
router.use("/path2", middleware1, middleware2);
```

然后通过判断把路由和中间件分离开

```javascript
const hasPath = typeof middleware[0] === "string";
if (hasPath) path = middleware.shift();
```

判断`m.router`是为了处理路由嵌套的场景,重新绑定参数

父路由的`path`在子路由以`prefix`的形式去实现

```javascript
  const router = new Router();
  const subRouter = new Router();

  subRouter.get('/users', ...);
  router.use('/api', subRouter.routes());
```

## middleware

`middleware()` 方法是路由的核心,返回一个中间件

---

```javascript
const path =
  router.opts.routerPath || ctx.newRouterPath || ctx.path || ctx.routerPath;
//对于请求直接匹配对应方法的路由
const matched = router.match(path, ctx.method);
//如果没匹配到直接执行下一个中间件
if (!matched.route) return next();
```

```javascript
//如果匹配到对应的路由
const layerChain = (
  router.exclusive ? [mostSpecificLayer] : matchedLayers
).reduce((memo, layer) => {
  // 第一步：添加参数处理中间件
  memo.push((ctx, next) => {
    // 提取路径参数
    ctx.captures = layer.captures(path, ctx.captures);
    // 设置到 ctx.params
    ctx.request.params = layer.params(path, ctx.captures, ctx.params);
    // 设置路由信息
    ctx.params = ctx.request.params;
    ctx.routerPath = layer.path;
    ctx.routerName = layer.name;
    ctx._matchedRoute = layer.path;
    if (layer.name) {
      ctx._matchedRouteName = layer.name;
    }

    return next();
  });
  return [...memo, ...layer.stack];
}, []);

return compose(layerChain)(ctx, next);
```

```javascript
// 假设有这样的路由
router.get("/users/:id", async (ctx, next) => {
  ctx.body = await getUser(ctx.params.id);
});

// 最终 layerChain 会是：
[
  // 参数处理中间件
  (ctx, next) => {
    ctx.params = { id: "123" }; // 假设路径是 /users/123
    return next();
  },
  // 路由处理中间件
  async (ctx, next) => {
    ctx.body = await getUser(ctx.params.id);
  },
];
```

嵌套的例子:

```javascript
// 父路由
const router = new Router();
// 子路由
const subRouter = new Router();

// 子路由定义
subRouter.get("/users/:id", async (ctx, next) => {
  console.log("子路由处理");
  ctx.body = await getUser(ctx.params.id);
});

// 父路由使用子路由
router.use("/api", subRouter.routes());

// 当请求 /api/users/123 时，layerChain 会是：
[
  // 父路由的参数处理中间件
  (ctx, next) => {
    ctx.params = {};
    ctx.routerPath = "/api";
    return next();
  },
  // 子路由的参数处理中间件
  (ctx, next) => {
    ctx.params = { id: "123" };
    ctx.routerPath = "/api/users/:id";
    return next();
  },
  // 子路由的处理中间件
  async (ctx, next) => {
    console.log("子路由处理");
    ctx.body = await getUser(ctx.params.id);
  },
];
```

# HTTP 方法

就是对`register`的包装

```javascript
for (const method of methods) {
  Router.prototype[method] = function (name, path, middleware) {
    this.register(path, [method], middleware, { name });
    return this;
  };
}

// 提供delete的别名 del
Router.prototype.del = Router.prototype["delete"];
```
