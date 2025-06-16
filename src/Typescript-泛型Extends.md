> TypeScript 泛型扩展的一些区别

# 泛型 `T`

最基本的泛型类型,3.5 版本后默认是`unknown`类型

即`T`隐含`T extends unknown`

```typescript
// 此函数的函数签名:
function identity<unknown>(arg: unknown): unknown;
function identity<T>(arg: T): T {
  return arg;
}

// 使用示例
const num = identity<number>(42); // 类型为 number
const str = identity<string>("hello"); // 类型为 string
const bool = identity(true); // 类型推断为 boolean
// 可以是undefined
const ud = identity(undefined); // undefined
const noll = identity(null); // null
```

# 泛型 `T extends {}`

`T extends {}` 排除了`unknown`中的`null`和`undefined`

**甚至可以是其他原始类型**

```typescript
function processObject<T extends {}>(obj: T): T {
  // 可以安全地访问对象属性
  console.log(Object.keys(obj));
  return obj;
}

// 使用示例
const result1 = processObject({ name: "John", age: 30 }); // 正确
const result2 = processObject([1, 2, 3]); // 正确
const result3 = processObject(() => {}); // 正确
const result4 = processObject(42); // 正确 输出 []
const result5 = processObject("hello"); //正确 ["0","1","2","3","4"]
```

这看起来可能有些反直觉

但其实它们也是有类型构造函数的: `Number`,`String`,上面也绑定了相应的属性和方法

# 泛型 `T extends object`

真正需要严格限制一个对象时，需要使用 `extends object`

```typescript
function processObject<T extends object>(obj: T): T {
  return obj;
}

const result1 = processObject(42); // 错误
const result2 = processObject("hello"); // 错误
```

# 泛型 `[T] extends [P]`

如果`T`是联合类型,使用`[]`包裹会使得`T`作为一个整体去判断

```typescript
type isP<T, P> = T extends P ? true : false;
type isPTotal<T, P> = [T] extends [P] ? true : false;

type XUnit = "x";
type XUnion = "x" | "y";
type R1 = isP<XUnit, XUnion>; // true
type R2 = isP<XUnion, XUnit>; // boolen
/**
 * 这里默认会展开
 * isP<"x"|"y","x">
 * isP<"x"> | isP<"y">
 * "x" extends "x" | "y" extends "x"
 * true | false
 * boolean
 */
type R3 = isPTotal<XUnit, XUnion>; // true
type R4 = isPTotal<XUnion, XUnit>; // false
```

# 泛型约束也满足类型运算

## 1. 多重约束

```typescript
interface Lengthwise {
  length: number;
}

interface Printable {
  print(): void;
}

function processItem<T extends Lengthwise & Printable>(item: T): T {
  console.log(item.length);
  item.print();
  return item;
}

// 使用示例
class Document implements Lengthwise, Printable {
  constructor(public content: string) {}

  get length(): number {
    return this.content.length;
  }

  print(): void {
    console.log(this.content);
  }
}

const doc = new Document("Hello World");
processItem(doc); // 正确：Document 同时实现了 Lengthwise 和 Printable
```

## 2. 条件类型与泛型约束

```typescript
type NonNullable<T> = T extends null | undefined ? never : T;

function processValue<T>(value: T): NonNullable<T> {
  if (value === null || value === undefined) {
    throw new Error("Value cannot be null or undefined");
  }
  return value as NonNullable<T>;
}

// 使用示例
const str = processValue("hello"); // 类型为 string
const num = processValue(42); // 类型为 number
// const nullValue = processValue(null);  // 运行时错误
```

注意下官方的实现是

```typescript
type NonNullable<T> = T & {};
```

1. `T & {}` 方式：

   - 使用交集类型（`&`）操作符
   - `{}` 类型在 TypeScript 中表示一个空对象类型，它不能是 `null` 或 `undefined`
   - 当 T 与 `{}` 取交集时，如果 T 是 `null` 或 `undefined`，结果将是 `never` 类型
   - 如果 T 是其他类型，结果就是 T 本身

2. 条件类型方式：
   - 使用条件类型（conditional type）
   - 如果 T 是 `null` 或 `undefined`，返回 `never`
   - 否则返回 T 本身

## 3. 递归泛型约束

```typescript
type DeepReadonly<T> = {
  readonly [P in keyof T]: T[P] extends object ? DeepReadonly<T[P]> : T[P];
};

// 使用示例
interface User {
  name: string;
  address: {
    street: string;
    city: string;
  };
  hobbies: string[];
}

const user: DeepReadonly<User> = {
  name: "John",
  address: {
    street: "123 Main St",
    city: "New York",
  },
  hobbies: ["reading", "coding"],
};

// user.name = "Jane";                    // 错误：只读属性
// user.address.street = "456 Oak St";    // 错误：只读属性
// user.hobbies.push("gaming");           // 错误：只读数组
```

[官方参考文档](https://www.typescriptlang.org/docs/handbook/2/generics.html)
