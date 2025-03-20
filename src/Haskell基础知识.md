## 布尔类型

[Data.Bool](https://hackage.haskell.org/package/base-4.17.0.0/docs/Data-Bool.html#t:Bool)

```haskell
:t True
:t False
:t otherwise -- True的别名 语义需要
```

### 布尔常用方法
1. `(&&) :: Bool -> Bool -> Bool infixr 3`
2. `(||) :: Bool -> Bool -> Bool infixr 2`
3. `not :: Bool -> Bool`

## 字符类型

[Data.Char](https://hackage.haskell.org/package/base-4.17.0.0/docs/Data-Char.html#t:Char)
ASCII码会直接打印,其他字符会被转成对应的Unicode显示


## 数值类型
1. 有符号整数`Int`,和操作系统位数有关
2. 无符号整数`Word`,和操作系统位数有关
3. 任意精度整数`Integer`
	加上`0b`,`0o`,`0x`等前缀可以展示对应进制的整数(注:二进制需要增加`BinaryLiterals`拓展)
4. 小数与有理数类型`Float`,`Double`,`Rational`
    有理数可以被处理成任意精度整数的除法

## 列表类型

[Data.List](https://hackage.haskell.org/package/base-4.17.0.0/docs/Data-List.html)

用`[]`包括用,并且只包括单一类型

```haskell
:t  [1,True] -- 直接报错
:t  [1,1.2]  -- 可以,返回Num类型
```

### 字符串

[Data.String](https://hackage.haskell.org/package/base-4.17.0.0/docs/Data-String.html)

```haskell
> ['H','e','l','l','0']
"Hello" -- String的类型为[Char]
```
 [type String = \[Char\]](https://hackage.haskell.org/package/base-4.17.0.0/docs/Data-Char.html#t:Char "Data.Char")

## 元组类型

[Data.Tuple](https://hackage.haskell.org/package/base-4.17.0.0/docs/Data-Tuple.html#t:Solo)

用`()`包裹,可以包含多个类型
* 确认元组后不可伸缩
* 确认元组后对应类型不可改变

### 元组常用方法
1. `fst :: (a, b) -> a`
2. `snd :: (a, b) -> b`
3. `curry :: ((a, b) -> c) -> a -> b -> c`
4. `uncurry :: (a -> b -> c) -> (a, b) -> c`
5. `swap :: (a, b) -> (b, a)`

## 函数类型

[Data.Function](https://hackage.haskell.org/package/base-4.17.0.0/docs/Data-Function.html#v:id)

一个简单的例子

```haskell
add :: Int -> Int -> Int -- 类型声明
add x y = x + y -- 绑定实现

main :: IO ()
main = print $ add 1 2 -- 3
```


### 函数的定义

函数可以理解为从参数到结果的一个映射


### 函数柯里化

`uncurry :: (a -> b -> c) -> (a, b) -> c`
当函数有多个参数时,必须通过元组一次性传入,然后返回结果,这样的函数就是非柯里化的函数

`curry :: ((a, b) -> c) -> a -> b -> c`
当函数有多个参数时,参数可以一个一个地依次输入,如果参数不足,将返回一个函数作为结果,这样的函数就是柯里化的函数


### 函数常用方法

#### 恒等映射

`id :: a -> a`

#### 函数复合

`(.) :: (b -> c) -> (a -> b) -> a -> c infixr 9`

```haskell
add :: Int -> Int -> Int -- 类型声明
add x y = x + y -- 绑定实现
add1 = add 1 -- add1 :: Int -> Int   +1
add2 = add 2 -- add2 :: Int -> Int   +2

main :: IO ()

main = print $ add1 . add2 $ 5
-- add1 . add2   +3   
-- result is 8
```

#### $

`($) :: (a -> b) -> a -> b infixr 0`

观察可知,`$`也是一种恒等映射,但是`$`操作符的优先级是最低的.故而可以用来分隔先后顺序,起到括号的作用

```haskell
putStrLn (show (1 + 1))
putStrLn (show $ 1 + 1)
putStrLn $ show (1 + 1)
putStrLn $ show $ 1 + 1
```

和`.`的区别

1. `+`是一个二元运算,`(1+1)`是一个值,没有输入所以不能使用复合操作
2. `show` 输入一个`Int`返回一个`String`,putStrLn输入一个`String`,返回一个`IO()`,可以进行[复合](./映射.md#复合)

```haskell
putStrLn . show $ 1 + 1
```

## 注释

```haskell
-- 这是单行注释

{-
    这是多行注释
    多行注释可以快速用来屏蔽一段代码
-}
```


## 模块



```haskell
-- Greetings.hs 声明模块名 和 导出的内容
module Greetings (sayHello) where

sayHello :: IO ()
sayHello = putStrLn "Hello"
```


```haskell
-- Say.hs
import Greetings

main :: IO ()
main = do
    Greetings.sayHello
-- bash: runghc Say.hs then print Hello
```

引入时可以指定要导出的内容

```haskell
-- Say.hs
import Greetings (sayHello)

main :: IO ()
main = do
    sayHello
-- bash: runghc Say.hs then print Hello
```

