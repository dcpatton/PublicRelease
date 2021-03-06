C UTEP Electronic Structure Lab (2019)
C
C
       SUBROUTINE UPRAVEL(IFNCT,ISHELLA,I_SITE,RVEC,RVECI,N_NUC,ILOC)
C ORIGINALLY WRITTEN BY MARK R PEDERSON (6-AUGUST 1999)
C UPRAVEL SHOULD BE USED IN SPNORB. THIS SUBROUTINE DIFFERS SLIGHTLY
C FROM UNRAVEL. UNRAVEL SHOULD BE USED WHEN THE RESULTING WAVEFUNCTIONS
C ARE ROTATED (USING REPMAT ETC..). UNRAVEL CAN BE USED FOR ALL PROBLEMS
C WHERE A REAL IRREDUCIBLE REPRESENTATION EXISTS. IN CASES WHERE A RIR
C DOES NOT EXIST AND ONE IS LOOPING OVER ALL ROTATIONS OF AN R POINT 
C UPRAVEL IS APPROPRIATE.
       use debug1
       use common3,only : NGRP
       use common2,only : N_CON, LSYMMAX, ISPN, NSPN
       use common5,only : PSI_COEF, OCCUPANCY, N_OCC, PSI, NWF, NWFS
       use common7,only : T1UNRV, T2UNRV
       use common8,only : REP, N_REP, NDMREP, U_MAT, N_SALC,
     &   INDBEG, LDMREP
! Conversion to implicit none.  Raja Zope Thu Aug 17 14:35:05 MDT 2017

!      INCLUDE  'PARAMAS'  
       INCLUDE  'PARAMA2'  
       INTEGER :: IFNCT, ISHELLA, I_SITE, N_NUC, ILOC, I, I_LOCAL,
     & I_SALC, IBASE, ICALL1, ICALL2, IMS, IND_SALC, INDEX, IOCC, IQ,
     & IQ_BEG, IREP, IROW, ISHELL, ISHELLV, ITOT, IWF, K_REP, K_ROW,
     & KSALC, LI, MDMREP, MU, NDEG
       REAL*8 :: RVEC , RVECI, FACTOR, TIMER1, TIMER2
       DIMENSION NDEG(3),IND_SALC(ISMAX,MAX_CON,3)
       DIMENSION RVECI(3,NGRP),RVEC(3)
       LOGICAL REDREP,FIRST,OCCL,OCCV
C       COMMON/UNRAVL/OCCL(MAX_OCC),OCCV(MAX_OCC)
C       DIMENSION ISHELLV(2),MDMREP(MAX_REP)
       DIMENSION ISHELLV(2),MDMREP(N_REP)
       SAVE
       DATA NDEG/1,3,6/
       DATA ICALL1,ICALL2,ISHELL/0,0,0/
       DATA FIRST/.TRUE./
C     
        REDREP=.FALSE.
        DO IREP=1,N_REP
        IF(LDMREP(IREP).NE.1)REDREP=.TRUE.
        IF(LDMREP(IREP)*(NDMREP(IREP)/LDMREP(IREP)).NE.NDMREP(IREP))THEN
        write(6,*)'PROBLEM IN UPRAVEL WITH REDUCIBLE REP MODE'
        CALL STOPIT 
        END IF
        MDMREP(IREP)=NDMREP(IREP)!/LDMREP(IREP)
C       MDMREP(IREP)=NDMREP(IREP)/LDMREP(IREP)
        END DO
          IF(FIRST.AND.DEBUG)THEN
          write(6,*)'N_REP:',N_REP
          write(6,*)'LDMREP:',(LDMREP(I),I=1,N_REP)
          write(6,*)'NDMREP:',(NDMREP(I),I=1,N_REP)
          write(6,*)'MDMREP:',(MDMREP(I),I=1,N_REP)
          END IF
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
         DO 5 K_ROW=1,MDMREP(K_REP)
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
          I_SALC=KSALC-MDMREP(K_REP)
          DO 950 IROW=1,MDMREP(K_REP)
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
            write(6,*)'UNRAVEL: MAXUNSYM MUST BE AT LEAST:',I_LOCAL
            CALL STOPIT
           END IF
           FACTOR=SQRT(OCCUPANCY(ITOT))
           IF(IROW.GT.1.AND.LDMREP(K_REP).NE.1)THEN
           IWF=IWF-1
           END IF
C          DO 25 J_LOCAL=1,I_LOCAL
C           PSI(J_LOCAL,IWF,ILOC)=FACTOR*PSI(J_LOCAL,IWF,ILOC)
C  25      CONTINUE
  950     CONTINUE
 1000    CONTINUE
 1010   CONTINUE
       NWFS(ISPN)=IWF
 1020  CONTINUE
       NWF=NWFS(NSPN)
         IF(NSPN.EQ.2)NWFS(NSPN)=NWF-NWFS(1)
       IF (IWF.NE.NWF) THEN
        write(6,*)'UNRAVEL: BIG BUG: NUMBER OF STATES IS INCORRECT'
        write(6,*)'IWF,NWF:',IWF,NWF
        CALL STOPIT
       END IF
       CALL GTTIME(TIMER2)
       T2UNRV=T2UNRV+(TIMER2-TIMER1)
       ICALL2=ICALL2+1
       IF (DEBUG.AND.(1000*(ICALL2/1000).EQ.ICALL2)) THEN
        write(6,*)'WASTED2:',T2UNRV
        write(6,*)'ICALL2,AVG:',ICALL2,T2UNRV/ICALL2
       END IF
       FIRST=.FALSE.
       RETURN
       END
