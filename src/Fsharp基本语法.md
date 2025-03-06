[language-reference](https://learn.microsoft.com/zh-cn/dotnet/fsharp/language-reference/)Ï
[F# for fun & profit](https://fsharpforfunandprofit.com/)

# Let 绑定

## 值绑定

> 语法

```
// Binding a value:
let identifier-or-pattern [: type] =expressionbody-expression
```

```fsharp
let i = 1

// 缩进
let someVeryLongIdentifier =
	// Note indentation below.
	3 * 4 + 5 * 6

// 元组
let i, j, k = (1, 2, 3)


let result =
    let i, j, k = (1, 2, 3)
    // Body expression:
    i + 2 * j + 3 * k
```

## 函数绑定

> 语法

```
// Binding a function value:
let identifier parameter-list [: return-type ] =expressionbody-expression
```

```fsharp
let function1 a = a + 1
// 通常，参数是模式，如元组模式：
let function2 (a, b) = a + b

let result =
    let function3 (a, b) = a + b
    100 * function3 (1, 2)

// 当然可以包括类型注释 自动推导的类型可以不填
let function4 (a: int) : int = a + 1
```

# 字符串

# 变量与函数
