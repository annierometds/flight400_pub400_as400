**FREE

//==============================================================================
// Program: FRS021 - Flight Schedule Maintenance
// Description: Interactive maintenance program for managing flight schedules
//              Supports add, update, and delete operations
//
// Modernized: Full conversion to ILE RPGLE free-format
//             - Replaced all indicators with boolean variables
//             - Converted subroutines to subprocedures
//             - Modernized file I/O and data structures
//             - Improved error handling and validation
//==============================================================================

CTL-OPT DFTACTGRP(*NO) ACTGRP(*NEW);

// File Declarations
DCL-F FRS021DF WORKSTN INFDS(wsds);
DCL-F AIRLINE DISK(*EXT) KEYED USAGE(*INPUT);
DCL-F AIRLINL DISK(*EXT) KEYED USAGE(*INPUT) RENAME(AIRLINER:AIRLINEL);
DCL-F FLIGHTSZ DISK(*EXT) KEYED USAGE(*UPDATE:*OUTPUT:*DELETE);
DCL-F FRCITY DISK(*EXT) KEYED USAGE(*INPUT) RENAME(CITYR:FRCTYR);
DCL-F TOCITY DISK(*EXT) KEYED USAGE(*INPUT) RENAME(CITYR:TOCTYR);

// Named Constants
DCL-C TRUE *ON;
DCL-C FALSE *OFF;

// Function Key Constants
DCL-C KEY_F02 X'32';
DCL-C KEY_F03 X'33';
DCL-C KEY_F04 X'34';
DCL-C KEY_F06 X'36';
DCL-C KEY_F07 X'37';
DCL-C KEY_F08 X'38';
DCL-C KEY_F09 X'39';
DCL-C KEY_F10 X'3A';
DCL-C KEY_F11 X'3B';
DCL-C KEY_F12 X'3C';
DCL-C KEY_ENTER X'F1';

// Day of Week Table
DCL-S dayTable CHAR(9) DIM(7) CTDATA PERRCD(1);

// Boolean Flags
DCL-S exitProgram IND INZ(FALSE);
DCL-S recordFound IND;
DCL-S errorOccurred IND INZ(FALSE);

// Display File Indicators (mapped to screen)
DCL-S errFlightNum IND; // 50
DCL-S errDayOfWeek IND; // 51
DCL-S errFromCity IND;  // 52
DCL-S errToCity IND;    // 53
DCL-S errDepTime IND;   // 54
DCL-S errArrTime IND;   // 55
DCL-S errMiles IND;     // 56
DCL-S errAirline IND;   // 57
DCL-S errSeats IND;     // 58
DCL-S errPrice IND;     // 59

// Workstation Data Structure
DCL-DS wsds;
  functionKey CHAR(1) POS(369);
END-DS;

// Program Status Data Structure
DCL-DS pgmSDS PSDS;
  pgmName *PROC;
  pgmStatus *STATUS;
  pgmUser CHAR(10) POS(254);
  jobName CHAR(10) POS(244);
  jobNumber CHAR(6) POS(264);
END-DS;

// API Error Data Structure
DCL-DS apiError;
  errBytesProvided INT(10) INZ(256);
  errBytesAvail INT(10) INZ(0);
  errMsgId CHAR(7);
  errReserved CHAR(1);
  errMsgData CHAR(240);
END-DS;

// Message Handling Data Structures
DCL-DS msgInfo;
  msgStackCtr INT(10) INZ(0);
  msgLength INT(10) INZ(80);
  msgFile CHAR(20) INZ('FRSMSGF   *LIBL   ');
  msgType CHAR(10) INZ('*INFO');
  msgKey CHAR(4) INZ('    ');
END-DS;

DCL-DS removeMsg;
  rmvStackCtr INT(10) INZ(0);
  rmvMsgQueue CHAR(10) INZ('*');
  rmvType CHAR(10) INZ('*ALL');
  rmvKey CHAR(4) INZ('    ');
END-DS;

// Working Variables
DCL-S msgId CHAR(7);
DCL-S msgData CHAR(80);
DCL-S msgQueue CHAR(10);
DCL-S pgmQueue CHAR(10);

// Data Structures for Field Formatting
DCL-DS depIntCode;
  depIntLen INT(5) POS(1) INZ(3);
  depIntFill CHAR(3) POS(3);
  depInt3 CHAR(3) POS(3);
  depIntName CHAR(16) POS(3);
END-DS;

DCL-DS arrIntCode;
  arrIntLen INT(5) POS(1) INZ(3);
  arrIntFill CHAR(3) POS(3);
  arrInt3 CHAR(3) POS(3);
  arrIntName CHAR(16) POS(3);
END-DS;

DCL-DS airlineKey;
  airlineLen INT(5) POS(1) INZ(3);
  airline3 CHAR(3) POS(3);
  airlineName CHAR(32) POS(3);
END-DS;

DCL-DS depCityCode;
  depCityLen INT(5) POS(1) INZ(0);
  depCityName CHAR(16) POS(3);
END-DS;

DCL-DS arrCityCode;
  arrCityLen INT(5) POS(1) INZ(0);
  arrCityName CHAR(16) POS(3);
END-DS;

DCL-DS dayOfWeek;
  dayLen INT(5) POS(1) INZ(0);
  dayName CHAR(16) POS(3);
END-DS;

DCL-DS ticketPrice;
  ticketLen INT(5) POS(1) INZ(0);
  ticketName CHAR(22) POS(3);
END-DS;

//==============================================================================
// Main Program Logic
//==============================================================================

initialize();

DOW NOT exitProgram;
  WRITE MSGCTL;
  EXFMT SELCTR;

  SELECT;
    WHEN functionKey = KEY_F02;
      refreshScreen();

    WHEN functionKey = KEY_F03;
      exitProgram = TRUE;

    WHEN functionKey = KEY_F04;
      promptAllFields();

    WHEN functionKey = KEY_F06;
      promptFromCity();

    WHEN functionKey = KEY_F07;
      promptToCity();

    WHEN functionKey = KEY_F08;
      promptAirline();

    WHEN functionKey = KEY_F09;
      callCommandLine();

    WHEN functionKey = KEY_F10;
      IF validateInput();
        addOrUpdateFlight();
        refreshScreen();
      ENDIF;

    WHEN functionKey = KEY_F11;
      IF validateInput();
        deleteFlight();
        refreshScreen();
      ENDIF;

    WHEN functionKey = KEY_F12;
      exitProgram = TRUE;

    OTHER;
      validateInput();
  ENDSL;
ENDDO;

*INLR = TRUE;

//==============================================================================
// Subprocedures
//==============================================================================

//------------------------------------------------------------------------------
// Initialize program
//------------------------------------------------------------------------------
DCL-PROC initialize;
  clearErrorIndicators();

  msgId = ' ';
  msgData = *BLANKS;
  msgQueue = pgmName;
  exitProgram = FALSE;
  pgmQueue = pgmName;

  // Initialize time fields
  SDPTHH = '00';
  SDPTMM = '00';
  SDPTAP = 'PM';
  SARRHH = '00';
  SARRMM = '00';
  SARRAP = 'PM';
END-PROC;

//------------------------------------------------------------------------------
// Clear all error indicators
//------------------------------------------------------------------------------
DCL-PROC clearErrorIndicators;
  errFlightNum = FALSE;
  errDayOfWeek = FALSE;
  errFromCity = FALSE;
  errToCity = FALSE;
  errDepTime = FALSE;
  errArrTime = FALSE;
  errMiles = FALSE;
  errAirline = FALSE;
  errSeats = FALSE;
  errPrice = FALSE;
  errorOccurred = FALSE;
END-PROC;

//------------------------------------------------------------------------------
// Map boolean indicators to display file indicators
//------------------------------------------------------------------------------
DCL-PROC setDisplayIndicators;
  *IN50 = errFlightNum;
  *IN51 = errDayOfWeek;
  *IN52 = errFromCity;
  *IN53 = errToCity;
  *IN54 = errDepTime;
  *IN55 = errArrTime;
  *IN56 = errMiles;
  *IN57 = errAirline;
  *IN58 = errSeats;
  *IN59 = errPrice;
END-PROC;

//------------------------------------------------------------------------------
// Validate all input fields
//------------------------------------------------------------------------------
DCL-PROC validateInput;
  DCL-PI *N IND;
  END-PI;

  clearErrorIndicators();
  removeMessages();

  // Validate flight number
  IF SFLGHT = *ZEROS;
    errFlightNum = TRUE;
    msgId = 'FRS0021';
    sendMessage();
    errorOccurred = TRUE;
  ENDIF;

  // Validate day of week
  IF SDYOWK = *BLANKS;
    errDayOfWeek = TRUE;
    msgId = 'FRS0022';
    sendMessage();
    errorOccurred = TRUE;
  ELSE;
    recordFound = %LOOKUP(SDYOWK : dayTable) > 0;
    IF NOT recordFound;
      errDayOfWeek = TRUE;
      msgId = 'FRS0023';
      sendMessage();
      errorOccurred = TRUE;
    ENDIF;
  ENDIF;

  // Validate from city
  IF SFRCTY = *BLANKS;
    errFromCity = TRUE;
    msgId = 'FRS0061';
    sendMessage();
    errorOccurred = TRUE;
  ELSE;
    CHAIN SFRCTY FRCTYR;
    IF NOT %FOUND(FRCITY);
      errFromCity = TRUE;
      msgId = 'FRS0062';
      sendMessage();
      errorOccurred = TRUE;
    ELSE;
      SFRINT = FRCINT;
    ENDIF;
  ENDIF;

  // Validate to city
  IF STOCTY = *BLANKS;
    errToCity = TRUE;
    msgId = 'FRS0071';
    sendMessage();
    errorOccurred = TRUE;
  ELSE;
    CHAIN STOCTY TOCTYR;
    IF NOT %FOUND(TOCITY);
      errToCity = TRUE;
      msgId = 'FRS0072';
      sendMessage();
      errorOccurred = TRUE;
    ELSE;
      STOINT = TOCINT;
    ENDIF;
  ENDIF;

  // Validate departure time
  IF SDPTHH = '00' AND SDPTMM = '00';
    errDepTime = TRUE;
    msgId = 'FRS0024';
    sendMessage();
    errorOccurred = TRUE;
  ENDIF;

  IF SDPTHH > '12' OR SDPTMM > '59';
    errDepTime = TRUE;
    msgId = 'FRS0024';
    sendMessage();
    errorOccurred = TRUE;
  ENDIF;

  IF SDPTAP <> 'AM' AND SDPTAP <> 'PM';
    errDepTime = TRUE;
    msgId = 'FRS0024';
    sendMessage();
    errorOccurred = TRUE;
  ENDIF;

  // Validate arrival time
  IF SARRHH = '00' AND SARRMM = '00';
    errArrTime = TRUE;
    msgId = 'FRS0024';
    sendMessage();
    errorOccurred = TRUE;
  ENDIF;

  IF SARRHH > '12' OR SARRMM > '59';
    errArrTime = TRUE;
    msgId = 'FRS0024';
    sendMessage();
    errorOccurred = TRUE;
  ENDIF;

  IF SARRAP <> 'AM' AND SARRAP <> 'PM';
    errArrTime = TRUE;
    msgId = 'FRS0024';
    sendMessage();
    errorOccurred = TRUE;
  ENDIF;

  // Validate miles
  IF SMILES = *ZEROS;
    errMiles = TRUE;
    msgId = 'FRS0025';
    sendMessage();
    errorOccurred = TRUE;
  ENDIF;

  // Validate airline
  IF SAIRLN = *BLANKS;
    errAirline = TRUE;
    msgId = 'FRS0041';
    sendMessage();
    errorOccurred = TRUE;
  ELSE;
    CHAIN SAIRLN AIRLINE;
    IF NOT %FOUND(AIRLINE);
      errAirline = TRUE;
      msgId = 'FRS0042';
      sendMessage();
      errorOccurred = TRUE;
    ENDIF;
  ENDIF;

  // Validate seats
  IF SSEATS = *ZEROS;
    errSeats = TRUE;
    msgId = 'FRS0083';
    sendMessage();
    errorOccurred = TRUE;
  ENDIF;

  // Validate price
  IF SPRICE = *BLANKS;
    errPrice = TRUE;
    msgId = 'FRS0084';
    sendMessage();
    errorOccurred = TRUE;
  ENDIF;

  setDisplayIndicators();

  RETURN NOT errorOccurred;
END-PROC;

//------------------------------------------------------------------------------
// Add or update flight record
//------------------------------------------------------------------------------
DCL-PROC addOrUpdateFlight;
  CHAIN SFLGHT FLIGHTSZ;

  IF %FOUND(FLIGHTSZ);
    updateFlightRecord();
  ELSE;
    addFlightRecord();
  ENDIF;
END-PROC;

//------------------------------------------------------------------------------
// Add new flight record
//------------------------------------------------------------------------------
DCL-PROC addFlightRecord;
  DCL-S fflght PACKED(9:0);
  DCL-S fdpcin CHAR(18);
  DCL-S fdpcnm CHAR(18);
  DCL-S fdyowk CHAR(18);
  DCL-S farcin CHAR(18);
  DCL-S farcnm CHAR(18);
  DCL-S fdpttm CHAR(34);
  DCL-S farvtm CHAR(34);
  DCL-S fairln CHAR(34);
  DCL-S fseats PACKED(4:0);
  DCL-S ftcktp CHAR(24);
  DCL-S fmiles PACKED(4:0);

  fflght = SFLGHT;

  // Format departure international code
  CLEAR depIntCode;
  depIntLen = 3;
  depInt3 = SFRINT;
  fdpcin = depIntCode;

  // Format departure city
  CLEAR depCityCode;
  depCityLen = %CHECKR(' ' : SFRCTY);
  depCityName = SFRCTY;
  fdpcnm = depCityCode;

  // Format arrival international code
  CLEAR arrIntCode;
  arrIntLen = 3;
  arrInt3 = STOINT;
  farcin = arrIntCode;

  // Format arrival city
  CLEAR arrCityCode;
  arrCityLen = %CHECKR(' ' : STOCTY);
  arrCityName = STOCTY;
  farcnm = arrCityCode;

  // Format day of week
  CLEAR dayOfWeek;
  dayLen = %CHECKR(' ' : SDYOWK);
  dayName = SDYOWK;
  fdyowk = dayOfWeek;

  // Format departure time
  fdpttm = SDPTHH + ':' + SDPTMM + ' ' + SDPTAP;

  // Format arrival time
  farvtm = SARRHH + ':' + SARRMM + ' ' + SARRAP;

  // Format airline
  CHAIN SAIRLN AIRLINEL;
  CLEAR airlineKey;
  airlineLen = 3;
  IF %FOUND(AIRLINL);
    airline3 = AIRLIN;
  ENDIF;
  fairln = airlineKey;

  fseats = SSEATS;

  // Format ticket price
  CLEAR ticketPrice;
  ticketLen = %CHECKR(' ' : SPRICE);
  ticketName = SPRICE;
  ftcktp = ticketPrice;

  fmiles = SMILES;

  // Write record using externally described format
  CLEAR FLIGHTR;
  FLGHT = fflght;
  DPCIN = fdpcin;
  DPCNM = fdpcnm;
  DYOWK = fdyowk;
  ARCIN = farcin;
  ARCNM = farcnm;
  DPTTM = fdpttm;
  ARVTM = farvtm;
  AIRLN = fairln;
  SEATS = fseats;
  TCKTP = ftcktp;
  MILES = fmiles;

  WRITE FLIGHTR;
END-PROC;

//------------------------------------------------------------------------------
// Update existing flight record
//------------------------------------------------------------------------------
DCL-PROC updateFlightRecord;
  DCL-S fdpcin CHAR(18);
  DCL-S fdpcnm CHAR(18);
  DCL-S fdyowk CHAR(18);
  DCL-S farcin CHAR(18);
  DCL-S farcnm CHAR(18);
  DCL-S fdpttm CHAR(34);
  DCL-S farvtm CHAR(34);
  DCL-S fairln CHAR(34);
  DCL-S fseats PACKED(4:0);
  DCL-S ftcktp CHAR(24);
  DCL-S fmiles PACKED(4:0);

  // Format departure international code
  CLEAR depIntCode;
  depIntLen = 3;
  depInt3 = SFRINT;
  fdpcin = depIntCode;

  // Format departure city
  CLEAR depCityCode;
  depCityLen = %CHECKR(' ' : SFRCTY);
  depCityName = SFRCTY;
  fdpcnm = depCityCode;

  // Format arrival international code
  CLEAR arrIntCode;
  arrIntLen = 3;
  arrInt3 = STOINT;
  farcin = arrIntCode;

  // Format arrival city
  CLEAR arrCityCode;
  arrCityLen = %CHECKR(' ' : STOCTY);
  arrCityName = STOCTY;
  farcnm = arrCityCode;

  // Format day of week
  CLEAR dayOfWeek;
  dayLen = %CHECKR(' ' : SDYOWK);
  dayName = SDYOWK;
  fdyowk = dayOfWeek;

  // Format departure time
  fdpttm = SDPTHH + ':' + SDPTMM + ' ' + SDPTAP;

  // Format arrival time
  farvtm = SARRHH + ':' + SARRMM + ' ' + SARRAP;

  // Format airline
  CHAIN SAIRLN AIRLINEL;
  CLEAR airlineKey;
  airlineLen = 3;
  IF %FOUND(AIRLINL);
    airline3 = AIRLIN;
  ENDIF;
  fairln = airlineKey;

  fseats = SSEATS;

  // Format ticket price
  CLEAR ticketPrice;
  ticketLen = %CHECKR(' ' : SPRICE);
  ticketName = SPRICE;
  ftcktp = ticketPrice;

  fmiles = SMILES;

  // Update record
  DPCIN = fdpcin;
  DPCNM = fdpcnm;
  DYOWK = fdyowk;
  ARCIN = farcin;
  ARCNM = farcnm;
  DPTTM = fdpttm;
  ARVTM = farvtm;
  AIRLN = fairln;
  SEATS = fseats;
  TCKTP = ftcktp;
  MILES = fmiles;

  UPDATE FLIGHTR;
END-PROC;

//------------------------------------------------------------------------------
// Delete flight record
//------------------------------------------------------------------------------
DCL-PROC deleteFlight;
  CHAIN SFLGHT FLIGHTSZ;
  IF %FOUND(FLIGHTSZ);
    DELETE FLIGHTR;
  ENDIF;
END-PROC;

//------------------------------------------------------------------------------
// Refresh screen - clear all fields
//------------------------------------------------------------------------------
DCL-PROC refreshScreen;
  clearErrorIndicators();
  setDisplayIndicators();

  CLEAR SELCTR;
  removeMessages();

  SDPTHH = '00';
  SDPTMM = '00';
  SDPTAP = 'PM';
  SARRHH = '00';
  SARRMM = '00';
  SARRAP = 'PM';
END-PROC;

//------------------------------------------------------------------------------
// Prompt for all fields (F4)
//------------------------------------------------------------------------------
DCL-PROC promptAllFields;
  CALL 'FRS413';
  PARM SFLGHT;
  PARM SDYOWK;
  PARM SFRCTY;
  PARM STOCTY;
  PARM SDPTHH;
  PARM SDPTMM;
  PARM SDPTAP;
  PARM SARRHH;
  PARM SARRMM;
  PARM SARRAP;
  PARM SMILES;
  PARM SAIRIN;
  PARM SSEATS;
  PARM SPRICE;

  // Look up airline name if international code returned
  IF SAIRIN <> *BLANKS;
    CHAIN SAIRIN AIRLINEL;
    IF %FOUND(AIRLINL);
      SAIRLN = AIRLNM;
    ENDIF;
  ENDIF;

  // Look up from city name
  IF SFRCTY <> *BLANKS;
    CHAIN SFRCTY FRCITY;
    IF %FOUND(FRCITY);
      SFRINT = FRCINT;
    ENDIF;
  ENDIF;

  // Look up to city name
  IF STOCTY <> *BLANKS;
    CHAIN STOCTY FRCITY;
    IF %FOUND(FRCITY);
      STOINT = FRCINT;
    ENDIF;
  ENDIF;
END-PROC;

//------------------------------------------------------------------------------
// Prompt for from city (F6)
//------------------------------------------------------------------------------
DCL-PROC promptFromCity;
  CALL 'FRS402';
  PARM SFRCTY;
  PARM SFRINT;
  PARM SAIRIN;

  // Look up airline name if international code returned
  IF SAIRIN <> *BLANKS;
    CHAIN SAIRIN AIRLINEL;
    IF %FOUND(AIRLINL);
      SAIRLN = AIRLNM;
    ENDIF;
  ENDIF;
END-PROC;

//------------------------------------------------------------------------------
// Prompt for to city (F7)
//------------------------------------------------------------------------------
DCL-PROC promptToCity;
  CALL 'FRS403';
  PARM STOCTY;
  PARM STOINT;
END-PROC;

//------------------------------------------------------------------------------
// Prompt for airline (F8)
//------------------------------------------------------------------------------
DCL-PROC promptAirline;
  CALL 'FRS412';
  PARM SAIRLN;
  PARM SAIRIN;
END-PROC;

//------------------------------------------------------------------------------
// Call command line (F9)
//------------------------------------------------------------------------------
DCL-PROC callCommandLine;
  CALL 'QUSCMDLN';
END-PROC;

//------------------------------------------------------------------------------
// Remove program messages
//------------------------------------------------------------------------------
DCL-PROC removeMessages;
  CALL 'QMHRMVPM';
  PARM removeMsg.rmvMsgQueue;
  PARM removeMsg.rmvStackCtr;
  PARM removeMsg.rmvKey;
  PARM removeMsg.rmvType;
  PARM apiError;
END-PROC;

//------------------------------------------------------------------------------
// Send program message
//------------------------------------------------------------------------------
DCL-PROC sendMessage;
  CALL 'QMHSNDPM';
  PARM msgId;
  PARM msgInfo.msgFile;
  PARM msgData;
  PARM msgInfo.msgLength;
  PARM msgInfo.msgType;
  PARM msgQueue;
  PARM msgInfo.msgStackCtr;
  PARM msgInfo.msgKey;
  PARM apiError;
END-PROC;

//==============================================================================
// Compile-time data - Day of week table
//==============================================================================
**CTDATA dayTable
Sunday
Monday
Tuesday
Wednesday
Thursday
Friday
Saturday
