* ---------------------------------------------------------------------------
* File   : std_cells.sp
* Author : yoobeom.kim@samsung.com
* Purpose: Example standard-cell subcircuits for the LVF global-variation flow.
*          Port order follows the Liberty pin names used in example.cfg.tcl.
*          Instance names (M1..) are the keys of the per-transistor
*          sensitivity table (sens.csv, column "inst").
* ---------------------------------------------------------------------------

.subckt INV_X1 A ZN VDD VSS
M1 ZN A VSS VSS nch W=0.20u L=0.045u AS=0.03p AD=0.03p PS=0.7u PD=0.7u
M2 ZN A VDD VDD pch W=0.60u L=0.045u AS=0.09p AD=0.09p PS=1.5u PD=1.5u
.ends INV_X1

.subckt NAND2_X1 A B ZN VDD VSS
M1 ZN  A n1  VSS nch W=0.40u L=0.045u AS=0.06p AD=0.06p PS=1.1u PD=1.1u
M2 n1  B VSS VSS nch W=0.40u L=0.045u AS=0.06p AD=0.06p PS=1.1u PD=1.1u
M3 ZN  A VDD VDD pch W=0.60u L=0.045u AS=0.09p AD=0.09p PS=1.5u PD=1.5u
M4 ZN  B VDD VDD pch W=0.60u L=0.045u AS=0.09p AD=0.09p PS=1.5u PD=1.5u
.ends NAND2_X1

.subckt NOR2_X1 A B ZN VDD VSS
M1 ZN  A VSS VSS nch W=0.20u L=0.045u AS=0.03p AD=0.03p PS=0.7u PD=0.7u
M2 ZN  B VSS VSS nch W=0.20u L=0.045u AS=0.03p AD=0.03p PS=0.7u PD=0.7u
M3 p1  A VDD VDD pch W=1.20u L=0.045u AS=0.18p AD=0.18p PS=2.7u PD=2.7u
M4 ZN  B p1  VDD pch W=1.20u L=0.045u AS=0.18p AD=0.18p PS=2.7u PD=2.7u
.ends NOR2_X1
