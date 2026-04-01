
> 如何快速在本地跑起来能用的语音识别和语音合成大模型

# 语音识别(ASR)

> ASR 是 Automated Speech Recognition 的缩写，中文通常称为 “自动语音识别”。简单来说，ASR 的核心任务就是让计算机“听懂”人类的话，并将其转化为对应的文字。它是实现人机交互的关键技术之一。

## [whisper](https://github.com/ggml-org/whisper.cpp)

> Whisper 是由 OpenAI 发布的通用大模型语音识别模型，在多语言泛化、复杂环境鲁棒性以及翻译能力上表现卓越

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

## [FunASR](https://github.com/modelscope/FunASR)

> FunASR 是阿里巴巴达摩院推出的工业级语音识别框架，通过 Paraformer 等非自回归模型，在中文识别精度、推理效率以及热词定制等生产场景下极具优势。

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

# 语音合成(TTS)

> TTS 是 Text-to-Speech（从文本到语音）的缩写，也就是我们常说的“语音合成”技术。简单来说，它的任务就是让计算机、手机或其他智能设备像人一样开口说话，把屏幕上的文字变成可以听见的音频。

## say

苹果系统自带语音播报功能

可以直接使用`say`指令触发

常用来做异步任务的回调提醒

```bash
# 更新完成后提醒
brew update && say "更新已完成"

# 倒计时播报
for i in {5..1}; do
  echo "倒计时 $i..."
  say "$i"
done
say "测试完毕！"
```

可以在系统配置切换音色

1. 打开 系统设置
2. 找到 辅助功能 => 阅读与朗读
3. 点击 系统声音 下拉菜单，在子菜单选择并下载对应音色即可

```bash
# 查看可用音色
say -v "?"
# 指定音色播报
say -v Tingting "测试"
# 可以保存为 aiff的文件形式
say -v Tingting "这段话会被保存到文件里" -o output.aiff
```

在网页端也可以通过内置的方法进行播报

```javascript
window.speechSynthesis.speak(
  new SpeechSynthesisUtterance("我是网页里的语音测试"),
);
```

如果是edge浏览器 可以直接使用edge本身自带的朗读功能,调用云端的播报,完成度更好

- 按住 `Command + Shift + U` 会立即从当前页面的顶部开始朗读。
- 在网页任意位置点击右键，选择 “大声朗读”。

或者直接使用脚本触发
```javascript
// 1. 创建语音合成实例
const utterance = new SpeechSynthesisUtterance("你好，我是 Edge 浏览器的原生语音助手。");

// 2. 设置属性 (可选)
utterance.rate = 1.0;  // 语速：0.1 到 10
utterance.pitch = 1.0; // 音高：0 到 2
utterance.volume = 1.0; // 音量：0 到 1

// 3. 执行播放
window.speechSynthesis.speak(utterance);
```

## [CosyVoice](https://github.com/FunAudioLLM/CosyVoice)

> CosyVoice 是由阿里巴巴通义实验室（Tongyi Lab）开发的开源大规模语音生成模型，。它专注于高质量的语音合成（TTS）、声音复刻（Voice Cloning）和多语言转换。

```bash
git clone --recursive https://github.com/FunAudioLLM/CosyVoice.git
cd CosyVoice

uv venv --python 3.10
source .venv/bin/activate

# onnxruntime 只有cuda版本构建 不支持mac 需要用不安全匹配测量安装依赖
# 有cuda依赖的非m系cpu直接安装应该是没有报错的
uv pip install -r requirements.txt --index-strategy unsafe-best-match
# mac环境安装时会跳过 matcha-tts 补一下安装
uv pip install matcha-tts --index-strategy unsafe-best-match
# 验证一下核心依赖的安装情况
python3 -c "import torch; import torchaudio; import modelscope; import matcha; print('✅ 环境正常')"

# 下载模型
mkdir -p pretrained_models
python3 -c "from modelscope import snapshot_download; snapshot_download('iic/CosyVoice2-0.5B', local_dir='pretrained_models/CosyVoice2-0.5B')"

# 启动 中途可能还有一些版本依赖的问题,按照报错提示处理即可
python3 webui.py --port 50000 --model_dir pretrained_models/CosyVoice2-0.5B
# 访问 http://localhost:50000/
```
