---
tags:
  - 函数式
  - 离散数学
---


带值验证命题之间真值等价.

真值表构造的 `与或/等价` 和系统自带的操作符是等价的.

`等价` 等价左右互推.

`逆否蕴含` 等价 `蕴含`.

`假言推理` 等价 `永真`.

这里按照数理逻辑应该用析取和合取表达的
这边为了保持语义一致性就直接使用 `与或非`
同时也对应集合论的`并交补`
类型论的`product type/ sum type/ empty type`


```haskell
-- BoolLogic.hs
import BoolOpTruthTable

-- 带值验证
验证输入 = [(True,True),(True,False),(False,True),(False,False)]
等值校验 运算1 运算2 (p,q) = 运算1 p q == 运算2 p q
等价 运算1 运算2 = all  (等值校验 运算1 运算2)  验证输入

-- 命题
蕴含命题 p q = (非 p) `或` q 

或非命题 p q = 非 ( p `或` q)

推出 = 蕴含

逆否命题 p q = (非 q) `推出` (非 p)

三段论 p q = (p `与` ( p `推出` q)) `推出` q

左右互推 p q = (p `推出` q) `与` ( q `推出` p)

main :: IO ()
-- main = print $ 
main = print $ and [
    或 `等价` (||),
    与 `等价` (&&),
    同或 `等价` (==),
    蕴含命题 `等价` 蕴含,
    或非命题 `等价` 或非,
    逆否命题 `等价` 蕴含,
    左右互推  `等价` 同或,
    三段论 `等价` 恒真
    ] 

```


真值表,用模式匹配映射出返回值即可,比较直观

```haskell
-- BoolOpTruthTable.hs
module BoolOpTruthTable (
    非,
    恒真 , 恒假, 恒左, 恒右, 非左, 非右, 同或, 与, 与非, 或, 或非, 蕴含, 非蕴含, 反蕴含, 反非蕴含
) where

非 :: Bool -> Bool
非 True = False
非 False = True

恒真 , 恒假, 恒左, 恒右, 非左, 非右, 同或, 与, 与非, 或, 或非, 蕴含, 非蕴含, 反蕴含, 反非蕴含 :: Bool -> Bool -> Bool

-- 恒真 左 右 = True
恒真 True True = True
恒真 True False = True
恒真 False True = True
恒真 False False = True


-- 恒假 左 右 = False
恒假 True True = False
恒假 True False = False
恒假 False True = False
恒假 False False = False

-- 恒左 左 右 = 左
恒左 True True = True
恒左 True False = True
恒左 False True = False
恒左 False False = False

-- 非左 左 右 = 非 左
非左 True True = False
非左 True False = False
非左 False True = True
非左 False False = True

-- 恒右 左 右 = 右
恒右 True True = True
恒右 True False = False
恒右 False True = True
恒右 False False = False

-- 非右 左 右 = 非 右
非右 True True = False
非右 True False = True
非右 False True = False
非右 False False = True

-- 同或 左 右 = 左 == 右
同或 True True = True
同或 True False = False
同或 False True = False
同或 False False = True

-- 异或 左 右 = 左 /= 右
异或 True True = False
异或 True False = True
异或 False True = True
异或 False False = False

-- 与 左 右 = 左 && 右
与 True True = True
与 True False = False
与 False True = False
与 False False = False

-- 与非 左 右 = 非 (左 && 右)
与非 True True = False
与非 True False = True
与非 False True = True
与非 False False = True

-- 或 左 右 = 左 || 右
或 True True = True
或 True False = True
或 False True = True
或 False False = False

-- 或非 左 右 = 非 (左 || 右)
或非 True True = False
或非 True False = False
或非 False True = False
或非 False False = True

-- 蕴含 左 右 = 如果左为真,则右必为真 左推出右
蕴含 True True = True
蕴含 True False = False
蕴含 False True = True
蕴含 False False = True

-- 非蕴含 左 右 = 左推不出右
非蕴含 True True = False
非蕴含 True False = True
非蕴含 False True = False
非蕴含 False False = False

-- 反蕴含 左 右 = 如果右为真,则左必为真 右推出左
反蕴含 True True = True
反蕴含 True False = True
反蕴含 False True = False
反蕴含 False False = True

-- 反非蕴含 左 右 = 右推不出左
反非蕴含 True True = False
反非蕴含 True False = False
反非蕴含 False True = True
反非蕴含 False False = False
```