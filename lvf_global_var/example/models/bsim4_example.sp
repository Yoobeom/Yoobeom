* ---------------------------------------------------------------------------
* File   : bsim4_example.sp
* Author : yoobeom.kim@samsung.com
* Purpose: Example BSIM4 (level=54) model cards for the LVF global-variation
*          flow regression. 45nm-class planar values, example use only.
*          Not a foundry model. Replace with the PDK model include in
*          production runs (cfg(model_include)).
* Notes  : delvto / mulu0 instance parameters are the perturbation hooks
*          used by tr_sens_char.tcl (cfg(hook,vth), cfg(hook,u0)).
* ---------------------------------------------------------------------------

.model nch nmos level=54 version=4.8 binunit=1 paramchk=1 mobmod=0 capmod=2
+ igcmod=0 igbmod=0 geomod=1 diomod=1 rdsmod=0 rbodymod=0 rgatemod=0
+ tnom=27 toxe=1.75e-9 toxp=1.1e-9 toxm=1.75e-9 epsrox=3.9
+ wint=5e-9 lint=3.75e-9 xpart=0 toxref=1.75e-9
+ vth0=0.469 k1=0.4 k2=0.01 k3=0 k3b=0 w0=2.5e-6
+ dvt0=1 dvt1=2 dvt2=-0.032 dvt0w=0 dvt1w=0 dvt2w=0
+ dsub=0.1 minv=0.05 voffl=0 dvtp0=1.0e-9 dvtp1=0.1 lpe0=0 lpeb=0
+ xj=1.4e-8 ngate=2e20 ndep=3.24e18 nsd=2e20 phin=0
+ cdsc=0 cdscb=0 cdscd=0 cit=0 voff=-0.13 nfactor=2.1 eta0=0.0058 etab=0
+ vfb=-0.55 u0=0.04359 ua=6e-10 ub=1.2e-18 uc=0 vsat=147390
+ a0=1.0 ags=1e-20 a1=0 a2=1.0 b0=0 b1=0 keta=0.04 dwg=0 dwb=0
+ pclm=0.02 pdiblc1=0.001 pdiblc2=0.001 pdiblcb=-0.005 drout=0.5
+ pvag=1e-20 delta=0.01 pscbe1=8.14e8 pscbe2=1e-7
+ fprout=0.2 pdits=0.08 pditsd=0.23 pditsl=2.3e6
+ rsh=5 rdsw=150 rsw=150 rdw=150 rdswmin=0 rdwmin=0 rswmin=0 prwg=0
+ prwb=6.8e-11 wr=1 alpha0=0.074 alpha1=0.005 beta0=30
+ agidl=0.0002 bgidl=2.1e9 cgidl=0.0002 egidl=0.8
+ cgso=1.1e-10 cgdo=1.1e-10 cgbo=2.56e-11 cgdl=2.653e-10 cgsl=2.653e-10
+ ckappas=0.03 ckappad=0.03 acde=1 moin=15 noff=0.9 voffcv=0.02
+ kt1=-0.11 kt1l=0 kt2=0.022 ute=-1.5 ua1=4.31e-9 ub1=7.61e-18 uc1=-5.6e-11
+ prt=0 at=33000
+ fnoimod=1 tnoimod=0
+ jss=0.0001 jsws=1e-11 jswgs=1e-10 njs=1 ijthsfwd=0.01 ijthsrev=0.001 bvs=10 xjbvs=1
+ jsd=0.0001 jswd=1e-11 jswgd=1e-10 njd=1 ijthdfwd=0.01 ijthdrev=0.001 bvd=10 xjbvd=1
+ pbs=1 cjs=0.0005 mjs=0.5 pbsws=1 cjsws=5e-10 mjsws=0.33 pbswgs=1 cjswgs=3e-10 mjswgs=0.33
+ pbd=1 cjd=0.0005 mjd=0.5 pbswd=1 cjswd=5e-10 mjswd=0.33 pbswgd=1 cjswgd=5e-10 mjswgd=0.33
+ tpb=0.005 tcj=0.001 tpbsw=0.005 tcjsw=0.001 tpbswg=0.005 tcjswg=0.001
+ xtis=3 xtid=3
+ dmcg=0 dmci=0 dmdg=0 dmcgt=0 dwj=0 xgw=0 xgl=0
+ rshg=0.4 gbmin=1e-10 rbpb=5 rbpd=15 rbps=15 rbdb=15 rbsb=15 ngcon=1

.model pch pmos level=54 version=4.8 binunit=1 paramchk=1 mobmod=0 capmod=2
+ igcmod=0 igbmod=0 geomod=1 diomod=1 rdsmod=0 rbodymod=0 rgatemod=0
+ tnom=27 toxe=1.85e-9 toxp=1.1e-9 toxm=1.85e-9 epsrox=3.9
+ wint=5e-9 lint=3.75e-9 xpart=0 toxref=1.85e-9
+ vth0=-0.418 k1=0.4 k2=-0.01 k3=0 k3b=0 w0=2.5e-6
+ dvt0=1 dvt1=2 dvt2=-0.032 dvt0w=0 dvt1w=0 dvt2w=0
+ dsub=0.1 minv=0.05 voffl=0 dvtp0=1e-9 dvtp1=0.05 lpe0=0 lpeb=0
+ xj=1.4e-8 ngate=2e20 ndep=2.44e18 nsd=2e20 phin=0
+ cdsc=0 cdscb=0 cdscd=0 cit=0 voff=-0.126 nfactor=2.1 eta0=0.0058 etab=0
+ vfb=0.55 u0=0.00440 ua=2.0e-9 ub=0.5e-18 uc=0 vsat=70000
+ a0=1.0 ags=1e-20 a1=0 a2=1 b0=0 b1=0 keta=-0.047 dwg=0 dwb=0
+ pclm=0.12 pdiblc1=0.001 pdiblc2=0.001 pdiblcb=3.4e-8 drout=0.56
+ pvag=1e-20 delta=0.01 pscbe1=8.14e8 pscbe2=9.58e-7
+ fprout=0.2 pdits=0.08 pditsd=0.23 pditsl=2.3e6
+ rsh=5 rdsw=150 rsw=150 rdw=150 rdswmin=0 rdwmin=0 rswmin=0 prwg=3.22e-8
+ prwb=6.8e-11 wr=1 alpha0=0.074 alpha1=0.005 beta0=30
+ agidl=0.0002 bgidl=2.1e9 cgidl=0.0002 egidl=0.8
+ cgso=1.1e-10 cgdo=1.1e-10 cgbo=2.56e-11 cgdl=2.653e-10 cgsl=2.653e-10
+ ckappas=0.03 ckappad=0.03 acde=1 moin=15 noff=0.9 voffcv=0.02
+ kt1=-0.11 kt1l=0 kt2=0.022 ute=-1.5 ua1=4.31e-9 ub1=7.61e-18 uc1=-5.6e-11
+ prt=0 at=33000
+ fnoimod=1 tnoimod=0
+ jss=0.0001 jsws=1e-11 jswgs=1e-10 njs=1 ijthsfwd=0.01 ijthsrev=0.001 bvs=10 xjbvs=1
+ jsd=0.0001 jswd=1e-11 jswgd=1e-10 njd=1 ijthdfwd=0.01 ijthdrev=0.001 bvd=10 xjbvd=1
+ pbs=1 cjs=0.0005 mjs=0.5 pbsws=1 cjsws=5e-10 mjsws=0.33 pbswgs=1 cjswgs=3e-10 mjswgs=0.33
+ pbd=1 cjd=0.0005 mjd=0.5 pbswd=1 cjswd=5e-10 mjswd=0.33 pbswgd=1 cjswgd=5e-10 mjswgd=0.33
+ tpb=0.005 tcj=0.001 tpbsw=0.005 tcjsw=0.001 tpbswg=0.005 tcjswg=0.001
+ xtis=3 xtid=3
+ dmcg=0 dmci=0 dmdg=0 dmcgt=0 dwj=0 xgw=0 xgl=0
+ rshg=0.4 gbmin=1e-10 rbpb=5 rbpd=15 rbps=15 rbdb=15 rbsb=15 ngcon=1
