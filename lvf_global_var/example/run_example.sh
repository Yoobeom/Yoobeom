#!/bin/sh
# ---------------------------------------------------------------------------
# File   : run_example.sh
# Author : yoobeom.kim@samsung.com
# Purpose: End-to-end regression of the LVF global-variation flow with ngspice
#          and the example BSIM4 models.  Run from the example directory.
#            sh run_example.sh [jobs]
# ---------------------------------------------------------------------------
set -e
JOBS=${1:-4}
HERE=$(cd "$(dirname "$0")" && pwd)
S="$HERE/../scripts"
CFG="$HERE/config/example.cfg.tcl"
COR="$HERE/config/corners.tcl"
OUT="$HERE/out"
MODE=${MODE:-logquad}

echo "== 1. per-transistor sensitivity simulation (+ whole-group check)"
tclsh "$S/tr_sens_char.tcl" -cfg "$CFG" -mode sens -jobs "$JOBS"

echo "== 2. direct global-corner simulation (validation reference)"
tclsh "$S/tr_sens_char.tcl" -cfg "$CFG" -mode corner -corner "$COR" -jobs "$JOBS"

echo "== 3. global sensitivity model"
tclsh "$S/build_global_model.tcl" -cfg "$CFG" -sens "$OUT/sens.csv" -o "$OUT"

echo "== 4. prediction and validation per corner"
for C in NVT_p1s NVT_p3s NVT_m3s PVT_p3s PVT_m3s NU0_m3s PU0_m3s SSG FFG SFG FSG SS1; do
    tclsh "$S/predict_global_delay.tcl" -cfg "$CFG" -model "$OUT/global_model.csv" \
          -corner "$COR" -name "$C" -mode "$MODE" -o "$OUT"
    tclsh "$S/validate_global_model.tcl" -pred "$OUT/pred_$C.csv" -sim "$OUT/corner_$C.csv" -o "$OUT" > /dev/null
done
tclsh "$S/summarize_validation.tcl" -out "$OUT" -cfg "$CFG"

echo "== 5. Liberty: nominal (with LVF sigma) and shifted corner libraries"
tclsh "$S/write_nominal_lib.tcl" -cfg "$CFG" -nominal "$OUT/nominal.csv" -sigma "$OUT/local_sigma.csv" \
      -o "$HERE/lib/example_nominal.lib" -libname example_nom
for C in SSG FFG; do
    tclsh "$S/apply_to_liberty.tcl" -cfg "$CFG" -lib "$HERE/lib/example_nominal.lib" \
          -pred "$OUT/pred_$C.csv" -o "$HERE/lib/example_$C.lib" -suffix "_$C"
done

echo "== 6. contribution-only reconstruction check (tool-style input without sign)"
tclsh <<TCL
source "$S/lvfgv_common.tcl"
lassign [::lvfgv::csv_read "$OUT/contrib.csv"] h rows
lassign [::lvfgv::csv_read "$OUT/local_sigma.csv"] h2 srows
set sig [dict create]
foreach r \$srows { dict set sig "[dict get \$r cell],[dict get \$r arc],[dict get \$r meas],[dict get \$r slew_idx],[dict get \$r load_idx]" \$r }
set out {}
foreach r \$rows {
    set k "[dict get \$r cell],[dict get \$r arc],[dict get \$r meas],[dict get \$r slew_idx],[dict get \$r load_idx]"
    set s [dict get \$sig \$k]
    lappend out [list [dict get \$r cell] [dict get \$r arc] [dict get \$r meas] [dict get \$r slew_idx] [dict get \$r load_idx] \
        [dict get \$s slew] [dict get \$s load] [dict get \$s v0] [dict get \$s sigma_local] [dict get \$r inst] [dict get \$r group] \
        [dict get \$r param] [dict get \$r contrib_frac] [dict get \$r sigma_mm]]
}
::lvfgv::csv_write "$OUT/tool_contrib_example.csv" {cell arc meas slew_idx load_idx slew load v0 sigma_local inst group param contrib_frac sigma_mm} \$out
TCL
tclsh "$S/contrib_to_global.tcl" -cfg "$CFG" -contrib "$OUT/tool_contrib_example.csv" \
      -o "$OUT/global_model_from_contrib.csv"
tclsh "$S/summarize_validation.tcl" -out "$OUT" -cfg "$CFG" -contrib_check > "$OUT/validation_summary.txt"

echo "== 7. PrimeTime derate commands (dry run)"
tclsh <<TCL
source "$S/pt_apply_global_derate.tcl"
lvfgv_apply_global_derate -csv "$OUT/derate_SSG.csv" -stat bound -dry_run 1
TCL
echo "== done"
