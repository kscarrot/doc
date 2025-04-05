# This

## this 丢失的情况

- 默认绑定
  在严格模式与非严格模式下,默认绑定有所区别,非严格模式 this 会绑定到上级作用域
  严格模式不会绑定到 window
- 隐式绑定
  当函数被对象引用起来调用时,this 会绑定在其依附的对象上

```javascript
function foo() {
  console.log(this.count); //2
}
var obj = {
  count: 2,
  foo: foo,
};
obj.foo();
```

- 别名丢失隐式绑定
  调用函数引用时,this 会根据调用者环境而定

```javascript
function foo() {
  console.log(this.count); //1
}
var count = 1;
var obj = {
  count: 2,
  foo: foo,
};
var bar = obj.foo;
bar();
```

- 回调丢失隐式绑定

```javascript
function foo() {
  console.log(this.count); //1
}
var count = 1;
var obj = {
  count: 2,
  foo: foo,
};
setTimeout(obj.foo);
```

## this 绑定修复

- bind 显式绑定
- call/apply 绑定
- 函数 bind

## react class 为什么要显式绑定

## 全局环境

```javascript
//在浏览器中,this指向window对象
console.log(this === window); //true

//node环境中,this是一个对象
this.a = 1;
global.a = 2;
const setx1 = function () {
  return this.a;
};
const setx2 = () => this.a;
console.log(setx1(), setx2()); //2 1
```

## 函数环境

### 简单调用

this 指向 global/window,需要指定上下文就要用到 call/apply 方法或者使用 bind 永久绑定上下文

### 箭头函数

箭头函数的 this 永远指向箭头函数被定义时的上下文,与调用时的上下文无关

### 作为方法

当函数作为对象里的方法被调用时,它们的 this 指向调用该函数的对象

```javascript
var o = {
  a: 10,
  b: {
    fn: function () {
      console.log(this.a);
      console.log(this);
    },
  },
};

o.b.fn(); //undefined b
var j = o.b.fn;
j(); //undefined global

var point = {
  x: 0,
  y: 0,
  moveTo: function (x, y) {
    console.log(this); //point
    var moveX = function (x) {
      console.log(this); //global  此处属于简单调用
      this.x = x;
    };
    var moveY = function (y) {
      this.y = y;
    }.bind(this);
    moveX(x);
    moveY(y);
  },
};
point.moveTo(1, 1);
console.log(point.x, point.y); //0 1
```

### 原型链

同上,如果一个方法存在一个对象的原型链上,那么 this 指向的是调用这个方法的对象,就像该方法在对象上一样

### 构造函数

当一个函数用作构造函数(使用 new 关键字),其 this 被绑定到正在构造的新对象

## 作为 DOM 事件

- 当函数被用作事件处理函数时,this 指向触发事件的元素
- 当作为一个内联事件处理函数时,this 指向监听器坐在的 DOM 元素
