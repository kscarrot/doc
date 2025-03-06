之前已经解除到了一些基础的抽象,像是等价,偏序,半群和幺半群.
现在我们会探索一些进阶的抽象概念,这些概念会让函数式编程变的更加有趣.

从通常习惯上,第一个被介绍的进阶的抽象应该是函子(Functor),但是在我们讨论函子之前,我想我们需要学习一下函子构建的基础--范畴.

函数式编程的一大特性就是*可组合性*(composition).但是这个特性到底意味着什么?我们能说仅仅是两个东西的简单组合吗?我们如何能够把东西的组合描述的更好呢?
我们需要对可组合性由一个更加严肃的定义.而这正是范畴想要表达的事情.

> 范畴是组合的本质(Categories capture the essence of composition.)

## 范畴
范畴的定义有一些长,而且被特别的分成了两个部分:
* 第一个部分是理论上的(我们需要定义范畴的构成)
* 第二部分是我们特别感兴趣的:组合的概念

### PartI 定义
一个范畴由两个类定义(对象类,态射类):
* 对象类: 由对象组成的类
* 态射类: 由对象间的态射锁构成的类
态射: 从一个对象类到另一个对象的映射关系.

注意,这里的对象不是oop里的对象,你可以把这里的对象想象成一个无法检查的黑盒,甚至可以想象成态射的一个辅助占位的符号

对于任何一个态射`f`都有一个源对象`A`和一个目标对象`B`,A和B都属于对象类`Object`
我们使用箭头来表示`f: A->B`,读作 f是A到B的态射.

### PartII 组合
这里有一个操作符`∘`,称为组合,满足下面一些性质:
* 组合性: 对于 `f: A->B` he  `g:B->C`,可以实现一个新的态射,这个态射是f和g的符合: `f∘g: A->C`
* 结合性:对于 `f: A->B` , `g:B->C`,`h:C->D`有`h∘(g∘f)=(h∘g)∘f`
* 单位元:对于任意对象X,存在一个映射到自身的态射 `identity:X->X`,有 `indentity∘f = f`

### 函数语言的范畴
* 对象类: 类型(types)
* 态射: 函数
* `∘`同时是函数的组合(composition)


![](https://github.com/kscarrot/blog/blob/master/asserts/catagory.svg)

这个图可以被解释为一个非常简单的编程语言,仅仅包括三种类型和少量的函数

* A = string
* B = number
* C = boolean
* f = string => number
* g = number => boolean
* g ∘ f = string => boolean

可以这样被实现
```typescript
function f(s: string): number {
  return s.length
}

function g(n: number): boolean {
  return n > 2
}

// h = g ∘ f
function h(s: string): boolean {
  return g(f(s))
}
```

## TypeScript的范畴
我们可以定义一个TS的范畴作为TypeScript的一个模型:
* 对象类: 所有的TypeScript类型: `string`,`number`,`Array<string>`....
* 态射: TypeScript的函数: `(a: A) => B`.....
* 恒等态射:`const identity = <A>(a: A): A => a`
* 态射的组合: 函数组合

作为TypeScript的一个模型,TS范畴受到了很多限制:没有循环,没有条件判断,几乎没有任何东西... 尽管如此,这种简单的模型对于我们主要目的来说已经足够丰富了:即合理的理解范畴的概念.

## 组合的关键问题
在TS范畴里,我们可以组合下面两个函数`f: (a: A) => B`和`g: (c: C) => D`,当B和C相等的时候.
```typescript
function compose<A, B, C>(g: (b: B) => C, f: (a: A) => B): (a: A) => C {
  return a => g(f(a))
}
```

但是如果B和C不相等呢?我们还能组合这些函数吗?
在下篇文章中,我们可以看到在哪些条件下能够进行这种组合.我们将讨论函子的概念.
