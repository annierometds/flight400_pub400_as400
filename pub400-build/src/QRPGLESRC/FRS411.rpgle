**FREE

//=============================================================================
// Program: FRS411 - FAX Confirmation Window
// Description: Displays a simulated FAX sending window with status updates
// Author: Modernized from FRS411.RPG
// Date: 2024
//=============================================================================

// Control Options
ctl-opt dftactgrp(*no) actgrp(*caller) option(*nodebugio:*srcstmt);

// Display File
dcl-f FRS411DF workstn indds(indicators) infds(wsds);

// Data Structures
dcl-ds indicators qualified;
  f03 ind pos(3);
  f12 ind pos(12);
end-ds;

dcl-ds wsds qualified;
  functionKey char(1) pos(369);
end-ds;

// Named Constants for Function Keys
dcl-c F03 x'33';
dcl-c F12 x'3C';
dcl-c ENTER x'F1';

// Variables
dcl-s delayCommand char(18);
dcl-s commandLength packed(15:5);

//=============================================================================
// API Prototype: QCMDEXC - Execute Command
//=============================================================================
dcl-pr QCMDEXC extpgm;
  command char(18) const;
  commandLength packed(15:5) const;
end-pr;

// Initialize
delayCommand = 'DLYJOB DLY(000002)';

// Display initial window and get additional FAX information
write FRSWIN;
exfmt FKEYS;

// Check for cancel
if wsds.functionKey = F03 or wsds.functionKey = F12;
  *inlr = *on;
  return;
endif;

// Display status: Dialing...
write FKEYS2;
delayCommand = 'DLYJOB DLY(000002)';
performDelay();

// Display status: Connecting...
write FKEYS3;
delayCommand = 'DLYJOB DLY(000003)';
performDelay();

// Display status: Sending...
write FKEYS4;
delayCommand = 'DLYJOB DLY(000004)';
performDelay();

// Display status: Success
exfmt FKEYS5;

*inlr = *on;
return;

//=============================================================================
// Subroutine: performDelay
// Purpose: Execute DLYJOB command to simulate FAX processing time
//=============================================================================
dcl-proc performDelay;
  commandLength = 18;

  QCMDEXC(delayCommand: commandLength);
end-proc;
