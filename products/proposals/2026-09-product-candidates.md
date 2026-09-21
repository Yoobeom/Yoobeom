# 상품 후보 3종 (초안, 선택 대기)

PrimeTime Tcl Cookbook은 STA 사인오프 엔지니어만 대상이라 시장이 좁다. 아래 3개는 순서대로 대상 폭을 넓힌 것이다. 어느 것도 아직 제작하지 않았다.

| # | 후보 | 대상 폭 | 채널 | 가격 | 제작 규모 |
|---|------|---------|------|------|-----------|
| A | STA 면접 100문 100답 | 반도체 설계 취업/이직 준비자 전체 (국내 + 인도/미국) | Gumroad, 크몽 | USD 19 / 25,000원 | 100문항, 약 80페이지, 스크립트 없음 |
| B | EDA 엔지니어를 위한 Tcl 실전 (툴 공통) | DC/ICC2/Innovus/PT/Tempus 쓰는 모든 PD·STA·DFT 엔지니어 | Gumroad, 크몽 | USD 29 / 39,000원 | 12장 + 연습문제 40개, 약 90페이지 |
| C | AI 쇼츠 무인 제작 워크북 (Kaggle 무료 GPU) | 부업으로 유튜브 쇼츠 하려는 일반인 | 크몽, 클래스101, 탈잉 | 29,000원 | 8장 + 노트북 3개 + 프롬프트 템플릿, 약 70페이지 |

## A. STA 면접 100문 100답

**왜 팔리나.** "STA interview questions"는 VLSI 취업 검색어 중 가장 꾸준한 축에 든다. 무료 블로그 답변은 한두 줄이고 틀린 것도 많다. 현직 사인오프 엔지니어가 쓴 계산 포함 답안은 경쟁이 거의 없다. 신입, 경력 이직, 협력사 면접관까지 산다.

**구성.**
1. 기초 (setup/hold 식, slack, launch/capture, 클럭 정의) 20문
2. 클럭 (uncertainty, latency, skew, CRPR, generated clock, clock gating check) 15문
3. 예외 (false path, multicycle, max/min delay, case analysis) 15문
4. 물리 효과 (OCV/AOCV/POCV, derate, SI/crosstalk, IR drop 영향) 15문
5. 인터페이스 (I/O delay, source-synchronous, CDC 관점의 타이밍) 10문
6. ECO와 클로저 (hold fix, 사이징, useful skew, 리포트 읽기) 15문
7. 실전 계산 문제 (숫자 주고 slack 계산, 파형 그리기) 10문

문항마다: 질문, 30초 답, 상세 답, 면접관이 이어서 묻는 꼬리 질문. 계산 문제는 풀이 과정 포함.

**샘플.**
> Q. 클럭 uncertainty를 setup과 hold에 다르게 주는 이유는?
> 30초 답: setup은 jitter와 skew 여유를 모두 빼야 하고, hold는 같은 에지에서 비교하므로 jitter 항이 빠지기 때문. 보통 setup uncertainty > hold uncertainty.
> 상세: setup은 launch 에지 N과 capture 에지 N+1을 비교하므로 두 에지 사이의 주기 jitter가 들어간다. hold는 같은 에지 N을 비교해 jitter가 상쇄되고 skew 불확실성만 남는다. pre-CTS에서는 skew 추정치를 포함하므로 둘 다 크게 잡고, post-CTS에서 propagated clock으로 바꾸면서 skew 항을 제거한다.
> 꼬리 질문: post-CTS에서 uncertainty를 0으로 두면 안 되는 이유는?

**리스크.** 영문판은 인도 시장 경쟁자(무료 PDF)가 있음. 차별점은 계산 문제와 꼬리 질문. 한국어판은 경쟁 없음.

## B. EDA 엔지니어를 위한 Tcl 실전 (툴 공통)

**왜 팔리나.** Tcl은 모든 Synopsys/Cadence 툴의 공통 언어인데, 시중 자료는 일반 Tcl 문법서 아니면 툴 매뉴얼뿐이다. "collection과 list의 차이", "attribute 다루기", "플로우 스크립트 구조", "로그 파싱"처럼 EDA에서만 나오는 문제를 다루는 책이 없다. PrimeTime 쿡북보다 대상이 5배 이상 넓다(PD, 합성, STA, DFT, CAD).

**구성.**
1. EDA Tcl이 일반 Tcl과 다른 점 (collection, attribute, 툴 변수)
2. 문자열과 리스트, 정규식: 넷 이름과 계층 경로 다루기
3. 파일 I/O: 리포트 파싱, CSV 생성, 로그 요약
4. proc 설계: 옵션 파싱, 에러 처리, 재사용
5. 플로우 스크립트 구조: config 분리, 스테이지, 재시작
6. 툴별 명령 대응표: DC / ICC2 / Innovus / PT / Tempus / Genus
7. 디버깅: puts 대신 로그, 성능 측정, 흔한 오류 12개
8. 실전 1: 합성 QoR 리포트를 표로
9. 실전 2: P&R 리포트에서 DRC/timing 요약
10. 실전 3: 여러 run 결과 병합과 diff
11. 실전 4: 회귀 테스트 스크립트
12. 연습문제 40개와 해답

**샘플.**
```tcl
# 계층 경로에서 블록 이름만 뽑아 카운트 (모든 툴 공통 Tcl)
proc count_by_block {names depth} {
    array set n {}
    foreach nm $names {
        set key [join [lrange [split $nm "/"] 0 [expr {$depth-1}]] "/"]
        if {[info exists n($key)]} { incr n($key) } else { set n($key) 1 }
    }
    return [lsort -integer -decreasing -stride 2 -index 1 [array get n]]
}
```

**리스크.** PrimeTime 쿡북과 내용 일부 중복. 쿡북을 이 책의 "심화편"으로 묶어 팔면 오히려 시너지.

## C. AI 쇼츠 무인 제작 워크북 (Kaggle 무료 GPU)

**왜 팔리나.** 부업 쇼츠 시장은 반도체 시장과 비교가 안 되게 크다. 기존 강의는 유료 툴(ElevenLabs, Midjourney) 구독을 전제로 한다. 이 워크북은 이미 갖고 있는 파이프라인(Kaggle T4로 목소리 복제 TTS + SDXL/FLUX 이미지 + Google Flow 영상 프롬프트 + Notion 소재 관리)을 그대로 문서화한 것이라 "월 0원"이 차별점이다. 제작 재료가 이미 있다.

**구성.**
1. 전체 파이프라인과 비용 0원 구조
2. Notion으로 소재 관리 (제공 템플릿 복제)
3. 대본 구조: 문제-해결-역효과-진짜해답
4. Kaggle 셋업과 GPU 쿼터 관리
5. 내 목소리 복제 TTS (Qwen3-TTS, GPT-SoVITS) 노트북 제공
6. 씬 이미지 생성 (SDXL, FLUX.1-schnell) 노트북 제공
7. Google Flow 8초 클립 프롬프트 변환 규칙
8. 편집, 업로드, 수익화 조건, 첫 30일 운영표

부록: 대본 템플릿 10개, 프롬프트 템플릿, 체크리스트.

**샘플.**
> Kaggle 무료 GPU는 주 30시간이다. TTS 한 편(100초)은 T4에서 약 3분, SDXL 컷 12장은 약 4분이므로 한 편당 GPU 10분 이내다. 주 30시간이면 이론상 180편, 실제로는 세션 시작 오버헤드를 포함해 주 40~60편이 한계다. 하루 2편 업로드 기준으로 쿼터의 30%만 쓴다.

**리스크.** 이 시장은 경쟁자가 많고 유행이 빠르다. 대신 판매량 상한이 가장 높고, 크몽/클래스101 노출도 가장 잘 된다. 본인 채널 성과(구독자, 조회수)를 표지에 쓸 수 있어야 전환이 난다.

## 권장

수익 기대치만 보면 C > A > B. 본인 브랜드와 맞고 제작 확신도가 높은 순은 A > B > C. A는 재료 없이 바로 쓸 수 있고 한국어판 경쟁이 없어 첫 번째로 권한다. C는 채널 성과가 생긴 뒤 내면 전환율이 다르다.

선택하면 해당 후보만 전체 제작한다.
