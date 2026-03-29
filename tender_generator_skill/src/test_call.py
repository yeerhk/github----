import os
import sys
import subprocess

# 1. 定位各个文件的路径
current_dir = os.path.dirname(os.path.abspath(__file__))
root_dir = os.path.dirname(current_dir)

converter_script = os.path.join(current_dir, "md2word.py")

# 指向你 data 文件夹里已经存在的那个 MD 文件（拿现成的当原材料）
md_file_name = "湖州卫康有害生物防治有限责任公司_项目标书.md"
md_path = os.path.join(root_dir, "data", md_file_name)
docx_path = md_path.replace(".md", ".docx")

print(f"🔧 [检查] 当前使用的 Python 解释器: {sys.executable}")
print(f"📄 [检查] 准备转换的 MD 文件: {md_path}")

# 2. 模拟主程序自动调用
print("\n⚙️ [阶段 3/3] 正在模拟主程序调用转换脚本...")
try:
    # 【修改这里】：去掉 capture_output 和 encoding，让它直接在屏幕上输出
    subprocess.run(
        [sys.executable, converter_script, md_path, docx_path],
        check=True
    )
    
    print("\n✅ [测试成功] 主程序自动调用逻辑完美运行！快去 data 文件夹看 Word 吧！")
    
except subprocess.CalledProcessError as e:
    print("\n❌ [测试失败] 调用出错了！")
except FileNotFoundError:
    print(f"\n❌ [错误] 找不到 MD 文件，请检查 data 文件夹下是否有：{md_file_name}")
