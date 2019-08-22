C UTEP Electronic Structure Lab (2019)
C
       SUBROUTINE UTRAVEL(IFNCT,ISHELLA,I_SITE,RVEC,RVECI,N_NUC,ILOC)
C
C ORIGINALLY WRITTEN BY MARK R PEDERSON (1985)
C UPDATED JUNE, 2013
C
C SUBROUTINE TO UNSYMMETRIZE THE WAVEFUNCTIONS....
C
       use debug1
       use common2,only : N_CON, LSYMMAX, ISPN, NSPN
       use common5,only : PSI_COEF, OCCUPANCY, N_OCC, PSI, NWF
       use common7,only : T1UNRV, T2UNRV
       use common8,only : REP, N_REP, NDMREP, U_MAT, N_SALC, INDBEG
! Conversion to implicit none.  Raja Zope Thu Aug 17 14:35:05 MDT 2017

!      INCLUDE  'PARAMAS'  
       INCLUDE  'PARAMA2'  
       INTEGER :: IFNCT, ISHELLA, I_SITE, N_NUC, ILOC, I_LOCAL, I_SALC,
     & IBASE, ICALL1, ICALL2, IMS, IND_SALC, INDEX, IOCC, IQ, IQ_BEG,
     & IROW, ISHELL, ISHELLV, ITOT, IWF, J_LOCAL, K_REP, K_ROW, KSALC,
     & LI, MU, NDEG
       REAL*8 :: RVEC , RVECI, FACTOR, TIMER1, TIMER2
       SAVE
       DIMENSION NDEG(3),IND_SALC(ISMAX,MAX_CON,3)
       DIMENSION RVECI(3,MX_GRP),RVEC(3)
       DIMENSION ISHELLV(2)
       DATA NDEG/1,3,6/
       DATA ICALL1,ICALL2,ISHELL/0,0,0/
C
       IF(I_SITE.EQ.1)THEN
        ICALL1=ICALL1+1
        CALL GTTIME(TIMER1)
        CALL OBINFO(1,RVEC,RVECI,N_NUC,ISHELLV(ILOC))
        CALL GSMAT(ISHELLV(ILOC),ILOC)
        CALL GTTIME(TIMER2)
        T1UNRV=T1UNRV+TIMER2-TIMER1
        IF (DEBUG.AND.(1000*(ICALL1/1000).EQ.ICALL1)) THEN
         write(6,*)'WASTED1=',T1UNRV,ISHELL
         write(6,*)'ICALL2,AVERAGE:',ICALL1,T1UNRV/ICALL2
        END IF
       END IF
       CALL GTTIME(TIMER1)
       ISHELL=ISHELLV(ILOC)
C
C UNSYMMETRIZE THE WAVEFUNCTIONS....
C
       ITOT=0
       IWF=0
       DO 1020 ISPN=1,NSPN
        KSALC=0
        DO 1010 K_REP=1,N_REP
C
C CALCULATE ARRAY LOCATIONS:
C
         DO 5 K_ROW=1,NDMREP(K_REP)
          KSALC=KSALC+1
    5    CONTINUE
         INDEX=INDBEG(ISHELLA,K_REP)
         DO 20 LI =0,LSYMMAX(IFNCT)
          DO 15 IBASE=1,N_CON(LI+1,IFNCT)
           DO 10 IQ=1,N_SALC(KSALC,LI+1,ISHELL)
            INDEX=INDEX+1
            IND_SALC(IQ,IBASE,LI+1)=INDEX
   10      CONTINUE
   15     CONTINUE
   20    CONTINUE
C
C END CALCULATION OF SALC INDICES FOR REPRESENTATION K_REP
C
         DO 1000 IOCC=1,N_OCC(K_REP,ISPN)
          ITOT=ITOT+1
          I_SALC=KSALC-NDMREP(K_REP)
          DO 950 IROW=1,NDMREP(K_REP)
           I_SALC=I_SALC+1
           IWF=IWF+1
           I_LOCAL=0
           DO 900 LI=0,LSYMMAX(IFNCT)
            DO 890 MU=1,NDEG(LI+1)
             IMS=MU+NDEG(LI+1)*(I_SITE-1)
             DO 880 IBASE=1,N_CON(LI+1,IFNCT)
              I_LOCAL=I_LOCAL+1
              PSI(I_LOCAL,IWF,ILOC)=0.0D0
              IQ_BEG=IND_SALC(1,IBASE,LI+1)-1
              DO 800 IQ=1,N_SALC(KSALC,LI+1,ISHELL)
               PSI(I_LOCAL,IWF,ILOC)=PSI(I_LOCAL,IWF,ILOC)+
     &         PSI_COEF(IQ+IQ_BEG,IOCC,K_REP,ISPN)*
     &         U_MAT(IMS,IQ,I_SALC,LI+1,ILOC)
  800         CONTINUE
  880        CONTINUE
  890       CONTINUE
  900      CONTINUE
           IF(I_LOCAL.GT.MAXUNSYM)THEN
            WRITE(6,*)'UTRAVEL: MAXUNSYM MUST BE AT LEAST:',I_LOCAL
            CALL STOPIT
           END IF
           FACTOR=1.0D0!SQRT(OCCUPANCY(ITOT))
           DO 25 J_LOCAL=1,I_LOCAL
            PSI(J_LOCAL,IWF,ILOC)=FACTOR*PSI(J_LOCAL,IWF,ILOC)
   25      CONTINUE
  950     CONTINUE
 1000    CONTINUE
 1010   CONTINUE
 1020  CONTINUE
C
       IF (IWF.NE.NWF) THEN
        PRINT *,'UTRAVEL: BIG BUG: NUMBER OF STATES IS INCORRECT'
        PRINT *,'IWF,NWF:',IWF,NWF
        CALL STOPIT
       END IF
       CALL GTTIME(TIMER2)
       T2UNRV=T2UNRV+(TIMER2-TIMER1)
       ICALL2=ICALL2+1
       IF (DEBUG.AND.(1000*(ICALL2/1000).EQ.ICALL2)) THEN
        write(6,*)'WASTED2:',T2UNRV
        write(6,*)'ICALL2,AVG:',ICALL2,T2UNRV/ICALL2
       END IF
       RETURN
       END