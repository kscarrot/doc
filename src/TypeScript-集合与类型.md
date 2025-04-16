---
tags:
  - typescript
  - 离散数学
---


> 类型是一种约束条件
> 推论: 类型越精确,约束条件越多,集合覆盖的范围越小


## 类型的集合定义

### unknown 

$$\forall T \in Types,T \subset unknown$$

所有类型的父集,全集,包含所有类型约束的集合


### never 

$$\forall T \in Types,never \subset T$$
所有类型的子集,空集,不包含任何类型约束

> 这里用偏序来思考  unknown 就是 TopType  never就是 Bottom Type

### subType
`A extends B`

$$\forall e \in A \rightarrow e \in B$$

对任意约束`e`属于`A`都有约束`e`属于`B`

即 满足约束集合A的类型a 一定是满足约束集合B的

或者说 A是B的子类

```typescript
interface Animal {
    size: number
}

interface Cat extends Animal {
    meow: () => void
}

interface Colorful {
    color: string
}


const horse: Animal = { size: 200 }
const blackCat: Colorful & Cat = { size: 20, color: '#fff', meow: () => console.log('meow') }

const measure = <T extends Animal>(animal: T) => animal.size
measure(horse)
measure(blackCat) // OK



const meme = (cat: Cat) => cat.meow()
meme(blackCat)
meme(horse) // Error
```

### 联合类型(UnionType)
 约束的并集  表示 `或` 关系
 约束变弱 范围扩大

 `白色 或者 马`


$$
A \& B \rightarrow  \forall T \in Types,T \subset A \lor T \subset B
$$




### 交叉类型(IntersectionType)

 约束的交集  表示 `且` 关系 
 约束变强 范围收窄
`白马`

$$
A \vert B \rightarrow  \forall T \in Types,T \subset A \land T \subset B
$$


### Exclude
约束的补集

$$
A - B \rightarrow  \forall T \in Types,T \subset A \land T \not\subset B
$$


```typescript
type Exclude<T, U> = T extends U ? never : T;

type ResponseCode = 0 | 100001 | 100002
type ErrorCode = Exclude<ResponseCode, 0>

const throwErrorMessage = (code: ErrorCode) => console.error(code)

throwErrorMessage(100001) // ok
throwErrorMessage(0) // error 
```



## 类型的代数结构

1. 交换律

$$
\begin{align}
A \& B &= B \& A \\
A \vert B &= B \vert A
\end{align} 
$$

2. 结合律

$$
\begin{align}
(A \& B) \& C &= A \& (B \& C) = A \& B \& C \\
(A \vert B) \vert C &= A \vert (B \vert C) = A \vert B \vert C
\end{align}
$$

3. 分配律

$$
\begin{align}
(A \& B) \vert C &= (A \vert C) \& (B \vert C) \\
(A \vert B) \& C &= (A \& C) \vert (B \& C) \\
(A - B) \& C &= (A \& C) - (B \& C)
\end{align}
$$

4. 幂等律

$$
\begin{align}
A \vert A &= A \\
A \& A &= A
\end{align}
$$

5. 幺元

$$
\begin{align}
A \vert never &= A \\
A - never &= A
\end{align}
$$

6. 零元

$$
\begin{align}
A \& never &= never \\
never - A &= never
\end{align}
$$

7. 吸收律

$$
\begin{align}
A \vert (A \& B) &= A \\
A \& (A \vert B) &= A
\end{align}
$$


可以由分配律推导而来

$$
\begin{align}
&( A \& B ) \vert A\\
&= ( A \& B ) \vert ( A \& unknown )\\
&= A \& ( B \vert unknown )\\
&= A \& unknown\\
&= A\\
\\
&A \& ( A \vert B ) \\
&= ( A \vert never ) \& ( A \vert B )\\
&= A \vert ( never \& B ) \\
&= A \vert never\\
&= A\\
\end{align}
$$

## never say `never`

对两个无关的类型取交叉会得到`never`

```typescript
type Nothing = number & string // never
```

如果一个变量被设定为`never`类型,那这个变量无法被赋值
```typescript
// 所以这个函数没法调用 会报类型错误
function fn(input: never) {}
```

可以利用这一点来做一个低配的match check
```typescript
function unknownColor(x: never): never {
    throw new Error('unknown color');
}

type Color = 'red' | 'green' | 'blue';

function getColorName(c: Color): string {
    switch (c) {
        case 'red':
            return 'is red';
        case 'green':
            return 'is green';
        default:
            // c没有被收窄到never 有可能取 'blue' 所以会编译错误
            return unknownColor(c);
    }
}
```

上述用例构建了一个理论上无法到达的代码的类型,同样的语义还有

```typescript
// 抛异常
function throwError(): never {
    throw new Error();
}

// 返回 Promise<never>
const p = Promise.reject('foo');
```


因为`union`对`never`的分配特性,参考`Typescript/issues/31751`

```typescript
type IsNever<T> = T extends never ? true : false;
type X = IsNever<never>; // => never
```

在`TypeScript/issues/23182`有解释

需要包裹一层
```typescript
type IsNever<T> = [T] extends [never] ? true : false;
```

## unknown `unknown`
`unknown`Typescript3.0版本引入


>TypeScript 3.0 引入了一个新的顶级类型 unknown。unknown 是 any 的类型安全替代类型。任何值都可以赋值给 unknown 类型，但如果没有类型断言或基于控制流的类型收窄，unknown 类型只能赋值给自身和 any 类型。同理，在对 unknown 类型的值执行任何操作之前，必须先通过类型断言或类型收窄将其转换为更具体的类型。

常用与强制类型转换
```typescript
let a = 2 as unknown as string;
```

泛型`T`
```typescript
type T20<T> = T & {}; // T & {}
type T21<T> = T | {}; // T | {}
type T22<T> = T & unknown; // T
type T23<T> = T | unknown; // unknown
```

难绷的`any`,自收敛
```typescript
type T06 = unknown & any; // any
type T16 = unknown | any; // any
```

条件类型
```typescript
type T30<T> = unknown extends T ? true : false; // Deferred
type T31<T> = T extends unknown ? true : false; // Deferred (so it distributes)
type T32<T> = never extends T ? true : false; // true
type T33<T> = T extends never ? true : false; // Deferred
```


```typescript
type NeverExtendUnkown = T31<never> // never 见上文never的特性


//因为unkown是宇宙类型 除了never 会恒为true 包括any
type IsSebSetOfUnknown<T> = T extends unknown ? true : false;
//这里的语义是 是否是 unknown 的子集


// 这个才是正确判断Unkown的类型 利用了子集的特性
type IsUnknown<T> = unknown extends T ? true : false;
// 同理可以推出 
type IsNumber<T> = number extends T ? true : false;
```


映射类型 可以看出`any`的特殊之处
```typescript
type T40 = keyof any; // string | number | symbol
type T41 = keyof unknown; // never
```