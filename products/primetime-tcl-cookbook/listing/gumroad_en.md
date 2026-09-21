# Gumroad / Leanpub listing (English)

## Product name
PrimeTime Tcl Cookbook: 41 Production Scripts for STA Signoff, ECO and Reporting

## Price
USD 39 (launch price USD 29 for the first 30 days). Set "pay what you want" minimum to 29.

## Short description (under 200 characters)
41 ready-to-run pt_shell scripts with a 56-page guide: path tables, clock-pair matrix, SDC audit, violator bucketing, ECO sizing loops, JSON export, DMSA.

## Full description

You know PrimeTime. What costs you time is turning "I need the worst path per clock pair across every block, as a CSV" into a script that runs in seconds and does not break on INFINITY slack.

This package is that script, and forty others, written the way a signoff flow is organised.

**What you get**

- 56-page PDF guide, 11 chapters, with every script explained: what it depends on, where it breaks, how to adapt it
- 41 standalone `.tcl` files with headers and usage lines, sourced directly into pt_shell
- CSV and JSON writers in pure Tcl, no packages to install
- Two scripts that run under plain `tclsh` for CI: run-to-run diff and multi-corner merge

**Chapters**

1. Tcl foundations for PrimeTime: collections, INFINITY-safe attribute access, batch error handling
2. Session setup: reproducible bring-up from one config block, environment snapshot, check_timing gate, SDC warning pairing
3. Querying the design: filtered queries, cone tracing, attribute discovery
4. Timing path analysis: one-line-per-path tables, slack histogram, clock-pair matrix, reg2reg/in2reg classification, stage delay breakdown
5. Clock analysis: inventory, latency statistics and skew per clock, generated clock sanity checks
6. Constraint audit: unconstrained endpoints rolled up by block, ignored exceptions, multicycle hold check, I/O coverage, case analysis review
7. Violation triage: bucket by block and clock pair with WNS/TNS, cells common to failing paths, DRV table
8. ECO scripting: candidate ranking, try-and-keep upsizing loop, hold buffering with setup guard, export to ICC2 and Innovus, fix_eco wrappers
9. Reporting: signoff summary JSON per run, run-to-run diff, report_timing bundles
10. Multi-corner/multi-mode: DMSA bring-up from a corner table, per-scenario collection, CSV merge for independent runs
11. Performance: measuring runtime and memory, slow-vs-fast query patterns, structured logging

Appendices: command and attribute quick reference, Tempus equivalents, script dependency list.

**Who it is for**

STA engineers, physical design engineers who own timing closure, and CAD/methodology engineers building signoff flows. Assumes you already run PrimeTime; this is not an introduction to static timing analysis.

**Requirements**

PrimeTime (any recent release). Chapter 8 needs the ECO capability; Chapter 10 needs DMSA for two of the three scripts. Attribute names that differ between releases are called out with the command to check them.

**License**

Single-organisation use. Use and modify the scripts freely inside your company. Do not redistribute the PDF.

## Tags
primetime, tcl, static timing analysis, sta, eco, signoff, synopsys, vlsi, physical design, eda

## Cover image
`dist/cover.png` (1600 x 2000)

## Product file
`dist/primetime-tcl-cookbook-v1.0.zip`

## FAQ (paste into listing)

**Does this work with Tempus?**
The scripts target PrimeTime. Appendix B maps every command and attribute used to its Tempus equivalent; the logic of each proc carries over unchanged.

**Do I need the ECO license?**
Only for Chapter 8 (5 of the 41 scripts). Everything else runs on a base PrimeTime license.

**An attribute name does not exist in my release.**
Run `list_attributes -application -class <class>` as described in the introduction, or use `dump_attrs` from Chapter 3. Reply to your receipt with the script name and pt_shell version and I will send the corrected line.
