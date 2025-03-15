# [kata 求和](https://www.codewars.com/kata/57a2013acf1fa5bfc4000921)

ts 写法

```typescript
const avg = (list: number[]) =>
  list.reduce((prev, curr) => prev + curr, 0) / list.length;
```

改成

```fsharp
let avg list =
    let sum = List.reduce (+) list
    let count = List.length list |> float
    sum / count

```

这里把`count`转浮点是因为 `/`操作的实现
除数是整形结果也会返回整形 和`kata`的 test case 有出入
参考 [/ 操作符](https://github.com/dotnet/fsharp/blob/main/src/FSharp.Core/prim-types.fs#L4663)

可以使用数组自带的[List.sum](https://github.com/dotnet/fsharp/blob/main/src/FSharp.Core/list.fs#L714)配合括号获得比较舒适的可读性

```fsharp
let avg list = List.sum list / float (List.length list)
```

可以比较魔性的用管道连起来

```fsharp
let avg list =
	list |> List.reduce (+) |> (/) <| float list.Length
```

> F#中 reduce 和 fold 的区别是 fold 需要在第二个参数指定一个初始值 类型 Ts, 而 reduce 会以 List.head 作为初始值 此处使用 reduce 可以少写一个参数
> 另这题没有考虑数组为 0 的情况

haskell 实现,使用模式匹配处理空列表

命名形式

```haskell
avg :: [Float] -> Float
avg [] = 0
avg xs = total / size
  where
    total = foldr (+) 0 xs
    size  = fromIntegral (length xs)
```

括号形式 
求和改用[sum](https://hackage.haskell.org/package/base-4.17.2.1/docs/Data-Foldable.html#v:sum)

```haskell
avg :: [Float] -> Float
avg [] = 0
avg xs = sum xs / fromIntegral  (length xs)
```

可以迁移到其他支持模式匹配的语言,例如`rust`

```rust
fn avg(xs: &[f64]) -> f64 {
    match xs.len() {
        0 => 0.0,
        n => xs.iter().sum::<f64>() / n as f64
    }
}
```
