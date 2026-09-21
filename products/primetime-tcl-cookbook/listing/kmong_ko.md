# 크몽 / 탈잉 / 클래스101 전자책 등록용 (한국어)

## 상품명
PrimeTime Tcl 스크립트 41종 + 활용 가이드 (STA 사인오프, ECO, 리포트 자동화)

## 가격
49,000원 (런칭 30일간 39,000원)

## 한 줄 소개
pt_shell에서 바로 source 해서 쓰는 Tcl 스크립트 41개와 56페이지 영문 가이드. 클럭 페어 매트릭스, SDC 감사, 위반 버킷팅, ECO 사이징 루프, JSON 리포트, DMSA 셋업까지.

## 상세 설명

PrimeTime을 매일 쓰는 엔지니어가 시간을 잃는 지점은 timing 이해가 아니라 "블록별 클럭 페어별 worst path를 CSV로" 같은 요구를 스크립트로 옮기는 과정입니다. INFINITY slack에서 expr가 터지고, collection을 list처럼 다루다 foreach가 한 번만 돌고, 9시간 배치가 마지막 스크립트 오타로 중단됩니다.

이 패키지는 그 스크립트를 미리 써 둔 것입니다. 사인오프 플로우 순서대로 정리했습니다.

**구성**

- 영문 PDF 가이드 56페이지, 11개 챕터. 스크립트마다 의존하는 PrimeTime 동작, 깨지는 조건, 수정 포인트를 설명
- 독립 실행 가능한 .tcl 파일 41개 (헤더, usage 포함). pt_shell에서 source 후 proc 호출
- 순수 Tcl로 작성한 CSV/JSON writer (패키지 설치 불필요)
- tclsh 단독 실행 스크립트 2종 (run 간 diff, 코너별 CSV 병합) — 라이선스 없이 CI에서 실행

**챕터**

1. PrimeTime용 Tcl 기초: collection 처리, INFINITY-safe attribute 접근, 배치 에러 처리
2. 세션 셋업: config 블록 하나로 재현 가능한 bring-up, 환경 스냅샷, check_timing 게이트, SDC warning 매핑
3. 디자인 쿼리: -filter 활용, fanin/fanout cone, attribute 탐색
4. 타이밍 패스 분석: path table, slack 히스토그램, 클럭 페어 매트릭스, reg2reg/in2reg 분류, stage delay 분해
5. 클럭 분석: 인벤토리, 클럭별 latency 통계와 skew, generated clock 검증
6. 제약 감사: 블록별 unconstrained endpoint, ignored exception, multicycle hold 체크, I/O 커버리지, case analysis 검토
7. 위반 분류: 블록/클럭 페어별 WNS/TNS 버킷, 실패 패스 공통 셀, DRV 테이블
8. ECO: 후보 셀 랭킹, try-and-keep 업사이징 루프, setup 여유 확인 후 hold 버퍼 삽입, ICC2/Innovus export, fix_eco 래퍼
9. 리포트: run별 사인오프 JSON, run 간 diff, report_timing 옵션 번들
10. 멀티 코너/모드: 코너 테이블 기반 DMSA 셋업, 시나리오별 수집, 독립 run CSV 병합
11. 성능: 런타임/메모리 측정, 느린 패턴과 빠른 패턴 비교, 로깅

부록: command/attribute 레퍼런스, Tempus 대응표, 스크립트 의존성 목록

**대상**

STA 엔지니어, 타이밍 클로저를 담당하는 PD 엔지니어, 사인오프 플로우를 만드는 CAD/방법론 엔지니어. PrimeTime 기본 사용은 알고 있다고 가정합니다. STA 입문서가 아닙니다.

**요구 사항**

PrimeTime (최근 릴리스). 8장은 ECO 기능, 10장 중 2개 스크립트는 DMSA 필요. 릴리스별로 다른 attribute 이름은 확인 명령과 함께 표기했습니다.

**라이선스**

구매 조직 내 사용. 스크립트 수정과 사내 사용 자유. PDF 재배포 금지.

## 카테고리
IT·프로그래밍 > 전자책 / 하드웨어·임베디드

## 검색 키워드
PrimeTime, Tcl, STA, static timing analysis, 사인오프, ECO, Synopsys, 반도체 설계, physical design, EDA

## 자주 묻는 질문

**Tempus에서도 쓸 수 있나요?**
스크립트는 PrimeTime 기준입니다. 부록 B에 사용된 모든 command/attribute의 Tempus 대응표가 있고, proc 로직은 그대로 옮겨집니다.

**ECO 라이선스가 필요한가요?**
8장(41개 중 5개)만 필요합니다. 나머지는 기본 PrimeTime 라이선스로 동작합니다.

**우리 릴리스에 없는 attribute가 있습니다.**
서문에 있는 `list_attributes -application -class <class>` 또는 3장의 `dump_attrs`로 확인할 수 있습니다. 스크립트 이름과 pt_shell 버전을 문의 주시면 수정 라인을 보내드립니다.
