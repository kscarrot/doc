> 源码来自: https://github.com/sodiray/radash

# sleep

1. 返回一个`Promise`
2. `setTimout` 之后调用 `resolve`

```typescript
export const sleep = (milliseconds: number) => {
  return new Promise((res) => setTimeout(res, milliseconds));
};
```

# tryit

跟新规范中的`Promise.prototype.try`不太一样

看起来非常像`golang`的调用

稳定返回 `[err,value]`

下方示例代码剔除了类型推导会更易读一些

```typescript
export const tryit = (func) => {
  return (...args) => {
    try {
      const result = func(...args);
      if (isPromise(result)) {
        return result
          .then((value) => [undefined, value])
          .catch((err) => [err, undefined]);
      }
      return [undefined, result];
    } catch (err) {
      return [err, undefined];
    }
  };
};
```

# retry

1. 如果成功了直接返回 `result`
2. 如果失败了(包括失败调用主动退出/到达重试次数上限被动退出)
3. 在循环里`await` 等待 `sleep`执行`delay`

```typescript
export const retry = async <TResponse>(
  options: {
    times?: number;
    delay?: number | null;
    backoff?: (count: number) => number;
  },
  func: (exit: (err: any) => void) => Promise<TResponse>
): Promise<TResponse> => {
  const times = options?.times ?? 3;
  const delay = options?.delay;
  const backoff = options?.backoff ?? null;
  for (const i of range(1, times)) {
    const [err, result] = (await tryit(func)((err: any) => {
      throw { _exited: err };
    })) as [any, TResponse];
    if (!err) return result;
    if (err._exited) throw err._exited;
    if (i === times) throw err;
    if (delay) await sleep(delay);
    if (backoff) await sleep(backoff(i));
  }
  // Logically, we should never reach this
  // code path. It makes the function meet
  // strict mode requirements.
  /* istanbul ignore next */
  return undefined as unknown as TResponse;
};
```

# debounce

防抖,利用闭包保存一个 `timer`

- 延迟足够的时间没有被再次调用的时候才会真正执行函数
- 如果在延迟时间内再次触发,重置`timer` 重新开始计时

```typescript
export const debounce = <TArgs extends any[]>(
  { delay }: { delay: number },
  func: (...args: TArgs) => any
) => {
  let timer: NodeJS.Timeout | undefined = undefined;

  const debounced: DebounceFunction<TArgs> = (...args: TArgs) => {
    clearTimeout(timer);
    timer = setTimeout(() => {
      func(...args);
      timer = undefined;
    }, delay);
  };
  return debounced;
};
```

# throttle

节流,利用闭包保存一个 `timer`

- 调用一次后`ready`变成`false`
- 间隔`interval`后`ready`变成`true`
- 每次触发重置`timer`限制最小间隔

```typescript
export const throttle = <TArgs extends any[]>(
  { interval }: { interval: number },
  func: (...args: TArgs) => any
) => {
  let ready = true;
  let timer: NodeJS.Timeout | undefined = undefined;

  const throttled: ThrottledFunction<TArgs> = (...args: TArgs) => {
    if (!ready) return;
    func(...args);
    ready = false;
    timer = setTimeout(() => {
      ready = true;
      timer = undefined;
    }, interval);
  };
  return throttled;
};
```

# once

利用闭包 只调用一次,再次调用返回之前的结果

```typescript
export const once = <TArgs extends any[]>(func: (...args: TArgs) => any) => {
  let called = false;
  let result: any;

  const onceFunc = (...args: TArgs) => {
    if (called) return result;
    called = true;
    result = func(...args);
    return result;
  };

  return onceFunc;
};
```

# memo

利用闭包 保存一个结果缓存

- 调用时返回结果,并设置缓存和超时时间(ttl)
- 调用时判断缓存命中情况 命中了直接返回缓存结果 否则返回新的函数调用结果

```typescript
const memoize = <TArgs extends any[], TResult>(
  cache: Cache<TResult>,
  func: (...args: TArgs) => TResult,
  keyFunc: ((...args: TArgs) => string) | null,
  ttl: number | null
) => {
  return function callWithMemo(...args: any): TResult {
    const key = keyFunc ? keyFunc(...args) : JSON.stringify({ args });
    const existing = cache[key];
    if (existing !== undefined) {
      if (!existing.exp) return existing.value;
      if (existing.exp > new Date().getTime()) {
        return existing.value;
      }
    }
    const result = func(...args);
    cache[key] = {
      exp: ttl ? new Date().getTime() + ttl : null,
      value: result,
    };
    return result;
  };
};

export const memo = <TArgs extends any[], TResult>(
  func: (...args: TArgs) => TResult,
  options: {
    key?: (...args: TArgs) => string;
    ttl?: number;
  } = {}
) => {
  return memoize({}, func, options.key ?? null, options.ttl ?? null) as (
    ...args: TArgs
  ) => TResult;
};
```
