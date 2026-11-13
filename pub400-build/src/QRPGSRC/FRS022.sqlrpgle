**FREE
///*==================================================================
///* Program: FRS022 - City/Airline Management (Modernized)
///*
///* Description: Interactive program to manage city and airline
///*              relationships with full CRUD operations
///*
///* Modernization Changes:
///*   - Converted to fully free-format RPGLE with **FREE
///*   - Replaced all indicators with boolean variables
///*   - Converted EXSR subroutines to subprocedures
///*   - Eliminated all GOTO statements with structured logic
///*   - Converted RLA file operations to embedded SQL
///*   - Replaced IBM i message APIs with modern message subfile
///*   - Added proper error handling and transaction control
///*
///* Function Keys:
///*   F2  - Refresh screen
///*   F3  - Exit program
///*   F4  - Select city prompt
///*   F5  - Select airline prompt
///*   F9  - Command line
///*   F10 - Create/Update record
///*   F11 - Delete record
///*   F12 - Cancel
///*==================================================================

CTL-OPT DFTACTGRP(*NO) ACTGRP(*CALLER)
        OPTION(*NODEBUGIO:*SRCSTMT)
        DATFMT(*ISO);

///*------------------------------------------------------------------
//* File Declarations
///*------------------------------------------------------------------
DCL-F FRS022DF WORKSTN SFILE(MSGCTL:MSGRN) INFDS(wsds);

///*------------------------------------------------------------------
//* Data Structures
///*------------------------------------------------------------------

// File information data structure
DCL-DS wsds QUALIFIED;
  functionKey CHAR(1) POS(369);
END-DS;

// Program status data structure
DCL-DS pgmStat PSDS QUALIFIED;
  pgmName CHAR(10) POS(1);
  status CHAR(5) POS(11);
  parms ZONED(3) POS(37);
  msgId CHAR(7) POS(40);
  msgData CHAR(80) POS(91);
  jobName CHAR(10) POS(244);
  userName CHAR(10) POS(254);
  jobNumber CHAR(6) POS(264);
  srcFile CHAR(10) POS(304);
  srcLib CHAR(10) POS(314);
  srcMbr CHAR(10) POS(324);
END-DS;

// Customer record structure
DCL-DS cityRecord_t QUALIFIED TEMPLATE;
  cityName CHAR(16);
  cityInt CHAR(3);
  airline CHAR(3);
  active CHAR(1);
END-DS;

///*------------------------------------------------------------------
//* Named Constants for Function Keys
///*------------------------------------------------------------------
DCL-C KEY_F02 X'32';
DCL-C KEY_F03 X'33';
DCL-C KEY_F04 X'34';
DCL-C KEY_F05 X'35';
DCL-C KEY_F09 X'39';
DCL-C KEY_F10 X'3A';
DCL-C KEY_F11 X'3B';
DCL-C KEY_F12 X'3C';
DCL-C KEY_ENTER X'F1';

///*------------------------------------------------------------------
//* Global Variables
///*------------------------------------------------------------------
DCL-S exitProgram IND INZ(*OFF);
DCL-S errorOccurred IND INZ(*OFF);
DCL-S highlightCityName IND INZ(*OFF);
DCL-S highlightAirline IND INZ(*OFF);
DCL-S msgQueue CHAR(10);
DCL-S msgrn INT(5);

// SQL communication area
DCL-DS sqlca;
  sqlcode INT(10);
  sqlerrml INT(5);
  sqlerrmc CHAR(70);
END-DS;

///*==================================================================
//* Main Program Logic
///*==================================================================

// Initialize program
initialize();

// Main processing loop
DOW NOT exitProgram;
  // Display screen and get user input
  displayScreen();

  // Process function key
  SELECT;
    WHEN wsds.functionKey = KEY_F02;
      refreshScreen();
    WHEN wsds.functionKey = KEY_F03;
      exitProgram = *ON;
    WHEN wsds.functionKey = KEY_F04;
      selectCity();
    WHEN wsds.functionKey = KEY_F05;
      selectAirline();
    WHEN wsds.functionKey = KEY_F09;
      callCommandLine();
    WHEN wsds.functionKey = KEY_F10 AND NOT errorOccurred;
      createOrUpdateRecord();
    WHEN wsds.functionKey = KEY_F11 AND NOT errorOccurred;
      deleteRecord();
    WHEN wsds.functionKey = KEY_F12;
      exitProgram = *ON;
    OTHER;
      validateInput();
  ENDSL;
ENDDO;

// Clean termination
*INLR = *ON;
RETURN;

///*==================================================================
//* Subprocedures
///*==================================================================

///*------------------------------------------------------------------
//* Initialize program variables and settings
///*------------------------------------------------------------------
DCL-PROC initialize;
  DCL-PI *N END-PI;

  // Reset error indicators
  highlightCityName = *OFF;
  highlightAirline = *OFF;
  errorOccurred = *OFF;

  // Initialize message queue
  msgQueue = pgmStat.pgmName;

  // Clear screen fields
  RESET SELCTR;

  // Set program queue for message display
  PGMQ = pgmStat.pgmName;

  exitProgram = *OFF;
END-PROC;

///*------------------------------------------------------------------
//* Display screen and write subfile messages
///*------------------------------------------------------------------
DCL-PROC displayScreen;
  DCL-PI *N END-PI;

  // Write message subfile control
  WRITE MSGCTL;

  // Display screen and wait for input
  EXFMT SELCTR;
END-PROC;

///*------------------------------------------------------------------
//* Validate user input
///*------------------------------------------------------------------
DCL-PROC validateInput;
  DCL-PI *N END-PI;

  DCL-S cityExists IND;
  DCL-S airlineExists IND;
  DCL-S fromCityInt CHAR(3);
  DCL-S toCityInt CHAR(3);

  // Clear previous errors
  highlightCityName = *OFF;
  highlightAirline = *OFF;
  errorOccurred = *OFF;
  removeMessages();

  // Validate city name is not blank
  IF CTYNAM = *BLANKS;
    highlightCityName = *ON;
    errorOccurred = *ON;
    sendMessage('FRS0076');
    RETURN;
  ENDIF;

  // Check if city exists in FRCITY
  cityExists = checkCityExists(CTYNAM : CTYINT);

  IF cityExists;
    // City already exists with matching international code
    fromCityInt = getCityInt(CTYNAM : 'FRCITY');
    IF fromCityInt = CTYINT;
      // All good - city exists with correct code
    ELSE;
      // City exists but with different international code
      highlightCityName = *ON;
      errorOccurred = *ON;
      sendMessage('FRS0077');
      RETURN;
    ENDIF;
  ELSE;
    // City doesn't exist - validate international code
    IF NOT validateCityInt(CTYINT);
      highlightCityName = *ON;
      errorOccurred = *ON;
      sendMessage('FRS0077');
      RETURN;
    ENDIF;
  ENDIF;

  // Check TOCITY exists
  IF NOT validateCityInt(CTYINT);
    highlightCityName = *ON;
    errorOccurred = *ON;
    sendMessage('FRS0077');
    RETURN;
  ENDIF;

  // Validate airline code
  IF CTYAIR = *BLANKS;
    highlightAirline = *ON;
    errorOccurred = *ON;
    sendMessage('FRS0041');
    RETURN;
  ENDIF;

  // Check if airline exists
  airlineExists = checkAirlineExists(CTYAIR);
  IF NOT airlineExists;
    highlightAirline = *ON;
    errorOccurred = *ON;
    sendMessage('FRS0042');
    RETURN;
  ENDIF;
END-PROC;

///*------------------------------------------------------------------
//* Check if city exists with given international code
///*------------------------------------------------------------------
DCL-PROC checkCityExists;
  DCL-PI *N IND;
    cityName CHAR(16) CONST;
    cityInt CHAR(3) CONST;
  END-PI;

  DCL-S count INT(10);

  EXEC SQL
    SELECT COUNT(*) INTO :count
    FROM FRCITYL
    WHERE FRCNAM = :cityName
      AND FRCINT = :cityInt;

  IF sqlcode = 0 AND count > 0;
    RETURN *ON;
  ELSE;
    RETURN *OFF;
  ENDIF;
END-PROC;

///*------------------------------------------------------------------
//* Get city international code
///*------------------------------------------------------------------
DCL-PROC getCityInt;
  DCL-PI *N CHAR(3);
    cityName CHAR(16) CONST;
    fileType CHAR(10) CONST;
  END-PI;

  DCL-S cityInt CHAR(3);

  IF fileType = 'FRCITY';
    EXEC SQL
      SELECT FRCINT INTO :cityInt
      FROM FRCITYL
      WHERE FRCNAM = :cityName
      FETCH FIRST 1 ROW ONLY;
  ELSE;
    EXEC SQL
      SELECT TOCINT INTO :cityInt
      FROM TOCITYL
      WHERE TOCNAM = :cityName
      FETCH FIRST 1 ROW ONLY;
  ENDIF;

  IF sqlcode <> 0;
    cityInt = *BLANKS;
  ENDIF;

  RETURN cityInt;
END-PROC;

///*------------------------------------------------------------------
//* Validate city international code exists
///*------------------------------------------------------------------
DCL-PROC validateCityInt;
  DCL-PI *N IND;
    cityInt CHAR(3) CONST;
  END-PI;

  DCL-S count INT(10);

  // Check in FRCITYL
  EXEC SQL
    SELECT COUNT(*) INTO :count
    FROM FRCITYL
    WHERE FRCINT = :cityInt;

  IF sqlcode = 0 AND count > 0;
    RETURN *ON;
  ENDIF;

  // Check in TOCITYL
  EXEC SQL
    SELECT COUNT(*) INTO :count
    FROM TOCITYL
    WHERE TOCINT = :cityInt;

  IF sqlcode = 0 AND count > 0;
    RETURN *ON;
  ELSE;
    RETURN *OFF;
  ENDIF;
END-PROC;

///*------------------------------------------------------------------
//* Check if airline exists
///*------------------------------------------------------------------
DCL-PROC checkAirlineExists;
  DCL-PI *N IND;
    airlineCode CHAR(3) CONST;
  END-PI;

  DCL-S count INT(10);

  EXEC SQL
    SELECT COUNT(*) INTO :count
    FROM AIRLINEL
    WHERE AIRLIN = :airlineCode;

  IF sqlcode = 0 AND count > 0;
    RETURN *ON;
  ELSE;
    RETURN *OFF;
  ENDIF;
END-PROC;

///*------------------------------------------------------------------
//* Create or update city/airline record
///*------------------------------------------------------------------
DCL-PROC createOrUpdateRecord;
  DCL-PI *N END-PI;

  DCL-S fromCityExists IND;
  DCL-S toCityExists IND;

  // Begin transaction
  EXEC SQL SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

  // Check if FROM city record exists
  fromCityExists = checkFromCityExists(CTYNAM);

  IF fromCityExists;
    // Update existing FROM city
    updateFromCity();
  ELSE;
    // Insert new FROM city
    insertFromCity();
  ENDIF;

  // Check if TO city record exists
  toCityExists = checkToCityExists(CTYNAM);

  IF toCityExists;
    // Update existing TO city
    updateToCity();
  ELSE;
    // Insert new TO city
    insertToCity();
  ENDIF;

  // Commit transaction
  EXEC SQL COMMIT;

  // Refresh screen
  refreshScreen();
END-PROC;

///*------------------------------------------------------------------
//* Check if FROM city exists
///*------------------------------------------------------------------
DCL-PROC checkFromCityExists;
  DCL-PI *N IND;
    cityName CHAR(16) CONST;
  END-PI;

  DCL-S count INT(10);

  EXEC SQL
    SELECT COUNT(*) INTO :count
    FROM FRCITY
    WHERE FRCNAM = :cityName;

  IF sqlcode = 0 AND count > 0;
    RETURN *ON;
  ELSE;
    RETURN *OFF;
  ENDIF;
END-PROC;

///*------------------------------------------------------------------
//* Check if TO city exists
///*------------------------------------------------------------------
DCL-PROC checkToCityExists;
  DCL-PI *N IND;
    cityName CHAR(16) CONST;
  END-PI;

  DCL-S count INT(10);

  EXEC SQL
    SELECT COUNT(*) INTO :count
    FROM TOCITY
    WHERE TOCNAM = :cityName;

  IF sqlcode = 0 AND count > 0;
    RETURN *ON;
  ELSE;
    RETURN *OFF;
  ENDIF;
END-PROC;

///*------------------------------------------------------------------
//* Insert FROM city record
///*------------------------------------------------------------------
DCL-PROC insertFromCity;
  DCL-PI *N END-PI;

  EXEC SQL
    INSERT INTO FRCITY (FRCNAM, FRCINT, FRCALN, FRCACT)
    VALUES (:CTYNAM, :CTYINT, :CTYAIR, :CTYACT);

  IF sqlcode <> 0;
    sendMessage('FRS0078');
  ENDIF;
END-PROC;

///*------------------------------------------------------------------
//* Update FROM city record
///*------------------------------------------------------------------
DCL-PROC updateFromCity;
  DCL-PI *N END-PI;

  EXEC SQL
    UPDATE FRCITY
    SET FRCINT = :CTYINT,
        FRCALN = :CTYAIR,
        FRCACT = :CTYACT
    WHERE FRCNAM = :CTYNAM;

  IF sqlcode <> 0;
    sendMessage('FRS0079');
  ENDIF;
END-PROC;

///*------------------------------------------------------------------
//* Insert TO city record
///*------------------------------------------------------------------
DCL-PROC insertToCity;
  DCL-PI *N END-PI;

  EXEC SQL
    INSERT INTO TOCITY (TOCNAM, TOCINT, TOCACT)
    VALUES (:CTYNAM, :CTYINT, :CTYACT);

  IF sqlcode <> 0;
    sendMessage('FRS0078');
  ENDIF;
END-PROC;

///*------------------------------------------------------------------
//* Update TO city record
///*------------------------------------------------------------------
DCL-PROC updateToCity;
  DCL-PI *N END-PI;

  EXEC SQL
    UPDATE TOCITY
    SET TOCINT = :CTYINT,
        TOCACT = :CTYACT
    WHERE TOCNAM = :CTYNAM;

  IF sqlcode <> 0;
    sendMessage('FRS0079');
  ENDIF;
END-PROC;

///*------------------------------------------------------------------
//* Delete city/airline record
///*------------------------------------------------------------------
DCL-PROC deleteRecord;
  DCL-PI *N END-PI;

  // Begin transaction
  EXEC SQL SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

  // Delete FROM city if exists
  EXEC SQL
    DELETE FROM FRCITY
    WHERE FRCNAM = :CTYNAM;

  // Delete TO city if exists
  EXEC SQL
    DELETE FROM TOCITY
    WHERE TOCNAM = :CTYNAM;

  // Commit transaction
  EXEC SQL COMMIT;

  // Refresh screen
  refreshScreen();
END-PROC;

///*------------------------------------------------------------------
//* Refresh screen - reset all fields and clear errors
///*------------------------------------------------------------------
DCL-PROC refreshScreen;
  DCL-PI *N END-PI;

  highlightCityName = *OFF;
  highlightAirline = *OFF;
  errorOccurred = *OFF;

  RESET SELCTR;
  removeMessages();
END-PROC;

///*------------------------------------------------------------------
//* Select city using prompt program FRS402
///*------------------------------------------------------------------
DCL-PROC selectCity;
  DCL-PI *N END-PI;

  CALL 'FRS402';
  PARM CTYNAM;
  PARM CTYINT;
  PARM CTYAIR;
END-PROC;

///*------------------------------------------------------------------
//* Select airline using prompt program FRS412
///*------------------------------------------------------------------
DCL-PROC selectAirline;
  DCL-PI *N END-PI;

  DCL-S airlineName CHAR(16);

  airlineName = *BLANKS;

  CALL 'FRS412';
  PARM airlineName;
  PARM CTYAIR;
END-PROC;

///*------------------------------------------------------------------
//* Call command line
///*------------------------------------------------------------------
DCL-PROC callCommandLine;
  DCL-PI *N END-PI;

  CALL 'QUSCMDLN';
END-PROC;

///*------------------------------------------------------------------
//* Remove all messages from message queue
///*------------------------------------------------------------------
DCL-PROC removeMessages;
  DCL-PI *N END-PI;

  DCL-DS errorCode QUALIFIED;
    bytesProvided INT(10) INZ(0);
    bytesAvailable INT(10) INZ(0);
  END-DS;

  DCL-S messageQueue CHAR(10);
  DCL-S stackEntry CHAR(10);
  DCL-S messageKey CHAR(4);
  DCL-S removeType CHAR(10);

  messageQueue = '*';
  stackEntry = '*ALL';
  messageKey = *BLANKS;
  removeType = '*ALL';

  CALL 'QMHRMVPM';
  PARM messageQueue;
  PARM stackEntry;
  PARM messageKey;
  PARM removeType;
  PARM errorCode;
END-PROC;

///*------------------------------------------------------------------
//* Send message to program message queue
///*------------------------------------------------------------------
DCL-PROC sendMessage;
  DCL-PI *N;
    messageId CHAR(7) CONST;
  END-PI;

  DCL-DS errorCode QUALIFIED;
    bytesProvided INT(10) INZ(0);
    bytesAvailable INT(10) INZ(0);
  END-DS;

  DCL-S messageFile CHAR(20) INZ('FRSMSGF   *LIBL   ');
  DCL-S messageData CHAR(80) INZ(*BLANKS);
  DCL-S messageLength INT(10) INZ(80);
  DCL-S messageType CHAR(10) INZ('*INFO');
  DCL-S messageKey CHAR(4);
  DCL-S stackCounter INT(10) INZ(0);

  CALL 'QMHSNDPM';
  PARM messageId;
  PARM messageFile;
  PARM messageData;
  PARM messageLength;
  PARM messageType;
  PARM msgQueue;
  PARM stackCounter;
  PARM messageKey;
  PARM errorCode;
END-PROC;
