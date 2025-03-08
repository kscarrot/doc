在过去的讨论范畴的一章我提到了Typescript的范畴和其中的中心问题,关于函数组合.
> 如何我们才能想这样组合两个函数 `f: A =>  B`和 `g: C => D`

为什么找到这个问题的答案这么重要.

因为如果范畴能被用在现代的函数编程语言,态射(Typescript中的函数)就可以用来建模真正的程序.

因此,解决这个问题也意味着能够找到 如何去解决通用编程问题的答案.对于开发者来说,这真是一个有趣的问题,不是嘛?

# 函数组合成程序

我们能把一个纯的程序(pure program)看成一个用一下签名来描述的函数

`A => B`
像这样签名的函数,接受一个类型A作为输入然后生成一个类型B作为结果而没有任何副作用.


我们也可以把一个有副作用的函数看做这样的签名

`A => F<B>`

这个签名描述了一个程序,接受类型`A`的输入,然后接受了一个通过副作用`F`的函数调用返回一个`B`的模型,其中`F`可以看做是一个生成B类型的构造器.

我们可以把类型构造器,看成一个输入0-n个类型参数返回一个新的类型的操作(operator)

# 例子

这里有一个`string`类型
这个`Array`类型构造钱会生成一个新的类型`Array<string>`

这里我们可以推导除一些n(n>=1)元类型构造器,

- `Array<A>` 副作用: 非确定性的计算,可能要处理多个可能的结果
- `Options<A>` 副作用: 计算可能会失败
- `Task<A>` 副作用: 异步计算

现在回到我们的主要问题

> 我们如何能够组合这`f: A => B` `g: C => D`两个函数呢

这个问题处理起来非常棘手,我们需要在 `B` 和 `C` 中间建立某种联系

我们已经知道了,如果 `B = C` 然后我们就可以在通常的解决方式那样组合两个函数

```typescript
function compose<A, B, C>(g: (b: B) => C, f: (a: A) => B): (a: A) => C {
  return a => g(f(a))
}
```
但是其他情况怎么办

# `B = F<C>`这个联系就是我们要找的函子

让我看考虑下面两种情况: 
我们要找的联系`B`和`C`来完成`B = F<C>`是一些 `F`的类型构造器
换句话说就是
- `f: A => F<B>`是一个有副作用的函数
- `g: B =>  C` 是一个纯函数
为了组合`f`和`g`我们需要找到一个 *提升(lift)* `g`的实现
能够帮助我们从 `B => C`推导出 `F<B> => F<C>`
那么我们就能用一个更加通用的组合 (此时`f`的输出类型将和提升后的函数的输入类型一致)

所以我们就能把原始的问题转换成另一个: 我们能够找到这么一个*提升*函数嘛?
让我们来看更多的例子

## 例子(F=Array)

```typescript
function lift<B, C>(g: (b: B) => C): (fb: Array<B>) => Array<C> {
  return fb => fb.map(g)
}
```
## 例子(F=Option)

```typescript
import { Option, isNone, none, some } from 'fp-ts/Option'

function lift<B, C>(g: (b: B) => C): (fb: Option<B>) => Option<C> {
  return fb => (isNone(fb) ? none : some(g(fb.value)))
}
```


## 例子(F=Task)
```typescript
import { Task } from 'fp-ts/Task'

function lift<B, C>(g: (b: B) => C): (fb: Task<B>) => Task<C> {
  return fb => () => fb().then(g)
}
```

这些提升函数看起来几乎都一样. 这不是巧合,表面形式的背后一定有一种可以被函数化的表现模式.

事实上以上所有的实例以及其他许多没有提到的类型函数都可以被称为函子.

# 函子

[数学定义](https://ncatlab.org/nlab/show/functor)

函子是 **范畴余范畴之间的映射关系**
函子能让我们推导出另一个范畴,并且能够让我们保留恒等性以及组合的性质.

由于范畴（Category）由两种要素构成（对象与态射），**函子（Functor）**同样由两种要素构成：

对象间的映射：将范畴 C 中的每个对象 X 关联到范畴 D 中的一个对象。

态射间的映射：将范畴 C 中的每个态射关联到范畴 D 中的一个态射。

`C`和`D`是两种不同的范畴(甚至是两种编程语言)

尽管两种不同编程语言之间的映射是一个有趣的方向，但我们更关注的是 C 和 D 为同一范畴（即 TypeScript）的映射。此时，我们讨论的是 自函子（Endofunctor）（“endo”意为“内部”）。

从现在起，当我提到「函子」时，实际是指 TypeScript 中的自函子。

## 函子的定义

一个函子是一对 `(F, lift)`当
- `F`是一个n参类型构造器 可以将`X`类型映射到 `F<X>` (映射两个对象)
- `lift`是一个函数 签名如下
```typescript
lift: <A, B>(f: (a: A) => B) => ((fa: F<A>) => F<B>)
```
作用于一个函数 `f: A => B`
映射到 `lift(f):  F<A> => F<B>` (映射两个范畴)

`lift`需要保持以下两个性质

- `lift(id X) = id(Fx)`  (恒等态射映射为恒等态射)
- `lift(g>>f) = lift(g) >> lift(f)` (组合的映射等于映射的组合)

示例

恒等率验证 带入 `id: <T> (x:T) => x` 

```typescript
const identity = <T>(x: T) => x;  
const liftedIdentity = lift(identity);  
liftedIdentity([1, 2, 3]); // 结果应为 [1, 2, 3]（即 identity_F(X)）  
```

组合率验证
```typescript
const f = (x: number) => x + 1;  
const g = (x: number) => x * 2;  
const liftedF = lift(f);  
const liftedG = lift(g);  

// 组合后提升  
const liftedGAfterF = liftedG(liftedF([1, 2, 3])); // [4, 6, 8]  
// 提升后组合  
const liftedGComposeF = lift(g ∘ f)([1, 2, 3]);    // [4, 6, 8]  
```


此外 `lift` 也可以通过 `map`变体实现 
`map`的本质是参数顺序调整后的`lift`





```typescript
// lift 形式  
const lift = <A, B>(f: (a: A) => B) => (fa: Array<A>) => fa.map(f);  

// map 形式（参数重排）  
const map = <A, B>(fa: Array<A>, f: (a: A) => B) => fa.map(f);  
```

## `fp-ts`中的自函子

我们如何使用`fp-ts`定义一个函子的实例? 让我们来看一些练习

我们通常用下面的数据模型来定义一个API调用的返回

```typescript
interface Response<A> {
  url: string
  status: number
  headers: Record<string, string>
  body: A
}
```

观察到`body`字段是参数化的,这使得`Response`成为一个适合定义为**函子实例(Functor Instance)**的候选,因为`Response`是一个n元的类型构造器,这是必要的前提条件.

要为`Response`定义函子实例,我们必须定义顿橙儿`map`函数

```typescript
import { Functor1 } from 'fp-ts/Functor'

export const URI = 'Response'

export type URI = typeof URI

declare module 'fp-ts/HKT' {
  interface URItoKind<A> {
    Response: Response<A>
  }
}

export interface Response<A> {
  url: string
  status: number
  headers: Record<string, string>
  body: A
}

function map<A, B>(fa: Response<A>, f: (a: A) => B): Response<B> {
  return { ...fa, body: f(fa.body) }
}

// functor instance for `Response`
export const functorResponse: Functor1<URI> = {
  URI,
  map
}
```

## 通用的问题被解决了嘛?
并没有完全解决. 函子允许我们组合一个有负作用的函数`f`和一个纯函数`g`
但是`g`必须是单参数的.但是如果`g`需要接收两个,三个甚至更多参数的时候怎么办?

| 操作 f	 | 操作 g	 | Com组合position |
| ------------- | ------------- | ------------- |
| pure | pure | `g ∘ f` |
| effectul | pure(unary) | `lift(g) ∘ f` |
| effectul | pure(n-ary) | ?|

为了处理像这样的情形,我们需要更多工具的帮助.
下一章,我们会讨论另一个值得记住的函数式编程抽象: 应用函子