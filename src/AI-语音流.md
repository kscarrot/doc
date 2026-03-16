# 语音转文本

## [whisper](https://github.com/ggml-org/whisper.cpp)

### 安装

```bash
xcode-select --install

# 下载项目源码
git clone https://github.com/ggerganov/whisper.cpp.git

# 进入目录
cd whisper.cpp

# 下载 base 模型 (体积小，速度快)
bash ./models/download-ggml-model.sh base

# 或者下载 medium 模型 (推荐，精度和速度平衡)
# bash ./models/download-ggml-model.sh medium
# 目前效果比较好的模型
# bash ./models/download-ggml-model.sh large-v3



# 安装cmake 如果没有
brew install cmake

# -B build 表示生成文件放在 build 文件夹中
cmake -B build


# 开始编译 这一步会编译所有东西，包括 server
cmake --build build --config Release


# 转换样本音频验证功能
./build/bin/whisper-cli -m models/ggml-large-v3.bin -f samples/jfk.wav


# 开启服务
./build/bin/whisper-server -m models/ggml-large-v3.bin --host 127.0.0.1 --port 8080

# 验证服务
curl http://127.0.0.1:8080/inference \
  -H "Content-Type: multipart/form-data" \
  -F file="@samples/jfk.wav" \
  -F response_format="json"
```

### 执行参数

参数详解：

- `-F file="@..."`: `@` 告诉 curl 这是一个文件路径，而不是字符串。

- `-F language="zh"`: 强制指定中文（如果不加，模型会尝试自动检测，但指定后速度更快更准）。

- `-F response_format="text"`: 直接返回纯文本结果（如果你想要时间戳，改成 `json` 或 `srt`）。

- `-F temperature="0.0"`: (可选) 让模型"老实一点"，减少幻觉，适合精准听写。

### 配合 ffmpeg

### 流式调用

## [FunASR](https://github.com/modelscope/FunASR)

官方提供了纯 CPU 版本和基于`Nvidia Docker`的 GPU 版本,有 Nvidia 显卡的可以直接起 Docker 跑 加载好镜像一键启动即可

`Apple Silicon M4` 直接使用官方的 `Docker` 镜像做不了 GPU 加速

这里通过`uv`构建虚拟环境

```bash
# 安装uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# 创建文件夹
mkdir funasr_demo
cd funasr_demo

# 安装python版本
uv venv --python 3.12
# 激活环境
source .venv/bin/activate

# 安装funasr和依赖
uv pip install funasr
uv pip install torch torchvision torchaudio
```

执行代码

```python
from funasr import AutoModel

# 1. 初始化模型
# 第一次运行会自动下载模型（约几百MB），请耐心等待
# device="mps" 是专门给 Mac M4 加速用的，如果报错，改成 "cpu"
print("正在加载模型...")
model = AutoModel(
    model="paraformer-zh",    # 语音识别主模型
    vad_model="fsmn-vad",     # 语音活动检测(切分长语音)
    punc_model="ct-punc",     # 标点恢复
    device="mps",             # M4 芯片建议用 mps，或者用 cpu
)

# 2. 运行识别
print("开始识别...")

# 同文件夹下的demo.wav文件
res = model.generate("demo.wav")

print("\n识别结果：")
print(res)
```

新建一个文件启动即可,第一次会下载模型等待的比较久一点

如果需要`http`服务可以用`fastapi`包装一层

```bash
python start.py
```

# 文本转语音

## CosyVoice

## Edge-TTS

# 全链路调试

# 终端入口

## Siri 快捷指令

## ReSpeaker XVF3800 麦克风阵列接入

## 小米音响接入

https://github.com/idootop/open-xiaoai

## WebRTC 套壳
