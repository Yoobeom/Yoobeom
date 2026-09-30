# LVF / derate derivation and timer variation models (how a TT library + LVF/global-sigma model can replace SS/FF corner signoff)

**Evidence labels used throughout.** `[PRIMARY-GH]` = read in full from a GitHub-hosted primary artifact (tool source code, real `.lib` files, vendor reference-methodology scripts, man-page dumps). `[MANUAL-MIRROR]` = Synopsys Liberty Reference Manual text as reproduced verbatim inside the open-source `liberty-db` crate (with page anchors into the 2020.09 manual). `[SNIPPET]` = fact taken from a WebSearch result summary only; the page itself could not be fetched (all non-GitHub hosts are blocked by the egress proxy). `[SECONDARY]` = community/engineer notes hosted on GitHub (not vendor documentation). `[UNVERIFIED]` = plausible but not confirmed by any accessible source. All equations are written out explicitly; symbols: μ = nominal/mean delay, σ = one-sigma delay variation, N or q = sigma multiplier (corner sigma), Δ = mean shift, γ = skewness.

## Key Question 1: Liberty LVF syntax and semantics (sigma tables, sigma_type, moment-based extension, AOCV `ocv_derate` groups, Liberty "va_" variation-aware constructs)

### Takeaway
LVF stores, per timing arc, slew/load-indexed lookup tables of the one-sigma variation of delay (`ocv_sigma_cell_rise/fall`), output transition (`ocv_sigma_rise/fall_transition`) and constraints (`ocv_sigma_rise/fall_constraint`), optionally split into `early`/`late` sigma via `sigma_type`; the 2017 moment-based extension adds `ocv_mean_shift_*`, `ocv_std_dev_*`, `ocv_skewness_*` tables for non-Gaussian modelling, while AOCV/POCV distance derates live in `ocv_table_template` + `ocv_derate { ocv_derate_factors {...} }` groups referenced through `default_ocv_derate_group` / `ocv_derate_group` / `ocv_derate_distance_group`. A separate, older Liberty "variation-aware" (VA) family (`timing_based_variation`/`pin_based_variation` groups with `va_parameters`, `nominal_va_values`, `va_values`, `va_compact_ccs_rise/fall`, `va_receiver_capacitance*`, `va_rise/fall_constraint`) expresses delay sensitivity to named (global) process parameters and is the only Liberty construct found that represents global variation as a parametric sensitivity.

### Cited Findings

**A. Sigma tables (single-parameter LVF)**

- Liberty Reference Manual (2020.09) text on `sigma_type`, reproduced verbatim in the `liberty-db` crate: "Specify the optional `sigma_type` attribute to define the type of arrival time listed in the `ocv_sigma_cell_rise`, `ocv_sigma_cell_fall`, `ocv_sigma_rise_transition`, and `ocv_sigma_fall_transition` group lookup tables. The values are `early`, `late`, and `early_and_late`. The default is `early_and_late`. You can specify the `sigma_type` attribute in the `ocv_sigma_cell_rise` and `ocv_sigma_cell_fall` groups. Syntax: `sigma_type: early | late | early_and_late;` Example: `sigma_type: early;`" (manual page anchor `bgn=357.15&end=357.24`). `[MANUAL-MIRROR]` — [liberty-db src/table.rs](https://github.com/zao111222333/liberty-db/blob/c1e36c1298892355843871076140fbcad4083c69/src/table.rs); manual mirror: [Liberty Reference Manual 2020.09](https://zao111222333.github.io/liberty-db/2020.09/reference_manual.html)
- The `liberty-db` data model (mirroring manual pages 347.33–349.32) treats each base table as a "supergroup" with its LVF companions: `cell_rise` ↔ `ocv_mean_shift_cell_rise`, `ocv_std_dev_cell_rise`, `ocv_skewness_cell_rise`, `ocv_sigma_cell_rise` (vector, one per `sigma_type`); same pattern for `cell_fall`, `rise_transition`, `fall_transition`, `rise_constraint`, `fall_constraint`, `retaining_rise`, `retaining_fall`, `retain_rise_slew`, `retain_fall_slew`. `[MANUAL-MIRROR]` — [liberty-db src/timing/mod.rs](https://github.com/zao111222333/liberty-db/blob/c1e36c1298892355843871076140fbcad4083c69/src/timing/mod.rs)
- Verbatim LVF example from a real (Synopsys-generated, dated 2020/10/19, `time_unit : "1ns"`, `nom_temperature : 85`, library `ts05nxqvlogl06hdp051f_lowvol_dlvl_TYPE1_tt0p355v85c_i0p75v`, i.e. a **TT, 0.355 V near-threshold** library) LVF file: every arc carries both moment tables and early/late sigma tables, e.g.
  ```
  ocv_sigma_cell_rise (tmg_ntin_oload_8x7) {
      sigma_type : "early";
      index_1 ("0.0020683, 0.00404192, 0.00789882, 0.01543606, 0.0301655, 0.05895014, 0.1152018, 0.22513");
      index_2 ("2.67185e-05, 0.0001321598, 0.0006537126, 0.00323351, 0.01599417, 0.07911321, 0.3913239");
      values ( ... );
  }
  ocv_sigma_cell_rise (tmg_ntin_oload_8x7) {
      sigma_type : "late";
      ...
  }
  ```
  followed by `ocv_sigma_cell_fall`, `ocv_sigma_rise_transition`, `ocv_sigma_fall_transition` each duplicated for `"early"` and `"late"`, plus `ocv_mean_shift_*`, `ocv_std_dev_*`, `ocv_skewness_*` for `cell_rise/fall` and `rise/fall_transition`. `[PRIMARY-GH]` — [N5_TYPE1_LVL.lib](https://github.com/harryliu-intel/async-toolkit/blob/2f5e6bf3e6d12b23cbe2de55ad06ee3a1cabfdad/async-toolkit/m3utils/m3utils/liberty/src/N5_TYPE1_LVL.lib)
- A second real example (liberty-db regression case) shows the early/late asymmetry numerically: for the same AND2 `cell_rise` arc, `sigma_type : early` values run `0.0008782 … 0.0422` ns while `sigma_type : late` values run `0.001288 … 0.0624` ns (late sigma ≈ 1.3–1.5× early sigma at every slew/load point), i.e. the delay distribution has a heavier slow tail. `[PRIMARY-GH]` — [liberty-db dev/tech/cases/ocv_sigma.lib](https://github.com/zao111222333/liberty-db/blob/c1e36c1298892355843871076140fbcad4083c69/dev/tech/cases/ocv_sigma.lib)
- Sigma grows strongly with load and slew in real tables (e.g. same file: early σ from 0.00088 ns at the smallest slew/load to 0.0422 ns at the largest, while nominal `cell_rise` goes 0.0163 → 0.5065 ns; so σ/μ ≈ 5.4 % at the fast corner of the table and ≈ 8.3 % at the slow corner). `[PRIMARY-GH]` — same file as above.
- Semantics of early/late sigma as documented in a community Liberty supplement (Traditional-Chinese engineering notes citing the 2017.06 manual line numbers): "delay(+σ) = delay + ocv_sigma_*_late ; delay(−σ) = delay − ocv_sigma_*_early"; constraint sigma tables are symmetric ("rise constraint(±σ) = nominal rise constraint ± ocv_sigma_rise_constraint value") and "`sigma_type` must NOT be specified in `ocv_sigma_rise_constraint` / `ocv_sigma_fall_constraint`, otherwise the tool errors"; constraint sigma tables may be 1-D/2-D/3-D with template variables `input_net_transition`, `total_output_net_capacitance`, `related_out_total_output_net_capacitance`; pin-direction rule: input pins → constraint sigma groups only, output pins → delay/transition sigma groups, inout → all. `[SECONDARY]` — [assrs/eda doc/Liberty_Attribute_Supplement.md](https://github.com/assrs/eda/blob/792ce46929990a80ae945fca0ed8e485891fb029/doc/Liberty_Attribute_Supplement.md)
- OpenSTA's Liberty reader implements exactly this: it reads each `ocv_sigma_*` sub-group, looks up `sigma_type`, and maps `early_and_late` (or absent) to both early and late models, `early` to early only, `late` to late only; it reads `ocv_sigma_{cell_rise|cell_fall}`, `ocv_sigma_{rise|fall}_transition`, `ocv_sigma_{rise|fall}_constraint` and their `ocv_std_dev_`, `ocv_mean_shift_`, `ocv_skewness_` companions. `[PRIMARY-GH]` — [OpenSTA liberty/LibertyReader.cc](https://github.com/The-OpenROAD-Project/OpenSTA/blob/d1e43c6f9f4e66cb59c3d7958a4aa7d1626b4614/liberty/LibertyReader.cc) (search for `sigma_type`, `ocv_sigma_cell_`)
- OpenSTA documentation lists the standard-deviation groups for normal (Gaussian) LVF: `ocv_sigma_cell_rise`, `ocv_sigma_cell_fall`, `ocv_sigma_rise_transition`, `ocv_sigma_fall_transition`, `ocv_sigma_rise_constraint`, `ocv_sigma_fall_constraint`; and the skew-normal (moment) groups: `ocv_std_dev_cell_rise/fall`, `ocv_mean_shift_cell_rise/fall`, `ocv_skewness_cell_rise/fall`, `ocv_std_dev_rise/fall_transition`, `ocv_skewness_rise_transition`, … `[PRIMARY-GH]` — [OpenSTA doc/Examples.md](https://github.com/The-OpenROAD-Project/OpenSTA/blob/d1e43c6f9f4e66cb59c3d7958a4aa7d1626b4614/doc/Examples.md)
- Full inventory of LVF group names as enumerated by an independent Liberty parser (NIIC EDA `timinglib` group table): `ocv_derate`, `ocv_derate_factors`, `ocv_table_template`, `ocv_mean_shift_{cell_fall, cell_rise, fall_constraint, fall_transition, retain_fall_slew, retain_rise_slew, retaining_fall, retaining_rise, rise_constraint, rise_transition}`, `ocv_std_dev_{same 10}`, `ocv_skewness_{same 10}`, `ocv_sigma_{fall_constraint, retain_fall_slew, retain_rise_slew, retaining_fall, retaining_rise, rise_constraint, …}`; attributes `default_ocv_derate_group`, `ocv_arc_depth`, `ocv_derate_group`, `sigma_type`, `va_parameters`, `va_values`; VA groups `pin_based_variation`, `timing_based_variation`, `va_compact_ccs_fall/rise`, `va_compact_ccs_retain_fall/rise`, `va_fall_constraint`, `va_rise_constraint`, `va_receiver_capacitance1_fall/rise`, `va_receiver_capacitance2_fall/rise`. `[PRIMARY-GH]` — [rectanglequery group_lookup](https://github.com/lbz007/rectanglequery/blob/59d6eb007bf65480fa3e9245542d0b6071f81831/src/db/timing/timinglib/group_lookup), [attr_lookup](https://github.com/lbz007/rectanglequery/blob/59d6eb007bf65480fa3e9245542d0b6071f81831/src/db/timing/timinglib/attr_lookup)
- "LVF represents variation data as a slew-/load-dependent table of sigmas per timing arc (pin, related pin, when condition), with tables supported for delay, transition, and constraint variation modeling." `[SNIPPET]` — [Cadence WP: Addressing Process Variation and Reducing Timing Pessimism at 16nm and Below](https://www.cadence.com/en_US/home/resources/white-papers/addressing-process-variation-and-reducing-timing-pessimism-at-16nm-and-below-wp.html)
- "As per Liberty specification, Liberty Variation Format (LVF) modeling is always done at one-sigma." `[SNIPPET]` — [Cadence blog: Overriding the One-Sigma Rule of Liberty for LVF Modeling](https://community.cadence.com/cadence_blogs_8/b/di/posts/library-characterization-tidbits-overriding-the-one-sigma-rule-of-liberty-for-lvf-modeling); a conflicting search summary of the PrimeLib datasheet says "LVF data is typically measured at 3 sigma (3σ)" `[SNIPPET]` — [PrimeLib datasheet](https://www.synopsys.com/content/dam/synopsys/implementation&signoff/datasheets/primelib-ds.pdf). (Interpretation in Inferences.)

**B. Moment-based LVF (mean shift / std dev / skewness)**

- Synopsys press release, 27 Feb 2017: "Three statistical moment-based extensions to the LVF standard consisting of mean shift, standard deviation and skewness" were ratified; "Moment-based LVF models non-Gaussian timing variation observed at ultra-low voltage corners"; targeted at near/sub-threshold operation for mobile/IoT. `[SNIPPET]` — [Synopsys news 2017-02-27](https://news.synopsys.com/2017-02-27-Synopsys-Announces-Expansion-of-Liberty-Modeling-Standard-Paving-Way-for-Ultra-Low-Power-IC-Design)
- Cadence patent (US 10,789,406, "Characterizing electronic component parameters including on-chip variations and moments") defines the tables: "`ocv_mean_shift_cell_rise`: the LUT of the offset values from the mean to the nominal, and mean = nominal + mean_shift; `ocv_std_dev_cell_rise`: the LUT of the standard deviation; `ocv_skewness_cell_rise`: the LUT of the skewness." `[SNIPPET]` — [USPTO 10789406](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/10789406)
- Community Liberty supplement: "Skewness … based on Pearson skewness coefficient: `Skewness = (E[(X−E[X])³])^(1/3)`", "used for non-Gaussian modelling in ultra-low-voltage (ULV) designs", "`ocv_skewness_*` must be defined together with `ocv_mean_shift_*`"; syntax example:
  ```
  timing() {
    ocv_mean_shift_cell_rise(lu_template_name) { index_1 (...); index_2 (...); values (...); }
    ocv_skewness_cell_rise(lu_template_name)   { index_1 (...); index_2 (...); values (...); }
    ocv_mean_shift_cell_fall(scalar) { values ("0.002") ; }
    ocv_skewness_cell_fall(scalar)   { values ("0.015") ; }
  }
  ```
  `[SECONDARY]` — [assrs/eda Liberty_Attribute_Supplement.md §16.8](https://github.com/assrs/eda/blob/792ce46929990a80ae945fca0ed8e485891fb029/doc/Liberty_Attribute_Supplement.md)
- Verbatim moment tables from the liberty-db regression library (units ns; 8×8 slew×load):
  ```
  ocv_mean_shift_cell_rise(delay_template_8x8){ index_1("0.0023, 0.0091, 0.0228, 0.0502, 0.105, 0.2145, 0.4335, 0.8715"); index_2("0.00015, 0.00059, 0.00148, 0.00325, 0.00679, 0.01388, 0.02805, 0.05639"); values("0.0000686, 0.0000914, ...", ...); }
  ocv_std_dev_cell_rise(delay_template_8x8){ ... values("0.000643, 0.000780, ... , 0.0218", ..., "0.0482, 0.0479, ..., 0.0440"); }
  ocv_skewness_cell_rise(delay_template_8x8){ ... values("0.00126, 0.00145, ...", ..., "-0.0206, -0.0210, ..., 0.0220"); }
  ```
  (skewness values are in time units and change sign across the table; std_dev grows from 0.00064 ns at low slew to 0.048 ns at high slew). `[PRIMARY-GH]` — [liberty-db dev/tech/cases/ocv.lib](https://github.com/zao111222333/liberty-db/blob/c1e36c1298892355843871076140fbcad4083c69/dev/tech/cases/ocv.lib)
- In the real near-threshold TT library, `ocv_mean_shift_cell_rise/fall` are all-zero tables while `ocv_skewness_cell_rise` is negative (≈ −1.4e-4 … −1.8e-3 ns) and `ocv_skewness_cell_fall` positive (≈ 7.5e-5 … 1.0e-3 ns) with `ocv_std_dev` ≈ 5e-3–1e-2 ns, i.e. asymmetry is present but small at this table's points. `[PRIMARY-GH]` — [N5_TYPE1_LVL.lib](https://github.com/harryliu-intel/async-toolkit/blob/2f5e6bf3e6d12b23cbe2de55ad06ee3a1cabfdad/async-toolkit/m3utils/m3utils/liberty/src/N5_TYPE1_LVL.lib)
- An open characterization pre-processor computes the moment tables from Monte-Carlo moment CSVs per (slew, load) index: `mean_shift = delay_mean − nominal`, `std_dev = delay_std_dev`, `skewness = delay_skewness` (also for transition), at corner `tt0p8v25c`. `[PRIMARY-GH]` — [StochasticCells/char22nm-preprocess src/arcs.rs](https://github.com/StochasticCells/char22nm-preprocess/blob/50d98d06c49c82c5525378a6d82bb8dec6c039aa/src/arcs.rs)
- Synopsys TAU 2016 talk title: "Importance of Modeling Non-Gaussianities in STA in sub-16nm Nodes" (P. Ghanta, Synopsys). `[SNIPPET, title only]` — [TAU 2016 slides](http://www.tauworkshop.com/2016/slides/10_TAU2016_Ghanta_nonGaussian_POCV.pdf)
- A Synopsys patent family ("Analyzing delay variations and transition time variations for electronic circuits") describes an asymmetric model where "the mean shift value Δ is determined based on the late sigma value and the early sigma values of the asymmetric distribution … based on a difference between the late sigma value and the early sigma value." `[SNIPPET]` — [USPTO 10255395](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/10255395), [10783301](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/10783301), [11288426](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/11288426)

**C. AOCV / distance derate groups inside Liberty**

- Verbatim syntax (community supplement, matching OpenSTA's reader):
  ```
  ocv_table_template(ocv_template_name) {
    variable_1 : path_depth | path_distance ;
    variable_2 : path_depth | path_distance ;  /* optional, 2-D */
    index_1 ("float, ..., float") ;
    index_2 ("float, ..., float") ;
  }
  ocv_derate(ocv_derate_group_name) {
    ocv_derate_factors(ocv_template_name) {
      rf_type : rise | fall | rise_and_fall ;
      derate_type : early | late ;
      path_type : clock | data | clock_and_data ;
      index_1 ("...") ; index_2 ("...") ;
      values ("float, ..., float", ...) ;
    }
  }
  /* library level */ default_ocv_derate_group : <name> ;  default_ocv_derate_distance_group : <name> ;  ocv_arc_depth : 1.0 ;
  /* cell level    */ ocv_derate_group : <name> ;  ocv_derate_distance_group : <name> ;
  /* arc level     */ ocv_arc_depth : <float> ;   /* precedence: timing arc > cell > library */
  ```
  Complete example (2-D depth×distance table, late/data/rise): `index_1 ("1, 5, 10, 20")` (depth), `index_2 ("100, 500, 1000, 5000")` (distance, um), `values ("1.05, 1.04, 1.03, 1.02", "1.04, 1.03, 1.02, 1.01", "1.03, 1.02, 1.01, 1.00", "1.02, 1.01, 1.00, 0.99")`; and a POCV distance-only group `ocv_table_template(ocv_distance_tmp){ variable_1 : path_distance ; index_1 ("100, 500, 1000, 5000"); }` referenced by `default_ocv_derate_distance_group`. `[SECONDARY]` — [assrs/eda Liberty_Attribute_Supplement.md §16.2–16.10](https://github.com/assrs/eda/blob/792ce46929990a80ae945fca0ed8e485891fb029/doc/Liberty_Attribute_Supplement.md)
- OpenSTA reads `ocv_table_template` (library level), `ocv_arc_depth` at library, cell and timing-group level, `default_ocv_derate_group`, and cell/library `ocv_derate` groups containing `ocv_derate_factors` with `rf_type` (rise|fall|rise_and_fall), `derate_type` (early|late|early_and_late), `path_type` (clock|data|clock_and_data). `[PRIMARY-GH]` — [OpenSTA LibertyReader.cc `readOcvDerateFactors`](https://github.com/The-OpenROAD-Project/OpenSTA/blob/d1e43c6f9f4e66cb59c3d7958a4aa7d1626b4614/liberty/LibertyReader.cc)
- GitHub-wide code search for `ocv_derate_distance_mode` and `ocv_table_template` in library files returned no hits (only parser sources), so no real-world Liberty AOCV table could be quoted; the PrimeTime side-file format is used instead in practice (see KQ3). `[PRIMARY-GH negative result]`

**D. Liberty variation-aware ("va_") constructs — global parameters as sensitivities**

- Liberty grammar description (from the Synopsys `liberty_parse` 2.6 distribution's `syntax.cmos.desc`) — verbatim:
  ```
  timing() {
      ...
      timing_based_variation() {
          va_parameters( list );
          nominal_va_values( list );
          va_compact_ccs_rise( [va_compact_ccs_rise_template_name] ) { va_values( list ); values( list ); }
          va_compact_ccs_fall( [va_compact_ccs_fall_template_name] ) { va_values( list ); values( list ); }
          va_receiver_capacitance1_fall( name ) { va_values( list ); index_1( list ); index_2( list ); values( list ); }
          va_receiver_capacitance1_rise( name ) { ... }
          va_receiver_capacitance2_fall( name ) { ... }
          va_receiver_capacitance2_rise( name ) { ... }
          va_rise_constraint( name ) { va_values( ... ); index_1( list ); index_2( list ); values( list ); }
          va_fall_constraint( name ) { ... }
      }
  }
  pin() {
      pin_based_variation() {
          when : virtual_attribute;
          va_parameters( list );
          nominal_va_values( list );
          va_receiver_capacitance1_fall( name ) { va_values( list ); index_1( list ); index_2( list ); values( list ); }
          ...
      }
  }
  ```
  i.e. each VA table is tagged with the process-parameter names (`va_parameters`), the nominal parameter values (`nominal_va_values`) and the parameter values at which the table was characterized (`va_values`). `[PRIMARY-GH]` — [geochrist/dctk syntax.cmos.desc](https://github.com/geochrist/dctk/blob/ebc3f0f3fa2c523b4797d87427dbd1a891fd3b8b/src-liberty_parse-2.6/desc/syntax.cmos.desc); same grammar in [ym-cell docs group.rst](https://github.com/yusuke-matsunaga/ym-cell/blob/6d4f66d5c522c658f479ff3940656c3a16d2b47f/docs/source/liberty/group.rst)
- Synopsys 2006 announcement: Liberty extensions "to enable variation-aware design … built on Composite Current Source (CCS) models", allowing engineers to "control design margins, improve design robustness, and increase parametric yield". `[SNIPPET]` — [Synopsys news item 122651](https://news.synopsys.com/index.php?s=20295&item=122651)
- PrimeTime VX (DAC 2006): three parts — "Liberty CCS modeling technology provides accurate timing models based on device variation; Star-RCXT VX enables sensitivity-based extraction for … interconnect variation; PrimeTime VX brings together device and interconnect models with statistical timing analysis"; STA on most of the design with statistical analysis on performance-critical nets; "a mix of analytical and sample-based statistical methods". `[SNIPPET]` — [Synopsys news 122590](https://news.synopsys.com/home?item=122590), [EDN news analysis](https://www.edn.com/news-analysis-is-synopsys-statistical-timing-tool-ready-for-prime-time/), [STARC adoption 122883](https://news.synopsys.com/home?item=122883)

**E. Standardization / versions**

- "The Liberty Technical Advisory Board (LTAB) has converged on a unified Liberty Variance Format (LVF) that includes OCV modeling along with existing timing, noise, and power models." `[SNIPPET]` — [Synopsys news 123415](https://news.synopsys.com/home?item=123415); Si2/Synopsys TAB formation: [EDN](https://www.edn.com/synopsys-si2-forming-tab-around-liberty-modeling-standard/) `[SNIPPET, title]`
- The Liberty User Guides and Reference Manual Suite Version 2017.06 (public PDF mirror) already documents `ocv_sigma_*`, `sigma_type`, and the moment groups (search hits for `ocv_sigma_rise_constraint`, `early_and_late`, `ocv_skewness`). `[SNIPPET]` — [Liberty 2017.06 PDF](https://media.c3d2.de/mgoblin_media/media_entries/659/Liberty_User_Guides_and_Reference_Manual_Suite_Version_2017.06.pdf)

### Inferences
- The "one-sigma rule" and the "measured at 3σ" statements are reconcilable: the LVF *tables store 1σ* (the timer multiplies by `timing_pocvm_corner_sigma`/`timing_nsigma_multiplier`), whereas characterization may *extract* the 3σ quantile from samples and divide by 3 to populate the table (the Cadence blog title "Overriding the One-Sigma Rule" implies Liberate offers a knob to store a different level). Treat the exact characterization quantile as tool-/flow-dependent.
- With `sigma_type : early` and `late` both present, an LVF library already encodes an asymmetric (two-half-Gaussian) distribution; the moment-based groups replace this with a three-moment skew model. The real N5-class TT library carries **both** representations so either PrimeTime mode (`timing_pocvm_enable_extended_moments` true/false) or Tempus mode (`delaycal_socv_lvf_mode moments|early_late`) can consume it.
- The Liberty VA (`va_parameters`/`va_values`) family is the only standardized Liberty mechanism found that stores delay as a function of *named global parameters* (a parametric global corner model); the modern LVF family stores only *local* random sigma per arc. A "TT + global sigma" flow therefore needs either VA-style sensitivity tables (legacy PrimeTime VX), a timer-side global-derate mechanism (KQ4), or separate corner libraries.
- Skewness unit convention matters when converting between tools: Liberty text (as reproduced) defines skewness as the cube root of the third central moment (time units), whereas OpenSTA applies the stored value directly as a dimensionless γ in its quantile formula (KQ3); whether OpenSTA normalizes at read time is not visible in the excerpts read.

### Gaps
- The Si2/Synopsys Liberty specification PDFs themselves (2013–2024 revisions, exact release in which `ocv_sigma_*` first appeared and the 2017 moment ratification text) could not be fetched; only the 2020.09 manual text mirrored in `liberty-db` and search snippets were accessible.
- No real-world `.lib` with `ocv_derate`/`ocv_table_template` (Liberty-embedded AOCV tables) was found on GitHub; the `ocv_derate_distance_mode` attribute mentioned in the assignment could not be verified anywhere (GitHub search: 0 hits) — treat as `[UNVERIFIED]`.
- Whether current PrimeTime still consumes `timing_based_variation`/`va_*` groups (PrimeTime VX era) is unverified.
