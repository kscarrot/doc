## redux
### 核心代码简单实现
```javascript
const createStore = (reducer, preloadedState, enhancer) => {
  if (typeof enhancer === 'function') {
    return enhancer(createStore)(reducer, preloadedState)
  }

  const store = {}
  store.state = preloadedState
  store.listensers = []

  store.subscribe = (listenser) => {
    store.listensers.push(listenser)
  }

  store.dispatch = (action) => {
    store.state = reducer(store.state, action)
    store.listensers.forEach((listenser) => listenser())
  }

  store.getState = () => store.state

  return store
}

```

核心有两点
1. 初始化一个state,在执行`dispatch`时用reducer更新state
2. 维护一个监听队列,在reducer之后触发更新相关的逻辑

### 中间件的实现
```javascript
  const applyMidware = (...midwares) => (createStore) => (reducer, preloadedState) => {
  const store = createStore(reducer, preloadedState)
  let dispatch = () => {
    throw new Error('midaware dispatch error')
  }

  const midwareAPI = {
    getState: store.getState,
    dispatch: (action, preloadedState) => dispatch(action, preloadedState),
  }

  const chain = midwares.map((midware) => midware(midwareAPI))
  dispatch = compose(...chain)(store.dispatch)

  return { ...store, dispatch }
}
```

核心在于重写store的dispatch方法,在调用dispatch的时候,链式调用各个中间件.链式调用时通过compose来完成中间件函数的组合.
链式调用的中间件函数通过闭包拿到`getState`和`dispatch`

## mobx
### 响应式的实现
核心有两部分
1. observer
通过挟持对象的*get*和*set*,在*get*时搜集依赖,在*set*是通知依赖进行更新
响应式对象的创建有两个思路,第一个是`Obejct.defineProperty`,第二个是新的es6API`proxy`.proxy出来兼容性的支持会差一些,整体功能会更加完备,不单单是劫持了key,对其他的诸如数组的操作也能保持正常的响应.
2. autoRun
包装需要响应更新的组件,当依赖发生变化时,自动执行.mobx-react通过改变props来完成组件的更新

## 对比
### redux的优缺点
#### 缺点
1. 较多的模板代码 
action和reducer分散,需要type去做对应
2. 必须用object和arrays描述状态
3. 变化通过action触发,reducer必须是纯函数
4. 组件更新粒度不够精确
需要用SCU或者memo守住更新粒度

#### 优点
1. 便于调试,便于测试
* 每个state的变化都有特定的action触发,可以对变更历史进行暂停然后排查异常的行为
* reducer是纯函数,测试一致性很强,线上搜集数据可以直接发送state和actions的快照
2. 支持时光旅行(Undo/Redo)
每一次状态都是一个新的对象,所以可以维护一个历史对象队列
3. 适合开发协作性应用
不需要考虑双方store同步的问题,只要两边都按顺序调用了actions就能拿到等同的结果.即通过传递action来完成同步
4. 可以通过中间件进行进一步的封装

### mobx的优缺点
#### 优点
1. 响应式更新数据
2. 简单的异步实现
3. 细化更新粒度
4. 对代码的侵入性比较小
不管是在Store直接通过重新赋值或者修改都可以触发更新

容器组件,把inject和observer删除后,可以直接通过传props完成剩余的功能

#### 缺点
1. 全局只有一份store,不便于更新状态
2. 包裹后的数据如果有联动的变化,不便于调试
3. 过于灵活,会导致编写时无序度提高,且不利于按照type提取业务逻辑




### 参考文档
[You Might Not Need Redux](https://medium.com/@dan_abramov/you-might-not-need-redux-be46360cf367)

[Why you should use MobX | alonbd.com](https://www.alonbd.com/blog/2019-10-09-why-you-should-use-mobx)

[深入理解redux - 掘金](https://juejin.im/post/5a9e6a61f265da239866c7a3)

[从零开始用 proxy 实现 Mobx - 知乎](https://zhuanlan.zhihu.com/p/27097547)
