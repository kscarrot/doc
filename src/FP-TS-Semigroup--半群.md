由于半群是函数式编程的基本的抽象类型,因此本文将会比平时更长.

## 一般定义
一个半群是定义一对`(A,*)`,其中`A`是一个非空结合,并且`*`是对`A`的一个关联运算,即`*`是一个函数,它接受两个`A`作为输入并返回元素`A`作为另一个输出.那么一个半群的性质即就有结合性.
`(x*y)*z = x*(y*z)`
这个性质可以告诉我们,再组合半群时可以不必担心括号的影响
> 半群抓住了可并行操作的本质
半群的例子很多:
* `(number,*) *` 作为数字乘法
* `(string,+) +` 作为字符串连接
* `(boolean,&&) &&`作为逻辑判断
等等...

## 类型类定义
与模块中包含`fp-ts`的其他类型类一样,通常将半群实现为一个 TypeScript的接口,其中操作`*`命名为`concat`
半群满足结合律:
`concat(concat(x,y),z) = concat(x,concat(y,z))`对于集合A中所有的x,y,z成立

concat对数组类型特别的有意义,但是在日常使用的实例类型中,还可以用`级联(concatenation)`,`合并(merge)`,`融合(fusion)`,`选择(selection)`,`相加(addition)`,`替换(substitution)`等等术语来进行描述

## 实例
下面是一个半群的具体实现:
```typescript
/** number `Semigroup` under multiplication */
const semigroupProduct: Semigroup<number> = {
  concat: (x, y) => x * y
}

const semigroupSum: Semigroup<number> = {
  concat: (x, y) => x + y
}
```


```typescript
const semigroupString: Semigroup<string> = {
  concat: (x, y) => x + y
}
```

如果给定一个类型`A`,但是A中没有实现concat方法该怎么办?我们可以使用下面的构造方法为给定类型创建一个简单的半群实例:
```typescript
/** Always return the first argument */
function getFirstSemigroup<A = never>(): Semigroup<A> {
  return { concat: (x, y) => x }
}

/** Always return the second argument */
function getLastSemigroup<A = never>(): Semigroup<A> {
  return { concat: (x, y) => y }
}
```

另一种方法是限定一个数组作为半群的泛型,并将单个的元素也映射成一个数组:
```typescript
function getArraySemigroup<A = never>(): Semigroup<Array<A>> {
  return { concat: (x, y) => x.concat(y) }
}

function of<A>(a: A): Array<A> {
  return [a]
}
```


## 从偏序关系中转化出半群
还有一种构造半群的方法:如果我们已经有一个Ord类型的实例,则可以通过一定的限制转化成一个半群:
```typescript
import { ordNumber } from 'fp-ts/lib/Ord'
import { getMeetSemigroup, getJoinSemigroup } from 'fp-ts/lib/Semigroup'

/** Takes the minimum of two values */
const semigroupMin: Semigroup<number> = getMeetSemigroup(ordNumber)

/** Takes the maximum of two values  */
const semigroupMax: Semigroup<number> = getJoinSemigroup(ordNumber)

semigroupMin.concat(2, 1) // 1
semigroupMax.concat(2, 1) // 2
```
接着我们编写一个类型更为复杂的实例:
```typescript
type Point = {
  x: number
  y: number
}

const semigroupPoint: Semigroup<Point> = {
  concat: (p1, p2) => ({
    x: semigroupSum.concat(p1.x, p2.x),
    y: semigroupSum.concat(p1.y, p2.y)
  })
}
```
看起来就像是一些模板代码.不过好消息是我们可以从半群结构中构造一个新的实例,就像为`Point`中每个字段提供了一个实例一样.
实际上`fp-ts/lib/Semigroup`模块导出了一个`getStrudctSemigroup`的组合子:
```typescript
import { getStructSemigroup } from 'fp-ts/lib/Semigroup'

const semigroupPoint: Semigroup<Point> = getStructSemigroup({
  x: semigroupSum,
  y: semigroupSum
})
```

我们可以继续用`getStrudctSemigroup`定义之前定义的实例:
```typescript
type Vector = {
  from: Point
  to: Point
}

const semigroupVector: Semigroup<Vector> = getStructSemigroup({
  from: semigroupPoint,
  to: semigroupPoint
})

```
`getStrudctSemigroup`不是唯一的一个的组合器,这里我们还提供了一个组合子,对于`A`有`(a:A)=>S`,那么我们可以从A推导出S的半群
```typescript
import { getFunctionSemigroup, Semigroup, semigroupAll } from 'fp-ts/lib/Semigroup'

/** `semigroupAll` is the boolean semigroup under conjunction */
const semigroupPredicate: Semigroup<(p: Point) => boolean> = getFunctionSemigroup(
  semigroupAll
)<Point>()
```
现在我们可以对Point进行合并
```typescript
const isPositiveX = (p: Point): boolean => p.x >= 0
const isPositiveY = (p: Point): boolean => p.y >= 0

const isPositiveXY = semigroupPredicate.concat(isPositiveX, isPositiveY)

isPositiveXY({ x: 1, y: 1 }) // true
isPositiveXY({ x: 1, y: -1 }) // false
isPositiveXY({ x: -1, y: 1 }) // false
isPositiveXY({ x: -1, y: -1 }) // false
```

## Folding
对于`concat`定义,我们仅仅只能组合两个元素,如果有更多的元素会怎么样呢?
这里我们实现了一个`fold`函数,他可以直接作用在一个数组中,将一个集合转换为一个元素:
```typescript
import { fold, semigroupSum, semigroupProduct } from 'fp-ts/lib/Semigroup'

const sum = fold(semigroupSum)

sum(0, [1, 2, 3, 4]) // 10

const product = fold(semigroupProduct)

product(1, [1, 2, 3, 4]) // 24

```

## 对于构造类型(type constructors)的半群
如果我们需要合并两个选择(`Option<A>`)类型,有下面一些情况
* none + none => none
* some(a) +none => none
* none + some(b) => none
* some(a)+some(b) =>  ???
对于最后一种条件的处理,我们碰到了一些麻烦,我们需要用某种方式将两个`some`"合并".
这正是半群所做的事情!我们能够使用半群的实例推导出Option<A>的半群.下面是如何使用`getApplySemigoup`这个组合子完成这件事:

```typescript
import { semigroupSum } from 'fp-ts/lib/Semigroup'
import { getApplySemigroup, some, none } from 'fp-ts/lib/Option'

const S = getApplySemigroup(semigroupSum)

S.concat(some(1), none) // none
S.concat(some(1), some(2)) // some(3)
```

## 附录
我们已经看到了半群是如何帮助我们完成"连接","合并","组合"等等这样一些工作把多个数据转化成一个.
我们把这些包装到最后的这个例子里进行展示:
让我们想想你正在运行的系统里,有某一个存储的客户的记录看起来像下面这样:

```typescript
interface Customer {
  name: string
  favouriteThings: Array<string>
  registeredAt: number // since epoch
  lastUpdatedAt: number // since epoch
  hasMadePurchase: boolean
}

```
不管出于什么样的理由,你最终都需要合并重复的记录,然后保留一个终值.我们需要合并这些记录.让我们看看半群是如何来完成这件事的


```typescript
const semigroupCustomer: Semigroup<Customer> = getStructSemigroup({
  // keep the longer name
  name: getJoinSemigroup(contramap((s: string) => s.length)(ordNumber)),
  // accumulate things
  favouriteThings: getMonoid<string>(), // <= getMonoid returns a Semigroup for `Array<string>` see later
  // keep the least recent date
  registeredAt: getMeetSemigroup(ordNumber),
  // keep the most recent date
  lastUpdatedAt: getJoinSemigroup(ordNumber),
  // Boolean semigroup under disjunction
  hasMadePurchase: semigroupAny
})

semigroupCustomer.concat(
  {
    name: 'Giulio',
    favouriteThings: ['math', 'climbing'],
    registeredAt: new Date(2018, 1, 20).getTime(),
    lastUpdatedAt: new Date(2018, 2, 18).getTime(),
    hasMadePurchase: false
  },
  {
    name: 'Giulio Canti',
    favouriteThings: ['functional programming'],
    registeredAt: new Date(2018, 1, 22).getTime(),
    lastUpdatedAt: new Date(2018, 2, 9).getTime(),
    hasMadePurchase: true
  }
)
/*
{ name: 'Giulio Canti',
  favouriteThings: [ 'math', 'climbing', 'functional programming' ],
  registeredAt: 1519081200000, // new Date(2018, 1, 20).getTime()
  lastUpdatedAt: 1521327600000, // new Date(2018, 2, 18).getTime()
  hasMadePurchase: true }
*/
```