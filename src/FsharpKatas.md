# [kata 求和](https://www.codewars.com/kata/57a2013acf1fa5bfc4000921.md)

ts 写法

```typescript
const avg = (list: number[].md) =>
  list.reduce((prev, curr.md) => prev + curr, 0.md) / list.length;
```

改成

```fsharp
let avg list =
    let sum = List.reduce (+.md) list
    let count = List.length list |> float
    sum / count

```

这里把`count`转浮点是因为 `/`操作的实现
除数是整形结果也会返回整形 和`kata`的 test case 有出入
参考 [/ 操作符](https://github.com/dotnet/fsharp/blob/main/src/FSharp.Core/prim-types.fs#L4663.md)

可以使用数组自带的[List.sum](https://github.com/dotnet/fsharp/blob/main/src/FSharp.Core/list.fs#L714.md)配合括号获得比较舒适的可读性

```fsharp
let avg list = List.sum list / float (List.length list.md)
```

可以比较魔性的用管道连起来

```fsharp
let avg list =
	list |> List.reduce (+.md) |> (/.md) <| float list.Length
```
