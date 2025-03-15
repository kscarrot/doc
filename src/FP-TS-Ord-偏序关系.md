---
tags:
  - 函数式
  - 离散数学
---



在上一篇有关`Eq`的文章中,我们讨论了相等的概念,在这篇博客,我们继续讨论排序的概念.
一个`Ord`类旨在通过声明一个总是允许排序类型的类型类,被描述为下面的方式:
```typescript
import { Eq } from 'fp-ts/lib/Eq'

type Ordering = -1 | 0 | 1

interface Ord<A> extends Eq<A> {
  readonly compare: (x: A, y: A) => Ordering
}
```
* x < y  compare 返回 -1
* x =y  compare 返回 0
* x > y compare 返回 1

下面是一个用number类型实例化`Ord`类的例子:
```typescript
const ordNumber: Ord<number> = {
  equals: (x, y) => x === y,
  compare: (x, y) => (x < y ? -1 : x > y ? 1 : 0)
}
```
实例必须满足下面三个规则:
1.*自反性*:`compare(x, x) === 0`,对于所有`A`中的`x`
2.*反对称性*:如果`compare(x, y) <= 0`且`compare(y, x) <= 0`,那么`equals (x,y) === true`,对于所有`A`中的`x`,`y`
3.*传递性*:如果 `compare(x, y) <= 0` 且 `compare(y, z) <= 0`那么`compare(x, z) <= 0`,对于所有`A`中的`x`,`y`

所以`compare`包含了 `Eq.equals`,即`compare(x,y) === 0` 和 `equails(x,y)===ture`是等价的.一个严格的`equal`能被`compare`用下面的方式推导出来

```typescript
equals: (x, y) => compare(x, y) === 0
```

事实上`fp-ts/lib/Ord`导出了一个`fromCompare`的辅助函数能够帮助你从简单的从偏序关系里推导出一个相等关系.

```typescript
import { Ord, fromCompare } from 'fp-ts/lib/Ord'

const ordNumber: Ord<number> = fromCompare((x, y) => (x < y ? -1 : x > y ? 1 : 0))
```

作为一个使用者能想下面这样定义一个min函数:
```typescript
function min<A>(O: Ord<A>): (x: A, y: A) => A {
  return (x, y) => (O.compare(x, y) === 1 ? y : x)
}

min(ordNumber)(2, 1) // 1
```

当我们在讨论数字的时候,这个例子看起来是非常显然的,不过并不总是这样,让我们考虑一些更加复杂的类型

```typescript
type User = {
  name: string
  age: number
}
```
我们应该如何定义一个关于User的偏序关系?
这取决于如何去定义,一种颗星的方式是用用户的年龄作为排序的依据

```typescript
const byAge: Ord<User> = fromCompare((x, y) => ordNumber.compare(x.age, y.age))
```
我们可以使用 `contramap`这个组合子去避免写太多的模板代码.`contramap`的作用是从一个对于A的Ord的实例,和一个将B转化为A的函数中推导出B的Ord的实例

```typescript
import { contramap } from 'fp-ts/lib/Ord'

const byAge: Ord<User> = contramap((user: User) => user.age)(ordNumber)
```

现在我们就能从两个user中使用`min`挑选出更年轻的那个
```typescript
const getYounger = min(byAge)

getYounger({ name: 'Guido', age: 48 }, { name: 'Giulio', age: 45 }) // { name: 'Giulio', age: 45 }
```

如果我们需要更年长的用户呢,理论上我们需要一个反向的偏序关系,用更理论的定义来面熟就是 `dual order`
幸运的是我们有另一个导出的组合子来做这件事:
```typescript
import { getDualOrd } from 'fp-ts/lib/Ord'

function max<A>(O: Ord<A>): (x: A, y: A) => A {
  return min(getDualOrd(O))
}

const getOlder = max(byAge)

getOlder({ name: 'Guido', age: 48 }, { name: 'Giulio', age: 45 }) // { name: 'Guido', age: 48 }
```