     FFRS406DFCF  E                    WORKSTN      KINFDS(WSDS)
      *
     D WSDS            DS
     D  KEY                          369    369A
      *
      * Constants
     D $F01            C                   X'31'
     D $F03            C                   X'33'
     D $F12            C                   X'3C'
     D $ENTER          C                   X'F1'
     D $HELP           C                   X'F3'
     D $PRINT          C                   X'F6'
     D $FALSE          C                   '0'
     D $TRUE           C                   '1'
      *
      * Parameters
     D ORDER#          S              9A
     D ENDYN           S              1A
      *
      * Work Fields
     D $EXIT           S              1A
     D ORDER           S              9A
      *
     C     *ENTRY        PLIST
     C                   PARM                    ORDER#
     C                   PARM                    ENDYN
      *
     C                   EXSR      INZSR
      *
     C                   DOW       $EXIT <> $TRUE
      *
     C                   WRITE     FRSWIN
     C                   EXFMT     FKEYS
      *
     C                   SELECT
     C                   WHEN      KEY = $F03
     C                   EXSR      $F03SR
     C                   WHEN      KEY = $F12
     C                   EXSR      $F12SR
     C                   WHEN      KEY = $ENTER
     C                   EXSR      $ENTKY
     C                   ENDSL
      *
     C     NEXT          TAG
     C                   ENDDO
      *
     C                   EVAL      *INLR = *ON
      *
      *================================================================
      * INZSR - Initialize Subroutine
      *================================================================
     C     INZSR         BEGSR
     C                   EVAL      ORDER = ORDER#
     C                   EVAL      ENDYN = 'N'
     C                   EVAL      $EXIT = $FALSE
     C                   ENDSR
      *
      *================================================================
      * $ENTKY - Enter Key Subroutine
      *================================================================
     C     $ENTKY        BEGSR
     C                   EVAL      $EXIT = $TRUE
     C                   ENDSR
      *
      *================================================================
      * $F03SR - F3 Exit Subroutine
      *================================================================
     C     $F03SR        BEGSR
     C                   EVAL      ENDYN = 'Y'
     C                   EVAL      $EXIT = $TRUE
     C                   ENDSR
      *
      *================================================================
      * $F12SR - F12 Cancel Subroutine
      *================================================================
     C     $F12SR        BEGSR
     C                   EVAL      ENDYN = 'Y'
     C                   EVAL      $EXIT = $TRUE
     C                   ENDSR
