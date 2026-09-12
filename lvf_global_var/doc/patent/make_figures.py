# ---------------------------------------------------------------------------
# File   : make_figures.py
# Author : yoobeom.kim@samsung.com
# Purpose: Patent drawings (fig1..fig7) for the LVF sensitivity based global
#          variation timing method.  Monochrome line art; data figures read
#          example/out results.  Run from any directory:
#            python3 make_figures.py
# ---------------------------------------------------------------------------
import csv, os, math
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


# ---------------------------------------------------------------------------
# 도 1 : 전체 흐름도
# ---------------------------------------------------------------------------
def fig1():
    fig, ax = plt.subplots(figsize=(6.3, 7.2))
    ax.set_xlim(0, 10); ax.set_ax = ax.set_ylim(0, 12); ax.axis("off")
    steps = [
        ("S110", "트랜지스터별 타이밍 민감도 획득\nS1(i,q), S2(i,q)  (LVF 특성화 데이터)"),
        ("S120", "변동 그룹 분류\n(NMOS / PMOS, Vt 종류, 모델명)"),
        ("S130", "그룹 민감도 합산 (부호 유지)\nG1(g,q) = Σ S1(i,q),  H2(g,q) = Σ S2(i,q)"),
        ("S140", "정합성 검증\n(그룹 동시 섭동 결과와 비교, 도 4)"),
        ("S150", "타이밍 변화량 산출\nΔD = Σ [G1·Δ + ½·H2·Δ²]  또는 로그 영역 모델"),
        ("S160", "타이밍 라이브러리 데이터 생성\n(테이블 갱신 v_new = v_old(1+r), 셀별 디레이트)"),
    ]
    x, w, h = 2.2, 5.6, 1.15
    ys = [10.4, 8.7, 7.0, 5.3, 3.6, 1.9]
    for (code, text), y in zip(steps, ys):
        box(ax, x, y, w, h, text)
        ax.text(x - 0.15, y + h / 2, code, ha="right", va="center", fontsize=9)
    for y0, y1 in zip(ys[:-1], ys[1:]):
        arrow(ax, x + w / 2, y0, x + w / 2, y1 + h)
    # side inputs
    box(ax, 8.2, 3.6, 1.7, 1.15, "전역 변동점\n정의 Δ(g,q)", fs=8)
    arrow(ax, 8.2, 3.6 + h / 2, x + w, 3.6 + h / 2)
    box(ax, 8.2, 1.9, 1.7, 1.15, "공칭 타이밍\n라이브러리", fs=8)
    arrow(ax, 8.2, 1.9 + h / 2, x + w, 1.9 + h / 2)
    box(ax, 8.2, 10.4, 1.7, 1.15, "셀 넷리스트\n소자 모델", fs=8)
    arrow(ax, 8.2, 10.4 + h / 2, x + w, 10.4 + h / 2)
    ax.text(x + w / 2, 0.9, "→ 전역 변동점 라이브러리, STA 디레이트, 트랜지스터별 기여도", ha="center", fontsize=8.5)
    arrow(ax, x + w / 2, 1.9, x + w / 2, 1.25)
    ax.text(5, 11.85, "[도 1]", ha="center", fontsize=10)
    finish(fig, "fig1.png")


# ---------------------------------------------------------------------------
# 도 2 : 개별 섭동과 그룹 동시 섭동의 개념도
# ---------------------------------------------------------------------------
def fig2():
    fig, ax = plt.subplots(figsize=(6.3, 4.2))
    ax.set_xlim(0, 12); ax.set_ylim(0, 7); ax.axis("off")

    def cell(ox, title, marks):
        # simplified NAND2: M3, M4 parallel (P), M1, M2 series (N)
        ax.text(ox + 1.6, 6.55, title, ha="center", fontsize=9)
        ax.plot([ox + 0.4, ox + 2.8], [6.1, 6.1], color=BLACK)           # VDD rail
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
# 도 3 : 동일 민감도의 두 가지 결합 (국부 RSS, 전역 부호 합)  - NAND2 A->ZN fall, center point
# ---------------------------------------------------------------------------
def fig3():
    rows = [r for r in read_csv("contrib.csv")
            if r["cell"] == "NAND2_X1" and r["arc"] == "A_r_ZN_f" and r["meas"] == "delay"
            and r["slew_idx"] == "1" and r["load_idx"] == "1" and r["param"] == "vth"]
    sig = [r for r in read_csv("local_sigma.csv")
           if r["cell"] == "NAND2_X1" and r["arc"] == "A_r_ZN_f" and r["meas"] == "delay"
           and r["slew_idx"] == "1" and r["load_idx"] == "1"][0]
    v0 = float(sig["v0"])
    insts = [r["inst"] for r in rows]
    c_local = [float(r["c_local"]) / v0 * 100 for r in rows]           # % of delay, 1 sigma_mm
    c_glob = [float(r["c_global_1sig"]) * 3 / v0 * 100 for r in rows]  # % of delay, 3 sigma_g
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
    fig.suptitle("[도 3]  NAND2 A→ZN 하강, 문턱 전압 파라미터, 트랜지스터별 기여 (1σ mismatch / 3σ 전역)", fontsize=9, y=1.03)
    fig.tight_layout()
    finish(fig, "fig3.png")


# ---------------------------------------------------------------------------
# 도 4 : 정합성 검증 흐름도
# ---------------------------------------------------------------------------
def fig4():
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
    box(ax, x, 1.5, w, 1.1, "합산 민감도 G1, H2 사용 → 타이밍 변화량 산출 (S150)")
    ax.text(x - 0.15, 2.05, "S144", ha="right", va="center", fontsize=9)
    arrow(ax, 5, 3.15, 5, 2.6, "예", tx=5.15, ty=2.9)
    ax.text(5, 0.7, "T1, T2 : 타이밍 값 대비 비율 임계값 (예 : 0.5 %, 1 %),  Δref : 기준 변동량 (예 : 3σ)", ha="center", fontsize=8)
    ax.text(5, 10.8, "[도 4]", ha="center", fontsize=10)
    finish(fig, "fig4.png")


# ---------------------------------------------------------------------------
# 도 5 : 라이브러리 테이블 갱신 개념도 (상대 변화율 보간)
# ---------------------------------------------------------------------------
def fig5():
    pred = [r for r in read_csv("pred_SSG.csv") if r["cell"] == "INV_X1" and r["arc"] == "A_r_ZN_f" and r["meas"] == "delay"]
    grid = {(int(r["slew_idx"]), int(r["load_idx"])): float(r["dv_rel_pred"]) for r in pred}
    fig, ax = plt.subplots(figsize=(6.3, 3.4))
    ax.set_xlim(0, 12); ax.set_ylim(0, 6); ax.axis("off")
    # model grid
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
    # arrow
    arrow(ax, 4.2, 3.3, 5.5, 3.3)
    ax.text(4.85, 3.55, "이중 선형 보간\n(격자 밖은 경계값)", ha="center", va="bottom", fontsize=7.5)
    # library table
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
    ax.text(6, 5.95, "[도 5]", ha="center", fontsize=10)
    finish(fig, "fig5.png")


# ---------------------------------------------------------------------------
# 도 6 : 예측값과 직접 시뮬레이션 값의 비교
# ---------------------------------------------------------------------------
def fig6():
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
    fig.suptitle("[도 6]", fontsize=10, y=1.02)
    fig.tight_layout()
    finish(fig, "fig6.png")


# ---------------------------------------------------------------------------
# 도 7 : 장치 블록도
# ---------------------------------------------------------------------------
def fig7():
    fig, ax = plt.subplots(figsize=(6.3, 4.0))
    ax.set_xlim(0, 12); ax.set_ylim(0, 7.5); ax.axis("off")
    ax.add_patch(Rectangle((0.4, 0.5), 8.6, 6.2, fc="white", ec=BLACK, lw=1.2))
    ax.text(0.6, 6.4, "장치 (700)", fontsize=9, va="center")
    # processor with modules
    ax.add_patch(Rectangle((0.7, 0.9), 4.6, 5.2, fc="white", ec=BLACK, lw=1.0))
    ax.text(0.9, 5.8, "프로세서 (710)", fontsize=8.5, va="center")
    mods = ["민감도 획득부 (711)", "그룹 분류부 (712)", "민감도 합산부 (713)",
            "정합성 검증부 (714)", "변화량 산출부 (715)", "라이브러리 생성부 (716)"]
    for n, m in enumerate(mods):
        box(ax, 1.0, 4.9 - n * 0.72, 4.0, 0.6, m, fs=7.5)
    box(ax, 5.9, 4.6, 2.8, 1.3, "메모리 (720)\n명령어, 작업 데이터", fs=8)
    box(ax, 5.9, 2.5, 2.9, 1.7, "저장부 (730)\n넷리스트, 소자 모델\n민감도 DB, 공칭 라이브러리\n변동점 정의", fs=7)
    box(ax, 5.9, 1.0, 2.8, 1.2, "입출력부 (740)", fs=8)
    arrow(ax, 5.3, 5.25, 5.9, 5.25); arrow(ax, 5.9, 5.0, 5.3, 5.0)
    arrow(ax, 5.3, 3.5, 5.9, 3.5); arrow(ax, 5.9, 3.3, 5.3, 3.3)
    arrow(ax, 5.3, 1.6, 5.9, 1.6)
    box(ax, 9.6, 4.4, 2.2, 1.2, "회로 시뮬레이터", fs=8)
    box(ax, 9.6, 2.3, 2.2, 1.2, "라이브러리\n특성화 도구", fs=8)
    box(ax, 9.6, 0.5, 2.2, 1.0, "STA 도구", fs=8)
    arrow(ax, 8.7, 1.6, 9.6, 1.0); arrow(ax, 9.6, 2.9, 8.7, 2.9); arrow(ax, 9.6, 5.0, 8.7, 3.9)
    ax.text(6, 7.2, "[도 7]", ha="center", fontsize=10)
    finish(fig, "fig7.png")


if __name__ == "__main__":
    fig1(); fig2(); fig3(); fig4(); fig5(); fig6(); fig7()
