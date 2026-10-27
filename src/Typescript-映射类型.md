> 映射类型(Mapped Types)

# keyof

> keyof 是一个 类型查询操作符(Type Query Operator) 接受一个对象类型,返回该对象所有公共属性名的联合类型

按照语义我们应该传给他一个对象类型 实际上可以作用给任何类型

## 形式化推导

* 属性访问操作符 `obj[k]` 必须在编译期保证安全（不能在运行时访问到不存在的属性导致未定义崩溃）。
* 因此，一个键`K` 属于 `T` 的充要条件是：**对于集合**`T` **中的每一个可能的值** `x`**，访问属性** `k` **都是合法且存在的**。

$$
\text{keyof } T \triangleq \{ k \mid \forall x \in T,\; x \text{ 拥有属性 } k \}
$$

为了书写简明，我们令命题 `P(x,k)` 表示：值`x`拥有合法的属性键`k`
那么：

$$
\text{keyof } T = \{ k \mid \forall x \in T,\; P(x, k) \}
$$

根据定义展开左侧：

$$
\text{keyof } (A \cup B) = \{ k \mid \forall x \in (A \cup B),\; P(x, k) \}
$$

对并集展开为逻辑合取

$$
\forall x \in (A \cup B),\; P(x) \iff (\forall x \in A,\; P(x)) \land (\forall x \in B,\; P(x))
$$

代入到集合定义中：

$$
\begin{aligned} \text{keyof } (A \cup B) &= \{ k \mid (\forall x \in A,\; P(x, k)) \land (\forall x \in B,\; P(x, k)) \} \\ &= \{ k \mid \forall x \in A,\; P(x, k) \} \cap \{ k \mid \forall x \in B,\; P(x, k) \} \\ &= (\text{keyof } A) \cap (\text{keyof } B) \end{aligned}
$$

我们再来看交叉类型（`A & B`）：

$$
\text{keyof } (A \cap B) = \{ k \mid \forall x \in (A \cap B),\; P(x, k) \}
$$

#### 结构化类型的属性合并

交叉类型 `A & B` 对应集合交：值 `x` 必须同时满足 `A` 和 `B` 的全部约束，也就是形状合并。

* `x` 属于 `A`，则拥有 `keyof A` 的全部属性
* `x` 属于 `B`，则拥有 `keyof B` 的全部属性

因此 `x` 属于 `A & B` 时，`keyof A` 或 `keyof B` 里出现过的键，`x` 都一定有：

$$
\text{keyof } (A \cap B) = (\text{keyof } A) \cup (\text{keyof } B)
$$

## 任意类型取值

在 `ECMAScript` 规范中，对象的属性名（Property Key）在运行时仅有以下两种原始类型：

- `string`
- `symbol`

而在 TypeScript 中，为了支持数组索引和数字下标访问（例如 `obj[0]` 会被自动转换为 `obj["0"]`），`number` 也被纳入了合法属性键的类型集合。

因此，TypeScript 内部定义了一个内置类型别名 `PropertyKey`：

```typescript
type PropertyKey = string | number | symbol;
```

### `keyof any` 

> 等价为 所有可能成为对象的基本类型并集

$$
\text{keyof any} \equiv \text{PropertyKey} \equiv \text{string} \mid \text{number} \mid \text{symbol}
$$

### `keyof unkown`

> 等价为 所有类型(顶层类型)的取值的并集

$$
\text{keyof unknown} = \bigcap_{T \in \text{AllTypes}} (\text{keyof } T) = \emptyset \equiv \text{never}
$$

### `keyof never`

> 等价为空集上的全称命题 是恒真的

$$
\text{keyof never} = \{ k \mid \forall x \in \emptyset,\; P(x, k) \}
$$

任意键 `k` 都满足条件，因此结果是全部合法属性键：

$$
\text{keyof never} \equiv \text{PropertyKey} \equiv \text{string} \mid \text{number} \mid \text{symbol}
$$

### 其他取值

```typescript
type T_null = keyof null // never
type T_undefined = keyof undefined // never
type T_void = keyof void // never

type T_obj1 = keyof {} // never
type T_obj2 = keyof object // never
type T_Object = keyof Object // "constructor" | "toString" | "valueOf" | "hasOwnProperty" | ...

// 函数类型本身没有声明属性；Function 接口才有 call / apply / bind
type T_fn = keyof (() => void) // never
type T_Function = keyof Function // "apply" | "call" | "bind" | "length" | "name" | ...

// 对于基础原始类型 number string boolean bigint symbol 会按照包装类型去取值
// 字面量 / unique symbol / 模板字符串 与对应原始类型相同，不另列
type T_number = keyof number   // 等同于 keyof Number
type T_string = keyof string   // 等同于 keyof String（含 number，因为有数字索引签名）
type T_boolean = keyof boolean // 等同于 keyof Boolean
type T_bigint = keyof bigint   // 等同于 keyof BigInt
type T_symbol = keyof symbol   // 等同于 keyof Symbol

// 数组：keyof T[] 等同于 keyof Array<T>
// 结果是 number（数字索引签名）并上 Array 原型方法名，不是只有下标
type T_array = keyof any[]

// 元组在数组键的基础上再带上字面量下标
type T_tuple = keyof [string, number] // "0" | "1" | keyof any[]
type T_idx = Exclude<keyof [string, number], keyof any[]> // "0" | "1"

// 索引签名：string 会额外带上 number（数字键会转成字符串）
type T_like = keyof { [n: number]: string }  // number
type T_strIdx = keyof { [k: string]: unknown } // string | number
type T_symIdx = keyof { [s: symbol]: unknown } // symbol

// Record 是映射类型，keyof 就是 K，不会像字符串索引那样并上 number
type T_record = keyof Record<string, unknown> // string
type T_recordU = keyof Record<"a" | "b", unknown> // "a" | "b"

// 枚举：keyof E 按成员值的类型走；keyof typeof E 才是成员名
enum NumE { A, B }
enum StrE { A = "a", B = "b" }
type T_numE = keyof NumE          // 等同于 keyof number
type T_strE = keyof StrE          // 等同于 keyof string
type T_enumKeys = keyof typeof NumE // "A" | "B"
```



# in

`[K in Keys]` 在映射类型（Mapped Types）内部逐一遍历联合类型中的每一个成员

## 对偶关系

| 维度 | `keyof`（拆解） | `in`（装配） |
| --- | --- | --- |
| **操作方向** | **对象类型 -> 联合类型**（收拢属性名） | **联合类型 -> 对象类型**（发散属性名） |
| **角色行为** | **提取器（Extractor）**：解包对象表面的所有键 | **生成器（Constructor）**：遍历键并绑定类型生成结构 |
| **JS 运行时类比** | `Object.keys(obj)` | `Object.fromEntries(...)` |
| **数学/范畴类比** | 投影映射（Projection / Analysis） | 乘积重构（Co-projection / Synthesis） |

把两者串联起来，能清晰看到**从对象到联合类型，再由联合类型还原回对象**的完整闭环：


```typescript
// 任意联合类型
type Status = "pending" | "fulfilled" | "rejected";

// 用 in 从联合类型凭空构建出表结构
type StatusMap = {
  [K in Status]: boolean;
};
// 结果:
// {
//   pending: boolean;
//   fulfilled: boolean;
//   rejected: boolean;
// }

// 再用 keyof 抽出来，又变回 Status
type RecoveredStatus = keyof StatusMap; // "pending" | "fulfilled" | "rejected"

```

公式化表示：


$$T \xrightarrow{\text{keyof}} \bigcup K_i \xrightarrow{[\;K \text{ in } \dots\;]} T'$$

如果映射体 `T[K]` 保持不变，**`{ [K in keyof T]: T[K] }` 是一个恒等变换（Identity Transformation）**。


# 应用

这些工具类型就是前面 `keyof` 和 `in` 的组

## `Partial<T>`

每个属性变成可选：

```typescript
type Partial<T> = {
  [P in keyof T]?: T[P];
};
```

## `Readonly<T>`

每个属性加上 `readonly`：

```typescript
type Readonly<T> = {
  readonly [P in keyof T]: T[P];
};
```

递归版见 [Typescript-泛型与拓展.md](./Typescript-泛型与拓展.md) 的 `DeepReadonly`。

## `Record<K, T>`

用键的联合装配出对象，值的类型统一为 `T`：

```typescript
type Record<K extends keyof any, T> = {
  [P in K]: T;
};
```

上一节的 `StatusMap` 就是 `Record<Status, boolean>`。

## `Pick<T, K>`

只保留 `K` 里出现的键：

```typescript
type Pick<T, K extends keyof T> = {
  [P in K]: T[P];
};
```

## `Exclude<T, U>`

从联合 `T` 里丢掉能赋给 `U` 的成员。不是映射类型，靠 `extends` 一项一项问：

```typescript
type Exclude<T, U> = T extends U ? never : T;
```

## `Omit<T, K>`

`Pick` 的补：先用 `Exclude` 去掉键，再 `Pick` 剩下的：

```typescript
type Omit<T, K extends keyof any> = Pick<T, Exclude<keyof T, K>>;
```

```typescript
interface User {
  id: number;
  name: string;
  email: string;
}

type UserPatch = Partial<User>;           // { id?: number; name?: string; email?: string }
type FrozenUser = Readonly<User>;         // { readonly id: number; ... }
type UserIdName = Pick<User, "id" | "name">;
type UserWithoutEmail = Omit<User, "email">;
type Flags = Record<"admin" | "guest", boolean>;
type Codes = Exclude<0 | 1 | 2, 0>;       // 1 | 2
```
