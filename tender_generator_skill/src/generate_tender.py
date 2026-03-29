import os
import re
import subprocess
from openai import OpenAI
from dotenv import load_dotenv

# 🚀 核心动作：在程序一启动时，立刻加载 .env 文件中的变量到系统环境变量中
load_dotenv()

# 现在，你可以安全地从环境变量中读取 Key 了
# os.getenv 会自动去系统环境变量（包括刚才 .env 加载进来的）里找对应的值
api_key = os.getenv("OPENAI_API_KEY")
base_url = os.getenv("OPENAI_BASE_URL")

if not api_key:
    raise ValueError("❌ 致命错误：未找到 OPENAI_API_KEY，请检查 .env 文件是否配置正确！")

# 初始化客户端
client = OpenAI(
    api_key=api_key, 
    base_url=base_url
)
def load_prompt_template(filepath):
    """加载 Skill 提示词模板"""
    with open(filepath, "r", encoding="utf-8") as f:
        return f.read()

def generate_tender(company_name, tender_requirements, prompt_path):
    print("🚀 [1/3] 正在呼叫 AI 大脑撰写标书...")
    
    # 读取系统提示词 (Skill Definition)
    system_prompt = load_prompt_template(prompt_path)
    
    # 构建用户输入
    user_prompt = f"企业名称: {company_name}\n招标要求: {tender_requirements}"
    
    response = client.chat.completions.create(
        model="gpt-4o", # 可替换为本地大模型，如 qwen2.5-72b-instruct
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt}
        ],
        temperature=0.3 # 标书需要严谨，降低温度值以减少幻觉
    )
    
    raw_md = response.choices[0].message.content
    # 增加防御性判断，告诉 Pylance 我们处理了 None 的情况
    if raw_md is None:
      print("❌ 警告：大模型返回了空内容！")
      return "" # 或者抛出异常 raise ValueError("API returned None")
  
    # 清洗 Markdown 内容 (防止大模型输出 ```markdown ... ``` 导致排版错误)
    cleaned_md = re.sub(r'^```markdown\n|```$', '', raw_md, flags=re.MULTILINE).strip()
    return cleaned_md

def save_and_convert(markdown_content, output_filename="tender"):
    # 确保输出目录存在
    output_dir = os.path.join(os.path.dirname(__file__), "..", "output")
    os.makedirs(output_dir, exist_ok=True)
    
    md_path = os.path.join(output_dir, f"{output_filename}.md")
    docx_path = os.path.join(output_dir, f"{output_filename}.docx")
    
    print(f"💾 [2/3] 正在将标书保存为 Markdown 文件: {md_path}")
    with open(md_path, "w", encoding="utf-8") as f:
        f.write(markdown_content)
        
    print(f"⚙️ [3/3] 正在调用本地脚本转换为 Word 文档: {docx_path}")
    
    # 调用本地转换脚本 md2word.py
    converter_script = os.path.join(os.path.dirname(__file__), "md2word.py")
    try:
        subprocess.run(["python", converter_script, md_path, docx_path], check=True)
        print(f"✅ 任务完成！标书已就绪，保存在: {docx_path}")
    except subprocess.CalledProcessError as e:
        print(f"❌ 转换失败: {e}")

if __name__ == "__main__":
    # 示例运行
    company = "星辰人工智能科技有限公司"
    requirements = "1. 需要一套私有化部署的大模型问答系统；2. 支持至少1000人并发；3. 要求包含详细的硬件拓扑图规划和售后培训方案。"
    
    prompt_file = os.path.join(os.path.dirname(__file__), "..", "prompt", "tender_writer_skill.md")
    
    md_text = generate_tender(company, requirements, prompt_file)
    save_and_convert(md_text, "星辰科技_大模型项目标书")
