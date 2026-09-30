# TT signoff는 global·local variance의 RSS 합산으로 성립한다

TT corner signoff의 기술적 근거는 (1) process variation이 die-to-die(global)와 within-die(local) 성분의 독립 합으로 분해되어 분산이 가산된다는 사실(σ_total² = σ_global² + σ_local²), (2) path를 따라 global 성분은 선형으로, local 성분은 RSS로 누적되므로 SS/FF corner 위에 LVF sigma를 얹는 관행이 두 성분을 선형 합산(3σ_g + 3σ_l)하여 통계적으로 일관된 값 3√(σ_g² + σ_l²)보다 최대 41 % 큰 margin을 만든다는 점, (3) global 성분은 launch clock·data·capture clock을 함께 움직여 slack에서 common-mode로 상쇄되고 잔여분은 mistracking뿐이라는 점의 조합이다. 이 세 요소는 각각 TSMC US 8,275,584의 σ_local = √(σ_total² − σ_global²) claim, IBM canonical form SSTA와 PrimeTime/Tempus의 RSS 누적, canonical form의 slack 대수에서 확인된다. 조사 범위 안에서 "TT signoff"를 방법론 이름으로 내걸고 silicon 수치까지 보고한 공개 논문은 없었고, 가장 근접한 claim은 Samsung US 9,977,845(local random + global variation 정보를 담은 library, global 값은 SS/FF에서 특성화한 뒤 3으로 나눠 1σ로 저장, slack은 두 값의 statistical sum)다. PrimeTime과 Tempus는 local sigma의 K-sigma corner와 mean/sigma guardband만 제공하고 native global variation 항이 없으므로, TT + global margin flow는 사용자가 guardband로 구성해야 하며 RC corner의 correlated BEOL 성분, voltage/temperature, low-VDD non-Gaussian, aging, IR drop, Vt-class·N/P·BEOL mistracking은 별도 corner 또는 guardband로 남는다.

## 결론 요약: 세 질문에 대한 직접 답변

**Q1. TT corner에서 signoff할 수 있는 기술적 근거.** foundry statistical model은 σ_total을 all-device 분포의 3σ, σ_global을 die-median 분포의 3σ로 정의하고 σ_local을 뺄셈 σ_local = √(σ_total² − σ_global²)으로 얻는다([TSMC US 8,275,584](https://patentimages.storage.googleapis.com/pdfs/US8275584.pdf), 원문 확인). SSG/FFG global corner는 이 σ_global만 담고 local은 Monte Carlo 또는 LVF에 맡기는 구조다([SemiWiki/CLKDA](https://semiwiki.com/x-subscriber/clk-design-automation/4481-variation-alphabet-soup/), 초록·검색 요약 확인). global 성분은 chip 전체에서 완전 상관이므로 N-stage path에서 σ_path,global = Σσ_g,i로 선형 누적되고, local 성분은 독립이므로 σ_path,local = √Σσ_l,i²로 누적된다([PrimeTime User Guide 13장](https://github.com/assrs/eda), 원문 확인; [EDN POCV](https://www.edn.com/parametric-on-chip-variation-a-step-towards-accurate-timing-analysis/), 초록·검색 요약 확인). corner + LVF 방식은 μ + 3σ_g,path + K·σ_l,path를 쓰지만 결합 분포의 참 K-sigma 값은 μ + K·√(σ_g,path² + σ_l,path²)이며, 두 값의 차이가 TT signoff가 회수할 수 있는 pessimism이다(유도, 2.2절). 여기에 launch/capture clock 공통 성분의 상쇄(canonical form에서는 slack 계수 s_i = rat_i − at_i가 자동으로 0에 가까워짐)가 더해진다. 단 D2D variation은 chip FMAX의 분산을 결정하므로(Bowman JSSC 2002) path 평균으로 사라지지 않고, TT 기준 flow는 global 성분을 corner projection 또는 명시적 σ_g margin으로 반드시 되돌려 넣어야 한다.

**Q2. global과 local을 한 번에 반영하는 방법.** 네 가지가 확인된다. (a) IBM canonical form SSTA: A = a₀ + Σ aᵢ ΔXᵢ + a_r ΔR로 모든 timing 값을 표현하고, 같은 canonical slack을 임의 corner로 projection한다(ΔXᵢ = 0이면 TT projection). (b) hybrid corner + POCV/SOCV/LVF: global은 SSG/FFG library corner에, local은 arc별 sigma에 두는 현행 산업 표준. (c) statistical/total corner library: chip-mean + OCV + aging + N/P mistrack 범위를 statistical timing tool로 돌려 3σ WC statistical corner를 Liberty 값으로 기록(IBM US 8,413,095), 또는 corner library 사이를 사용자 confidence level로 보간(Cadence US 7,487,475), Monte Carlo에서 K-sigma corner 추출(Cadence US 9,805,158). (d) TT library에 global variation 값을 1σ로 정규화해 실어 두고 slack에서 local과 RSS 합산(Samsung US 9,977,845), 또는 equivalent parameter로 global 분포를 MC로 만들어 local과 결합(Synopsys US 12,430,486). 상용 timer에는 native global 항이 없어 (b)와 (d)를 사용자 guardband로 조합하는 것이 실무적 구현이다.

**Q3. global-local 관계 모델링 방법.** 기본은 additive/nested variance model(Stine–Boning 1997의 f_RAW = f_WLV + f_DLV + f_INTERACTION + ε, nested ANOVA)이며 그 위에 네 가지 확장이 있다. spatial correlation model(grid + PCA, quad-tree, Matérn형 ρ(v) with nugget)은 within-die correlated 성분을 region별 공유 source로 바꿔 canonical form에 넣는다. mismatch model(Pelgrom σ²(ΔP) = A_P²/(WL) + S_P²D²)은 parameter 수준에서 corner에 독립이지만, delay 수준 local sigma는 ∂D/∂Vt가 overdrive 감소로 커져 SS·low-VDD corner에서 크게 증가한다(Dreslinski 2010: 0.4 V에서 약 5배). 그래서 LVF는 PVT corner별로 특성화된다. non-Gaussian moment model(mean shift, std_dev, skewness)은 low-VDD의 skew를 담는다. global-local 독립성은 공학적 가정이며, US 8,271,256은 local 크기와 global shift의 상관 가능성을 명시하고, N/P global 상관이 약할 때(R² ≈ 0.15) SSGNP corner가 3σ를 약 2.5σ로 조인다. 측정 수치는 planar 130/90/45 nm와 Intel 14 nm single-fin σ_Vt(19/24 mV) 정도만 공개되어 있고, FinFET/GAA node의 σ_global : σ_local 비율은 공개 자료에서 찾지 못했다.

## TT signoff의 기술적 근거: 분산은 가산되고 path에서는 global만 선형 누적된다

### 분해 모델이 corner와 LVF의 역할을 나눈다

process variation의 표준 분해는 독립 성분의 nested 합이다. 각 수준(lot, wafer, die, within-die systematic, within-die random)이 독립 분산 항을 기여하므로

    σ²_total = σ²_L2L + σ²_W2W + σ²_D2D + σ²_WID,sys + σ²_WID,rand

이고, 실무에서는 inter-die 항을 global 하나로, within-die 항을 local 하나로 묶어

    σ²_T = σ²_G + σ²_L

로 쓴다. Stine–Boning–Chung의 공간 분해(f_RAW(x,y) = f_WLV + f_DLV + f_INTERACTION + ε)와 nested ANOVA variance component 추정이 이 모델의 출처다([Boning/Chung ECS 1997 preprint](https://boning.mit.edu/wp-content/uploads/2022/11/ECS97-paper-preprint-1.pdf), 초록·검색 요약 확인; [Stine et al., IEEE TSM 1997](https://boning.mit.edu/publications/journal-papers/), 서지만 확인). TSMC의 통합 모델 특허는 같은 식을 σ_total² = σ_local² + σ_global² + A(A는 무시 가능한 계수)로 쓰고, 50개 이상(바람직하게는 1,000개 이상)의 die에서 die당 15개 이상의 동일 device를 측정하여 die median의 3σ를 σ_global, 전체 data의 3σ를 σ_total로 정의한 뒤 σ_local = √(σ_total² − σ_global²)로 얻는다. "median 값은 local variation에서 실질적으로 자유롭다"는 것이 global 항 분리의 근거다([US 8,275,584](https://patentimages.storage.googleapis.com/pdfs/US8275584.pdf), 원문 확인). TSMC의 compact model 논문 제목 자체가 이 모델이다: 이웃한 두 device에 대해 Id1 = Id0 + G + L1, Id2 = Id0 + G + L2, 즉 공유 global offset G와 독립 local offset Lᵢ([Lin et al., SISPAD 2012](http://in4.iue.tuwien.ac.at/pdfs/sispad2012/10-5.pdf), 초록·검색 요약 확인).

이 분해가 signoff에 갖는 의미는 Bowman–Duvall–Meindl이 정리했다. die-to-die 성분은 die 위의 모든 element를 같은 방향으로 움직이고, within-die 성분은 path마다 독립이다. 그 결과 within-die variation은 다수 critical path의 max를 통해 FMAX의 **평균**을 이동시키고, die-to-die variation은 FMAX의 **분산** 대부분을 결정한다([Bowman et al., JSSC 2002](https://dblp.org/db/journals/jssc/jssc37.html), 초록·검색 요약 확인). global 항은 die 하나에 대해서는 결정론적 shift이므로 corner로 다루는 것이 정확하고, local 항은 path 위에서 max-of-N과 RSS 효과가 있어 corner로는 pessimism 없이 표현할 수 없다. corner(global)와 LVF(local)의 역할 분담은 이 통계적 성질에서 나온다.

### path에서 global은 Σσ, local은 √Σσ²로 누적된다

stage delay dⱼ의 sigma를 σⱼ, stage 간 상관을 ρⱼₖ라 하면 path 분산은

    σ²_path = Σⱼ σⱼ² + 2 Σⱼ<ₖ ρⱼₖ σⱼ σₖ

이다. ρ = 1(global)이면 σ_path,global = Σ σ_g,i로 stage 수 N에 선형이고, ρ = 0(local)이면 σ_path,local = √Σ σ_l,i²로 √N에 비례한다. 두 성분이 함께 있으면

    σ_path = √( (Σᵢ σ_g,i)² + Σᵢ σ_l,i² )

이다. canonical form(3.1절)에서는 이것이 σ²_path = Σᵢ(Σⱼ a_j,i)² + Σⱼ a²_j,r로 나오며 두 극한을 모두 포함한다(표준 유도; 식은 검색 요약에서 구조만 확인). 동일 stage N개라면 σ_path = √(N²g²σ_G² + N s²) = N·g·σ_G·√(1 + s²/(N g² σ_G²))로, global 항 O(N), local 항 O(√N)이다. PrimeTime User Guide는 이를 "gate가 많은 긴 path는 gate 간 random variation이 서로 상쇄되어 total variation이 작고, 물리적으로 넓게 퍼진 path는 systematic variation이 크다"로 서술하고([PrimeTime User Guide, Advanced On-Chip Variation](https://github.com/assrs/eda), 원문 확인), EDN의 POCV 기사는 "correlated global variation은 path 길이에 선형, uncorrelated local variation은 제곱근으로 증가한다"고 쓴다([EDN](https://www.edn.com/parametric-on-chip-variation-a-step-towards-accurate-timing-analysis/), 초록·검색 요약 확인).

AOCV depth table은 이 √N 법칙의 corner 투영이다. 동일 독립 stage n개의 상대 3σ 폭은

    f(n) = (3·σ_n)/mean_n = ((3·σ)/mean)·(1/√n) = k/√n

이며, PrimeTime S-2021.06-SP5와 Tempus 21.14 동작을 기준으로 정리된 gist가 이 식과 예시 table(depth 1…8 → 1.1, 1.05, 1.033, 1.025, 1.020, 1.017, 1.014, 1.013)을 준다([brabect1 gist](https://gist.github.com/brabect1/6281f4cf9fb53002fb17f15fa3bf4f62), 원문 확인). stage당 3σ/mean = 15 %라면 25-stage path의 3σ 폭은 3 %가 되어, 실무 인용치 "inverter 1σ local delay variation ≈ 5 %, 3σ의 path 영향은 path 길이에 따라 8 %에서 3 %"와 일치한다([Semiconductor Engineering](https://semiengineering.com/process-variation-not-a-solved-issue/), 초록·검색 요약 확인). PrimeTime `report_timing -variation`의 예제도 같은 산술을 보여 준다: 두 stage의 (Mean, Sensit) = (1.00, 3.00), (1.00, 2.00)이 path (2.00, 3.61)로 합쳐지고(√(3² + 2²) = 3.606), K = 3 corner 값은 12.82다. 3σ 증분을 단순 합산했다면 17.00이므로 corner 값은 25 %, variation 항(10.8 vs 15.0)은 28 % 작다([PrimeTime User Guide, Reporting the POCV Analysis Results](https://github.com/assrs/eda), 원문 확인; 비율은 유도).

### corner + LVF는 3σ_g + Kσ_l을 선형으로 더한다 (이중 계상, 유도)

corner signoff는 "모든 global variation을 3σ 극단 corner에 고정"하고 local은 early/late split 또는 sigma로 얹는다([Tetelbaum 2014](https://anysilicon.com/wp-content/uploads/2014/10/Corner_based_Signoff_paper_Jan_2014a.pdf), 초록·검색 요약 확인). IBM의 hybrid multi-corner 특허도 "conventionally, every global variation is set to its three-standard deviation (3 sigma) extreme corners"라 쓰고 local(statistically independent) parameter만 RSS로 묶는다([US 7,555,740](https://patentimages.storage.googleapis.com/pdfs/US7555740.pdf), 원문 확인). 따라서 SSG(global-only) corner에 LVF를 얹은 corner 값은

    D_corner+LVF = μ + 3σ_G,path + K·σ_L,path

이고, 결합 분포의 참 K-sigma 값은

    D_K = μ + K·√(σ_G,path² + σ_L,path²)

다. 두 값의 차이가 선형 합산 pessimism이다. 아래는 K = 3, σ_L' = σ_L/√n_eff(path의 유효 local sigma)로 놓은 유도 결과다(출처 없음, 본 리뷰의 계산).

| σ_L' / σ_G | corner + local 합산 3(σ_G + σ_L') | 참 3σ = 3√(σ_G² + σ_L'²) | variation 항 초과분 |
|---|---|---|---|
| 1.0 | 6.0 σ_G | 4.24 σ_G | 41 % |
| 0.5 | 4.5 σ_G | 3.35 σ_G | 34 % |
| 0.33 | 4.0 σ_G | 3.16 σ_G | 27 % |
| 0.1 | 3.3 σ_G | 3.015 σ_G | 9 % |

초과분의 크기는 σ_L'/σ_G 비율이 결정한다. 이 비율은 depth가 깊은 setup path에서는 작고(√n 평균), clock-to-Q + gate 한두 개인 hold path에서는 크다. 이중 계상 pessimism이 short-path/hold closure에서 가장 크게 체감되는 이유다(추정). 같은 산술을 다른 방향으로 쓰면, SS **total** corner(이미 local을 포함)에 LVF를 다시 얹는 경우 초과분은 σ_G와 무관하게 정확히 3σ_L'이다. TSMC 특허는 이 경우를 그림으로 설명한다: "total variation의 corner에 local variation을 적용하면 예측된 variation이 total variation보다 커진다 … 음영 부분이 낭비되는 design margin"이며, "σ_local은 σ_total의 일부이므로 항상 σ_total보다 클 수 없는데 기존 1/√(WL) mismatch model은 그보다 큰 σ_local을 주기도 한다"([US 8,275,584](https://patentimages.storage.googleapis.com/pdfs/US8275584.pdf), 원문 확인). SSG corner가 도입된 직접 이유가 이 이중 계상 제거다. 엔지니어 기록은 같은 cell의 delay 순서를 SSGNP < SSG < SS, FFGNP > FFG > FF로 정리한다([PVTCorner.txt](https://raw.githubusercontent.com/CaseyZhu/my_git_hub/7232a669a64df31377f70d0ef0268daf3c5f8fe4/PVTCorner.txt), 2차 자료).

IBM 특허의 수치 예도 같은 구조다. canonical slack 5 + 0.9ΔR + 0.6ΔA + 0.5ΔB를 worst-case 3σ corner로 projection하면 "5 − 3·(0.9 + 0.6 + 0.5) = 5 − 3·2 = −1"이다([US 8,458,632](https://patents.google.com/patent/US8458632), 초록·검색 요약 확인). 이것은 모든 source를 동시에 −3σ에 두는 box corner(선형 합)이고, 세 계수를 RSS한 통계적 3σ 값은 5 − 3·√(0.9² + 0.6² + 0.5²) = 5 − 3·1.19 ≈ 1.4다(유도). box corner 대비 RSS corner의 pessimism 비율은 Σ|aᵢ|/√Σaᵢ²로 1과 √(n+1) 사이에 있다.

SRAM worst-case corner 특허는 두 방식을 이름으로 구분한다. "G corner는 chip-mean Monte Carlo의 single-cell 3σ Iread 한계, P corner는 chip-to-chip과 within-chip을 모두 흔든 Monte Carlo에서 global과 local의 root-mean-square sum을 취한 것"이며, "global과 local을 합(sum)으로 더한 SRM corner가 더 보수적"이다([US 8,352,895](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/8352895), 초록·검색 요약 확인). 즉 sum corner와 RSS corner의 구분은 memory 설계에서는 이미 명문화된 관행이다.

### global 성분은 launch/capture 사이에서 상쇄되고 mistracking만 남는다

deterministic OCV corner는 launch clock과 data에 late derate, capture clock에 early derate를 동시에 적용한다([PrimeTime `set_timing_derate` 설명](https://github.com/assrs/eda), 원문 확인). 이것은 global shift가 launch와 capture에서 반대 방향으로 갈 수 있다고 가정하는 것과 같다. 물리적으로 공유되는 clock segment는 "동시에 빠르고 느릴 수 없다"는 것이 CRPR/CPPR의 근거이며([ecrionix CPPR](https://ecrionix.org/sta/day-10-clock-analysis/), 초록·검색 요약 확인), corner STA는 이 credit을 물리적 공통 segment에만 준다. canonical form에서는 사정이 다르다. slack S = RAT − AT도 canonical이고 공통 segment의 global 계수는 AT와 RAT에 같은 부호로 들어가 sᵢ = ratᵢ − atᵢ에서 상쇄된다. 독립 random 계수는 상쇄되지 않고 RSS된다. IBM은 이를 "common portion의 common path credit과 non-common portion의 RSS credit"으로 구분하고([Zolotov, ResearchGate profile](https://www.researchgate.net/profile/Vladimir-Zolotov-2), 초록·검색 요약 확인), 특허로는 post-CPPR slack에 latch-to-latch random delay의 RSS 값을 합쳐 clock skew 영향을 정량화한다([US 2012/0047477](https://patentimages.storage.googleapis.com/pdfs/US20120047477.pdf), 원문 확인). 공통 segment가 아닌 data path와 capture path 사이에서도 global shift의 setup 잔여분은 두 path의 global sensitivity **차이**에 비례하지 합이 아니다(추정).

상쇄되지 않는 것은 parameter 간 mistracking이다. Synopsys의 global mistracking 특허는 "transistor threshold voltage mistracking, doping mistracking, channel length mistracking, metal layer resistivity/track width/thickness mistracking"을 나열하고, signoff가 FF/TT/SS corner에서 수행됨을 전제로 corner 집합 대신 parameter variation의 region을 덮는 방식을 제안한다([US 11,893,332](https://patents.google.com/patent/US11893332B2/en), 초록·검색 요약 확인). Tempus는 같은 잔여분을 `set_vt_skew_derate -threshold_voltage_group SVT -fast 0.90 -slow 1.10`(-mean/-sigma 선택)로 모델링하고([Innovus Text Command Reference](https://github.com/assrs/eda), 원문 확인), PrimeTime 실무는 "OCV는 local process variation, MixedVt는 global process corner correlation을 derate로 모델링한다"고 정리한다([chipgun PrimeTime and Timing Derate](https://github.com/chipgun/nibaix.github.io/blob/master/2022/05/07/PrimeTime-and-OCV/index.html), 원문 확인). SSG corner를 TT로 옮기면 SS corner 안에 묻혀 있던 Vt-class·N/P·FEOL/BEOL mistracking 항을 명시적으로 되돌려 넣어야 한다.

