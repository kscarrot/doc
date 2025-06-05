# 图片优化

## 图片格式优化

- 对于照片类图片：优先使用 `WebP`(压缩率高)，不支持时降级到 `JPG`(兼容性好)
- 对于图标、Logo 等：使用 `SVG`(内联引入) 或 `PNG`(优先过一遍[tinypng](https://tinify.cn/))
- 对于动画：使用 `WebP` 或 `GIF`
- 特别小的图片可以考虑内联成`base64`进行载入

  ```html
  <img src="data:image/svg+xml;base64,[data]" />
  ```

  ```css
  /* 小图标使用 base64 */
  .icon {
    background-image: url("data:image/png;base64,...");
  }
  ```

- 以 `UI` 设计和产品需求优先,如果资源尺寸过大需要找`UI`确认导出质量是否合适

- 构建工具配置合适的压缩比例
  比如`vite-plugin-imagemin`

## 静态资源使用 CDN

- 使用 `CDN`(OSS 服务) 加速图片加载
  `CD` 工作流上传静态资源 `assert`到图床
- 结合 `window.devicePixelRatio` 和屏幕尺寸请求最佳图床尺寸

```javascript
// 可以通过以下方式获取设备像素比
const dpr = window.devicePixelRatio || 1;
// 结合屏幕宽度计算最佳图片尺寸
const screenWidth = window.innerWidth;
const optimalWidth = Math.round(screenWidth * dpr);
// 更新图片的 src 属性，添加 CDN 参数
<source
  srcset={`${originalSrc}?x-oss-process=image/resize,w_${optimalWidth}`}
  type="image/jpeg"
/>;
```

这样可以确保在高分辨率屏幕上显示清晰图片，同时避免在低分辨率设备上加载过大的图片

## 图片组件

### 响应式

原理:

1.  浏览器会按照 source 标签的顺序依次检查每个 source 元素
2.  检查 type 属性指定的 MIME 类型是否支持
3.  如果支持,则使用该 source 的 srcset 指定的图片
4.  如果所有 source 都不支持,则回退到 img 标签的 src
    '

```html
<picture>
  <source srcset="image.webp" type="image/webp" />
  <source srcset="image.jpg" type="image/jpeg" />
  <!-- 兜底方picture标签时使用 -->
  <img src="image.jpg" alt="描述" />
</picture>
```

进一步的使用 `srcset` 和 `sizes` 属性
根据实际显示尺寸提供图片

```html
<img
  src="small.jpg"
  srcset="small.jpg 300w, medium.jpg 600w, large.jpg 900w"
  sizes="(max-width: 300px) 300px,
            (max-width: 600px) 600px,
            900px"
  alt="响应式图片"
/>
```

### 懒加载

原理:

1.  使用 `loading="lazy"` 属性实现原生懒加载
2.  `data-src` 存储实际图片地址
3.  `src` 属性使用占位图
4.  当图片进入视口时,浏览器自动将 `data-src` 的值赋给 `src`

```html
<img
  src="placeholder.jpg"
  data-src="actual-image.jpg"
  loading="lazy"
  alt="描述"
/>
```

可以通过 `IntersectionObserver` 实现自定义懒加载

```tsx
// LazyImage.tsx
import { useEffect, useRef, useState } from "react";

interface LazyImageProps {
  src: string;
  alt: string;
  placeholder?: string; //支持自定义占位图
  threshold?: number; //触发阈值
  rootMargin?: string; //rootMargin
}

const LazyImage: React.FC<LazyImageProps> = ({
  src,
  alt,
  placeholder = "data:image/gif;base64...", // 1x1 透明图片
  threshold = 0,
  rootMargin = "50px",
}) => {
  const [isLoaded, setIsLoaded] = useState(false);
  const [isInView, setIsInView] = useState(false);
  const imgRef = useRef<HTMLImageElement>(null);
  const observerRef = useRef<IntersectionObserver | null>(null);

  useEffect(() => {
    // 创建 IntersectionObserver 实例
    observerRef.current = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          // 当图片进入视口时
          if (entry.isIntersecting) {
            setIsInView(true);
            // 停止观察
            observerRef.current?.unobserve(entry.target);
          }
        });
      },
      {
        threshold, // 触发回调的阈值
        rootMargin, // 视口边距
      }
    );

    // 开始观察图片元素
    if (imgRef.current) {
      observerRef.current.observe(imgRef.current);
    }

    // 清理函数
    return () => {
      if (observerRef.current) {
        observerRef.current.disconnect();
      }
    };
  }, [threshold, rootMargin]);

  // 图片加载完成时的处理
  const handleLoad = () => {
    setIsLoaded(true);
  };

  return (
    <div className="lazy-image-container">
      <img
        ref={imgRef}
        src={isInView ? src : placeholder}
        alt={alt}
        onLoad={handleLoad}
        className={`lazy-image ${isLoaded ? "loaded" : "loading"}`}
        style={{
          opacity: isLoaded ? 1 : 0,
          transition: "opacity 0.3s ease-in-out",
        }}
      />
      {!isLoaded && (
        <div className="loading-placeholder">
          <div className="loading-spinner" />
        </div>
      )}
    </div>
  );
};

// 使用示例
const App = () => {
  return (
    <div>
      <LazyImage
        src="https://example.com/large-image.jpg"
        alt="Large image"
        threshold={0.1}
        rootMargin="100px"
      />
    </div>
  );
};
```

### 预加载

反过来,如果是首屏图片,需要高优先加载

```html
<img
  src="hero-image.jpg"
  alt="Hero image"
  loading="eager"
  fetchpriority="high"
/>
```

如果是静态内容,可以使用`link`标签进行预加载

```html
<link rel="preload" as="image" href="hero-image.jpg" />
```

## 缓存策略

静态资源如果在自身服务需要自己设置缓存逻辑

### nginx 配置

```nginx
# 图片缓存配置
location ~* \.(jpg|jpeg|png|gif|ico|webp)$ {
    # 设置缓存时间为30天
    expires 30d;
    # 允许浏览器缓存,但不允许代理服务器修改
    add_header Cache-Control "public, no-transform";
    # 添加ETag支持
    etag on;
    # 添加Last-Modified支持
    if_modified_since exact;
}
```

### node 直接配置

```javascript
// 使用 Koa 中间件配置图片缓存头
app.use(async (ctx, next) => {
  if (ctx.path.startsWith("/images")) {
    //- `Cache-Control: public` - 允许所有用户缓存
    //- `Cache-Control: max-age=xxx` - 缓存时间(秒) 30天
    ctx.set("Cache-Control", "public, max-age=2592000");

    // ETag 用于验证资源是否变化
    // 当浏览器再次请求时,会带上 If-None-Match 头
    // 如果 ETag 匹配,服务器返回 304,浏览器使用缓存
    // 如果 ETag 不匹配,服务器返回 200 和新资源
    // 在 public 缓存策略下,ETag 在以下情况会用到:
    // 1. 缓存过期后,浏览器会发起验证请求
    // 2. 用户强制刷新页面(Ctrl+F5)
    // 3. 资源被修改,但缓存时间未到
    const etag = crypto.createHash("md5").update(ctx.path).digest("hex");
    ctx.set("ETag", etag);
  }
  await next();
});
```

### 静态资源 hash

使用 Vite 内置的静态资源处理

```js
// vite.config.js
export default {
  build: {
    rollupOptions: {
      output: {
        // 使用 contenthash保证相同资源打包的hash值是一致的
        assetFileNames: "assets/[name].[hash][extname]",
      },
    },
  },
};
```

## SEO 优化

- 图片的名称最好有一个简短的描述 且和内容对应
- alt 属性描写图片的替代文本
- svg 需要增加 title 来进行结构化

```html
<img src="puppy.jpg" alt="Dalmatian puppy playing fetch" />
<svg aria-labelledby="svgtitle1">
  <title id="svgtitle1">
    Googlebot wearing an apron and chef hat, struggling to make pancakes on the
    stovetop
  </title>
</svg>
```

## 优化验收

- 使用 Lighthouse 检查图片优化
- 监控图片加载性能
- 分析用户设备特征，优化图片策略
