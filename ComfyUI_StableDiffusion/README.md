# AI画像生成
 - WSL上にComtyUIを起動して、webブラウザからワークフローを作成して画像を生成する
 - Stable Diffusion 任意のモデル
 - 背景透過: [BEN2](https://github.com/DoctorDiffusion/ComfyUI-BEN)

# 環境

OS: Ubuntu 24.04 (WSL, Host:Windows 11 Home)
GPU: Radeon RX 9600XT 16GB
MEM: DDR5-5600 64GB (32GB x2)
Python 3.12.3 (WSL, venv)

# インストール

## Python
pythonはインストール済みの3.12を利用, venvで仮想環境だけ作成

## ROCmインストール

[ROCm公式ドキュメント (WSL用Radeon)](https://rocm.docs.amd.com/projects/radeon/en/latest/docs/install/wsl/install-radeon.html)


## Pytorch

[ROCm公式ドキュメント (WSL用Pytorch)](https://rocm.docs.amd.com/projects/radeon/en/latest/docs/install/wsl/install-pytorch.html)

## ComfyUI

[ComfyUI GitHub](https://github.com/comfyanonymous/ComfyUI)


### モデル

- モデル
ComfyUI/models/checkpoints/
にHuggingFaceからダウンロードした.safetensorsを配置

- VAE
ComfyUI/models/vae
SD1.5系のVAEを配置

- BEN2ノードの追加
ComfyUI/custom_nodes/

# JSON

ComfyUIからエクスポートしたワークフロー設定
