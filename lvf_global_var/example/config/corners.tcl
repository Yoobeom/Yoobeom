# ---------------------------------------------------------------------------
# File   : corners.tcl
# Author : yoobeom.kim@samsung.com
# Purpose: Global variation points for prediction and validation.
#          Entry format: {group param unit value}
#            unit abs   : physical shift (vth [V] as |Vth| increase, u0 relative)
#            unit sigma : multiples of cfg(sigma_g,<group>,<param>)
# ---------------------------------------------------------------------------

# single-parameter sweeps (linearity check)
set corner(NVT_p1s)  {{N vth sigma  1}}
set corner(NVT_p3s)  {{N vth sigma  3}}
set corner(NVT_m3s)  {{N vth sigma -3}}
set corner(PVT_p3s)  {{P vth sigma  3}}
set corner(PVT_m3s)  {{P vth sigma -3}}
set corner(NU0_m3s)  {{N u0  sigma -3}}
set corner(PU0_m3s)  {{P u0  sigma -3}}

# combined process corners (all parameters move together)
set corner(SSG)  {{N vth sigma  3} {P vth sigma  3} {N u0 sigma -3} {P u0 sigma -3}}
set corner(FFG)  {{N vth sigma -3} {P vth sigma -3} {N u0 sigma  3} {P u0 sigma  3}}
set corner(SFG)  {{N vth sigma  3} {P vth sigma -3} {N u0 sigma -3} {P u0 sigma  3}}
set corner(FSG)  {{N vth sigma -3} {P vth sigma  3} {N u0 sigma  3} {P u0 sigma -3}}
set corner(SS1)  {{N vth sigma  1} {P vth sigma  1} {N u0 sigma -1} {P u0 sigma -1}}
