import os
import re
import sys
import time
import subprocess
from openai import OpenAI
from dotenv import load_dotenv

# ==========================================
# 1. 初始化与配置加载
# ==========================================
print("🔄 [初始化] 正在加载环境变量...")
load_dotenv()

api_key = os.getenv("OPENAI_API_KEY")
base_url = os.getenv("OPENAI_BASE_URL")
model_name = os.getenv("MODEL_NAME") or "qwen3.5-flash-2026-02-23"

if not api_key:
    raise ValueError("❌ 致命错误：未找到 OPENAI_API_KEY，请检查 .env 文件！")
if not base_url:
    raise ValueError("❌ 致命错误：未找到 OPENAI_BASE_URL，请检查 .env 文件！")

print(f"✅ [初始化] 成功连接配置。当前使用模型: {model_name}")

client = OpenAI(
    api_key=api_key, 
    base_url=base_url,
    timeout=120.0
)

# ==========================================
# 2. 核心功能函数
# ==========================================
def load_prompt_template(filepath):
    """加载 Skill 提示词模板"""
    print(f"📂 [读取] 正在加载提示词模板: {os.path.basename(filepath)}")
    with open(filepath, "r", encoding="utf-8") as f:
        return f.read()

def generate_tender(company_name, tender_requirements, prompt_path):
    print(f"\n🚀 [阶段 1/3] 准备呼叫 AI 大脑...")
    system_prompt = load_prompt_template(prompt_path)
    user_prompt = f"企业名称: {company_name}\n招标要求: {tender_requirements}"
    
    print(f"📡 [网络] 正在发送请求到大模型 ({model_name})...")
    print(f"🧠 [思考] AI 正在仔细阅读 {len(tender_requirements)} 字的招标文件...")
    print("⏳ 请耐心等待 10~30 秒，不要关闭窗口...")
    
    # 记录开始思考的时间
    start_time = time.time()
    
    response = client.chat.completions.create(
        model=model_name,
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt}
        ],
        temperature=0.3,
        stream=True  # 开启流式传输
    )
    
    raw_md = ""
    is_first_word = True # 标记是否是第一个字
    
    # 循环接收 AI 吐出来的每一个字
    for chunk in response:
        # 提取当前片段的内容
        if chunk.choices[0].delta.content is not None:
            # 如果是 AI 吐出的第一个字，打印一下它思考了多久
            if is_first_word:
                think_time = time.time() - start_time
                print(f"💡 [搞定] 思考完毕！(耗时: {think_time:.1f} 秒)")
                print("\n✍️  [生成] AI 开始撰写标书：")
                print("="*60)
                is_first_word = False
                
            content = chunk.choices[0].delta.content
            print(content, end="", flush=True) 
            raw_md += content 
            
    print("\n" + "="*60)
    print("✅ [生成] AI 撰写完毕！")
  
    cleaned_md = re.sub(r'^```markdown\n|```$', '', raw_md, flags=re.MULTILINE).strip()
    return cleaned_md

def save_and_convert(markdown_content, output_filename, output_dir):
    """保存 MD 文件并转换为 Word"""
    os.makedirs(output_dir, exist_ok=True)
    
    md_path = os.path.join(output_dir, f"{output_filename}.md")
    docx_path = os.path.join(output_dir, f"{output_filename}.docx")
    
    print(f"\n💾 [阶段 2/3] 正在保存 Markdown 文件...")
    with open(md_path, "w", encoding="utf-8") as f:
        f.write(markdown_content)
    print(f"✅ [保存] Markdown 文件已存至: {md_path}")
        
    print(f"\n⚙️ [阶段 3/3] 正在转换为 Word 文档...")
    converter_script = os.path.join(os.path.dirname(__file__), "md2word.py")
    try:
        subprocess.run([sys.executable, converter_script, md_path, docx_path], check=True)
        print(f"🎉 [大功告成] Word 标书已生成！文件位置: {docx_path}")
    except subprocess.CalledProcessError as e:
        print(f"❌ [错误] Word 转换失败: {e}")

# ==========================================
# 3. 主程序执行逻辑
# ==========================================
if __name__ == "__main__":
    print("\n" + "*"*50)
    print(" 🤖 自动化标书生成系统启动 ")
    print("*"*50 + "\n")

    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    data_dir = os.path.join(base_dir, "data")
    prompt_file = os.path.join(base_dir, "prompt", "tender_writer_skill.md")
    
    # 读取企业名称
    company_file = os.path.join(data_dir, "投标企业.txt")
    if not os.path.exists(company_file):
        raise FileNotFoundError(f"❌ 找不到文件: {company_file}")
    
    with open(company_file, "r", encoding="utf-8") as f:
        company = f.read().strip()
    print(f"🏢 [数据] 成功读取投标企业: 【{company}】")
        
    # 智能寻找招标文件
    tender_file = None
    for filename in os.listdir(data_dir):
        if filename.endswith(".txt") and filename != "投标企业.txt":
            tender_file = os.path.join(data_dir, filename)
            break
            
    if not tender_file:
        raise FileNotFoundError("❌ 在 data 目录下没有找到招标文件！请放入 txt 格式的招标文件。")
        
    with open(tender_file, "r", encoding="utf-8") as f:
        requirements = f.read().strip()
    
    # 打印一下读取了多少字，心里有数
    print(f"📄 [数据] 成功读取招标文件: 【{os.path.basename(tender_file)}】 (共 {len(requirements)} 字)")
    
    # 执行生成
    md_text = generate_tender(company, requirements, prompt_file)
    
    # 保存与转换
    if md_text:
        output_name = f"{company}_项目标书"
        save_and_convert(md_text, output_name, data_dir)
