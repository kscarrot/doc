
# 通俗的讲什么是生成器?

> 官方文档连接: [异步生成器]( https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Global_Objects/AsyncGenerator)

简单来说，**生成器（Generator）就是一个可以踩“暂停键”的特殊函数**。

普通的函数就像坐过山车，一按启动键（调用函数），就必须一路狂奔到终点（`return`），中间谁也停不下来。

而生成器函数就像是在看视频，你可以在中途任何地方按“暂停键”（`yield`）**。

当你按暂停时，函数会把当前的结果交给你，然后就在那儿定格等着。

直到你下一次点**“播放键”（`next()`），它才会抬起脚，继续往下走，直到遇到下一个暂停点或者结束。

### 为什么要用生成器？

1. **控制权反转：** 允许你在函数执行的中间插手，塞入新的数据或者决定什么时候继续。

2. **省内存（惰性求值）：** 如果你需要 100 万个数字，普通函数会直接在内存里创建一个包含 100 万个数字的数组。而生成器是“要一个给一个”，你需要第 5 个，它才算第 5 个，内存里永远只占一个坑。

### TypeScript 代码示例

在 TypeScript 中，写生成器有两个核心标志：

1. 函数名前面要加一个星号 `*`（变成 `function*`）。

2. 函数内部使用 `yield` 来设置暂停点。

我们来看一个“排队领号机”的通俗例子：

TypeScript

```TypeScript
// 1. 定义一个生成器函数（注意那个 * 号）
function* ticketGenerator() {
    console.log("--- 机器启动，准备生成第一个号码 ---");
    yield "号码牌 001";
    // 第一次暂停，返回 001
    console.log("--- 机器继续，准备生成第二个号码 ---");
    yield "号码牌 002";
    // 第二次暂停，返回 002
    console.log("--- 机器继续，准备生成最后一个号码 ---");
    yield "号码牌 003";
    // 第三次暂停，返回 003
    console.log("--- 号码发完了 ---");
    return "已售罄";
    // 结束
}

// 2. 调用生成器函数，注意：这时候函数体内部的代码【并不会】马上执行！
// 它只是创建并返回了一个“控制器”（也就是迭代器对象）
const machine = ticketGenerator();

// 3. 第一次按下“播放键” next()
const res1 = machine.next();
// 输出: --- 机器启动，准备生成第一个号码 ---
console.log(res1);
// 输出: { value: '号码牌 001', done: false } (done 为 false 意味着还没结束)
// 4. 第二次按下“播放键” next()
const res2 = machine.next();
// 输出: --- 机器继续，准备生成第二个号码 ---
console.log(res2);
// 输出: { value: '号码牌 002', done: false }
// 5. 我们甚至可以拿着拿到的号码去干别的事，过很久再来按第三次
const res3 = machine.next();
// 输出: { value: '号码牌 003', done: false }
// 6. 第四次按“播放键”，后面没 yield 了，遇到了 returnconst
res4 = machine.next();
// 输出: --- 号码发完了 ---console.log(res4);
// 输出: { value: '已售罄', done: true } (done 为 true，代表彻底结束了)
```

### 实际开发中的高级玩法：斐波那契数列（无限流）

生成器最厉害的地方在于，它可以写出**死循环**，但绝对**不会导致浏览器或服务器卡死**。因为它每次走到 `yield` 就停住了。

TypeScript

```TypeScript
// 创建一个可以无限产生斐波那契数（0, 1, 1, 2, 3, 5, 8...）的生成器
function* fibonacciGenerator(): Generator<number, void, unknown> {
    let current = 0;
    let nextNum = 1;

    while (true) {
    // 虽然是死循环，但有 yield 在，非常安全
    yield current;
    // 吐出当前数字，并暂停
    // 经典的解构赋值，计算下一个数
      [current, nextNum] = [nextNum, current + nextNum];
    }
}

const fib = fibonacciGenerator();

// 想要几个就拿几个，绝不浪费内存
console.log(fib.next().value); // 0
console.log(fib.next().value); // 1
console.log(fib.next().value); // 1
console.log(fib.next().value); // 2
console.log(fib.next().value); // 3
```

### 总结

把生成器想象成一个“随叫随到”的打工人：

- 叫他一次（`next()`），他就动一下。

- 只要遇到 `yield`，他就立刻把手头的成果（`value`）交出来，然后原地摸鱼（暂停）。

- 直到你下次再叫他，他才会继续干活。

## 外部传参的例子

没问题，这是生成器最酷的地方！`yield` 不仅能像水龙头一样向外“吐出”**数据，它还能像漏斗一样从外部**“接收”数据。

在外部，我们通过给 `next(参数)` 传参，这个参数会变成生成器内部**上一次暂停的那个 **`yield`** 表达式的返回值**。

### 通俗比喻：自动售货机

我们可以把“能传参的生成器”想象成一个**自动售货机**：

1. 你按一下按钮（第一次 `next()`），机器告诉你：“请投币”（`yield` 吐出提示）。

2. 你往里面投了一个硬币（第二次 `next(5)` 传参），机器拿到这 5 块钱，内部程序继续往下走。

### TypeScript 代码示例

我们来看一个“小怪兽喂食”的例子。外部投喂不同的食物，小怪兽在内部会有不同的反应：

TypeScript

```TypeScript
// 这里的 Generator 类型定义：
// <向外吐的数据类型, 最终返回的数据类型, 外部传进来的数据类型>
function* monsterGenerator(): Generator<string, string, string> {
    console.log("小怪兽醒了，肚子好饿...");

    // 1. 第一次暂停，向外索要食物。
    // 【注意】当外部下一次调用 next("肉") 时，"肉" 会整体替换掉 `yield "我想吃东西，给我点什么吧..."` 这句话，然后赋值给 food1const food1 = yield "我想吃东西，给我点什么吧...";

    console.log(`【怪兽内部】吃下了: ${food1}`);
    if (food1 === "苹果") {
        console.log("【怪兽内部】呸，真难吃，我要吃肉！");
    } else {
        console.log("【怪兽内部】真好吃，谢谢主人！");
    }

    // 2. 第二次暂停，再次索要饮料const drink = yield "我还口渴，想喝点什么...";

    console.log(`【怪兽内部】喝下了: ${drink}`);
    if (drink === "牛奶") {
        return "怪兽吃饱喝足，满意的睡去了 zzz";
    } else {
        return "怪兽喝完肚子疼，生气地跑了！";
    }
}

// 启动怪兽
const monster = monsterGenerator();

// ----------------------------------------------------
// 第一次启动（注意：第一次 next() 里面传参数是没用的，因为前面没有 yield 等着接收）
// ----------------------------------------------------
const step1 = monster.next();
// 控制台输出: 小怪兽醒了，肚子好饿...
console.log(step1.value);
// 输出: "我想吃东西，给我点什么吧..." （这是内部 yield 吐出来的）
// ----------------------------------------------------

// 第二次调用，我们从外部“投喂”一个苹果
// ----------------------------------------------------
const step2 = monster.next("苹果");
// 控制台输出:
// 【怪兽内部】吃下了: 苹果
// 【怪兽内部】呸，真难吃，我要吃肉！
console.log(step2.value);
// 输出: "我还口渴，想喝点什么..." （这是第二个 yield 吐出来的）
// ----------------------------------------------------
// 第三次调用，我们从外部“投喂”牛奶
// ----------------------------------------------------
const step3 = monster.next("牛奶");
// 控制台输出:
// 【怪兽内部】喝下了: 牛奶
console.log(step3.value);
// 输出: "怪兽吃饱喝足，满意的睡去了 zzz" （这是最终的 return 值）
```

### 数据是怎么流动的？（脑补这个画面）

很多人在这里容易绕晕，记住这个公式：

> `const 变量 = yield 输出值;`

这是一个双向通道：

1. **右边的 **`yield 输出值`：是里面给外面的。

2. **左边的 **`const 变量 =`：是外面通过 `next(输入值)` 塞进来的。

因为第一次执行 `next()` 只是为了跑到第一个 `yield` 面前停下，此时代码还没执行到“赋值”那一步，所以**第一次 **`next()`** 传参毫无意义**。从第二次 `next(值)` 开始，传入的值才会真正赋给代码里的变量，从而改变函数内部的 `if/else` 走向。

# 实现一个人在回路的流程

用异步生成器（Async Generator）来实现**人在回路（Human-in-the-Loop）是非常优雅且标准的做法。核心在于理解 **`yield`** 的双向通信**机制：它不仅能把状态“吐”给外部，还能通过外部调用 `.next(value)` 把审批结果“喂”回给函数内部。

为了让你的示例变成一个真正可运行、结构清晰的“工具调度”模式，我们可以设计一个执行器（Executor）来驱动这个生成器。

以下是完整的实现方案：

### 核心插件代码

TypeScript

```TypeScript
interface PluginState {
  input: string;
  [key: string]: any;
}

// 异步生成器插件
async function* humanApprovalPlugin(state: PluginState) {
  console.log("-> [Step 1] 插件启动，开始安全检测...");
  yield { status: "checking_safety" };

  console.log("-> [Step 2] 发现敏感内容，触发暂停，等待人工审批...");

  // 核心点：yield 抛出状态，并等待外部通过 .next(result) 传入审批结果
  const approvalResult: any = yield {
    status: "wait_for_human_approval",
    data: state.input
  };

  console.log("-> [Step 3] 收到审批结果:", approvalResult);

  if (!approvalResult?.approved) {
    return { status: "rejected", reason: approvalResult?.reason || "用户拒绝" };
  }

  console.log("-> [Step 4] 审批通过，准备执行工具...");
  return { status: "approved", action: "execute_tool", toolInput: state.input };
}
```

### 调度执行器（驱动生成器）

异步生成器不能自己往下走，需要一个宿主（Orchestrator/Executor）来根据生成器抛出的状态做不同的处理。

TypeScript

```TypeScript
// 模拟异步的人工审批（例如：等待前端点击按钮、或者钉钉/Slack回调）
function mockHumanInput(): Promise<{ approved: boolean; reason?: string }> {
  return new Promise((resolve) => {
    setTimeout(() => {
      // 模拟用户点击了“同意”
      resolve({ approved: true });
      // 如果要模拟拒绝，可以换成：resolve({ approved: false, reason: "风险过高" });
    }, 2000); // 模拟 2 秒后用户完成了审批
  });
}

// 调度器函数
async function runWorkflow() {
  const initialState = { input: "向账户 0x123... 转账 100 ETH" };

  // 1. 初始化生成器实例
  const workflow = humanApprovalPlugin(initialState);

  // 2. 第一次驱动：走到第一个 yield (安全检测)
  let result = await workflow.next();
  console.log("【外部感知】当前状态:", result.value); // { status: 'checking_safety' }

  // 3. 第二次驱动：走到第二个 yield (触发人工审批)
  result = await workflow.next();
  console.log("【外部感知】当前状态:", result.value); // { status: 'wait_for_human_approval', data: ... }

  // 4. 触发挂起逻辑：判断是否需要人工介入
  if (result.value?.status === "wait_for_human_approval") {
    console.log("n[系统提示] 流程已挂起，正在等待人工操作...");

    // 等待异步的人工输入const humanDecision = await mockHumanInput();
    console.log(`[系统提示] 收集到人工决策:`, humanDecision, "n");

    // 5. 第三次驱动：将人工结果【注入】回生成器
    // 此时 humanDecision 会赋值给生成器内部的 approvalResult
    result = await workflow.next(humanDecision);
  }

  // 6. 结束流程
  // 此时 done 为 true，result.value 拿到的是 return 的值
  console.log("【外部感知】最终流程结束状态:", result.value);
}

// 执行调度
runWorkflow();
```

### 运行日志输出

当你运行上述代码时，控制台的交替打印顺序如下，完美实现了串行挂起和唤醒：

Plaintext

```Plain Text
-> [Step 1] 插件启动，开始安全检测...
【外部感知】当前状态: { status: 'checking_safety' }
-> [Step 2] 发现敏感内容，触发暂停，等待人工审批...
【外部感知】当前状态: { status: 'wait_for_human_approval', data: '向账户 0x123... 转账 100 ETH' }

[系统提示] 流程已挂起，正在等待人工操作...
（等待 2 秒...）
[系统提示] 收集到人工决策: { approved: true }

-> [Step 3] 收到审批结果: { approved: true }
-> [Step 4] 审批通过，准备执行工具...
【外部感知】最终流程结束状态: { status: 'approved', action: 'execute_tool', toolInput: '向账户 0x123... 转账 100 ETH' }
```

### 💡 为什么这种模式适合 Agent工具调度？

1. **状态机解耦**：插件内部只需关心“我需要什么”，通过 `yield` 扔出去即可。外部的调度器去关心“怎么拿到这个东西”（读数据库、发 Webhook、等前端 Socket）。

2. **无需断点续传的上下文管理**：如果不借助 Generator，通常需要把当前状态存入 Redis，等用户审批完后重新调用一个 `resumeWorkflow(stateId)` 函数，还要重新恢复上下文。而 Generator 隐式地在内存中**维持了整个调用栈和局部变量**。

