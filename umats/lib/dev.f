c     Given stress s, calculate deviator and hydrostatic pressure
      subroutine deviat(s,sd,p)
      implicit none
      real*8 s(6),sd(6),p
      p = (s(1)+s(2)+s(3))/3.
      sd(1) = s(1)-p
      sd(2) = s(2)-p
      sd(3) = s(3)-p
      sd(4) = s(4)
      sd(5) = s(5)
      sd(6) = s(6)
      return
      end subroutine deviat