# 异步
## 事件循环
Js是单线程的,在执行时,有些任务有pending的状态(I/O,异步状态)
这些任务不能立即完成,而执行栈又不能停下来等他,所以异步的任务会以事件的形式在完成后发起回调.事件的执行需要一定的顺序,通常以队列的形式按照先后顺次执行,这个过程一般被称为事件循环.
一般来说,宿主执行的task称为宏任务.Js引擎自己控制的task称为微任务.

## 执行顺序
1. 执行同步代码,将异步任务加入队列
2. 从微任务队首开始执行队列,直至微任务队列清空(若执行的过程中又产生了微任务,也会加入到队尾在本周期被执行完)
3. 从宏任务队首开始执行一个任务,直至调用栈清空
4. 回到第2步完成一个循环


## 分类
### 宏任务
* setTimeout
* setInterval
* requestAnimationFrame
* requestIdleFrame
* I/O
* UI rendering (UI的执行点在所有microtask之后,下一个task之前)

### 微任务
* Promise
* Object.observe
* MutatonObserver
* process.nextTick

## node 
* 微任务队列   nextTick > other 
* 宏任务队列  timer > io > check > close (soket)
* [Node.js 事件循环，定时器和 process.nextTick() | Node.js](https://nodejs.org/zh-cn/docs/guides/event-loop-timers-and-nexttick/)

参考:[JS 中 setTimeout 的实现机理是什么？ - 知乎](https://www.zhihu.com/question/463446982/answer/1928623264)


## 一些注意点
* 在执行异步任务前需要先清空调用栈,所以尾部的`log`一般都会先执行
* Promise的构造函数是立即执行的,并且会执行完,所以在excute内,resolve之后的内容也会先执行
* 一个Promise可能有多个`then`,按照调用顺序执行

## Promise
1. Promise构造函数执行时立即调用executor 函数， resolve 和 reject 两个函数作为参数传递给executor
2. resolve 和 reject 函数被调用时，分别将promise的状态改为/fulfilled（/完成）或rejected（失败)  一旦修改过后,状态就确定下来
3. 实现链式调用, then 需要返回一个新的Promise实例
4. 为了保证时序正确,传递到 then() 中的函数被置入了一个微任务队列，而不是立即执行,使得then里的内容在上下文执行完后再执行.另外then里的内容需要在resolve或者reject执行完毕后才能执行,所以需要先把onFulfilled和onRejected存在队列里,在执行res或者rej时进行调用


## 节流防抖
### 防抖
在一定时间内重复触发的事件会重置前一个触发的事件
基本思路,闭包里装一个计时器,再次触发就重置
* 运用:  input等频繁触发副作用的调用,缺点是如果触发特别频繁会抑制本来将要执行的动作

### 节流
每隔一段时间触发一个事件,后面的事件会在出发前把之前触发的事件覆盖,如果触发时已经超过节流间隔,立即执行
* 运用: resize scroll  touchmove 和动画相关场景
