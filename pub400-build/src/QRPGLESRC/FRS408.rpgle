**free
//  %METADATA
//  %TEXT Select Customer from List of Orders
//  %EMETADATA

Ctl-Opt DftActGrp(*No) ActGrp(*New);

// File: CUSTORD - Externally-described logical file
// Strategy: USE_EXTERNAL_DDS - Fields automatically available from external file
// DDS Location: QDDSSRCF/custord.lf
// Note: Fields ORDRNO, AGNTNO, CUSTNM, CUSTNO, FLGTNO, DEPART, TCKTNO, CLASS, SENDSG
//       are automatically defined by the external file and available after READ
Dcl-F CUSTORD Disk(*Ext) Keyed Usage(*Input);

Dcl-F FRS408DF Workstn Sfile(SFL:SFLRN) InfDs(WSDS) IndDs(IndDs);

// Constants
Dcl-C $F01 x'31';
Dcl-C $F03 x'33';
Dcl-C $F09 x'39';
Dcl-C $F12 x'3C';
Dcl-C $ENTER x'F1';
Dcl-C $HELP x'F3';
Dcl-C $PAGUP x'F4';
Dcl-C $PAGDN x'F5';
Dcl-C $PRINT x'F6';
Dcl-C $FALSE '0';
Dcl-C $TRUE '1';

// External Program Prototypes
Dcl-Pr QMHRMVPM ExtPgm('QMHRMVPM');
  MessageQueue Char(10) Const;
  CallStackCounter Int(10) Const;
  MessageKey Char(4) Const;
  MessagesToClear Char(10) Const;
  ErrorCode Char(256);
End-Pr;

Dcl-Pr QMHSNDPM ExtPgm('QMHSNDPM');
  MessageID Char(7) Const;
  QualifiedMessageFileName Char(20) Const;
  MessageData Char(80) Const;
  MessageDataLength Int(10) Const;
  MessageType Char(10) Const;
  CallStackEntry Char(10) Const;
  CallStackCounter Int(10) Const;
  MessageKey Char(4);
  ErrorCode Char(256);
End-Pr;

Dcl-Pr QUSCMDLN ExtPgm('QUSCMDLN');
End-Pr;

// Data Structures
Dcl-DS APIERR;
  ERRSIZ Int(10) Inz(256);
  ERRLEN Int(10) Inz(0);
  ERRMIC Char(7);
  ERRNBR Char(1);
  ERRDTA Char(240);
End-DS;

Dcl-DS *N;
  MSGCTR Int(10) Inz(0);
  MSGLEN Int(10) Inz(80);
  MSGF Char(20) Inz('FRSMSGF   *LIBL     ');
  MSGTYP Char(10) Inz('*INFO     ');
  MSGKEY Char(4) Inz('    ');
End-DS;

Dcl-DS *N;
  RMVCTR Int(10) Inz(0);
  RMVMSQ Char(10) Inz('*         ');
  RMVCLR Char(10) Inz('*ALL      ');
  RMVKEY Char(4) Inz('    ');
End-DS;

Dcl-DS *N Psds;
  $PGM Char(10) Pos(1);
  $STAT Char(5) Pos(11);
  $PARMS Char(3) Pos(37);
  $MSGID Char(7) Pos(40);
  $DATA Char(80) Pos(91);
  $JOBNA Char(10) Pos(244);
  $USRNA Char(10) Pos(254);
  $JOBNO Char(6) Pos(264);
  $SRCF Char(10) Pos(304);
  $SRCL Char(10) Pos(314);
  $SRCM Char(10) Pos(324);
End-DS;

Dcl-DS WSDS;
  KEY Char(1) Pos(369);
  PAGRRN Int(5) Pos(378);
End-DS;

Dcl-DS *N;
  ENDCNK Char(70);
  ENDCNL Packed(5:0) Pos(1);
  ENDCNM Char(25) Pos(3);
  BLNKSA Char(39) Pos(28);
  ENDORD Packed(9:0) Pos(67);
End-DS;

Dcl-DS *N;
  CUSKEY Char(70);
  CUSLEN Packed(5:0) Pos(1);
  CUSNAM Char(25) Pos(3);
  BLNKSB Char(39) Pos(28);
  CUSORD Packed(9:0) Pos(67);
End-DS;

Dcl-DS IndDs;
  Ind40 Ind Pos(40);
  Ind42 Ind Pos(42);
  Ind50 Ind Pos(50);
  Ind60 Ind Pos(60);
  Ind97 Ind Pos(97);
  Ind98 Ind Pos(98);
  Ind99 Ind Pos(99);
End-DS;

// Program variables
Dcl-S $EXIT Char(1);
Dcl-S SFLRN Packed(4:0);
Dcl-S ENDRN Packed(4:0);
Dcl-S SFLPS Packed(4:0);
Dcl-S MSGID Char(7);
Dcl-S MSGDTA Char(80);
Dcl-S MSGQUE Char(10);
Dcl-S PGMQ Char(10);
Dcl-S ORDRN Packed(9:0);
Dcl-S CUSTN Char(25);
Dcl-S SELIO Char(1);
Dcl-S SEARCH Char(25);
Dcl-S LoopCtr Int(10);

// Main procedure interface
Dcl-Pi *N;
  PCUSNM Char(25);
  PORDNO Packed(9:0);
End-Pi;

// Main logic
$EXIT = $FALSE;  // RESET EXIT FLAG
Exsr $RMVMS;
Exsr $RESET;
Exsr $LOAD;  // LOAD SFL

// Main loop
Dow $EXIT = $FALSE;  // DO UNTIL F3/F12
  Write FRSWIN;      // WRITE MSGCTL
  Write FKEYS;       // WRITE SFL CMDL
  Write MSGCTL;      // WRITE MSGCTL
  Exfmt SFLCTL;      // WRITE SFL CTL

  SFLPS = PAGRRN;

  Select;
    When KEY = $F03;
      Exsr $F03SR;  // F03 EXIT
    When KEY = $F09;
      Exsr $F09SR;  // F09 COMMAND LINE
    When KEY = $F12;
      Exsr $F12SR;  // F12 CANCEL
    When KEY = $PAGDN;
      Exsr $PGDN;   // PAGE DOWN
    Other;
      Exsr $ENTKY;  // Enter
  EndSl;
EndDo;

*InLr = *On;

// ============================================================================
// Subroutines
// ============================================================================

// INIT SUBROUTINE
Begsr *InzSr;
  Ind50 = *Off;  // RESET ERR IND

  MSGID = ' ';
  MSGDTA = *Blanks;
  MSGQUE = $PGM;
  PGMQ = $PGM;
  $EXIT = $FALSE;  // PGM EXIT = OFF

  SFLRN = 0;
  ENDRN = 0;
  SFLPS = 1;

  CUSKEY = *Blanks;
  CUSNAM = 'A';
  CUSLEN = 1;
  CUSORD = 1;

  SetLL CUSNAM CUSTORD;
Endsr;

// Load subfile
Begsr $LOAD;
  // Read a page of records or until EOF.
  For LoopCtr = 1 To 4;
    Read CUSTORD;

    If %Eof(CUSTORD);
      Leave;
    EndIf;

    // Fields from CUSTORD are automatically available:
    // ORDRNO, AGNTNO, CUSTNM, CUSTNO, FLGTNO, DEPART, TCKTNO, CLASS, SENDSG
    ORDRN = ORDRNO;
    CUSKEY = CUSTNM;
    CUSTN = CUSNAM;
    CUSORD = ORDRNO;

    SFLRN += 1;
    Write SFL;  // WRITE SFL RCRD
  EndFor;

  ENDCNK = CUSTNM;  // UPDATE END KEYS
  ENDORD = ORDRNO;
  ENDRN = SFLRN;    // FOR FILE/SUBFILE

  If Not %Eof(CUSTORD);  // IF NOT EOF
    // Read one more to make sure
  EndIf;

  If SFLRN = *Zeros;     // IF NO RECS ADDED
    Ind42 = *Off;        // TO SFL SET ERR IND
  Else;                  // OTHERWISE
    Ind42 = *On;         // SET IND TO DSP SFL
    SFLPS = SFLRN;       // SET SFL POSTN TO PAGE JUST ADDED
  EndIf;
Endsr;

Begsr $RESET;
  Ind40 = *On;
  Write FRSWIN;  // WRITE MSGCTL
  Write SFLCTL;
  Ind40 = *Off;
  Ind42 = *Off;

  Reset SFLRN;
  Reset ENDRN;
  Reset SFLPS;
Endsr;

Begsr $REPOS;
  Exsr $RESET;
  If SEARCH = *Blanks;
    CUSKEY = CUSTNM;  // UPDATE END KEYS
    CUSORD = ORDRNO;
  EndIf;
  SetLL CUSNAM CUSTORD;
  Exsr $LOAD;
Endsr;

Begsr $PGDN;
  If Not %Eof(CUSTORD);
    SFLRN = ENDRN;
    Exsr $LOAD;
  Else;
    Ind60 = *On;
  EndIf;
Endsr;

Begsr $ENTKY;
  Ind50 = *Off;  // RESET ERR IND
  If SEARCH <> *Blanks;
    CUSLEN = %Check(' ':SEARCH);
    CUSNAM = SEARCH;
    Exsr $REPOS;
  Else;
    Exsr $SFLRD;
  EndIf;
Endsr;

// RD SFL CHG RCDS
Begsr $SFLRD;
  Exsr $RMVMS;  // SND ERR MESSAGE

  ReadC SFL;    // SELECTION MADE?
  Ind97 = %Eof(FRS408DF);
  Ind98 = %Eof(FRS408DF);

  If Ind97;
    Exsr $REPOS;  // REPOSITN SFL
    Return;       // Exit subroutine (replaces GOTO ENDSEL)
  EndIf;

  Dow Not Ind98;
    If SELIO = '1';
      PORDNO = ORDRN;
      PCUSNM = CUSTN;
      $EXIT = $TRUE;  // SET EXIT FLAG ON
      Leave;
    EndIf;

    ReadC SFL;
    Ind97 = %Eof(FRS408DF);
    Ind98 = %Eof(FRS408DF);

    If Ind97;
      Exsr $REPOS;  // REPOSITN SFL
      Exsr $SNDMS;  // SND ERR MESSAGE
      Leave;        // REPOSITN SFL
    EndIf;
  EndDo;
Endsr;

Begsr $RMVMS;
  QMHRMVPM(RMVMSQ:RMVCTR:RMVKEY:RMVCLR:APIERR);
Endsr;

Begsr $SNDMS;
  QMHSNDPM(MSGID:MSGF:MSGDTA:MSGLEN:MSGTYP:MSGQUE:MSGCTR:MSGKEY:APIERR);
Endsr;

// F3 SUBROUTINE
Begsr $F03SR;
  $EXIT = $TRUE;  // SET EXIT FLAG ON
Endsr;

// F9 SUBROUTINE
Begsr $F09SR;
  QUSCMDLN();  // GET CMD LINE
Endsr;

Begsr $F12SR;
  $EXIT = $TRUE;
Endsr;
