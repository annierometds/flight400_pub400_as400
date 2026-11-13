**FREE

//==============================================================================
// Program: FRS413 - Flight Selection Subfile
// Description: Display available flights in a subfile and allow selection
// Converted from: FRS413.RPG (OPM) to ILE Free-Format
//==============================================================================

CTL-OPT DFTACTGRP(*NO) ACTGRP(*CALLER);
CTL-OPT OPTION(*NODEBUGIO : *SRCSTMT);

// File declarations
DCL-F FLIGHTSZ DISK(*EXT) KEYED USAGE(*INPUT) INFDS(flightInfds);
DCL-F FRS413DF WORKSTN SFILE(SFL:SFLRN) INFDS(wsds) INDDS(indicators);

// Named constants - Function keys
DCL-C F01 X'31';
DCL-C F03 X'33';
DCL-C F09 X'39';
DCL-C F12 X'3C';
DCL-C ENTER X'F1';
DCL-C HELP X'F3';
DCL-C PAGUP X'F4';
DCL-C PAGDN X'F5';
DCL-C PRINT X'F6';

// Named constants - Boolean
DCL-C TRUE '1';
DCL-C FALSE '0';

// Program parameters
DCL-PI *N;
  SFLGHT CHAR(90);    // Return flight number
  SDYOWK CHAR(9);     // Return day of week
  SFRCTY CHAR(16);    // Return from city
  STOCTY CHAR(16);    // Return to city
  SDPTHH CHAR(2);     // Return departure hour
  SDPTMM CHAR(2);     // Return departure minute
  SDPTAP CHAR(2);     // Return departure AM/PM
  SARRHH CHAR(2);     // Return arrival hour
  SARRMM CHAR(2);     // Return arrival minute
  SARRAP CHAR(2);     // Return arrival AM/PM
  SMILES CHAR(5);     // Return miles
  SAIRIN CHAR(3);     // Return airline
  SSEATS CHAR(3);     // Return seats available
  SPRICE CHAR(3);     // Return price code
END-PI;

// Indicator data structure
DCL-DS indicators;
  exitFlag IND POS(3);          // F3 pressed
  sflDsp IND POS(40);           // Subfile clear
  sflDspCtl IND POS(42);        // Subfile display control
  errorInd IND POS(50);         // Error indicator
  endOfPageMsg IND POS(60);     // End of page message
  searchChg IND POS(97);        // Search field changed
  sflEnd IND POS(98);           // Subfile end
  eof IND POS(99);              // End of file
END-DS;

// Work station device information
DCL-DS wsds;
  KEY CHAR(1) POS(369);         // Function key pressed
  PAGRRN INT(5) POS(378);       // Page relative record number
END-DS;

// File information data structure
DCL-DS flightInfds;
  // Add fields as needed
END-DS;

// API Error Data Structure
DCL-DS APIERR QUALIFIED;
  ERRSIZ INT(10) INZ(256);
  ERRLEN INT(10) INZ(0);
  ERRMIC CHAR(7);
  ERRNBR CHAR(1);
  ERRDTA CHAR(240);
END-DS;

// Message API Data Structures
DCL-DS msgApiData QUALIFIED;
  MSGCTR INT(10) INZ(0);
  MSGLEN INT(10) INZ(80);
  MSGF CHAR(20) INZ('FRSMSGF   *LIBL     ');
  MSGTYP CHAR(10) INZ('*INFO     ');
  MSGKEY CHAR(4) INZ('    ');
END-DS;

DCL-DS rmvApiData QUALIFIED;
  RMVCTR INT(10) INZ(0);
  RMVMSQ CHAR(10) INZ('*         ');
  RMVCLR CHAR(10) INZ('*ALL      ');
  RMVKEY CHAR(4) INZ('    ');
END-DS;

// Program status data structure
DCL-DS PSDS PSDS QUALIFIED;
  PGM CHAR(10) POS(1);
  STAT CHAR(5) POS(11);
  PARMS ZONED(3) POS(37);
  MSGID CHAR(7) POS(40);
  DATA CHAR(80) POS(91);
  JOBNA CHAR(10) POS(244);
  USRNA CHAR(10) POS(264);
  JOBNO CHAR(6) POS(264);
  SRCF CHAR(10) POS(304);
  SRCL CHAR(10) POS(314);
  SRCM CHAR(10) POS(324);
END-DS;

// Flight record data structure - externally described from FLIGHTSZ
DCL-DS flightData LIKEREC(FLGHTR:*INPUT);

// Subfile record keys
DCL-S FLTKEY ZONED(9:0);
DCL-S ENDFLT ZONED(9:0);

// Subfile control fields
DCL-S SFLRN INT(5) INZ(0);
DCL-S ENDRN INT(5) INZ(0);
DCL-S SFLPS ZONED(4:0) INZ(1);
DCL-S SEARCH ZONED(9:0);

// Message API fields
DCL-S MSG_ID CHAR(7);
DCL-S MSG_DTA CHAR(80);
DCL-S MSG_QUE CHAR(10);
DCL-S PGM_Q CHAR(10);

// Program control variables
DCL-S exitPgm IND INZ(*OFF);

// Subfile display fields
DCL-S FLGHTN ZONED(9:0);
DCL-S FRCITY CHAR(16);
DCL-S TOCITY CHAR(16);
DCL-S DPCINT CHAR(3);
DCL-S ARCINT CHAR(3);
DCL-S DYOFWK CHAR(2);
DCL-S DYOFW9 CHAR(9);
DCL-S DPTIME CHAR(8);
DCL-S ARTIME CHAR(8);
DCL-S AIRLNM CHAR(3);
DCL-S PRICE CHAR(3);
DCL-S MILES PACKED(5:0);
DCL-S SEATS PACKED(3:0);
DCL-S SELIO CHAR(1);

// Working storage for data manipulation
DCL-DS ddpcnData QUALIFIED;
  full CHAR(18);
  length INT(5) POS(1);
  name CHAR(16) POS(3);
END-DS;

DCL-DS darcnData QUALIFIED;
  full CHAR(18);
  length INT(5) POS(1);
  name CHAR(16) POS(3);
END-DS;

DCL-DS dyowkData QUALIFIED;
  full CHAR(18);
  length INT(5) POS(1);
  abbrev CHAR(2) POS(3);
  fullName CHAR(9) POS(3);
  rest CHAR(7) POS(12);
END-DS;

DCL-DS dpcinData QUALIFIED;
  full CHAR(18);
  length INT(5) POS(1);
  code CHAR(3) POS(3);
  blank CHAR(13) POS(6);
END-DS;

DCL-DS arcinData QUALIFIED;
  full CHAR(18);
  length INT(5) POS(1);
  code CHAR(3) POS(3);
  blank CHAR(13) POS(6);
END-DS;

DCL-DS priceData QUALIFIED;
  full CHAR(24);
  length INT(5) POS(1);
  code CHAR(3) POS(3);
  blank CHAR(19) POS(6);
END-DS;

DCL-DS dptimData QUALIFIED;
  full CHAR(34);
  length INT(5) POS(1);
  time8 CHAR(8) POS(3);
  hours CHAR(2) POS(3);
  minutes CHAR(2) POS(6);
  ampm CHAR(2) POS(9);
  rest CHAR(24) POS(11);
END-DS;

DCL-DS artimData QUALIFIED;
  full CHAR(34);
  length INT(5) POS(1);
  time8 CHAR(8) POS(3);
  hours CHAR(2) POS(3);
  minutes CHAR(2) POS(6);
  ampm CHAR(2) POS(9);
  rest CHAR(24) POS(11);
END-DS;

DCL-DS airlnData QUALIFIED;
  full CHAR(34);
  length INT(5) POS(1);
  code CHAR(3) POS(3);
  rest CHAR(29) POS(6);
END-DS;

//==============================================================================
// Main Processing
//==============================================================================

// Initialize program
initialize();

// Remove any previous messages
removeMessages();

// Reset and load subfile
resetSubfile();
loadSubfile();

// Main display loop
exitPgm = *OFF;
DOW NOT exitPgm;
  WRITE FRSWIN;      // Write window
  WRITE FKEYS;       // Write function keys
  WRITE MSGCTL;      // Write message control
  EXFMT SFLCTL;      // Display subfile control

  SFLPS = PAGRRN;    // Save current position

  // Process function key
  SELECT;
    WHEN KEY = F03;
      handleF03();
    WHEN KEY = F09;
      handleF09();
    WHEN KEY = F12;
      handleF12();
    WHEN KEY = PAGDN;
      handlePageDown();
    OTHER;
      handleEnter();
  ENDSL;
ENDDO;

*INLR = *ON;
RETURN;

//==============================================================================
// Subprocedures
//==============================================================================

// Initialize program
DCL-PROC initialize;
  errorInd = *OFF;

  MSG_ID = *BLANKS;
  MSG_DTA = *BLANKS;
  MSG_QUE = PSDS.PGM;
  PGM_Q = PSDS.PGM;
  exitPgm = *OFF;

  SFLRN = 0;
  ENDRN = 0;
  SFLPS = 1;

  FLTKEY = 0;
  SETLL FLTKEY FLIGHTSZ;
END-PROC;

// Load subfile with records
DCL-PROC loadSubfile;
  DCL-S counter INT(5);

  // Read a page of records or until EOF
  FOR counter = 1 TO 9;
    READ FLIGHTSZ;
    IF %EOF(FLIGHTSZ);
      LEAVE;
    ENDIF;

    // Move data from file record to subfile fields
    FLGHTN = flightData.FLGHTN;

    // Use %SUBST to extract data from VARCHAR fields
    FRCITY = %SUBST(flightData.DPCNAM:1:16);
    DPCINT = %SUBST(flightData.DPCINT:1:3);

    TOCITY = %SUBST(flightData.ARCNAM:1:16);
    ARCINT = %SUBST(flightData.ARCINT:1:3);

    DYOFWK = %SUBST(flightData.DYOFWK:1:2);
    DYOFW9 = %SUBST(flightData.DYOFWK:1:9);

    DPTIME = %SUBST(flightData.DPTIME:1:8);
    ARTIME = %SUBST(flightData.ARTIME:1:8);

    AIRLNM = %SUBST(flightData.AIRLNM:1:3);
    PRICE = %SUBST(flightData.TCKTPR:1:3);

    MILES = flightData.MILES;
    SEATS = flightData.SEATS;

    SFLRN += 1;
    WRITE SFL;
  ENDFOR;

  // Save end keys
  ENDFLT = flightData.FLGHTN;
  ENDRN = SFLRN;

  // Check if there are more records
  IF NOT %EOF(FLIGHTSZ);
    READ FLIGHTSZ;
  ENDIF;

  // Set display indicators
  IF SFLRN = 0;
    sflDspCtl = *OFF;
  ELSE;
    sflDspCtl = *ON;
    SFLPS = SFLRN;
  ENDIF;
END-PROC;

// Reset subfile
DCL-PROC resetSubfile;
  sflDsp = *ON;
  WRITE FRSWIN;
  WRITE SFLCTL;
  sflDsp = *OFF;
  sflDspCtl = *OFF;

  SFLRN = 0;
  ENDRN = 0;
  SFLPS = 1;
END-PROC;

// Reposition subfile
DCL-PROC repositionSubfile;
  resetSubfile();

  IF SEARCH = 0;
    FLTKEY = flightData.FLGHTN;
  ENDIF;

  SETLL FLTKEY FLIGHTSZ;
  loadSubfile();
END-PROC;

// Handle page down
DCL-PROC handlePageDown;
  IF NOT %EOF(FLIGHTSZ);
    SETGT ENDFLT FLIGHTSZ;
    SFLRN = ENDRN;
    loadSubfile();
  ELSE;
    endOfPageMsg = *ON;
  ENDIF;
END-PROC;

// Handle Enter key
DCL-PROC handleEnter;
  errorInd = *OFF;

  IF SEARCH <> 0;
    FLTKEY = SEARCH;
    repositionSubfile();
  ELSE;
    readSubfile();
  ENDIF;
END-PROC;

// Read changed subfile records
DCL-PROC readSubfile;
  removeMessages();

  READC SFL;

  IF searchChg;
    repositionSubfile();
    RETURN;
  ENDIF;

  DOW NOT sflEnd;
    IF SELIO = '1';
      // Return selected flight information
      SFLGHT = %EDITC(FLGHTN:'X');
      SFRCTY = FRCITY;
      STOCTY = TOCITY;
      SDYOWK = DYOFW9;

      dptimData.full = DPTIME;
      SDPTHH = dptimData.hours;
      SDPTMM = dptimData.minutes;
      SDPTAP = dptimData.ampm;

      artimData.full = ARTIME;
      SARRHH = artimData.hours;
      SARRMM = artimData.minutes;
      SARRAP = artimData.ampm;

      SAIRIN = AIRLNM;
      SPRICE = PRICE;
      SMILES = %CHAR(MILES);
      SSEATS = %CHAR(SEATS);

      exitPgm = *ON;
      LEAVE;
    ENDIF;

    READC SFL;

    IF searchChg;
      repositionSubfile();
      sendMessage();
      LEAVE;
    ENDIF;
  ENDDO;
END-PROC;

// Remove program messages
DCL-PROC removeMessages;
  DCL-PR QMHRMVPM EXTPGM;
    messageQueue CHAR(10) CONST;
    callStackCounter INT(10) CONST;
    messageKey CHAR(4) CONST;
    messagesToRemove CHAR(10) CONST;
    errorCode LIKEDS(APIERR);
  END-PR;

  QMHRMVPM(rmvApiData.RMVMSQ : rmvApiData.RMVCTR :
           rmvApiData.RMVKEY : rmvApiData.RMVCLR : APIERR);
END-PROC;

// Send program message
DCL-PROC sendMessage;
  DCL-PR QMHSNDPM EXTPGM;
    messageId CHAR(7) CONST;
    messageFile CHAR(20) CONST;
    messageData CHAR(80) CONST;
    messageDataLen INT(10) CONST;
    messageType CHAR(10) CONST;
    callStackEntry CHAR(10) CONST;
    callStackCounter INT(10) CONST;
    messageKey CHAR(4);
    errorCode LIKEDS(APIERR);
  END-PR;

  QMHSNDPM(MSG_ID : msgApiData.MSGF : MSG_DTA : msgApiData.MSGLEN :
           msgApiData.MSGTYP : MSG_QUE : msgApiData.MSGCTR :
           msgApiData.MSGKEY : APIERR);
END-PROC;

// Handle F3 - Exit
DCL-PROC handleF03;
  exitPgm = *ON;
END-PROC;

// Handle F9 - Command line
DCL-PROC handleF09;
  DCL-PR QUSCMDLN EXTPGM END-PR;
  QUSCMDLN();
END-PROC;

// Handle F12 - Cancel
DCL-PROC handleF12;
  exitPgm = *ON;
END-PROC;
