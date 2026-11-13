**FREE

//==================================================================
// Program: FRS402 - City Selection Subfile Program
// Purpose: Display list of cities in subfile for user selection
// Returns: Selected city name, international code, and airline code
//==================================================================

CTL-OPT DFTACTGRP(*NO) ACTGRP(*NEW)
        OPTION(*NODEBUGIO:*SRCSTMT)
        DATFMT(*ISO) TIMFMT(*ISO);

// File Declarations
DCL-F FRCITY DISK(*EXT) KEYED USAGE(*INPUT);
DCL-F FRS402DF WORKSTN SFILE(SFL:SFLRN) INFDS(WSDS);

// Entry Parameters
DCL-PI *N;
  FRMCTY CHAR(16);  // Return: City name
  FRMINT CHAR(3);   // Return: International code
  FRMAIR CHAR(3);   // Return: Airline code
END-PI;

// Function Key Constants
DCL-C $F01 x'31';
DCL-C $F03 x'33';
DCL-C $F09 x'39';
DCL-C $F12 x'3C';
DCL-C $ENTER x'F1';
DCL-C $HELP x'F3';
DCL-C $PAGUP x'F4';
DCL-C $PAGDN x'F5';
DCL-C $PRINT x'F6';

// Boolean Constants
DCL-C $FALSE '0';
DCL-C $TRUE '1';

// API Error Data Structure
DCL-DS APIERR;
  ERRSIZ INT(10) INZ(256);
  ERRLEN INT(10) INZ(0);
  ERRMIC CHAR(7);
  ERRNBR CHAR(1);
  ERRDTA CHAR(240);
END-DS;

// Message Data Structure
DCL-DS MSGDS;
  MSGCTR INT(10) INZ(0);
  MSGLEN INT(10) INZ(80);
  MSGF CHAR(20) INZ('FRSMSGF   *LIBL     ');
  MSGTYP CHAR(10) INZ('*INFO     ');
  MSGKEY CHAR(4) INZ('    ');
END-DS;

// Remove Message Data Structure
DCL-DS RMVDS;
  RMVCTR INT(10) INZ(0);
  RMVMSQ CHAR(10) INZ('*         ');
  RMVCLR CHAR(10) INZ('*ALL      ');
  RMVKEY CHAR(4) INZ('    ');
END-DS;

// Program Status Data Structure
DCL-DS *N PSDS;
  $PGM CHAR(10) POS(1);
  $STAT CHAR(5) POS(11);
  $PARMS ZONED(3:0) POS(37);
  $MSGID CHAR(7) POS(40);
  $DATA CHAR(80) POS(91);
  $JOBNA CHAR(10) POS(244);
  $USRNA CHAR(10) POS(254);
  $JOBNO CHAR(6) POS(264);
  $SRCF CHAR(10) POS(304);
  $SRCL CHAR(10) POS(314);
  $SRCM CHAR(10) POS(324);
END-DS;

// Workstation Data Structure
DCL-DS WSDS;
  KEY CHAR(1) POS(369);
  PAGRRN INT(5) POS(378);
END-DS;

// Global Variables
DCL-S $EXIT CHAR(1);
DCL-S SFLRN PACKED(4:0);
DCL-S ENDRN PACKED(4:0);
DCL-S SFLPS PACKED(4:0);
DCL-S FRCKEY CHAR(16);
DCL-S ENDKEY CHAR(16);
DCL-S MSGID CHAR(7);
DCL-S MSGDTA CHAR(80);
DCL-S MSGQUE CHAR(10);
DCL-S PGMQ CHAR(10);


//==================================================================
// Main Processing
//==================================================================

initialize();
$RMVMS();
$RESET();
$LOAD();

DOW $EXIT <> $TRUE;
  WRITE FRSWIN;
  WRITE FKEYS;
  WRITE MSGCTL;
  EXFMT SFLCTL;

  SFLPS = PAGRRN;

  SELECT;
    WHEN KEY = $F03;
      $F03SR();
    WHEN KEY = $F09;
      $F09SR();
    WHEN KEY = $F12;
      $F12SR();
    WHEN KEY = $PAGDN;
      $PGDN();
    OTHER;
      $ENTKY();
  ENDSL;
ENDDO;

*INLR = *ON;
RETURN;

//==================================================================
// initialize - Initialize Program Variables
//==================================================================
DCL-PROC initialize;

  *IN50 = *OFF;  // Reset error indicator

  ENDKEY = *BLANKS;

  MSGID = *BLANKS;
  MSGDTA = *BLANKS;
  MSGQUE = $PGM;
  PGMQ = $PGM;
  $EXIT = $FALSE;

  SFLRN = 0;
  ENDRN = 0;
  SFLPS = 1;

  FRCKEY = *BLANKS;
  FRCKEY = 'A';

  SETLL FRCKEY FRCITY;

END-PROC;

//==================================================================
// $LOAD - Load Subfile with Records
//==================================================================
DCL-PROC $LOAD;

  DCL-S i INT(10);

  // Read a page of records or until EOF
  FOR i = 1 TO 4;
    READ FRCITY;

    IF %EOF(FRCITY);
      LEAVE;
    ENDIF;

    SFCTYN = FRCNAM;
    SFCTYI = FRCINT;
    SFCTYA = FRCALN;

    SFLRN += 1;
    WRITE SFL;
  ENDFOR;

  ENDKEY = FRCNAM;
  ENDRN = SFLRN;

  // If not EOF, read one more to determine if more records exist
  IF NOT %EOF(FRCITY);
    READ FRCITY;
  ENDIF;

  // Set subfile display indicator
  IF SFLRN = 0;
    *IN42 = *OFF;
  ELSE;
    *IN42 = *ON;
    SFLPS = SFLRN;
  ENDIF;

END-PROC;

//==================================================================
// $RESET - Clear and Reinitialize Subfile
//==================================================================
DCL-PROC $RESET;

  *IN40 = *ON;
  WRITE FRSWIN;
  WRITE SFLCTL;
  *IN40 = *OFF;
  *IN42 = *OFF;

  SFLRN = 0;
  ENDRN = 0;
  SFLPS = 1;

END-PROC;

//==================================================================
// $REPOS - Reposition Subfile Based on Search Key
//==================================================================
DCL-PROC $REPOS;

  $RESET();

  IF SEARCH = *BLANKS;
    FRCKEY = FRCNAM;
  ENDIF;

  SETLL FRCKEY FRCITY;
  $LOAD();

END-PROC;

//==================================================================
// $PGDN - Page Down - Load Next Page of Records
//==================================================================
DCL-PROC $PGDN;

  IF NOT %EOF(FRCITY);
    SETGT ENDKEY FRCITY;
    SFLRN = ENDRN;
    $LOAD();
  ELSE;
    *IN60 = *ON;
  ENDIF;

END-PROC;

//==================================================================
// $ENTKY - Process Enter Key
//==================================================================
DCL-PROC $ENTKY;

  *IN50 = *OFF;  // Reset error indicator

  IF SEARCH <> *BLANKS;
    FRCKEY = SEARCH;
    $REPOS();
  ELSE;
    $SFLRD();
  ENDIF;

END-PROC;

//==================================================================
// $SFLRD - Read Subfile for Changed Records
//==================================================================
DCL-PROC $SFLRD;

  $RMVMS();

  READC(E) SFL;

  // Process changed records
  DOW NOT %EOF(FRS402DF);

    IF SELIO = '1';
      FRMCTY = SFCTYN;
      FRMINT = SFCTYI;
      FRMAIR = SFCTYA;
      $EXIT = $TRUE;
      LEAVE;
    ENDIF;

    READC(E) SFL;

  ENDDO;

END-PROC;

//==================================================================
// $RMVMS - Remove Program Messages
//==================================================================
DCL-PROC $RMVMS;

  DCL-PR QMHRMVPM EXTPGM;
    MessageQueue CHAR(10) CONST;
    CallStackCounter INT(10) CONST;
    MessageKey CHAR(4) CONST;
    MessagesToRemove CHAR(10) CONST;
    ErrorCode LIKEDS(APIERR);
  END-PR;

  QMHRMVPM(RMVMSQ : RMVCTR : RMVKEY : RMVCLR : APIERR);

END-PROC;

//==================================================================
// $SNDMS - Send Program Message
//==================================================================
DCL-PROC $SNDMS;

  DCL-PR QMHSNDPM EXTPGM;
    MessageID CHAR(7) CONST;
    MessageFile CHAR(20) CONST;
    MessageData CHAR(80) CONST;
    MessageDataLength INT(10) CONST;
    MessageType CHAR(10) CONST;
    MessageQueue CHAR(10) CONST;
    CallStackCounter INT(10) CONST;
    MessageKey CHAR(4);
    ErrorCode LIKEDS(APIERR);
  END-PR;

  QMHSNDPM(MSGID : MSGF : MSGDTA : MSGLEN : MSGTYP : MSGQUE :
           MSGCTR : MSGKEY : APIERR);

END-PROC;

//==================================================================
// $F03SR - Handle F3 Exit
//==================================================================
DCL-PROC $F03SR;

  $EXIT = $TRUE;

END-PROC;

//==================================================================
// $F09SR - Handle F9 Command Line
//==================================================================
DCL-PROC $F09SR;

  DCL-PR QUSCMDLN EXTPGM;
  END-PR;

  QUSCMDLN();

END-PROC;

//==================================================================
// $F12SR - Handle F12 Cancel
//==================================================================
DCL-PROC $F12SR;

  $EXIT = $TRUE;

END-PROC;
