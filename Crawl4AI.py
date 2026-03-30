import asyncio
import os
import re
import urllib.request
from urllib.parse import urlparse
from crawl4ai import AsyncWebCrawler

# ==========================================
# 工具 1：Markdown 清洗成纯文本
# ==========================================
def clean_markdown_to_text(md_text):
    if not md_text:
        return ""
    text = re.sub(r'!\[.*?\]\(.*?\)', '', md_text)
    text = re.sub(r'\[([^\]]+)\]\([^)]+\)', r'\1', text)
    text = re.sub(r'\n{3,}', '\n\n', text)
    return text.strip()

# ==========================================
# 工具 2：[黑客视角] 从 Next.js 底层源码提取所有路由
# ==========================================
def get_all_zh_urls():
    print("🕵️ [黑客视角] 正在从网页底层源码提取所有隐藏链接...")
    base_url = "https://code.claude.com/docs/zh-CN"
    
    try:
        # 伪装成正常浏览器访问主页
        req = urllib.request.Request(base_url, headers={'User-Agent': 'Mozilla/5.0'})
        response = urllib.request.urlopen(req).read().decode('utf-8')
        
        # 核心逻辑：用正则匹配 Next.js 底层 JSON 数据中的所有页面路径
        paths = set()
        
        # 匹配形如 "en/amazon-bedrock" 或 "zh-CN/amazon-bedrock" 的底层数据
        for match in re.finditer(r'\\?["\']((?:en|zh-CN)/[a-zA-Z0-9_-]+)\\?["\']', response):
            path = match.group(1)
            # 官方源码里有些路径是 en 开头的，我们强制把它替换成 zh-CN 中文版
            if path.startswith("en/"):
                path = path.replace("en/", "zh-CN/")
            paths.add(path)
            
        # 拼接成完整的网址
        urls = [f"https://code.claude.com/docs/{p}" for p in paths]
        
        # 把首页自己也加进去
        if base_url not in urls:
            urls.append(base_url)
            
        return list(set(urls))
    except Exception as e:
        print(f"❌ 读取源码失败: {e}")
        return []

# ==========================================
# 主程序
# ==========================================
async def main():
    save_dir = r"E:\github公开仓库\Claude_Knowledge_Base_ZH" 
    os.makedirs(save_dir, exist_ok=True)

    # 1. 直接从源码里扒出所有链接
    urls_to_crawl = get_all_zh_urls()
    
    if not urls_to_crawl:
        print("⚠️ 没找到链接，请检查网络。")
        return

    # 剧透一下：正常情况下这里会发现 70+ 个隐藏页面！
    print(f"🎯 破解成功！从网页底层源码中发现了 {len(urls_to_crawl)} 个中文文档页面。")
    print("⏳ 开始批量抓取并清洗为 TXT，请稍等...")
    print("-" * 50)

    # 2. 启动爬虫
    async with AsyncWebCrawler(verbose=False) as crawler:
        for index, url in enumerate(urls_to_crawl, start=1):
            print(f"[{index}/{len(urls_to_crawl)}] 正在抓取: {url}")
            
            try:
                result = await crawler.arun(
                    url=url,
                    word_count_threshold=10,
                    extraction_strategy="Basic",
                    bypass_cache=False
                )
                
                if result.markdown:
                    # 清洗成纯文本
                    pure_text = clean_markdown_to_text(result.markdown)
                    
                    # 生成文件名
                    parsed_url = urlparse(url)
                    path = parsed_url.path.strip("/")
                    
                    if path == "docs/zh-CN":
                        filename = "docs_zh-CN_overview.txt"
                    else:
                        filename = path.replace("/", "_") + ".txt"
                        
                    full_path = os.path.join(save_dir, filename)
                    
                    # 保存文件
                    with open(full_path, "w", encoding="utf-8") as f:
                        f.write(pure_text)
                    print(f"  └─ ✅ 成功保存 -> {filename}")
                else:
                    print(f"  └─ ⚠️ 页面无有效内容，跳过。")
                    
            except Exception as e:
                print(f"  └─ ❌ 抓取失败: {str(e)}")
            
            await asyncio.sleep(1)

        print("-" * 50)
        print(f"🎉 大功告成！所有中文页面的纯净版 TXT 已保存至 {save_dir}")

if __name__ == "__main__":
    asyncio.run(main())
