**FREE
//==============================================================================
// Program: FRS024 - Customer Name Maintenance
// Description: Interactive program for maintaining customer names
// Converted: OPM RPG to ILE RPGLE Fully Free-Format
//==============================================================================

CTL-OPT DFTACTGRP(*NO) ACTGRP(*CALLER);

// File Declarations
DCL-F FRS024DF WORKSTN INFDS(WSDS);
DCL-F CUSTNAME DISK(*EXT) KEYED USAGE(*INPUT);
DCL-F CUSTOMRZ DISK(*EXT) KEYED USAGE(*UPDATE:*OUTPUT:*DELETE);

// Named Constants - Function Keys
DCL-C F01 X'31';
DCL-C F02 X'32';
DCL-C F03 X'33';
DCL-C F04 X'34';
DCL-C F09 X'39';
DCL-C F10 X'3A';
DCL-C F11 X'3B';
DCL-C F12 X'3C';
DCL-C ENTER X'F1';
DCL-C HELP X'F3';
DCL-C PRINT X'F6';

// Named Constants - General
DCL-C APOST X'7D';
DCL-C CHARS 'ABCDEFGHIJKLMNOPQRSTUVWXYZ-
             abcdefghijklmnopqrstuvwxyz ';

//==============================================================================
// API Prototypes
//==============================================================================

// QMHRMVPM - Remove Program Messages
DCL-PR QMHRMVPM EXTPGM('QMHRMVPM');
  MessageQueue CHAR(10) CONST;
  CallStackCounter INT(10) CONST;
  MessageKey CHAR(4) CONST;
  MessagesToRemove CHAR(10) CONST;
  ErrorCode LIKEDS(ApiErr);
END-PR;

// QMHSNDPM - Send Program Message
DCL-PR QMHSNDPM EXTPGM('QMHSNDPM');
  MessageID CHAR(7) CONST;
  QualifiedMsgF CHAR(20) CONST;
  MessageData CHAR(80) CONST;
  MessageDataLen INT(10) CONST;
  MessageType CHAR(10) CONST;
  CallStackEntry CHAR(10) CONST;
  CallStackCounter INT(10) CONST;
  MessageKey CHAR(4);
  ErrorCode LIKEDS(ApiErr);
END-PR;

// FRS405 - Customer Selection Program
DCL-PR FRS405 EXTPGM('FRS405');
  CustomerNumber ZONED(9:0);
  CustomerName CHAR(25);
END-PR;

// QUSCMDLN - Display Command Line
DCL-PR QUSCMDLN EXTPGM('QUSCMDLN');
END-PR;

// Program Status Data Structure
DCL-DS PsdsInfo PSDS QUALIFIED;
  PgmName *PROC;
  PgmStatus *STATUS;
  PgmParms INT(3) POS(37);
  PgmExcpMsgId CHAR(7) POS(40);
  PgmExcpData CHAR(79) POS(91);
  PgmJobName CHAR(10) POS(244);
  PgmUserName CHAR(10) POS(254);
  PgmJobNumber CHAR(6) POS(264);
  PgmSourceFile CHAR(10) POS(304);
  PgmSourceLib CHAR(10) POS(314);
  PgmSourceMbr CHAR(10) POS(324);
END-DS;

// API Error Data Structure
DCL-DS ApiErr;
  BytesProv INT(10) INZ(256);
  BytesAvail INT(10) INZ(0);
  ApiExcpId CHAR(7) INZ;
  ApiReserved CHAR(1) INZ;
  ApiExcpData CHAR(240) INZ;
END-DS;

// Message Handling Data Structure
DCL-DS MsgInfo;
  MsgCtr INT(10) INZ(0);
  MsgLen INT(10) INZ(80);
  MsgFile CHAR(20) INZ('FRSMSGF   *LIBL     ');
  MsgType CHAR(10) INZ('*INFO     ');
  MsgKey CHAR(4) INZ('    ');
END-DS;

// Remove Message Data Structure
DCL-DS RmvInfo;
  RmvCtr INT(10) INZ(0);
  RmvMsgQ CHAR(10) INZ('*         ');
  RmvClr CHAR(10) INZ('*ALL      ');
  RmvKey CHAR(4) INZ('    ');
END-DS;

// Workstation Data Structure
DCL-DS WSDS;
  Key CHAR(1) POS(369);
END-DS;

// Customer Key Data Structure
DCL-DS CusKey;
  CusLen INT(5);
  CusNam CHAR(64);
END-DS;

// External DS from CUSTNAME file - Input Record
DCL-DS CustNameRec EXTNAME('CUSTNAME') QUALIFIED;
END-DS;

// External DS from CUSTOMRZ file - Update Record
DCL-DS CustomrzRec EXTNAME('CUSTOMRZ') QUALIFIED;
END-DS;

// Working Variables
DCL-S ExitFlag IND INZ(*OFF);
DCL-S MsgId CHAR(7);
DCL-S MsgData CHAR(80);
DCL-S MsgQueue CHAR(10);
DCL-S PgmQueue CHAR(10);
DCL-S NbrChk ZONED(9:0);
DCL-S NameChk CHAR(25);
DCL-S CnmChk ZONED(2:0);
DCL-S CustNum ZONED(9:0);

// Boolean Indicators (replacing numbered indicators)
DCL-S RecordFound IND INZ(*OFF);          // Replaces *IN44
DCL-S ErrorOccurred IND INZ(*OFF);        // Replaces *IN50
DCL-S CustomerNumberError IND INZ(*OFF);  // Replaces *IN51
DCL-S CustomerNameError IND INZ(*OFF);    // Replaces *IN52

// Display File Indicator Constants
DCL-C IND_RECORD_FOUND 44;
DCL-C IND_ERROR 50;
DCL-C IND_CUST_NUM_ERR 51;
DCL-C IND_CUST_NAME_ERR 52;

//==============================================================================
// Main Procedure
//==============================================================================

// Initialize program
InitializeProgram();

// Main processing loop
DOW NOT ExitFlag;
  WRITE MSGCTL;
  EXFMT SELCTR;

  SELECT;
    WHEN Key = F02;
      RefreshScreen();
    WHEN Key = F03;
      ExitProgram();
    WHEN Key = F04;
      CallSelection();
    WHEN Key = F09;
      CommandLine();
    WHEN Key = F12;
      CancelProgram();
    OTHER;
      ValidateInput();
  ENDSL;

  // Handle F10 - Add/Update
  IF Key = F10 AND NOT *INLR AND NOT ErrorOccurred;
    AddUpdateCustomer();
  ENDIF;

  // Handle F11 - Delete
  IF Key = F11 AND NOT *INLR AND NOT ErrorOccurred;
    DeleteCustomer();
  ENDIF;
ENDDO;

*INLR = *ON;
RETURN;

//==============================================================================
// Subprocedures
//==============================================================================

//------------------------------------------------------------------------------
// InitializeProgram - Initialize program variables and screen
//------------------------------------------------------------------------------
DCL-PROC InitializeProgram;
  // Initialize boolean indicators
  RecordFound = *OFF;
  ErrorOccurred = *OFF;
  CustomerNumberError = *OFF;
  CustomerNameError = *OFF;

  // Clear display file indicators
  ClearDisplayIndicators();

  MsgId = *BLANKS;
  MsgData = *BLANKS;
  MsgQueue = PsdsInfo.PgmName;
  PgmQueue = PsdsInfo.PgmName;
  ExitFlag = *OFF;

  RESET SELCTR;
END-PROC;

//------------------------------------------------------------------------------
// ValidateInput - Validate input data from screen
//------------------------------------------------------------------------------
DCL-PROC ValidateInput;
  // Clear error indicators
  RecordFound = *OFF;
  ErrorOccurred = *OFF;
  CustomerNumberError = *OFF;
  CustomerNameError = *OFF;
  ClearDisplayIndicators();

  RemoveMessages();

  // Validate customer number is not zero
  IF SCUST# = *ZEROS;
    ErrorOccurred = *ON;
    CustomerNumberError = *ON;
    MsgId = 'FRS0064';
    SendMessage();
    SetDisplayIndicators();
    RETURN;
  ENDIF;

  // Check if customer exists in CUSTOMRZ
  NbrChk = SCUST#;
  CHAIN NbrChk CUSTOMRZ;
  IF NOT %FOUND(CUSTOMRZ);
    // Customer not found in CUSTOMRZ - this is OK for new customers
  ELSE;
    // Customer exists - validate name matches
    CusKey = *BLANKS;
    %SUBST(CusKey:1:%LEN(CustomrzRec.CUSTNM)) = CustomrzRec.CUSTNM;
    NameChk = %SUBST(CustomrzRec.CUSTNM:1:25);
    IF SCUSTN = NameChk;
      RETURN;
    ENDIF;
  ENDIF;

  // Validate customer name in CUSTNAME file
  CusKey = *BLANKS;
  CusLen = %CHECKR(' ':SCUSTN);
  %SUBST(CusNam:1:CusLen) = %SUBST(SCUSTN:1:CusLen);

  CHAIN CusNam CUSTNAME;
  IF NOT %FOUND(CUSTNAME);
    ErrorOccurred = *ON;
    CustomerNameError = *ON;
    MsgId = 'FRS0067';
    SendMessage();
    SetDisplayIndicators();
    RETURN;
  ENDIF;

  // Validate name contains valid characters
  CnmChk = *ZEROS;
  CnmChk = %CHECK(CHARS:SCUSTN);
  IF CnmChk = *ZEROS;
    ErrorOccurred = *ON;
    CustomerNameError = *ON;
    MsgId = 'FRS0066';
    SendMessage();
    SetDisplayIndicators();
    RETURN;
  ENDIF;
END-PROC;

//------------------------------------------------------------------------------
// RemoveMessages - Remove program messages from message queue
//------------------------------------------------------------------------------
DCL-PROC RemoveMessages;
  QMHRMVPM(RmvMsgQ : RmvCtr : RmvKey : RmvClr : ApiErr);
END-PROC;

//------------------------------------------------------------------------------
// SendMessage - Send program message to message queue
//------------------------------------------------------------------------------
DCL-PROC SendMessage;
  QMHSNDPM(MsgId : MsgFile : MsgData : MsgLen :
           MsgType : MsgQueue : MsgCtr : MsgKey : ApiErr);
END-PROC;

//------------------------------------------------------------------------------
// RefreshScreen - Refresh screen and clear errors
//------------------------------------------------------------------------------
DCL-PROC RefreshScreen;
  RecordFound = *OFF;
  ErrorOccurred = *OFF;
  CustomerNumberError = *OFF;
  CustomerNameError = *OFF;
  ClearDisplayIndicators();
  RESET SELCTR;
  RemoveMessages();
END-PROC;

//------------------------------------------------------------------------------
// SetDisplayIndicators - Map boolean variables to display file indicators
//------------------------------------------------------------------------------
DCL-PROC SetDisplayIndicators;
  *IN(IND_RECORD_FOUND) = RecordFound;
  *IN(IND_ERROR) = ErrorOccurred;
  *IN(IND_CUST_NUM_ERR) = CustomerNumberError;
  *IN(IND_CUST_NAME_ERR) = CustomerNameError;
END-PROC;

//------------------------------------------------------------------------------
// ClearDisplayIndicators - Clear all display file indicators
//------------------------------------------------------------------------------
DCL-PROC ClearDisplayIndicators;
  *IN(IND_RECORD_FOUND) = *OFF;
  *IN(IND_ERROR) = *OFF;
  *IN(IND_CUST_NUM_ERR) = *OFF;
  *IN(IND_CUST_NAME_ERR) = *OFF;
END-PROC;

//------------------------------------------------------------------------------
// ExitProgram - Set exit flag to exit program
//------------------------------------------------------------------------------
DCL-PROC ExitProgram;
  ExitFlag = *ON;
END-PROC;

//------------------------------------------------------------------------------
// CallSelection - Call customer selection program FRS405
//------------------------------------------------------------------------------
DCL-PROC CallSelection;
  CustNum = *ZEROS;

  FRS405(CustNum : SCUSTN);

  SCUST# = CustNum;
END-PROC;

//------------------------------------------------------------------------------
// CommandLine - Call command line interface
//------------------------------------------------------------------------------
DCL-PROC CommandLine;
  QUSCMDLN();
END-PROC;

//------------------------------------------------------------------------------
// AddUpdateCustomer - Add or update customer record
//------------------------------------------------------------------------------
DCL-PROC AddUpdateCustomer;
  // Check if customer exists
  NbrChk = SCUST#;
  CHAIN NbrChk CUSTOMRZ;

  IF NOT %FOUND(CUSTOMRZ);
    // Add new customer
    CUSTNO = SCUST#;
    CusKey = *BLANKS;
    CusLen = %CHECKR(' ':SCUSTN);
    %SUBST(CusNam:1:CusLen) = %SUBST(SCUSTN:1:CusLen);
    CUSTNM = CusKey;
    WRITE CUSTZ;
  ELSE;
    // Update existing customer
    CusKey = *BLANKS;
    CusLen = %CHECKR(' ':SCUSTN);
    %SUBST(CusNam:1:CusLen) = %SUBST(SCUSTN:1:CusLen);
    CUSTNM = CusKey;
    UPDATE CUSTZ;
  ENDIF;

  RefreshScreen();
END-PROC;

//------------------------------------------------------------------------------
// DeleteCustomer - Delete customer record
//------------------------------------------------------------------------------
DCL-PROC DeleteCustomer;
  NbrChk = SCUST#;
  CHAIN NbrChk CUSTOMRZ;
  IF %FOUND(CUSTOMRZ);
    DELETE CUSTOMRZ;
  ENDIF;

  RefreshScreen();
END-PROC;

//------------------------------------------------------------------------------
// CancelProgram - Cancel and exit program
//------------------------------------------------------------------------------
DCL-PROC CancelProgram;
  ExitFlag = *ON;
END-PROC;
