---
tags:
  - 函数式
---



既然函子对多参数的支持不够好,那么就要想办法绕过多参数.

## Currying
首先我们看看这个签名,然后将其柯里化:
```typescript
g: (args: [B, C]) => D

//currying
g: (b: B) => (c: C) => D
```
现在我们解决了多个参数的问题,但是需要重写一个lift函数

```typescript
liftA2(g): (fb: F<B>) => (fc: F<C>) => F<D>

lift(g): (fb: F<B>) => F<(c: C) => D>
```
事实上,lift2对`F<(c: C) => D>`做了一个拆包,转化成了`(fc: F<C>) => F<D>`

## Apply
展示一下Apply的签名,ap就是拆包操作

```typescript
interface Apply<F> extends Functor<F> {
  ap: <C, D>(fcd: HKT<F, (c: C) => D>, fc: HKT<F, C>) => HKT<F, D>
}

interface Applicative<F> extends Apply<F> {
  of: <A>(a: A) => HKT<F, A>
}
```

下面是一些用例:

* *Example* (F = Array)
```typescript
import { flatten } from 'fp-ts/lib/Array'

const applicativeArray = {
  map: <A, B>(fa: Array<A>, f: (a: A) => B): Array<B> => fa.map(f),
  of: <A>(a: A): Array<A> => [a],
  ap: <A, B>(fab: Array<(a: A) => B>, fa: Array<A>): Array<B> =>
    flatten(fab.map(f => fa.map(f)))
}
Ï
```

* *Example* (F = Option)
```typescript
import { Option, some, none, isNone } from 'fp-ts/lib/Option'

const applicativeOption = {
  map: <A, B>(fa: Option<A>, f: (a: A) => B): Option<B> =>
    isNone(fa) ? none : some(f(fa.value)),
  of: <A>(a: A): Option<A> => some(a),
  ap: <A, B>(fab: Option<(a: A) => B>, fa: Option<A>): Option<B> =>
    isNone(fab) ? none : applicativeOption.map(fa, fab.value)
}
```

* *Example* (F = Task)
```typescript
import { Task } from 'fp-ts/lib/Task'

const applicativeTask = {
  map: <A, B>(fa: Task<A>, f: (a: A) => B): Task<B> => () => fa().then(f),
  of: <A>(a: A): Task<A> => () => Promise.resolve(a),
  ap: <A, B>(fab: Task<(a: A) => B>, fa: Task<A>): Task<B> => () =>
    Promise.all([fab(), fa()]).then(([f, a]) => f(a))
}
```

## Lifting
所以对于两个参数我们重写了lift,3个参数也可以支持

```typescript
import { HKT } from 'fp-ts/lib/HKT'
import { Apply } from 'fp-ts/lib/Apply'

type Curried2<B, C, D> = (b: B) => (c: C) => D

function liftA2<F>(
  F: Apply<F>
): <B, C, D>(g: Curried2<B, C, D>) => Curried2<HKT<F, B>, HKT<F, C>, HKT<F, D>> {
  return g => fb => fc => F.ap(F.map(fb, g), fc)
}


type Curried3<B, C, D, E> = (b: B) => (c: C) => (d: D) => E

function liftA3<F>(
  F: Apply<F>
): <B, C, D, E>(
  g: Curried3<B, C, D, E>
) => Curried3<HKT<F, B>, HKT<F, C>, HKT<F, D>, HKT<F, E>> {
  return g => fb => fc => fd => F.ap(F.ap(F.map(fb, g), fc), fd)
}
```

更多的参数也可以通过featch去实现