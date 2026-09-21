# 런칭 체크리스트 (소유자 작업)

자동화로 준비된 것: 원고, 스크립트 41개, PDF, 표지 PNG, 판매용 ZIP, 영문/한글 상품 설명. 아래는 계정과 결제가 필요해서 소유자가 직접 해야 하는 항목입니다. 총 소요 시간 약 1시간.

## 1. 판매 채널 (우선순위 순)

| 순서 | 채널 | 이유 | 수수료 | 예상 가격 |
|------|------|------|--------|-----------|
| 1 | Gumroad (gumroad.com) | 해외 EDA 엔지니어 시장이 국내보다 10배 이상 큼. 계정 개설 10분, PayPal/은행 정산 | 10% + 결제수수료 | USD 29–39 |
| 2 | 크몽 전자책 | 국내 반도체 인력. 2025-03 법률상담 받아둔 채널 | 20% | 39,000–49,000원 |
| 3 | Leanpub | 기술서 전문. 업데이트 배포가 쉬움 | 20% | USD 29–39 |

Amazon KDP는 코드 위주 PDF에 부적합(리플로우 EPUB 요구, 스크립트 ZIP 동봉 불가)하므로 제외.

## 2. Gumroad 등록 순서

1. gumroad.com 가입, 정산 계정 연결 (PayPal 또는 한국 은행 계좌: Payoneer 경유)
2. New product > Digital product
3. 이름/가격/설명: `listing/gumroad_en.md` 내용 복사
4. 파일 업로드: `dist/primetime-tcl-cookbook-v1.0.zip`
5. 표지: `dist/cover.png`
6. Publish 후 URL 확보

## 3. 크몽 등록 순서

1. 전문가 등록(사업자 없이 개인도 가능) > 전자책 카테고리
2. `listing/kmong_ko.md` 내용 붙여넣기
3. 파일: 동일 ZIP
4. 심사 1–3일

## 4. 첫 판매를 만드는 유통 (비용 0원)

- LinkedIn 글 1개: 클럭 페어 매트릭스 스크립트 전문(04_worst_per_clock_pair.tcl) 공개 + "나머지 40개는 여기" 링크. 코드가 실제로 유용하면 공유가 일어남.
- Reddit r/chipdesign, r/FPGA (self-promo 규칙 확인 후 주 1회 이하)
- 국내: 반도체 설계 커뮤니티/카페, 회사 동료 (사내 규정 확인)
- GitHub: `scripts/01_*.tcl` 4개를 공개 저장소에 무료로 두고 README에서 전체 패키지 링크. 검색 유입용.

## 5. 회사 규정 확인 (판매 전 필수)

- 스크립트 헤더의 author 이메일은 개인 계정(youbumkim@gmail.com)으로 통일되어 있음. 회사 계정 언급 없음.
- 내용은 공개된 PrimeTime 명령어와 일반적인 Tcl 패턴만 사용. 회사 디자인/라이브러리/내부 플로우 정보 없음. 그래도 겸업/부업 관련 사내 규정은 확인 필요.

## 6. 판매 후

- 구매자 문의는 대부분 attribute 이름 차이. `dump_attrs`로 확인 후 한 줄 답변.
- 수정 사항은 `manuscript/`와 `scripts/`에 반영 후 `BOOK_VERSION=1.1 python3 build/build.py`로 재빌드, Gumroad에서 파일 교체(기존 구매자 자동 알림).

## 7. 다음 상품 후보 (같은 파이프라인 재사용)

1. Innovus/Genus Tcl Cookbook (같은 구조, P&R 쪽 수요가 더 큼)
2. 한국어판 (번역만 하면 됨, 크몽 전용)
3. SDC 작성 체크리스트 + 검증 스크립트 (얇고 저렴한 USD 15 상품, 첫 상품으로 유입)
