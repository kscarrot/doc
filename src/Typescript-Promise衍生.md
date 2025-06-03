# 其他方法

| 方法               | 规范   | 引入时间 |
| ------------------ | ------ | -------- |
| Promise.catch      | ES6    | 2015     |
| Promise.finally    | ES2018 | 2018     |
| Promise.all        | ES6    | 2015     |
| Promise.race       | ES6    | 2015     |
| Promise.allSettled | ES2020 | 2020     |
| Promise.any        | ES2021 | 2021     |

## catch

> 此方法是 Promise.prototype.then(undefined, onRejected) 的一种简写形式

```typescript
export function catch_<T>(
  promise: Promise<T>,
  onRejected: (reason: any) => any
): Promise<T> {
  return promise.then(undefined, onRejected);
}
```

错误处理的坑点

```typescript
const p2 = new Promise((resolve, reject) => {
  setTimeout(() => {
    // 错误在setTimeout的回调中抛出
    throw new Error("未捕获的异常！");
  }, 1000);
});
```

正确的方式

```typescript
// 方式1：在setTimeout中调用reject
const p2 = new Promise((resolve, reject) => {
  setTimeout(() => {
    // 使用reject
    reject(new Error("这个错误可以被捕获"));
  }, 1000);
});

// 方式2：使用try-catch包装异步操作
const p2 = new Promise(async (resolve, reject) => {
  try {
    await new Promise((r) => setTimeout(r, 1000));
    throw new Error("错误");
  } catch (error) {
    reject(error);
  }
});
```

## finally

无论成功或者失败都会调用的函数

```typescript
  finally(callback) {
    // 调用then方法，传入两个相同的处理函数
    return this.then(
      value => {
        // 创建一个新的Promise实例，确保异步执行callback
        return MYPromise.resolve(callback()).then(() => value);
      },
      reason => {
        // 创建一个新的Promise实例，确保异步执行callback
        return MYPromise.resolve(callback()).then(() => { throw reason; });
      }
    );
  }
```

## all

用一个数组来记录返回结果

等队列里所有的`Promise`执行成功返回`Promise<T[]>`

```typescript
export function all<T>(promises: Promise<T>[]): Promise<T[]> {
  return new Promise((resolve, reject) => {
    const results: T[] = [];
    let completedCount = 0;

    // 如果传入空数组，直接返回空数组
    if (promises.length === 0) {
      resolve(results);
      return;
    }

    promises.forEach((promise, index) => {
      Promise.resolve(promise).then(
        (value) => {
          results[index] = value;
          completedCount++;

          // 当所有promise都完成时，返回结果数组
          if (completedCount === promises.length) {
            resolve(results);
          }
        },
        (reason) => {
          // 任何一个promise失败，立即reject
          reject(reason);
        }
      );
    });
  });
}
```

## allSettled

返回类型是

```typescript
type AllSettled = Promise<
  Array<{ status: "fulfilled" | "rejected"; value?: T; reason?: any }>
>;
```

```typescript
export function allSettled<T>(
  promises: Promise<T>[]
): Promise<PromiseSettledResult<T>[]> {
  return new Promise((resolve) => {
    const results: PromiseSettledResult<T>[] = [];
    let completedCount = 0;

    // 如果传入空数组，直接返回空数组
    if (promises.length === 0) {
      resolve(results);
      return;
    }

    promises.forEach((promise, index) => {
      Promise.resolve(promise).then(
        (value) => {
          results[index] = { status: "fulfilled", value };
          completedCount++;

          // 当所有promise都完成时，返回结果数组
          if (completedCount === promises.length) {
            resolve(results);
          }
        },
        (reason) => {
          results[index] = { status: "rejected", reason };
          completedCount++;

          // 当所有promise都完成时，返回结果数组
          if (completedCount === promises.length) {
            resolve(results);
          }
        }
      );
    });
  });
}
```

和`all`的区别是,`all`中有一个结果`reject`之后就会`reject`不走`then`逻辑

`allSettled`独立返回每一个的状态

## race

```typescript
export function race<T>(promises: Promise<T>[]): Promise<T> {
  return new Promise((resolve, reject) => {
    // 如果传入空数组，返回一个永远pending的promise
    if (promises.length === 0) {
      return;
    }

    // 外层的状态只能变更一次,所有promise执行resolve或reject,速度快的执行
    promises.forEach((promise) => {
      Promise.resolve(promise).then(resolve, reject);
    });
  });
}
```

## any

```typescript
export function any<T>(promises: Promise<T>[]): Promise<T> {
  return new Promise((resolve, reject) => {
    // 如果传入空数组，返回一个永远pending的promise
    if (promises.length === 0) {
      return;
    }

    const errors: any[] = [];
    let completedCount = 0;

    promises.forEach((promise, index) => {
      Promise.resolve(promise).then(
        (value) => {
          // 任何一个promise成功就立即resolve
          resolve(value);
        },
        (reason) => {
          errors[index] = reason;
          completedCount++;

          // 当所有promise都失败时，才reject
          if (completedCount === promises.length) {
            reject(new Error("All promises were rejected"));
          }
        }
      );
    });
  });
}
```

与`race`的异同:

`any`返回第一个成功的`Promise`
`race`返回第一个`Promise`

```typescript
// 例子1：race 的情况
const p1 = new Promise((resolve) => setTimeout(() => resolve("p1成功"), 1000));
const p2 = new Promise((_, reject) => setTimeout(() => reject("p2失败"), 500));

Promise.race([p1, p2])
  .then((result) => console.log("race结果:", result))
  .catch((error) => console.log("race错误:", error));
// 输出: race错误: p2失败
// 因为 p2 虽然失败了，但是最先完成，所以 race 返回 p2 的错误

// 例子2：any 的情况
Promise.any([p1, p2])
  .then((result) => console.log("any结果:", result))
  .catch((error) => console.log("any错误:", error));
// 输出: any结果: p1成功
// 因为 any 会等待第一个成功的 Promise，所以返回 p1 的结果
```

使用场景：
`race` 适用于：需要获取最快响应的场景，比如设置超时
`any` 适用于：需要获取第一个成功结果的场景，比如尝试多个备选方案

## 并发控制

```typescript
export function concurrent<T>(
  tasks: (() => Promise<T>)[],
  limit: number
): Promise<T[]> {
  return new Promise((resolve, reject) => {
    if (tasks.length === 0) {
      resolve([]);
      return;
    }

    const results: T[] = [];
    let running = 0;
    let completed = 0;
    let index = 0;

    function runTask() {
      if (index >= tasks.length) {
        return;
      }

      const currentIndex = index++;
      running++;

      tasks[currentIndex]()
        .then((result) => {
          results[currentIndex] = result;
        })
        .catch(reject)
        .finally(() => {
          running--;
          completed++;

          if (completed === tasks.length) {
            resolve(results);
          } else {
            runTask();
          }
        });
    }

    // 启动初始的并发任务
    for (let i = 0; i < Math.min(limit, tasks.length); i++) {
      runTask();
    }
  });
}
```

这里实现是封装了一个`runTask`

初始化时执行`limit`次`runTask`

`runTask`的`finally`里判断

- 如果任务队列全部执行完了调用`resolve`
- 否则调用`runTask`按顺序队列中待执行的请求
