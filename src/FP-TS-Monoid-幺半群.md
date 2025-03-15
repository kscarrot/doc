---
tags:
  - 函数式
  - 抽象代数
---


在上一章半群里,我们看到了`Semigroup`是如何解决合并值这样一个工作的.幺半群是半群的一个特例,它有一个特别的值对于`concat`是没有影响的,也被称为幺元.

## 类型定义
像往常一样,在`fp-ts`里,Monod被放在`fp-ts/lib/Monoid`模块中,它也被实现成了一个Ts的接口,其中幺元,我们命名为`empty`

```typescript
import { Semigroup } from 'fp-ts/lib/Semigroup'

interface Monoid<A> extends Semigroup<A> {
  readonly empty: A
}
```
遵循单位元规则:
* `concat(x,empty) = concat(empty,x) = x`
即对一个值做concat空的操作,不会改变这个值.
特别的,如果幺元存在,那么幺元一定是独一无二的.

## 实例
我们看到的大多数半群实际上都是幺半群

```typescript
/** number `Monoid` under addition */
const monoidSum: Monoid<number> = {
  concat: (x, y) => x + y,
  empty: 0
}

/** number `Monoid` under multiplication */
const monoidProduct: Monoid<number> = {
  concat: (x, y) => x * y,
  empty: 1
}

const monoidString: Monoid<string> = {
  concat: (x, y) => x + y,
  empty: ''
}

/** boolean monoid under conjunction */
const monoidAll: Monoid<boolean> = {
  concat: (x, y) => x && y,
  empty: true
}

/** boolean monoid under disjunction */
const monoidAny: Monoid<boolean> = {
  concat: (x, y) => x || y,
  empty: false
}
```
你可能觉得所有的半群可能都是幺半群.这里举出一个反例

```typescript
const semigroupSpace: Semigroup<string> = {
  concat: (x, y) => x + ' ' + y
}
```

让我们继续把幺半群应用到一些复杂的类型里面,就像之前的Point那样.

```typescript
import { getStructMonoid } from 'fp-ts/lib/Monoid'

const monoidPoint: Monoid<Point> = getStructMonoid({
  x: monoidSum,
  y: monoidSum
})

type Vector = {
  from: Point
  to: Point
}

const monoidVector: Monoid<Vector> = getStructMonoid({
  from: monoidPoint,
  to: monoidPoint
})
```

## Folding
当我们使用幺半群代替半群的时候,folding变的更简单了:我们不需要显式的提供一个初始值,这个初始值会被初始化为幺半群的幺元

```typescript
import { fold } from 'fp-ts/lib/Monoid'

fold(monoidSum)([1, 2, 3, 4]) // 10
fold(monoidProduct)([1, 2, 3, 4]) // 24
fold(monoidString)(['a', 'b', 'c']) // 'abc'
fold(monoidAll)([true, false, true]) // false
fold(monoidAny)([true, false, true]) // true
```

## 类型构造的幺半群
我们已经知道了半群是怎么作用在`Option<A>`上的.这里我们另外实现了`getFisrtMonoid`和`getLastMonoid`用来完成`concat`的工作

```typescript


import {getApplyMonoid
,getFirstMonoid
, getLastMonoid, some, none } from 'fp-ts/lib/Option'
const M1 = getApplyMonoid(monoidSum)

M1.concat(some(1), none) // none
M1.concat(some(1), some(2)) // some(3)
M1.concat(some(1), M1.empty) // some(1)


const M2 = getLastMonoid<number>()

M2.concat(some(1), none) // some(1)
M2.concat(some(1), some(2)) // some(2)

const M3 = getFirstMonoid<number>()

M3.concat(some(1), none) // some(1)
M3.concat(some(1), some(2)) // some(1)

```

下面给出一个更详细的例子,`getLastMonoid`通常可以让我们管理可选配置

```typescript
import { Monoid, getStructMonoid } from 'fp-ts/lib/Monoid'
import { Option, some, none, getLastMonoid } from 'fp-ts/lib/Option'

/** VSCode settings */
interface Settings {
  /** Controls the font family */
  fontFamily: Option<string>
  /** Controls the font size in pixels */
  fontSize: Option<number>
  /** Limit the width of the minimap to render at most a certain number of columns. */
  maxColumn: Option<number>
}

const monoidSettings: Monoid<Settings> = getStructMonoid({
  fontFamily: getLastMonoid<string>(),
  fontSize: getLastMonoid<number>(),
  maxColumn: getLastMonoid<number>()
})

const workspaceSettings: Settings = {
  fontFamily: some('Courier'),
  fontSize: none,
  maxColumn: some(80)
}

const userSettings: Settings = {
  fontFamily: some('Fira Code'),
  fontSize: some(12),
  maxColumn: none
}

/** userSettings overrides workspaceSettings */
monoidSettings.concat(workspaceSettings, userSettings)
/*
{ fontFamily: some("Fira Code"),
  fontSize: some(12),
  maxColumn: some(80) }
*/

```
