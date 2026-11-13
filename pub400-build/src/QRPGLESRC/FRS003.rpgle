     FFRS003DF  CF   E             WORKSTN INFDS(WSDS)
     FORDNAME   IF   E           DISK
     FFLIGHTSZ  IF   E           DISK
     D TF              S             11  0 DIM(9999)
     D*
     D FLDS            DS
     D  INZTYP                 1      5
     D*
     D $F01            C                   CONST(X'31')
     D $F03            C                   CONST(X'33')
     D $F09            C                   CONST(X'39')
     D $F12            C                   CONST(X'3C')
     D $ENTER          C                   CONST(X'F1')
     D $HELP           C                   CONST(X'F3')
     D $PRINT          C                   CONST(X'F6')
     D*
     D $OFF            C                   CONST('0')
     D $ON             C                   CONST('1')
     D*
     D $FALSE          C                   CONST('0')
     D $TRUE           C                   CONST('1')
     D*
     D                SDS
     D  $PGM                   1     10                                          _ERR_
     D  $STAT                 11     15  0                                       _ERR_
     D  $PARMS                37     39  0                                       _ERR_
     D  $MSGID                40     46                                          _ERR_
     D  $DATA                 91    169                                          _ERR_
     D  $JOBNA               244    253                                          _ERR_
     D  $USRNA               254    263                                          _ERR_
     D  $JOBNO               264    269                                          _ERR_
     D  $SRCF                304    313                                          _ERR_
     D  $SRCL                314    323                                          _ERR_
     D  $SRCM                324    333                                          _ERR_
     D*
     D WSDS            DS
     D  KEY                  369    369
     D*
     D* Field name mapping for ORDNAME file
     D CNAME           S             66A   VARYING
     D*
     D* Field name mapping for FLIGHTSZ file
     D FFLGHT          S              9  0
     D FDPCIN          S             16A   VARYING
     D FDPCNM          S             16A   VARYING
     D FDYOWK          S             16A   VARYING
     D FARCIN          S             16A   VARYING
     D FARCNM          S             16A   VARYING
     D FDPTTM          S             32A   VARYING
     D FARVTM          S             32A   VARYING
     D FAIRLN          S             32A   VARYING
     D FSEATS          S              4  0
     D FTCKTP          S             22A   VARYING
     D FMILES          S              4  0
     D*
     D                 DS
     D  PRICEA                 1     24
     D  PRICEL                 1      2B 0
     D  PRICEN                 3      5
     D  BLNK19                 6     24
     D*
     D                 DS
     D  DPTIMA                 1     34
     D  DPTIML                 1      2B 0
     D  DPTIM8                 3     10
     D  DPREST                11     34
     D*
     D                 DS
     D  ARTIMA                 1     34
     D  ARTIML                 1      2B 0
     D  ARTIM8                 3     10
     D  ARREST                11     34
     D*
     D                 DS
     D  AIRLNA                 1     34
     D  AIRLNL                 1      2B 0
     D  AIRLN3                 3      5
     D  ALREST                 6     34
     D*
     D                 DS
     D  CUSTKY                 1     66
     D  CUSTLN                 1      2B 0
     D  CUSTNM                 3     66
     D*
     D                 DS
     D  CLASSK                 1      3
     D  CLASSL                 1      2B 0
     D  CLASSN                 3      3
     D*
     D                 DS
     D  DDPCNA                 1     18
     D  DDPCNL                 1      2B 0
     D  DDPCNM                 3     18
     D*
     D                 DS
     D  DARCNA                 1     18
     D  DARCNL                 1      2B 0
     D  DARCNM                 3     18
     D*
     D                 DS
     D  FILDPK                 1     26
     D  FILYY                  1      4
     D  FDASH1                 5      5    INZ('-')
     D  FILMM                  6      7
     D  FDASH2                 8      8    INZ('-')
     D  FILDD                  9     10
     D  FREST                 11     26    INZ
     C*
     C     *ENTRY        PLIST
     C                   PARM                    AGENT#            9 0
     C                   PARM                    PORDER            9 0
     C*                                                     * D=DELETE
     C*                    RESETFRSDSP                      * REFRESH SCREEN -
     C                   EXSR      INZSR
     C*
     C     $EXIT         DOUEQ     $TRUE
     C*
     C                   WRITE     MSGCTL                                        * WRITE MSGCTL
     C                   EXFMT     FRSDSP                                        * DISPLAY SCREEN
     C*
     C     KEY           CASEQ     $F03          $F03SR                          * F03 EXIT
     C     KEY           CASEQ     $F09          $F09SR                          * F03 EXIT
     C     KEY           CASEQ     $F12          $F12SR                          * F12 CANCEL
     C                   ENDCS
     C*
     C                   ENDDO                                                   * END DO
     C*
     C     END           TAG
     C*
     C                   MOVE      *ON           *INLR                           * LAST RECORD=ON
     C*
     C*
     C*
     C     INZSR         BEGSR                                                   * SET OUTPT SCREEN
     C*
     C                   SETOFF                                         4450     * ERROR IND. SC 1
     C*
     C     *DTAARA       DEFINE                  FLDS
     C                   IN        FLDS
     C*
     C                   MOVE      ' '           MSGID             7
     C                   MOVE      *BLANKS       MSGDTA           80
     C                   MOVE      $PGM          MSGQUE           10
     C*
     C                   MOVE      $FALSE        $EXIT             1
     C                   MOVE      $PGM          PGMQ
     C*
     C                   Z-ADD     PORDER        ORDNUM                                     ACTIVE
     C*
     C     ORDNUM        CHAIN     ORDNAME                            44
     C*
     C* Map external file fields to old names
     C                   EVAL      CNAME = CUSTNM
     C*
     C                   MOVE      DEPART        FILDPK
     C                   MOVE      FILYY         DOFYR
     C                   MOVE      FILMM         DOFMON
     C                   MOVE      FILDD         DOFDAY
     C*
     C                   MOVE      CNAME         CUSTKY
     C                   MOVEL     %TRIM(CUSTNM) CUSNAM
     C*
     C                   EVAL      CLASS = %TRIM(CLASS)
     C                   MOVE      CLASS         CLASSK
     C*
     C     CLASSN        IFEQ      '1'                                           * RUN INTERACTIVE
     C                   MOVE      'X'           COSFIR
     C                   ENDIF
     C     CLASSN        IFEQ      '2'                                           * RUN INTERACTIVE
     C                   MOVE      'X'           COSBUS
     C                   ENDIF
     C     CLASSN        IFEQ      '3'                                           * RUN INTERACTIVE
     C                   MOVE      'X'           COSECO
     C                   ENDIF
     C*
     C                   Z-ADD     TCKTNO        TCKETS                                     ACTIVE
     C*
     C     FLGTNO        CHAIN     FLIGHTSZ                           45
     C*
     C* Map external file fields to old names
     C                   Z-ADD     FLGHTN        FFLGHT
     C                   EVAL      FDPCIN = DPCINT
     C                   EVAL      FDPCNM = DPCNAM
     C                   EVAL      FDYOWK = DYOFWK
     C                   EVAL      FARCIN = ARCINT
     C                   EVAL      FARCNM = ARCNAM
     C                   EVAL      FDPTTM = DPTIME
     C                   EVAL      FARVTM = ARTIME
     C                   EVAL      FAIRLN = AIRLNM
     C                   Z-ADD     SEATS         FSEATS
     C                   EVAL      FTCKTP = TCKTPR
     C                   Z-ADD     MILES         FMILES
     C*
     C                   MOVE      FDPCNM        DDPCNA
     C                   MOVEL     DDPCNM        FCITY
     C                   MOVE      FARCNM        DARCNA
     C                   MOVEL     DARCNM        TCITY
     C*
     C                   MOVE      *BLANKS       DPTIMA                          * SET ERR MESSAGE
     C                   MOVE      *BLANKS       ARTIMA                          * SET ERR MESSAGE
     C                   MOVE      *BLANKS       AIRLNA                          * SET ERR MESSAGE
     C                   MOVE      *BLANKS       PRICEA                          * SET ERR MESSAGE
     C*
     C                   Z-ADD     FFLGHT        FLIGHT
     C                   MOVE      FDPTTM        DPTIMA
     C                   MOVEL     DPTIM8        DPTIME
     C                   MOVE      FARVTM        ARTIMA
     C                   MOVEL     ARTIM8        ARTIME
     C                   MOVE      FAIRLN        AIRLNA
     C                   MOVEL     AIRLN3        AIRLIN
     C                   MOVEL     FTCKTP        PRICEA
     C                   Z-ADD     0.00          PRICE                           * RETURN START TIME
     C                   MOVE      PRICEN        PRICE                           * RETURN START TIME
     C     PRICEL        IFEQ      2                                             * RETURN START TIME
     C     PRICE         MULT      10            PRICE                           * RETURN START TIME
     C                   ELSE
     C     PRICE         MULT      100           PRICE                           * RETURN START TIME
     C                   ENDIF
     C*
     C                   Z-ADD     0             ADJPRC            6 2
     C     COSFIR        IFNE      ' '                                           * RUN INTERACTIVE
     C     PRICE         MULT      3             ADJPRC
     C                   ENDIF
     C     COSBUS        IFNE      ' '                                           * RUN INTERACTIVE
     C     PRICE         MULT      2             ADJPRC
     C                   ENDIF
     C     COSECO        IFNE      ' '                                           * RUN INTERACTIVE
     C                   Z-ADD     PRICE         ADJPRC
     C                   ENDIF
     C*
     C     TCKETS        IFGE      01                                            * RUN INTERACTIVE
     C                   Z-ADD     ADJPRC        PRICE
     C     TCKETS        MULT      PRICE         PRICE
     C     PRICE         MULT      .04           TAXDUE
     C     PRICE         ADD       TAXDUE        TOTAL
     C                   END
     C*
     C     INZTYP        IFEQ      'CLEAR'
     C                   CLEAR                   TF
     C                   ELSE
     C                   RESET                   TF
     C                   END
     C*
     C     ENDINZ        ENDSR
     C*
     C*
     C     $F03SR        BEGSR                                                   * F3 SUBROUTINE
     C                   MOVE      $TRUE         $EXIT                           * SET EXIT FLAG ON
     C                   ENDSR
     C*
     C*
     C     $F09SR        BEGSR                                                   * F9 SUBROUTINE
     C                   CALL      'QUSCMDLN'                                    * GET CMD LINE
     C                   ENDSR
     C*
     C*
     C     $F12SR        BEGSR
     C                   MOVE      $TRUE         $EXIT
     C                   ENDSR
