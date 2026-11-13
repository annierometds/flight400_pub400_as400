**FREE

// =====================================================================
// Program: FRS412
// Description: Airline Selection with Subfile
// Converted from OPM RPG to ILE RPG with fully free-format
// =====================================================================

CTL-OPT DFTACTGRP(*NO) ACTGRP(*NEW);

DCL-F AIRLINE DISK(*EXT) KEYED USAGE(*INPUT);
DCL-F FRS412DF WORKSTN SFILE(SFL:subfileRecordNumber) INFDS(wsds);

// =====================================================================
// Function Key Constants
// =====================================================================
DCL-C $F01 x'31';
DCL-C $F03 x'33';
DCL-C $F12 x'3C';
DCL-C $ENTER x'F1';
DCL-C $HELP x'F3';
DCL-C $PAGUP x'F4';
DCL-C $PAGDN x'F5';
DCL-C $PRINT x'F6';

// Boolean Constants
DCL-C $FALSE '0';
DCL-C $TRUE '1';

// =====================================================================
// Program Interface
// =====================================================================
DCL-PI *N;
  returnAirlineName CHAR(16);  // Return airline name
  returnAirlineCode CHAR(3);   // Return airline code
END-PI;

// =====================================================================
// API Error Data Structure
// =====================================================================
DCL-DS apierr;
  errsiz INT(10) INZ(256);
  errlen INT(10) INZ(0);
  errmic CHAR(7);
  errnbr CHAR(1);
  errdta CHAR(240);
END-DS;

// =====================================================================
// Message Handling Data Structure
// =====================================================================
DCL-DS *N;
  msgctr INT(10) INZ(0);
  msglen INT(10) INZ(80);
  msgf CHAR(20) INZ('FRSMSGF   *LIBL     ');
  msgtyp CHAR(10) INZ('*INFO     ');
  msgkey CHAR(4) INZ('    ');
END-DS;

// =====================================================================
// Remove Message Data Structure
// =====================================================================
DCL-DS *N;
  rmvctr INT(10) INZ(0);
  rmvmsq CHAR(10) INZ('*         ');
  rmvclr CHAR(10) INZ('*ALL      ');
  rmvkey CHAR(4) INZ('    ');
END-DS;

// =====================================================================
// Program Status Data Structure
// =====================================================================
DCL-DS *N PSDS;
  $pgm CHAR(10) POS(1);
  $stat CHAR(5) POS(11);
  $parms ZONED(3:0) POS(37);
  $msgid CHAR(7) POS(40);
  $data CHAR(80) POS(91);
  $jobna CHAR(10) POS(244);
  $usrna CHAR(10) POS(254);
  $jobno CHAR(6) POS(264);
  $srcf CHAR(10) POS(304);
  $srcl CHAR(10) POS(314);
  $srcm CHAR(10) POS(324);
END-DS;

// =====================================================================
// Workstation Data Structure
// =====================================================================
DCL-DS wsds;
  functionKey CHAR(1) POS(369);
  pageRelativeRecordNumber INT(5) POS(378);
END-DS;

// =====================================================================
// API Prototypes
// =====================================================================
DCL-PR QMHRMVPM EXTPGM;
  messageQueue CHAR(10) CONST;
  callStackCounter INT(10) CONST;
  messageKey CHAR(4) CONST;
  messagesToRemove CHAR(10) CONST;
  errorCode LIKEDS(apierr);
END-PR;

DCL-PR QMHSNDPM EXTPGM;
  messageId CHAR(7) CONST;
  qualifiedMsgF CHAR(20) CONST;
  messageData CHAR(80) CONST;
  messageDataLen INT(10) CONST;
  messageType CHAR(10) CONST;
  callStackEntry CHAR(10) CONST;
  callStackCounter INT(10) CONST;
  messageKey CHAR(4);
  errorCode LIKEDS(apierr);
END-PR;

// =====================================================================
// Global Variables
// =====================================================================
DCL-S exitProgram IND INZ($FALSE);
DCL-S subfileRecordNumber INT(10) INZ(0);
DCL-S endingRecordNumber INT(10) INZ(0);
DCL-S subfilePosition INT(10) INZ(1);
DCL-S lastAirlineName CHAR(16);
DCL-S messageId CHAR(7);
DCL-S messageData CHAR(80);
DCL-S messageQueue CHAR(10);
DCL-S programQueue CHAR(10);

// Indicators
DCL-S clearSubfile IND;
DCL-S displaySubfile IND;
DCL-S errorIndicator IND;
DCL-S bottomOfPage IND;
DCL-S subfileChanged IND;
DCL-S endOfSubfile IND;
DCL-S endOfFile IND;

// =====================================================================
// Main Program Logic
// =====================================================================

initializeProgram();

exitProgram = $FALSE;
removeMessages();
resetSubfile();
loadSubfile();

DOW exitProgram = $FALSE;

  WRITE FRSWIN;
  WRITE FKEYS;
  WRITE MSGCTL;
  EXFMT SFLCTL;

  errorIndicator = *OFF;  // Reset error indicator

  subfilePosition = pageRelativeRecordNumber;

  // Process function keys
  SELECT;
    WHEN functionKey = $F03;
      handleF03();
    WHEN functionKey = $F12;
      handleF12();
    WHEN functionKey = $PAGDN;
      pageDown();
    OTHER;
      handleEnter();
  ENDSL;

  // Check for selection without page down
  IF selio <> '1' OR functionKey = $PAGDN;
    // Continue loop
  ELSE;
    removeMessages();
  ENDIF;

ENDDO;

*INLR = *ON;

// =====================================================================
// Procedure: initializeProgram
// Description: Initialize program variables and settings
// =====================================================================
DCL-PROC initializeProgram;

  messageId = ' ';
  messageData = *BLANKS;
  messageQueue = $pgm;
  programQueue = $pgm;

  exitProgram = $FALSE;

  subfileRecordNumber = 0;
  endingRecordNumber = 0;
  subfilePosition = 1;

END-PROC;

// =====================================================================
// Procedure: loadSubfile
// Description: Load subfile with airline records
// =====================================================================
DCL-PROC loadSubfile;
  DCL-S recordCount INT(10);

  FOR recordCount = 1 TO 6;
    READ AIRLINE;

    IF %EOF(AIRLINE);
      LEAVE;
    ENDIF;

    airnam = airlnm;
    airint = airlin;

    subfileRecordNumber += 1;
    WRITE SFL;
  ENDFOR;

  lastAirlineName = airlnm;
  endingRecordNumber = subfileRecordNumber;

  IF NOT %EOF(AIRLINE);
    READ AIRLINE;  // Read one more to check for more records
  ENDIF;

  IF subfileRecordNumber = 0;
    displaySubfile = *OFF;  // No records to display
  ELSE;
    displaySubfile = *ON;   // Display subfile
    subfilePosition = subfileRecordNumber; // Position to last record added
  ENDIF;

END-PROC;

// =====================================================================
// Procedure: resetSubfile
// Description: Clear and reset the subfile
// =====================================================================
DCL-PROC resetSubfile;

  clearSubfile = *ON;
  WRITE FRSWIN;
  WRITE SFLCTL;
  clearSubfile = *OFF;
  displaySubfile = *OFF;

  subfileRecordNumber = 0;
  endingRecordNumber = 0;
  subfilePosition = 0;

END-PROC;

// =====================================================================
// Procedure: repositionSubfile
// Description: Reposition subfile to specific record
// =====================================================================
DCL-PROC repositionSubfile;

  resetSubfile();
  lastAirlineName = airlnm;
  SETLL airlnm AIRLINE;
  loadSubfile();

END-PROC;

// =====================================================================
// Procedure: pageDown
// Description: Handle page down request
// =====================================================================
DCL-PROC pageDown;

  IF NOT %EOF(AIRLINE);
    SETGT lastAirlineName AIRLINE;
    subfileRecordNumber = endingRecordNumber;
    loadSubfile();
  ELSE;
    bottomOfPage = *ON;
  ENDIF;

END-PROC;

// =====================================================================
// Procedure: handleEnter
// Description: Process Enter key - handle selection
// =====================================================================
DCL-PROC handleEnter;

  removeMessages();

  READC SFL;

  IF subfileChanged = '1';
    repositionSubfile();
    sendMessage();
    RETURN;
  ENDIF;

  DOW endOfSubfile = *OFF;

    IF selio = '1';
      returnAirlineName = airnam;
      returnAirlineCode = airint;
      exitProgram = $TRUE;
      LEAVE;
    ENDIF;

    READC SFL;

    IF subfileChanged = '1';
      repositionSubfile();
      removeMessages();
      sendMessage();
      LEAVE;
    ENDIF;

  ENDDO;

END-PROC;

// =====================================================================
// Procedure: removeMessages
// Description: Remove all messages from program message queue
// =====================================================================
DCL-PROC removeMessages;

  QMHRMVPM(rmvmsq : rmvctr : rmvkey : rmvclr : apierr);

END-PROC;

// =====================================================================
// Procedure: sendMessage
// Description: Send message to program message queue
// =====================================================================
DCL-PROC sendMessage;

  QMHSNDPM(messageId : msgf : messageData : msglen : msgtyp :
           messageQueue : msgctr : msgkey : apierr);

END-PROC;

// =====================================================================
// Procedure: handleF03
// Description: Handle F3 exit key
// =====================================================================
DCL-PROC handleF03;

  exitProgram = $TRUE;

END-PROC;

// =====================================================================
// Procedure: handleF12
// Description: Handle F12 cancel key
// =====================================================================
DCL-PROC handleF12;

  exitProgram = $TRUE;

END-PROC;
