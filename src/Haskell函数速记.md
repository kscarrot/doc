> [源文档](https://hackage.haskell.org/package/base-4.17.2.1/docs/GHC-Base.html)

## map
```haskell
map :: forall a b. (a -> b) -> [a] -> [b]
map f [x1, x2, ..., xn] == [f x1, f x2, ..., f xn]
map f [x1, x2, ...] == [f x1, f x2, ...]
>>> map (+1) [1, 2, 3]
[2,3,4]
```
## zipwith

```haskell
zipWith :: forall a b c. (a -> b -> c) -> [a] -> [b] -> [c]
-- zipWith generalises zip by zipping with the function given as the first argument, instead of a tupling function.
-- 第一个参数是操作函数
-- 然后分别取 第二个 第三个 列表中的元素一一对应执行 (zip 拉链) 返回一个新的列表
zipWith (,) xs ys == zip xs ys
zipWith f [x1,x2,x3..] [y1,y2,y3..] == [f x1 y1, f x2 y2, f x3 y3..]

>>> zipWith (+) [1, 2, 3] [4, 5, 6]
[5,7,9]
```

## flip

```haskell
flip :: forall a b c. (a -> b -> c) -> b -> a -> c
>>> flip (++) "hello" "world"
"worldhello"
```