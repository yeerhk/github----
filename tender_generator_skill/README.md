# Tender Generator Skill (标书自动生成智能体)

这是一个基于大语言模型（LLM）和 Pandoc 的自动化文档生产流水线。它可以根据输入的“企业名称”和“招标要求”，自动构思、撰写并排版成一份结构严谨的 Markdown 标书，最后自动转换为通用的 Word (.docx) 格式。

## 📁 目录结构

- `prompt/`
  - `tender_writer_skill.md`: 核心 AI 大脑（Skill Prompt），定义了标书撰写专家的角色、工作流和约束。
- `src/`
  - `generate_tender.py`: 主控制流脚本，负责调用 LLM API、清洗数据并串联转换流程。
  - `md2word.py`: 格式转换工具，封装了 Pandoc 命令，负责将 Markdown 转换为精装 Word 文档。
- `output/`: (运行后自动生成) 存放生成的 .md 和 .docx 标书文件。

## 🚀 快速开始

### 1. 环境准备
- 安装 Python 依赖: 
  ```bash
  pip install -r requirements.txt
  ```
- 安装 Pandoc (用于 Markdown 转 Word): 
  - 前往 [Pandoc 官网](https://pandoc.org/installing.html) 下载并安装。

### 2. 配置 API Key
在运行前，请在终端或系统环境变量中设置你的 OpenAI API Key (或兼容接口配置):
```bash
# Windows (CMD)
set OPENAI_API_KEY=your_api_key_here

# Linux / macOS
export OPENAI_API_KEY="your_api_key_here"
```

### 3. 运行生成流水线
```bash
cd src
python generate_tender.py
```

## 💡 进阶玩法 (Pro-Tips)
如果你希望生成的 Word 文档拥有你们公司专属的字体、字号、页眉页脚（例如红头文件样式），请：
1. 在项目根目录放置一个标准的 `template.docx`。
2. 打开 `src/md2word.py`，取消注释 `--reference-doc` 相关的代码。
Pandoc 转换时会自动套用该模板的样式，实现真正的“一键出稿”。
