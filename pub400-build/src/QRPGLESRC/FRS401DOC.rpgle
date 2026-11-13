================================================================================
FRS401 MODERNIZATION DOCUMENTATION
================================================================================

Program Name:    FRS401M.RPGLE (Modernized version of FRS401.RPG)
Date:            2025
Purpose:         Agent Selection Window with modern RPG features
Original:        FRS401.RPG (OPM RPG III)
Converted:       FRS401.RPGLE (Fixed-format ILE RPGLE via CVTRPGSRC)
Modernized:      FRS401M.RPGLE (Fully free-format with modern patterns)

================================================================================
SUMMARY OF CHANGES
================================================================================

1. FULLY FREE-FORMAT SYNTAX
   - Converted from fixed-format columns to **FREE
   - All declarations use dcl-* syntax (dcl-f, dcl-s, dcl-ds, dcl-c, dcl-pr)
   - Operations use free-format syntax (dow...enddo, if...endif, select...endsl)

2. INDICATOR ELIMINATION
   - Replaced numbered indicators (*IN40, *IN42, etc.) with named boolean vars
   - Created INDDS data structure mapping indicators to descriptive names:
     * clearSfl (*IN40)       - Clear subfile indicator
     * displaySfl (*IN42)     - Display subfile indicator
     * errorAlarm (*IN50)     - Error alarm indicator
     * endSflMore (*IN60)     - End of subfile/more indicator
     * searchChanged (*IN97)  - Search field changed
     * sflEnd (*IN98)         - Subfile end of records
     * agentsEof (*IN99)      - End of file indicator (INFDS)

3. SUBROUTINES TO PROCEDURES
   Converted all internal subroutines (BEGSR/ENDSR) to procedures (dcl-proc):
   - *INZSR         initialize()
   - $LOAD          loadSubfile()
   - $RESET         clearSubfile()
   - $REPOS         repositionSubfile()
   - $PGDN          pageDown()
   - $ENTKY         processEnter()
   - $SFLRD         processSelection()
   - $RMVMS         removeProgramMessages()
   - $SNDMS         sendProgramMessage()
   - $F03SR/F12SR   (inline in main loop)
   - $F09SR         (direct call in main loop)

4. API CALL MODERNIZATION
   Replaced CALL/PARM with prototyped procedure calls:
   - QMHRMVPM  removeMsg() prototype
   - QMHSNDPM  sendMsg() prototype
   - QUSCMDLN  displayCmdLine() prototype

5. DATA STRUCTURE IMPROVEMENTS
   - Used qualified data structures for better organization
   - Replaced overlapping DS with proper subfields
   - Used EXTNAME to externally describe agent record
   - Created INFDS structures for file and workstation feedback

6. CONTROL FLOW IMPROVEMENTS
   - Eliminated GOTO statements (GOTO ENDSEL removed)
   - Replaced CASxx operations with SELECT/WHEN/ENDSL
   - Converted DO loops to FOR loops where applicable
   - Used LEAVE instead of GOTO for early exit

7. MODERN CODING STANDARDS
   - Added comprehensive inline documentation
   - Used descriptive variable names
   - Organized code into logical sections
   - Added procedure-level comments
   - Improved code readability

8. ILE FEATURES
   - Set DFTACTGRP(*NO) for true ILE behavior
   - Set ACTGRP(*CALLER) for proper activation group handling
   - Added OPTION(*NODEBUGIO) for better debugging

================================================================================
DETAILED CHANGE COMPARISON
================================================================================

AREA: File Declarations
------------------------------------------------------------------------
OLD (Fixed Format):
  FAGENTSL IF  F     136 66AI     5 DISK
  FFRS401DFCF  E                    WORKSTN      KINFDS WSDS

NEW (Free Format):
  dcl-f AGENTSL disk(*ext) keyed usage(*input) infds(agentsInfds);
  dcl-f FRS401DF workstn indds(indicators) infds(wsInfds)
        sfile(SFL:sflRecNum);

Benefits:
  - More readable and self-documenting
  - Explicit INDDS and INFDS declarations
  - Named subfile record number variable

------------------------------------------------------------------------
AREA: Constants
------------------------------------------------------------------------
OLD (I-specs):
  I              X'31'                 C         $F01
  I              '0'                   C         $FALSE

NEW (dcl-c):
  dcl-c F03 x'33';
  dcl-c F09 x'39';
  dcl-c F12 x'3C';

Benefits:
  - Cleaner syntax
  - Easier to maintain
  - More visible in code

------------------------------------------------------------------------
AREA: Data Structures
------------------------------------------------------------------------
OLD (I-specs):
  IAPIERR      DS
  I I            256                   B   1   40ERRSIZ
  I I            0                     B   5   80ERRLEN

NEW (dcl-ds):
  dcl-ds apiError qualified;
    bytesProvided int(10) inz(%size(apiError));
    bytesAvail int(10);
    exceptionId char(7);
    reserved char(1);
    exceptionData char(256);
  end-ds;

Benefits:
  - Qualified to avoid name conflicts
  - Self-sizing with %SIZE
  - Modern data types (INT instead of BINDEC)
  - Clear field names

------------------------------------------------------------------------
AREA: Main Processing Loop
------------------------------------------------------------------------
OLD:
  C           $EXIT     DOUEQ$TRUE
  C                     WRITEFRSWIN
  C                     WRITEFKEYS
  C                     WRITEMSGCTL
  C                     EXFMTSFLCTL
  C                     Z-ADDPAGRRN    SFLPS
  C           KEY       CASEQ$F03      $F03SR
  C           KEY       CASEQ$F09      $F09SR
  C                     ENDCS
  C                     ENDDO

NEW:
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
    endsl;
  enddo;

Benefits:
  - More readable logic flow
  - Boolean variable instead of character flag
  - SELECT statement clearer than CASXX
  - No need for separate subroutines for simple exits

------------------------------------------------------------------------
AREA: Subfile Loading
------------------------------------------------------------------------
OLD:
  C           $LOAD     BEGSR
  C                     DO   4
  C                     READ AGENTSL                  99
  C           *IN99     IFEQ *ON
  C                     LEAVE
  C                     ENDIF
  C                     ADD  1         SFLRN
  C                     WRITESFL
  C                     ENDDO
  C                     ENDSR

NEW:
  dcl-proc loadSubfile;
    dcl-s recordsLoaded int(5);

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

      endKey.name = agentRec.AGNAME;
    endfor;
  end-proc;

Benefits:
  - Procedure provides better encapsulation
  - FOR loop more intuitive than DO
  - Named EOF indicator (agentsEof)
  - Qualified record structure
  - Local variables with proper scope

------------------------------------------------------------------------
AREA: API Calls
------------------------------------------------------------------------
OLD:
  C           $RMVMS    BEGSR
  C                     CALL 'QMHRMVPM'
  C                     PARM           RMVMSQ
  C                     PARM           RMVCTR
  C                     PARM           RMVKEY
  C                     PARM           RMVCLR
  C                     PARM           APIERR
  C                     ENDSR

NEW:
  dcl-pr removeMsg extpgm('QMHRMVPM');
    msgQueue char(10) const;
    msgControl int(10) const;
    msgKey char(4) const;
    msgRemove char(10) const;
    errorCode likeds(apiError);
  end-pr;

  dcl-proc removeProgramMessages;
    dcl-s msgControl int(10) inz(0);
    dcl-s msgKey char(4) inz(*blanks);

    removeMsg('*':msgControl:msgKey:'*ALL':apiError);
  end-proc;

Benefits:
  - Prototype provides parameter checking at compile time
  - CONST keyword prevents accidental modification
  - Cleaner call syntax
  - Better error detection

------------------------------------------------------------------------
AREA: Control Flow
------------------------------------------------------------------------
OLD (with GOTO):
  C           *IN97     IFEQ '1'
  C                     EXSR $REPOS
  C                     GOTO ENDSEL
  C                     ENDIF
  ...
  C           ENDSEL    ENDSR

NEW (structured):
  if searchChanged;
    repositionSubfile();
    return;
  endif;

Benefits:
  - Eliminated GOTO for better structure
  - RETURN provides clean procedure exit
  - Easier to understand flow

================================================================================
INDICATOR MAPPING REFERENCE
================================================================================

Display File Indicator Usage (from FRS401DF.DSPF):
----------------------------------------------------
40 - SFLCLR      clearSfl
42 - SFLDSP      displaySfl
50 - ALARM       errorAlarm
60 - SFLMSG      endSflMore
80 - N80 (msg)   displayMsg
97 - (search)    searchChanged (internal)
98 - (READC)     sflEnd (internal)
99 - SFLEND      agentsEof (file INFDS)

================================================================================
COMPILATION INSTRUCTIONS
================================================================================

To compile the modernized program:

  CRTRPGMOD MODULE(FLGHT400/FRS401M)
            SRCFILE(FLGHT400/QRPGLESRC)
            SRCMBR(FRS401M)
            DBGVIEW(*LIST)

  CRTPGM PGM(FLGHT400/FRS401M)
         MODULE(FLGHT400/FRS401M)
         ACTGRP(*CALLER)

Or using CRTBNDRPG:

  CRTBNDRPG PGM(FLGHT400/FRS401M)
            SRCFILE(FLGHT400/QRPGLESRC)
            SRCMBR(FRS401M)
            DFTACTGRP(*NO)
            ACTGRP(*CALLER)
            DBGVIEW(*LIST)

================================================================================
TESTING CHECKLIST
================================================================================

 Program compiles without errors
 Display file window appears correctly
 Subfile loads with agent records
 Page Down scrolls through records
 Search field positions to correct agent
 Selection option '1' returns agent name to caller
 F3 exits program
 F9 displays command line
 F12 cancels/exits program
 Error messages display correctly
 Parameter returns selected agent name
 Program handles empty file gracefully

================================================================================
MIGRATION STRATEGY
================================================================================

PHASE 1: Side-by-Side Testing
  - Keep FRS401.RPG operational
  - Test FRS401M.RPGLE in development
  - Compare behavior with original

PHASE 2: Update Calling Programs
  - Identify all programs calling FRS401
  - Update CALL statements if program name changed
  - Verify parameter passing

PHASE 3: Production Cutover
  - Rename or delete old FRS401 program
  - Rename FRS401M to FRS401 (or update callers)
  - Monitor for issues

Alternative: Create as new program and gradually migrate callers

================================================================================
FURTHER MODERNIZATION OPPORTUNITIES
================================================================================

1. SQL CONVERSION
   - Replace RLA (READ/SETLL/SETGT) with embedded SQL
   - Use cursors for subfile loading
   - Benefits: Better performance, more flexible queries

2. SERVICE PROGRAM
   - Extract procedures to service program
   - Allow other programs to reuse selection logic
   - Benefits: Code reuse, easier maintenance

3. DATA AREA OR DATA QUEUE
   - Use data structures for inter-program communication
   - Benefits: Type safety, better documentation

4. ERROR LOGGING
   - Add comprehensive error logging
   - Use message file for all user messages
   - Benefits: Better troubleshooting

5. UNIT TESTING
   - Create RPGUnit test cases
   - Test individual procedures
   - Benefits: Confidence in changes

================================================================================
MAINTENANCE NOTES
================================================================================

- All indicators now have descriptive names via INDDS
- Procedures are self-contained with local scope
- API calls are type-checked via prototypes
- Code is easier to debug with *NODEBUGIO
- Activation group allows proper cleanup

For questions or issues, refer to this documentation and the inline
comments in FRS401M.RPGLE.

================================================================================
END OF DOCUMENTATION
================================================================================
