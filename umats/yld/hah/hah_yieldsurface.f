c-----------------------------------------------------------------------
c     Module used to calculate yield surface distorted by HAH approach

c     General references
c     [1] Barlat et al. IJP 58, 2014 p201-218
c     [2] Jeong et al., IJP, 2016 (in press)

c     Dependents
c     hah_io in hah_lib.f
c     hah_decompose in hah_lib.f
c     yld in  ../yld.f
c-----------------------------------------------------------------------
      subroutine hah_yieldsurface(iyld_choice,yldc,nyldc,
     $     yldp,nyldp,sdev,
     $     phi_chi,dphi_chi,d2phi_chi,ntens,
     $     phi,dphi,d2phi)
c     Arguments
c     iyld_choice: choice of yield surface kernel
c     yldc      : yield surface constants
c     nyldc     : Len of yldc
c     yldp      : yield surface parameters
c     nyldp     : Len of yldp
c     sdev      : deviatoric stress tensor
c     phi_chi   : isotropic yield surface
c     dphi_chi  : isotropic yield surface 1st derivative
c     d2phi_chi : isotropic yield surface 2nd derivative
c     ntens     : Len of deviatoric stress tensor
c     phi       : HAH yield surface
c     dphi      : HAH yield surface 1st derivative
c     d2phi     : HAH yield surface 2nd derivative
      implicit none
      integer iyld_choice,ntens,nyldp,nyldc
      dimension yldc(nyldc),yldp(nyldp),sdev(ntens)

      real*8 yldc,yldp,sdev

c     isotropic yield surface
      dimension dphi_chi(ntens),d2phi_chi(ntens,ntens)
      real*8, intent(in) :: phi_chi,dphi_chi,d2phi_chi

c     HAH yield surface
      dimension dphi(ntens),d2phi(ntens,ntens)
      real*8 phi,dphi,d2phi

c     local - microstructure deviator
      dimension emic(6)
      real*8 emic
c     local - Bauschinger parameters
      dimension gk(4)
      dimension e_ks(5)
      dimension f_ks(2)
      dimension target(ntens)
      real*8 gk,e_ks,f_ks,eeq,target
c     local - Latent hardening parameters
      real*8 gL,ekL,eL

c     local - cross hardening parameters
      real*8 gS,c_ks,ss
c     local
      dimension sc(ntens),so(ntens),sdp(ntens),sp(ntens) ! stress double prime
      real*8 sc,so,sdp,sp,ref
c     local-latent
      dimension dphi_lat(ntens),d2phi_lat(ntens,ntens)
      real*8 phi_lat,dphi_lat,d2phi_lat
c     local-cross
      dimension dphi_x(ntens),d2phi_x(ntens,ntens)
      real*8 phi_x,dphi_x,d2phi_x,phi_omega
c     local-bau
      dimension phibs(2)
      real*8 phibs
c     local-control
      integer imsg
      logical idiaw
      
cf2py intent(in) iyld_choice,yldc,nyldc,yldp,nylpd
cf2py intent(in) sdev,phi_chi,dphi_chi,d2phi_chi,ntens
cf2py intent(out) phi,dphi,d2phi

c-----------------------------------------------------------------------
      imsg = 0
      idiaw=.false.

c$$$c     obtain deviatoric stress
c$$$      call deviat(cauchy,ntens,sdev)
      if (idiaw) then
         call fill_line(imsg,'#',72)
         call w_chr(imsg,'Enter HAH_YIELDSURFACE')
         call fill_line(imsg,'#',72)
         call w_chr(imsg,'deviatoric stress')
         call w_dim(imsg,sdev,ntens,1d0,.false.)
c     call exit(-1)
      endif

c-----------------------------------------------------------------------
c     Restore yldp into state variables/parameters
      call hah_io(0,nyldp,ntens,yldp,emic,gk,e_ks,f_ks,eeq,ref,
     $     gL,ekL,eL,gS,c_ks,ss)

c     calculate yield surface

c     decompose deviatoric stress
      if (idiaw) then
         call w_chr(imsg,'calling to hah_decompose')
      endif
      call hah_decompose(sdev,ntens,emic,sc,so)
      if (idiaw) then
         call w_chr(imsg,'deviatoric Stress decomposition')
         call w_dim(imsg,sdev,ntens,1d0,.false.)
         call w_chr(imsg,'emic')
         call w_dim(imsg,emic,ntens,1d0,.false.)
         call w_chr(imsg,'sc')
         call w_dim(imsg,sc,ntens,1d0,.false.)
         call w_chr(imsg,'so')
         call w_dim(imsg,so,ntens,1d0,.false.)
      endif

      sdp(:) = sc(:) + so(:)/gL
      if (idiaw) then
         call w_val(imsg,'gL:',gL)
         call w_chr(imsg,'sdp')
         call w_dim(imsg,sdp,ntens,1d0,.false.)
      endif

c------------------------------
c     Latent extension
c------------------------------
c***  Target direction
      target(:) = sdev(:)
c***  stress double prime following eq 25 in Ref [1]
      if (gL.eq.0) then
         call w_empty_lines(imsg,2)
         call fill_line(imsg,'*',72)
         call w_chr(imsg,'**** Error gL is zero ****')
         call fill_line(imsg,'*',72)
         call exit(-1)
      endif
c      call exit(-1)
c------------------------------
      if (.false.) then
         call w_chr(imsg,'** calling yld for phi_lat **')
c     call exit(-1)
         call yld(iyld_choice,yldp,yldc,nyldp,nyldc,sdp,phi_lat,
     $        dphi_lat,d2phi_lat,ntens)
c     call exit(-1)
      else
         phi_lat=1d0
      endif

c------------------------------
c     Cross load hardening
c------------------------------
      sp(:) = 4d0*(1d0-gS)*so(:)
      if (idiaw) then
         call w_chr(imsg,'** calling yld for phi_x **')
      endif
      call yld(iyld_choice,yldp,yldc,nyldp,nyldc,sp,phi_x,dphi_x,
     $     d2phi_x,ntens)
c      call exit(-1)

      phi_omega = (dsqrt(phi_lat**2+phi_x**2))**8d0

c------------------------------
c     Bauschinger
c------------------------------
      if (idiaw) then
         call w_chr(imsg,'** calling Bauschinger for phibs **')
         call w_chr(imsg,'f_ks passed to Bauschinger')
         call w_dim(imsg,f_ks,2,1d0,.false.)
      endif
      call bauschinger(f_ks,yldc(9),emic,sdev,ntens,phibs(1),phibs(2))
      if (idiaw) then
         call w_chr(imsg,'phib1, phib2')
         call w_dim(imsg,phibs,2,1d0,.false.)
         call w_chr(imsg,'**')
      endif

c--------------------------------------------------
c     HAH Yield surface
      phi = (phi_omega+phibs(1)+phibs(2))**(1d0/8d0)
c--------------------------------------------------

      if (idiaw)  then
         call w_empty_lines(imsg,2)
         call fill_line(imsg,'*',72)
         call w_val(imsg,'phi_x    :',phi_x)
         call w_val(imsg,'phi_chi  :',phi_chi)
         call w_val(imsg,'phi_lat  :',phi_lat)
         call w_val(imsg,'phi_omega:',phi_omega)
         call w_val(imsg,'phi      :',phi)
         call w_chr(imsg,'Exit HAH_YIELDSURFACE')
         call fill_line(imsg,'*',72)
         call w_empty_lines(imsg,2)
      endif

c      call exit(-1)

      return
      end subroutine hah_yieldsurface

c-----------------------------------------------------------------------
      subroutine hah_ys_ref(iyld,cauchy,ntens,yldc,nyldc)
      implicit none
      integer iyld,ntens,nyldc
      dimension cauchy(ntens),yldc(nyldc)
      real*8 cauchy,yldc

      dimension dphi(ntens),d2phi(ntens,ntens)
      real*8 ref,dphi,d2phi

      call yld2000_2d(cauchy,ref,dphi,d2phi,yldc)


      return
      end subroutine hah_ys_ref
