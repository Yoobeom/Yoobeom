# ---------------------------------------------------------------------------
# File   : make_figures.py
# Author : yoobeom.kim@samsung.com
# Purpose: Patent drawings (fig1..fig12) for the decoupled per-transistor
#          timing variation model (LVF contribution x aggregate sensitivity x
#          per-transistor parameter shift).  Monochrome line art; data
#          figures read example/out results.  Run from any directory:
#            python3 make_figures.py
# ---------------------------------------------------------------------------
import csv, os, math
from collections import defaultdict
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle, Polygon, FancyArrowPatch

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "figures")
DATA = os.path.normpath(os.path.join(HERE, "..", "..", "example", "out"))
os.makedirs(OUT, exist_ok=True)

plt.rcParams.update({
    "font.family": "NanumGothic",
    "axes.unicode_minus": False,
    "font.size": 9,
    "axes.linewidth": 0.8,
    "lines.linewidth": 1.0,
})
BLACK = "#000000"
GRAY = "#7a7a7a"
LIGHT = "#d9d9d9"
SG = {("N", "vth"): 0.015, ("P", "vth"): 0.015, ("N", "u0"): 0.03, ("P", "u0"): 0.03}


def box(ax, x, y, w, h, text, fs=8.5, lw=1.0, fill="white", ls="-"):
    ax.add_patch(Rectangle((x, y), w, h, fc=fill, ec=BLACK, lw=lw, ls=ls))
    ax.text(x + w / 2, y + h / 2, text, ha="center", va="center", fontsize=fs, linespacing=1.3)


def diamond(ax, cx, cy, w, h, text, fs=8.5):
    ax.add_patch(Polygon([(cx - w / 2, cy), (cx, cy + h / 2), (cx + w / 2, cy), (cx, cy - h / 2)],
                         closed=True, fc="white", ec=BLACK, lw=1.0))
    ax.text(cx, cy, text, ha="center", va="center", fontsize=fs, linespacing=1.3)


def arrow(ax, x0, y0, x1, y1, text="", ls="-", tx=None, ty=None, fs=8):
    ax.add_patch(FancyArrowPatch((x0, y0), (x1, y1), arrowstyle="-|>", mutation_scale=10,
                                 lw=1.0, color=BLACK, linestyle=ls, shrinkA=0, shrinkB=0))
    if text:
        ax.text(tx if tx is not None else (x0 + x1) / 2 + 0.15, ty if ty is not None else (y0 + y1) / 2,
                text, fontsize=fs, ha="left", va="center")


def finish(fig, name):
    fig.savefig(os.path.join(OUT, name), dpi=200, bbox_inches="tight", facecolor="white")
    plt.close(fig)
    print("wrote", name)


def read_csv(name):
    with open(os.path.join(DATA, name), newline="") as fh:
        return list(csv.DictReader(fh))


def sens_tables():
    """per-transistor S1 (delay rows) and whole-group direct S1, keyed by point"""
    S = defaultdict(dict); Gd = {}; V0 = {}
    for r in read_csv("sens.csv"):
        if r["meas"] != "delay" or r["s1"] == "":
            continue
        k = (r["cell"], r["arc"], r["slew_idx"], r["load_idx"], r["group"], r["param"])
        if r["inst"].startswith("GROUP:"):
            Gd[k] = float(r["s1"])
        else:
            S[k][r["inst"]] = float(r["s1"]); V0[k] = float(r["v0"])
    return S, Gd, V0


# ---------------------------------------------------------------------------
# 도 1 : 분리·결합 모델링 구조
# ---------------------------------------------------------------------------
def fig1():
    fig, ax = plt.subplots(figsize=(6.6, 5.6))
    ax.set_xlim(0, 12); ax.set_ylim(0, 9.5); ax.axis("off")
    # sources
    box(ax, 0.1, 7.6, 3.7, 1.3, "LVF 특성화 데이터 (110)\n트랜지스터별 섭동 민감도 S1(i,q)\nTR 식별 정보 있음", fs=7)
    box(ax, 4.15, 7.6, 3.7, 1.3, "집합 민감도 라이브러리 (120)\nsensitivity 그룹 S_agg(p)\nTR 식별 정보 없음", fs=7)
    box(ax, 8.2, 7.6, 3.7, 1.3, "레이아웃 / LLE 엔진 (130)\n인스턴스·TR별 ΔVth(i), ΔU0(i)\n(또는 전역 변동, 열화)", fs=7)
    # steps
    box(ax, 0.1, 5.4, 3.7, 1.2, "S210 기여도 결정\nC(i; s,l) = |S1(i)| / Σ|S1(j)|\nΣ C(i) = 1", fs=7.5)
    box(ax, 4.15, 5.4, 3.7, 1.2, "S220 집합 민감도 획득\nS_agg(p; s,l) 표면", fs=7.5)
    box(ax, 8.2, 5.4, 3.7, 1.2, "S240 변동량 획득\nΔp(i), 경계 + 내부 TR", fs=7.5)
    for x in (1.95, 6.0, 10.05):
        arrow(ax, x, 7.6, x, 6.6)
    box(ax, 2.3, 3.4, 7.4, 1.1, "S230 트랜지스터별 파라미터 민감도 복원\nS_rec(i,p; s,l) = C(i; s,l) · S_agg(p; s,l)", fs=8)
    arrow(ax, 1.95, 5.4, 1.95, 4.5); ax.plot([1.95, 2.3], [4.5, 4.5], color=BLACK)
    arrow(ax, 6.0, 5.4, 6.0, 4.5)
    box(ax, 2.3, 1.7, 7.4, 1.1, "S250 타이밍 변화량 산출\nΔD_arc = Σ_i Σ_p C(i) · S_agg(p) · Δp(i)", fs=8)
    arrow(ax, 6.0, 3.4, 6.0, 2.8)
    arrow(ax, 10.05, 5.4, 10.05, 2.25); ax.plot([9.7, 10.05], [2.25, 2.25], color=BLACK)
    box(ax, 0.3, 0.2, 5.4, 1.0, "S260a STA 보정\nD_corrected = D_base + ΔD_arc (인스턴스별)", fs=7.5)
    box(ax, 6.3, 0.2, 5.4, 1.0, "S260b 타이밍 라이브러리 생성\nv_new = v_old(1 + r), 셀별 디레이트", fs=7.5)
    arrow(ax, 4.5, 1.7, 3.0, 1.2); arrow(ax, 7.5, 1.7, 9.0, 1.2)
    ax.text(6, 9.25, "[도 1]", ha="center", fontsize=10)
    finish(fig, "fig1.png")


# ---------------------------------------------------------------------------
# 도 2 : 개별 섭동과 그룹 동시 섭동의 개념도
# ---------------------------------------------------------------------------
def fig2():
    fig, ax = plt.subplots(figsize=(6.3, 4.2))
    ax.set_xlim(0, 12); ax.set_ylim(0, 7); ax.axis("off")

    def cell(ox, title, marks):
        ax.text(ox + 1.6, 6.55, title, ha="center", fontsize=9)
        ax.plot([ox + 0.4, ox + 2.8], [6.1, 6.1], color=BLACK)
        ax.text(ox + 2.9, 6.1, "VDD", fontsize=7, va="center")
        for name, bx in (("M3", ox + 0.5), ("M4", ox + 1.9)):
            fill = LIGHT if name in marks else "white"
            box(ax, bx, 4.9, 0.8, 0.8, name + "\n(P)", fs=7, fill=fill)
            ax.plot([bx + 0.4, bx + 0.4], [5.7, 6.1], color=BLACK)
            ax.plot([bx + 0.4, bx + 0.4], [4.4, 4.9], color=BLACK)
        ax.plot([ox + 0.9, ox + 2.3], [4.4, 4.4], color=BLACK)
        ax.plot([ox + 1.6, ox + 1.6], [3.7, 4.4], color=BLACK)
        ax.text(ox + 1.75, 4.05, "ZN", fontsize=7, va="center")
        fill = LIGHT if "M1" in marks else "white"
        box(ax, ox + 1.2, 2.9, 0.8, 0.8, "M1\n(N)", fs=7, fill=fill)
        fill = LIGHT if "M2" in marks else "white"
        box(ax, ox + 1.2, 1.6, 0.8, 0.8, "M2\n(N)", fs=7, fill=fill)
        ax.plot([ox + 1.6, ox + 1.6], [2.4, 2.9], color=BLACK)
        ax.plot([ox + 1.6, ox + 1.6], [1.1, 1.6], color=BLACK)
        ax.plot([ox + 0.9, ox + 2.3], [1.1, 1.1], color=BLACK)
        ax.text(ox + 2.4, 1.1, "VSS", fontsize=7, va="center")
        ax.text(ox + 0.6, 3.3, "A", fontsize=7, ha="right", va="center")
        ax.text(ox + 0.6, 2.0, "B", fontsize=7, ha="right", va="center")

    cell(0.3, "(a) 개별 섭동 : M1", {"M1"})
    cell(4.3, "(b) 개별 섭동 : M2", {"M2"})
    cell(8.3, "(c) 그룹 동시 섭동 : M1, M2", {"M1", "M2"})
    ax.text(0.3, 0.55, "ΔD(M1) = D+(M1) - D0", fontsize=8.5)
    ax.text(4.3, 0.55, "ΔD(M2) = D+(M2) - D0", fontsize=8.5)
    ax.text(8.3, 0.55, "ΔD(N) = D+(N) - D0", fontsize=8.5)
    ax.text(6, 0.05, "검증 :  ΔD(N)  ≒  ΔD(M1) + ΔD(M2)     (1차,  음영 = q+δ 섭동된 트랜지스터)", ha="center", fontsize=9)
    ax.text(6, 6.9, "[도 2]", ha="center", fontsize=10)
    finish(fig, "fig2.png")


# ---------------------------------------------------------------------------
# 도 3 : LVF 데이터로부터 기여도 표면 생성
# ---------------------------------------------------------------------------
def fig3():
    fig, ax = plt.subplots(figsize=(6.6, 3.6))
    ax.set_xlim(0, 12); ax.set_ylim(0, 6); ax.axis("off")
    box(ax, 0.2, 4.4, 2.3, 1.0, "특성화 덱\narc_data", fs=7.5)
    box(ax, 2.9, 4.4, 2.3, 1.0, "±δ 섭동 측정 결과\n(D+, D-, D0)", fs=7.5)
    box(ax, 5.6, 4.4, 2.3, 1.0, "S1(i,q; s,l)\n중앙 차분", fs=7.5)
    box(ax, 8.3, 4.4, 3.5, 1.0, "기여도 표면 C(i; s,l)\n조회 테이블 / 속성 / 적합 함수", fs=7.5)
    arrow(ax, 2.5, 4.9, 2.9, 4.9); arrow(ax, 5.2, 4.9, 5.6, 4.9); arrow(ax, 7.9, 4.9, 8.3, 4.9)
    ax.text(6, 3.7, "C(i; s,l) = |S1(i,q; s,l)| / Σ_j |S1(j,q; s,l)|      (부호 유지 시  C(i) = S1(i) / Σ_j S1(j)),   Σ_i C(i) = 1",
            ha="center", fontsize=8.5)
    # example table
    hdr = ["slew", "load", "XMP0", "XMP0@2", "XMP0@3"]
    rows = [["S1", "L1", "0.13", "0.13", "0.12"], ["S1", "L2", "0.15", "0.11", "0.14"], ["S2", "L1", "0.10", "0.17", "0.12"]]
    x0, y0, cw, rh = 2.2, 2.6, 1.5, 0.5
    for c, h in enumerate(hdr):
        box(ax, x0 + c * cw, y0, cw, rh, h, fs=7.5, fill=LIGHT)
    for r_, row in enumerate(rows):
        for c, v in enumerate(row):
            box(ax, x0 + c * cw, y0 - (r_ + 1) * rh, cw, rh, v, fs=7.5)
    ax.text(6, 0.35, "기여도는 셀 / 아크 / 천이 방향 / 조건(when) / slew / load 에 의존하는 표면으로 저장된다 (예시 값)", ha="center", fontsize=8)
    ax.text(6, 5.75, "[도 3]", ha="center", fontsize=10)
    finish(fig, "fig3.png")


# ---------------------------------------------------------------------------
# 도 4 : 집합 민감도 라이브러리로부터 S_agg(p) 추출
# ---------------------------------------------------------------------------
def fig4():
    fig, ax = plt.subplots(figsize=(6.6, 3.4))
    ax.set_xlim(0, 12); ax.set_ylim(0, 5.6); ax.axis("off")
    box(ax, 0.1, 3.3, 3.9, 1.8, "sensitivity 그룹\n• device_param : delta_p_vta ...\n• contributing_devices : all\n• sens_cell_rise / sens_cell_fall", fs=7)
    box(ax, 4.4, 3.4, 3.4, 1.6, "S_agg(p; s,l) =\n[ΔD(+p) - ΔD(-p)]\n/ [p+ - p-]", fs=7.5)
    box(ax, 8.2, 3.5, 3.7, 1.4, "표면 또는 대표값\n표면 / mean_abs / RMS / max", fs=7.5)
    arrow(ax, 4.0, 4.2, 4.4, 4.2); arrow(ax, 7.8, 4.2, 8.2, 4.2)
    hdr = ["대표값", "용도"]
    rows = [["표면 S(s,l)", "STA 보간, 정확도 우선"], ["mean_abs", "셀 / 아크 대표값, 보고"],
            ["RMS", "큰 민감도 강조"], ["max", "guard-band, 최악 조건"]]
    x0, y0, rh = 2.6, 2.6, 0.45
    cws = [2.4, 4.4]
    for c, h in enumerate(hdr):
        box(ax, x0 + sum(cws[:c]), y0, cws[c], rh, h, fs=7.5, fill=LIGHT)
    for r_, row in enumerate(rows):
        for c, v in enumerate(row):
            box(ax, x0 + sum(cws[:c]), y0 - (r_ + 1) * rh, cws[c], rh, v, fs=7.5)
    ax.text(6, 0.25, "모든 소자를 동시에 섭동하여 산출되므로 트랜지스터 식별 정보가 없다  →  LVF 기여도가 보완", ha="center", fontsize=8)
    ax.text(6, 5.4, "[도 4]", ha="center", fontsize=10)
    finish(fig, "fig4.png")


# ---------------------------------------------------------------------------
# 도 5 : 결합에 의한 복원과 정합성 조건
# ---------------------------------------------------------------------------
def fig5():
    fig, ax = plt.subplots(figsize=(6.6, 3.2))
    ax.set_xlim(0, 12); ax.set_ylim(0, 5.2); ax.axis("off")
    box(ax, 0.3, 3.2, 2.6, 1.3, "C(i; s,l)\nTR 가중치, Σ C = 1\n(LVF)", fs=7.5)
    box(ax, 3.6, 3.2, 2.6, 1.3, "S_agg(p; s,l)\n집합 파라미터 민감도\n(USM / 그룹 섭동)", fs=7.5)
    box(ax, 6.9, 3.2, 2.6, 1.3, "S_rec(i,p; s,l)\n= C(i) · S_agg(p)\nTR별 파라미터 민감도", fs=7.5)
    box(ax, 10.0, 3.2, 1.8, 1.3, "STA-ready\n모델", fs=7.5)
    ax.text(3.25, 3.85, "×", ha="center", va="center", fontsize=14)
    arrow(ax, 6.2, 3.85, 6.9, 3.85); arrow(ax, 9.5, 3.85, 10.0, 3.85)
    ax.text(6, 2.3, "ΔD(i) = S_rec(i,p; s,l) · Δp(i)", ha="center", fontsize=9)
    box(ax, 0.2, 0.4, 11.6, 1.3,
        "정합성 조건 : 모든 TR에 동일한 Δp 가 인가되면  Σ_i C(i) · S_agg(p) · Δp = S_agg(p) · Δp\n"
        "(동시 변동 시 타이밍 변화량 = 개별 TR 변화량의 합,  집합 민감도 = TR별 민감도의 부호 합)", fs=7.5)
    ax.text(6, 5.0, "[도 5]", ha="center", fontsize=10)
    finish(fig, "fig5.png")


# ---------------------------------------------------------------------------
# 도 6 : 인스턴스별 LLE 변동량 → STA 보정 흐름
# ---------------------------------------------------------------------------
def fig6():
    fig, ax = plt.subplots(figsize=(6.6, 4.6))
    ax.set_xlim(0, 12); ax.set_ylim(0, 7.6); ax.axis("off")
    box(ax, 0.2, 5.6, 2.6, 1.4, "레이아웃 / LLE 엔진\n인스턴스별\nΔVth(i), ΔU0(i)", fs=7.5)
    box(ax, 3.3, 5.6, 2.8, 1.4, "조회 / 보간\nC(i; s,l), S_agg(p; s,l)\n(인스턴스의 slew, load)", fs=7.5)
    box(ax, 6.6, 5.6, 2.6, 1.4, "TR별 ΔD(i)\n파라미터별", fs=7.5)
    box(ax, 9.7, 5.6, 2.1, 1.4, "아크 보정\nΔD_arc", fs=7.5)
    arrow(ax, 2.8, 6.3, 3.3, 6.3); arrow(ax, 6.1, 6.3, 6.6, 6.3); arrow(ax, 9.2, 6.3, 9.7, 6.3)
    ax.text(6, 4.7, "ΔD_arc = Σ_i Σ_p C(i) · S_agg(p) · Δp(i,p),      D_corrected = D_base + ΔD_arc", ha="center", fontsize=8.5)
    hdr = ["데이터", "조회 키"]
    rows = [["기여도", "cell / arc / transition / when / slew / load / TR"],
            ["집합 민감도", "cell / arc / transition / parameter / slew / load"],
            ["LLE 변동량", "instance / TR / parameter"],
            ["STA 출력", "보정된 셀 지연 / 천이 시간 (또는 인스턴스별 디레이트)"]]
    x0, y0, rh = 1.2, 3.8, 0.5
    cws = [2.2, 7.4]
    for c, h in enumerate(hdr):
        box(ax, x0 + sum(cws[:c]), y0, cws[c], rh, h, fs=7.5, fill=LIGHT)
    for r_, row in enumerate(rows):
        for c, v in enumerate(row):
            box(ax, x0 + sum(cws[:c]), y0 - (r_ + 1) * rh, cws[c], rh, v, fs=7.5)
    ax.text(6, 0.9, "경계 트랜지스터와 내부 트랜지스터 모두 반영, 트랜지스터별 LLE 재특성화 불필요", ha="center", fontsize=8)
    ax.text(6, 7.35, "[도 6]", ha="center", fontsize=10)
    finish(fig, "fig6.png")


# ---------------------------------------------------------------------------
# 도 7 : 동일 민감도의 두 가지 결합 (국부 RSS, 전역 부호 합)
# ---------------------------------------------------------------------------
def fig7():
    rows = [r for r in read_csv("contrib.csv")
            if r["cell"] == "NAND2_X1" and r["arc"] == "A_r_ZN_f" and r["meas"] == "delay"
            and r["slew_idx"] == "1" and r["load_idx"] == "1" and r["param"] == "vth"]
    sig = [r for r in read_csv("local_sigma.csv")
           if r["cell"] == "NAND2_X1" and r["arc"] == "A_r_ZN_f" and r["meas"] == "delay"
           and r["slew_idx"] == "1" and r["load_idx"] == "1"][0]
    v0 = float(sig["v0"])
    insts = [r["inst"] for r in rows]
    c_local = [float(r["c_local"]) / v0 * 100 for r in rows]
    c_glob = [float(r["c_global_1sig"]) * 3 / v0 * 100 for r in rows]
    rss = math.sqrt(sum(c * c for c in c_local))
    tot = sum(c_glob)
    fig, axes = plt.subplots(1, 2, figsize=(6.3, 2.9))
    for ax, vals, total, title, tlabel in (
            (axes[0], c_local, rss, "(a) 국부 변동 : 독립 → 제곱합의 제곱근", "RSS"),
            (axes[1], c_glob, tot, "(b) 전역 변동 : 공통 이동 → 부호 합", "Σ")):
        xs = list(range(len(vals)))
        ax.bar(xs, vals, width=0.6, color="white", edgecolor=BLACK, linewidth=1.0)
        ax.bar([len(vals) + 0.4], [total], width=0.6, color="white", edgecolor=BLACK, linewidth=1.0, hatch="////")
        ax.axhline(0, color=BLACK, lw=0.8)
        ax.set_xticks(xs + [len(vals) + 0.4])
        ax.set_xticklabels([f"{i}\n({'N' if i in ('M1', 'M2') else 'P'})" for i in insts] + [tlabel], fontsize=8)
        for x, v in zip(xs + [len(vals) + 0.4], vals + [total]):
            ax.text(x, v + (0.15 if v >= 0 else -0.15), f"{v:.2f}", ha="center",
                    va="bottom" if v >= 0 else "top", fontsize=7.5)
        ax.set_title(title, fontsize=9)
        ax.set_ylabel("지연 대비 [%]", fontsize=8)
        ax.spines[["top", "right"]].set_visible(False)
        ax.tick_params(axis="y", labelsize=8)
    axes[0].set_ylim(-1, max(c_local + [rss]) * 1.35)
    axes[1].set_ylim(min(c_glob + [0]) * 1.6 - 0.5, max(c_glob + [tot]) * 1.3)
    fig.suptitle("[도 7]  NAND2 A→ZN 하강, 문턱 전압 파라미터, 트랜지스터별 기여 (1σ mismatch / 3σ 전역)", fontsize=9, y=1.03)
    fig.tight_layout()
    finish(fig, "fig7.png")


# ---------------------------------------------------------------------------
# 도 8 : 정합성 검증 흐름도
# ---------------------------------------------------------------------------
def fig8():
    fig, ax = plt.subplots(figsize=(6.3, 6.4))
    ax.set_xlim(0, 10); ax.set_ylim(0, 11); ax.axis("off")
    x, w, h = 2.0, 6.0, 1.1
    box(ax, x, 9.4, w, h, "그룹 동시 섭동 시뮬레이션 (±δ)\nG1_direct(g,q), H2_direct(g,q) 산출")
    ax.text(x - 0.15, 9.95, "S141", ha="right", va="center", fontsize=9)
    box(ax, x, 7.5, w, 1.3, "차이 산출\nd1 = |G1 - G1_direct|·Δref / D0\nd2 = ½·(H2_direct - H2)·Δref² / D0", fs=8)
    ax.text(x - 0.15, 8.15, "S142", ha="right", va="center", fontsize=9)
    arrow(ax, 5, 9.4, 5, 8.8)
    diamond(ax, 5, 6.2, 3.6, 1.5, "d1 ≤ T1 ?")
    ax.text(x - 0.15, 6.2, "S143", ha="right", va="center", fontsize=9)
    arrow(ax, 5, 7.5, 5, 6.95)
    box(ax, 7.4, 5.65, 2.5, 1.1, "특성화 데이터 오류\n(수렴, 정밀도, 부호)\n재특성화", fs=7.5)
    arrow(ax, 6.8, 6.2, 7.4, 6.2, "아니오", tx=6.85, ty=6.45)
    diamond(ax, 5, 3.9, 3.6, 1.5, "|d2| ≤ T2 ?")
    arrow(ax, 5, 5.45, 5, 4.65, "예", tx=5.15, ty=5.05)
    box(ax, 7.4, 3.35, 2.5, 1.1, "H2_direct 사용\n또는 직접 특성화 대상", fs=7.5)
    arrow(ax, 6.8, 3.9, 7.4, 3.9, "아니오", tx=6.85, ty=4.15)
    box(ax, x, 1.5, w, 1.1, "합산 민감도 G1, H2 및 기여도 C(i) 사용 → 타이밍 변화량 산출")
    ax.text(x - 0.15, 2.05, "S144", ha="right", va="center", fontsize=9)
    arrow(ax, 5, 3.15, 5, 2.6, "예", tx=5.15, ty=2.9)
    ax.text(5, 0.7, "T1, T2 : 타이밍 값 대비 비율 임계값 (예 : 0.5 %, 1 %),  Δref : 기준 변동량 (예 : 3σ)", ha="center", fontsize=8)
    ax.text(5, 10.8, "[도 8]", ha="center", fontsize=10)
    finish(fig, "fig8.png")


# ---------------------------------------------------------------------------
# 도 9 : 라이브러리 테이블 갱신 개념도
# ---------------------------------------------------------------------------
def fig9():
    pred = [r for r in read_csv("pred_SSG.csv") if r["cell"] == "INV_X1" and r["arc"] == "A_r_ZN_f" and r["meas"] == "delay"]
    grid = {(int(r["slew_idx"]), int(r["load_idx"])): float(r["dv_rel_pred"]) for r in pred}
    fig, ax = plt.subplots(figsize=(6.3, 3.4))
    ax.set_xlim(0, 12); ax.set_ylim(0, 6); ax.axis("off")
    ax.text(2.2, 5.5, "모델 격자 : 상대 변화율 r(slew, load)", ha="center", fontsize=9)
    slews = ["10", "30", "80"]; loads = ["1", "4", "12"]
    for j in range(3):
        for k in range(3):
            box(ax, 0.9 + k * 1.0, 3.9 - j * 0.9, 1.0, 0.9, f"{grid[(j, k)]:+.3f}", fs=7.5)
    for k, l in enumerate(loads):
        ax.text(1.4 + k * 1.0, 4.95, l + " fF", ha="center", fontsize=7)
    for j, s in enumerate(slews):
        ax.text(0.8, 4.35 - j * 0.9, s + " ps", ha="right", va="center", fontsize=7)
    ax.text(2.4, 1.55, "slew × load, 시뮬레이션 격자", ha="center", fontsize=7.5)
    arrow(ax, 4.2, 3.3, 5.5, 3.3)
    ax.text(4.85, 3.55, "이중 선형 보간\n(격자 밖은 경계값)", ha="center", va="bottom", fontsize=7.5)
    ax.text(9.1, 5.5, "라이브러리 테이블 (cell_fall) : v_new = v_old · (1 + r)", ha="center", fontsize=9)
    lib_slew = ["5", "20", "50", "100"]; lib_load = ["0.5", "2", "6", "16"]
    for j in range(4):
        for k in range(4):
            box(ax, 6.8 + k * 1.15, 4.2 - j * 0.75, 1.15, 0.75, "v·(1+r)", fs=6.5)
    for k, l in enumerate(lib_load):
        ax.text(6.8 + k * 1.15 + 0.575, 5.05, l + " fF", ha="center", fontsize=7)
    for j, s in enumerate(lib_slew):
        ax.text(6.7, 4.2 - j * 0.75 + 0.375, s + " ps", ha="right", va="center", fontsize=7)
    ax.text(9.1, 0.9, "라이브러리 고유 인덱스 (단위 : time_unit, capacitive_load_unit 로 변환)", ha="center", fontsize=7.5)
    ax.text(6, 5.95, "[도 9]", ha="center", fontsize=10)
    finish(fig, "fig9.png")


# ---------------------------------------------------------------------------
# 도 10 : 전역 변동점 예측값과 직접 시뮬레이션 값의 비교
# ---------------------------------------------------------------------------
def fig10():
    corners = ["NVT_p1s", "NVT_p3s", "NVT_m3s", "PVT_p3s", "PVT_m3s", "NU0_m3s", "PU0_m3s", "SS1", "SSG", "FFG", "SFG", "FSG"]
    labels = ["N vth +1σ", "N vth +3σ", "N vth -3σ", "P vth +3σ", "P vth -3σ", "N u0 -3σ", "P u0 -3σ", "SS1", "SSG", "FFG", "SFG", "FSG"]
    xs_sim, ys_pred = [], []
    e_lin, e_logq = [], []
    for c in corners:
        rows = [r for r in read_csv(f"validate_{c}.csv") if r["meas"] == "delay"]
        el, eq = [], []
        for r in rows:
            v0 = float(r["v0"]); vs = float(r["v_sim"])
            xs_sim.append(vs / v0)
            ys_pred.append((v0 + float(r["dv_logquad"])) / v0)
            el.append(abs(float(r["err_abs_pct_lin"])))
            eq.append(abs(float(r["err_abs_pct_logquad"])))
        e_lin.append(sum(el) / len(el)); e_logq.append(sum(eq) / len(eq))
    fig, axes = plt.subplots(1, 2, figsize=(6.3, 3.3), gridspec_kw={"width_ratios": [1, 1.7]})
    ax = axes[0]
    ax.plot([0.8, 1.3], [0.8, 1.3], color=GRAY, lw=0.8, ls="--")
    ax.scatter(xs_sim, ys_pred, s=6, facecolors="none", edgecolors=BLACK, linewidths=0.6)
    ax.set_xlabel("직접 시뮬레이션  D/D0", fontsize=8)
    ax.set_ylabel("모델 예측 (logquad)  D/D0", fontsize=8)
    ax.set_xlim(0.8, 1.3); ax.set_ylim(0.8, 1.3)
    ax.set_xticks([0.8, 0.9, 1.0, 1.1, 1.2, 1.3]); ax.set_yticks([0.8, 0.9, 1.0, 1.1, 1.2, 1.3])
    ax.tick_params(labelsize=7.5)
    ax.set_title(f"(a) 12개 전역 변동점, 지연 {len(xs_sim)} 포인트", fontsize=8.5)
    ax.set_aspect("equal")
    ax.spines[["top", "right"]].set_visible(False)
    ax = axes[1]
    xs = list(range(len(corners)))
    ax.bar([x - 0.2 for x in xs], e_lin, width=0.4, color="white", edgecolor=BLACK, linewidth=0.8, label="선형 (lin)")
    ax.bar([x + 0.2 for x in xs], e_logq, width=0.4, color="white", edgecolor=BLACK, linewidth=0.8, hatch="////", label="로그 2차 (logquad)")
    ax.set_xticks(xs); ax.set_xticklabels(labels, fontsize=6.5, rotation=60, ha="right")
    ax.set_ylabel("평균 |오차| [% of D]", fontsize=8)
    ax.tick_params(axis="y", labelsize=7.5)
    ax.set_title("(b) 전역 변동점별 평균 오차", fontsize=8.5)
    ax.legend(fontsize=7, frameon=False, loc="upper left")
    ax.spines[["top", "right"]].set_visible(False)
    fig.suptitle("[도 10]", fontsize=10, y=1.02)
    fig.tight_layout()
    finish(fig, "fig10.png")


# ---------------------------------------------------------------------------
# 도 11 : 복원 오차와 파라미터별 기여도 비교
# ---------------------------------------------------------------------------
def fig11():
    S, Gd, V0 = sens_tables()
    err_u = defaultdict(list); err_s = defaultdict(list)
    for k, d in S.items():
        if k not in Gd:
            continue
        sagg = Gd[k]; v0 = V0[k]; D = 3 * SG[(k[4], k[5])]
        tot_abs = sum(abs(v) for v in d.values()); tot = sum(d.values())
        for inst, si in d.items():
            cu = abs(si) / tot_abs if tot_abs > 0 else 0
            cs = si / tot if tot != 0 else 0
            key = f"{k[0].replace('_X1', '')}\n{k[4]}/{k[5]}"
            err_u[key].append(abs(cu * sagg - si) * D / v0 * 100)
            err_s[key].append(abs(cs * sagg - si) * D / v0 * 100)
    keys = [k for k in err_u if max(err_u[k]) > 0.005]
    keys = sorted(keys)
    # contribution comparison, driving group only
    comp = defaultdict(lambda: defaultdict(list))
    for k, d in S.items():
        cell, arc, j, kk, g, p = k
        od = "fall" if arc.endswith("_f") else "rise"
        if (g == "N" and od != "fall") or (g == "P" and od != "rise"):
            continue
        tot_abs = sum(abs(v) for v in d.values())
        for inst, si in d.items():
            comp[(cell, arc, inst)][p].append(abs(si) / tot_abs)
    labels, cv, cu = [], [], []
    for (cell, arc, inst) in sorted(comp):
        v = comp[(cell, arc, inst)]
        if "vth" not in v or "u0" not in v:
            continue
        mv = sum(v["vth"]) / len(v["vth"]); mu = sum(v["u0"]) / len(v["u0"])
        if mv in (0.0, 1.0) and mu in (0.0, 1.0):
            continue  # single-transistor arcs: trivially 1 / 0
        labels.append(f"{cell.replace('_X1', '')} {arc.split('_')[0]}{arc.split('_')[1]} {inst}")
        cv.append(mv); cu.append(mu)
    fig, axes = plt.subplots(1, 2, figsize=(6.6, 3.2), gridspec_kw={"width_ratios": [1.1, 1.3]})
    ax = axes[0]
    xs = list(range(len(keys)))
    ax.bar([x - 0.2 for x in xs], [max(err_u[k]) for k in keys], width=0.4, color="white", edgecolor=BLACK, linewidth=0.8, label="부호 없는 C(i)")
    ax.bar([x + 0.2 for x in xs], [max(err_s[k]) for k in keys], width=0.4, color="white", edgecolor=BLACK, linewidth=0.8, hatch="////", label="부호 유지 C(i)")
    ax.set_xticks(xs); ax.set_xticklabels(keys, fontsize=6.5)
    ax.set_ylabel("최대 복원 오차 [% of D, 3σ]", fontsize=8)
    ax.set_ylim(0, 0.8)
    ax.set_title("(a) S_rec = C(i)·S_agg 의 복원 오차", fontsize=8.5)
    ax.legend(fontsize=7, frameon=False, loc="upper right")
    ax.tick_params(axis="y", labelsize=7.5)
    ax.spines[["top", "right"]].set_visible(False)
    ax = axes[1]
    xs = list(range(len(labels)))
    ax.bar([x - 0.2 for x in xs], cv, width=0.4, color="white", edgecolor=BLACK, linewidth=0.8, label="C_vth")
    ax.bar([x + 0.2 for x in xs], cu, width=0.4, color="white", edgecolor=BLACK, linewidth=0.8, hatch="////", label="C_u0")
    ax.set_xticks(xs); ax.set_xticklabels(labels, fontsize=6, rotation=60, ha="right")
    ax.set_ylabel("기여도", fontsize=8)
    ax.set_ylim(0, 1.3)
    ax.set_yticks([0, 0.2, 0.4, 0.6, 0.8, 1.0])
    ax.set_title("(b) 구동 그룹 적층 트랜지스터의 기여도", fontsize=8.5)
    ax.legend(fontsize=7, frameon=False, loc="upper center", ncol=2)
    ax.tick_params(axis="y", labelsize=7.5)
    ax.spines[["top", "right"]].set_visible(False)
    fig.suptitle("[도 11]", fontsize=10, y=1.02)
    fig.tight_layout()
    finish(fig, "fig11.png")


# ---------------------------------------------------------------------------
# 도 12 : 장치 블록도
# ---------------------------------------------------------------------------
def fig12():
    fig, ax = plt.subplots(figsize=(6.3, 4.3))
    ax.set_xlim(0, 12); ax.set_ylim(0, 8.2); ax.axis("off")
    ax.add_patch(Rectangle((0.4, 0.5), 8.6, 6.9, fc="white", ec=BLACK, lw=1.2))
    ax.text(0.6, 7.1, "장치 (700)", fontsize=9, va="center")
    ax.add_patch(Rectangle((0.7, 0.9), 4.6, 5.9, fc="white", ec=BLACK, lw=1.0))
    ax.text(0.9, 6.5, "프로세서 (710)", fontsize=8.5, va="center")
    mods = ["기여도 결정부 (711)", "집합 민감도 획득부 (712)", "민감도 복원부 (713)", "변동량 획득부 (714)",
            "정합성 검증부 (715)", "변화량 산출부 (716)", "보정 · 라이브러리 생성부 (717)"]
    for n, m in enumerate(mods):
        box(ax, 1.0, 5.6 - n * 0.72, 4.0, 0.6, m, fs=7.5)
    box(ax, 5.9, 5.3, 2.9, 1.3, "메모리 (720)\n명령어, 작업 데이터", fs=8)
    box(ax, 5.9, 2.9, 2.9, 2.0, "저장부 (730)\n넷리스트, 소자 모델\nLVF 데이터, 집합 민감도 lib\n공칭 lib, 레이아웃 추출\n변동점 정의", fs=6.8)
    box(ax, 5.9, 1.0, 2.9, 1.3, "입출력부 (740)", fs=8)
    arrow(ax, 5.3, 6.05, 5.9, 6.05); arrow(ax, 5.9, 5.75, 5.3, 5.75)
    arrow(ax, 5.3, 4.0, 5.9, 4.0); arrow(ax, 5.9, 3.7, 5.3, 3.7)
    arrow(ax, 5.3, 1.65, 5.9, 1.65)
    box(ax, 9.6, 5.9, 2.2, 1.1, "회로 시뮬레이터\n특성화 도구", fs=7.5)
    box(ax, 9.6, 3.9, 2.2, 1.1, "배치 · 배선 도구\n(레이아웃 추출)", fs=7.5)
    box(ax, 9.6, 1.9, 2.2, 1.1, "STA 도구", fs=7.5)
    arrow(ax, 9.6, 6.45, 8.8, 4.6); arrow(ax, 9.6, 4.45, 8.8, 4.2); arrow(ax, 8.8, 1.65, 9.6, 2.3)
    ax.text(6, 7.9, "[도 12]", ha="center", fontsize=10)
    finish(fig, "fig12.png")


if __name__ == "__main__":
    for f in (fig1, fig2, fig3, fig4, fig5, fig6, fig7, fig8, fig9, fig10, fig11, fig12):
        f()
