# typeof 操作符

从 [MDN 的文档](https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Operators/typeof)可以知道能够直接区分的类型

| 类型         | 结果        |
| ------------ | ----------- |
| Undefined    | "undefined" |
| Null         | "object"    |
| Boolean      | "boolean"   |
| Number       | "number"    |
| BigInt       | "bigint"    |
| String       | "string"    |
| Symbol       | "symbol"    |
| Function     | "function"  |
| 其他任何对象 | "object"    |

这里有两个经典坑点:

1. `typeof null === "object";`
2. `typeof NaN === "number";`

一些二级结论:

1. `new`出来的除了`new Function()`以外都是`object`

所以有以下需要规避的坑子写法

```typescript
typeof new Boolean(true) === "object";
typeof new Number(1) === "object";
typeof new String("abc") === "object";
```

2. `class`是函数

```typescript
typeof class C {} === "function";
```

3. 未声明,已声明未赋值的变量都是`undefined`

# Primitive Type

> 源码来自 redash https://github.com/sodiray/radash/blob/master/src/typed.ts

核心特性: **存储在栈内存: 直接存储值而不是引用**

有以下衍生特性

1. 不可变
2. 按值比较(`===`)
3. 没有方法

包括 `number`, `string`, `boolean`, `symbol`, `bigint`, `undefined`, `null`

因为不是对象,所以不能代理(Proxy)

```typescript
export const isPrimitive = (value: any): boolean => {
  return (
    value === undefined || // 短路
    value === null || // 特例
    (typeof value !== "object" && typeof value !== "function") // 非对象
  );
};
```

其他标准对象:

```typescript
export const isSymbol = (value: any): value is symbol => {
  return !!value && value.constructor === Symbol;
};

export const isString = (value: any): value is string => {
  // instanceof 是为了兼容 new String(123)这种低能写法
  return typeof value === "string" || value instanceof String;
};

export const isNumber = (value: any): value is number => {
  // 这里要搞掉NaN
  // 更直白的 typeof value === 'number' && !isNaN(value);
  try {
    return Number(value) === value;
  } catch {
    return false;
  }
};

// number衍生的  亦可考虑Number.isInteger直接判断
export const isInt = (value: any): value is number => {
  return isNumber(value) && value % 1 === 0;
};

export const isFloat = (value: any): value is number => {
  return isNumber(value) && value % 1 !== 0;
};
```

# 对象类型

```typescript
// 对象衍生
export const isObject = (value: any): value is object => {
  // 干掉null
  // 排除原始类型
  // 排除 RegExp
  return !!value && value.constructor === Object;
};

export const isArray = Array.isArray;

export const isFunction = (value: any): value is Function => {
  return !!(value && value.constructor && value.call && value.apply);
};

export const isDate = (value: any): value is Date => {
  return Object.prototype.toString.call(value) === "[object Date]";
};

export const isPromise = (value: any): value is Promise<any> => {
  if (!value) return false;
  if (!value.then) return false;
  if (!isFunction(value.then)) return false;
  return true;
};
```

当然还有一些其他的对象类型,参考 [lodash 源码](https://github.com/lodash/lodash/blob/main/lodash.js#L93)通过[tag 去判别](https://262.ecma-international.org/7.0/#sec-object.prototype.tostring)

# 判断相等

参考[Object.is](https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Global_Objects/Object/is)

通过`Object.is`规避了`===`判断`+0`,`-0`还有`NaN`的问题

```typescript
+0 === -0; // true
NaN === NaN; // false
```

特别的 规范旨在用`Object.hasOwn()`代替`Object.prototype.hasOwnProperty()`

这里用`Reflect.ownKeys`会遍历所有自有属性 可以少写一个`for of`

```typescript
export const isEqual = <TType>(x: TType, y: TType): boolean => {
  if (Object.is(x, y)) return true;
  if (x instanceof Date && y instanceof Date) {
    return x.getTime() === y.getTime();
  }
  if (x instanceof RegExp && y instanceof RegExp) {
    return x.toString() === y.toString();
  }

  // 非null对象才执行后面的逻辑
  if (
    typeof x !== "object" ||
    x === null ||
    typeof y !== "object" ||
    y === null
  ) {
    return false;
  }
  const keysX = Reflect.ownKeys(x as unknown as object) as (keyof typeof x)[];
  const keysY = Reflect.ownKeys(y as unknown as object);
  if (keysX.length !== keysY.length) return false;
  for (let i = 0; i < keysX.length; i++) {
    if (!Reflect.has(y as unknown as object, keysX[i])) return false;
    if (!isEqual(x[keysX[i]], y[keysX[i]])) return false;
  }
  return true;
};
```

# 数据拷贝

## 浅拷贝

`redash`实现,只 Copy 了一层

```typescript
export const clone = <T>(obj: T): T => {
  // Primitive values do not need cloning.
  if (isPrimitive(obj)) {
    return obj;
  }

  // Binding a function to an empty object creates a
  // copy function.
  if (typeof obj === "function") {
    return obj.bind({});
  }

  // Access the constructor and create a new object.
  // This method can create an array as well.
  const newObj = new ((obj as object).constructor as { new (): T })();

  // Assign the props.
  Object.getOwnPropertyNames(obj).forEach((prop) => {
    // Bypass type checking since the primitive cases
    // are already checked in the beginning
    (newObj as any)[prop] = (obj as any)[prop];
  });

  return newObj;
};
```

## 深拷贝

最简单的使用`JSON`序列化之后反序列化

有以下典型缺点:

1. 无法处理循环引用,会抛出错误
2. 会丢失 `undefined`、`Symbol`、函数等特殊类型
3. 会丢失 `Date` 对象,变成字符串
4. 会丢失 `RegExp` 对象,变成空对象
5. 会丢失 `Error` 对象,变成空对象
6. 会丢失 `Map`、`Set`、`WeakMap`、`WeakSet` 等内置对象
7. 会丢失原型链上的属性
8. 会丢失不可枚举的属性
9. 会丢失 `getter/setter` 属性

自己实现的思路是根据对应的特性做树状递归去实现

对于循环引用,包括对象子结构之间的循环引用,利用栈去判断是否有环

新一点的内核提供了[structuredClone](https://developer.mozilla.org/zh-CN/docs/Web/API/Window/structuredClone)可供调用

可以作为替代方法 (低版本浏览器有 `polyfil` 可用,`Nodejs 17` 也支持了该方法)

> 

### 最佳实践

- 使用 `Object.assign()` 或展开运算符 `...` 进行简单对象的浅拷贝
- 使用 `Array.prototype.slice()` 或展开运算符 `...` 进行数组的浅拷贝
- 需要深拷贝时，考虑使用 `lodash.cloneDeep` 或自定义深拷贝函数
- 考虑使用 `structuredClone()` API
