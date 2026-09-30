# TT signoff는 global·local variance의 RSS 합산으로 성립한다

TT corner signoff의 기술적 근거는 (1) process variation이 die-to-die(global)와 within-die(local) 성분의 독립 합으로 분해되어 분산이 가산된다는 사실(σ_total² = σ_global² + σ_local²), (2) path를 따라 global 성분은 선형으로, local 성분은 RSS로 누적되므로 SS/FF corner 위에 LVF sigma를 얹는 관행이 두 성분을 선형 합산(3σ_g + 3σ_l)하여 통계적으로 일관된 값 3√(σ_g² + σ_l²)보다 최대 41 % 큰 margin을 만든다는 점, (3) global 성분은 launch clock·data·capture clock을 함께 움직여 slack에서 common-mode로 상쇄되고 잔여분은 mistracking뿐이라는 점의 조합이다. 이 세 요소는 각각 TSMC US 8,275,584의 σ_local = √(σ_total² − σ_global²) claim, IBM canonical form SSTA와 PrimeTime/Tempus의 RSS 누적, canonical form의 slack 대수에서 확인된다. 조사 범위 안에서 "TT signoff"를 방법론 이름으로 내걸고 silicon 수치까지 보고한 공개 논문은 없었고, 가장 근접한 claim은 Samsung US 9,977,845(local random + global variation 정보를 담은 library, global 값은 SS/FF에서 특성화한 뒤 3으로 나눠 1σ로 저장, slack은 두 값의 statistical sum)다. PrimeTime과 Tempus는 local sigma의 K-sigma corner와 mean/sigma guardband만 제공하고 native global variation 항이 없으므로, TT + global margin flow는 사용자가 guardband로 구성해야 하며 RC corner의 correlated BEOL 성분, voltage/temperature, low-VDD non-Gaussian, aging, IR drop, Vt-class·N/P·BEOL mistracking은 별도 corner 또는 guardband로 남는다.

## 결론 요약: 세 질문에 대한 직접 답변

**Q1. TT corner에서 signoff할 수 있는 기술적 근거.** foundry statistical model은 σ_total을 all-device 분포의 3σ, σ_global을 die-median 분포의 3σ로 정의하고 σ_local을 뺄셈 σ_local = √(σ_total² − σ_global²)으로 얻는다([TSMC US 8,275,584](https://patentimages.storage.googleapis.com/pdfs/US8275584.pdf), 원문 확인). SSG/FFG global corner는 이 σ_global만 담고 local은 Monte Carlo 또는 LVF에 맡기는 구조다([SemiWiki/CLKDA](https://semiwiki.com/x-subscriber/clk-design-automation/4481-variation-alphabet-soup/), 초록·검색 요약 확인). global 성분은 chip 전체에서 완전 상관이므로 N-stage path에서 σ_path,global = Σσ_g,i로 선형 누적되고, local 성분은 독립이므로 σ_path,local = √Σσ_l,i²로 누적된다([PrimeTime User Guide 13장](https://github.com/assrs/eda), 원문 확인; [EDN POCV](https://www.edn.com/parametric-on-chip-variation-a-step-towards-accurate-timing-analysis/), 초록·검색 요약 확인). corner + LVF 방식은 μ + 3σ_g,path + K·σ_l,path를 쓰지만 결합 분포의 참 K-sigma 값은 μ + K·√(σ_g,path² + σ_l,path²)이며, 두 값의 차이가 TT signoff가 회수할 수 있는 pessimism이다(유도, "corner + LVF는 3σ_g + Kσ_l을 선형으로 더한다" 절). 여기에 launch/capture clock 공통 성분의 상쇄(canonical form에서는 slack 계수 s_i = rat_i − at_i가 자동으로 0에 가까워짐)가 더해진다. 단 D2D variation은 chip FMAX의 분산을 결정하므로(Bowman JSSC 2002) path 평균으로 사라지지 않고, TT 기준 flow는 global 성분을 corner projection 또는 명시적 σ_g margin으로 반드시 되돌려 넣어야 한다.

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

이다. canonical form("SSTA canonical form" 절)에서는 이것이 σ²_path = Σᵢ(Σⱼ a_j,i)² + Σⱼ a²_j,r로 나오며 두 극한을 모두 포함한다(표준 유도; 식은 검색 요약에서 구조만 확인). 동일 stage N개라면 σ_path = √(N²g²σ_G² + N s²) = N·g·σ_G·√(1 + s²/(N g² σ_G²))로, global 항 O(N), local 항 O(√N)이다. PrimeTime User Guide는 이를 "gate가 많은 긴 path는 gate 간 random variation이 서로 상쇄되어 total variation이 작고, 물리적으로 넓게 퍼진 path는 systematic variation이 크다"로 서술하고([PrimeTime User Guide, Advanced On-Chip Variation](https://github.com/assrs/eda), 원문 확인), EDN의 POCV 기사는 "correlated global variation은 path 길이에 선형, uncorrelated local variation은 제곱근으로 증가한다"고 쓴다([EDN](https://www.edn.com/parametric-on-chip-variation-a-step-towards-accurate-timing-analysis/), 초록·검색 요약 확인).

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


### TT signoff가 덮지 못하는 항목은 corner 또는 guardband로 남는다

TT library + LVF + global margin은 FEOL device의 global·local process 성분만 다룬다. 다음 항목은 별도 처리가 필요하다.

- **RC corner (BEOL).** PrimeTime의 via variation과 Tempus의 RC variation은 random·독립 성분만 통계 처리한다. Tempus `set_socv_rc_variation_factor`는 "global variation을 nominal delay의 percentage로 적용"하는 평탄한 wire-sigma이지 die-to-die BEOL parameter가 아니다([Innovus CUI Text Command Reference](https://github.com/assrs/eda), 원문 확인). Tempus의 layer 간 상관 옵션은 `statistical`(모든 layer 독립) 또는 `binomial`이고, `-enable_corner_based_beol`로 corner BEOL을 고정할 수 있다(원문 확인). correlated BEOL 성분은 여전히 cworst/cbest 등 RC corner 또는 tightened/statistical RC corner로 덮어야 한다([Kahng, Dobre, Chan, ICCD 2014](https://www.researchgate.net/publication/289572597_Improved_signoff_methodology_with_tightened_BEOL_corners), 제목만 확인).
- **Voltage/temperature.** environmental 변수는 process 분포가 아니다. PrimeTime 실무는 "OCV derate는 local process만 담고, V/T·reliability derate는 -aocvm_guardband/-pocvm_guardband로 추가"한다([chipgun](https://github.com/chipgun/nibaix.github.io/blob/master/2022/05/07/PrimeTime-and-OCV/index.html), 원문 확인). temperature inversion은 corner 열거 또는 온도별 재특성화 + margin으로만 다뤄진다([LSI US 8,645,888](https://patentimages.storage.googleapis.com/pdfs/US8645888.pdf), 원문 확인); 통계 signoff와 결합한 자료는 없다.
- **low-VDD non-Gaussian.** VDD ≤ 0.5 V에서 gate delay σ는 nominal delay에 필적하고 PDF는 강하게 non-Gaussian이다([TI US 8,302,047](https://patentimages.storage.googleapis.com/pdfs/US8302047.pdf), 원문 확인). LTAB는 2017년 mean shift, standard deviation, skewness의 moment-based LVF를 비준했다([Synopsys 2017-02-27](https://news.synopsys.com/2017-02-27-Synopsys-Announces-Expansion-of-Liberty-Modeling-Standard-Paving-Way-for-Ultra-Low-Power-IC-Design), 초록·검색 요약 확인). μ ± Kσ가 아니라 3-moment 분포의 quantile로 corner 값을 잡아야 한다.
- **LVF sigma의 corner 의존성.** LVF는 PVT corner별로 특성화되므로 SS/low-V corner의 local sigma는 TT sigma보다 크다. TT에서 특성화한 sigma로 SS tail을 덮으면 local 항이 과소평가된다(추정, "Pelgrom mismatch" 절의 Dreslinski 5배 근거).
- **aging, IR drop.** PrimeTime은 guardband(-pocvm_guardband, mean과 sigma 모두 scale), Tempus는 `set_advanced_variation_mode -scope {vtskew | aging | wire_variation | beol | lle | layout_effect | lde}`와 `setDelayCalMode -early_irdrop_data_type`으로 다룬다(원문 확인). 통계 항이 아니라 derate다.
- **mistracking.** "global 성분은 launch/capture 사이에서 상쇄되고 mistracking만 남는다" 절 참조. corner 안에 묻혀 있던 항이므로 TT 기준에서는 명시적으로 추가해야 한다.
- **crosstalk.** "POCV는 non-SI cell delay에만 적용되며 timing window 정렬 변화로 delta delay를 간접 변경"하고, `set_timing_derate -static/-dynamic`은 `-pocvm_guardband`와 함께 쓸 수 없다(원문 확인).

### 비교표 (a): pessimism 발생 기제

| 항목 | corner-based (SS/FF + OCV/AOCV) | corner + POCV/LVF (SSG/FFG + sigma) | statistical / TT + global·local RSS |
|---|---|---|---|
| global 처리 | 3σ corner 고정 (total corner는 local 포함) | 3σ global corner 고정 (SSG/FFG, local 제외) | nominal(TT) + σ_g,path 항 또는 canonical projection |
| local 처리 | flat derate 또는 depth/distance table (선형 합 가정) | arc별 σ, path에서 RSS, K-sigma corner | arc별 σ, RSS |
| global–local 결합 | 선형 (SS total corner + derate는 local 이중 계상) | 선형: 3σ_g + Kσ_l | RSS: K√(σ_g² + σ_l²) |
| depth 효과 | OCV: 없음 (긴 path 과보수, 짧은 path 과낙관); AOCV: k/√n table | √N 자동 | √N 자동 |
| launch/capture common-mode | CRPR로 물리 공통 segment만 | 동일 | canonical form: global 계수 자동 상쇄 + random RSS credit |
| N/P 상관 | SS(완전 상관) 또는 SSGNP(3σ→~2.5σ) | 동일 | global 벡터의 covariance로 표현 가능 |
| graph merge pessimism | 없음 | statistical max 보정 (PrimeTime "statistical graph pessimism", Tempus `mean_and_three_sigma_bounded`) | 동일 |
| 남는 pessimism | 매우 큼 (모든 항 선형) | 3σ_g + Kσ_l의 선형 합, mistracking 미분리 | corner 미커버 항목(RC, V/T, aging, IR)은 여전히 corner/guardband |
| 공개된 회수량 | — | path-based SOCV/LVF vs GBA AOCV: setup 150 ps, hold 200 ps 평균 개선([Cadence WP](https://www.cadence.com/en_US/home/resources/white-papers/addressing-process-variation-and-reducing-timing-pessimism-at-16nm-and-below-wp.html), 초록·검색 요약 확인); SOCV로 worst-case margin 10–15 % 감소([Cadence Liberate Variety](https://www.cadence.com/en_US/home/tools/custom-ic-analog-rf-design/library-characterization/variety-statistical-characterization-solution.html), 초록·검색 요약 확인) | 공개 수치 없음 (미확인) |

## global과 local을 동시에 반영하는 방법: canonical form이 원형이고 상용 flow는 hybrid다

### SSTA canonical form은 global source와 random 항을 한 식에 담고 임의 corner로 projection한다

Visweswariah 등의 first-order canonical form은 모든 delay, arrival time, slack을

    A = a₀ + Σᵢ₌₁ⁿ aᵢ ΔXᵢ + a_r ΔR_A

로 쓴다. a₀는 nominal, ΔXᵢ ~ N(0,1)은 chip 전체가 공유하는 global source(L_eff, V_t, metal thickness, temperature, Vdd 등), aᵢ는 1차 sensitivity, ΔR_A ~ N(0,1)은 A에만 속한 independent random 항이다. global과 local의 구분은 순전히 index로 이루어진다([Visweswariah et al., DAC 2004](https://people.eecs.berkeley.edu/~alanmi/research/timing/papers/sta_ibm.pdf), 초록·검색 요약 확인; 구조는 [IBM US 7,428,716](https://patentimages.storage.googleapis.com/pdfs/US7428716.pdf) 원문에서 "deterministic portion a₀, correlated (or global) portion, independent (or local) portion"으로 확인). 합은 계수 덧셈이고 random 계수만 RSS된다(c_r = √(a_r² + b_r²)); max는 Clark(1961)의 식으로 mean·variance를 맞추고 tightness probability T_A = Φ((a₀ − b₀)/θ), θ = √(Σ(aᵢ − bᵢ)² + a_r² + b_r²)로 계수를 재구성한다(cᵢ = T_A aᵢ + (1 − T_A) bᵢ; 검색 요약에서 θ와 T_A 확인, 나머지는 표준형 재구성). IBM 특허는 "RSS 규칙"을 명시한다: "propagation of known independently random terms allows taking the square root of the sum of the squares … rather than straight summation as in deterministic STA"([US 9,400,864](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/9400864), 초록·검색 요약 확인).

projection은 같은 canonical slack에 corner 값을 대입하는 것이다: S(corner) = s₀ + Σᵢ sᵢ ΔXᵢ^corner ± k·(random 항). ΔXᵢ = 0이면 TT projection, ΔXᵢ = ±3이면 SS/FF projection이다. IBM은 이를 특허로 갖고 있다. US 8,141,012는 "full parameter space에서 SSTA를 한 번 돌리고 path별로 k개 corner를 선택해 deterministic 값으로 projection한 뒤 worst slack corner에서 closure"를 claim하고, 각 parameter는 −3σ에서 +3σ까지 변한다([US 8,141,012](https://patentimages.storage.googleapis.com/pdfs/US8141012.pdf), 원문 확인). US 2012/0117527은 "deterministic·corner-based인 첫 parameter와 그것과 non-separable한 통계 parameter"를 단일 run으로 처리하고 corner 값 대입으로 projection한다(원문 확인). US 7,117,466(2003)은 global parameter는 일관된 값으로, separable parameter는 각각 worst 값으로 두어 corner 열거 없이 path별 worst 조합을 구한다(원문 확인). IBM은 이 체계를 EinsStat/EinsTimer로 45 nm ASIC signoff에 썼고 "약 62 GB, 19시간"의 run을 보고했다([45 nm ASIC SSTA 논문, academia.edu 사본](https://www.academia.edu/4136360/Timing_Closure_in_45Nanometer_ASICs_Using_Statistical_Static_Timing_Analysis_Design_Methodology), 초록·검색 요약 확인, 저자·venue 미확인). 학계의 확장 canonical form(WARF US 7,350,171)은 X = μ_X + Σ α_X,i Rᵢ + Σ β_X,j Gⱼ로 node sensitivity와 global sensitivity를 claim에 명시한다(원문 확인).

### hybrid corner + POCV/SOCV/LVF가 현행 산업 표준이다

Synopsys의 combined-modeling 특허 배경은 산업 기준선을 한 문장으로 준다: "STA에서 local process variation은 POCV로 한 번의 run 안에서, global process variation은 FF/TT/SS corner의 여러 run으로 모델링된다"([US 12,430,486](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/12430486), 초록·검색 요약 확인). Cadence Signoff Summit(2013)도 "global variation은 corner로, local variation은 corner로 다루기 매우 어렵다"고 정리했다([Cadence Industry Insights](https://community.cadence.com/cadence_blogs_8/b/ii/posts/signoff-summit-an-update-on-ocv-aocv-socv-and-statistical-timing), 초록·검색 요약 확인). foundry는 "SSG/TTG/FFG global corner는 between-wafer variance만 포함하고 on-die variance는 global corner 주위의 Monte Carlo local parameter로 분리"하며 "global corner가 AOCV, POCV, SOCV, LVF의 기초"다([SemiWiki/CLKDA](https://semiwiki.com/x-subscriber/clk-design-automation/4481-variation-alphabet-soup/); [Kahng DAC 2015](https://vlsicad.ucsd.edu/Publications/Conferences/330/c330.pdf), 초록·검색 요약 확인). 실제 library 이름이 이를 보여 준다: `dti_tm16ffc_90c_7p5t_stdcells_ssgnp_0p72v_125c_rev1p0p0.lib`(TSMC 16FFC), `sch240mc_cln07ff41001_base_svt_c11_ssgnp_cworstccworstt_max_0p765v_125c.lib`(N7), `ffgnp_0p88v_0p88v_m40c`, `tt_0p80v_0p80v_25c`(원문 확인, 공개 flow script). 한 A14급 flow의 corner manifest는 `process: [SS, TT, FF, SSGNP, FFGNP, local_NFET, local_PFET]`를 나열한다([elizaOS/research](https://github.com/elizaOS/research), 원문 확인).

이 방식의 결합 규칙은 "corner + LVF는 3σ_g + Kσ_l을 선형으로 더한다" 절의 선형 합이다. PrimeTime의 derate 합성은 `<total derate> = <AOCV derate> × <aocvm_guardband scaling> + <flat add margin>`이고([gist](https://gist.github.com/brabect1/6281f4cf9fb53002fb17f15fa3bf4f62), 원문 확인), POCV에서는 `Cell delay derated = "Cell delay" × ("POCVM guardband" × "POCVM distance derate" + "Incremental derate")`, `Cell delay sigma = "POCVM delay sigma" × ("POCVM guardband" × "POCVM coef scale factor")`다([PrimeTime User Guide](https://github.com/assrs/eda), 원문 확인). 즉 D ≈ D_corner·(1 + K·σ_local/μ) + margin의 multiplicative stacking이며, global 항은 D_corner 안에 3σ로 고정되어 있다. Kahng은 signoff 기준의 변화로 "tightened corners and signoff at typical"을 언급하지만 본문 수치는 확인하지 못했다([Kahng DAC 2015](https://vlsicad.ucsd.edu/Publications/Conferences/330/c330.pdf), 초록·검색 요약 확인).

### statistical corner / total corner library는 global·local 통계를 library 값으로 구워 넣는다

IBM US 8,413,095는 "chip mean과 OCV process, aging, N/P mistrack parameter 범위"에 statistical timing tool을 적용해 "delay와 power의 WC statistical corner"를 구하고 이를 단일 worst-case Liberty library에 기록한다. 설명부는 Monte Carlo로 "3σ WC statistical corner"를 구하고, library 값을 "같은 statistical corner 정의와 global parameter를 scale해 맞춘 test macro의 chip sign-off statistical delay requirement"와 비교한다([US 8,413,095](https://patentimages.storage.googleapis.com/pdfs/US8413095.pdf), 원문 확인). Cadence의 Kriplani 계열(US 7,487,475 / 8,448,104 / 8,645,881)은 BC/TC/WC library의 confidence level 사이를 사용자 지정 k(예: k = 3 ≈ 99.87 %)로 보간해 "그 confidence level의 library를 만들지 않고" 성능을 추정한다(원문 확인). Cadence US 9,805,158은 Monte Carlo 소수 sample에서 K-sigma corner를 추출하며 "K-sigma corner는 circuit과 performance measure에 의존하므로 foundry의 FF/SS corner가 적절하지 않을 수 있다"고 쓴다([FPO](https://www.freepatentsonline.com/9805158.html), 초록·검색 요약 확인). Solido US 8,494,670은 "n-sigma hypercube" 대신 target yield로 구동되는 MC sample을 corner로 삼는다(원문 확인). Toshiba US 2009/0249272는 SSTA slack sensitivity로 path별 corner 조건을 정한 뒤 deterministic STA로 signoff하는 SSTA→corner→STA flow다(원문 확인). NEC Electronics US 2009/0019408은 PCA 주성분별 ±3σ permissible range를 global(chip 간)과 local(chip 내)로 나누어 core-macro model이 둘을 함께 덮도록 claim한다(원문 확인).

이 방식의 주의점 하나. global spread를 포함한 "total" sigma를 TT에서 LVF로 특성화해 timer에 주면, timer는 cell을 독립으로 취급하므로 global 항이 √N으로 평균되고 launch/capture common-mode credit도 사라진다. total-sigma LVF는 global 항을 과소평가한다(추정; PrimeTime "각 cell instance는 통계적으로 독립" 원문 확인에 근거).

### Samsung US 9,977,845와 Synopsys US 12,430,486이 목표 개념에 가장 가깝다

Samsung US 9,977,845(KR 10-2015-0010681, 2015-01-22 우선권)의 독립 claim은 "local random variation 정보와, global variation parameter 집합에 기초해 얻은 global variation 정보를 포함하는 library를 load"하고, arc delay를 계산한 뒤 "delay, local random variation 정보, global variation 정보에 기초해" 위반을 판정하며, slack은 "path의 local random variation 값과 global variation 값의 statistical sum"으로 계산한다. 설명부는 global 값을 "SS와 FF의 최소 두 corner에서 특성화"하고 "corner가 3σ 수준이면 3으로 나누어 1σ로 library에 기록"하며, "path의 total variation은 local random 값과 global 값의 root-square-sum"이고, "library에 없는 corner의 global 값도 계산"하며 "operating speed 분포는 3σ 수준일 수 있다"고 쓴다([USPTO 9977845](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/9977845), 초록·검색 요약 확인; 발명자·정확한 등록일·KR 공개번호 미확인). 즉

    σ_path,total = √( G_path² + L_path² ),  G_arc = (3σ corner에서 특성화한 global 값)/3

의 구조이며, nominal delay + K·σ_path,total이 곧 "TT + combined global/local margin" signoff다. 같은 출원인의 US 10,192,015(KR 2016-0147435 A)는 GBA로 critical path를 뽑고 PBA를 각 group의 최대 "criticality sigma level"에서 돌려 group별 path 수로 yield를 추정한다(초록·검색 요약 확인). 이는 path별 sigma-parameterized STA가 2015–2016년에 이미 통계적 yield metric으로 쓰였음을 시사한다.

Synopsys US 12,430,486(우선권 2022-11-30, 등록 2025-09-30)은 "global parameter 집합을 equivalent parameter로 모델링하고 MC로 metric의 global 분포를 구한 뒤" local과 결합하며, "FF/TT/SS library가 있는 V/T corner에서는 interpolation 기법"을 쓴다(초록·검색 요약 확인; claim 1 미확인). Synopsys US 11,893,332(2021-08-05 출원, 2024-02-06 등록)는 corner 집합 대신 mistracking parameter의 region을 덮는 "region-based" 분석으로 "margin-based signoff보다 정확"하다고 주장하며 "corner-based와 statistical variation model을 모두 포함"한다(초록·검색 요약 확인). IBM US 7,555,740(2007)은 반대 방향의 hybrid다: statistically dependent(global) parameter는 worst corner에, independent parameter는 best/worst corner slack 차이로 sensitivity S를 구해 RSS = n·√Σ(S_x σ_x)²(n < 6) credit을 준다(원문 확인; 분모가 σ_b + σ_w인지 σ_b − σ_w인지는 두 기록이 다르므로 원문 재확인 필요).

### clock common-mode는 canonical form에서만 자동이고 corner flow는 derate로 흉내 낸다

canonical form의 global 계수 상쇄는 "global 성분은 launch/capture 사이에서 상쇄되고 mistracking만 남는다" 절에 있다. corner flow에서 이를 부분적으로 흉내 내는 장치는 다음이다. TI US 8,806,413은 clock-tree cell에 별도 AOCV table(flat 구간 k2 > k1)을 두어 clock path의 variation penalty를 줄인다(원문 확인). TSMC US 8,365,115는 "non-common timing-path element" 수만으로 derate를 정하는 SBOCV이며, table 생성 조건으로 "VARIATION TYPE SSG [W/O GLOBAL VARIATION], TRANSITION @TT, N*SIGMA 5.0, TECHNOLOGY 45LP"를 인쇄한다(원문 확인). Altera US 7,926,019는 nearest common ancestor 기준 CCPP group을 열거해 pessimism을 제거한다(원문 확인). 대칭적 반례도 있다: TSMC US 8,972,919는 double-patterning misalignment의 두 극단 coupling을 launch와 capture에 반대로 배정해 systematic 변수를 corner식으로 다룬다(원문 확인). launch/capture 사이에서 실제로 상쇄되는 global margin의 비율을 정량화한 공개 자료는 없다(미확인).

## global-local 관계 모델링 방법: additive 분해가 기본이고 delay sigma만 corner에 종속된다

### nested variance 분해와 TSMC의 뺄셈 정의

parameter p의 device i(die d) 값은 p_{d,i} = p₀ + g_d + s(xᵢ, yᵢ) + r_{d,i}로 쓰이고 Var = σ²_G + σ²_S + σ²_R이다(global / within-die systematic·spatial / within-die random; 표준형). foundry 실무는 s(x,y)를 "distance/spatial effect"로 local 항에 접어 넣는다([TSMC SISPAD 2012](http://in4.iue.tuwien.ac.at/pdfs/sispad2012/10-5.pdf), 초록·검색 요약 확인). TSMC US 8,275,584의 정의를 다시 쓰면

    σ_total = 3·std(모든 die × 모든 device),   σ_global = 3·std(die별 median)
    σ_local = √(σ_total² − σ_global²)   [Eq. 2]   또는   σ_global = √(σ_total² − σ_local²)   [Eq. 3]

이며 claim 1은 "σ_total 생성 → σ_global/σ_local 중 하나를 첫 sigma로 지정 → 나머지를 σ_total에서 제거 → global corner model과 local corner model을 각각 생성"이다(원문 확인). 이 뺄셈 정의가 SSG(die-median 분포의 3σ)와 SS(all-device 분포의 3σ)의 차이를 정확히 local 항으로 만든다(추정). Intel의 정의도 같다: "die-to-die variation은 lot-to-lot, wafer-to-wafer, 그리고 within-wafer의 일부로서 die 위 모든 transistor에 균일하게 작용한다"([Bowman et al., JSSC 2002](https://www2.cs.sfu.ca/~alaa/papers/islped07_variations.pdf), 초록·검색 요약 확인). 65 nm test structure로 random 성분과 layout-dependent systematic 성분을 calibrate하는 방법은 Agarwal–Nassif가 정리했다([DAC 2007](https://dl.acm.org/doi/pdf/10.1145/1278480.1278582), 초록·검색 요약 확인). 14 nm FinFET high-sigma 연구는 Vt를 "global(chip mean) 1개 + local(symmetric, asymmetric, L_eff) 3개"로 분해한다([Giles et al., VLSI 2015](https://ieeexplore.ieee.org/document/7223657/), 초록·검색 요약 확인).

독립성은 공학적 가정이다. Sun의 physics-based MOSFET model 특허는 "local intra-die variation의 크기가 global process shift와 독립이 아닐 수 있으며 … 그런 관계가 관찰되면 model도 같은 관계를 보여야 하고 두 요인을 독립으로 다루면 안 된다"고 명시한다([US 8,271,256](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/8271256), 초록·검색 요약 확인). global vector 자체도 다차원이다: N/P global 상관이 약하고(R² ≈ 0.15), short-channel에서는 L 변동이 Vt를 지배하므로 global로 취급된다(2차 자료). die-mean Vt shift와 within-die σ_Vt의 상관을 측정한 1차 논문은 찾지 못했다(미확인).

### foundry corner menu: total corner는 통계 corner가 아니다

| corner / model | 정의 | 포함 성분 | 용도 | 검증 |
|---|---|---|---|---|
| Total corner TT/SS/FF/SF/FS | all-device 분포의 3σ (TSMC 정의) | global + local (local이 모든 device에 동일 방향으로 고정) | 전통 corner STA; "statistical corner가 아님" | 원문(US 8,275,584) + 2차 자료 |
| Global corner TTG/SSG/FFG/SFG/FSG | die-median 분포의 3σ; "total corner에서 local 영향을 뺀 것" | global만 | Local MC의 중심, AOCV/POCV/SOCV/LVF의 기초 corner | 초록·검색 요약(SemiWiki) + 2차 자료(Cadence forum 인용) |
| Global corner + Local MC | SSG/FFG 주위에 Gaussian local | global 고정 + local 확률 | "signoff golden" (2차 자료) | 2차 자료 |
| Local MC only | TT 주위 local만 | local | mismatch 평가 | 2차 자료 |
| Global MC + Local MC (Total MC) | 둘 다 확률 | global + local | 검증: global MC 3σ = global corner, total MC 3σ = total corner | 2차 자료 |
| SSGNP/FFGNP | N/P global 상관을 완전 상관에서 실측 상관으로 완화 | global (N/P decorrelated) | digital STA 표준 process corner (16 nm–2 nm급 library 이름으로 확인) | 원문(library 이름) + 2차 자료 |

SSGNP의 3σ → 약 2.5σ 조임은 상관 계수로 재현된다. N/P 균형 회로에서 delay의 global sigma는 완전 상관 대비 √((1 + ρ_NP)/2)배이고, R² = 0.15에서 ρ_NP ≈ 0.39이면 √((1 + 0.39)/2) ≈ 0.83 ≈ 2.5/3이다(유도; R²·2.5σ 수치는 [raytroop corners.md](https://raw.githubusercontent.com/raytroop/raytroop.github.io/98a66e32ed9f79ab3ac3659341045162c7823256/source/_posts/corners.md), 2차 자료). 공개 PDK가 같은 3층 구조를 코드로 보여 준다. IHP SG13G2는 `.LIB mos_tt`, `mos_tt_mismatch`, `mos_tt_stat`(global MC, "process tolerance MC에는 typical mean file만 사용"), `mos_ss`, `mos_ss_mismatch`, `mos_ff`, `mos_ff_mismatch`를 정의하고 global 1σ를 "min–max의 1/3"로 둔다(ss/ff = ±3σ global corner)([cornerMOSlv.lib](https://raw.githubusercontent.com/IHP-GmbH/IHP-Open-PDK/main/ihp-sg13g2/libs.tech/ngspice/models/cornerMOSlv.lib), 원문 확인). sky130은 tt/ss/ff/sf/fs 등 모든 global corner library가 동일한 `*__mismatch.corner.spice`를 include한다([sky130.lib.spice](https://raw.githubusercontent.com/google/skywater-pdk-libs-sky130_fd_pr/main/models/sky130.lib.spice), 원문 확인). TSMC의 SBOCV 특허 그림은 derate table을 "SSG [W/O GLOBAL VARIATION]"에서 특성화했음을 인쇄한다(원문 확인).

### Pelgrom mismatch는 parameter 수준에서 corner에 독립이고 delay 수준에서는 종속된다

Pelgrom 법칙은 σ²(ΔP) = A_P²/(W·L) + S_P²·D²이다(면적 항 + 거리 항)([Pelgrom et al., JSSC 1989](https://www.semanticscholar.org/paper/Matching-properties-of-MOS-transistors-Pelgrom-Duinmaijer/cc3979e1f2b9c1434b2e6cb34175346a1cf9fd40), 서지 확인). 물리 원인은 RDF(Mizuno 1994, Stolk 1998: σ_VT ∝ t_ox·N_A^{1/4}/√(WL), 배경 지식), LER(Asenov 2003, 초록·검색 요약 확인), HKMG의 work-function variation, FinFET/GAA의 fin/sheet 형상 변동이다. FinFET에서는 면적 대신 fin 수로 σ_multi-fin = σ_single-fin/√N_fin(초록·검색 요약 확인). N3급 TCAD DTCO는 FinFET과 nanosheet 모두에서 MGG를 지배적 local 원인으로 보고하고, n-type 구조에서 RDD ≈ 8 mV, GER ≈ 4 mV의 σ_VT를 준다(2차 자료). 이는 GAA에서 local sigma가 channel doping이나 die-mean Vt와 약하게만 결합됨을 시사한다(추정).

parameter 수준의 local sigma는 corner에 독립으로 정의된다. IHP와 sky130 PDK는 같은 mismatch file을 tt/ss/ff 아래에 그대로 include하고, 바뀌는 것은 additive nominal `vth0_corner`뿐이다(원문 확인). 그러나 delay 수준의 local sigma는 corner와 VDD에 강하게 종속된다:

    σ_D,local ≈ |∂D/∂V_t|_corner · σ_Vt,local,   (∂D/∂V_t)/D = α/(V_DD − V_t)  (alpha-power, 유도)

overdrive가 작을수록(SS corner, low VDD) 상대 sigma가 커지고, near-threshold에서는 ln D가 ΔV_t에 선형이 되어 lognormal형 right-skew가 나타난다. 근거 수치: "process variation만으로 인한 성능 변동은 nominal VDD의 약 30 %(1.3×)에서 400 mV의 150 %(2.5×)까지 약 5배 증가"([Dreslinski et al., Proc. IEEE 2010](https://semiengineering.com/near-threshold-computing-2/), 초록·검색 요약 확인); "VDD ≤ 0.5 V에서 gate delay의 표준편차가 nominal delay에 필적"([TI US 8,302,047](https://patentimages.storage.googleapis.com/pdfs/US8302047.pdf), 원문 확인); "inverter의 1σ 상대 delay variation ≈ 5 %, supply/threshold에 따라 2–3배"([Semiconductor Engineering](https://semiengineering.com/process-variation-not-a-solved-issue/), 초록·검색 요약 확인). ARM의 14 nm급 test structure 측정은 partition 자체가 전압 종속임을 보인다: "within-die variation은 spatially uncorrelated이고, die-to-die variation은 강하게 상관되지만 VDD를 낮추면 uncorrelated 쪽으로 퇴화"([Yeric, ICMTS 2014](https://ieeexplore.ieee.org/document/6841477), 초록·검색 요약 확인). σ_L/σ_G 비율이 전압에 따라 변하므로 global-local split은 전압 corner별로 검증해야 한다(추정). 실무 대응은 LVF를 PVT corner별로 특성화하는 것이며, 한 학술 flow는 0.4 V·25 °C의 worst-case sub-threshold corner에서 SiliconSmart로 LVF를 만들었다([J. Phys.: Conf. Ser. 1706 012081](https://iopscience.iop.org/article/10.1088/1742-6596/1706/1/012081/pdf), 초록·검색 요약 확인). Cadence Liberate Variety는 "global과 local variation에 대한 delay sensitivity"를 특성화 corner에서 계산하며, global parameter로 "lateral diffusion length/width, NMOS/PMOS substrate doping, oxide thickness, threshold voltage"를 흔든다([Cadence Process Variation Modeling](https://www.cadence.com/en_US/home/tools/custom-ic-analog-rf-design/library-characterization/liberate-trio-characterization-suite/process-variation-modeling.html), 초록·검색 요약 확인). D = D₀(1 + g)(1 + l)형 곱셈 model을 interaction 항과 함께 명시한 논문은 찾지 못했고, PrimeTime의 derate 합성식이 문서화된 가장 가까운 곱셈형이다(미확인/원문 확인).

### spatial correlation model은 correlated within-die 항을 region source로 바꾼다

Chang–Sapatnekar는 die를 n개 grid로 나누고 grid 간 상관이 거리에 따라 감소하는 covariance Σ를 PCA로 대각화해 Δp_intra,g = Σⱼ v_gj √λⱼ p'ⱼ의 독립 source로 만든 뒤 1차 Taylor 전개로 PERT형 단일 traversal을 수행한다([ICCAD 2003 / TCAD 2005](https://www.researchgate.net/publication/224695002_Statistical_Timing_Analysis_Considering_Spatial_Correlations), 초록·검색 요약 확인; 식은 재구성). Agarwal–Blaauw–Zolotov의 quad-tree는 level l에서 2^l × 2^l region에 독립 변수를 두고 ΔL_g = Σ_l ΔL_{l,r_l(g)}, cov = 공유 조상 node의 분산 합으로 상관을 만든다; level-0 변수가 곧 global 항이다([ICCAD 2003 / US 7,689,954](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/7689954), 초록·검색 요약 확인). Xiong–Zolotov–He는 "전체 분산을 global, spatial, random 성분으로 분해"하고 valid(PSD) 상관 함수 ρ(v)를 constrained 최적화와 alternating projection으로 측정치에 맞춘다([ISPD 2006 / TCAD 2007](https://www.researchgate.net/publication/3226060_Robust_Extraction_of_Spatial_Correlation), 초록·검색 요약 확인); ρ(v) = [σ_G² + σ_S² ρ_S(v)]/σ_total²로 쓰면 v→0의 불연속(nugget) 높이가 σ_R²/σ_total², 원거리 바닥이 σ_G²/σ_total²이다(재구성). 세 방법 모두 canonical form과 같은 대수 객체(유한 개 독립 N(0,1) source + residual)로 끝난다.

측정 추세는 spatial 항의 축소다. Berkeley test chip에서 "90 nm → 45 nm에 random WID variation은 두 배 이상 증가, systematic layout-dependent variation은 감소"했고 겉보기 상관은 poly 방향·간격에 종속이었다([Pang et al., JSSC 2009](https://ieeexplore.ieee.org/document/5173763/), 초록·검색 요약 확인). ARM 14 nm급 측정은 WID를 spatially uncorrelated로 보고하며 "layout pattern이나 circuit structure의 systematic 효과가 random-but-correlated로 오인될 수 있다"고 경고한다(Yeric 2014, 초록·검색 요약 확인). IBM은 65/45 nm대에 interconnect R/C의 거리 감쇠 상관을 측정해 linear/bilinear/Gaussian 감쇠형으로 model화했고([US 7,945,887](https://patentimages.storage.googleapis.com/pdfs/US7945887.pdf), 원문 확인), Synopsys는 "random intra-die variation의 spatial correlation이 거리에 따라 감소"하고 "systematic intra-die CD·Cu thickness variation이 lot/wafer/die 성분에 필적"한다고 썼다([US 8,000,826](https://patentimages.storage.googleapis.com/pdfs/US8000826.pdf), 원문 확인). 2022년 analog-layout review는 여전히 ΔP = g + u + s와 correlation distance(10 µm–1 mm 가정)를 쓰지만, 14 nm 사례에서 R_L = 1000 µm이면 uncorrelated 항이 지배한다([Karmokar et al., ASP-DAC 2022, 변환 텍스트](https://raw.githubusercontent.com/xiaohangguo/pdfChat/8f8cc30a1ab866ffc1a135006ae8793f5f801b23/uploads/auto/Common-Centroid_Layout_for_Active_and_Passive_Devices_A_Review_and_the_Road_Ahead.md), 2차 자료). AOCV의 distance 축이 FinFET node에서 정보를 거의 갖지 않게 되어 depth-only √N 평균의 POCV/LVF로 옮겨 간 흐름과 일치하며(추정), 잔여 within-die systematic은 LDE로 extraction에서 다룬다. 28 nm 이하에서 within-die correlation length를 측정한 논문은 찾지 못했다(미확인).

### non-Gaussian moment model은 항의 모양만 바꾸고 global/local 분리는 유지한다

delay가 source의 비선형 함수이므로 Gaussian source에서도 delay는 skew된다. quadratic canonical form D = d₀ + aᵀΔX + ΔXᵀBΔX + a_rΔR(Zhang et al., DAC 2005, 초록·검색 요약 확인; 식 재구성), IBM의 extended form(선형 Gaussian block은 해석적, 비선형/non-Gaussian block은 수치 적분·moment matching; [Chang et al., DAC 2005](https://research.ibm.com/publications/criticality-computation-in-parameterized-statistical-timing), 초록·검색 요약 확인; [US 7,293,248](https://patentimages.storage.googleapis.com/pdfs/US7293248.pdf), 원문 확인), Cheng–Xiong–He의 2차 다항 fitting과 Fourier 급수 max(초록·검색 요약 확인)가 학술 계보다. 산업 형태가 moment-based LVF다: mean shift Δμ = E[d] − d_nom, σ = √E[(d − E[d])²], skewness γ = E[(d − E[d])³]/σ³이며, corner 값은 μ ± Kσ가 아니라 3-moment 분포의 quantile로 잡는다(표준 정의). LVF는 "nominal과 세 moment(μ, σ, γ)의 네 LUT"로 분포를 표현하고([LVFGen, ISPD 2025](https://eprints.whiterose.ac.uk/id/eprint/226187/1/3698364.3705359.pdf), 초록·검색 요약 확인), 단일 Gaussian 기반이라 "분포가 non-Gaussian이면 정확도를 잃는다"는 것이 Gaussian-mixture LVF2의 동기다([LVF2, DAC 2024](https://eprints.whiterose.ac.uk/id/eprint/221555/1/3649329.3655670.pdf), 초록·검색 요약 확인). TSMC OIP에서는 "N5 low-VDD의 delay 분포가 더 skew되어 skewness moment를 추가"했다고 보고되었다([SemiWiki OIP](https://semiwiki.com/semiconductor-manufacturers/tsmc/7759-top-10-highlights-from-the-tsmc-open-innovation-platform-ecosystem-forum/), 초록·검색 요약 확인). early/late sigma로도 비대칭은 표현된다: 공개 test library의 같은 AND2 cell_rise arc에서 late sigma가 early의 1.3–1.5배다([liberty-db ocv_sigma.lib](https://github.com/zao111222333/liberty-db/blob/c1e36c1298892355843871076140fbcad4083c69/dev/tech/cases/ocv_sigma.lib), 원문 확인). 단위 주의: Liberty 문서는 skewness를 3차 중심 moment의 세제곱근(시간 단위)으로, OpenSTA는 저장값을 무차원 γ로 쓰는 것으로 읽혀 tool 간 변환 시 확인이 필요하다(원문 확인; 정규화 여부 미확인).

### 비교표 (b): global-local 관계 model

| model | 수식/구조 | global 항 | local 항 | 관계 가정 | 대표 출처 | 검증 |
|---|---|---|---|---|---|---|
| additive / nested variance | σ²_T = σ²_G + σ²_L (+ spatial); σ_local = √(σ_total² − σ_global²) | die-mean 공통 offset | 독립 random | 독립, 분산 가산 | Stine 1997; TSMC US 8,275,584; Bowman 2002 | 원문(특허)/초록 |
| spatial correlation grid + PCA | Σ_gh = σ²ρ(dist); PCA → 독립 source | 전 cell 공통 성분 | residual | 거리 감쇠 상관 | Chang–Sapatnekar 2003/2005 | 초록 |
| quad-tree | ΔL_g = Σ_l ΔL_{l,r}; level-0 = global | level-0 변수 | 최하위 level | 공유 조상 수로 상관 | Agarwal–Blaauw–Zolotov 2003 | 초록 |
| Matérn/valid ρ(v) 추출 | ρ(v) = (σ_G² + σ_S²ρ_S(v))/σ_T², nugget σ_R²/σ_T² | ρ 바닥 | nugget | PSD 제약 | Xiong–Zolotov–He 2006/2007 | 초록 |
| multiplicative / corner-dependent sigma | D ≈ D_corner(1 + Kσ_l/μ) + margin; σ_D,local = ∂D/∂Vt·σ_Vt | corner에 고정 | corner별 LVF sigma | parameter σ는 corner 독립, delay σ는 종속 | PrimeTime derate 합성; Dreslinski 2010; Yeric 2014 | 원문/초록 |
| correlation-aware global corner (SSGNP) | σ_g,delay ∝ √((1 + ρ_NP)/2) | N/P 부분 상관 | 별도 | R² ≈ 0.15 | 2차 자료 | 2차 |
| global-local 상관 허용 | local 크기 = f(global shift) | — | — | 비독립 | US 8,271,256 | 초록 |
| non-Gaussian moment / quadratic | Δμ, σ, γ; ΔXᵀBΔX | 비선형 global 가능 | 3-moment | 분리 유지, 모양만 변경 | LVF moments 2017; Zhang DAC 2005; IBM US 7,293,248 | 원문/초록 |

### 공개된 측정 수치 (node·출처)

| 항목 | 값 | node / 조건 | 출처 | 검증 |
|---|---|---|---|---|
| single-fin random σ_Vt | 19 mV NMOS / 24 mV PMOS, ±5σ까지 정규 | Intel 14 nm FinFET | Giles et al., VLSI 2015 | 초록 (1σ인지 3σ인지 요약이 상충, 원문 확인 필요) |
| research FinFET A_VT | 2.91 mV·µm (n) / 2.58 mV·µm (p) | SOI FinFET (연구용) | "FinFET Mismatch in Subthreshold Region," IEEE TED | 초록 |
| open PDK local mismatch | NMOS 3.9, PMOS 2.2 mV·µm/√(WL) (device당) | IHP SG13G2 130 nm | sg13g2_moslv_mismatch.lib | 원문 |
| open PDK local mismatch | 3.36 mV·µm/√(WL) | sky130 130 nm nfet_01v8 | tt.pm3.spice | 원문 |
| open PDK global 1σ | vfbo 0.5 %, toxo 1.33 %, muew 3.2 % 등 parameter별 | IHP SG13G2 | sg13g2_moslv_stat.lib | 원문 |
| WID random 추세 | 90 → 45 nm에서 2배 이상 증가, systematic 감소 | Berkeley test chip | Pang et al., JSSC 2009 | 초록 |
| WID 공간 상관 | spatially uncorrelated; D2D 상관은 low VDD에서 감소 | ARM 14 nm급 | Yeric, ICMTS 2014 | 초록 |
| delay variation vs VDD | ~30 % (nominal) → ~150 % (0.4 V), 약 5배 | 근-threshold | Dreslinski et al., 2010 | 초록 |
| local delay sigma | inverter 1σ ≈ 5 %; 3σ path 영향 8 %→3 % | 일반 | Semiconductor Engineering | 초록 |
| LVF σ/μ | early σ/μ 5.4 % (빠른 table 점) → 8.3 % (느린 점); late ≈ 1.3–1.5× early | 공개 test library | liberty-db ocv_sigma.lib | 원문 |
| TT→SS FMAX 이동 vs local slack σ | 1.85 GHz → 1.63 GHz (~12 %); stage별 slack σ 9–17 ps | RISC-V ASIC, LVF | arXiv 2512.13866 | 초록 |
| AOCV depth table 예 | 1.1 (depth 1) → 1.013 (depth 8) | 예시 | brabect1 gist | 원문 |
| AOCV late derate 예 | 1.091 (depth 1) … 1.030 (depth 10) | sensitivity 기반 | Freescale US 8,656,331 | 원문 |
| SBOCV table 조건 | N·σ = 5.0, OCV 5.4 %, 45LP, SSG w/o global variation | TSMC | US 8,365,115 FIG. 6a | 원문 |
| SSGNP 조임 | 3σ → ~2.5σ (N/P R² = 0.15) | digital STA | raytroop 노트 | 2차 |
| σ_global : σ_local (FinFET/GAA) | 없음 | 22–3 nm | — | 미확인 |

## EDA tool 구현 현황: local sigma는 native, global 항은 guardband로 사용자가 구성한다

### Liberty LVF는 local sigma·moment만 담고 global parameter는 legacy VA 구문에만 있다

LVF의 sigma group은 timing arc 단위 lookup table이다: `ocv_sigma_cell_rise`, `ocv_sigma_cell_fall`, `ocv_sigma_rise_transition`, `ocv_sigma_fall_transition`, `ocv_sigma_rise_constraint`, `ocv_sigma_fall_constraint`. 값은 1σ이며 "rise delay(±σ) = nominal rise delay ± ocv_sigma_cell_rise value"다. `sigma_type : early | late | early_and_late`(기본 early_and_late)로 delay(+σ) = delay + late sigma, delay(−σ) = delay − early sigma의 비대칭을 표현하고, constraint sigma group에는 `sigma_type`을 둘 수 없다(대칭 ±)([Liberty Reference Manual 2020.09 mirror](https://zao111222333.github.io/liberty-db/2020.09/reference_manual.html); [Liberty 2017.06](https://media.c3d2.de/mgoblin_media/media_entries/659/Liberty_User_Guides_and_Reference_Manual_Suite_Version_2017.06.pdf), 원문 확인). moment group은 `ocv_mean_shift_*`, `ocv_std_dev_*`, `ocv_skewness_*`로 각각 cell_rise/fall, rise/fall_transition, rise/fall_constraint, retaining_rise/fall, retain_rise/fall_slew의 10종이며 "mean = nominal + mean_shift", skewness는 mean_shift와 함께 정의해야 한다(원문 확인). Synopsys가 생성한 실제 N5급 TT 0.355 V library는 arc마다 early/late sigma table과 moment table을 **둘 다** 실어 PrimeTime(`timing_pocvm_enable_extended_moments`)과 Tempus(`delaycal_socv_lvf_mode moments|early_late`) 어느 mode로도 읽힌다([N5_TYPE1_LVL.lib](https://github.com/harryliu-intel/async-toolkit/blob/2f5e6bf3e6d12b23cbe2de55ad06ee3a1cabfdad/async-toolkit/m3utils/m3utils/liberty/src/N5_TYPE1_LVL.lib), 원문 확인). "LVF는 Liberty 규격상 항상 1σ로 모델링"([Cadence blog](https://community.cadence.com/cadence_blogs_8/b/di/posts/library-characterization-tidbits-overriding-the-one-sigma-rule-of-liberty-for-lvf-modeling), 초록·검색 요약 확인)과 "LVF data는 보통 3σ에서 측정"(PrimeLib datasheet 요약)은 table 값 1σ vs 특성화 quantile 3σ/3의 차이로 읽힌다(추정).

AOCV/distance derate는 `ocv_table_template`(variable_1/2 : path_depth | path_distance) + `ocv_derate { ocv_derate_factors { rf_type; derate_type early|late; path_type clock|data|clock_and_data; values } }`, library 속성 `default_ocv_derate_group`, `default_ocv_derate_distance_group`, cell 속성 `ocv_derate_group`, `ocv_derate_distance_group`, arc/cell/library의 `ocv_arc_depth`(우선순위 arc > cell > library)로 표현된다(원문 확인, OpenSTA reader와 일치). `ocv_derate_distance_mode`는 어디에서도 확인되지 않았다(미확인). global parameter를 명시적으로 담는 유일한 Liberty 구문은 legacy variation-aware family다: `timing_based_variation()`/`pin_based_variation()` 안의 `va_parameters`, `nominal_va_values`, `va_values`, `va_compact_ccs_rise/fall`, `va_receiver_capacitance1/2_*`, `va_rise/fall_constraint`([liberty_parse 2.6 syntax.cmos.desc](https://github.com/geochrist/dctk/blob/ebc3f0f3fa2c523b4797d87427dbd1a891fd3b8b/src-liberty_parse-2.6/desc/syntax.cmos.desc), 원문 확인). 현재 PrimeTime이 이 구문을 소비하는지는 미확인이다. 결론: 표준 LVF만으로는 "TT + global sigma"를 표현할 수 없고, VA-style sensitivity table, timer 측 global derate, 또는 별도 corner library 중 하나가 필요하다.

### PrimeTime POCV: 확인된 변수·명령과 정확한 derate 식

아래는 PrimeTime User Guide(Q-2019.12/M-2018.06), Variables and Attributes(W-2024.09-SP3), Tool Commands(U-2022.12-SP5)의 공개 mirror 텍스트와 공개 flow script에서 확인한 항목이다(원문 확인; vendor 원본 대조 권장).

- `timing_pocvm_enable_analysis`(기본 false; PrimeTime-ADV): graph-based POCV 활성화, "AOCV와 달리 PBA only mode 없음", `set_operating_conditions`를 통해 on_chip_variation mode로 자동 전환.
- `timing_pocvm_corner_sigma`(float, 기본 3.0): update_timing에서 graph corner 값을 계산하는 K sigma. `timing_pocvm_report_sigma`(기본 3.0): 보고용 sigma, corner sigma보다 작아야 하며 결과는 corner sigma 재계산 결과를 bound; 0이면 POCV 없는 slack.
- `timing_enable_slew_variation`(기본 true), `timing_enable_constraint_variation`(기본 false), `timing_use_slew_variation_in_constraint_arcs {none|setup|hold|setup_hold}`, `timing_enable_via_variation`(IVM side file: `read_ivm`, `report_ivm -summary`), `timing_pocvm_enable_extended_moments`(기본 false; ADV-PLUS; "mean_shift, std_dev, skewness … non-Gaussian"), `timing_pocvm_enable_delay_slew_correlation`, `timing_ocvm_enable_distance_analysis`(기본 true; `read_parasitics_load_locations true` 필요; distance derate는 "mean만 이동, sigma 불변"), `timing_pocvm_precedence {file|library|lib_cell_in_file}`, `timing_pocvm_max_transition_sigma`/`_clock_sigma`/`_sequential_sigma`, `timing_pocvm_enable_extrapolation_warning`, `timing_ocvm_precedence_compatibility`, `extract_model_create_variation_tables`.
- side file: `read_ocvm file.pocvm`(`ocvm_type: pocvm`, `coefficient:` = σ/nominal, `distance:`/`table:`; "depth field 미지원"); LVF는 link 시 자동 인식.
- derate: `set_timing_derate -pocvm_guardband`(mean과 sigma 모두 scale), `-pocvm_coefficient_scale_factor`(sigma만), `-pocvm_subtract_sigma_factor_from_nominal`(constraint nominal에서 LVF sigma×derate를 뺌; `-cell_check` 전용), `-increment`(mean derate; AOCV/POCV option과 병용 불가); guardband와 coefficient scale은 "직교·곱셈"으로 적용; instance에 plain `set_timing_derate`를 주면 POCV model을 override해 scalar derate가 된다. `report_timing_derate -pocvm_guardband | -pocvm_coefficient_scale_factor`, `reset_timing_derate`.
- 보고: `report_timing -variation`(Mean, Sensit 열; Incr Corner = Mean ± K·Sensit; "statistical adjustment", "statistical graph pessimism", "clock reconvergence pessimism" 항목), `report_ocvm -type pocvm [-coefficient] [-list_not_annotated]`, `report_delay_calculation -derate`, 속성 `variation_slack.mean`, `variation_slack.std_dev`, `statistical_adjustment`.
- 정확한 식(`report_delay_calculation -derate` 출력):

      Cell delay derated = "Cell delay" × ("POCVM guardband" × "POCVM distance derate" + "Incremental derate")
      Cell delay sigma   = "POCVM delay sigma" × ("POCVM guardband" × "POCVM coef scale factor")
      (side-file coefficient flow: Cell delay sigma = "Cell delay" × ("POCVM guardband" × "POCVM coefficient" × "POCVM coef scale factor"))

  예: POCVM delay sigma 0.000652/0.000500, guardband 0.98 → derated delay 0.012780/0.009804, sigma 0.000639/0.000490; coefficient 0.05, guardband 1.02 → delay 0.008886에 sigma 0.000453.
- User Guide의 derate 예: `set_timing_derate -early 0.95 -late 1.05 -pocvm_guardband`("global margin to entire distribution"), `set_timing_derate -early 1.03 -late 1.03 -pocvm_coefficient_scale_factor [get_cells {BLK1 BLK2}]`("block-specific variation margin, sigma only"). Synopsys reference methodology(ICC2-RM O-2018.06-SP2, FC-RM X-2025.06-SP2)는 `set_timing_derate -cell_delay -pocvm_guardband -early 0.97 -corner [all_corners]`를 corner별로 적용한다([FC-RM TCL_POCV_SETUP_FILE.tcl](https://github.com/velika1023-debug/FC-RM_X-2025.06-SP2/blob/main/FC-RM_X-2025.06-SP2/examples/TCL_POCV_SETUP_FILE.tcl), 원문 확인). 즉 vendor의 의도된 사용법은 corner를 유지한 채 LVF 위에 guardband를 얹는 것이다.
- moment mode에서 "corner 값은 정규분포의 K sigma 확률에 대응하는 quantile"이며, 일반 POCV model은 early/late 동작으로부터 moment model로 변환된다(원문 확인).

### Tempus/Innovus SOCV: 확인된 변수·명령

Innovus Stylus CUI(21.10–24.10)와 legacy Text Command Reference(21.10–25.10) mirror, Innovus 25.10 man page, 공개 flow template과 signoff log에서 확인했다(원문 확인).

- `timing_analysis_socv`(기본 false), legacy `setAnalysisMode -socv true`; `timing_nsigma_multiplier`(기본 3.0, "sigma multiplier in SOCV mode"); `set_socv_reporting_nsigma_multiplier [-views] {[-setup f] [-hold f]} [-transition f]`(view별·setup/hold별 n-sigma; man page 예 `-setup 2.5 -view std_max_setup`, `-hold 3.0`; template 예 `-setup 3 -hold 4.5`); `timing_set_nsigma_multiplier`는 obsolete; `timing_socv_view_based_nsigma_multiplier_mode`(기본 true).
- `timing_socv_statistical_min_max_mode {statistical | mean_and_three_sigma_bounded}`(기본 후자: worst mean을 mean으로, sigma는 worst (mean ± 3σ)를 bound하도록 계산; Innovus SOCV 최적화에 필수, Tempus 분석에 권장).
- `delaycal_socv_lvf_mode {moments | early_late}`(기본 moments), `delaycal_socv_accuracy_mode {low|medium|high|ultra}`(low: slew–delay 상관 무시(기본); high: skewness를 1 stage 국소 반영; ultra: PBA에서 다음 stage로 skewness 전파), `delaycal_socv_use_lvf_tables {all|delay|slew|constraint}`, `delaycal_socv_machine_learning_level {0|1|3}`.
- constraint sigma: `timing_library_setup_sigma_multiplier`, `timing_library_hold_sigma_multiplier`(기본 0.0), `timing_library_setup/hold_constraint_corner_sigma_multiplier`, `set_socv_constraint_config -setup_folding -hold_folding -libs`("folding factor는 특성화 시 nominal setup/hold table에 더해진 OCV pessimism 양을 기록").
- interconnect: `timing_socv_rc_variation_mode`(기본 false), `set_socv_rc_variation_factor <f> [-early] [-late] [-views]`("global variation을 nominal delay의 percentage로 적용"; template 예 0.1), `report_socv_interconnect_variation`, `setDelayCalMode -wire_variation_correlation_mode {statistical|binomial} -wire_variation_rc_correlation <v> -enable_corner_based_beol`; 이름만 확인: `delaycal_wire_corner_sigma_multiplier`, `delaycal_via_corner_sigma_multiplier`, `delaycal_wire_var_reporting_sigma_multiplier`.
- AOCV→SOCV: `timing_library_infer_socv_from_aocv`(기본 false), `timing_library_scale_aocv_to_socv_to_n_sigma`(기본 3; "AOCV derate는 3σ variation 기준으로 도출된 것으로 가정").
- 잔여 global 항: `timing_enable_vtskew_derate_mode`, `set_vt_skew_derate -threshold_voltage_group <g> -fast <f> -slow <f> [-mean|-sigma] [-setup|-hold]`, `set_advanced_variation_mode -scope {vtskew | aging | wire_variation | beol | lle | layout_effect | lde}`, `timing_derate_voltage_scaling_mode {first_library|snap_to_nearest|interpolate}`.
- 보고: `timing_report_enable_verbose_ssta_mode`, `timing_report_socv_summary_mean_sigma`, `timing_report_fields`의 `delay_mean delay_sigma arrival_mean arrival_sigma transition_mean transition_sigma socv_derate vt_skew_derate`; `timing_extract_model_write_lvf`; incremental sigma derate 산술 "1 + 0.9 = 1.9, additive mode에서는 1 + 0.8 + 0.9 = 2.7".
- template에만 보이고 문서에서 확인되지 않은 이름: `set_limited_access_feature socv 1`, `timing_library_update_libset_ssocv`, `timing_ssta_enable_nsigma_enumeration`, `timing_ssta_generate_sta_timing_report_format`(script 확인, 의미 미확인). `timing_socv_sigma_spatial_multiplier`는 문서가 자기모순(bool로 표기, 설명은 fractional multiplier; log 값 1.0).

OpenSTA는 `sta_pocv_mode scalar|normal|skew_normal`과 `sta_pocv_quantile`(기본 3σ)로 같은 계열을 구현하고 Liberty reader가 `ocv_sigma_*`, `ocv_std_dev_*`, `ocv_mean_shift_*`, `ocv_skewness_*`, `sigma_type`, `ocv_derate_factors`, `ocv_table_template`를 읽는다([OpenSTA doc/Examples.md](https://github.com/The-OpenROAD-Project/OpenSTA/blob/d1e43c6f9f4e66cb59c3d7958a4aa7d1626b4614/doc/Examples.md), 원문 확인).

### 문서·script에서 확인되지 않은 변수명

다음 이름은 PrimeTime 세 reference, Innovus/Tempus reference, 공개 script 어디에서도 0건이다. 존재한다고 가정하지 말 것.

| 이름 | 상태 |
|---|---|
| `timing_pocvm_enable_global_variation` (PrimeTime) | 문서·script에서 확인되지 않음 |
| `timing_enable_socv_global_variation` (Tempus) | 문서·script에서 확인되지 않음 (유사 문자열은 오류 메시지 예 `timing_enable_socv_analysis`뿐) |
| "Global Variation (GV) in PrimeTime", "LVF with global sigma" | 문서에 "global variation", "global_sigma" 문자열 없음 |
| `timing_pocvm_precision_mode`, `timing_ocvm_precision_mode_value`, `timing_pocvm_enable_distribution_report` | 문서·script에서 확인되지 않음 |
| `ocv_derate_distance_mode` (Liberty) | 확인되지 않음 |
| PrimeShield의 global variation 분석 | 문서 미입수, 미확인 |

vendor 문서에서 "global"이 붙은 항목은 Tempus `set_socv_rc_variation_factor`("global variation as percentage of nominal delay", interconnect 전용)와 PrimeTime `-pocvm_guardband` 예의 "global margin that scales all distributions"뿐이다. 두 timer 모두 cell을 독립 random variable로 취급하며(PrimeTime: "각 cell instance는 통계적으로 독립"), IBM canonical form 같은 global parameter mode는 문서화되어 있지 않다(원문 확인). 따라서 TT + global margin flow는 (a) library corner 선택(TTG vs SSG), (b) mean/sigma guardband, (c) global spread를 포함한 total-sigma 특성화 중 하나로 사용자가 구성해야 한다.

### 특성화 도구

Cadence Liberate Variety는 "random·systematic process variation을 모델링하고 AOCV/SOCV table을 생성하며 global과 local variation에 대한 delay sensitivity를 계산"하고, Liberate Trio는 AOCV/SOCV/LVF를 생성한다(초록·검색 요약 확인). Synopsys SiliconSmart는 LVF sigma 또는 POCV side-file coefficient를 생성하며 "distance derate는 도구가 아니라 silicon 측정으로 만든다"([chipgun](https://github.com/chipgun/nibaix.github.io/blob/master/2022/05/07/PrimeTime-and-OCV/index.html), 원문 확인). Samsung Foundry는 PrimeLib를 5/4/3 nm에서 인증했고(PRNewswire 2021, 초록·검색 요약 확인), 10LPP reference flow는 SOCV/LVF 기반 timing closure로 검증되었다([Semiconductor Digest 2016](https://sst.semiconductor-digest.com/2016/10/cadence-reference-flow-with-digital-and-signoff-tools-certified-on-samsungs-10nm-process-technology/), 초록·검색 요약 확인). 특성화 비용은 "cell, Vt, drive strength, PVT corner마다 광범위한 특성화"이며 LVFGen은 MC 대비 2.27×(5k-sample 정확도)/4.06×(100k-sample 정확도) 가속을 보고한다(초록·검색 요약 확인). 공개 전처리기는 (slew, load)별 MC moment CSV에서 mean_shift = delay_mean − nominal, std_dev, skewness를 table로 만든다([char22nm-preprocess](https://github.com/StochasticCells/char22nm-preprocess/blob/50d98d06c49c82c5525378a6d82bb8dec6c039aa/src/arcs.rs), 원문 확인). Cadence US 10,789,406은 RSS 특성화가 "low voltage·high-Vt cell의 비선형 효과를 정확히 담지 못한다"고 지적하고 adaptive response surface로 sigma와 moment를 추출한다(초록·검색 요약 확인).

### PrimeTime Tcl 예제 (TT library + LVF/POCV, corner sigma와 guardband)

아래 값은 모두 placeholder다. guardband와 sigma는 project의 variation data(global sigma 추정치, LVF 검증 결과)로 정해야 한다. 사용한 변수·명령은 위에서 확인된 것으로 제한했다.

```tcl
# Author : yoobeom.kim@samsung.com
# Purpose: TT-corner LVF/POCV signoff setup with K-sigma corner and global guardband (placeholder values)

# ---- flow 기본 설정 (project flow에 맞게 교체) ----
set link_path        "* tt_0p80v_25c_lvf.db"      ;# TT corner LVF library (placeholder)
read_verilog         top.v
link_design          top
set_app_var read_parasitics_load_locations true     ;# distance derate용 위치 정보
read_parasitics      top.spef
read_sdc             top.sdc

# ---- POCV/LVF 활성화 (LVF table은 link 시 자동 인식) ----
set_app_var timing_pocvm_enable_analysis        true   ;# on_chip_variation mode로 자동 전환
set_app_var timing_pocvm_corner_sigma           3.0    ;# PLACEHOLDER: K-sigma corner (default 3)
set_app_var timing_pocvm_report_sigma           3.0    ;# report sigma (corner sigma 이하)
set_app_var timing_enable_slew_variation        true
set_app_var timing_enable_constraint_variation  true
set_app_var timing_pocvm_enable_extended_moments false ;# moment LVF 사용 시 true (ADV-PLUS)
set_app_var timing_ocvm_enable_distance_analysis true

# ---- side file (LVF 없는 IP cell의 coefficient; 필요 시) ----
# read_ocvm ip_cells.pocvm
# set_app_var timing_pocvm_precedence file

# ---- global margin: mean과 sigma를 함께 scale (PLACEHOLDER 값) ----
# 값은 project의 sigma_global 추정치(예: SSG/TTG 차이의 1/3)와 K로부터 정한다.
set_timing_derate -early 0.95 -late 1.05 -pocvm_guardband

# ---- block별 sigma-only margin (PLACEHOLDER 값) ----
set_timing_derate -early 1.03 -late 1.03 -pocvm_coefficient_scale_factor [get_cells {BLK1 BLK2}]

update_timing

report_timing_derate -pocvm_guardband
report_timing_derate -pocvm_coefficient_scale_factor
report_ocvm -type pocvm -coefficient -list_not_annotated
report_timing -variation -derate
```

주의: guardband는 corner별로 다르게 둘 수 있고(Synopsys RM은 `-corner`로 구분), `-pocvm_guardband`는 `-dynamic`과 함께 쓸 수 없으며, instance에 plain `set_timing_derate`를 주면 그 arc의 POCV model이 무효화된다(원문 확인).

## 논문 분석: 근거의 조각은 모두 공개되어 있으나 TT signoff를 한 편으로 정리한 논문은 없다

### 핵심 논문 14편

**Visweswariah, Ravindran, Kalafala, Walker, Narayan, "First-Order Incremental Block-Based Statistical Timing Analysis," DAC 2004 / IEEE TCAD 2006.** 상관(global) source와 독립 random 항을 함께 갖는 canonical first-order delay model을 제안하고, 선형 시간 block-based 전파와 tightness probability 기반 max 재표현, local/global criticality를 제공한다. 결과가 canonical form이므로 각 source에 대한 1차 sensitivity가 바로 나오고 임의 corner projection이 가능하다. TT signoff의 형식적 기초이며 IBM EinsStat의 엔진이다. 초록·검색 요약 확인(PDF 미입수; max 재표현 식의 정확한 표기 미확인).

**Bowman, Duvall, Meindl, "Impact of die-to-die and within-die parameter fluctuations on the maximum clock frequency distribution for gigascale integration," IEEE JSSC 37(2), 2002.** D2D 성분은 정규분포, WID 성분은 path별 독립 항으로 두고 N_cp개 critical path의 max로 FMAX 분포를 유도한다. "WID는 FMAX mean, D2D는 FMAX variance"라는 결론이 corner(global)/statistics(local) 분업의 통계적 근거다. TT 기준 signoff는 WID로 인한 mean shift를 K-sigma local margin으로, D2D를 global margin으로 각각 예산해야 함을 뜻한다. 초록·검색 요약 확인(식은 재구성). TVLSI 2009 multi-core 확장의 저자 표기가 기록 간에 다르다(Bowman et al. vs Herbert & Marculescu; 미확인).

**Chang, Sapatnekar, "Statistical timing analysis considering spatial correlations using a single PERT-like traversal," ICCAD 2003 / TCAD 2005.** grid model + PCA로 correlated intra-die parameter를 독립 source로 바꾸고 1차 Taylor 전개 delay를 PERT형으로 전파한다. inter-die 항은 모든 cell에 공통인 성분으로 자연스럽게 canonical form에 들어간다. spatial 항이 FinFET에서 축소되었더라도 region source 개념은 global-local 관계 model의 원형이다. 초록·검색 요약 확인(수치 결과 미확인).

**Agarwal, Blaauw, Zolotov, "Statistical timing analysis for intra-die process variations with spatial correlations," ICCAD 2003 (특허 US 7,689,954).** multi-level quad-tree로 die를 분할하고 level별 독립 변수의 합으로 device length 변동을 표현한다. level 간 분산 배분이 상관 감쇠 속도를 결정하고, level-0 변수가 global 항 역할을 한다. global/spatial/random을 하나의 계층 변수로 통합한 가장 직관적 model이다. 초록·검색 요약 확인.

**Xiong, Zolotov, He, "Robust extraction of spatial correlation," ISPD 2006 / TCAD 26(4), 2007.** 전체 분산을 global·spatial·random으로 분해하고 측정 잡음 아래에서도 valid(PSD) 상관 함수·행렬을 constrained 최적화와 alternating projection으로 추출한다. σ_G/σ_S/σ_R 분할이 model 공리가 아니라 측정으로 정해지는 양임을 보이는 논문이다. 초록·검색 요약 확인(수치·함수형 미확인).

**Onaissi, Najm, "A Linear-Time Approach for Static Timing Analysis Covering All Process Corners," ICCAD 2006 / TCAD 27(7), 2008.** parameter box 위에서 affine hyperplane을 전파해 2ⁿ corner를 한 번에 bound한다. random 항이 없는 global-only model로, corner 열거를 대체하는 "parameterized STA"의 대표다. TT signoff 관점에서는 global 항을 symbolic하게 유지하는 방법 중 하나다. 초록·검색 요약 확인(정확도·runtime 미확인).

**Kahng, "New Game, New Goal Posts: A Recent History of Timing Closure," DAC 2015.** 공정·모델 표준·EDA·signoff 기준의 변화를 개괄하며 "variation modeling and signoff corner definition, including variation-aware path-based STA"를 중심 주제로 다룬다. 검색 요약에 "SSG global corner는 global variation만 포함", "global corner가 AOCV/POCV/SOCV/LVF의 기초", "tightened corners and signoff at typical"이 등장한다. 본문 수치와 corner 수는 확인하지 못했다. 초록·검색 요약 확인.

**Tetelbaum, "Corner-based Timing Signoff and What Is Next," AnySilicon 백서, 2014년 1월.** corner 수가 2013년 12–126개이고 2020년 16–248개로 예측되며(5 process × 2 T × 4 metal × 4 V = 160 corner 산술), corner 기반 signoff가 global 3σ 고정 + local early/late split이라는 구조를 명시하고 "timing deadlock"과 statistical signoff의 필요를 논한다. 후속 LinkedIn 글은 "16개 corner면 충분"으로 정리한다. TT signoff 논의의 실무 배경이다. 초록·검색 요약 확인.

**Mahajan Rita, Sharma Aru, Bansal Manish, "Timing analysis journey from OCV to LVF," J. Phys.: Conf. Ser. 1706 (2020) 012081.** OCV→AOCV→POCV→LVF의 진화를 한 design의 PrimeTime report로 비교한다. "OCV는 긴 path에 pessimistic, 짧은 path에 optimistic", "LVF는 slack을 개선하며 OCV 대비 pessimism이 매우 작다"고 쓰고, LVF는 0.4 V·25 °C worst-case sub-threshold corner에서 특성화했다. slack 수치는 확인하지 못했다(article number는 012081; 012095는 오기). 초록·검색 요약 확인.

**"A parametric approach for handling local variation effects in timing analysis," DAC 2009 (POCV 원논문).** SSTA에서 파생된 local variation model을 "통계 library 특성화와 통계 RC 추출 없이" 제공하며 65/45 nm의 multi-million instance production design에서 "setup의 비현실적 pessimism 제거, hold의 risk 포착"을 보고한다. corner + local-sigma hybrid의 출발점이다. 초록·검색 요약 확인(저자 미확인).

**Pelgrom, Duinmaijer, Welbers, "Matching properties of MOS transistors," IEEE JSSC 24(5), 1989.** σ²(ΔP) = A_P²/(WL) + S_P²D²의 면적·거리 law. random 항의 1/√area와 systematic 거리 항이 local variation model의 출발점이며, foundry mismatch model card(open PDK의 `delvto_mm/√(WL)`)가 그대로 따른다. 서지 확인, 내용은 배경 지식.

**Dreslinski, Wieckowski, Blaauw, Sylvester, Mudge, "Near-Threshold Computing," Proc. IEEE 98(2), 2010.** process variation만으로 인한 성능 변동이 nominal VDD의 ~30 %에서 400 mV의 ~150 %로 약 5배 증가한다고 보고한다. 같은 parameter-level local sigma가 operating point에 따라 delay sigma를 크게 바꾼다는 가장 많이 인용되는 근거이며, LVF를 corner별로 특성화해야 하는 이유다. 초록·검색 요약 확인.

**Yeric, "Processor yield at 14nm and beyond," ICMTS 2014.** 64-bit Kogge-Stone adder, ring oscillator, sub-ps delay 측정 회로로 얻은 data에서 within-die variation은 spatially uncorrelated, die-to-die variation은 강하게 상관되지만 VDD를 낮추면 uncorrelated 쪽으로 퇴화한다고 보고한다. global/local partition 자체가 전압 종속임을 보인 유일한 측정 자료다. 초록·검색 요약 확인(그림·수치 미확인).

**Giles et al., "High sigma measurement of random threshold voltage variation in 14nm Logic FinFET technology," VLSI 2015.** 단일 fin NMOS/PMOS의 random Vt 변동 19 mV/24 mV, ±5σ까지 정규분포. production FinFET의 유일한 공개 local 수치이며 LVF/POCV의 Gaussian 가정을 ±5σ까지 뒷받침한다. die-to-die 수치는 없고, 19–24 mV가 1σ인지 3σ인지 검색 요약이 상충한다. 초록·검색 요약 확인.

**Lin, Hsiao, Tseng, Jeng (TSMC), "Id1 = Id0 + G + L1, Id2 = Id0 + G + L2: A Comprehensive Solution for Process Variation Characterization and Modeling," SISPAD 2012.** global, local, correlation, corner effect, distance effect, spatial effect를 compact model에 통합한 foundry 논문. 제목의 식이 곧 shared global offset + independent local offset model이다. US 8,275,584의 논문판으로 읽힌다. 초록·검색 요약 확인.

**Pipeline-Stage-Resolved Timing Characterization of a RISC-V Processor (arXiv 2512.13866 / Eng. Res. Express, 2025).** TT/FF/SS MMMC STA에 AOCV와 LVF를 더해 signoff Fmax 1.85 GHz(TT)→1.63 GHz(SS)를 보고하고, LVF를 써도 stage별 slack σ는 9–17 ps로 좁으며 "variation은 주로 PVT corner 간 예측 가능한 mean shift로 나타난다"고 쓴다. 공개 자료 중 유일한 design 단위의 global(mean shift) vs local(slack σ) 분해 수치다. 초록·검색 요약 확인.

### 논문 재고표 (d)

검증 수준: 원문 = 원문 확인, 초록 = 초록·검색 요약 확인, 서지 = 제목/서지만 확인, 배경 = 배경 지식(미확인).

| 연도 | 저자 | venue | 기여 | TT signoff 관련성 | 검증 |
|---|---|---|---|---|---|
| 1961 | Clark | Operations Research 9(2) | Gaussian max의 mean/variance/covariance 식 | SSTA max 연산의 기초 | 초록 |
| 1989 | Pelgrom, Duinmaijer, Welbers | JSSC 24(5) | mismatch 면적·거리 law | local model 기초 | 서지/배경 |
| 1992 | Michael, Ismail | JSSC 27(2) | mismatch 통계 model | local | 서지 |
| 1994 | Mizuno, Okumura, Toriumi | TED 41(11) | RDF 실험 | local 물리 | 배경 |
| 1997 | Stine, Boning, Chung | IEEE TSM 10(1) | spatial variation 분해 | additive model 출처 | 서지 |
| 1997 | Boning, Chung | ECS | f_RAW = f_WLV + f_DLV + f_INT + ε | additive model | 초록 |
| 1998 | Stolk, Widdershoven, Klaassen | TED 45(9) | dopant fluctuation model | local 물리 | 서지 |
| 1998 | Asenov | TED 45(12) | RDF 3-D atomistic | local 물리 | 배경 |
| 2000 | Boning, Nassif | IEEE Press chapter | inter/intra-die, systematic/random 분류 | 용어 | 서지 |
| 2001 | Nassif | CICC | 제조 variation 분석 | intra-die 증가 논지 | 서지 |
| 2002 | Bowman, Duvall, Meindl | JSSC 37(2) | D2D vs WID FMAX 모델 | corner/statistics 분업 근거 | 초록 |
| 2002 | Orshansky et al. | TCAD 21(5) | intrachip gate length 변동 영향 | spatial | 서지 |
| 2003 | Jess, Kalafala, Naidu, Otten, Visweswariah | DAC | path-based SSTA, parametric yield | yield 정의 | 초록 |
| 2003 | Visweswariah | DAC (invited) | "Death, taxes and failing chips" | corner 방법론 비판 | 초록 |
| 2003 | Chang, Sapatnekar | ICCAD (TCAD 2005) | grid + PCA SSTA | spatial model | 초록 |
| 2003 | Agarwal, Blaauw, Zolotov | ICCAD | quad-tree SSTA | spatial model | 초록 |
| 2003 | Asenov, Kaya, Brown | TED 50(5) | LER 변동 | local 물리 | 초록 |
| 2003 | Drennan, McAndrew | JSSC 38(3) | 물리 기반 mismatch model | local (1/√area 한계) | 초록 |
| 2004 | Visweswariah et al. | DAC (TCAD 2006) | canonical form SSTA | 형식적 기초 | 초록 |
| 2004 | Le, Li, Pileggi | DAC (STAC) | PCA 기반 correlated SSTA | spatial/reconvergence | 초록 |
| 2004 | Sapatnekar | 책 *Timing* | SSTA 교과서 | 배경 | 서지 |
| 2005 | Chang, Zolotov, Narayan, Visweswariah | DAC | non-Gaussian/nonlinear SSTA | moment model | 초록 |
| 2005 | Zhang, Chen, Hu, Gubner, Chen | DAC | quadratic timing model | non-Gaussian | 초록 |
| 2005 | Zhan, Strojwas, Li, Pileggi et al. | DAC | non-Gaussian delay 상관 SSTA | non-Gaussian | 서지 |
| 2005 | Friedberg et al. | ISQED | within-die spatial correlation | spatial | 서지 |
| 2005 | Kinget | JSSC 40(6) | mismatch trade-off | local | 서지 |
| 2005 | Srivastava, Sylvester, Blaauw | 책 | 통계 분석·최적화 | 배경 | 서지 |
| 2006 | Onaissi, Najm | ICCAD (TCAD 2008) | all-corner hyperplane STA | global symbolic | 초록 |
| 2006 | Xiong, Zolotov, He | ISPD (TCAD 2007) | spatial correlation 추출 | σ_G/σ_S/σ_R 측정 | 초록 |
| 2006 | Cline, Chopra, Blaauw, Cao | ICCAD | CD variation model | systematic vs random | 서지 |
| 2006 | Xiong et al. | DAC | criticality 계산 | SSTA 진단 | 초록 |
| 2006 | (DAC) | DAC | ICA로 non-Gaussian 상관 처리 | non-Gaussian | 서지 |
| 2007 | Cheng, Xiong, He | DAC (TCAD 2009, TVLSI) | 2차 다항/Fourier max | non-Gaussian | 초록 |
| 2007 | Sinha, Zhou, Shenoy | TCAD 26(8) | Clark max 오차·순서 | max 정확도 | 초록 |
| 2007 | Agarwal, Nassif | DAC | 65 nm test structure | 분해 측정법 | 초록 |
| 2007 | Takeuchi et al. | IEDM | 다중 fab σ_Vt 정규화 | RDF 지배 여부 | 초록 |
| 2007 | Kuhn | IEDM | variation 저감 | 배경 | 초록 |
| 2007 | Wang, Bastani, Abadir | DAC | design–silicon timing 상관 | silicon 상관 방법 | 초록 |
| 2007 | Klass | Stanford EE380 강의 | ±3σ 창과 yield | 배경 | 초록 |
| 2008 | Blaauw, Chopra, Srivastava, Scheffer | TCAD 27(4) | SSTA survey | 배경 | 초록 |
| 2008 | Chen, Zhang, Zolotov, Visweswariah, Xiong | ASP-DAC | "Static timing: Back to our roots" | corner+OCV+CPPR 대체 | 초록 |
| 2008 | Hargreaves, Hult, Reda | ASP-DAC | 90 nm WID 통계 모델링 | spatial 측정 | 초록 |
| 2008 | Orshansky, Nassif, Boning | 책 (Springer) | inter/intra-deterministic/intra-statistical 분류 | 용어 | 초록 |
| 2008 | Kuhn et al. | Intel Technology Journal 12(2) | 45 nm variation 관리 | 배경 | 서지 |
| 2008 | (ISPD tutorial) | ISPD | "Variations, Margins, & Statistics" | 배경 | 서지 |
| 2009 | Forzan, Pandini | Integration 42(3) | SSTA survey | 배경 | 초록 |
| 2009 | Pang, Nikolić | JSSC 44(5) | 90 nm variability 측정 | WID 상관 | 초록 |
| 2009 | Pang, Qian, Spanos, Nikolić | JSSC 44(8) | 45 nm variability 측정 | random↑ systematic↓ | 초록 |
| 2009 | (DAC, POCV) | DAC | parametric OCV | hybrid 출발점 | 초록 |
| 2009 | Bowman et al. (또는 Herbert, Marculescu) | TVLSI 17(12) | multi-core FMAX 확장 | D2D/WID | 초록 (저자 불일치) |
| 2010 | Dreslinski et al. | Proc. IEEE 98(2) | near-threshold 변동 5배 | corner 종속 sigma | 초록 |
| 2010 | Silva, Phillips, Silveira | TCAD | corner 기반 variation-aware 검증 | global | 서지 |
| 2010 | (IBM) | academia.edu 사본 | 45 nm ASIC SSTA signoff | IBM 실적 | 초록 (저자·venue 미확인) |
| 2011 | Kuhn et al. | TED 58(8) | Intel variation review | 배경 | 초록 |
| 2011 | Nikolić et al. | TCAS-I 58(9) | 45 nm design 관점 | 분해 | 초록 |
| 2011 | Onaissi, Taraporevala, Liu, Najm | DAC | all-PVT-corner STA | global | 초록 (저자 미확인) |
| 2011 | Mishra, Mittal | Embedded.com | 40 nm corner 축소 | corner 수 | 초록 |
| 2011 | Kahng | TAU keynote | "The Future of Signoff" | random vs systematic | 초록 |
| 2011 | (ACM) | — | FMAX/ISB 추정 | silicon 상관 | 초록 |
| 2012 | Lin, Hsiao, Tseng, Jeng (TSMC) | SISPAD | Id = Id0 + G + L | foundry 분해 | 초록 |
| 2012 | Auth et al. (Intel) | VLSI | 22 nm tri-gate | variability 감소 | 초록 |
| 2013 | (HiSIM group) | IEEE | D2D/WID 추출 | 분해 | 초록 |
| 2014 | Yeric (ARM) | ICMTS | 14 nm test structure | WID uncorrelated | 초록 |
| 2014 | Kahng, Dobre, Chan | ICCD | tightened BEOL corner | RC corner | 서지 |
| 2014 | Tetelbaum | AnySilicon (2편) | corner 폭증, statistical signoff | 배경 | 초록 |
| 2014 | Natarajan et al. (Intel) | IEDM | 14 nm | sub-fin doping | 초록 |
| 2014 | Saha | IEEE Access 2 | 통계 compact model | 특성화 | 초록 |
| 2015 | Kahng | DAC | timing closure 역사 | signoff at typical | 초록 |
| 2015 | Giles et al. (Intel) | VLSI | 14 nm σ_Vt | local 수치 | 초록 |
| 2015 | Damrongplasit | UC Berkeley TR | variability 정의 | 용어 | 초록 |
| 2016 | Ghanta (Synopsys) | TAU | non-Gaussian POCV | moment | 서지 |
| 2018 | Samsung | VLSI | 7 nm EUV | variability | 초록 |
| 2019 | Kahng, Mallappa, Saul, Tong | DATE | unobserved corner 예측 (10→48 corner, 16 nm) | corner 축소 | 초록 |
| 2019 | Yeap et al. (TSMC) | IEDM | N5 EUV | Vt variation | 초록 |
| 2019 | (TU Delft) | thesis | sub-20 nm delay model | VDD 종속 | 초록 |
| 2019 | (Electronics 8(5) 501) | MDPI | log-skew-normal delay | non-Gaussian | 서지 |
| 2020 | Rita, Aru, Manish | J. Phys.: Conf. Ser. 1706 | OCV→LVF 비교 | hybrid | 초록 |
| 2020 | Nguyen et al. | ACOMP | AOCV | 배경 | 초록 |
| 2020 | Jha et al. | JEDS | NW vs NS LER mismatch | GAA local | 초록 |
| 2020 | Nagy et al. (CiTIUS) | EDL | FinFET/NW/NS variability | GAA local | 2차 |
| 2020 | Shah, Nayyar, Sinha | IEEE D&T 37(4) | silicon-proven signoff, ±5 % | silicon 상관 | 초록 |
| 2021 | (TRETS) | ACM TRETS | 16 nm FinFET FPGA variability | 측정 | 서지 |
| 2021 | Lütkemeyer | TAU | signoff 방법론 비판 | 배경 | 서지 |
| 2022 | Karmokar et al. | ASP-DAC | common-centroid review | ΔP = g + u + s | 2차 |
| 2022 | (MDPI Electronics 11) | — | ML multi-corner | corner 축소 | 서지 |
| 2022 | Fang | ISSCC tutorial | process monitor | 배경 | 서지 |
| 2024 | Mishagli, Koskin, Blokhina | arXiv | correlated extremes SSTA | 이론 | 서지 |
| 2024 | (LVF2) | DAC | Gaussian-mixture LVF | non-Gaussian | 초록 |
| 2024 | Zhu, Guo, Cai | ICCAD | One-for-All cross-corner | corner 축소 | 초록 |
| 2024 | (IEEE) | — | ULV moment LVF | moment | 서지 |
| 2024 | (DATE) | DATE | DL statistical timing | 배경 | 서지 |
| 2025 | Zhou et al. | ISPD | LVFGen | 특성화 가속 | 초록 |
| 2025 | Xu et al. | TODAES 31(4) | FACT multi-corner | corner 축소 | 초록 |
| 2025 | (arXiv 2512.13866) | Eng. Res. Express | RISC-V TT/SS + LVF | global vs local 수치 | 초록 |
| 2025 | (arXiv 2509.14551, 2510.26985) | arXiv | shift-left survey; 실용 timing closure | 배경 | 초록 |
| 2013 | (KISTI TRKO201300034125) | 국가 R&D 보고서 | OCV 모델링 (사다리꼴 기법) | 국내 유일 연구 자료 | 초록 |

핵심 공백: SS+OCV, SS+POCV/LVF, TT+statistical margin을 같은 design에서 frequency/area/power로 비교한 peer-reviewed 논문, LVF/POCV 예측과 silicon Fmax·hold fail의 상관 연구, FinFET/GAA node의 σ_global : σ_local 수치는 어느 것도 찾지 못했다(미확인). 국내 학술지·학위논문에서 "TT corner signoff", "통계적 타이밍 signoff"를 다룬 문헌도 없었다.

## 특허 분석: global/local 분해는 foundry·IDM이, sigma→corner 변환은 EDA가 claim했다

### 핵심 특허 20건

**TSMC US 8,275,584 (우선권 2006-12-12, 등록 2012-09-25), "Unified model for process variations in integrated circuits."** claim 1: test pattern에서 intra-die/inter-die data 수집 → σ_total 생성 → σ_global/σ_local 중 하나를 첫 sigma로 지정 → 나머지를 σ_total에서 제거 → global corner model과 local corner model을 각각 생성. claim 14/21은 die median → σ_global, intra-die σ 평균 → σ_local의 두 경로를 정한다. 배경은 "total corner에 local을 다시 적용하면 local 이중 계상"과 "1/√(WL) mismatch가 σ_total보다 큰 σ_local을 줄 수 있음"을 명시한다. 본 리뷰의 근거 사슬에서 가장 중요한 1차 자료다. 원문 확인.

**Samsung Electronics US 9,977,845 (KR 10-2015-0010681, 2015-01-22), "Method of performing static timing analysis for an integrated circuit."** 독립 claim은 local random variation 정보 + global variation parameter 집합에서 얻은 global variation 정보를 담은 library를 load하고, slack을 delay와 "local random 값과 global 값의 statistical sum"으로 계산한다. 설명부: global 값은 SS/FF에서 특성화, 3σ corner면 3으로 나눠 1σ 저장, total = RSS(local, global), library에 없는 corner의 global 값 계산, 3σ speed 분포, 제조 방법 claim 포함. "nominal + combined global/local statistical margin" signoff에 가장 가까운 claim이다. 초록·검색 요약 확인(발명자·등록일·KR 공개번호·전체 claim 미확인).

**IBM US 7,428,716 (2003-09-19) 및 US 8,010,921, US 7,111,260/7,512,919, US 7,086,023.** canonical form 엔진 특허. 설명부는 delay = a₀ + Σaᵢ·Δxᵢ + a_{n+1}·ΔR을 "deterministic portion, correlated (or global) portion, independent (or local) portion"으로 정의하고, claim은 "sources of variation의 확률분포의 weighted sum" 형태의 statistical arrival time을 recite한다. 원문 확인.

**IBM US 7,555,740 (2007-02-27), "…statistical sensitivity credit in path-based hybrid multi-corner STA."** global(statistically dependent) parameter는 worst corner에 두고, independent parameter의 sensitivity를 best/worst corner slack 차이 S = (P_b − P_w)/(σ_b ± σ_w)로 구해 RSS credit(n·√Σ(S_xσ_x)², n < 6)을 준다. 설명부가 "모든 global variation을 3σ 극단 corner에 고정"하는 관행을 명문화한다. 동시 출원 US 2008/0209372(non-common path delay + RSS credit으로 multi-corner 생략 판단), 2008/0209374, 2008/0209375. 원문 확인(분모 부호는 기록 불일치).

**IBM US 8,141,012 (2009-08-27), "Timing closure on multiple selective corners in a single statistical timing run."** 전체 parameter 공간(각 −3σ~+3σ)에서 SSTA 한 번 → path별 k개 corner 선택 → 나머지 sub-space를 포함한 "mixed mode projection"으로 deterministic 값 → worst slack corner에서 closure. corner projection을 가장 직접 claim한다. 원문 확인.

**IBM US 2012/0117527 A1 (2010-11-10), "…non-separable statistical and deterministic variations."** deterministic·corner-based 첫 parameter와 non-separable 통계 parameter를 단일 run으로 처리하고, extended canonical form에 corner 값을 대입해 projection(최저·최고 corner 사이 선형 보간, 2차 상호작용 항). IBM의 명시적 global-corner/local-statistical hybrid 정식화다. 원문 확인(등록번호 미확인).

**IBM US 8,413,095 (2012-02-21), "Statistical single library including on chip variation…"** chip mean과 OCV process, aging, N/P mistrack parameter 범위에 statistical model과 statistical timing tool을 적용해 delay/power의 WC statistical corner를 구하고 단일 WC Liberty library에 기록. Monte Carlo 3σ; "같은 statistical corner 정의와 global parameter를 scale한 test macro의 chip sign-off statistical delay requirement"와 비교. total/statistical corner library의 claim-level 원형. 원문 확인.

**IBM US 8,806,402 / 8,949,765 (2012-10-31), "Modeling multi-patterning variability with statistical timing."** claim 5가 각 variation source를 "mean 분포, global 분포 sensitivity, spatial 분포 sensitivity, random 분포 sensitivity"로 명시(W = W₀ + ΔW_glob + ΔW_spatial + ΔW_rand). 원문 확인.

**IBM US 9,501,609 / 10,013,516 / 10,606,970 (2015-12-02~), "Selection of corners and/or margins using SSTA."** SSTA로 path별 parameterized model을 만들고 corner 간 slack 차이를 분석해 "주어진 margin으로 원하는 coverage를 만족하는 corner 집합"을 고른다. statistical corner selection의 post-2015 대표. 초록·검색 요약 확인.

**Synopsys (Extreme DA 팀) US 8,407,640 / 8,555,222 / 8,843,864 (우선권 2010-08-25), SCS-OCV.** 8,407,640 claim 1: 각 path의 parametric delay를 "nominal + standard deviation(local random variation의 timing 영향)"으로 두고 "N sigma corner delay 값을 보존하는 statistical maximum". 8,555,222 claim 1: path의 N-sigma corner slack에 도달하는 cell별 delay shift = σ_cell²/√Σσ²(corner 배분). 설명부는 "global(chip-to-chip)은 corner, local은 OCV"로 분리하고 POCV를 "통계 library·RC 없이 SSTA에서 파생"으로 정의한다. 공개 출원 claim은 "N-sigma timing report 출력"을 recite. PrimeTime POCV의 claim 기반. 8,407,640/8,555,222 원문 확인, 8,843,864 초록·검색 요약 확인.

**Magma → Synopsys US 7,992,114 (2008) / US 8,307,317 (2011 계속출원, 2012 등록), "Timing analysis using statistical on-chip variation."** "위치와 무관한 random variation의 timing 영향"과 "power mesh를 따른 bin 간 거리의 함수인 상관으로 표현한 systematic variation의 영향"을 따로 추정한 뒤 "timing requirement를 만족하는 margin을 선택". 통계 library 없이 design-specific OCV margin을 얻는 가장 이른 EDA claim. 원문 확인(모출원 출원일 표기가 두 문서에서 상충).

**Synopsys US 11,893,332 (2021-08-05, 등록 2024-02-06), "Global mistracking analysis."** Vt-class·interconnect mistracking을 corner 집합이 아닌 parameter region으로 덮는 region-based STA; FF/TT/SS signoff를 전제로 "margin-based signoff보다 정확"하고 "circuit element class 간 상관을 명시적으로 모델링". 초록·검색 요약 확인(claim 1 미확인).

**Synopsys US 12,430,486 (우선권 2022-11-30, 등록 2025-09-30), "Combined global and local process variation modeling."** global parameter 집합을 equivalent parameter로 모델링해 MC로 global 분포를 얻고 local과 결합; FF/TT/SS library가 있는 V/T corner에서는 보간. 배경 문장이 산업 기준선(POCV로 local, corner run으로 global)을 명시. 초록·검색 요약 확인(claim 1 미확인).

**Cadence US 7,487,475 / 8,448,104 / 8,645,881 (우선권 2004-10-15), Kriplani "confidence level" SSTA.** BC/TC/WC library의 confidence level 사이를 사용자 지정 k로 보간해 "그 confidence level의 library를 만들지 않고" 성능·yield를 추정. corner library 보간형 statistical corner. 원문 확인.

**Cadence US 8,762,908 / 8,336,010 (우선권 2009-12-04), DS-OCV.** corner library로 OCV-mode STA → top-N path에 sensitivity model로 SSTA(slack = mean − 3σ, 99.9 % yield) → Slack2 = Slack1 : α·RT1 − β·AT1을 풀어 launch/capture derate를 구해 corner STA 입력으로 사용. 통계에서 derate를 도출하는 design-specific 방법. 원문 확인.

**Cadence US 9,805,158 (2015-11-16) / 9,836,564 (2015-04-09).** Monte Carlo 소수 sample에서 K-sigma corner/worst sample을 추출; "foundry FF/SS corner가 적절하지 않을 수 있다". 초록·검색 요약 확인.

**Cadence US 10,789,406 (2018-11-16), "Characterizing electronic component parameters including on-chip variations and moments."** adaptive sensitivity 기반 response surface로 sigma와 moment(mean shift, std_dev, skewness table 정의 포함)를 추출; "결과 library는 local(within-cell/within-die)과 global die-to-die variation을 SSTA용으로 모델링"; RSS 특성화의 low-V 비선형 한계 지적. 초록·검색 요약 확인.

**Texas Instruments US 8,302,047 (우선권 2009-05-06), "Statistical static timing analysis in non-linear regions."** NLOPALV: cell별 delay 함수(CADF) 위에서 f-sigma operating point를 잡아 path의 f-sigma delay를 계산; "VDD ≤ 0.5 V에서 gate delay σ가 nominal에 필적하고 PDF는 강하게 non-Gaussian". Synopsys가 아니라 TI 특허다. 원문 확인.

**TSMC US 8,365,115 (우선권 2009-03-06) / US 8,117,575 (2009-08-10).** SBOCV: non-common path element 수만으로 derate(claim 6은 signoff 승인 방법); stage-weight 합으로 index하는 통합 derate table, derate = 3σ delay/mean delay(transistor-level 통계 simulation). FIG. 6a가 "SSG [W/O GLOBAL VARIATION], @TT, N·σ = 5.0, 45LP"를 인쇄해 local derate가 global 제거 조건에서 특성화됨을 문서화. 원문 확인.

**Freescale US 8,656,331 (2013-02-14), "Timing margins for on-chip variations from sensitivity data."** 특성화 시 transistor별 random parameter(ΔVt) sensitivity를 Liberty 형식 table로 저장하고 AOCV derate로 변환(예: depth 1–10 late derate 1.091…1.030), 위반 instance의 실제 load/slew에서 custom derate 재생성; global vs random parameter 분류를 fab이 제공. Cadence가 아니라 Freescale 특허다. 원문 확인.

**ARM US 9,690,889 / 2015/0370955 / 2016/0357894 / 9,892,220 (2014년경).** AOCV/SBOCV derate를 cell의 실제 load·slew·depth에 맞춰 sigma 분포로 재조정. local variation을 operating point의 함수로 만드는 chipmaker/IP claim. 초록·검색 요약 확인.

**NEC US 7,526,399 (JP 2003) / Renesas US 7,512,920 (JP 2005) / NEC Electronics US 2009/0019408 (JP 2007) / Toshiba US 2009/0249272 (JP 2008).** NEC: 거리 기반 systematic 성분과 stage 수 기반 random 성분(독립 정규 가정, √N)을 RSS로 결합하는 OCV 계산. Renesas: clock·data path를 하나로 묶어 σ_random을 구하고 σ_systematic과 합쳐 σ_chip → D_ocv(예: 3σ_chip/D_base = 0.664 vs 0.972/0.940). NEC Electronics: PCA 주성분별 ±3σ permissible range를 global/local로 나눠 core-macro model이 둘을 함께 덮도록 claim, timing yield 목표 반복. Toshiba: SSTA slack sensitivity로 path별 corner 조건 결정 후 deterministic STA. 모두 원문 확인.

**Matsushita US 2004/0261044 (JP 2003).** test chip 측정 → 상관 Monte Carlo → derating factor 대비 delay yield 곡선(50/75/90/97 % ↔ P = 1.00/1.08/1.15/1.25) → 목표 yield의 derating factor 설정; inside-chip/outside-chip 성분을 각자의 정규 난수로 중첩. "typical delay 기준 yield 지정 margin"의 가장 이른 형태. 원문 확인.

### assignee 정정

검색 요약이 잘못 귀속한 항목을 원문 front page로 바로잡는다: US 8,302,047은 **Texas Instruments**(Synopsys 아님); US 7,992,114/8,307,317은 **Magma Design Automation → Synopsys**(Cadence·Samsung 아님); US 8,555,222/8,843,864/8,407,640은 **Synopsys**(TSMC 아님); US 10,789,406은 **Cadence**(Synopsys 아님); US 9,805,158/9,836,564는 **Cadence**(Solido 아님); US 11,893,332와 US 12,430,486은 **Synopsys**; US 8,656,331은 **Freescale**(Cadence 아님); US 7,594,208은 **Altera**(IBM SSTA 아님); US 7,886,246은 **IBM**(Mentor 아님); US 2015/0213186은 Mentor의 "Timing driven clock tree synthesis"이지 corner 선택 특허가 아니다. 미확인 assignee: US 10,275,554, US 9,183,333(Synopsys로 요약됨), US 8,713,501, US 10,162,916, US 10,311,196, US 11,475,194, US 10,169,507, US 8,352,895.

### 특허 재고표 (e-1): EDA vendor·IBM

검증: 원문 = 공식 PDF front page·claim 확인; 초록 = 검색 요약 확인; 부분 = PDF 일부만 판독. 연도는 최초 우선권/출원 기준.

| 번호 | 제목 (요지) | assignee | 연도 | claim 1의 global/local·corner/sigma 요지 | 검증 |
|---|---|---|---|---|---|
| US 2004/0002844 | statistical modeling & SSTA | IBM (Jess) | 2002 | 계수 sensitivity 기반 통계 행동 model | 원문 |
| US 7,428,716 / 8,010,921 | statistical timing analysis of digital circuits | IBM | 2003 | canonical form; arrival = source 분포의 weighted sum (global+local 항 설명부) | 원문 |
| US 7,111,260 / 7,512,919 / 2008/0307379 | incremental SSTA | IBM | 2003 | tightness probability 기반 증분 전파 | 원문 |
| US 7,086,023 | criticality prediction | IBM | 2003 | node criticality probability | 원문 |
| US 7,117,466 | correlated process pessimism removal | IBM | 2003 | global parameter 일관 배정 + separable parameter worst; corner 열거 없음 | 원문 |
| US 7,089,143 / 7,444,608 | timing evaluation | IBM | 2004 | 유사 cell 상관 항 상쇄, 비유사 항 RSS | 원문 |
| US 7,280,939 | spatial distribution 효과 | IBM | 2004 | 위치/centroid 거리 기반 slack | 원문 |
| US 7,401,307 / 7,716,616 | slack sensitivity | IBM | 2004 | nominal + k·σ reference run에서 sensitivity | 원문 |
| US 7,174,523 | variable sigma adjust | IBM | 2004 | 전압 sensitivity 곡선으로 corner 조정 | 원문 |
| US 7,293,248 / 8,015,525 | non-Gaussian/nonlinear SSTA | IBM | 2004 | generalized canonical form | 원문 (claim 미판독) |
| US 7,437,697 | criticality (cutset) | IBM | 2005 | edge criticality | 원문 |
| US 7,480,880 / 7,861,199 | yield gradient | IBM | 2006/2007 | 통계 timing에서 yield gradient | 원문 |
| US 7,555,740 | hybrid multi-corner sensitivity credit | IBM | 2007 | global worst corner + independent RSS credit | 원문 |
| US 2008/0209372 / 0209374 / 0209375 | multi-corner 보조 | IBM | 2007 | non-common path RSS credit; parameter 순서; 가변 threshold | 원문 |
| US 7,886,246 | failing timing requirements | IBM | 2008 | random group은 σ×배수, corner group은 sensitivity×배수로 slack 외삽 | 원문 |
| US 7,873,926 | practical worst test | IBM | 2008 | 통계 worst slack 판정 | 원문 |
| US 2009/0288051 | statistical slew propagation | IBM | 2008 | canonical slew를 corner로 projection, 유한차분 sensitivity | 원문 |
| US 8,056,035 | crosstalk in SSTA | IBM | 2008 | 통계 effective capacitance | 원문 |
| US 8,104,005 | incremental SSTA 최적화 | IBM | 2008 | 증분 extrema | 원문 |
| US 8,141,025 | mixed deterministic/statistical | IBM | 2009 | filtering 기준으로 통계 표현 선택 | 원문 |
| US 8,122,404 | hierarchical statistical abstraction | IBM | 2009 | macro 통계 abstract | 원문 |
| US 8,108,815 | N-way max non-Gaussian | IBM | 2009 | 양자화 min/max | 원문 |
| US 8,141,012 | closure on selected corners in one SSTA run | IBM | 2009 | 전체 parameter 공간 SSTA → k corner projection | 원문 |
| US 8,359,563 | moment-based characterization waveform | IBM | 2009 | waveform moment (LVF moment 아님) | 원문 |
| US 2012/0117527 | non-separable statistical + deterministic | IBM | 2010 | corner-based parameter + 통계 parameter 단일 run, corner 대입 projection | 원문 (등록 미확인) |
| US 2012/0047477 | clock skew impact on slack | IBM | 2010 | post-CPPR slack + latch-to-latch random RSS | 원문 |
| US 8,413,095 | statistical single library incl. OCV | IBM | 2012 | chip mean + OCV + aging + N/P mistrack → WC statistical corner Liberty | 원문 |
| US 8,732,642 | statistical optimization | IBM | 2012 | canonical sensitivity로 최적화; pad-cell 쌍의 global 상쇄 | 원문 |
| US 8,806,402 / 8,949,765 | multi-patterning variability | IBM | 2012 | canonical shift/scale; global·spatial·random sensitivity (claim 5) | 원문 |
| US 7,945,887 | modeling spatial correlations | IBM (Lu) | — | 거리 감쇠 R/C 상관 grid | 원문 |
| US 2008/0270953, 2008/0250370, 2011/0106497 | at-speed test coverage; variational waveform; voltage binning yield | IBM | 2007–2009 | 주변 | 원문 |
| US 9,501,609 / 10,013,516 / 10,606,970 | corner/margin selection using SSTA | IBM | 2015 | coverage 목표의 corner·margin 선택 | 초록 |
| US 10,055,532 / 2016/0283640 | collapsing terms in SSTA | IBM | 2015 | region 비민감 항 collapse; "per sigma" 정규화 canonical | 초록 |
| US 9,495,497; US 11,093,675 | DVFS (canonical projection); multiple-input switching | IBM | — | 주변 | 초록 |
| US 7,237,212 | 거리 종속 derate | Synopsys | 2004 | region/path별 derate에 distance 성분 | 원문 |
| US 2007/0156367 | MC 성능 분포 | Synopsys | 2006 | parameter 분포 sampling | 원문 |
| US 2007/0174797 / 8,000,826 | systematic + random intra-die yield | Synopsys | 2006 | tile별 systematic + random; 거리 감쇠 상관 언급 | 원문 |
| US 8,204,730 | variation-aware library, mismatch | Synopsys | 2008 | mismatch 전체를 synthetic Gaussian 변수로 | 원문 (claim 미판독) |
| US 8,615,727 | samples-based multi-corner STA | Synopsys | 2010 | multi-corner (통계 아님) | 원문 |
| US 2014/0289690 | OCV-aware CTS | Synopsys | 2013 | 주변 | 원문 |
| US 8,407,640 / 8,555,222 / 8,843,864 | SCS-OCV / statistical corner evaluation | Synopsys (Extreme DA 팀) | 2010 | nominal + σ(local random) → N-sigma corner 보존 max; cell별 corner 배분 | 원문/원문/초록 |
| US 9,183,333 | generalized moment approach | Synopsys (요약) | 2013 | gate별 σ + 고차 moment | 초록 |
| US 10,755,023 | circuit timing analysis (moment 대수) | Synopsys | 2018 | moment conjugation/negation | 초록 |
| US 10,255,395 / 10,783,301 / 11,288,426 | delay/transition variation propagation | Synopsys | 2016–17? | stage별 σ, 상관 계수, Elmore 기반 wire σ; POCV 정규분포 | 초록 |
| US 12,112,108 | timing yield, correlated samples | Synopsys | 2019 | 공통 arc 상관을 고려한 MC yield | 초록 |
| US 11,893,332 | global mistracking analysis | Synopsys | 2021 | mistracking region 기반 STA | 초록 |
| US 12,430,486 | combined global+local modeling | Synopsys | 2022 | equivalent parameter MC global 분포 + local | 초록 |
| US 10,002,225 / 2017/0235868 | STA accuracy (GBA/PBA) | Synopsys | 2016 | 주변 | 초록 |
| US 7,487,486 | statistical sensitivity | Extreme DA 창업진 | 2004 | sensitivity 행렬 전파 | 원문 |
| US 2009/0288050 | statistical delay/noise | Extreme DA 창업진 | 2005 | 독립 변수의 선형 함수로 통계 waveform | 원문 |
| US 7,992,114 / 8,307,317 | statistical OCV margin | Magma → Synopsys | 2008 | random(위치 무관) + systematic(spatial bin 상관) → margin 선택 | 원문 |
| US 7,458,049 | aggregate sensitivity | Magma | 2006 | sensitivity × criticality | 원문 |
| US 7,474,999 | process variation polynomial model | Cadence (Scheffer) | 2002 | nominal + variation 다항 | 원문 |
| US 7,487,475 / 8,448,104 / 8,645,881 | confidence-level SSTA | Cadence (Kriplani) | 2004 | BC/TC/WC library 보간, k-sigma | 원문 |
| US 7,882,471 | sensitivity 기반 parameterized timing | Cadence (Kariat/Phillips/Keller) | 2005 | cell sensitivity 특성화, parameterized report | 원문 |
| US 7,493,574 | statistical corners for yield | Cadence | 2006 | 통계 simulation → statistical corner 생성 | 원문 |
| US 8,239,798 | variation-aware ETM | Cadence (Goyal) | 2007 | arc의 통계 함수 | 원문 (claim 미판독) |
| US 8,180,621 | parametric perturbations | Cadence (Phillips) | 2007 | transistor-level 섭동 | 원문 |
| US 8,813,006 | within-die 특성화 가속 | Cadence | 2008 | 입력 transistor 섭동 sensitivity를 library에 annotate | 원문 |
| US 8,245,165 / 8,782,583 | WAVSTAN | Cadence | 2008 | waveform 기반 variational STA | 원문 |
| US 8,762,908 / 8,336,010 | DS-OCV derate | Cadence | 2009 | STA vs SSTA(mean−3σ) 비교로 derate | 원문 |
| US 8,745,561 | CPPR tree | Cadence | 2013 | CPPR 구조로 최적화 유도 | 원문 |
| US 8,713,501 | DBLOCV | (미판독) | 2014 등록 | dual-box 위치 기반 OCV | 부분 |
| US 9,805,158 / 9,836,564 | K-sigma corner / worst sample from MC | Cadence | 2015 | MC 기반 corner 추출 | 초록 |
| US 10,073,934 / 10,185,795 | SSTA with skewness | Cadence | 2016–17? | LVF moment(skewness) 반영 | 초록 |
| US 10,275,554 | coskewness delay propagation | (미확인; Cadence 팀) | — | 상관·coskewness table | 초록 |
| US 10,789,406 | characterizing OCV and moments | Cadence | 2018 | adaptive response surface → sigma/moment | 초록 |
| US 2008/0133202 / 2011/0087478 | 효율적 특성화 | Altos 창업진 | 2006 | 통계 아님 | 원문 |
| US 2009/0327989 | statistical interconnect corner | Mentor | 2008 | RRR 차원 축소 + application-specific corner | 원문 |
| US 2005/0251771 | process variation band layout | Mentor | 2005 | 주변 | 원문 |
| US 8,494,670 | MC 기반 corner 추출 | Solido | 2011 | yield 목표 기반 MC sample corner | 원문 (claim 미판독) |
| US 9,483,602 | rare-event failure rate | Solido | 2011 | HSMC | 초록 |
| US 7,594,210 / 2008/0120584 | timing variation characterization | CLK DA | 2006 | topology family별 σ/μ | 원문 |
| US 2013/0227510 / 9,245,071 | database-based timing variation analysis | CLK DA | 2012 | — | 원문(A1)/초록 |
| US 7,350,171 / 2007/0113211 / 7,689,954 | extended canonical; quad-tree | WARF; Michigan | 2005/2006 | node sensitivity αᵢ + global sensitivity βⱼ | 원문/초록 |
| US 8,290,761 | 압축 intra-die model, QMC | CMU | 2008 | spatial 상관으로 r개 변수 | 원문 |
| US 2006/0059446 | sensitivity-based SSTA | HP | 2004 | 주변 | 원문 |
| US 7,716,023 | multidimensional corner derivation | Sun/Oracle | 2007 | surrogate 기반 yield corner (global) | 원문 |
| US 8,271,256 / 2011/0040548 | physics-based MOSFET variational model | Sun/Oracle | — | local–global 상관 허용 | 초록/원문(A1) |

### 특허 재고표 (e-2): chipmaker·foundry·IP

| 번호 | 제목 (요지) | assignee | 연도 | claim 1의 global/local·corner/sigma 요지 | 검증 |
|---|---|---|---|---|---|
| US 9,977,845 | STA method (library with local random + global) | Samsung Electronics | 2015 (KR) | local random + global 정보 library; slack = statistical sum; global 1σ 정규화 (설명부) | 초록 |
| US 10,192,015 / KR 2016-0147435 A | yield 추정·최적화 | Samsung Electronics | 2015–16 (KR) | criticality sigma level group별 path 수로 yield | 초록 |
| US 2016/0117435 / KR 2016-0047662 A | timing matching | Samsung Electronics | 2014–15 | 관련성 미확인 | 초록 |
| US 8,275,584 | unified process variation model | TSMC | 2006 | σ_total → σ_global/σ_local 뺄셈 → global/local corner model | 원문 |
| US 7,802,209 | intra-die SSTA library 축소 | TSMC | 2007 | 동작 device만의 library | 원문 |
| US 8,365,115 / 2010/0229137 | SBOCV | TSMC | 2009 | non-common element 수 기반 derate; signoff 승인 claim | 원문 |
| US 8,117,575 / 2011/0035715 | stage-weight OCV table | TSMC | 2009 | 3σ/mean 비 derate table | 원문 |
| US 8,707,230 | MC simulation (device+MPT) | TSMC | 2013 | global/total corner·local 공간 그림 | 원문 |
| US 8,972,919 | STA with DPT misalignment | TSMC | 2012 | launch/capture에 반대 극단 coupling | 원문 |
| US 7,290,232 | multi-corner 최적화 (intra-corner variability) | Altera (Intel) | 2004 | corner별 delay 범위 | 원문 |
| US 7,926,019 | common clock path pessimism | Altera (Intel) | 2008 | CCPP group 제거 | 원문 |
| US 2005/0273308 | local/global 분리 robustness | TI | 2004 | global 범위 위의 local robustness | 원문 |
| US 8,302,047 / 2010/0287517 | NLOPALV | TI | 2009 | local variation의 f-sigma operating point | 원문 |
| US 8,806,413 / 2014/0082576 | gradient AOCV | TI | 2012 | depth < k 동일 derate; clock tree 별도 table | 원문 |
| US 8,656,331 | AOCV from sensitivity data | Freescale (NXP) | 2013 | transistor sensitivity → derate | 원문 |
| US 7,010,475 | derating factor determination | Philips (NXP) | 1999/2003 | cell별 derating 값 simulation | 원문 |
| US 6,356,861 | statistical device model from worst-case files | Agere | 1999 | corner file → PCA → 통계 model (global) | 원문 |
| US 7,399,648 | location-based OCV factor | Agere | 2005 | delay 함수 + layout 함수 결합 | 원문 |
| US 7,480,881 / 2008/0046848 | STA derating + clock conservatism | LSI | 2006 | 두 corner의 min/max stage delay + Y1/Y2 | 원문 |
| US 2009/0217226 | K-factor off-corner derates | (LSI 정황) | 2008 | base corner 특성화 + off-corner K | 원문 |
| US 7,181,713 / 6,851,098 | STA risk analysis | LSI | 2002/2005 | corner 간 variability·margin → risk | 원문 |
| US 6,880,142 | interconnect metal variation delay | LSI | 2002 | 두 독립 변수로 R/C corner | 원문 |
| US 7,069,178 | IDDQ from process monitor derate | LSI | 2004 | die derate + on-chip variation | 원문 |
| US 2013/0152034 | internal-depth derating | LSI | 2011 | simple/complex cell 내부 depth | 원문 |
| US 2013/0080986 / 8,516,424 | IR-drop signoff | LSI | 2011 | cell별 전압 derate | 원문 |
| US 8,645,888 / 2014/0089881 / 8,181,144 | temperature inversion | LSI (Broadcom) | 2008 | 온도별 특성화 + margin | 원문 |
| US 2008/0141190 | process variation tolerant memory | Qualcomm | 2006 | block별 분포 결합 yield | 원문 |
| US 9,690,889 / 2015/0370955 / 2016/0357894 / 9,892,220 | timing derate 조정 | ARM | 2014 | load/slew/depth별 sigma 분포로 derate 재조정 | 초록 |
| US 11,624,777 | slew-load characterization | Arm | 2021 | LVF model data | 초록 |
| US 10,318,676 / WO 2018/140300 | statistical frequency enhancement | Ampere | 2016–17 | path 분포·PDF | 초록 |
| US 10,318,696 | process variation reduction for STA | Ampere (Applied Micro) | 2016–17 | 대표 cell variation profile | 초록 |
| US 10,235,484 | timing-sensitive circuit extraction | Oracle | 2016 | global(instance) vs local(device) 통계 margin | 초록 |
| US 9,633,150 | DOE variation mitigation | Oracle | — | global corner에서 local 영향 최대 | 초록 |
| US 6,526,541 | σ 저장 library | NEC | 2000 | path별 delay σ; σ_CHIP(r) + σ_TR; m·Σσ_CHIP + n·√Σσ_TR² | 원문 |
| US 7,526,399 | systematic + random OCV RSS | NEC | 2003 | 거리 기반 systematic + √N random, RSS | 원문 |
| US 2009/0019408 (JP 2009-021378) | 통계 cell library, global/local range | NEC Electronics | 2007 | PCA ±3σ permissible range를 global/local로 | 원문 |
| US 2009/0024974 | layout-context 통계 delay library | NEC Electronics | 2007 | 1차 sensitivity delay 함수 | 원문 |
| US 7,512,920 | 통합 path σ_chip OCV | Renesas | 2005 | σ_random + σ_systematic → D_ocv | 원문 |
| US 2009/0249272 | SSTA → corner → STA | Toshiba | 2008 | slack sensitivity로 path별 corner | 원문 |
| US 8,196,077 | 통계 cell library 생성 | Toshiba | 2009 | topology group 대표 cell σ/μ | 원문 |
| US 2004/0254776 | stage 수 기반 in-chip variation | Fujitsu | 2002 | 3σ 확률에 맞춘 stage 수 보정 | 원문 |
| US 2008/0178134 | wiring 기반 OCV 계수 | Fujitsu | 2007 | R/C 변동 table → OCV 계수 | 원문 |
| US 2008/0010558 | SSTA pessimism 평가 | Fujitsu | 2006 | 독립 집합 yield 경계 | 원문 |
| US 2007/0074138 | 통계 delay 분석 | Fujitsu | 2005 | critical path 누적 분포 | 원문 |
| US 6,389,381 | delay 계수 table | Fujitsu | 1997 | 통계 아님 | 원문 |
| US 7,239,997 | 통계 LSI delay simulation | Matsushita | 2003 | cell μ/σ library + 통계 timing | 원문 |
| US 2004/0261044 | yield 기반 design margin | Matsushita | 2003 | derating factor ↔ delay yield | 원문 |
| US 6,684,375 | delay 분포 계산 | Matsushita | 2000 | 상관 포함 정점 분포 | 원문 |
| US 2006/0107244 | 전체 난수열 MC | Matsushita | 2004 | path 간 상관 유지 | 원문 |
| US 6,507,936 | wire R/C 변동 timing 검증 | Matsushita | 2000 | 주변 | 원문 |
| US 8,352,895 | SRAM worst-case corner (G/P/SRM) | (미확인) | — | sum corner vs RMS corner | 초록 |
| US 10,162,916 | FPGA variation factors (sigma/delta) | (미확인; Xilinx 정황) | — | sigma = random, delta = systematic | 초록 |
| US 10,311,196 | symbolic timing with spatial variation | (미확인; Altera/Intel 정황) | — | global variation + CCPR | 초록 |
| CN 104101827 / WO 2015/196772 / US 10,422,830 | process corner 검출 회로 | (미확인) | 2014 | corner = 3σ/6σ 정의 | 초록 |
| US 11,755,807; US 12,499,299; CN 117077596; CN 113508338; CN 108133102; CN 121835586; KR 100801054; KR 2019-0115352; KR 101620841 | multi-corner 예측(ML), 저전압 SSTA, STA flow, lithography, MOSFET global corner model, timing view, on-chip margin 측정 등 | (미확인) | — | 관련성 낮거나 미확인 | 초록/서지 |
| 미검증 후보 | US 11,475,194; 11,361,800; 10,169,507; 9,760,664/5; 10,430,536; 9,710,594; 12,487,278; 10,289,776; 12,056,428; CN 105335536; EP 2899653 | (미확인) | — | 목록만 확인 | 미확인 |

### 우선권 연도 timeline

| 연도 | 문서 (assignee) | 주제 |
|---|---|---|
| 1997–2000 | Fujitsu 6,389,381; Agere 6,356,861; Philips 7,010,475 모출원; NEC 6,526,541; Matsushita 6,507,936/6,684,375 | derate 계수, corner file → 통계 model, σ 저장 library |
| 2002 | IBM 2004/0002844; Cadence 7,474,999; Fujitsu 2004/0254776; LSI 6,880,142/6,851,098 | 초기 통계 model, stage 수 보정 |
| 2003 | IBM canonical 3건 + 7,117,466; NEC 7,526,399; Matsushita 7,239,997/2004/0261044; Philips 7,010,475 | canonical form, RSS OCV, yield 기반 margin |
| 2004 | IBM 7,089,143/7,280,939/7,401,307/7,174,523/7,293,248(prov.); Extreme DA 7,487,486; Cadence 7,487,475(prov.); Synopsys 7,237,212; TI 2005/0273308; HP; Altera 7,290,232 | RSS credit, confidence-level corner, 거리 derate, global/local 분리 |
| 2005 | Extreme DA 2009/0288050; Agere 7,399,648; Cadence 7,882,471(prov.); IBM 7,437,697; Renesas 7,512,920; WARF 7,350,171; Fujitsu 2007/0074138 | location OCV, sensitivity timing |
| 2006 | IBM 7,480,880; Cadence 7,493,574; Magma 7,458,049; LSI 7,480,881; CLK DA 7,594,210; TSMC 8,275,584; Synopsys 2007/0156367, 2007/0174797; Qualcomm 2008/0141190; Fujitsu 2008/0010558 | σ_global/σ_local 뺄셈 model, statistical corner |
| 2007 | IBM 7,555,740 family, 7,861,199; Cadence 8,239,798/8,180,621(prov.); Sun 7,716,023; TSMC 7,802,209; NEC Electronics 2009/0019408, 2009/0024974; Fujitsu 2008/0178134 | hybrid multi-corner, global/local permissible range |
| 2008 | IBM 7,873,926/7,886,246/2009/0288051/8,056,035/8,104,005; Mentor 2009/0327989; Synopsys 8,204,730; Magma 7,992,114; Cadence 8,813,006/8,245,165; Toshiba 2009/0249272; LSI 2009/0217226; Altera 7,926,019; CMU 8,290,761; LSI 8,181,144 root | statistical OCV margin, SSTA→corner, CCPP |
| 2009 | IBM 8,141,025/8,122,404/8,108,815/8,141,012/8,359,563; TSMC 8,365,115/8,117,575; TI 8,302,047(prov.); Cadence 8,762,908(prov.); Toshiba 8,196,077 | corner projection, SBOCV, NLOPALV, DS-OCV |
| 2010 | TI 8,302,047; Cadence 8,762,908; IBM 2012/0047477, 2012/0117527; Synopsys SCS-OCV(prov.), 8,615,727 | N-sigma corner, non-separable hybrid |
| 2011 | Solido 8,494,670; Magma/Synopsys 8,307,317; Synopsys 8,407,640; LSI 2013/0080986, 2013/0152034 | MC corner 추출 |
| 2012 | IBM 8,413,095/8,732,642/8,806,402; CLK DA 2013/0227510; TI 8,806,413(prov.); TSMC 8,972,919(prov.) | statistical single library, gradient AOCV |
| 2013 | Freescale 8,656,331; Synopsys 8,555,222/2014/0289690(prov.); TSMC 8,707,230; Cadence 8,745,561; Synopsys 9,183,333; IBM 8,949,765 | sensitivity → AOCV, moments |
| 2014–2015 | ARM 9,690,889 family; Samsung 9,977,845(KR 2015-01); Cadence 9,836,564/9,805,158; IBM 9,501,609, 10,055,532; Samsung 10,192,015(KR) | derate 재조정, global 1σ library + RSS slack, K-sigma corner, corner 선택 |
| 2016–2018 | Cadence 10,073,934/10,275,554; Synopsys 10,255,395 family; Oracle 10,235,484; Ampere 10,318,676/10,318,696; Synopsys 10,755,023; Cadence 10,789,406 | LVF moments, POCV wire σ, moment 대수 |
| 2019–2022 | Synopsys 12,112,108; Synopsys 11,893,332; Arm 11,624,777; Synopsys 12,430,486 | 상관 yield, mistracking region, combined global+local |

특허 기록의 전체 그림: corner projection·hybrid corner claim은 2007–2012년 IBM에, nominal + sigma OCV claim은 2008–2010년 Magma·Extreme DA/Synopsys에, moment LVF claim은 2013–2018년 Synopsys·Cadence에 몰려 있다. global sigma를 corner로 만드는 claim은 foundry(TSMC 8,275,584)와 IBM library 측(8,413,095)에만 있고, "typical corner + combined global/local N-sigma margin"을 nominal corner에서 문자 그대로 claim한 검증된 문서는 없다. Samsung 9,977,845가 요약 수준에서 가장 가깝고, 그 구성 요소(global 3σ corner + local RSS: IBM 7,555,740; σ_local from σ_total: TSMC; N-sigma corner report: Synopsys SCS-OCV)는 모두 선행 기술로 존재한다.

## 조사 범위와 검증 수준

조사 범위는 28 nm–3 nm급 digital STA signoff와 그 기초가 되는 SSTA·variation modeling 문헌, EDA vendor 문서, 미국·한국·일본·중국 특허다. 검증 수준은 네 단계로 표기했다.

- **원문 확인**: 문서 전문을 읽고 인용. 해당 항목: 2015년 초 이전에 등록·공개된 미국 특허 약 60건(공식 USPTO PDF의 front page·요약·claim 1; 일부 PDF는 claim 페이지 text layer가 없어 요약만 판독), PrimeTime User Guide(Q-2019.12/M-2018.06)·PrimeTime Suite Variables and Attributes(W-2024.09-SP3)·Tool Commands(U-2022.12-SP5)·Innovus/Tempus Text Command Reference(21.10–25.10)·Innovus 25.10 man page의 공개 mirror 텍스트, Liberty Reference Manual 2020.09 mirror와 2017.06 PDF, OpenSTA 문서·source, 실제 LVF library(N5급 TT 0.355 V, 공개 test library), 공개 flow script·log, IHP/sky130 PDK model file, gist·blog 원문. vendor 문서는 원본이 아닌 mirror 텍스트이므로 외부 인용 전 원본 대조가 필요하다.
- **초록·검색 요약 확인**: 논문 초록·검색 요약, 특허 요약·claim 발췌만 확인하고 전문은 열지 못한 항목. IEEE/ACM/IOP/arXiv 논문 대부분, Synopsys·Cadence 백서·datasheet·blog, Semiconductor Engineering·SemiWiki·EDN 기사, 2015년 이후 특허 전부(Samsung 9,977,845·10,192,015, ARM, Ampere, Oracle, IBM 9,501,609 family, Synopsys 11,893,332·12,430,486·12,112,108·10,255,395 family·9,183,333·10,755,023, Cadence 9,805,158·9,836,564·10,073,934·10,275,554·10,789,406).
- **미확인**: 제목·서지만 확인했거나 존재를 확인하지 못한 항목. Kahng DAC 2015 본문 수치, J. Phys.: Conf. Ser. 1706의 slack 수치, SNUG·CDNLive·TSMC OIP·Samsung SAFE 발표 본문, Bautz/Lokanadham TAU 2014, Ghanta TAU 2016, Lütkemeyer TAU 2021, IBM 45 nm ASIC 논문의 저자·venue, TVLSI 2009 multi-core 논문의 저자, FinFET/GAA node의 σ_global : σ_local 수치, within-die correlation length(28 nm 이하), Giles 2015의 19/24 mV가 1σ인지 3σ인지, US 7,555,740 sensitivity 식의 분모 부호, US 2012/0117527·2009/0288051의 등록 여부, US 8,275,584 외 TSMC LVF-era 특허, Intel·Qualcomm·Apple·NVIDIA·AMD·MediaTek·SK hynix·Huawei/HiSilicon·Empyrean·Primarius의 관련 특허, 국내 학술지·학위논문·SAFE 국문 자료, KR 계열 공개번호, `timing_pocvm_enable_global_variation`류 변수명(문서·script 0건), PrimeShield의 global variation 기능, Liberty `ocv_derate_distance_mode`, PrimeTime의 legacy `va_*` 구문 지원 여부.
- **추정**: 본 리뷰의 유도·해석. 이중 계상 백분율표, σ_D,local ≈ ∂D/∂Vt·σ_Vt와 alpha-power 근사, SSGNP 2.5σ의 상관 계수 재현, canonical form의 max·slack 식 중 검색 요약에 없는 부분(재구성), "total-sigma LVF는 common-mode credit을 잃는다", "AOCV distance 축이 FinFET에서 정보를 잃었다", "이중 계상은 hold/short path에서 크다", σ_L/σ_G의 전압 종속성 해석.

전문 확인이 특히 필요한 항목(우선순위 순): (1) Samsung US 9,977,845 전체 claim·KR 공개본·발명자, (2) TSMC US 8,275,584 이후의 LVF-era foundry 특허(assignee + CPC G06F30/3312, G06F2119/12 검색), (3) Kahng DAC 2015와 Tetelbaum 2014 본문, (4) J. Phys.: Conf. Ser. 1706 012081의 Fig. 3–6 slack 수치, (5) Giles VLSI 2015와 Yeric ICMTS 2014의 그림·수치, (6) Kuhn TED 2011의 within-wafer/within-die RO data, (7) Visweswariah DAC 2004 원문의 max 재표현 식, (8) Synopsys US 12,430,486·11,893,332의 claim 1, (9) Cadence 16 nm 백서의 150/200 ps 수치의 design·node, (10) PrimeTime·Tempus 최신 vendor 원본 문서(특히 Tempus User Guide의 SOCV global derate 유무), (11) Liberty 규격 원본(ocv_sigma 최초 도입 release, 2017 moment 비준 문구), (12) Cadence Community forum의 global/total corner 정의 원문.

## 결론: 사내 적용에 필요한 것은 σ_L/σ_G 비율과 common-mode credit의 자체 측정값이다

공개 자료가 주는 것은 TT signoff의 대수(분산 가산, √N, canonical projection, RSS corner)와 그 구성 요소의 선행 기술이며, 주지 않는 것은 정량이다. 이중 계상으로 회수 가능한 margin은 path의 유효 σ_L'/σ_G 비율이 결정하는데(1:1이면 variation 항의 41 %, 1:10이면 9 %), 이 비율은 FinFET/GAA node에서 공개된 적이 없고 전압에 따라 변한다(Yeric). 따라서 TT + RSS margin flow의 타당성 주장은 자사 test structure의 die-median 분포(σ_global)와 within-die 분포(σ_local)를 TSMC 특허의 정의대로 같은 device·같은 corner에서 뽑고, 그 값으로 SSG+LVF와 TT+RSS의 slack 차이를 design에서 직접 비교하는 것으로만 뒷받침된다. 두 번째 미측정량은 launch/capture 사이의 global 상쇄 비율이다. canonical form에서는 자동이지만 상용 timer는 cell을 독립으로 보므로, TT flow에서 global margin을 guardband로 넣으면 이 credit을 얻지 못하고 SS corner보다 오히려 보수적일 수 있다. clock tree의 공통 depth 대비 data path depth 분포로 상쇄 비율을 추정하고 guardband를 setup/hold·path 유형별로 나눠 두는 것이 현실적인 절충이다. 세 번째로, LVF sigma는 corner별 값이므로 TT sigma로 SS tail을 덮을 수 없다. TT 기준 flow라도 local sigma는 SS/low-V library에서 가져오거나 σ_D,local의 전압 의존성으로 scale해야 하고, 0.5 V 이하에서는 moment LVF가 필수다. 마지막으로 mistracking(Vt class, N/P, BEOL), RC corner의 correlated 성분, V/T, aging, IR drop은 SS corner가 암묵적으로 덮던 항목이므로 TT 기준으로 옮길 때 각각 명시적 항으로 되살려야 하며, 이 항목들의 합이 회수한 margin을 상당 부분 상쇄할 수 있다. 특허 측면에서는 Samsung 9,977,845의 library 구조(global 값 1σ 정규화 + RSS slack)가 이미 있으므로 사내 flow는 그 claim 범위와 EDA 선행 기술(IBM 7,555,740, TSMC 8,275,584, Synopsys SCS-OCV)을 함께 검토한 뒤 설계하는 것이 순서다.

## 참고 문헌

### A. 논문·백서·기사

1. C. Visweswariah, K. Ravindran, K. Kalafala, S. G. Walker, S. Narayan, "First-Order Incremental Block-Based Statistical Timing Analysis," DAC 2004; IEEE TCAD 25(10), 2006. https://people.eecs.berkeley.edu/~alanmi/research/timing/papers/sta_ibm.pdf ; https://dl.acm.org/doi/10.1109/TCAD.2005.862751
2. J. A. G. Jess, K. Kalafala, S. R. Naidu, R. H. J. M. Otten, C. Visweswariah, "Statistical timing for parametric yield prediction of digital integrated circuits," DAC 2003. https://dl.acm.org/doi/10.1145/775832.776066
3. C. Visweswariah, "Death, taxes and failing chips," DAC 2003. https://dl.acm.org/doi/10.1145/775832.775921
4. R. Chen, L. Zhang, V. Zolotov, C. Visweswariah, J. Xiong, "Static timing: Back to our roots," ASP-DAC 2008. https://www.researchgate.net/publication/4327328_Static_timing_Back_to_our_roots
5. J. Xiong, V. Zolotov, N. Venkateswaran, C. Visweswariah, "Criticality computation in parameterized statistical timing," DAC 2006. https://research.ibm.com/publications/criticality-computation-in-parameterized-statistical-timing
6. H. Chang, V. Zolotov, S. Narayan, C. Visweswariah, "Parameterized block-based statistical timing analysis with non-Gaussian parameters, nonlinear delay functions," DAC 2005.
7. "Timing Closure in 45 Nanometer ASICs Using Statistical Static Timing Analysis Design Methodology" (IBM; 저자·venue 미확인). https://www.academia.edu/4136360/Timing_Closure_in_45Nanometer_ASICs_Using_Statistical_Static_Timing_Analysis_Design_Methodology
8. H. Chang, S. S. Sapatnekar, "Statistical timing analysis considering spatial correlations using a single PERT-like traversal," ICCAD 2003; "Statistical Timing Analysis Under Spatial Correlations," IEEE TCAD 24(9), 2005. https://www.researchgate.net/publication/224695002_Statistical_Timing_Analysis_Considering_Spatial_Correlations
9. A. Agarwal, D. Blaauw, V. Zolotov, "Statistical timing analysis for intra-die process variations with spatial correlations," ICCAD 2003. https://dl.acm.org/doi/abs/10.5555/996070.1009993
10. J. Le, X. Li, L. T. Pileggi, "STAC: statistical timing analysis with correlation," DAC 2004. https://dl.acm.org/doi/10.1145/996566.996665
11. J. Xiong, V. Zolotov, L. He, "Robust extraction of spatial correlation," ISPD 2006; IEEE TCAD 26(4), 2007. https://www.researchgate.net/publication/3226060_Robust_Extraction_of_Spatial_Correlation
12. B. Cline, K. Chopra, D. Blaauw, Y. Cao, "Analysis and modeling of CD variation for statistical static timing," ICCAD 2006.
13. B. Hargreaves, H. Hult, S. Reda, "Within-die process variations: How accurately can they be statistically modeled?," ASP-DAC 2008. https://ieeexplore.ieee.org/document/4484007/
14. D. Blaauw, K. Chopra, A. Srivastava, L. Scheffer, "Statistical Timing Analysis: From Basic Principles to State of the Art," IEEE TCAD 27(4), 2008. https://dl.acm.org/doi/abs/10.1109/TCAD.2007.907047
15. C. Forzan, D. Pandini, "Statistical static timing analysis: A survey," Integration 42(3), 2009. https://www.sciencedirect.com/science/article/abs/pii/S0167926008000564
16. M. Orshansky, S. Nassif, D. Boning, *Design for Manufacturability and Statistical Design: A Constructive Approach*, Springer, 2008. https://www.researchgate.net/publication/288222537_Design_for_manufacturability_and_statistical_design_A_constructive_approach
17. S. Onaissi, F. N. Najm, "A Linear-Time Approach for Static Timing Analysis Covering All Process Corners," ICCAD 2006; IEEE TCAD 27(7), 2008. https://dl.acm.org/doi/10.1145/1233501.1233545
18. S. Onaissi, F. Taraporevala, J. Liu, F. N. Najm, "A fast approach for static timing analysis covering all PVT corners," DAC 2011. https://dl.acm.org/doi/10.1145/2024724.2024899
19. L. Zhang, W. Chen, Y. Hu, J. A. Gubner, C. C.-P. Chen, "Correlation-preserved non-Gaussian statistical timing analysis with quadratic timing model," DAC 2005. https://www.researchgate.net/publication/3337907_A_Quadratic_Modeling-Based_Framework_for_Accurate_Statistical_Timing_Analysis_Considering_Correlations
20. Y. Zhan, A. J. Strojwas, X. Li, L. T. Pileggi, D. Newmark, M. Sharma, "Correlation-aware statistical timing analysis with non-Gaussian delay distributions," DAC 2005. https://www.cecs.uci.edu/~papers/dac05/abstracts/2005/dac05_abs.pdf
21. L. Cheng, J. Xiong, L. He, "Non-Linear Statistical Static Timing Analysis for Non-Gaussian Variation Sources," DAC 2007; IEEE TCAD 28(1), 2009. https://www.researchgate.net/publication/4257296_Non-Linear_Statistical_Static_Timing_Analysis_for_Non-Gaussian_Variation_Sources
22. C. E. Clark, "The Greatest of a Finite Set of Random Variables," Operations Research 9(2), 1961. https://pubsonline.informs.org/doi/10.1287/opre.9.2.145
23. D. Sinha, H. Zhou, N. V. Shenoy, "Advances in Computation of the Maximum of a Set of Gaussian Random Variables," IEEE TCAD 26(8), 2007. https://dl.acm.org/doi/10.1109/TCAD.2007.893544
24. K. A. Bowman, S. G. Duvall, J. D. Meindl, "Impact of die-to-die and within-die parameter fluctuations on the maximum clock frequency distribution for gigascale integration," IEEE JSSC 37(2), 2002. https://dblp.org/db/journals/jssc/jssc37.html
25. "Impact of die-to-die and within-die parameter variations on the clock frequency and throughput of multi-core processors," IEEE TVLSI 17(12), 2009 (저자 표기 불일치). https://dl.acm.org/doi/abs/10.1109/TVLSI.2008.2006057
26. B. E. Stine, D. S. Boning, J. E. Chung, "Analysis and decomposition of spatial variation in integrated circuit processes and devices," IEEE TSM 10(1), 1997. https://boning.mit.edu/publications/journal-papers/
27. D. Boning, J. Chung, "Spatial variation in semiconductor processes: modeling for control," ECS 1997. https://boning.mit.edu/wp-content/uploads/2022/11/ECS97-paper-preprint-1.pdf
28. S. R. Nassif, "Modeling and analysis of manufacturing variations," CICC 2001. https://www.researchgate.net/publication/3900188_Modeling_and_Analysis_of_Manufacturing_Variations
29. K. Agarwal, S. R. Nassif, "Characterizing process variation in nanometer CMOS," DAC 2007. https://dl.acm.org/doi/pdf/10.1145/1278480.1278582
30. C.-K. Lin, C. Hsiao, H.-C. Tseng, M.-C. Jeng, "Id1 = Id0 + G + L1, Id2 = Id0 + G + L2: A Comprehensive Solution for Process Variation Characterization and Modeling," SISPAD 2012. http://in4.iue.tuwien.ac.at/pdfs/sispad2012/10-5.pdf
31. M. J. M. Pelgrom, A. C. J. Duinmaijer, A. P. G. Welbers, "Matching properties of MOS transistors," IEEE JSSC 24(5), 1989. https://www.semanticscholar.org/paper/Matching-properties-of-MOS-transistors-Pelgrom-Duinmaijer/cc3979e1f2b9c1434b2e6cb34175346a1cf9fd40
32. P. G. Drennan, C. C. McAndrew, "Understanding MOSFET mismatch for analog design," IEEE JSSC 38(3), 2003. https://www.semanticscholar.org/paper/Understanding-MOSFET-mismatch-for-analog-design-Drennan-McAndrew/2689433ff7e91b0bc1e8e81c8ab26162aaa56368
33. A. Asenov, S. Kaya, A. R. Brown, "Intrinsic parameter fluctuations in decananometer MOSFETs introduced by gate line edge roughness," IEEE TED 50(5), 2003. https://eprints.gla.ac.uk/2958/1/intrinsic_para_fluct.pdf
34. K. Takeuchi et al., "Understanding random threshold voltage fluctuation by comparing multiple fabs and technologies," IEDM 2007. https://ieeexplore.ieee.org/document/4418975
35. K. J. Kuhn et al., "Process Technology Variation," IEEE TED 58(8), 2011. https://www.researchgate.net/publication/252061364_Process_Technology_Variation
36. M. D. Giles et al., "High sigma measurement of random threshold voltage variation in 14nm Logic FinFET technology," VLSI 2015. https://ieeexplore.ieee.org/document/7223657/
37. L.-T. Pang, K. Qian, C. J. Spanos, B. Nikolić, "Measurement and Analysis of Variability in 45 nm Strained-Si CMOS Technology," IEEE JSSC 44(8), 2009. https://ieeexplore.ieee.org/document/5173763/
38. B. Nikolić et al., "Technology Variability From a Design Perspective," IEEE TCAS-I 58(9), 2011. https://www.researchgate.net/publication/220624688_Technology_Variability_From_a_Design_Perspective
39. G. Yeric, "Processor yield at 14nm and beyond," ICMTS 2014. https://ieeexplore.ieee.org/document/6841477
40. R. G. Dreslinski, M. Wieckowski, D. Blaauw, D. Sylvester, T. Mudge, "Near-Threshold Computing: Reclaiming Moore's Law Through Energy Efficient Integrated Circuits," Proc. IEEE 98(2), 2010. https://semiengineering.com/near-threshold-computing-2/
41. C. K. Jha et al., "Comparison of LER Induced Mismatch in NWFET and NSFET for 5-nm CMOS," IEEE JEDS 2020. https://ieeexplore.ieee.org/document/9205251/
42. D. Nagy et al., "Simulations of Statistical Variability in n-Type FinFET, Nanowire, and Nanosheet FETs" (venue 미확인). https://www.researchgate.net/publication/354306427_Simulations_of_Statistical_Variability_in_n_-Type_FinFET_Nanowire_and_Nanosheet_FETs
43. S. K. Saha, "Compact MOSFET Modeling for Process Variability-Aware VLSI Circuit Design," IEEE Access 2, 2014. https://ieeexplore.ieee.org/document/6732881/
44. N. Karmokar et al., "Common-Centroid Layout for Active and Passive Devices: A Review and the Road Ahead," ASP-DAC 2022 (변환 텍스트). https://raw.githubusercontent.com/xiaohangguo/pdfChat/8f8cc30a1ab866ffc1a135006ae8793f5f801b23/uploads/auto/Common-Centroid_Layout_for_Active_and_Passive_Devices_A_Review_and_the_Road_Ahead.md
45. A. B. Kahng, "New game, new goal posts: A recent history of timing closure," DAC 2015. https://dl.acm.org/doi/10.1145/2744769.2747937 ; https://vlsicad.ucsd.edu/Publications/Conferences/330/c330.pdf
46. A. B. Kahng, "The Future of Signoff," TAU 2011 keynote. https://vlsicad.ucsd.edu/Presentations/talk/TAU11-Keynote-Kahng-distributed.pdf
47. A. B. Kahng, S. Dobre, T.-B. Chan, "Improved signoff methodology with tightened BEOL corners," ICCD 2014. https://www.researchgate.net/publication/289572597_Improved_signoff_methodology_with_tightened_BEOL_corners
48. A. B. Kahng, U. Mallappa, L. Saul, S. Tong, "'Unobserved Corner' Prediction: Reducing Timing Analysis Effort for Faster Design Convergence in Advanced-Node Design," DATE 2019. https://www.semanticscholar.org/paper/50b67818072d0439d8eaf693c6b891a695d0a4a9
49. A. Tetelbaum, "Corner-based Timing Signoff and What Is Next," AnySilicon, Jan 2014. https://anysilicon.com/wp-content/uploads/2014/10/Corner_based_Signoff_paper_Jan_2014a.pdf ; "Design for Variability and Signoff Tips," Feb 2014. https://anysilicon.com/wp-content/uploads/2014/10/Signoff_Tips_paper_Feb_2014a.pdf ; "How to Minimize the Number of Timing Signoff Corners." https://www.linkedin.com/pulse/how-minimize-number-timing-signoff-corners-dr-alexander-tetelbaum
50. Mahajan Rita, Sharma Aru, Bansal Manish, "Timing analysis journey from OCV to LVF," J. Phys.: Conf. Ser. 1706 (2020) 012081. https://iopscience.iop.org/article/10.1088/1742-6596/1706/1/012081/pdf
51. A. Mishra, R. Mittal, "Reducing signoff corners to achieve faster 40 nm SOC design closure," Embedded.com, 2011. https://www.embedded.com/reducing-signoff-corners-to-achieve-faster-40-nm-soc-design-closure/
52. L. Zhu, X. Guo, Y. Cai, "One-for-All: An Unified Learning-based Framework for Efficient Cross-Corner Timing Signoff," ICCAD 2024. https://dl.acm.org/doi/10.1145/3676536.3676656
53. J. Xu et al., "FACT: Fast and Accurate Multi-Corner Predictor for Timing Closure in Commercial EDA Flows," ACM TODAES 31(4). https://dl.acm.org/doi/10.1145/3768166
54. "Machine-Learning-Based Multi-Corner Timing Prediction for Faster Timing Closure," Electronics 11(10):1571, 2022. https://doi.org/10.3390/electronics11101571
55. "A parametric approach for handling local variation effects in timing analysis," DAC 2009. https://dl.acm.org/doi/10.1145/1629911.1629949
56. D. M. T. Nguyen et al., "Advanced On-Chip Variation in Static Timing Analysis for Deep Submicron Regime," ACOMP 2020. https://ieeexplore.ieee.org/document/9353065/
57. "Accelerating timing closure using incremental advanced OCV." https://ieeexplore.ieee.org/document/7153482/ ; "A New Generation of Static Timing Analysis Technology Based on N7+ Process—POCV." https://ieeexplore.ieee.org/document/8977171/
58. "Pipeline-Stage-Resolved Timing Characterization of FPGA and ASIC Implementations of a RISC-V Processor," arXiv:2512.13866 / Eng. Res. Express. https://arxiv.org/pdf/2512.13866
59. D. Mishagli, E. Koskin, E. Blokhina, "Statistical Static Timing Analysis of VLSI as the Statistics of Correlated Extremes," arXiv:2401.03559; "Gate-Level Statistical Timing Analysis: Exact Solutions, Approximations and Algorithms," arXiv:2401.03588. https://arxiv.org/abs/2401.03559
60. J. Zhou et al., "LVFGen: Efficient Liberty Variation Format (LVF) Generation Using Variational Analysis and Active Learning," ISPD 2025. https://eprints.whiterose.ac.uk/id/eprint/226187/1/3698364.3705359.pdf
61. "LVF2: A statistical timing model based on Gaussian mixture," DAC 2024. https://eprints.whiterose.ac.uk/id/eprint/221555/1/3649329.3655670.pdf
62. "Shift-Left Techniques in Electronic Design Automation: A Survey," arXiv:2509.14551; "Practical Timing Closure in FPGA and ASIC Designs," arXiv:2510.26985. https://arxiv.org/pdf/2509.14551 ; https://arxiv.org/pdf/2510.26985
63. A. Shah, R. Nayyar, A. Sinha, "Silicon-Proven Timing Signoff Methodology Using Hazard-Free Robust Path Delay Tests," IEEE Design & Test 37(4), 2020. https://ieeexplore.ieee.org/document/8758603/
64. L.-C. Wang, P. Bastani, M. S. Abadir, "Design-Silicon Timing Correlation — A Data Mining Perspective," DAC 2007. https://dl.acm.org/doi/10.1145/1278480.1278580
65. "Cross-Corner Delay Variation Model for Standard Cell Libraries." https://www.researchgate.net/publication/351592387_Cross-Corner_Delay_Variation_Model_for_Standard_Cell_Libraries
66. "Ultra-Low Voltage Enablement for Standard Cells with Moment based LVF," IEEE 2024. https://ieeexplore.ieee.org/document/10528685/
67. "Statistical Corner Conditions of Interconnect Delay (Corner LPE Specifications)." https://www.researchgate.net/publication/220243212_Statistical_Corner_Conditions_of_Interconnect_Delay_Corner_LPE_Specifications
68. B. Klass, "Design for Yield Using Statistical Design," Stanford EE380, 2007. https://web.stanford.edu/class/ee380/Abstracts/070207-EE380_Design_for_Yield_Klass_1p0.pdf
69. Boise State thesis, "CMOS characterization, modeling, and circuit design in the presence of random local variation." https://scholarworks.boisestate.edu/cgi/viewcontent.cgi?article=1768&context=td
70. N. Damrongplasit, "Study of Variability in Advanced Transistor Technologies," UC Berkeley EECS-2015-37. https://www2.eecs.berkeley.edu/Pubs/TechRpts/2015/EECS-2015-37.pdf
71. S. Walia, "PrimeTime Advanced OCV Technology," Synopsys white paper. https://www.synopsys.com/content/dam/synopsys/implementation&signoff/white-papers/PrimeTime_AdvancedOCV_WP.pdf
72. "Parametric on-chip variation: A step towards accurate timing analysis," EDN. https://www.edn.com/parametric-on-chip-variation-a-step-towards-accurate-timing-analysis/
73. Cadence, "Addressing Process Variation and Reducing Timing Pessimism at 16nm and Below." https://www.cadence.com/en_US/home/resources/white-papers/addressing-process-variation-and-reducing-timing-pessimism-at-16nm-and-below-wp.html
74. Cadence Liberate Variety; Liberate Trio Process Variation Modeling. https://www.cadence.com/en_US/home/tools/custom-ic-analog-rf-design/library-characterization/variety-statistical-characterization-solution.html ; https://www.cadence.com/en_US/home/tools/custom-ic-analog-rf-design/library-characterization/liberate-trio-characterization-suite/process-variation-modeling.html
75. Cadence, "Signoff Summit: An Update on OCV, AOCV, SOCV, and Statistical Timing," 2013. https://community.cadence.com/cadence_blogs_8/b/ii/posts/signoff-summit-an-update-on-ocv-aocv-socv-and-statistical-timing
76. Cadence, "Overriding the One-Sigma Rule of Liberty for LVF Modeling." https://community.cadence.com/cadence_blogs_8/b/di/posts/library-characterization-tidbits-overriding-the-one-sigma-rule-of-liberty-for-lvf-modeling
77. Cadence, "Accelerating Monte Carlo Analysis at Advanced Nodes." https://www.cadence.com/content/dam/cadence-www/global/en_US/documents/tools/custom-ic-analog-rf-design/monte-carlo-analysis-at-advanced-nodes-wp.pdf
78. B. Bautz, S. Lokanadham, "SOCV," TAU 2014. http://www.tauworkshop.com/2014/Slides/Bautz_SOCV_TAU_2014.pdf ; P. Ghanta, "Importance of Modeling Non-Gaussianities in STA in sub-16nm Nodes," TAU 2016. http://www.tauworkshop.com/2016/slides/10_TAU2016_Ghanta_nonGaussian_POCV.pdf
79. "SOCV Delay and Arrival Calculations in Tempus." https://www.academia.edu/38965092/SOCV_Delay_and_Arrival_Calculations_in_Tempus
80. Synopsys press release, 2017-02-27, LVF moment 확장. https://news.synopsys.com/2017-02-27-Synopsys-Announces-Expansion-of-Liberty-Modeling-Standard-Paving-Way-for-Ultra-Low-Power-IC-Design
81. SemiWiki/CLK Design Automation, "Variation Alphabet Soup." https://semiwiki.com/x-subscriber/clk-design-automation/4481-variation-alphabet-soup/
82. SemiWiki, "Top 10 Highlights from the TSMC Open Innovation Platform Ecosystem Forum." https://semiwiki.com/semiconductor-manufacturers/tsmc/7759-top-10-highlights-from-the-tsmc-open-innovation-platform-ecosystem-forum/
83. Semiconductor Engineering, "Process Variation Not A Solved Issue." https://semiengineering.com/process-variation-not-a-solved-issue/ ; "Process Corner Explosion." https://semiengineering.com/process-corner-explosion/ ; "Timing Library LVF Validation For Production Design Flows." https://semiengineering.com/timing-library-lvf-validation-for-production-design-flows/
84. Electronic Design, "Industry Ready To Sign On To Statistical Timing Signoff," 2007. https://www.electronicdesign.com/news/products/article/21756569/industry-ready-to-sign-on-to-statistical-timing-signoff
85. EE Times, "Designers wary as IBM embraces statistical timing." https://www.eetimes.com/designers-wary-as-ibm-embraces-statistical-timing-3/ ; "IBM markets statistical timing analyzer." https://www.eetimes.com/ibm-markets-statistical-timing-analyzer/
86. Samsung 10LPP Cadence reference flow (SOCV/LVF), 2016. https://sst.semiconductor-digest.com/2016/10/cadence-reference-flow-with-digital-and-signoff-tools-certified-on-samsungs-10nm-process-technology/
87. brabect1, "OCV and timing derating #sta" (gist). https://gist.github.com/brabect1/6281f4cf9fb53002fb17f15fa3bf4f62
88. "PrimeTime and Timing Derate" (2022-05-07). https://github.com/chipgun/nibaix.github.io/blob/master/2022/05/07/PrimeTime-and-OCV/index.html
89. raytroop, "Process Variation & RC corner." https://raw.githubusercontent.com/raytroop/raytroop.github.io/98a66e32ed9f79ab3ac3659341045162c7823256/source/_posts/corners.md ; CaseyZhu, PVTCorner.txt. https://raw.githubusercontent.com/CaseyZhu/my_git_hub/7232a669a64df31377f70d0ef0268daf3c5f8fe4/PVTCorner.txt
90. KISTI ScienceON, 국가 R&D 보고서 TRKO201300034125 (OCV 모델링). https://scienceon.kisti.re.kr/srch/selectPORSrchReport.do?cn=TRKO201300034125 ; velog @dkwl928, "OCV / AOCV / POCV." https://velog.io/@dkwl928/OCV-AOCV-POCV

### B. 표준·model file

91. Liberty User Guides and Reference Manual Suite 2017.06, Ch. 15 "On-Chip Variation (OCV) Modeling." https://media.c3d2.de/mgoblin_media/media_entries/659/Liberty_User_Guides_and_Reference_Manual_Suite_Version_2017.06.pdf
92. Liberty Reference Manual 2020.09 mirror (liberty-db). https://zao111222333.github.io/liberty-db/2020.09/reference_manual.html ; test library ocv_sigma.lib. https://github.com/zao111222333/liberty-db/blob/c1e36c1298892355843871076140fbcad4083c69/dev/tech/cases/ocv_sigma.lib
93. Liberty grammar (liberty_parse 2.6, `va_*`). https://github.com/geochrist/dctk/blob/ebc3f0f3fa2c523b4797d87427dbd1a891fd3b8b/src-liberty_parse-2.6/desc/syntax.cmos.desc
94. N5급 TT 0.355 V LVF library 예. https://github.com/harryliu-intel/async-toolkit/blob/2f5e6bf3e6d12b23cbe2de55ad06ee3a1cabfdad/async-toolkit/m3utils/m3utils/liberty/src/N5_TYPE1_LVL.lib
95. IHP SG13G2 model file (cornerMOSlv.lib, sg13g2_moslv_stat.lib, sg13g2_moslv_mismatch.lib). https://raw.githubusercontent.com/IHP-GmbH/IHP-Open-PDK/main/ihp-sg13g2/libs.tech/ngspice/models/cornerMOSlv.lib
96. SkyWater sky130 model file. https://raw.githubusercontent.com/google/skywater-pdk-libs-sky130_fd_pr/main/models/sky130.lib.spice
97. StochasticCells char22nm-preprocess (moment table 생성). https://github.com/StochasticCells/char22nm-preprocess/blob/50d98d06c49c82c5525378a6d82bb8dec6c039aa/src/arcs.rs

### C. Tool 문서·script

98. Synopsys PrimeTime User Guide(Ch. 13 Variation), PrimeTime Suite Variables and Attributes(W-2024.09-SP3), Tool Commands(U-2022.12-SP5) — 공개 mirror. https://github.com/assrs/eda
99. Cadence Innovus Text Command Reference / Stylus CUI Reference(21.10–25.10) — 공개 mirror. https://github.com/assrs/eda ; Innovus 25.10 man page dump. https://github.com/echo-edai/innovus-tcl-helper
100. Synopsys reference methodology TCL_POCV_SETUP_FILE.tcl (FC-RM X-2025.06-SP2). https://github.com/velika1023-debug/FC-RM_X-2025.06-SP2/blob/main/FC-RM_X-2025.06-SP2/examples/TCL_POCV_SETUP_FILE.tcl
101. OpenSTA doc/Examples.md, LibertyReader.cc. https://github.com/The-OpenROAD-Project/OpenSTA/blob/d1e43c6f9f4e66cb59c3d7958a4aa7d1626b4614/doc/Examples.md
102. 공개 flow script/log: PSU_RTL2GDS pt_min_pocv.tcl. https://github.com/ECE510-2020-SPRING/PSU_RTL2GDS ; 32xlr8/gflow. https://github.com/32xlr8/gflow ; elizaOS/research corner manifest. https://github.com/elizaOS/research
103. Cadence Tempus datasheet. https://www.cadence.com/en_US/home/resources/datasheets/tempus-timing-signoff-solution-ds.html ; Synopsys PrimeTime datasheet. https://www.synopsys.com/content/dam/synopsys/implementation&signoff/datasheets/primetime-ds.pdf

### D. 특허

104. TSMC, US 8,275,584 B2, "Unified model for process variations in integrated circuits." https://patentimages.storage.googleapis.com/pdfs/US8275584.pdf
105. Samsung Electronics, US 9,977,845 B2, "Method of performing static timing analysis for an integrated circuit." https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/9977845 ; US 10,192,015 B2. https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/10192015 ; KR 2016-0147435 A. https://patents.google.com/patent/KR20160147435A/ko
106. IBM, US 7,428,716; 8,010,921; 7,111,260; 7,512,919; 7,086,023; 7,117,466. https://patentimages.storage.googleapis.com/pdfs/US7428716.pdf ; https://patentimages.storage.googleapis.com/pdfs/US7117466.pdf
107. IBM, US 7,555,740; 2008/0209372; 7,886,246. https://patentimages.storage.googleapis.com/pdfs/US7555740.pdf ; https://patentimages.storage.googleapis.com/pdfs/US20080209372.pdf ; https://patentimages.storage.googleapis.com/pdfs/US7886246.pdf
108. IBM, US 8,141,012; 2012/0117527; 2012/0047477; 8,413,095; 8,732,642; 8,806,402; 8,949,765; 7,945,887; 7,293,248; 8,359,563. https://patentimages.storage.googleapis.com/pdfs/US8141012.pdf ; https://patentimages.storage.googleapis.com/pdfs/US20120117527.pdf ; https://patentimages.storage.googleapis.com/pdfs/US8413095.pdf ; https://patentimages.storage.googleapis.com/pdfs/US8949765.pdf ; https://patentimages.storage.googleapis.com/pdfs/US7945887.pdf
109. IBM, US 9,501,609; 10,013,516; 10,606,970; 10,055,532; 8,458,632; 9,400,864. https://patents.google.com/patent/US9501609 ; https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/10606970 ; https://patents.google.com/patent/US8458632
110. Synopsys (Extreme DA 팀), US 8,407,640; 2012/0072880; 8,555,222; 8,843,864. https://patentimages.storage.googleapis.com/pdfs/US8407640.pdf ; https://patentimages.storage.googleapis.com/pdfs/US8555222.pdf ; https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/8843864
111. Magma → Synopsys, US 7,992,114; 8,307,317; 7,458,049. https://patentimages.storage.googleapis.com/pdfs/US7992114.pdf ; https://patentimages.storage.googleapis.com/pdfs/US8307317.pdf
112. Synopsys, US 7,237,212; 8,204,730; 8,000,826; 8,615,727; 9,183,333; 10,755,023; 10,255,395/10,783,301/11,288,426; 12,112,108; 11,893,332; 12,430,486. https://patentimages.storage.googleapis.com/pdfs/US7237212.pdf ; https://patentimages.storage.googleapis.com/pdfs/US8000826.pdf ; https://patents.google.com/patent/US9183333B2/en ; https://patents.justia.com/patent/11288426 ; https://patents.google.com/patent/US11893332B2/en ; https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/12430486
113. Extreme DA 창업진, US 7,487,486; 2009/0288050. https://patentimages.storage.googleapis.com/pdfs/US7487486.pdf
114. Cadence, US 7,487,475; 8,448,104; 8,645,881; 7,882,471; 7,493,574; 8,239,798; 8,180,621; 8,813,006; 8,245,165; 8,782,583; 8,762,908; 8,336,010; 8,745,561; 7,474,999. https://patentimages.storage.googleapis.com/pdfs/US7487475.pdf ; https://patentimages.storage.googleapis.com/pdfs/US8762908.pdf ; https://patentimages.storage.googleapis.com/pdfs/US8813006.pdf
115. Cadence, US 9,805,158; 9,836,564; 10,073,934; 10,185,795; 10,275,554(assignee 미확인); 10,789,406. https://www.freepatentsonline.com/9805158.html ; https://patents.justia.com/patent/10073934 ; https://patents.google.com/patent/US10789406
116. Mentor, US 2009/0327989. https://patentimages.storage.googleapis.com/pdfs/US20090327989.pdf ; Solido, US 8,494,670. https://patentimages.storage.googleapis.com/pdfs/US8494670.pdf ; CLK DA, US 7,594,210; 2013/0227510. https://patentimages.storage.googleapis.com/pdfs/US7594210.pdf
117. WARF, US 7,350,171; Michigan, US 7,689,954; CMU, US 8,290,761; Sun/Oracle, US 7,716,023; 8,271,256; Oracle, US 10,235,484; 9,633,150. https://patentimages.storage.googleapis.com/pdfs/US7350171.pdf ; https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/7689954 ; https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/8271256 ; https://patents.google.com/patent/US10235484B2/en
118. TSMC, US 7,802,209; 8,365,115; 2010/0229137; 8,117,575; 2011/0035715; 8,707,230; 8,972,919. https://patentimages.storage.googleapis.com/pdfs/US8365115.pdf ; https://patentimages.storage.googleapis.com/pdfs/US8117575.pdf ; https://patentimages.storage.googleapis.com/pdfs/US8707230.pdf ; https://patentimages.storage.googleapis.com/pdfs/US8972919.pdf
119. Altera (Intel), US 7,290,232; 7,926,019; 7,594,208. https://patentimages.storage.googleapis.com/pdfs/US7290232.pdf ; https://patentimages.storage.googleapis.com/pdfs/US7926019.pdf
120. Texas Instruments, US 2005/0273308; 8,302,047 / 2010/0287517; 8,806,413 / 2014/0082576. https://patentimages.storage.googleapis.com/pdfs/US8302047.pdf ; https://patentimages.storage.googleapis.com/pdfs/US8806413.pdf
121. Freescale, US 8,656,331. https://patentimages.storage.googleapis.com/pdfs/US8656331.pdf ; Philips, US 7,010,475. https://patentimages.storage.googleapis.com/pdfs/US7010475.pdf
122. Agere/LSI/Broadcom, US 6,356,861; 7,399,648; 7,480,881; 2009/0217226; 7,181,713; 6,880,142; 7,069,178; 2013/0152034; 2013/0080986; 8,645,888; 2014/0089881. https://patentimages.storage.googleapis.com/pdfs/US6356861.pdf ; https://patentimages.storage.googleapis.com/pdfs/US7399648.pdf ; https://patentimages.storage.googleapis.com/pdfs/US8645888.pdf
123. Qualcomm, US 2008/0141190. https://patentimages.storage.googleapis.com/pdfs/US20080141190.pdf
124. ARM, US 9,690,889; 2015/0370955; 2016/0357894; 9,892,220; 11,624,777. https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/9690889 ; https://www.freepatentsonline.com/y2016/0357894.html
125. Ampere Computing, US 10,318,676; 10,318,696. https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/10318676 ; https://patents.google.com/patent/US10318696B1
126. NEC / NEC Electronics / Renesas, US 6,526,541; 7,526,399; 2009/0019408; 2009/0024974; 7,512,920. https://patentimages.storage.googleapis.com/pdfs/US6526541.pdf ; https://patentimages.storage.googleapis.com/pdfs/US7526399.pdf ; https://patentimages.storage.googleapis.com/pdfs/US20090019408.pdf ; https://patentimages.storage.googleapis.com/pdfs/US7512920.pdf
127. Toshiba, US 2009/0249272; 8,196,077. https://patentimages.storage.googleapis.com/pdfs/US20090249272.pdf ; https://patentimages.storage.googleapis.com/pdfs/US8196077.pdf
128. Fujitsu, US 2004/0254776; 2008/0178134; 2008/0010558; 2007/0074138; 6,389,381. https://patentimages.storage.googleapis.com/pdfs/US20040254776.pdf ; https://patentimages.storage.googleapis.com/pdfs/US20080178134.pdf
129. Matsushita, US 7,239,997; 2004/0261044; 6,684,375; 2006/0107244; 6,507,936. https://patentimages.storage.googleapis.com/pdfs/US7239997.pdf ; https://patentimages.storage.googleapis.com/pdfs/US20040261044.pdf
130. 기타, US 8,352,895 (SRAM corner). https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/8352895 ; US 10,162,916; 10,311,196. https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/10311196 ; CN 104101827 / WO 2015/196772 / US 10,422,830. https://patents.google.com/patent/WO2015196772A1/en
