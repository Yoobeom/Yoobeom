# 선행기술 검토 자료

Author: yoobeom.kim@samsung.com
대상 발명: 라이브러리 특성화 데이터로부터 복원한 트랜지스터별 민감도를 이용한 셀 타이밍 변동 모델 (patent_draft_ko.md 개정 2판)

조사 조건: 이 자료는 웹 검색 결과의 초록·요약과 배경 지식으로 작성하였다. Google Patents, USPTO 원문 페이지는 작성 환경에서 접근이 차단되어 청구항 원문을 확인하지 못했다. 각 문헌의 "확인 포인트"를 원문에서 직접 확인해야 한다. 출원인·연도에 "(추정)"이 붙은 항목은 원문 확인이 필요하다.

링크 규칙: Google Patents는 `https://patents.google.com/patent/US<번호>`, USPTO 원문 PDF는 `https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/<번호>`. 한국 공개건은 KIPRIS(`https://www.kipris.or.kr`)에서 번호로 조회.

---

## 1. 본 발명의 구성요소 (대비 기준)

| 기호 | 구성요소 | 청구항 |
|---|---|---|
| E1 | LVF(국부 변동) 특성화의 트랜지스터별 섭동 민감도를 획득 | 1 |
| E2 | 민감도를 정규화한 트랜지스터별 기여도 Cᵢ (합 = 1, slew/load/arc 의존 표면) | 1, 2, 3 |
| E3 | 트랜지스터 식별 정보가 없는 집합(USM) 파라미터 민감도 Sₚ 획득 | 1, 6, 7 |
| E4 | Cᵢ × Sₚ 로 트랜지스터별 파라미터 민감도 복원 (재특성화 없음) | 1 |
| E5 | 트랜지스터별로 상이한 변동량 Δpᵢ (LLE, 경계 + 내부 TR, 열화) | 1, 10, 15 |
| E6 | 곱의 합으로 타이밍 변화량 → STA 인스턴스 보정 | 1, 11, 19 |
| E7 | 동시 변동 = 개별 합 정합성 검증, 교차항 판정 | 8, 9, 20 |
| E8 | 동일 민감도로 국부(RSS)·전역(부호 합) 동시 산출, 전역 라이브러리·디레이트 생성 | 12, 13, 14, 18 |

읽을 때 각 문헌이 E1~E8 중 무엇을 개시하는지 표시하는 것이 목적이다. 마지막 절의 대비표에 미리 채운 값은 요약 기반 추정이므로 원문으로 갱신해야 한다.

---

## 2. 읽는 순서

| 우선순위 | 문헌 | 이유 |
|---|---|---|
| A (필독) | 비특허 1 ICCAD 2023 | 출원인 공저. 경계 TR 민감도 라이브러리 + P&R의 Vth/이동도 변환 + STA 반영. 본 발명과 가장 가깝고 공지 예외 기간 경과 가능성 |
| A | US 9,355,207 | 인스턴스 기반 계통 변동(인접 셀에 의한 이동도·Vth 이동)을 STA에 반영. E5, E6과 겹칠 수 있음 |
| A | US 2012/0072880 A1 | 제목이 "민감도 기반 random OCV 통계 모델링". E1, E2와 겹칠 수 있음 |
| A | US 8,204,730 | 트랜지스터별 섭동 mismatch 특성화와 global/random 파라미터 구분. E1, E8과 겹칠 수 있음 |
| B (확인) | US 11,531,802 / 11,853,676 / 12,210,811 | 레이아웃 컨텍스트별 셀 타이밍 특성화. E5, E6의 대안 접근 |
| B | US 10,599,130 / 10,817,637 | LLE 고려 설계·제조. E5 |
| B | US 8,656,331 | 특성화 민감도 데이터에서 OCV 디레이트 산출. E8 |
| B | US 8,813,006 | within-die 변동 특성화 가속(섭동 대상 트랜지스터 축소). E1 |
| B | US 8,522,183 | 열화 계수 기반 STA 조정. E5(열화) |
| B | 비특허 2 TCAD 2022 | 민감도로 임계 트랜지스터를 골라 열화 특성화. E1, E5(열화) |
| C (참고) | US 9,594,858, US 8,103,990, US 7,882,471 / 8,631,369, US 8,307,317, US 7,684,969, US 10,318,696 | 통계 특성화·SSTA 일반 |
| C | US 8,621,409, US 7,584,438 / 8,347,252, US 8,037,433 | 레이아웃 종속 효과 추정·저감 |
| C | US 9,977,845, US 10,546,093 | 배선 변동 민감도(국부·전역 구분) |
| C | US 11,816,413 / 12,175,180, US 10,762,259 | 컨텍스트 인식 설계, 기생 민감도 |
| C | 비특허 3, 4, 5 | 트랜지스터별 SSTA 모델, 코너 간 변동 모델, 통계 특성화 논문 |

---

## 3. 문헌별 정리

### A-1. 비특허문헌 1 — Kim, Han, Bae, Kim(Yoobeom), Kim, Seo, "Local Layout Effect-Aware Static Timing Analysis by Use of a New Sensitivity-Based Library," ICCAD 2023

- 링크: Semantic Scholar `https://www.semanticscholar.org/paper/36f58d4602a782566d1f1ac4d896cdd3bdfb4d89`, ACM DL(ICCAD 2023 proceedings)
- 요약(검색 초록): 레이아웃 정보를 STA에 통합하여 타이밍 정확도를 높이고 마진 비관성을 줄이는 방법. 타이밍 라이브러리에 셀 경계 트랜지스터의 파라미터에 대한 지연 민감도 데이터를 추가하고, P&R 도구가 물리 파라미터를 측정하여 문턱 전압 및 이동도 변화로 변환한 뒤 STA 엔진에 전달한다. 최대 주파수 약 2.6 % 개선, 누설 6 % 감소.
- 개시 요소: E5(경계 TR의 LLE Δp), E6(STA 보정), 트랜지스터 파라미터 민감도 라이브러리(직접 특성화).
- 본 발명과의 차이: (1) 경계 트랜지스터 한정 → 본 발명은 내부 트랜지스터 포함, (2) 민감도를 직접 특성화 → 본 발명은 LVF 기여도 × 집합 민감도로 복원, 재특성화 없음, (3) 기여도와 파라미터 민감도의 분리 저장 구조 없음.
- 확인 포인트: 논문에 "모든 트랜지스터" 또는 "LVF 데이터 재사용"에 대한 언급이 있는지, 민감도 라이브러리의 형식(sensitivity 그룹인지), 향후 과제(future work)에 내부 TR 확장이 언급되었는지. 향후 과제에 언급되어 있으면 진보성 논리에서 "해결 수단은 개시되지 않음"을 강조해야 한다.
- 절차 확인: 공개일(2023년 10~11월)로부터 12개월이 지났으므로 한국·미국 모두 공지 예외 주장이 어렵다. 이 논문과 연계된 사내 출원(경계 TR 민감도 라이브러리) 유무를 IP 부서에서 확인하고, 있으면 본 건과의 관계(별개 발명, 개량)를 정리한다.

### A-2. US 9,355,207 B2 — "Performing static timing analysis in the presence of instance-based systematic variations"

- 출원인: 확인 필요. 공개 연도: 2016년경(추정)
- 링크: `https://patents.google.com/patent/US9355207B2`, `https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/9355207`
- 요약(검색 초록): 응력(strain)을 이용하는 공정에서 인접 셀 인스턴스 간 상호작용이 같은 셀의 다른 인스턴스에서 같은 트랜지스터의 캐리어 이동도를 크게 바꿀 수 있다. 상대 이동도 이동과 문턱 전압 이동을 레이아웃 분석 데이터의 함수로 두고 STA를 수행한다.
- 개시 요소(추정): E5(인스턴스별 Δp), E6(STA 보정). 민감도의 출처가 셀 레벨인지 트랜지스터 레벨인지가 관건.
- 본 발명과의 차이(추정): 인스턴스별 이동량을 타이밍으로 변환하는 민감도를 어떻게 얻는지가 다르다. 본 발명은 LVF 기여도 × 집합 민감도의 복원(E2, E3, E4)이 핵심이며, 이 문헌에 트랜지스터별 기여도의 정규화나 집합 민감도와의 결합이 없으면 차별된다.
- 확인 포인트: 독립항에서 (a) 민감도가 셀 단위인지 트랜지스터 단위인지, (b) 트랜지스터별 민감도를 어떻게 얻는지(직접 특성화, 라이브러리 속성), (c) 경계/내부 트랜지스터 구분, (d) 셀 인스턴스별 보정을 delay table에 적용하는 방식. 종속항에 "sensitivity table per transistor"가 있으면 E4의 차별 논리(재특성화 불필요, 복원)를 더 강조해야 한다.

### A-3. US 2012/0072880 A1 — "Sensitivity-based complex statistical modeling for random on-chip variation"

- 출원인: Altos Design Automation 또는 Cadence(추정). 공개: 2012년
- 링크: `https://patents.google.com/patent/US20120072880A1`
- 요약(제목 및 배경 지식 기반): 랜덤 OCV(국부 변동)를 트랜지스터별 파라미터 민감도로 모델링하는 특성화 방법. Liberate Variety의 sensitivity-based LVF 특성화의 기초 특허일 가능성.
- 개시 요소(추정): E1(트랜지스터별 섭동 민감도), 제곱합에 의한 국부 통계량(E8의 국부 부분).
- 본 발명과의 차이(추정): 민감도를 국부 통계량 산출에만 사용. 기여도 정규화(E2), 집합 민감도와의 결합(E3, E4), 트랜지스터별 상이 변동량(E5), 전역 부호 합(E8 전역)은 없을 것으로 예상.
- 확인 포인트: 명세서에 "global variation"에 대한 민감도 합산이나 "contribution"이라는 표현이 있는지, 비선형(complex) 모델링이 2차 항을 포함하는지(청구항 14의 2차·로그 모델과 관계), 등록 여부(등록 번호)와 패밀리.

### A-4. US 8,204,730 B2 — "Generating variation-aware library data with efficient device mismatch characterization"

- 출원인: Synopsys(추정). 등록: 2012년
- 링크: `https://patents.google.com/patent/US8204730B2`, `https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/8204730`
- 요약(검색 초록): 전역 변동 파라미터는 칩의 모든 트랜지스터에 유사하게 작용하고, 랜덤 변동 파라미터는 트랜지스터마다 다르게 작용한다. 민감도를 얻기 위해 R개 트랜지스터 × n개 랜덤 변수에 대해 N = R × n회의 HSPICE 실행을 수행하고, 각 실행은 하나의 파라미터만 비공칭으로 두며, 공칭 실행과 비교하여 민감도를 계산한다.
- 개시 요소: E1(트랜지스터별 섭동), 전역/랜덤 파라미터 구분. 전역 민감도는 전역 파라미터를 직접 섭동하여 얻는 것으로 보임.
- 본 발명과의 차이: 전역 민감도를 트랜지스터별 민감도의 합으로 얻지 않고 직접 섭동한다(E8 전역의 차별). 기여도 정규화, 집합 민감도와의 결합, 트랜지스터별 상이 변동량이 없다.
- 확인 포인트: 전역 파라미터 민감도의 산출 방식(직접 섭동인지 합산인지), "mismatch sensitivity를 다른 용도로 재사용"하는 기재가 있는지, 라이브러리 형식(sensitivity 그룹 포함 여부). 이 문헌의 sensitivity 라이브러리가 본 발명의 "집합 민감도 라이브러리(USM)"에 해당한다면 E3의 출처로 배경기술에 인용하는 것이 안전하다.

### B-1. US 11,531,802 B2 / US 11,853,676 B2 / US 12,210,811 B2 — "Layout context-based cell timing characterization"

- 출원인: TSMC(추정). 등록: 2022 / 2023 / 2025
- 링크: `https://patents.google.com/patent/US11531802B2`, `.../US11853676B2`, `.../US12210811B2`
- 요약(검색 초록): 셀 주변 회로 토폴로지(컨텍스트)에 따라 핀 지연이 달라지는 레이아웃 종속 효과를 다룬다. 학습(training) 단계와 인식(recognition) 단계로 구성된 셀 타이밍 특성화. 기존에는 가장 빠른/느린 조건의 타이밍 테이블이 위치와 무관하게 모든 인스턴스에 동일하게 적용되어 과도하게 보수적이거나 공격적이었다.
- 개시 요소(추정): 컨텍스트별 타이밍 데이터 생성, 인스턴스별 적용(E6와 유사한 목적).
- 본 발명과의 차이: 컨텍스트별로 타이밍을 학습·인식하는 데이터 기반 접근. 트랜지스터별 파라미터 이동량과 민감도의 곱(E4, E5, E6)이 아니며, LVF·집합 민감도 재사용(E1~E4)이 없다.
- 확인 포인트: 학습 단계의 입력이 트랜지스터 파라미터 이동량인지 레이아웃 형상인지, 출력이 delay table인지 보정 계수인지. 세 건의 청구항 차이(계속 출원의 확장 범위).

### B-2. US 10,599,130 B2 — "Method and system for manufacturing an integrated circuit in consideration of a local layout effect", US 10,817,637 B2 — "System and method of designing integrated circuit by considering local layout effect"

- 출원인: Samsung Electronics(추정). 등록: 2020
- 링크: `https://patents.google.com/patent/US10599130B2`, `https://patents.google.com/patent/US10817637B2`, USPTO PDF `.../downloadPdf/10599130`, `.../downloadPdf/10817637`
- 요약: 국부 레이아웃 효과를 고려한 설계·제조 흐름. 인스턴스별 LLE 파라미터 추출과 타이밍·넷리스트 조정이 포함될 가능성.
- 개시 요소(추정): E5(인스턴스별 LLE 파라미터).
- 본 발명과의 차이: LLE 파라미터를 타이밍으로 변환할 트랜지스터별 민감도의 복원(E2~E4)이 없을 것으로 예상.
- 확인 포인트: 사내 선행 출원이므로 발명자와 청구항을 확인하고, 본 건이 이 출원의 개량으로 위치 지어지는지 검토. 두 건에 "sensitivity", "transistor-level" 표현이 있는지.

### B-3. US 8,656,331 B1 — "Timing margins for on-chip variations from sensitivity data"

- 출원인: Cadence(추정). 등록: 2014
- 링크: `https://patents.google.com/patent/US8656331B1`, `.../downloadPdf/8656331`
- 요약(검색 초록): 표준 셀 특성화(트랜지스터 레벨 시뮬레이션)에서 수집한 민감도 데이터로부터 OCV 디레이트 계수를 도출한다.
- 개시 요소: E8 중 디레이트 생성(청구항 13과 유사한 목적).
- 본 발명과의 차이: 디레이트의 원천이 국부 변동 민감도이며, 트랜지스터별 기여도와 집합 민감도의 결합, 전역 변동점별 상대 변화율 보간(청구항 12)이 없다. 청구항 13(셀별 디레이트)은 독립항 1의 종속항이므로 단독으로는 문제되지 않으나, 배경기술에 인용해 두는 것이 좋다.
- 확인 포인트: 디레이트가 셀별인지 일률적인지, 전역 변동을 다루는지.

### B-4. US 8,813,006 B1 — "Accelerated characterization of circuits for within-die process variations"

- 출원인: Cadence(추정). 등록: 2014
- 링크: `https://patents.google.com/patent/US8813006B1`, `.../downloadPdf/8813006`
- 요약(검색 초록): within-die 변동에 대해 입력 천이 민감도 분석과 출력 부하 민감도 분석을 수행하고, 입력/출력 트랜지스터를 하나 이상의 공정 변동에 대해 복수의 slew 및 load에서 섭동한다.
- 개시 요소: E1(섭동 대상 트랜지스터 선택으로 가속). "logic cone sensitivity"의 기초일 가능성.
- 본 발명과의 차이: 국부 변동 특성화의 가속 기법. 기여도 재사용·집합 민감도 결합 없음.
- 확인 포인트: 섭동 대상을 줄이는 기준(스위칭 경로)이 본 발명의 "내부 트랜지스터 포함"과 반대 방향이므로, 이 문헌이 내부 트랜지스터를 특성화 대상에서 제외하는 근거로 인용될 수 있다.

### B-5. US 8,522,183 B2 — "Static timing analysis adjustments for aging effects"

- 출원인: 확인 필요. 등록: 2013
- 링크: `https://patents.google.com/patent/US8522183B2`, `.../downloadPdf/8522183`
- 요약(검색 초록): 표준 셀 라이브러리의 아크·상태 조합마다 트랜지스터 레벨 모델의 시뮬레이션으로 열화 계수 데이터를 생성하고 STA를 조정한다.
- 개시 요소: E5(열화)와 E6의 결합이나, 열화 계수를 직접 시뮬레이션으로 산출.
- 본 발명과의 차이: 청구항 15(열화)는 트랜지스터별 변동량을 복원된 민감도에 곱하는 방식이며, 열화 계수를 아크별로 직접 시뮬레이션하지 않는다.
- 확인 포인트: 열화 계수가 트랜지스터별 열화량의 함수인지, 셀 단위 스칼라인지.

### B-6. 비특허문헌 2 — "Efficient Aging-Aware Standard Cell Library Characterization Based on Sensitivity Analysis," IEEE TCAD, 2022

- 링크: `https://ieeexplore.ieee.org/document/9911681`
- 요약(검색 초록): 민감도 분석으로 임계 트랜지스터(critical transistors)를 추출하여 SPICE 시뮬레이션 수를 크게 줄이는 열화 인식 특성화.
- 개시 요소: E1(트랜지스터별 민감도), E5(열화)와의 연결. 임계 트랜지스터만 특성화.
- 본 발명과의 차이: 민감도로 특성화 대상을 선별하여 재특성화를 줄이는 접근. 본 발명은 재특성화 자체를 없애고 복원된 민감도에 트랜지스터별 열화량을 곱한다.
- 확인 포인트: 민감도가 트랜지스터별 Vth 변화에 대한 지연 민감도인지, 열화 시 지연을 민감도 × ΔVth로 추정하는 식이 논문에 있는지(있다면 E4의 "곱" 자체는 공지이므로 E2·E3의 결합 구조를 강조).

### C-1. US 9,594,858 B1 — "Methods, systems, and articles of manufacture for implementing scalable statistical library characterization for electronic designs"

- 출원인: Cadence(추정). 등록: 2017. 링크: `https://patents.google.com/patent/US9594858B1`
- 요약: 통계 특성화의 확장성(시뮬레이션 수 감소, 분산 처리). 확인 포인트: 민감도 재사용 언급 여부.

### C-2. US 8,103,990 B2 — "Characterising circuit cell performance variability in response to perturbations in manufacturing process parameters"

- 출원인: ARM(추정). 등록: 2012. 링크: `https://patents.google.com/patent/US8103990B2`
- 요약: 공정 파라미터 섭동에 대한 셀 성능 변동 특성화. 확인 포인트: 섭동이 셀 단위(전역)인지 트랜지스터 단위인지, 결합 규칙(RSS/합).

### C-3. US 7,882,471 B1 / US 8,631,369 B1 — "Timing and signal integrity analysis of integrated circuits with semiconductor process variations"

- 출원인: Cadence(추정). 등록: 2011 / 2014. 링크: `https://patents.google.com/patent/US7882471B1`, `.../US8631369B1`
- 요약(검색 초록): 공칭 지연과 함께 회로 요소 및 변동 파라미터(공정, 환경)에 대한 지연 민감도를 제공하는 민감도 기반 통계 지연 계산. 셀 타입별로 각 공정 파라미터에 대한 지연·천이 민감도를 모델링.
- 확인 포인트: 파라미터 민감도가 셀 단위(전역 파라미터)인지. SSTA canonical 모델의 전형이므로 E8 전역 부분과 대비.

### C-4. US 8,307,317 B2 — "Statistical on-chip variation timing analysis" (Cadence, 2012), US 7,684,969 — "Forming statistical model of independently variable parameters for timing analysis" (IBM 추정), US 10,318,696 B1 — "Efficient techniques for process variation reduction for static timing analysis" (2019)

- 링크: `https://patents.google.com/patent/US8307317B2`, `.../US7684969B2`, `.../US10318696B1`
- 요약: SOCV 분석, 독립 변수 통계 모델, 변동 비관성 감소 기법. STA 단계의 통계 처리이며 라이브러리 특성화 데이터의 재사용과는 거리가 있다. 확인 포인트: 셀별 디레이트·민감도 사용 방식.

### C-5. US 8,621,409 B2 — "System and method for reducing layout-dependent effects"

- 출원인: 확인 필요. 등록: 2013. 링크: `https://patents.google.com/patent/US8621409B2`
- 요약(검색 초록): 레이아웃에서 넷리스트를 추출하고 LDE 데이터를 추정, 넷리스트 기반 시뮬레이션과 회로도 기반 시뮬레이션을 비교하여 LDE의 가중치와 민감도를 계산해 레이아웃을 조정한다.
- 확인 포인트: "가중치와 민감도"의 정의가 트랜지스터별인지, 타이밍 라이브러리·STA에 적용되는지. 레이아웃 조정 목적이므로 본 발명과 용도가 다르다.

### C-6. US 7,584,438 B2 / US 8,347,252 B2 — "Method for rapid estimation of layout-dependent threshold voltage variation in a MOSFET array", US 8,037,433 B2 — "System and methodology for determining layout-dependent effects in ULSI simulation"

- 출원인: IBM(추정) / 확인 필요. 링크: `https://patents.google.com/patent/US7584438B2`, `.../US8347252B2`, `.../US8037433B2`
- 요약: 레이아웃 종속 Vth 변동의 신속 추정, 시뮬레이션에서 LDE 결정. E5의 입력(Δp 추출)에 해당하는 기술이며 타이밍 변환 부분은 없을 것으로 예상.

### C-7. US 9,977,845 B2 — "Method of performing static timing analysis for an integrated circuit", US 10,546,093 B2 — "...designing integrated circuit by considering process variations of wire"

- 출원인: Samsung Electronics(추정). 링크: `https://patents.google.com/patent/US9977845B2`, `.../US10546093B2`
- 요약(검색 초록): 배선 용량 민감도 계수(전역 변동, 모든 층·코너)와 랜덤 배선 지연 민감도 계수(국부 변동)를 구분하여 STA에 사용.
- 관련성: 전역/국부 변동을 민감도 계수로 구분해 다루는 사내 선행 사례. 소자가 아닌 배선 대상이므로 직접 충돌은 없으나, 청구항 표현(전역 변동 민감도, 국부 변동 민감도)의 용어를 맞추는 참고가 된다.

### C-8. US 11,816,413 B2 / US 12,175,180 B2 — "Systems and methods for context aware circuit design", US 10,762,259 B1 — "Circuit design/layout assistance based on sensitivities to parasitics"

- 링크: `https://patents.google.com/patent/US11816413B2`, `.../US12175180B2`, `.../US10762259B1`
- 요약: 컨텍스트 인식 설계, 기생 성분 민감도 기반 설계 보조. 참고 수준.

### C-9. KR 2018-0032505 A / US 10,103,172 B2 / US 11,271,011 B2 — "국소 레이아웃 효과(LLE)를 이용하는 FinFET 기반 라이브러리 내 고성능 표준 셀 설계 기술"

- 출원인: Samsung Electronics(추정). 링크: `https://patents.google.com/patent/KR20180032505A/ko`, `.../US10103172B2`, `.../US11271011B2`
- 요약: 확산 단절(DDB, SDB), 게이트 컷 등 LLE를 성능 향상에 이용하는 셀 레이아웃 설계. 타이밍 모델링 특허가 아니므로 참고.

### C-10. 비특허문헌 3, 4, 5

- "Transistor-Specific Delay Modeling for SSTA," 2008: 트랜지스터별 파라미터에 대한 지연 모델을 SSTA에 사용. E1과 관련. 원문에서 민감도의 산출과 합산 방식 확인.
- "Cross-Corner Delay Variation Model for Standard Cell Libraries," 2021: 코너 간 지연 변동 모델. E8 전역 라이브러리 생성과 관련. 코너 데이터 보간 방식인지 민감도 방식인지 확인.
- "Fast and accurate statistical characterization of standard cell libraries," Microelectronics Reliability, 2011: 통계 특성화 가속. E1과 관련.
- Cadence 백서 "Addressing Process Variation and Reducing Timing Pessimism at 16nm and Below": Liberate Variety의 sensitivity-based 특성화, logic cone sensitivity, 상관·비상관 파라미터에 대한 비선형 민감도. 특허는 아니나 공지 기술 범위 파악용.

---

## 4. 대비표 (요약 기반 추정, 원문으로 갱신할 것)

○ 개시, △ 유사·일부, × 미개시, ? 미확인

| 문헌 | E1 TR별 섭동 | E2 기여도 정규화 | E3 집합 민감도 | E4 곱에 의한 복원 | E5 TR별 상이 Δp (내부 TR) | E6 STA 인스턴스 보정 | E7 동시=개별합 검증 | E8 국부·전역 동시, 라이브러리 생성 |
|---|---|---|---|---|---|---|---|---|
| ICCAD 2023 | △ (경계 TR 직접 특성화) | × | × | × | △ (경계 TR만) | ○ | × | × |
| US 9,355,207 | ? | × | ? | × | ○ (인스턴스별) | ○ | × | × |
| US 2012/0072880 | ○ | ? | × | × | × | × | × | △ (국부) |
| US 8,204,730 | ○ | × | △ (전역 직접 섭동) | × | × | × | × | △ (전역 직접) |
| US 11,531,802 계열 | × | × | × | × | △ (컨텍스트) | ○ | × | × |
| US 10,599,130 / 10,817,637 | ? | × | × | × | ○ | ? | × | × |
| US 8,656,331 | ○ | × | × | × | × | × | × | △ (디레이트) |
| US 8,813,006 | ○ | × | × | × | × | × | × | × |
| US 8,522,183 | △ | × | × | × | △ (열화, 아크별) | ○ | × | × |
| TCAD 2022 | ○ | △ (임계 TR 선별) | × | × | △ (열화) | × | × | × |
| SSTA 계열 (US 7,882,471 등) | × | × | ○ (셀 단위) | × | × | ○ | × | △ |

현재 요약 기준으로 E2, E3와 E4의 결합(기여도 × 집합 민감도로 복원)과 E7(동시 변동 = 개별 합 검증)을 개시한 문헌은 없다. 이 두 요소가 독립항의 차별 축이다. E5(내부 TR 포함)는 ICCAD 2023과의 직접 차별점이다.

---

## 5. 추가 검색 권장 (전문 접근 가능 환경에서)

- Google Patents 검색식 예: `(sensitivity) (transistor) (contribution OR weight) (library) (LVF OR "variation format") (global OR corner)`, `("layout effect" OR LDE OR LLE) (sensitivity) (threshold voltage) (static timing)`, `(aggregate OR "all transistors") sensitivity "per transistor" reconstruct`
- CPC 분류: G06F30/3312 (타이밍 분석), G06F30/367 (회로 시뮬레이션), G06F2119/12 (타이밍), G06F2119/06 (전력) — 최근 5년 Cadence, Synopsys, Siemens, TSMC, Samsung 출원인 한정 검색
- 한국: KIPRIS에서 "민감도 라이브러리 국부 레이아웃 효과 타이밍", "트랜지스터별 민감도 표준 셀 변동" 검색. ICCAD 2023 공저자 이름으로 출원인 검색
- 학술: "sensitivity-based LVF", "transistor contribution LVF", "USM sensitivity library", "layout-dependent effect aware STA sensitivity" (ICCAD/DAC/DATE/ISPD 2022~2026)

---

## 6. 원문 확인 후 갱신할 항목

1. 4절 대비표의 ?와 추정치
2. 각 문헌의 출원인·등록일·패밀리
3. patent_draft_ko.md 【선행기술문헌】의 목록(A·B 문헌으로 압축), 【배경기술】 [0005]의 인용 문장
4. 청구항 1의 마지막 한정("국부 변동 통계량 산출용 특성화 과정에서 산출된")이 US 2012/0072880, US 8,204,730 대비 충분한 차별인지. 부족하면 청구항 2(부호 유지 정규화, 합 = 1)나 청구항 8(정합성 검증)을 독립항에 편입
5. US 9,355,207의 독립항이 트랜지스터별 민감도 테이블을 포함하면 독립항 1에 "재특성화 없이 복원" 문구를 명시적으로 넣는 방안 검토
