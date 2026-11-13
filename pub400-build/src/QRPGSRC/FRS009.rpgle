**FREE

// Program: FRS009 - Order Selection Program
// Description: Interactive program for order selection with various function ke
// Converted to Free Form RPGLE from RPG

Ctl-Opt DftActGrp(*NO) ActGrp(*NEW);

// File Declarations
Dcl-F FRS009DF WorkStn InfDS(WSDS);
Dcl-F ORDERSZ Disk(*EXT) Keyed Usage(*INPUT:*OUTPUT:*UPDATE:*DELETE);

// Named Constants for Function Keys
Dcl-C $F01    x'31';
Dcl-C $F02    x'32';
Dcl-C $F03    x'33';
Dcl-C $F04    x'34';
Dcl-C $F05    x'35';
Dcl-C $F09    x'39';
Dcl-C $F10    x'3A';
Dcl-C $F12    x'3C';
Dcl-C $ENTER  x'F1';
Dcl-C $HELP   x'F3';
Dcl-C $PRINT  x'F6';

// Named Constants for Apostrophe and Boolean Values
Dcl-C APOST   x'7D';
Dcl-C $FALSE  '0';
Dcl-C $TRUE   '1';

// Program Status Data Structure
Dcl-DS *SDS;
  $PGM    Char(10)  Pos(1);
  $STAT   Char(5)   Pos(11);
  $PARMS  Char(3)   Pos(37);
  $MSGID  Char(7)   Pos(40);
  $DATA   Char(79)  Pos(91);
  $JOBNA  Char(10)  Pos(244);
  $USRNA  Char(10)  Pos(254);
  $JOBNO  Char(6)   Pos(264);
  $SRCF   Char(10)  Pos(304);
  $SRCL   Char(10)  Pos(314);
  $SRCM   Char(10)  Pos(324);
End-DS;

// API Error Data Structure
Dcl-DS APIERR;
  ERRSIZ  Int(10)   Pos(1)   Inz(256);
  ERRLEN  Int(10)   Pos(5);
  ERRMIC  Char(7)   Pos(9);
  ERRNBR  Char(1)   Pos(16);
  ERRDTA  Char(240) Pos(17);
End-DS;

// Message API Data Structure
Dcl-DS MSGDS;
  MSGCTR  Int(10)   Pos(1)   Inz(80);
  MSGLEN  Int(10)   Pos(5)   Inz(80);
  MSGF    Char(20)  Pos(9)   Inz('FRSMSGF   *LIBL     ');
  MSGTYP  Char(10)  Pos(29)  Inz('*INFO     ');
  MSGKEY  Char(4)   Pos(39)  Inz('    ');
End-DS;

// Remove Message Data Structure
Dcl-DS RMVDS;
  RMVCTR  Int(10)   Pos(1);
  RMVMSQ  Char(10)  Pos(5)   Inz('*         ');
  RMVCLR  Char(10)  Pos(15)  Inz('*ALL      ');
  RMVKEY  Char(4)   Pos(25)  Inz('    ');
End-DS;

// WorkStation Data Structure
Dcl-DS WSDS;
  KEY     Char(1)   Pos(369);
End-DS;

// Program Parameters
Dcl-Pi *N;
  PAGENT  Char(90);
  RUNTYP  Char(6);
End-Pi;

// Standalone Variables
Dcl-S ORDER   Zoned(6:0);
Dcl-S CUSNAM  Char(30);
Dcl-S DODYY   Zoned(4:0);
Dcl-S DODMM   Zoned(2:0);
Dcl-S DODDD   Zoned(2:0);
Dcl-S MSGDTA  Char(80);
Dcl-S MSGQUE  Char(10);
Dcl-S MSGID   Char(7);
Dcl-S PGMQ    Char(20);
Dcl-S $EXIT   Char(1);

// Main Program Logic
ORDER = 0;
CUSNAM = *BLANKS;
DODYY = 0;
DODMM = 0;
DODDD = 0;
MSGDTA = *BLANKS;
MSGQUE = *BLANKS;
PGMQ = *BLANKS;

// Initialize screen
Write SELCTR;
INZSR();

// Main loop
DoU $EXIT = $TRUE;
  Write MSGCTL;
  ExFmt SELCTR;

  Select;
    When KEY = $F02;
      $F02SR();
    When KEY = $F03;
      $F03SR();
    When KEY = $F04;
      $F04SR();
    When KEY = $F05;
      $F05SR();
    When KEY = $F09;
      $F09SR();
    When KEY = $F12;
      $F12SR();
    Other;
      $ERRCK();
  EndSl;

  // F10 pressed - Create record
  If KEY = $F10 And Not *InLR And Not *In50;
    $F10SR();
  EndIf;
EndDo;

*InLR = *On;
Return;

// ============================================================
// Subroutine: INZSR - Initialize program
// ============================================================
Dcl-Proc INZSR;
  *In50 = *Off;
  *In51 = *Off;
  *In52 = *Off;

  MSGID = ' ';
  MSGDTA = *BLANKS;
  MSGQUE = $PGM;
  $EXIT = $FALSE;
  PGMQ = $PGM;
End-Proc;

// ============================================================
// Subroutine: $ERRCK - Check input data
// ============================================================
Dcl-Proc $ERRCK;
  *In44 = *Off;
  *In50 = *Off;
  *In51 = *Off;
  *In52 = *Off;
  *In53 = *Off;

  $RMVMS();

  // Check if order is zero
  If ORDER = *Zeros;
    *In50 = *On;
    *In53 = *On;
    MSGID = 'FRS0090';
    $SNDMS();
    Return;
  EndIf;

  // Chain to order file
  Chain ORDER ORDNMZ;
  If Not %Found(ORDERSZ);
    *In44 = *On;
    *In50 = *On;
    *In53 = *On;
    MSGID = 'FRS0091';
    $SNDMS();
    Return;
  EndIf;
End-Proc;

// ============================================================
// Subroutine: $RMVMS - Remove program messages
// ============================================================
Dcl-Proc $RMVMS;
  Dcl-PR QMHRMVPM ExtPgm('QMHRMVPM');
    CallStk   Char(10) Const;
    CallStkC  Int(10)  Const;
    MsgKey    Char(4)  Const;
    MsgsRmv   Char(10) Const;
    Error     Char(256);
  End-PR;

  QMHRMVPM(RMVMSQ : RMVCTR : RMVKEY : RMVCLR : APIERR);
End-Proc;

// ============================================================
// Subroutine: $SNDMS - Send program message
// ============================================================
Dcl-Proc $SNDMS;
  Dcl-PR QMHSNDPM ExtPgm('QMHSNDPM');
    MsgID     Char(7)   Const;
    MsgF      Char(20)  Const;
    MsgData   Char(80)  Const;
    MsgDtaLen Int(10)   Const;
    MsgType   Char(10)  Const;
    CallStkE  Char(10)  Const;
    CallStkC  Int(10)   Const;
    MsgKey    Char(4);
    Error     Char(256);
  End-PR;

  QMHSNDPM(MSGID : MSGF : MSGDTA : MSGLEN : MSGTYP : MSGQUE : MSGCTR :
           MSGKEY : APIERR);
End-Proc;

// ============================================================
// Subroutine: $F02SR - F2 Refresh
// ============================================================
Dcl-Proc $F02SR;
  *In50 = *Off;
  *In51 = *Off;
  *In52 = *Off;
  Write SELCTR;
  $RMVMS();
End-Proc;

// ============================================================
// Subroutine: $F03SR - F3 Exit
// ============================================================
Dcl-Proc $F03SR;
  $EXIT = $TRUE;
End-Proc;

// ============================================================
// Subroutine: $F04SR - F4 Select by Customer
// ============================================================
Dcl-Proc $F04SR;
  Dcl-PR FRS408 ExtPgm('FRS408');
    CusName   Char(30);
    OrderNum  Zoned(6:0);
  End-PR;

  FRS408(CUSNAM : ORDER);
  DODYY = 0;
  DODMM = 0;
  DODDD = 0;

  If ORDER <> 0;
    $F10SR();
  EndIf;
End-Proc;

// ============================================================
// Subroutine: $F05SR - F5 Select by Date
// ============================================================
Dcl-Proc $F05SR;
  Dcl-PR FRS407 ExtPgm('FRS407');
    Year      Zoned(4:0);
    Month     Zoned(2:0);
    Day       Zoned(2:0);
    OrderNum  Zoned(6:0);
  End-PR;

  FRS407(DODYY : DODMM : DODDD : ORDER);
  CUSNAM = *BLANKS;

  If ORDER <> 0;
    $F10SR();
  EndIf;
End-Proc;

// ============================================================
// Subroutine: $F09SR - F9 Command Line
// ============================================================
Dcl-Proc $F09SR;
  Dcl-PR QUSCMDLN ExtPgm('QUSCMDLN');
  End-PR;

  QUSCMDLN();
End-Proc;

// ============================================================
// Subroutine: $F10SR - F10 Process Order
// ============================================================
Dcl-Proc $F10SR;
  Dcl-PR FRS002 ExtPgm('FRS002');
    Agent     Char(90);
    OrderNum  Zoned(6:0);
  End-PR;

  Dcl-PR FRS003 ExtPgm('FRS003');
    Agent     Char(90);
    OrderNum  Zoned(6:0);
  End-PR;

  Dcl-PR FRS004 ExtPgm('FRS004');
    Agent     Char(90);
    OrderNum  Zoned(6:0);
  End-PR;

  Dcl-PR FRS005 ExtPgm('FRS005');
    Agent     Char(90);
    OrderNum  Zoned(6:0);
  End-PR;

  Select;
    When RUNTYP = 'UPDATE';
      FRS002(PAGENT : ORDER);
    When RUNTYP = 'DSPLAY';
      FRS003(PAGENT : ORDER);
    When RUNTYP = 'DELETE';
      FRS004(PAGENT : ORDER);
    When RUNTYP = 'FAX   ';
      FRS005(PAGENT : ORDER);
  EndSl;

  $F02SR();
End-Proc;

// ============================================================
// Subroutine: $F12SR - F12 Cancel
// ============================================================
Dcl-Proc $F12SR;
  $EXIT = $TRUE;
End-Proc;
