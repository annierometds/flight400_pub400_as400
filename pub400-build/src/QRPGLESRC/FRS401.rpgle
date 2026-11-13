**FREE

//==============================================================================
// Program: FRS401M - Agent Selection Window (Modernized)
// Description: Displays a subfile window allowing user to select an agent
//              from the AGENTSL file. Returns selected agent name to caller.
//
// Modernization Changes:
// - Converted to fully free-format RPG
// - Replaced indicators with named boolean variables
// - Converted subroutines to procedures
// - Added prototypes for IBM API calls
// - Improved error handling
// - Added inline documentation
//
// Parameters:
//   selectedAgent - Output: Name of selected agent (or blank if cancelled)
//==============================================================================

ctl-opt dftactgrp(*no) actgrp(*caller) option(*nodebugio);

// File declarations
dcl-f AGENTSL disk(*ext) keyed usage(*input) infds(agentsInfds);
dcl-f FRS401DF workstn indds(indicators) infds(wsInfds)
      sfile(SFL:sflRecNum);

// Agent file data structure
dcl-ds agentRec extname('AGENTSL':*input) qualified end-ds;

// Agent file INFDS
dcl-ds agentsInfds;
  agentsEof ind pos(12);
end-ds;

// Workstation INFDS
dcl-ds wsInfds;
  funcKey char(1) pos(369);
  pageRrn int(5) pos(378);
end-ds;

// Indicator data structure
dcl-ds indicators;
  clearSfl ind pos(40);
  displaySfl ind pos(42);
  errorAlarm ind pos(50);
  endSflMore ind pos(60);
  displayMsg ind pos(80);
  searchChanged ind pos(97);
  sflEnd ind pos(98);
end-ds;

// Function key constants
dcl-c F03 x'33';
dcl-c F09 x'39';
dcl-c F12 x'3C';
dcl-c ENTER x'F1';
dcl-c PAGDN x'F5';

// Program status data structure
dcl-ds psdsDs psds qualified;
  pgmName char(10) pos(1);
  msgId char(7) pos(40);
  jobName char(10) pos(244);
  userName char(10) pos(254);
  jobNumber char(6) pos(264);
end-ds;

// Message handling data structures
dcl-ds apiError qualified;
  bytesProvided int(10) inz(%size(apiError));
  bytesAvail int(10);
  exceptionId char(7);
  reserved char(1);
  exceptionData char(256);
end-ds;

dcl-ds messageInfo qualified;
  msgKey char(4) inz(*blanks);
  msgQueue char(10) inz(*blanks);
  msgFile char(20) inz('FRSMSGF   *LIBL     ');
  msgType char(10) inz('*INFO     ');
  msgLen int(10) inz(80);
  msgData char(80) inz(*blanks);
end-ds;

// API Prototypes
dcl-pr removeMsg extpgm('QMHRMVPM');
  msgQueue char(10) const;
  msgControl int(10) const;
  msgKey char(4) const;
  msgRemove char(10) const;
  errorCode likeds(apiError);
end-pr;

dcl-pr sendMsg extpgm('QMHSNDPM');
  msgId char(7) const;
  msgFile char(20) const;
  msgData char(80) const;
  msgLen int(10) const;
  msgType char(10) const;
  msgQueue char(10) const;
  msgControl int(10) const;
  msgKey char(4);
  errorCode likeds(apiError);
end-pr;

dcl-pr displayCmdLine extpgm('QUSCMDLN');
end-pr;

// Subfile control variables
dcl-s sflRecNum int(5);
dcl-s endRecNum int(5);
dcl-s sflPos int(5);

// Search positioning variables
dcl-ds endKey qualified;
  name like(agentRec.AGNAME);
end-ds;

// Program control variables
dcl-s exitProgram ind inz(*off);

// Program parameters
dcl-pi *n;
  selectedAgent char(10);
end-pi;

//==============================================================================
// Main Processing
//==============================================================================

// Initialize program
initialize();
removeProgramMessages();
clearSubfile();
loadSubfile();

// Main interaction loop
dow not exitProgram;
  write FRSWIN;
  write FKEYS;
  write MSGCTL;
  exfmt SFLCTL;

  sflPos = pageRrn;

  select;
    when funcKey = F03;
      exitProgram = *on;

    when funcKey = F09;
      displayCmdLine();

    when funcKey = F12;
      exitProgram = *on;

    when funcKey = PAGDN;
      pageDown();

    other;
      processEnter();
  endsl;
enddo;

// Clean up and exit
*inlr = *on;
return;

//==============================================================================
// Procedures
//==============================================================================

//------------------------------------------------------------------------------
// initialize - Initialize program variables and position file
//------------------------------------------------------------------------------
dcl-proc initialize;
  dcl-s startKey like(agentRec.AGNAME);

  errorAlarm = *off;
  messageInfo.msgQueue = psdsDs.pgmName;
  exitProgram = *off;

  sflRecNum = 0;
  endRecNum = 0;
  sflPos = 1;

  // Position to start with 'A'
  startKey = 'A';
  setll startKey AGENTSL;
end-proc;

//------------------------------------------------------------------------------
// loadSubfile - Load one page of records into the subfile
//------------------------------------------------------------------------------
dcl-proc loadSubfile;
  dcl-s recordsLoaded int(5);

  recordsLoaded = 0;

  // Read up to 4 records
  for recordsLoaded = 1 to 4;
    read AGENTSL agentRec;

    if agentsEof;
      leave;
    endif;

    sflRecNum += 1;
    OAGNT# = agentRec.AGNMBR;
    OAGNTN = agentRec.AGNAME;
    SELIO = *blanks;

    write SFL;

    // Save positioning info
    endKey.name = agentRec.AGNAME;
  endfor;

  endRecNum = sflRecNum;

  // Check if more records exist
  if not agentsEof;
    read AGENTSL agentRec;
  endif;

  // Set display control indicators
  if sflRecNum = 0;
    displaySfl = *off;
  else;
    displaySfl = *on;
    sflPos = sflRecNum;
  endif;

  endSflMore = agentsEof;
end-proc;

//------------------------------------------------------------------------------
// clearSubfile - Clear the subfile
//------------------------------------------------------------------------------
dcl-proc clearSubfile;
  clearSfl = *on;
  write FRSWIN;
  write SFLCTL;
  clearSfl = *off;
  displaySfl = *off;

  sflRecNum = 0;
  endRecNum = 0;
  sflPos = 0;
end-proc;

//------------------------------------------------------------------------------
// repositionSubfile - Reposition file and reload subfile
//------------------------------------------------------------------------------
dcl-proc repositionSubfile;
  dcl-s posKey like(agentRec.AGNAME);

  clearSubfile();

  if SEARCH = *blanks;
    posKey = endKey.name;
  else;
    posKey = SEARCH;
  endif;

  setll posKey AGENTSL;
  loadSubfile();
end-proc;

//------------------------------------------------------------------------------
// pageDown - Load next page of records
//------------------------------------------------------------------------------
dcl-proc pageDown;
  dcl-s posKey like(agentRec.AGNAME);

  if not agentsEof;
    posKey = endKey.name;
    setgt posKey AGENTSL;
    sflRecNum = endRecNum;
    loadSubfile();
  else;
    endSflMore = *on;
  endif;
end-proc;

//------------------------------------------------------------------------------
// processEnter - Process Enter key - either search or selection
//------------------------------------------------------------------------------
dcl-proc processEnter;
  errorAlarm = *off;

  if SEARCH <> *blanks;
    repositionSubfile();
  else;
    processSelection();
  endif;
end-proc;

//------------------------------------------------------------------------------
// processSelection - Process subfile selections
//------------------------------------------------------------------------------
dcl-proc processSelection;
  dcl-s firstRead ind inz(*on);

  removeProgramMessages();

  readc SFL;

  // Handle repositioning request
  if searchChanged;
    repositionSubfile();
    return;
  endif;

  // Process selection option
  dow not sflEnd;
    if SELIO = '1';
      selectedAgent = OAGNTN;
      exitProgram = *on;
      leave;
    endif;

    readc SFL;

    if searchChanged;
      repositionSubfile();
      leave;
    endif;
  enddo;
end-proc;

//------------------------------------------------------------------------------
// removeProgramMessages - Remove all program messages
//------------------------------------------------------------------------------
dcl-proc removeProgramMessages;
  dcl-s msgControl int(10) inz(0);
  dcl-s msgKey char(4) inz(*blanks);

  removeMsg('*':msgControl:msgKey:'*ALL':apiError);
end-proc;

//------------------------------------------------------------------------------
// sendProgramMessage - Send a program message (for future use)
//------------------------------------------------------------------------------
dcl-proc sendProgramMessage;
  dcl-pi *n;
    msgIdParm char(7) const;
    msgDataParm char(80) const options(*nopass);
  end-pi;

  dcl-s msgControl int(10) inz(0);
  dcl-s msgData char(80);

  if %parms >= 2;
    msgData = msgDataParm;
  else;
    msgData = *blanks;
  endif;

  sendMsg(msgIdParm:messageInfo.msgFile:msgData:messageInfo.msgLen:
          messageInfo.msgType:messageInfo.msgQueue:msgControl:
          messageInfo.msgKey:apiError);
end-proc;
