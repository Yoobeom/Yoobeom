# Promotion drafts

Replace GUMROAD_URL after the product is published. Post the LinkedIn one first; it carries the full free script so it stands on its own.

## LinkedIn (English)

One pt_shell query, every clock pair, worst slack.

Most first-pass "timing violations" on a new block are clock-pair problems: an async pair with no clock group, a generated clock with the wrong master. Before anyone opens a path report, this table shows which pairs are actually failing.

```tcl
proc clock_pair_matrix {{delay_type max} {max_paths 50000}} {
    set paths [get_timing_paths -delay_type $delay_type -nworst 1 \
                   -max_paths $max_paths -slack_lesser_than 1e9]
    array set worst {}; array set nviol {}; array set npath {}
    foreach_in_collection p $paths {
        set s [get_attribute $p slack]
        if {![string is double -strict $s]} { continue }
        set l [get_object_name [get_attribute -quiet $p startpoint_clock]]
        set c [get_object_name [get_attribute -quiet $p endpoint_clock]]
        set key "$l,$c"
        if {![info exists worst($key)] || $s < $worst($key)} { set worst($key) $s }
        if {![info exists npath($key)]} { set npath($key) 0; set nviol($key) 0 }
        incr npath($key)
        if {$s < 0} { incr nviol($key) }
    }
    foreach key [lsort [array names worst]] {
        lassign [split $key ","] l c
        puts [format "%-24s %-24s %9.3f %6d %6d" $l $c $worst($key) $nviol($key) $npath($key)]
    }
}
```

Two details that matter: `-nworst 1` so each endpoint counts once, and the `string is double -strict` guard because slack can be INFINITY.

This is one of 41 scripts in a cookbook I put together for STA signoff: session setup, SDC audit, violator bucketing by block, ECO sizing loop with keep/revert, hold buffering that checks setup first, JSON export, DMSA. 56 pages, every script standalone. GUMROAD_URL

#PrimeTime #STA #Tcl #VLSI #PhysicalDesign

## Reddit r/chipdesign (check self-promotion rules first; post as a text post)

Title: PrimeTime Tcl: 4 free scripts (clock-pair matrix, INFINITY-safe attributes, batch error handling)

Body:
I wrote up the scripts I kept rewriting at every company for PrimeTime signoff. Four are free here (GitHub link), no signup: a worst-slack-per-clock-pair table from one get_timing_paths query, attribute helpers that do not blow up on INFINITY, a safe_source wrapper for long batches, and the collection patterns everyone gets wrong once.

The rest (41 total, with a 56-page guide) covers SDC audit, violator bucketing, ECO sizing loops, hold fixing with a setup guard, JSON reports, and DMSA. Paid, link in the free README. Happy to answer questions about any of the scripts here.

## Korean community (반도체 설계 카페 / 사내 게시판, 규정 확인 후)

제목: PrimeTime Tcl 스크립트 4개 무료 공개 (클럭 페어 매트릭스, INFINITY-safe attribute, 배치 에러 처리)

본문:
사인오프할 때마다 다시 짜던 PrimeTime 스크립트를 정리했습니다. 4개는 무료로 공개합니다 (GitHub 링크): get_timing_paths 한 번으로 만드는 클럭 페어별 worst slack 테이블, INFINITY에서 안 터지는 attribute 헬퍼, 긴 배치용 safe_source, 그리고 collection 다룰 때 한 번씩 다 틀리는 패턴 정리.

전체 41개 + 56페이지 가이드(SDC 감사, 위반 버킷팅, ECO 사이징 루프, setup 확인 후 hold 버퍼 삽입, JSON 리포트, DMSA)는 유료이고 링크는 무료 README에 있습니다. 스크립트 관련 질문은 댓글로 주시면 답변드립니다.
