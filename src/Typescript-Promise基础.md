# [Promise 文档](https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Global_Objects/Promise)

> Promise 对象表示异步操作最终的完成（或失败）以及其结果值

从函子的角度对 Promise 做一下构建

首先构造一个常规的容器

```typescript
class Option<T> {
  private value: T | null;

  private constructor(value: T | null) {
    //思考:如果是异步赋值应该如何处理?
    this.value = value;
  }

  static some<T>(value: T | Option<T>): Option<T> {
    if (value instanceof Option) {
      return value;
    }
    return new Option(value);
  }

  map<U>(fn: (value: T) => U): Option<U> {
    return this.value === null ? Option.none<U>() : Option.some(fn(this.value));
  }

  flatMap<U>(fn: (value: T) => Option<U>): Option<U> {
    return this.value === null ? Option.none<U>() : fn(this.value);
  }
}
```

实现 `map` 包装任意值并且返回自身构造一个自函子

```Typescript
// 拍平结构 Some(1)
const option = Option.some(Option.some(1));
// 链式调用
const add1 = (value: number) => value + 1;
const add2 = (value: number) => value + 2;
const multiply = (value: number) => value * 2;
const result = option.map(add1).map(add2).map(multiply);
// Some(8)
```

`Option`有两个状态,`Some`和`None`

`Promise`可以模仿这个结构,但是我们遇到的问题是取值是异步的,并且可能失败

即上文`Option`的`construct`是一个异步状态

那么我们只能传一个回调`resolve`来处理结果 来实现拿到值之后再进行计算


对称的我们需要一个`reject`来处理失败的状态

按照规范`Promise`有三个状态

```typescript
const PROMISE_STATUS = {
  PENDING: "pending",
  FULFILLED: "fulfilled",
  REJECTED: "rejected",
} as const;

type PromiseStatus = (typeof PROMISE_STATUS)[keyof typeof PROMISE_STATUS];
```

初始值为`pending` 只能扭转一次

- 成功之后扭转为`fulfilled`执行`resolve`
- 失败之后扭转为`rejected`执行`reject`

```typescript
resolve(value: T) {
    this.status = PROMISE_STATUS.FULFILLED;
    this.value = value;
}

reject(reason: string) {
    this.status = PROMISE_STATUS.REJECTED;
    this.reason = reason;
}
```

# Promise 实现

先看类型签名,在`Typescript`的`node_modules`文件下

可以看到`lib.*.promise.d.ts`的构造签名

```typescript
interface PromiseConstructor {
  new <T>(
    executor: (
      resolve: (value: T | PromiseLike<T>) => void,
      reject: (reason?: any) => void
    ) => void
  ): Promise<T>;
}
```

看`new`函数的签名可以知道,`Promise`的参数是一个立即执行函数`executor`

`executor`有两个参数,并返回一个`Promise<T>`

- `resolve` 接受一个返回值,可以是另一个 `Promise`
- `reject` 接受一个 `reason`

结合上面一部分`Promise`的状态扭转,完成第一版

```typescript
class MyPromise<T> {
  status: PromiseStatus = PROMISE_STATUS.PENDING;
  value: T | undefined;
  reason?: any;

  constructor(
    executor: (
      resolve: (value: T) => void,
      reject: (reason: any) => void
    ) => void
  ) {
    const resolve = (value: T) => {
      if (this.status === PROMISE_STATUS.PENDING) {
        this.status = PROMISE_STATUS.FULFILLED;
        this.value = value;
      }
    };

    const reject = (reason: any) => {
      if (this.status === PROMISE_STATUS.PENDING) {
        this.status = PROMISE_STATUS.REJECTED;
        this.reason = reason;
      }
    };

    try {
      executor(resolve, reject);
    } catch (error) {
      reject(error);
    }
  }
}
```

继续查看`Promise`的接口定义

```Typescript
interface Promise<T> {
  then<TResult1 = T, TResult2 = never>(
    onfulfilled?: ((value: T) => TResult1 | PromiseLike<TResult1>) | undefined | null,
    onrejected?: ((reason: any) => TResult2 | PromiseLike<TResult2>) | undefined | null,
  ): Promise<TResult1 | TResult2>;
}
```

`then`接受`onfulfilled`函数和`onrejected`函数 返回一个 `Promise<T>`

`catch`接受`onrejected`函数返回一个`Promise<T>`

## `then`的异步执行

```typescript
const promise = new Promise((resolve) => {
  setTimeout(() => {
    resolve(1);
  }, 1000);
});

promise.then((x) => console.log(x));
```

`then`里回调函数需要等`resolve`调用之后才执行

## `then`的链式调用

```typescript
const promise = new Promise((resolve) => {
  setTimeout(() => resolve(1), 1000);
});

promise
  .then((x) => x + 1)
  .then((x) => x * 2)
  .then(console.log);
```

链式调用的多个`then` 每个 `then` 都会返回一个新的`Promise`

每个`Promise`都要等前一个`Promise`的状态改变才能执行

所以还需要有一个队列来放置这些回调函数

对称的有`onFulfilledCallbacks`和`onRejectedCallbacks`

## 自返回结构

`then`里还可以返回`Promise`

```typescript
Promise.resolve(1)
  .then((x) => {
    return Promise.resolve(x + 1); // 返回一个新的Promise
  })
  .then((x) => console.log(x)); // 2

Promise.resolve(1)
  .then((x) => Promise.resolve(x + 1)) // 返回Promise<number>
  .then((x) => x + 1) // 自动解包，x是number类型
  .then(console.log); // 3
```

实际应用场景,根据上一步的结果拉取下一个结构

```typescript
// 模拟API调用
function fetchUser(id: number) {
  return Promise.resolve({ id, name: "John" });
}

function fetchUserPosts(userId: number) {
  return Promise.resolve([
    { id: 1, title: "Post 1" },
    { id: 2, title: "Post 2" },
  ]);
}

// 链式调用
fetchUser(1)
  .then((user) => {
    return fetchUserPosts(user.id); // 返回新的Promise
  })
  .then((posts) => console.log(posts));
```

我们编写一个`resolvePromise`来处理解包的情况

一共三个特例

- `Promise`返回自己,构成循环调用 直接报错
- 返回`PromiseLike`的方法,继续调用返回值的`then`方法 直到变成值为止
- 非`PromiseLike`,直接返回值

代码如下

```typescript
function resolvePromise<T>(
  promise2: MyPromise<T>,
  x: any,
  resolve: (value: T) => void,
  reject: (reason: any) => void
) {
  // 1. 如果 promise2 和 x 相同，抛出 TypeError
  if (promise2 === x) {
    return reject(new TypeError("Chaining cycle detected for promise"));
  }

  // 标记是否已调用，防止多次调用
  let called = false;

  // 2. 如果 x 是 HYPromise 实例
  if (x instanceof MyPromise) {
    // 根据 x 的状态调用 resolve 或 reject
    x.then(
      (y) => {
        resolvePromise(promise2, y, resolve, reject);
      },
      (reason) => {
        reject(reason);
      }
    );
  } else if (x !== null && (typeof x === "object" || typeof x === "function")) {
    // 3. PromiseLike
    try {
      // 获取 x 的 then 方法
      const then = x.then as MyPromise<T>["then"];
      if (typeof then === "function") {
        // 如果 then 是函数
        // 使用 x 作为上下文调用 then 方法
        then.call(
          x,
          (y) => {
            // 成功回调
            if (called) return; // 如果已经调用过，直接返回
            called = true;
            // 递归处理 y
            resolvePromise(promise2, y, resolve, reject);
          },
          (reason) => {
            // 失败回调
            if (called) return; // 如果已经调用过，直接返回
            called = true;
            reject(reason);
          }
        );
      } else {
        // 如果 then 不是函数
        // 直接调用 resolve
        resolve(x);
      }
    } catch (error) {
      // 如果获取或调用 then 方法抛出异常
      if (called) return; // 如果已经调用过，直接返回
      called = true;
      reject(error);
    }
  } else {
    // 4. 如果 x 不是对象或函数
    // 直接调用 resolve
    resolve(x);
  }
}
```

然后就可以完善 `then` 方法了

```typescript

  then(onFulfilled: (value?: T) => void, onRejected: (reason: any) => void) {
    onFulfilled = typeof onFulfilled === 'function' ? onFulfilled : value => value;
    // prettier-ignore
    onRejected = typeof onRejected === 'function' ? onRejected : reason => { throw reason; };

    const promise2 = new MyPromise((resolve, reject) => {
      switch (this.status) {
        case PROMISE_STATUS.FULFILLED: {
          setTimeout(() => {
            try {
              const x = onFulfilled(this.value);
              resolvePromise(promise2, x, resolve, reject);
            } catch (error) {
              onRejected(error);
            }
          });
          break;
        }
        case PROMISE_STATUS.REJECTED:
          setTimeout(() => {
            try {
              const x = onRejected(this.reason);
              resolvePromise(promise2, x, resolve, reject);
            } catch (error) {
              reject(error);
            }
          });
          break;
        case PROMISE_STATUS.PENDING: {
          this.onFulfilledCallbacks.push(() => {
            setTimeout(() => {
              try {
                const x = onFulfilled(this.value);
                resolvePromise(promise2, x, resolve, reject);
              } catch (error) {
                reject(error);
              }
            });
          });
          this.onRejectedCallbacks.push(() => {
            setTimeout(() => {
              try {
                const x = onRejected(this.reason);
                resolvePromise(promise2, x, resolve, reject);
              } catch (error) {
                reject(error);
              }
            });
          });
          break;
        }
      }
    });

    return promise2;
  }

```

# 验证实现

[规范](https://github.com/promises-aplus/promises-spec)

[测试用例](https://github.com/promises-aplus/promises-tests)

```typescript
import { createRequire } from "module";
import MyPromise from "./myPromise.ts";

const require = createRequire(import.meta.url);
const promisesAplusTests = require("promises-aplus-tests");

const adapter = {
  resolved: (value: any) => MyPromise.resolve(value),
  rejected: (reason: any) => MyPromise.reject(reason),
  deferred: () => {
    let resolve: (value: any) => void;
    let reject: (reason: any) => void;
    const promise = new MyPromise(
      (res: (value: any) => void, rej: (reason: any) => void) => {
        resolve = res;
        reject = rej;
      }
    );
    return {
      promise,
      resolve: resolve!,
      reject: reject!,
    };
  },
};

promisesAplusTests(adapter, function (err: any) {
  if (err) {
    console.error("测试失败:", err);
    process.exit(1);
  }
  console.log("所有测试通过！");
});
```
