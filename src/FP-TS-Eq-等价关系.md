---
tags:
  - 函数式
  - 离散数学
---


翻译自[fp-ts-doc](https://dev.to/gcanti/getting-started-with-fp-ts-setoid-39f3),自己记录用,侵删.

  这个系列博客我想讨论一下关于"类型类"和"实例",让我们来看看在`fp-ts`中他们是什么样还有如何被描述的.

> "类型类"在维基百科上的解释:
>     程序员通过指定一组函数或常量名称以及它们各自的类型来定义类型类，这些函数或常量名称对于属于该类的每种类型都必须存在。

 在`fp-ts`中,类型系统用TypeScript描述为`interface S`
一个类型类`Eq`,旨在包含一个描述相等关系的类型,其定义方式如下:
```typescript
interface Eq<A> {
  /** returns `true` if `x` is equal to `y` */
  readonly equals: (x: A, y: A) => boolean
}
```

这个定义可以被解读为
> 如果一个 `A` 属于 类型类 `Eq`,那么就有一个被命名为`equal`的函数被定义在这个类型中
什么是实例?
> 程序员可以声明任意的`A`类型作为给定`C`类型的实例,通过在A中完成`C`类型中所有成员的实现.
在`fp-ts`中实例被描述成一个静态类型.
这里有一个`number`类型生成`Eq`实例的例子
```typescript
const eqNumber: Eq<number> = {
  equals: (x, y) => x === y
}
```

实例必须满足下面三个规则:
1. *自反性*: `equals(x,x) === true`对于`A`中的所有`x`成立
2. *交换性*:`equals(x, y) === equals(y, x)`对于`A`中所有`x`,`y`都成立
3. *传递性*: 对于`A`中的`x`,`y`,`z`如果`equals(x,y)===true`且
`equals(y, z) === true`,那么`equals(x, z) === true`

程序员可以通过下面的方式定义一个函数`elem`(这个命名代表他是集合中的一个元素):
```typescript
function elem<A>(E: Eq<A>): (a: A, as: Array<A>) => boolean {
  return (a, as) => as.some(item => E.equals(item, a))
}

elem(eqNumber)(1, [1, 2, 3]) // true
elem(eqNumber)(4, [1, 2, 3]) // false
```
现在我们可以编写一些更加复杂的`Eq`类型的实例:
```typescript
type Point = {
  x: number
  y: number
}

const eqPoint: Eq<Point> = {
  equals: (p1, p2) => p1.x === p2.x && p1.y === p2.y
}
```
我们也可以试着通过检查引用是否相等优化一下`equals`方法
```typescript
const eqPoint: Eq<Point> = {
  equals: (p1, p2) => p1 === p2 || (p1.x === p2.x && p1.y === p2.y)
}
```
这是一个非常常见的模板代码.好消息是,如果如果我们可以为每个字段提供一个`Eq`实例,那么我们就能对整个`Point`构建一个`Eq`实例.
事实上我们在`fp-ts/lit/Eq`中导出了一个`getEtructEq`的结合子:
```typescript
import { getStructEq } from 'fp-ts/lib/Eq'

const eqPoint: Eq<Point> = getStructEq({
  x: eqNumber,
  y: eqNumber
})
```
那么我们现在可以用过填充`getStructEq`来实现我们刚刚完成的定义
```typescript
type Vector = {
  from: Point
  to: Point
}

const eqVector: Eq<Vector> = getStructEq({
  from: eqPoint,
  to: eqPoint
})
```
`getStructEq`不是`fp-ts`中导出的唯一的结合子,这里还有一个结合子允许我们完成一个数组类型的`Eq`实例
```typescript
import { getEq } from 'fp-ts/lib/Array'
const eqArrayOfPoints: Eq<Array<Point>> = getEq(eqPoint)
```
最后还有一个更加通用的方法通过`contramap`这个结合子去构建一个`Eq`实例:给定一个`A`的`Eq`实例,和一个把`B`转化为`A`的函数,我们可以衍生出`B`的`Eq`实例
```typescript
import { contramap } from 'fp-ts/lib/Eq'

type User = {
  userId: number
  name: string
}

/** two users are equal if their `userId` field is equal */
const eqUser = contramap((user: User) => user.userId)(eqNumber)

eqUser.equals({ userId: 1, name: 'Giulio' }, { userId: 1, name: 'Giulio Canti' }) // true
eqUser.equals({ userId: 1, name: 'Giulio' }, { userId: 2, name: 'Giulio' }) // false
```