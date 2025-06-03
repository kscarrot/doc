# This

## this 丢失的情况

- 默认绑定
  在严格模式与非严格模式下,默认绑定有所区别,非严格模式 `this` 会绑定到上级作用域
  严格模式不会绑定到 `window`
- 隐式绑定
  当函数被对象引用起来调用时,`this` 会绑定在其依附的对象上

```typescript
function foo() {
  console.log(this.name); //"obj"
}
const obj = {
  name: "obj",
  foo: foo,
};
obj.foo();
```

- 别名丢失隐式绑定
  调用函数引用时,`this` 会根据调用者环境而定

```typescript
let ctx = "upContext";
function foo() {
  console.log(this.ctx);
}
foo(); // undefined
window.ctx = "windowContext";
foo(); // windowContext
const obj = {
  ctx: "objContext",
  foo: foo,
};
const bar = obj.foo;
bar(); // windowContext
obj.foo(); // objContext
```

- 回调丢失隐式绑定

```typescript
function foo() {
  console.log(this.ctx);
}
const obj = {
  ctx: "objContext",
  foo: foo,
};
window.ctx = "windowContext";
foo(); // windowContext
obj.foo(); // objContext
setTimeout(obj.foo); // windowContext
setTimeout(() => obj.foo()); // objContext
```

## this 绑定修复

- `bind` 显式绑定

```typescript
function foo() {
  console.log(this.name);
}

const obj = {
  name: "obj",
  foo: foo,
};

// 使用 bind 创建一个新函数,this 被永久绑定到 obj
const boundFoo = foo.bind(obj);

// 即使在其他上下文中调用,this 仍然指向 obj
boundFoo(); // "obj"

// 即使作为回调函数,this 仍然保持绑定
setTimeout(boundFoo); // "obj"

// bind 还可以预设参数
function greet(greeting, name) {
  console.log(`${greeting}, ${name}! I'm ${this.name}`);
}

const boundGreet = greet.bind(obj, "Hello");
boundGreet("Alice"); // "Hello, Alice! I'm obj"
```

- `call/apply` 绑定

```typescript
function greet(name) {
  console.log(`Hello ${name}, I'm ${this.name}`);
}

const person = {
  name: "Alice",
};

// 使用 call 调用函数,this 指向 person
greet.call(person, "Bob"); // "Hello Bob, I'm Alice"

// 使用 apply 调用函数,参数以数组形式传入
greet.apply(person, ["Bob"]); // "Hello Bob, I'm Alice"

// call 和 apply 的区别在于参数传递方式
function sum(a, b, c) {
  console.log(this.name, a + b + c);
}

const numbers = [1, 2, 3];

// call 需要分别传入参数
sum.call(person, 1, 2, 3); // "Alice 6"

// apply 可以传入参数数组
sum.apply(person, numbers); // "Alice 6"
```

## React Class 组件中的 this 绑定

`React Class` 组件中事件处理函数需要显式绑定 `this` 的原因:

1. `React` 使用合成事件系统,事件处理函数会被 `React` 调用,导致 `this` 指向丢失
2. 如果不绑定 `this`,方法函数内的 `this` 将指向 `undefined` (严格模式)或 `window` (非严格模式),无法访问组件实例的 `props`、`state` 等属性

## 全局环境

可以使用`globalThis`设置和访问全局配置 使得不同环境都可以生效

```typescript
// 设置全局变量
globalThis.myGlobalVar = "Hello";

// 访问全局变量
console.log(globalThis.myGlobalVar); // 'Hello'

// 在不同环境中都能正常工作
if (typeof window !== "undefined") {
  console.log(window.myGlobalVar); // 浏览器中可用
}
if (typeof global !== "undefined") {
  console.log(global.myGlobalVar); // Node.js 中可用
}
```

## 作为 DOM 事件

- 当函数被用作事件处理函数时,`this` 指向触发事件的元素
- 当作为一个内联事件处理函数时,`this` 指向监听器坐在的 `DOM` 元素

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Document</title>
  </head>
  <body>
    <button id="btn">Click me Active</button>
    <button onclick="console.log(this)">Click me inline</button>
    <script>
      const btn = document.getElementById("btn");
      btn.addEventListener("click", function () {
        console.log(this); // 指向button
      });
    </script>
  </body>
</html>
```
