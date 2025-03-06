   xslx文件是一个[workbook](https://docs.microsoft.com/zh-cn/office/vba/api/excel.workbook)对象.
 一个workbook里可以有多张表,可以通过遍历 `workbook.Sheets` 或者 使用提供的 `SheetNames`去访问对应的表.
 Sheet内部是用对象来标注的,比如一个3*2的表单,就会有 `A1,A2,A3,B1,B2,B3`,访问的时候可以直接根据单元格去访问.
 js要读表的话,最方便的还是转换成json去访问,单元格的key会被map成header的名称.

* 读xlsx:
```javascript
    const xlsx = require("xlsx");
    const workbook =  xlsx.readFile('a.xlsx')
    for (const sheet in workbook.Sheets) {
        console.log(xlsx.utils.sheet_to_json(workbook.Sheets[sheet]))
    }
```

* 写xlsx:
```javascript
    const xlsx = require("xlsx");
    const fs = require("fs");
    const ws = xlsx.utils.json_to_sheet([], { header: ["a","b","c",]});
    const wb = xlsx.utils.book_new();
    xlsx.utils.book_append_sheet(wb, ws, "工作表1");
    const buff = xlsx.write(wb, { type: "buffer", bookType: "xlsx" });
    fs.writeFileSync("a.xlsx", buff, { flag: "w" });
```

* 在网页中读excel
> upload 设置accept为 `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`
然后通过file接口去读取数据
```javascript
    const reader = new FileReader();
    reader.onload = e => {
        const workbook = xlsx.read(e.target.result, { type: 'binary' });
    };
    reader.readAsBinaryString(files[0]);
```

* 在网页中保存data为excel
```javascript
    const ws = xlsx.utils.json_to_sheet(currentData, {header});
    const wb = xlsx.utils.book_new();
    xlsx.utils.book_append_sheet(wb, ws, 'sheetName');
    const wbout = xlsx.write(wb, { bookType: 'xlsx', type: 'array' });
    //调用file-saver保存文件 或者直接调用 xlsx.writeFile
    saveAs(new Blob([wbout], { type: 'application/octet-stream' }), 'WbName.xlsx');
```


