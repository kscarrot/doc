# curry

> curry 化的作用: 解放多参函数传参的使用限制

```typescript
// 调用的时候必须传两个参数
const add = (a: number, b: number) => a + b;
add(1, 2); // 3
// 转成高阶函数之后,我们可以通过闭包保留中间的过程,把参数配置化
const addCurry = (a: number) => (b: number) => a + b;
// 构建出两个相似的工具函数
const addTwo = addCurry(2);
const addFour = addCurry(4);
// 当然也可以直接调用
addCurry(1)(2); // 3
```

## 实现

利用函数的一个属性[Function.length](https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Global_Objects/Function/length)

核心就是文档第一句提到的:`Function` 实例的 `length` 数据属性表示函数**期望**的参数数量

最容易想到的实现是利用闭包存储传入的参数,直到传入的参数达到期望的参数数量然后调用

```typescript
type Args = any[];
const curry =
  (fn: Function, arr: Args = []) =>
  (...args: Args) => {
    if ([...arr, ...args].length === fn.length) {
      return fn(...arr, ...args);
    } else {
      return curry(fn, [...arr, ...args]);
    }
  };
```

这里有两个问题

### 1. curry 函数调用的泛型没有得到保留

如上述实现,参数通通变成了`any`

一种可行的解法是多写函数类型重载覆盖常见的场景,[参考文章](https://dev.to/francescoagati/optimizing-a-typescript-curry-function-from-static-types-to-variadic-types-2ma0)

```typescript
interface CurryFunction1<T1, R> {
  (arg1: T1): R;
}

interface CurryFunction2<T1, T2, R> {
  (arg1: T1): CurryFunction1<T2, R>;
}

interface CurryFunction3<T1, T2, T3, R> {
  (arg1: T1): CurryFunction2<T2, T3, R>;
}

function curry<T1, T2, R>(
  fn: (arg1: T1, arg2: T2) => R
): CurryFunction2<T1, T2, R>;
function curry<T1, T2, T3, R>(
  fn: (arg1: T1, arg2: T2, arg3: T3) => R
): CurryFunction3<T1, T2, T3, R>;
function curry(fn: Function) {
  return function curried(...args: any[]) {
    if (args.length >= fn.length) {
      return fn(...args);
    } else {
      return (...args2: any[]) => curried(...args, ...args2);
    }
  };
}
```

使用的时候可以正常推导出类型

```typescript
const clg = (str: string, count: number, isOK: boolean) => {};
const curriedClg = curry(clg);
//curriedClg: CurryFunction3<string, number, boolean, void>
```

观察一下可以直到手写的推导提示都是同一个模式

所以可以利用`infer`和类型的元组特性来做一个折叠

```typescript
type CurryFunction<T extends unknown[], R> = T extends [infer A, ...infer Rest]
  ? (arg: A) => CurryFunction<Rest, R>
  : R;

function curry<T extends unknown[], R>(
  fn: (...args: T) => R
): CurryFunction<T, R> {
  return function curried(...args: unknown[]): unknown {
    if (args.length >= fn.length) {
      return fn(...(args as T));
    } else {
      return (...args2: unknown[]) =>
        curried(...([...args, ...args2] as unknown[]));
    }
  } as CurryFunction<T, R>;
}
```

如果想要获得更多的推导,这里还有一篇介绍[Optimizing a TypeScript Curry Function](https://hackernoon.com/learn-advanced-typescript-4yl727e6)可供参考

### 2.占位参数的实现

```typescript
const addCurry = (a: number) => (b: number) => a + b;
// 因为参数在闭包中不是一个层级,隐含了顺序
// 但是传参是没有这个限制的
// 比如3参数想要配置化第二个参数最后传,那就要先占位

addCurry(_)(2)(1); // 通过占位先传b再传a
```

`ramda`仓库里还有[curryN](https://github.com/ramda/ramda/blob/v0.30.1/source/internal/_curryN.js)的实现

```javascript
/**
 * curryN 函数实现原理：
 * 1. 接收三个参数：
 *    - length: 目标函数的参数个数
 *    - received: 已经接收到的参数数组
 *    - fn: 要柯里化的原始函数
 *
 * 2. 返回一个新函数，这个函数可以：
 *    - 接收新的参数
 *    - 合并已接收的参数和新参数
 *    - 判断是否满足执行条件
 *    - 如果满足则执行原函数，否则继续返回新的柯里化函数
 */
export default function _curryN(length, received, fn) {
  return function () {
    // 用于存储最终合并的参数
    var combined = [];
    // 新传入参数的索引
    var argsIdx = 0;
    // 剩余需要填充的参数个数
    var left = length;
    // 合并后参数的索引
    var combinedIdx = 0;
    // 是否存在占位符
    var hasPlaceholder = false;

    // 遍历所有参数（已接收的 + 新传入的）
    while (combinedIdx < received.length || argsIdx < arguments.length) {
      var result;
      // 判断是否使用已接收的参数
      if (
        combinedIdx < received.length &&
        (!_isPlaceholder(received[combinedIdx]) || argsIdx >= arguments.length)
      ) {
        // 如果已接收的参数不是占位符，或者新参数已经用完，使用已接收的参数
        result = received[combinedIdx];
      } else {
        // 否则使用新传入的参数
        result = arguments[argsIdx];
        argsIdx += 1;
      }

      // 将参数添加到合并数组中
      combined[combinedIdx] = result;

      // 如果不是占位符，减少剩余参数计数
      if (!_isPlaceholder(result)) {
        left -= 1;
      } else {
        // 如果存在占位符，标记一下
        hasPlaceholder = true;
      }
      combinedIdx += 1;
    }

    // 判断是否满足执行条件：
    // 1. 没有占位符
    // 2. 剩余参数个数小于等于0（即参数已经足够）
    return !hasPlaceholder && left <= 0
      ? fn.apply(this, combined) // 满足条件，执行原函数
      : _arity(Math.max(0, left), _curryN(length, combined, fn)); // 不满足条件，返回新的柯里化函数
  };
}

// 最后封装成curry
var curry = _curry1(function curry(fn) {
  return curryN(fn.length, fn);
});
```

## 部分调用`partial`

相比之下`Radash`的`partial`就实现的更加简便一遍,参考第一版的实现,但是只能按顺序预填充一个层级的参数

```typescript
type RemoveItemsInFront<
  TItems extends any[],
  TItemsToRemove extends any[]
> = TItems extends [...TItemsToRemove, ...infer TRest] ? TRest : TItems;

export const partial = <T extends any[], TA extends Partial<T>, R>(
  fn: (...args: T) => R,
  ...args: TA
) => {
  return (...rest: RemoveItemsInFront<T, TA>) =>
    fn(...([...args, ...rest] as T));
};
```

# `compose` 和 `pipe`

## compose

`compose` 是函数式编程中的一个重要概念，它允许我们将多个函数组合成一个新的函数

组合后的函数会**从右到左**依次执行，每个函数的输出会作为下一个函数的输入

也就是**结合**的概念

### 基本实现

```typescript
const compose = (...fns) => {
  if (fns.length === 0) {
    return (arg) => arg;
  }

  if (fns.length === 1) {
    return fns[0];
  }

  return fns.reduce(
    (a, b) =>
      (...args) =>
        a(b(...args))
  );
};
```

`Radash`的实现,注意函数的执行顺序,参考上面`a(b(...args))`的包裹

需要用一下`reverse`方法,保证最右的最先执行

```typescript
function compose(...funcs: ((...args: any[]) => any)[]) {
  return funcs.reverse().reduce((acc, fn) => fn(acc));
}
```

## pipe

`Radash`里叫做`chain`

```typescript
export function chain(...funcs: ((...args: any[]) => any)[]) {
  return (...args: any[]) => {
    return funcs.slice(1).reduce((acc, fn) => fn(acc), funcs[0](...args));
  };
}
```

函数**从左至右**依次链式执行

可以看做参数被函数处理之后变成新的参数传给下一个函数

语言规范里有[管道操作符](https://github.com/tc39/proposal-pipeline-operator)的提案,目前是`stage-2`

看`fsharp`的官方文档可以很清楚了解他们的差别

```fsharp
// Function composition and pipeline operators compared.

let addOne x = x + 1
let timesTwo x = 2 * x

// Composition operator
// ( >> ) : ('T1 -> 'T2) -> ('T2 -> 'T3) -> 'T1 -> 'T3
let Compose2 = addOne >> timesTwo

// Backward composition operator
// ( << ) : ('T2 -> 'T3) -> ('T1 -> 'T2) -> 'T1 -> 'T3
let Compose1 = addOne << timesTwo

// Result is 5
let result1 = Compose1 2

// Result is 6
let result2 = Compose2 2

// Pipelining
// Pipeline operator
// ( |> ) : 'T1 -> ('T1 -> 'U) -> 'U
let Pipeline2 x = addOne x |> timesTwo

// Backward pipeline operator
// ( <| ) : ('T -> 'U) -> 'T -> 'U
let Pipeline1 x = addOne <| timesTwo x

// Result is 5
let result3 = Pipeline1 2

// Result is 6
let result4 = Pipeline2 2
```

## 小结

- 单参包裹多次然后重复调用就可以考虑用`compose`组合功能了
- 参数需要经过多个步骤返回最终的结果,可以使用`pipe`提高可读性
