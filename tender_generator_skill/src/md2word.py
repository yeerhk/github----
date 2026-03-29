#你可以直接打开电脑自带的终端 (CMD / PowerShell)，输入：
#python 你的脚本路径.py 任何你想转换的md文件路径.md
#例如：
#python D:\每日脚本-本地不上传\md2word.py E:\AI_Workspace\标书.md
#或者
#python D:\每日脚本-本地不上传\md2word.py C:\Users\Desktop\明天开会要用的报告.md

import markdown
from docx import Document
from bs4 import BeautifulSoup, Tag
import os

def convert_md_to_docx(md_path, docx_path, template_path=None):
    print(f"正在读取毛坯房: {md_path}...")
    # 1. 读取 MD 文件
    with open(md_path, 'r', encoding='utf-8') as f:
        md_text = f.read()
    
    # 2. 把 MD 转换成 HTML (作为中间桥梁)
    html = markdown.markdown(md_text)
    soup = BeautifulSoup(html, 'html.parser')
    
    # 3. 🌟 核心魔法：加载你的精装模板！
    if template_path and os.path.exists(template_path):
        print(f"正在套用精装模板: {template_path}...")
        doc = Document(template_path)
        
        # 【贴心小功能】如果你的模板里本身有占位文字，这里可以自动清空它，只保留样式
        for paragraph in doc.paragraphs:
            p = paragraph._element
            p.getparent().remove(p)
            p._p = p._element = None
    else:
        print("没找到模板，只能建个默认毛坯房了...")
        doc = Document()
    
    # 4. 简单解析并写入 Word
    for element in soup.contents:
        if isinstance(element, Tag):
            if element.name == 'h1':
                doc.add_heading(element.text.strip(), level=1)
            elif element.name == 'h2':
                doc.add_heading(element.text.strip(), level=2)
            elif element.name == 'h3':
                doc.add_heading(element.text.strip(), level=3)
            
            # 👉 修复点 1：处理普通段落里的“软回车”
            elif element.name == 'p':
                # 把一段话按换行符 \n 切成多行
                lines = element.text.split('\n')
                for line in lines:
                    # 只有当这一行有实际文字时，才写入 Word（去掉前后空格）
                    if line.strip(): 
                        doc.add_paragraph(line.strip())
            
            # 👉 修复点 2：顺手增加对 Markdown 列表的支持（标书必备）
            elif element.name in ['ul', 'ol']:
                # 找到列表里的每一项 <li>
                for li in element.find_all('li'):
                    if li.text.strip():
                        # 在前面加个点或序号，当成独立段落写入
                        doc.add_paragraph("• " + li.text.strip())

            
    # 5. 保存精装房
    doc.save(docx_path)
    print(f"🎉 搞定！精装房已交付: {docx_path}")

# 运行转换
if __name__ == "__main__":
    work_dir = r"E:\AI_Workspace"
    md_file = os.path.join(work_dir, "标书.md")
    docx_file = os.path.join(work_dir, "标书.docx")
    
    # 👉 告诉代码你的模板在哪里
    template_file = os.path.join(work_dir, "标书排版模板.docx") 
    
    if os.path.exists(md_file):
        # 把模板路径也传进去
        convert_md_to_docx(md_file, docx_file, template_file)
    else:
        print(f"没找到 {md_file}，请先让 AI 生成哦！")
