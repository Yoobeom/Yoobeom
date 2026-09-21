#!/usr/bin/env python3
#-----------------------------------------------------------------------
# File    : build.py
# Author  : youbumkim@gmail.com
# Purpose : Build the cookbook PDF, cover PNG and sales ZIP from manuscript
# Usage   : python3 build/build.py   (run from the product root)
#-----------------------------------------------------------------------
import os, re, sys, glob, subprocess, shutil, zipfile, datetime

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAN  = os.path.join(ROOT, "manuscript")
SCR  = os.path.join(ROOT, "scripts")
OUT  = os.path.join(ROOT, "dist")
CHROME = os.environ.get("CHROME", "/opt/pw-browsers/chromium-1194/chrome-linux/chrome")
TITLE = "PrimeTime Tcl Cookbook"
SUBTITLE = "Production scripts for STA signoff, ECO, and report automation"
VERSION = os.environ.get("BOOK_VERSION", "1.0")
YEAR = datetime.date.today().year

import markdown
from pygments.formatters import HtmlFormatter

def load_manuscript():
    parts = []
    for f in sorted(glob.glob(os.path.join(MAN, "*.md"))):
        txt = open(f, encoding="utf-8").read()
        def inc(m):
            p = os.path.join(SCR, m.group(1))
            code = open(p, encoding="utf-8").read().rstrip("\n")
            return f"\n```tcl\n{code}\n```\n"
        txt = re.sub(r"\{\{include:([^}]+)\}\}", inc, txt)
        parts.append(txt)
    return "\n\n".join(parts)

def build_toc(html):
    items = []
    def repl(m):
        level, attrs, text = m.group(1), m.group(2), m.group(3)
        plain = re.sub(r"<[^>]+>", "", text)
        anchor = re.sub(r"[^a-z0-9]+", "-", plain.lower()).strip("-")
        anchor = f"h{level}-{len(items)}-{anchor}"
        if level in ("1", "2"):
            items.append((level, plain, anchor))
        return f'<h{level} id="{anchor}"{attrs}>{text}</h{level}>'
    html = re.sub(r"<h([1-3])([^>]*)>(.*?)</h\1>", repl, html, flags=re.S)
    toc = ['<nav class="toc"><h1 class="toc-title">Contents</h1><ul>']
    for level, text, anchor in items:
        if text == TITLE or text.startswith("Production scripts"):
            continue
        toc.append(f'<li class="l{level}"><a href="#{anchor}">{text}</a></li>')
    toc.append("</ul></nav>")
    return html, "\n".join(toc)

CSS = """
@page { size: A4; margin: 22mm 20mm 24mm 20mm; }
html { font-size: 10.5pt; }
body { font-family: "DejaVu Serif", Georgia, serif; line-height: 1.45; color: #1a1a1a; margin: 0; }
h1, h2, h3, .toc-title { font-family: "DejaVu Sans", Helvetica, Arial, sans-serif; color: #111; }
h1 { font-size: 22pt; margin: 0 0 14pt 0; padding-bottom: 6pt; border-bottom: 2px solid #222; page-break-before: always; }
h2 { font-size: 14pt; margin: 20pt 0 8pt 0; }
h3 { font-size: 11.5pt; margin: 14pt 0 6pt 0; }
p { margin: 0 0 8pt 0; text-align: left; }
ul, ol { margin: 0 0 8pt 0; padding-left: 20pt; }
li { margin-bottom: 3pt; }
code { font-family: "DejaVu Sans Mono", Menlo, monospace; font-size: 8.6pt; background: #f3f3f3; padding: 0 2px; }
pre { font-family: "DejaVu Sans Mono", Menlo, monospace; font-size: 7.9pt; line-height: 1.32;
      background: #f7f7f5; border: 1px solid #d8d8d3; border-left: 3px solid #555; padding: 7pt 9pt; margin: 8pt 0 12pt 0;
      white-space: pre-wrap; word-wrap: break-word; page-break-inside: auto; }
pre code { background: none; padding: 0; font-size: inherit; }
table { border-collapse: collapse; width: 100%; margin: 6pt 0 12pt 0; font-size: 9pt; page-break-inside: auto; }
th, td { border: 1px solid #bbb; padding: 3pt 6pt; vertical-align: top; text-align: left; }
th { background: #e9e9e6; font-family: "DejaVu Sans", sans-serif; font-weight: bold; }
tr { page-break-inside: avoid; }
strong { font-weight: bold; }
.cover { page-break-after: always; height: 240mm; display: flex; flex-direction: column; justify-content: space-between; }
.cover .band { border-top: 6px solid #111; border-bottom: 1px solid #111; padding: 28mm 0 10mm 0; margin-top: 30mm; }
.cover h1.t { border: none; font-size: 34pt; margin: 0 0 10pt 0; page-break-before: auto; }
.cover .s { font-family: "DejaVu Sans", sans-serif; font-size: 14pt; color: #333; }
.cover .meta { font-family: "DejaVu Sans", sans-serif; font-size: 10pt; color: #444; }
.cover .meta div { margin-bottom: 3pt; }
.toc { page-break-after: always; }
.toc ul { list-style: none; padding: 0; }
.toc li.l1 { font-family: "DejaVu Sans", sans-serif; font-weight: bold; margin-top: 8pt; }
.toc li.l2 { padding-left: 16pt; font-size: 9.5pt; }
.toc a { color: #111; text-decoration: none; }
.toc-title { page-break-before: auto; }
.front h1 { page-break-before: auto; }
.codehilite .err { border: none; background: none; }
@page { @bottom-right { content: counter(page); font-family: "DejaVu Sans", sans-serif; font-size: 9pt; color: #555; } }
.legal { font-size: 8.5pt; color: #555; margin-top: 30mm; }
"""

def html_doc(body, toc):
    hl = HtmlFormatter(style="friendly").get_style_defs(".codehilite")
    cover = f"""
<section class="cover">
  <div class="band">
    <h1 class="t">{TITLE}</h1>
    <div class="s">{SUBTITLE}</div>
  </div>
  <div class="meta">
    <div>41 ready-to-run scripts for pt_shell</div>
    <div>Session setup, path analysis, clock checks, constraint audit, triage, ECO, reporting, DMSA</div>
    <div>Version {VERSION}</div>
  </div>
  <div class="legal">
    Copyright {YEAR}. All rights reserved. This document and the accompanying scripts are licensed to the purchaser
    for use within their own organisation. Redistribution of the document is not permitted. PrimeTime is a trademark
    of Synopsys, Inc. Tempus and Innovus are trademarks of Cadence Design Systems, Inc. This work is not affiliated
    with or endorsed by either company. Scripts are provided as-is; verify results in your own flow before signoff.
  </div>
</section>
"""
    return f"""<!DOCTYPE html>
<html><head><meta charset="utf-8"><title>{TITLE}</title>
<style>{CSS}\n{hl}</style></head>
<body>{cover}{toc}<div class="front">{body}</div></body></html>"""

def main():
    os.makedirs(OUT, exist_ok=True)
    md = load_manuscript()
    body = markdown.markdown(md, extensions=["tables", "fenced_code", "codehilite", "sane_lists"],
                             extension_configs={"codehilite": {"guess_lang": False, "noclasses": False}})
    body, toc = build_toc(body)
    html = html_doc(body, toc)
    html_path = os.path.join(OUT, "primetime-tcl-cookbook.html")
    open(html_path, "w", encoding="utf-8").write(html)

    pdf_path = os.path.join(OUT, "primetime-tcl-cookbook.pdf")
    cmd = [CHROME, "--headless=new", "--no-sandbox", "--disable-gpu", "--no-pdf-header-footer",
           f"--print-to-pdf={pdf_path}", "file://" + html_path]
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    # Cover PNG for store listings (1600x2000, portrait)
    cover_html = os.path.join(OUT, "cover.html")
    open(cover_html, "w", encoding="utf-8").write(cover_page())
    png_path = os.path.join(OUT, "cover.png")
    subprocess.run([CHROME, "--headless=new", "--no-sandbox", "--disable-gpu", "--hide-scrollbars",
                    "--window-size=1600,2000", f"--screenshot={png_path}", "file://" + cover_html],
                   check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    # Sales package: PDF + scripts + README
    zip_path = os.path.join(OUT, "primetime-tcl-cookbook-v%s.zip" % VERSION)
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as z:
        z.write(pdf_path, "primetime-tcl-cookbook.pdf")
        for f in sorted(glob.glob(os.path.join(SCR, "*.tcl"))):
            z.write(f, "scripts/" + os.path.basename(f))
        z.writestr("README.txt", PACKAGE_README)
    print("built:", pdf_path, png_path, zip_path)

def cover_page():
    return f"""<!DOCTYPE html><html><head><meta charset="utf-8"><style>
html,body{{margin:0;width:1600px;height:2000px;background:#f4f2ec;font-family:"DejaVu Sans",sans-serif;color:#141414}}
.w{{position:absolute;left:0;top:0;width:1600px;height:2000px}}
.top{{position:absolute;left:0;top:0;width:1600px;height:70px;background:#141414}}
.t{{position:absolute;left:120px;top:420px;width:1360px;font-size:118px;font-weight:bold;line-height:1.05;letter-spacing:-2px}}
.s{{position:absolute;left:120px;top:760px;width:1300px;font-size:44px;line-height:1.35;color:#333}}
.rule{{position:absolute;left:120px;top:700px;width:220px;height:10px;background:#141414}}
.code{{position:absolute;left:120px;top:1060px;width:1360px;background:#1c1c1c;color:#e6e6e6;font-family:"DejaVu Sans Mono",monospace;font-size:26px;line-height:1.5;padding:40px 48px;box-sizing:border-box;border-radius:4px}}
.code .k{{color:#8fd3ff}} .code .c{{color:#8a8a8a}}
.b{{position:absolute;left:120px;top:1720px;font-size:34px;color:#333;line-height:1.4}}
.v{{position:absolute;right:120px;top:1860px;font-size:28px;color:#666}}
</style></head><body><div class="w">
<div class="top"></div>
<div class="t">PrimeTime<br>Tcl Cookbook</div>
<div class="rule"></div>
<div class="s">Production scripts for STA signoff,<br>ECO, and report automation</div>
<div class="code"><span class="c"># worst slack per clock pair, one query</span><br>
<span class="k">set</span> paths [get_timing_paths -nworst 1 -max_paths 50000 \\<br>
&nbsp;&nbsp;&nbsp;&nbsp;-slack_lesser_than 0]<br>
<span class="k">foreach_in_collection</span> p $paths {{<br>
&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">set</span> s [get_attribute $p slack]<br>
&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">set</span> key "[get_object_name [get_attribute $p startpoint_clock]],\\<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[get_object_name [get_attribute $p endpoint_clock]]"<br>
&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">if</span> {{![info exists w($key)] || $s < $w($key)}} {{ <span class="k">set</span> w($key) $s }}<br>
}}</div>
<div class="b">41 scripts &middot; 11 chapters &middot; pt_shell ready<br>Setup &middot; Queries &middot; Paths &middot; Clocks &middot; SDC audit &middot; Triage &middot; ECO &middot; Export &middot; DMSA</div>
<div class="v">v{VERSION}</div>
</div></body></html>"""

PACKAGE_README = f"""PrimeTime Tcl Cookbook v{VERSION}
=================================

Contents
  primetime-tcl-cookbook.pdf   the book
  scripts/*.tcl                41 standalone scripts referenced in the book

Quick start (inside pt_shell, after link_design and update_timing):
  foreach f [glob ./scripts/*.tcl] {{ source $f }}
  path_table -group CLK -max_paths 100
  clock_pair_matrix
  bucket_violators -depth 2 -out violators.csv

Scripts that begin with a configuration block (02_session_setup.tcl,
10_dmsa_setup.tcl) are templates: copy and edit, do not source directly.

License: single-organisation use. Do not redistribute the PDF.
Support: reply to your purchase receipt with the script name and the
pt_shell version; attribute name differences between releases are the
most common issue and are quick to resolve.
"""

if __name__ == "__main__":
    main()
