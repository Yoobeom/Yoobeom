// ---------------------------------------------------------------------------
// File   : make_docx.js
// Author : yoobeom.kim@samsung.com
// Purpose: Build patent_draft_ko.docx from patent_draft_ko.md (KIPO style
//          specification) and embed figures/fig1..fig7.png in the 【도면】
//          section (all figures/figN.png present).  Uses the docx npm package.
//            node make_docx.js
// ---------------------------------------------------------------------------
const fs = require("fs");
const path = require("path");
const {
  Document, Packer, Paragraph, TextRun, HeadingLevel, Table, TableRow, TableCell,
  WidthType, AlignmentType, ImageRun, BorderStyle, LevelFormat, ShadingType, PageBreak,
} = require("docx");

const HERE = __dirname;
const MD = path.join(HERE, "patent_draft_ko.md");
const OUT = path.join(HERE, "patent_draft_ko.docx");
const FIGDIR = path.join(HERE, "figures");

const FONT = { ascii: "Malgun Gothic", hAnsi: "Malgun Gothic", eastAsia: "Malgun Gothic", cs: "Malgun Gothic" };
const MONO = { ascii: "Consolas", hAnsi: "Consolas", eastAsia: "Malgun Gothic", cs: "Consolas" };
const PAGE_W = 11906, PAGE_H = 16838;            // A4 in DXA
const MARGIN = 1134;                              // 20 mm
const TEXT_W = PAGE_W - 2 * MARGIN;               // 9638

function stripInline(s) {
  return s.replace(/`([^`]*)`/g, "$1").replace(/\*\*([^*]*)\*\*/g, "$1").replace(/\\\|/g, "|");
}

function textParagraph(text, opts = {}) {
  const runs = [];
  const parts = text.split(/(`[^`]*`)/g);
  for (const p of parts) {
    if (p === "") continue;
    if (p.startsWith("`") && p.endsWith("`")) {
      runs.push(new TextRun({ text: p.slice(1, -1), font: MONO, size: opts.size || 20 }));
    } else {
      runs.push(new TextRun({ text: stripInline(p), font: FONT, size: opts.size || 20, bold: opts.bold || false }));
    }
  }
  return new Paragraph({
    children: runs,
    alignment: opts.alignment || AlignmentType.LEFT,
    spacing: { after: opts.after === undefined ? 100 : opts.after, line: 300 },
    indent: opts.indent,
    numbering: opts.numbering,
    keepNext: opts.keepNext,
  });
}

function heading(text, level) {
  return new Paragraph({
    heading: level,
    children: [new TextRun({ text: stripInline(text), font: FONT })],
    spacing: { before: level === HeadingLevel.HEADING_1 ? 360 : 240, after: 120 },
    keepNext: true,
  });
}

function tableFromRows(rows) {
  const ncol = rows[0].length;
  const colw = Math.floor(TEXT_W / ncol);
  const widths = new Array(ncol).fill(colw);
  widths[ncol - 1] = TEXT_W - colw * (ncol - 1);
  const border = { style: BorderStyle.SINGLE, size: 4, color: "000000" };
  const borders = { top: border, bottom: border, left: border, right: border };
  const trs = rows.map((cells, ri) => new TableRow({
    tableHeader: ri === 0,
    children: cells.map((c, ci) => new TableCell({
      width: { size: widths[ci], type: WidthType.DXA },
      borders,
      shading: ri === 0 ? { type: ShadingType.CLEAR, fill: "E7E6E6", color: "auto" } : undefined,
      margins: { top: 40, bottom: 40, left: 80, right: 80 },
      children: [new Paragraph({
        children: [new TextRun({ text: stripInline(c.trim()), font: FONT, size: 18, bold: ri === 0 })],
        alignment: ci === 0 ? AlignmentType.LEFT : AlignmentType.CENTER,
        spacing: { after: 0 },
      })],
    })),
  }));
  return new Table({ rows: trs, width: { size: TEXT_W, type: WidthType.DXA }, columnWidths: widths });
}

function figureBlock(n) {
  const file = path.join(FIGDIR, `fig${n}.png`);
  if (!fs.existsSync(file)) return [textParagraph(`【도 ${n}】 (figures/fig${n}.png 없음)`)];
  const buf = fs.readFileSync(file);
  // PNG size from IHDR
  const w = buf.readUInt32BE(16), h = buf.readUInt32BE(20);
  const maxW = 600, maxH = 720;
  let scale = Math.min(maxW / w, maxH / h, 1.0);
  const out = [
    textParagraph(`【도 ${n}】`, { bold: true, after: 60, keepNext: true }),
    new Paragraph({
      children: [new ImageRun({ type: "png", data: buf, transformation: { width: Math.round(w * scale), height: Math.round(h * scale) } })],
      alignment: AlignmentType.CENTER,
      spacing: { after: 240 },
    }),
  ];
  return out;
}

function build() {
  const lines = fs.readFileSync(MD, "utf8").split(/\r?\n/);
  const children = [];
  let i = 0;
  let inCode = false;
  let codeBuf = [];
  let tableBuf = [];
  const flushTable = () => {
    if (tableBuf.length === 0) return;
    const rows = tableBuf
      .filter(l => !/^\|\s*-+/.test(l))
      .map(l => l.replace(/^\|/, "").replace(/\|\s*$/, "").split("|"));
    children.push(tableFromRows(rows));
    children.push(new Paragraph({ spacing: { after: 120 } }));
    tableBuf = [];
  };
  while (i < lines.length) {
    const raw = lines[i];
    const line = raw.replace(/\s+$/, "");
    i++;
    if (line.startsWith("```")) {
      if (inCode) {
        for (const c of codeBuf) {
          children.push(new Paragraph({ children: [new TextRun({ text: c, font: MONO, size: 17 })], spacing: { after: 0, line: 260 }, indent: { left: 400 } }));
        }
        children.push(new Paragraph({ spacing: { after: 120 } }));
        codeBuf = []; inCode = false;
      } else { inCode = true; }
      continue;
    }
    if (inCode) { codeBuf.push(line); continue; }
    if (line.startsWith("|") && line.trim().endsWith("|")) { tableBuf.push(line); continue; }
    flushTable();
    if (line.trim() === "") continue;
    if (line.startsWith("---")) {
      children.push(new Paragraph({ children: [new PageBreak()] }));
      continue;
    }
    if (line.startsWith("# ")) {
      children.push(new Paragraph({ heading: HeadingLevel.TITLE, alignment: AlignmentType.CENTER,
        children: [new TextRun({ text: line.slice(2), font: FONT, size: 36, bold: true })], spacing: { after: 240 } }));
      continue;
    }
    if (line.startsWith("## 【도면】")) {
      children.push(heading("【도면】", HeadingLevel.HEADING_1));
      for (let n = 1; n <= 30; n++) {
        if (!fs.existsSync(path.join(FIGDIR, `fig${n}.png`))) break;
        children.push(...figureBlock(n));
      }
      // skip the placeholder line(s) until next heading or separator
      while (i < lines.length && !lines[i].startsWith("#") && !lines[i].startsWith("---")) i++;
      continue;
    }
    if (line.startsWith("## ")) { children.push(heading(line.slice(3), HeadingLevel.HEADING_1)); continue; }
    if (line.startsWith("### ")) { children.push(heading(line.slice(4), HeadingLevel.HEADING_2)); continue; }
    if (line.startsWith("- ")) {
      children.push(textParagraph(line.slice(2), { numbering: { reference: "bullets", level: 0 }, after: 60 }));
      continue;
    }
    if (/^【청구항 \d+】/.test(line)) {
      children.push(textParagraph(line, { bold: true, after: 40, keepNext: true }));
      continue;
    }
    if (/^\[(수학식|표) \d+\]/.test(line)) {
      children.push(textParagraph(line, { bold: true, after: 40, keepNext: true }));
      continue;
    }
    if (/^[A-Za-zΔσΣ|√].*=/.test(line) && line.length < 90 && !/^\[/.test(line)) {
      // equation line
      children.push(textParagraph(line, { indent: { left: 720 }, after: 120 }));
      continue;
    }
    children.push(textParagraph(line));
  }
  flushTable();

  const doc = new Document({
    creator: "yoobeom.kim@samsung.com",
    title: "특허 출원 명세서 초안",
    styles: {
      default: { document: { run: { font: FONT, size: 20 } } },
      paragraphStyles: [
        { id: "Heading1", name: "Heading 1", basedOn: "Normal", next: "Normal", quickFormat: true,
          run: { size: 26, bold: true, font: FONT }, paragraph: { spacing: { before: 360, after: 120 }, outlineLevel: 0 } },
        { id: "Heading2", name: "Heading 2", basedOn: "Normal", next: "Normal", quickFormat: true,
          run: { size: 22, bold: true, font: FONT }, paragraph: { spacing: { before: 240, after: 100 }, outlineLevel: 1 } },
      ],
    },
    numbering: { config: [{ reference: "bullets", levels: [{ level: 0, format: LevelFormat.BULLET, text: "•", alignment: AlignmentType.LEFT,
      style: { paragraph: { indent: { left: 560, hanging: 280 } } } }] }] },
    sections: [{
      properties: { page: { size: { width: PAGE_W, height: PAGE_H }, margin: { top: MARGIN, bottom: MARGIN, left: MARGIN, right: MARGIN } } },
      children,
    }],
  });
  Packer.toBuffer(doc).then(buf => { fs.writeFileSync(OUT, buf); console.log("wrote", OUT, buf.length, "bytes"); });
}
build();
