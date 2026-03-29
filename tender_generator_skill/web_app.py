import gradio as gr
import shutil
import os

# ==========================================
# 第一步：定义你的专属目录（你可以随便改路径）
# ==========================================
# 比如把文件保存在代码运行的同级目录下
UPLOAD_DIR = "./data"     # 存放用户上传的源文件
OUTPUT_DIR = "./data"    # 存放脚本处理后生成的文件

# 确保这两个文件夹存在，如果没有，Python会自动帮你创建
os.makedirs(UPLOAD_DIR, exist_ok=True)
os.makedirs(OUTPUT_DIR, exist_ok=True)

# ==========================================
# 第二步：核心处理逻辑（函数参数必须和UI输入一一对应）
# ==========================================
def process_file_and_text(uploaded_file, user_text):
    """
    uploaded_file: 对应界面的“文件上传”组件
    user_text: 对应界面的“文本框”组件
    """
    # 1. 防御性编程：防止用户没传文件就点提交报错
    if uploaded_file is None:
        return None

    # 2. 获取原文件名，并把它保存到你指定的目录
    # uploaded_file.name 是临时文件的绝对路径
    original_filename = os.path.basename(uploaded_file.name) 
    save_path = os.path.join(UPLOAD_DIR, original_filename)
    
    # 把临时文件拷贝到你的专属目录
    shutil.copy(uploaded_file.name, save_path)
    
    print(f"✅ 文件已成功保存到: {save_path}")
    print(f"✅ 接收到用户输入的指令: {user_text}")

    # ==========================================
    # 第三步：在这里执行你的 AI 脚本 / 核心逻辑！
    # 你现在可以使用 save_path (文件路径) 和 user_text (用户文字) 来做处理了
    # ==========================================
    
    # 这里我们用代码“模拟”一下你的脚本生成了一个新文件
    # 假设你的脚本根据用户的图片和文字，生成了一个包含了处理结果的 txt 文件
    generated_filename = f"result_for_{original_filename}.txt"
    generated_file_path = os.path.join(OUTPUT_DIR, generated_filename)

    # 写入一些模拟内容到生成的文件中
    with open(generated_file_path, "w", encoding="utf-8") as f:
        f.write(f"【AI 处理报告】\n")
        f.write(f"你上传的文件名是: {original_filename}\n")
        f.write(f"你输入的指令是: {user_text}\n")
        f.write(f"处理状态: 成功！")

    print(f"🎉 处理完成，生成文件: {generated_file_path}")

    # 4. 把生成的文件路径返回，Gradio会自动把它变成下载按钮！
    return generated_file_path

# ==========================================
# 第四步：搭建 UI 界面
# ==========================================
demo = gr.Interface(
    fn=process_file_and_text,
    
    # inputs 改为一个列表，包含两个组件：文件和文本
    inputs=[
        gr.File(label="1. 请上传你的源文件"),
        gr.Textbox(label="2. 请输入提示词/参数", placeholder="例如：帮我把这张图片变成赛博朋克风格...", lines=3)
    ],
    
    # outputs 保持不变，接收生成的文件
    outputs=gr.File(label="3. 点击下载生成的文件"),
    
    title="我的 AI 自动化处理工具",
    description="上传文件并输入指令，系统会自动将文件保存到指定目录，运行脚本后返回结果供下载。"
)

if __name__ == "__main__":
    # 注意看你的截图，你用的端口是 1860，我这里帮你保留了
    demo.launch(server_name="0.0.0.0", server_port=1860)
