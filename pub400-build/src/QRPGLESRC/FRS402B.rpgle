**free

// Select From City from List (old: no reposition)

// File Declarations
Dcl-F FRCITY Usage(*Input) Keyed;
Dcl-F FRS402DF Workstn InfDs(WSDS) Sfile(SFL:SFLRN);

// Constants - Function Keys
Dcl-C $F01 X'31';
Dcl-C $F03 X'33';
Dcl-C $F12 X'3C';
Dcl-C $ENTER X'F1';
Dcl-C $HELP X'F3';
Dcl-C $PAGUP X'F4';
Dcl-C $PAGDN X'F5';
Dcl-C $PRINT X'F6';

// Constants - Boolean
Dcl-C $FALSE '0';
Dcl-C $TRUE '1';

// Data Structures

// API Error Structure
Dcl-DS APIERR;
  ERRSIZ Int(10) Inz(256);
  ERRLEN Int(10) Inz(0);
  ERRMIC Char(7) Inz;
  ERRNBR Char(1) Inz;
  ERRDTA Char(240) Inz;
End-DS;

// Message Data Structure
Dcl-DS *N;
  MSGCTR Int(10) Inz(0);
  MSGLEN Int(10) Inz(80);
  MSGF Char(20) Inz('FRSMSGF   *LIBL     ');
  MSGTYP Char(10) Inz('*INFO     ');
  MSGKEY Char(4) Inz('    ');
End-DS;

// Remove Message Data Structure
Dcl-DS *N;
  RMVCTR Int(10) Inz(0);
  RMVMSQ Char(10) Inz('*         ');
  RMVCLR Char(10) Inz('*ALL      ');
  RMVKEY Char(4) Inz('    ');
End-DS;

// Program Status Data Structure
Dcl-DS *N Psds;
  $PGM Char(10) Pos(1);
  $STAT Zoned(5:0) Pos(11);
  $PARMS Zoned(3:0) Pos(37);
  $MSGID Char(7) Pos(40);
  $DATA Char(79) Pos(91);
  $JOBNA Char(10) Pos(244);
  $USRNA Char(10) Pos(254);
  $JOBNO Char(6) Pos(264);
  $SRCF Char(10) Pos(304);
  $SRCL Char(10) Pos(314);
  $SRCM Char(10) Pos(324);
End-DS;

// Workstation Data Structure (File Info DS)
Dcl-DS WSDS;
  KEY Char(1) Pos(369);
  PAGRRN Int(5) Pos(378);
End-DS;

// Varying Length Data Structure
Dcl-DS *N;
  DFCTYA Char(18) Pos(1);
  DFCTYL Int(5) Pos(1);
  DFCTYN Char(16) Pos(3);
End-DS;

// Standalone Fields
Dcl-S ENDFCN Like(FRCNAM);
Dcl-S MSGID Char(7);
Dcl-S MSGDTA Char(80);
Dcl-S MSGQUE Char(10);
Dcl-S PGMQ Like(MSGQUE);
Dcl-S $EXIT Char(1);
Dcl-S SFLRN Packed(4:0);
Dcl-S ENDRN Packed(4:0);
Dcl-S SFLPS Like(SFLRN);

// Procedure Interface - Entry Parameters
Dcl-Pi *N;
  FRMCTY Char(16);  // Return city name
End-Pi;

// Prototypes for External Programs
Dcl-Pr QMHRMVPM ExtPgm('QMHRMVPM');
  *N Char(10) Const;  // Message queue
  *N Int(10) Const;   // Call message queue entry
  *N Char(4) Const;   // Message key
  *N Char(10) Const;  // Messages to remove
  *N LikeDs(APIERR);  // Error code
End-Pr;

Dcl-Pr QMHSNDPM ExtPgm('QMHSNDPM');
  *N Char(7) Const;   // Message ID
  *N Char(20) Const;  // Message file
  *N Char(80) Const;  // Message data
  *N Int(10) Const;   // Message data length
  *N Char(10) Const;  // Message type
  *N Char(10) Const;  // Message queue
  *N Int(10) Const;   // Call stack entry
  *N Char(4);         // Message key
  *N LikeDs(APIERR);  // Error code
End-Pr;

// Main Processing

Reset $EXIT;
Exsr $RMVMS;
Exsr $RESET;
Exsr $LOAD;

// Main Loop - Do until F3/F12
Dou $EXIT = $TRUE;

  Write FRSWIN;    // Write window
  Write FKEYS;     // Write function keys
  Write MSGCTL;    // Write message control
  Exfmt SFLCTL;    // Display subfile control

  *In50 = *Off;    // Reset error indicator

  SFLPS = PAGRRN;  // Set subfile position

  // Process function keys
  Select;
    When KEY = $F03;
      Exsr $F03SR;   // F03 Exit

    When KEY = $F12;
      Exsr $F12SR;   // F12 Cancel

    When KEY = $PAGDN;
      Exsr $PGDN;    // Page Down

    Other;
      Exsr $ENTKY;   // Enter
  EndSl;

  // Handle selection logic
  If SELIO <> '1';
    Iter;
  EndIf;

  If KEY = $PAGDN;
    Iter;
  EndIf;

  Exsr $RMVMS;  // Send error message

EndDo;

*InLR = *On;

// *INZSR - Initialization Subroutine
Begsr *InzSr;

  MSGID = ' ';
  MSGDTA = *Blanks;
  MSGQUE = $PGM;
  PGMQ = $PGM;

  $EXIT = $FALSE;  // Program exit = Off

  SFLRN = 0;
  ENDRN = 0;
  SFLPS = 1;

Endsr;

// $LOAD - Load Subfile
Begsr $LOAD;

  Dow *In99 = *Off;

    // Read up to 6 records per page
    If SFLRN - ENDRN >= 6;
      Leave;
    EndIf;

    Read FRCITY;

    If %Eof(FRCITY);
      *In99 = *On;
      Leave;
    EndIf;

    SFCTYN = FRCNAM;

    SFLRN += 1;
    Write SFL;  // Write subfile record

  EndDo;

  ENDFCN = FRCNAM;
  ENDRN = SFLRN;  // For file/subfile

  If Not %Eof(FRCITY);
    Read FRCITY;  // Read one more to make sure
  EndIf;

  If SFLRN = *Zeros;
    *In42 = *Off;  // No records to display
  Else;
    *In42 = *On;   // Display subfile
    SFLPS = SFLRN; // Set subfile position to page just added
  EndIf;

Endsr;

// $RESET - Reset Subfile
Begsr $RESET;

  *In40 = *On;
  Write FRSWIN;
  Write SFLCTL;
  *In40 = *Off;
  *In42 = *Off;

  Reset SFLRN;
  Reset ENDRN;
  Reset SFLPS;

Endsr;

// $REPOS - Reposition Subfile
Begsr $REPOS;

  Exsr $RESET;
  ENDFCN = FRCNAM;
  SetLL FRCNAM FRCITY;
  Exsr $LOAD;

Endsr;

// $PGDN - Page Down
Begsr $PGDN;

  If *In99 = *Off;
    SetGT ENDFCN FRCITY;
    SFLRN = ENDRN;
    Exsr $LOAD;
  Else;
    *In60 = *On;
  EndIf;

Endsr;

// $ENTKY - Enter Key Processing
Begsr $ENTKY;

  Exsr $RMVMS;  // Remove program messages

  ReadC SFL;

  // Process changed subfile records using %EOF to detect end
  Dow Not %Eof();

    If SELIO = '1';
      FRMCTY = SFCTYN;
      $EXIT = $TRUE;  // Set exit flag on
      Leave;
    EndIf;

    ReadC SFL;

  EndDo;

Endsr;

// $RMVMS - Remove Program Messages
Begsr $RMVMS;

  QMHRMVPM(RMVMSQ : RMVCTR : RMVKEY : RMVCLR : APIERR);

Endsr;

// $SNDMS - Send Program Message
Begsr $SNDMS;

  QMHSNDPM(MSGID : MSGF : MSGDTA : MSGLEN : MSGTYP : MSGQUE : MSGCTR : MSGKEY : APIERR);

Endsr;

// $F03SR - F3 Subroutine
Begsr $F03SR;

  $EXIT = $TRUE;  // Set exit flag on

Endsr;

// $F12SR - F12 Subroutine
Begsr $F12SR;

  $EXIT = $TRUE;  // Set exit flag on

Endsr;
