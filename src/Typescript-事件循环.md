## 事件循环

Js 是单线程的,在执行时,有些任务有 `pending` 的状态(`IO`,`request`)

这些任务不能立即完成,而执行栈又不能停下来等他,所以异步的任务会以事件的形式在完成后发起回调

事件的执行需要一定的顺序,通常以队列的形式按照先后顺次执行,这个过程一般被称为事件循环.

## 执行顺序

1. 执行同步代码,将异步任务加入队列
2. 从微任务队首开始执行队列,直至微任务队列清空
3. 若执行的过程中又产生了微任务,也会加入到队尾在本周期被执行完
4. 从宏任务队首开始执行一个任务,直至调用栈清空
5. 回到第 2 步完成一个循环

## 分类

### 宏任务

- setTimeout
- setInterval
- requestAnimationFrame
- requestIdleFrame
- I/O
- UI rendering (UI 的执行点在所有 microtask 之后,下一个 task 之前)

### 微任务

- Promise
- Object.observe
- MutatonObserver
- process.nextTick

## node

- 微任务队列 nextTick > other
- 宏任务队列 timer > io > check > close (soket)

[Nodejs Event Loop 文档](https://nodejs.org/en/learn/asynchronous-work/event-loop-timers-and-nexttick)

## 一些注意点

- 在执行异步任务前需要先清空调用栈,所以尾部的`log`一般都会先执行
- `Promise` 的构造函数是立即执行的,并且会执行完,所以在 `excute` 内,`resolve` 之后的内容也会先执行
- 一个 `Promise` 可能有多个`then`,按照调用顺序执行

## 实践

### `setTimeout` 和 `Promise` 的顺序

```typescript
consoleLog("start");

setTimeout(function () {
  consoleLog("setTimeout1");
}, 0);

new Promise((resolve) => {
  consoleLog("Promise1_execute");
  for (var i = 0; i < 10000; i++) {
    if (i === 10) {
      consoleLog("Promise1_loop_10");
    }
    i == 9999 && resolve(1);
  }
  // 即使调用了 resolve，函数体内的代码会继续执行直到函数结束
  consoleLog("Promise1_end");
}).then(function () {
  consoleLog("Promise1_then1");
});

consoleLog("end");
```

执行栈

```typescript
expect(consoleLog.mock.calls).toStrictEqual([
  ["start"],
  ["Promise1_execute"],
  ["Promise1_loop_10"],
  ["Promise1_end"],
  ["end"],
  ["Promise1_then1"],
  ["setTimeout1"],
]);
```

### `setTimeout`里嵌套`Promise`的情况

```typescript
consoleLog("start");

setTimeout(() => {
  consoleLog("setTimeout1");
  Promise.resolve().then(() => {
    consoleLog("setTimeout1_Promise1_then1");
  });
}, 0);

new Promise((resolve) => {
  consoleLog("Promise2_execute");
  setTimeout(() => {
    consoleLog("Promise2_setTimeout1");
    resolve("Promise2_resolve");
  }, 0);
}).then((res) => {
  consoleLog("Promise2_then1");
  setTimeout(() => {
    consoleLog("Promise2_then1_setTimeout1");
    consoleLog(res);
  }, 0);
});

consoleLog("end");
```

执行栈 执行异步顺序过程中新加的异步任务依然按照队列进行执行

```typescript
expect(consoleLog.mock.calls).toStrictEqual([
  ["start"],
  ["Promise2_execute"],
  ["end"],
  ["setTimeout1"],
  ["setTimeout1_Promise1_then1"],
  ["Promise2_setTimeout1"],
  ["Promise2_then1"],
  ["Promise2_then1_setTimeout1"],
  ["Promise2_resolve"],
]);
```

### `async` 和 `await` 嵌套的情况

`await` 相当于立即调用 `Promise`

`await`之后的内容要等当前 `Promise`执行完之后才会向下继续执行

可以用被`then`包裹去理解

```typescript
async function async1() {
  consoleLog("async1 start");
  await async2();
  consoleLog("async1 end");
}
async function async2() {
  consoleLog("async2");
}
consoleLog("script start");
setTimeout(() => {
  consoleLog("settimeout");
});
async1();
new Promise((resolve) => {
  consoleLog("promise1");
  resolve(0);
}).then(function () {
  consoleLog("promise2");
});
consoleLog("script end");
```

调用栈

```typescript
expect(consoleLog.mock.calls).toStrictEqual([
  ["script start"],
  ["async1 start"],
  ["async2"],
  ["promise1"],
  ["script end"],
  ["async1 end"],
  ["promise2"],
  ["settimeout"],
]);
```
