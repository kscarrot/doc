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

 > 白色 或者 马

$$A \& B \rightarrow  \forall T \in Types,T \subset A \lor T \subset B$$


### 交叉类型(IntersectionType)

 约束的交集  表示 `且` 关系 约束变强 范围收窄
$$A \& B \rightarrow  \forall T \in Types,T \subset A \land T \subset B$$

> 白马

### Exclude
约束的补集

$$A - B \rightarrow  \forall T \in Types,T \subset A \land T \not\subset B$$


```typescript
type Exclude<T, U> = T extends U ? never : T;

type ResponseCode = 0 | 100001 | 100002
type ErrorCode = Exclude<ResponseCode, 0>

const throwErrorMessage = (code: ErrorCode) => console.error(code)

throwErrorMessage(100001) // ok
throwErrorMessage(0) // error 
```



## 集合的代数结构
1. 交换律
* A & B = B & A
* A | B = B | A
2. 结合律
* ( A & B ) & C = A & ( B & C) = A & B & C
* (A | B ) | C = A | ( B | C ) = A | B | C
3. 分配律
* ( A & B ) | C = ( A | C ) & (B | C )
* (A | B ) & C = ( A & C ) | ( B & C)
* (A - B ) & C = (A & C ) - (B & C )

4. 幂等律
* A | A = A
* A  &  A = A

5. 幺元
* A | never = A
* A - never = A

6. 零元
* A & never = never
* never - A = never

7. 吸收律
* A | (A & B ) = A
* A & ( A | B ) = A
可以由分配律推导而来
```
( A & B ) | A
= ( A & B ) | ( A & Unknown )
= A & ( B | Unknown )
= A & Unknown
= A

A & ( A | B ) 
= ( A | never ) & ( A | B )
= A | ( never & B ) 
= A | never 
= A
```

## Example
我们来看一下一下高阶类型`补集(Exclude)`,[TypeScript2.8文档](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-2-8.html)介绍了条件类型的用法,可以理解为一个类型的三元表达式.

```typescript
type Exclude<T, U> = T extends U ? never : T
// ( 属于 T 且 属于 U  =>  never ) | 属于 T 且不属于 U => T 
// Exclude<T,U> =  T - U
// ps 这个推断也叫Diff类型
//可以很自然的推断出非某种类型
type NonNullable<T> = Exclude <T, null | undefined>

type Extract<T, U> = T extends U ? T : never
// (属于 T 且 属于 U => T ) | ( 属于 T 且不属于 U => never)
//  根据定义 Extract<T,U> 和  T & U 等价
// ps 这个推断也叫Filter类型
```

## 映射类型
简单的类型可以通过组织成对象的结构派升出一个更加复杂的类型.使用索引类型查询可以拿到对象的key,再配合索引访问操作符可以拿到对应key的值.下面是配合 in 操作符的一些衍生.
> keyof T 的结果为 T 上已知公共属性名的联合
`keyof { name:string ,age:number} = 'name' | 'age' `

```typescript
type Readonly<T> = { readonly [P in keyof T]: T[P]}

type Mutable<T> = { -readonly [P in keyof T]: T[P] }

type Partial<T> = { [P in keyof T]?: T[P]}

type Required<T> = { [P in keyof T]-?: T[P] }

type Nullable<T> = { [P in keyof T]: T[P] | null }

type Pick<T, K extends keyof T> = { [P in K]: T[P]}

type Record<K extends string, T> = { [P in K]: T }

type Omit<T, K> = Pick<T, Exclude<keyof T, K>>

```

关于`keyof`的一些 推断
* 约束越多,范围越小,范围越小,约束越多
* keyof 求的是object的约束
```typescript
type A = { a: 1; c: 1 }
type B = { b: 1; c: 1 }
type C = A & B
// C => { a : 1 , b: 1 ,c :1 )
// keyof (A&B) = (keyof A) | (keyof B) => 'a' 'b' 'c'
type D = A | B
// D => { a: 1; c: 1 } | { b: 1; c: 1 } | {a:1 ,b:1 ,c:1}
// keyof (A|B) = (keyof A)&(keyof B)  => 'c'
// A的约束 B 不一定有 反过来也成立
// 所以 A | B 都有的约束一定是 A和B公共的约束
```
