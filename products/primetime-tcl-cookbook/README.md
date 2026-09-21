# PrimeTime Tcl Cookbook

Sellable technical e-book package: 41 pt_shell scripts plus a 56-page guide.

```
manuscript/   chapter sources (Markdown, {{include:file.tcl}} pulls scripts in)
scripts/      41 standalone Tcl scripts, one header each
build/        build.py: Markdown -> HTML -> PDF (headless chromium), cover PNG, ZIP
listing/      store copy (Gumroad EN, Kmong KR) and launch checklist
dist/         build outputs (PDF, cover PNG, sales ZIP), committed for download
```

Build:

```
pip install markdown pygments
python3 build/build.py            # writes dist/*.pdf, cover.png, *.zip
BOOK_VERSION=1.1 python3 build/build.py
```

`CHROME` env var overrides the chromium binary path.

Check every script parses (no PrimeTime needed):

```
tclsh build/check_scripts.tcl
```
