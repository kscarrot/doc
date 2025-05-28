# [Object.defineProperty](https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Global_Objects/Object/defineProperty)

> Object.defineProperty() 静态方法会直接在一个对象上定义一个新属性，或修改其现有属性，并返回此对象。

这里只对对象生效,所以我们可以看到像`Vue`的实现是要求你的`data`字段返回一个对象的

可以在[Vue 官网](https://v2.cn.vuejs.org/v2/guide/reactivity.html#%E5%A6%82%E4%BD%95%E8%BF%BD%E8%B8%AA%E5%8F%98%E5%8C%96)的响应式文档上看到解释

> 当你把一个普通的 JavaScript 对象传入 Vue 实例作为 data 选项，Vue 将遍历此对象所有的 property，并使用 Object.defineProperty 把这些 property 全部转为 getter/setter。

并且官方还贴心的告知了响应式绑定时需要注意的地方:

1. [对于对象](https://v2.cn.vuejs.org/v2/guide/reactivity.html#%E5%AF%B9%E4%BA%8E%E5%AF%B9%E8%B1%A1)

   `Vue` 无法检测 `property` 的添加或移除。

   由于 `Vue` 会在初始化实例时对 `property` 执行 `getter/setter` 转化

   所以 `property` 必须在 `data` 对象上存在才能让 `Vue` 将它转换为响应式的

2. [对于数组](https://v2.cn.vuejs.org/v2/guide/reactivity.html#%E5%AF%B9%E4%BA%8E%E6%95%B0%E7%BB%84)

   Vue 不能检测以下数组的变动：

   - 当你利用索引直接设置一个数组项时，例如：`vm.items[indexOfItem] = newValue`
   - 当你修改数组的长度时，例如：`vm.items.length = newLength`

## 基于`defineProperty`的简单实现

定义一个观察者

```typescript
class Observer {
  collector: Collector;
  constructor(obj: object) {
    this.collector = createCollector();
    if (isArray(obj)) {
      // 数组需要对数组上每个元素数据绑定响应式
      for (const item of obj) {
        observe(item);
      }
    } else {
      // 对象需要对对象上的每个键的值绑定响应式
      for (const key of Object.keys(obj)) {
        defineReactive(obj, key);
      }
    }
  }
}

function observe(obj: any) {
  // 非对象数据直接返回
  if (isPrimitive(obj)) {
    return;
  }
  return new Observer(obj);
}
```

接着用`Object.defineProperty`实现递归的响应式绑定和依赖搜集

```typescript
function defineReactive(obj: object, key: string) {
  const collector = createCollector();
  let value = (obj as Record<string, any>)[key];
  let childObect = observe(value);
  Object.defineProperty(obj, key, {
    get() {
      // 如果有当前活动的收集器，则添加依赖
      if (activeCollector) {
        activeCollector.addDep(collector);
      }
      if (childObect) {
        // 子对象也是对象 同样需要收集依赖
        childObect.collector.addDep(collector);
        if (isArray(value)) {
          for (const item of value) {
            // 数据里可能不是对象，所以需要判断
            item?.collector?.addDep(collector);
          }
        }
      }
      return value;
    },
    set(newVal) {
      let oldVal = value;
      if (value === newVal) return;
      // 更新值
      value = newVal;
      // 新值可能是对象 添加观察者
      childObect = observe(newVal);
      // 通知依赖更新
      collector.update({ key, oldVal, newVal });
    },
  });
}
```

`Vue`源码实现是用`Watcher`新建`Dep`,这里简单搞个搜集器

```typescript
function createCollector(): Collector {
  return {
    id: uid++,
    deps: new Set(),
    addDep(collector: Collector) {
      this.deps.add(collector);
    },
    update(info: DepInfo) {
      console.log("数据更新了！", info);
      // 通知所有依赖
      this.deps.forEach((dep) => dep.update(info));
    },
  };
}
```

在读数据的时候进行依赖搜集

在修改数据的时候触发依赖的更新

```typescript
// 当前活动的收集器
let activeCollector: Collector | null = null;
// 创建一个根收集器
const rootCollector = createCollector();
// 设置当前活动的收集器
activeCollector = rootCollector;

// 测试代码
let data = {
  objKey: {
    subObjKey: 1,
  },
  primitiveKey: 2,
  arrayKey: [{ arraItemKey: 9 }, 2, 3],
};

observe(data);

// 访问数据，触发依赖收集
data.objKey.subObjKey;
data.primitiveKey;
(data.arrayKey[0] as any).arraItemKey;

// 清除当前活动的收集器
activeCollector = null;

// 修改数据，触发更新
data.objKey.subObjKey = 999;
// 数据更新了！ { key: 'subObjKey', oldVal: 1, newVal: 999 }
data.primitiveKey = 888;
// 数据更新了！ { key: 'primitiveKey', oldVal: 2, newVal: 888 }
(data.arrayKey[0] as any).arraItemKey = 4;
// 数据更新了！ { key: 'arraItemKey', oldVal: 9, newVal: 4 }
```

这里就可以解释直接修改数组的索引或者长度为什么不能响应

因为依赖搜集没有正常触发,值是后绑定上去的

正常情况下数组的方法也是不能触发响应依赖更新的

[源码](https://github.com/vuejs/vue/blob/main/src/core/observer/array.ts)对数组的这些变更方法做了`patch` 使得触发对应方法的时候也通知对应的依赖进行更新

```typescript
const methodsToPatch = [
  "push",
  "pop",
  "shift",
  "unshift",
  "splice",
  "sort",
  "reverse",
];
```

# [Proxy](https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Global_Objects/Proxy)和[Reflect](https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Global_Objects/Reflect)

Proxy 可以创建一个对象的代理,实现自定义的操作

这里直接贴 MDN 给的例子

```typescript
let validator = {
  set: function (obj: any, prop: string, value: any) {
    if (prop === "age") {
      if (!Number.isInteger(value)) {
        throw new TypeError("The age is not an integer");
      }
      if (value > 200) {
        throw new RangeError("The age seems invalid");
      }
    }

    // The default behavior to store the value
    obj[prop] = value;

    // 表示成功
    return true;
  },
};

let person = new Proxy({}, validator);

person.age = 100;

console.log(person.age);
// 100

person.age = "young";
// 抛出异常：Uncaught TypeError: The age is not an integer

person.age = 300;
// 抛出异常：Uncaught RangeError: The age seems invalid
```

`Proxy`的功能比起`defineProperty`相当宽泛

除了`get`和`set`,还可以对以下属性进行代理

- 原型(`get/set PrototypeOf`)
- `in`(`has`)和`delete`(`deleteProperty`)操作
- 函数调用(`apply`)
- `new`(`construct`)

我们可以发现`Proxy`也要求代理对象是一个对象

那么如果是一个值,应该如何处理呢,当然是用对象给他包裹一层

# [Ref](https://github.com/vuejs/core/blob/main/packages/reactivity/src/ref.ts)

## [官方文档](https://cn.vuejs.org/api/reactivity-core#ref)介绍

```typescript
function ref<T>(value: T): Ref<UnwrapRef<T>>;

interface Ref<T> {
  value: T;
}

const count = ref(0);
console.log(count.value); // 0

count.value = 1;
console.log(count.value); // 1
```

## 类型签名

```typescript
export function ref<T>(
  value: T
): [T] extends [Ref]
  ? IfAny<T, Ref<T>, T>
  : Ref<UnwrapRef<T>, UnwrapRef<T> | T>;
export function ref<T = any>(): Ref<T | undefined>;
export function ref(value?: unknown) {
  return createRef(value, false);
}
```

这里有类型的重载

先看第二个 `function ref<T = any>(): Ref<T | undefined>;`

传值根据参数类型自动推导类型

```typescript
const count = ref(0); // 类型为 Ref<number>
const emptyRef = ref(); // 类型为 Ref<undefined> 支持后续再赋值
```

然后看第一个类型签名

回顾一下`Ref`

```typescript
interface Ref<T = any, S = T> {
  get value(): T;
  set value(_: S);
  [RefSymbol]: true;
}
```

绝大部分情况下`get`和`set`都是对称的,所以会指定泛型参数`S = T`

再拿出`ref`的返回值类型

```typescript
[T] extends [Ref]
  ? IfAny<T, Ref<T>, T>
  : Ref<UnwrapRef<T>, UnwrapRef<T> | T>
```

直接用 `T extends Ref` 如果`T`是联合类型 会被展开到类型成员上

使用元组类型`[T] extends [Ref]`约束类型判断作为一个整体进行

接着拆开条件类型

### 正值条件: `IfAny<T, Ref<T>, T>`

如果`T` 是 `Ref`,那么返回`T` 类似 Fp 概念里拆盒子的操作

```typescript
const countRef = ref(0);
const sameRef = ref(countRef); // 类型是`Ref<T>`而不是`Ref<Ref<T>>`
```

这里有个[小技巧](https://stackoverflow.com/questions/49927523/disallow-call-with-any/49928360#49928360),利用类型体操魔法把`any`收窄到`Ref<any>`

```typescript
type IfAny<T, Y, N> = 0 extends 1 & T ? Y : N;
```

### 负值条件: `Ref<UnwrapRef<T>, UnwrapRef<T> | T>`

[`UnwrapRef<T>`](https://github.com/vuejs/core/blob/main/packages/reactivity/src/ref.ts#L494)本身是一段教科书般的类型推导

这里不贴代码直接叙述大致思路

根据上个章节基本类型里的探索

我们会发现`object`类型其实是有点古神的,含义比较丰富

### case1:排除不需要推导的类型

一共 3 种情况

1. 不需要再展开

   包括值类型(Primitive),以及一些衍生对象类型但是不需要响应式处理的

   ```typescript
   type Primitive =
     | string
     | number
     | boolean
     | bigint
     | symbol
     | undefined
     | null;
   export type Builtin = Primitive | Function | Date | Error | RegExp;
   ```

2. `Ref` 本身

   同正值条件思路,拆盒子

3. `runtime` 对象

   包括 `Node | Window`

### case2: 集合类型

- `Map`：递归解包值类型 `V`
- `WeakMap`：递归解包值类型 `V`
- `Set`：递归解包值类型 `V`
- `WeakSet`：递归解包值类型 `V`

### case3: 数组类型

对数组的每个元素递归应用 `UnwrapRefSimple`

```typescript
 { [K in keyof T]: UnwrapRefSimple<T[K]> }
```

效果:

```typescript
// 数组类型
type T3 = UnwrapRef<Ref<number[]>>;
// number[]
```

### case4: 对象类型

对对象的每个属性递归应用 `UnwrapRef`
`symbol`属性保持原样

```typescript
{
    [P in keyof T]: P extends symbol ? T[P] : UnwrapRef<T[P]>
}
```

效果:

```typescript
// 对象类型
type T2 = UnwrapRef<Ref<{ count: Ref<number> }>>;
// { count: number }
```

最终效果,对于嵌套的拆盒子都能正常处理

```typescript
// 嵌套类型
type T4 = UnwrapRef<Ref<{ items: Ref<number[]> }>>;
// { items: number[] }
```

## 实现

如果是 Ref 了就直接返回,避免重复包装

这里的参数里包含`shallow`,是因为单独指定类似浅拷贝的 `ref` 赋值避免特性传染

```typescript
function createRef(rawValue: unknown, shallow: boolean) {
  if (isRef(rawValue)) {
    return rawValue;
  }
  return new RefImpl(rawValue, shallow);
}
```

最后就是 `RefImpl`本体

我干掉了开发标记和性能优化部分便于阅读

(主要是 `shallow`减少层级 和 `rawValue`比较原始值减小开销)

```typescript
class RefImpl<T = any> {
  _value: T;
  private _rawValue: T;

  dep: Dep = new Dep();

  public readonly [ReactiveFlags.IS_REF] = true;

  constructor(value: T) {
    this._value = value;
  }

  get value() {
    //读值的时候搜集依赖
    this.dep.track();
    return this._value;
  }

  set value(newValue) {
    //写值的时候判断值更新了触发依赖更新
    const oldValue = this._value;
    if (hasChanged(newValue, oldValue)) {
      this._value = newValue;
      this.dep.trigger();
    }
  }
}
```
