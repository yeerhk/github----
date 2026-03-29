import os
import re
import sys
import time
import json
import requests
import subprocess
from typing import Any
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

if not api_key or not base_url:
    raise ValueError("❌ 致命错误：未找到 OPENAI_API_KEY 或 BASE_URL，请检查 .env 文件！")

print(f"✅ [初始化] 成功连接配置。当前使用模型: {model_name}")

client = OpenAI(
    api_key=api_key, 
    base_url=base_url,
    timeout=120.0
)

# ==========================================
# 2. 核心功能函数 (新增联网搜索)
# ==========================================
def execute_web_search(query: str) -> str:
    """底层的 SearXNG 搜索逻辑"""
    base_url = os.getenv("SEARXNG_BASE_URL")
    user = os.getenv("SEARXNG_USER")
    pwd = os.getenv("SEARXNG_PASS")
    
    if not base_url:
        return "错误: 请在 .env 文件中配置 SEARXNG_BASE_URL"
        
    search_url = f"{base_url.rstrip('/')}/search"
    params = {"q": query, "format": "json"}
    auth = (user, pwd) if user and pwd else None
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36"
    }
    
    try:
        response = requests.get(search_url, params=params, headers=headers, auth=auth, timeout=15)
        response.raise_for_status()
        results = response.json().get("results", [])
        
        if not results:
            return f"未找到关于 '{query}' 的搜索结果。"
            
        output = [f"找到关于 '{query}' 的前 5 条结果：\n"]
        for i, res in enumerate(results[:5]):
            output.append(f"{i+1}. 标题: {res.get('title')}\n   摘要: {res.get('content')}\n")
        return "\n".join(output)
    except Exception as e:
        return f"搜索失败: {str(e)}"

# 定义给 AI 看的工具说明书
# 🌟 加上 : list[Any] ，给它发一张免死金牌
tools: list[Any] = [
    {
        "type": "function",
        "function": {
            "name": "search_web",
            "description": "当需要获取企业真实背景、最新动态、主营业务等信息时，使用此工具进行联网搜索。",
            "parameters": {
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "搜索关键词，例如 'XX公司 简介' 或 'XX公司 主营业务'"
                    }
                },
                "required": ["query"]
            }
        }
    }
]


def load_prompt_template(filepath):
    print(f"📂 [读取] 正在加载提示词模板: {os.path.basename(filepath)}")
    with open(filepath, "r", encoding="utf-8") as f:
        return f.read()

def generate_tender(company_name, tender_requirements, prompt_path):
    print(f"\n🚀 [阶段 1/3] 准备呼叫 AI 大脑...")
    system_prompt = load_prompt_template(prompt_path)
    user_prompt = f"企业名称: {company_name}\n招标要求: {tender_requirements}"
    
    # 🌟 终极修复：明确告诉 Pylance 这个列表可以装任何格式的字典
    messages: list[Any] = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": user_prompt}
    ]
    
    print(f"📡 [网络] 正在发送请求到大模型 ({model_name})...")
    print(f"🧠 [思考] AI 正在阅读招标文件，并评估是否需要联网搜索企业背景...")
    start_time = time.time()
    
    # 【第一轮对话】：不开启流式，让 AI 决定是否调用工具
    response = client.chat.completions.create(
        model=model_name,
        messages=messages,
        tools=tools,
        tool_choice="auto",
        temperature=0.3
    )
    
    response_msg = response.choices[0].message
    
    # 检查 AI 是否决定使用搜索工具
    if response_msg.tool_calls:
        print("🔍 [联网] AI 决定查阅资料，正在启动 SearXNG 引擎...")
        
        # 🌟 官方推荐写法：使用 model_dump 将对象安全地转为字典，并剔除空值
        # 🌟 修复国内大模型（如 Qwen）的兼容性：必须手动保留 content 字段，哪怕是空字符串
        messages.append({
            "role": "assistant",
            "content": response_msg.content or "",
            "tool_calls": [
                {
                    "id": t.id,
                    "type": "function",
                    "function": {
                        "name": t.function.name,          # type: ignore
                        "arguments": t.function.arguments # type: ignore
                    }
                } for t in response_msg.tool_calls
            ]
        })


        
        for tool_call in response_msg.tool_calls:
            # 🌟 提取 function 属性，并用魔法注释让 Pylance 闭嘴跳过检查
            func = tool_call.function  # type: ignore
            
            if func.name == "search_web":
                args_str = func.arguments or "{}"
                args = json.loads(args_str)
                query = args.get("query", "")
            
                if query:
                    print(f"👉 正在搜索: 【{query}】")
                    search_result = execute_web_search(query)
                
                # 🌟 【新增这一行】把搜索结果的前 300 个字打印出来，看看里面有没有法人和代码
                    print(f"📦 搜索结果预览: {str(search_result)[:300]}...")

                    
                    messages.append({
                        "role": "tool",
                        "tool_call_id": tool_call.id,
                        "content": str(search_result)
                    })
                
        print("💡 [搞定] 资料收集完毕！AI 开始整合信息...")
        
        # 【第二轮对话】：开启流式输出
        # 此时 messages 的类型是 list[Any]，Pylance 绝对不会再报错了
        final_response = client.chat.completions.create(
            model=model_name,
            messages=messages,
            temperature=0.3,
            stream=True
        )
        return process_stream_output(final_response, start_time)
        
    else:
        print("💡 [搞定] AI 认为现有信息充足，无需联网！")
        return process_simulated_stream(response_msg.content or "", start_time)



def process_stream_output(response, start_time):
    """处理真实的流式输出"""
    raw_md = ""
    is_first_word = True
    for chunk in response:
        if chunk.choices[0].delta.content is not None:
            if is_first_word:
                print(f"\n✍️  [生成] AI 开始撰写标书 (耗时: {time.time() - start_time:.1f} 秒)：")
                print("="*60)
                is_first_word = False
            content = chunk.choices[0].delta.content
            print(content, end="", flush=True) 
            raw_md += content 
    print("\n" + "="*60)
    print("✅ [生成] AI 撰写完毕！")
    return re.sub(r'^```markdown\n|```$', '', raw_md, flags=re.MULTILINE).strip()

def process_simulated_stream(content, start_time):
    """模拟流式打字机效果（当未调用工具时使用）"""
    print(f"\n✍️  [生成] AI 开始撰写标书 (耗时: {time.time() - start_time:.1f} 秒)：")
    print("="*60)
    for char in content:
        print(char, end="", flush=True)
        time.sleep(0.005) # 极速打字机效果
    print("\n" + "="*60)
    print("✅ [生成] AI 撰写完毕！")
    return re.sub(r'^```markdown\n|```$', '', content, flags=re.MULTILINE).strip()

def save_and_convert(markdown_content, output_filename, output_dir):
    """保存 MD 文件并转换为 Word (保持不变)"""
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
# 3. 主程序执行逻辑 (保持不变)
# ==========================================
if __name__ == "__main__":
    print("\n" + "*"*50)
    print(" 🤖 自动化标书生成系统启动 (增强联网版) ")
    print("*"*50 + "\n")

    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    data_dir = os.path.join(base_dir, "data")
    prompt_file = os.path.join(base_dir, "prompt", "tender_writer_skill.md")
    
    company_file = os.path.join(data_dir, "投标企业.txt")
    if not os.path.exists(company_file):
        raise FileNotFoundError(f"❌ 找不到文件: {company_file}")
    
    with open(company_file, "r", encoding="utf-8") as f:
        company = f.read().strip()
    print(f"🏢 [数据] 成功读取投标企业: 【{company}】")
        
    tender_file = None
    for filename in os.listdir(data_dir):
        if filename.endswith(".txt") and filename != "投标企业.txt":
            tender_file = os.path.join(data_dir, filename)
            break
            
    if not tender_file:
        raise FileNotFoundError("❌ 在 data 目录下没有找到招标文件！请放入 txt 格式的招标文件。")
        
    with open(tender_file, "r", encoding="utf-8") as f:
        requirements = f.read().strip()
    
    print(f"📄 [数据] 成功读取招标文件: 【{os.path.basename(tender_file)}】 (共 {len(requirements)} 字)")
    
    md_text = generate_tender(company, requirements, prompt_file)
    
    if md_text:
        output_name = f"{company}_项目标书"
        save_and_convert(md_text, output_name, data_dir)
