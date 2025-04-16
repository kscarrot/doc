# pyenv

```bash
# 查看本地python版本
python --version
# 选择虚拟版本
# 执行 venv
pyenv local 3.11.8
python -m venv venv
# 激活虚拟环境
source venv/bin/activate
# 安装所需的包
pip install numexpr

# 退出虚拟环境
deactivate

# 取消pyenv绑定
pyenv local --unset
```