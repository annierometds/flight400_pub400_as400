# What was changed for PUB400

All source in `src/` was recovered from `FLGHT400.FILE` (the IBM i 7.6 save file). Line-level edits:

## Summary

| Change | Why | Where |
|---|---|---|
| `'FRSMSGF   FLGHT400  '` → `'FRSMSGF   *LIBL     '` | message file is found through the library list (same width, so fixed-format columns don't move) | every RPG program that sends messages |
| `'GO FLGHT400/FRSMANT'` → `'GO FRSMANT'` (same for FRSREPT) | menus come from the library list | QRPGSRC/FRS000 |
| `FLGHT400/` removed from `REF`, `REFFLD`, `CHKMSGID` | display files resolve through the library list | QDDSSRCD/* |
| `FLGHT400/` removed from `DCLF`, `OVRDBF`, `CHKOBJ`, `CRTDTAARA`, `CHGDTAARA` | same | QCLPSRC/* |
| `CALL FLGHT400/...`, `UPDDTA FLGHT400/AIRLINE` → unqualified | menu options run from the library list (menus set CURLIB to your library) | QMNUSRC/*QQ |
| `RUNQRY QRY(FLGHT400/ALLAGENTS ...)` → `RUNQRY QRY(*NONE) QRYFILE((AGENTS / FLIGHTS))` | the saved Query/400 definitions are objects, not source, so they can't be rebuilt | QMNUSRC/FRSREPTQQ |
| Re-split a `QMHSNDPM(...)` call that was cut off at column 80 and added the missing `APIERR);` | the line was truncated in the save file and would not compile | QRPGSRC/FRS009 |
| `DSPLIB LIB(MARKNAP)` → `DSPLIB LIB(*CURLIB)` | MARKNAP was a library on the original author's system | QCLPSRC/MSGPRGH |

## Added

- `src/QCLPSRC/FLBUILD.clle`: a CL build program that creates the message file, files, display files, programs, commands and menus in the right order, then loads data. It logs every step to table `FLBLOG`.
- `src/QSQLSRC/SEED.sql`: seed rows recovered from the save file (FNAME, LNAME, FRCITY, TOCITY, AIRLINE) plus the agent list from FLIGHT400-GUIDE.md (password `mercury`).
- Message file `FRSMSGF`: 41 messages recovered from the save file. FRS0078/FRS0079 (used only by the modernized FRS022) had no saved text, so short texts were written for them.

## Not compiled (kept as source only)

- `QRPGLESRC/*`: the Bob-modernized ILE versions from the lab. Their objects would replace the original programs of the same names. Compile any of them on purpose when you want to demo the modernized version.
- `QRPGSRC` variants `FRS001`, `FRS001T`, `FRS001U2`, `FRS001X`, `FRS401B`, `FRS402B`, `FRS404B`: alternates that nothing calls. Program `FRS001` is built from member `FRS001U`, matching the original object.

## Line-by-line

### QCLPSRC/BLDCST

- line 3: `OVRDBF     FILE(CUSTOMER) TOFILE(FLGHT400/CUSTOMERS)`  →  `OVRDBF     FILE(CUSTOMER) TOFILE(CUSTOMERS)`

### QCLPSRC/FRS001CL

- line 5: `OVRDBF     FILE(CUSTOMER) TOFILE(FLGHT400/CUSTOMERS)`  →  `OVRDBF     FILE(CUSTOMER) TOFILE(CUSTOMERS)`

### QCLPSRC/FRS411CL

- line 3: `DCLF       FLGHT400/FRS411DF`  →  `DCLF       FRS411DF`

### QCLPSRC/MSGPRG

- line 14: `/* DCLF       FILE(FLGHT400/MSGPANEL) RCDFMT(MSGPANEL)   */`  →  `/* DCLF       FILE(MSGPANEL) RCDFMT(MSGPANEL)   */`

### QCLPSRC/MSGPRGH

- line 2: `DCLF       FILE(FLGHT400/MSGPANEL) RCDFMT(MSGPANEL)`  →  `DCLF       FILE(MSGPANEL) RCDFMT(MSGPANEL)`
- line 5: `DSPLIB LIB(MARKNAP) OUTPUT(*PRINT)`  →  `DSPLIB LIB(*CURLIB) OUTPUT(*PRINT)   (MARKNAP is a library from the original author's system)`

### QCLPSRC/USECLEAR

- line 5: `CHKOBJ     OBJ(FLGHT400/FLDS) OBJTYPE(*DTAARA)`  →  `CHKOBJ     OBJ(FLDS) OBJTYPE(*DTAARA)`
- line 8: `CRTDTAARA  DTAARA(FLGHT400/FLDS) +`  →  `CRTDTAARA  DTAARA(FLDS) +`
- line 13: `CHGDTAARA  DTAARA(FLGHT400/FLDS (1 5)) +`  →  `CHGDTAARA  DTAARA(FLDS (1 5)) +`

### QCLPSRC/USERESET

- line 5: `CHKOBJ     OBJ(FLGHT400/FLDS) OBJTYPE(*DTAARA)`  →  `CHKOBJ     OBJ(FLDS) OBJTYPE(*DTAARA)`
- line 8: `CRTDTAARA  DTAARA(FLGHT400/FLDS) +`  →  `CRTDTAARA  DTAARA(FLDS) +`
- line 13: `CHGDTAARA  DTAARA(FLGHT400/FLDS (1 5)) +`  →  `CHGDTAARA  DTAARA(FLDS (1 5)) +`

### QDDSSRCD/FRS000DF

- line 28: `A            AGNTNM    R   10   B  6 40REFFLD(ORDERS/AGENT_NAME FLGHT400/A-`  →  `A            AGNTNM    R   10   B  6 40REFFLD(ORDERS/AGENT_NAME A-`
- line 38: `A            PASSWD    R   10   B  8 40REFFLD(ORDERS/AGENT00001 FLGHT400/A-`  →  `A            PASSWD    R   10   B  8 40REFFLD(ORDERS/AGENT00001 A-`

### QDDSSRCD/FRS023DF

- line 30: `A            SAGEN#    R    4D  B  6 46REFFLD(ORDERS/AGENT_NO FLGHT400/AGE-`  →  `A            SAGEN#    R    4D  B  6 46REFFLD(ORDERS/AGENT_NO AGE-`
- line 39: `A            SAGENT    R   10   B  8 40REFFLD(ORDERS/AGENT_NAME FLGHT400/A-`  →  `A            SAGENT    R   10   B  8 40REFFLD(ORDERS/AGENT_NAME A-`
- line 55: `A            SPASSW    R   10   B 10 40REFFLD(ORDERS/AGENT00001 FLGHT400/A-`  →  `A            SPASSW    R   10   B 10 40REFFLD(ORDERS/AGENT00001 A-`

### QDDSSRCD/FRS024DF

- line 31: `A            SCUST#    R    6D  B  6 44REFFLD(CUSTZ/CUSTNO FLGHT400/CUSTOM-`  →  `A            SCUST#    R    6D  B  6 44REFFLD(CUSTZ/CUSTNO CUSTOM-`
- line 41: `A            SCUSTN    R   25   B  8 25REFFLD(CUSTZ/CUSTNM FLGHT400/CUSTOM-`  →  `A            SCUSTN    R   25   B  8 25REFFLD(CUSTZ/CUSTNM CUSTOM-`

### QDDSSRCD/FRS025DF

- line 30: `A            SAIRLN    R   16A  B  6 34REFFLD(AIRLNR/AIRLNM FLGHT400/AIRLI-`  →  `A            SAIRLN    R   16A  B  6 34REFFLD(AIRLNR/AIRLNM AIRLI-`
- line 40: `A            SAIRLI    R    3A  B  8 25REFFLD(AIRLNR/AIRLIN FLGHT400/AIRLI-`  →  `A            SAIRLI    R    3A  B  8 25REFFLD(AIRLNR/AIRLIN AIRLI-`

### QDDSSRCD/FRS401DF

- line 4: `A                                      REF(FLGHT400/CUSTNAME)`  →  `A                                      REF(CUSTNAME)`
- line 22: `A            SELIO          1A  I  8  3CHKMSGID(FRS0028 FLGHT400/FRSMSGF)`  →  `A            SELIO          1A  I  8  3CHKMSGID(FRS0028 FRSMSGF)`
- line 24: `A            OAGNT#    R    4   O  8  8REFFLD(ANAMER/AGNMBR FLGHT400/AGENT-`  →  `A            OAGNT#    R    4   O  8  8REFFLD(ANAMER/AGNMBR AGENT-`
- line 27: `A            OAGNTN    R   25   O  8 16REFFLD(ANAMER/AGNAME FLGHT400/AGENT-`  →  `A            OAGNTN    R   25   O  8 16REFFLD(ANAMER/AGNAME AGENT-`

### QDDSSRCD/FRS401DFB

- line 4: `A                                      REF(FLGHT400/AGENTSL)`  →  `A                                      REF(AGENTSL)`
- line 21: `A                                      CHKMSGID(FRS0028 FLGHT400/FRSMSGF)`  →  `A                                      CHKMSGID(FRS0028 FRSMSGF)`
- line 23: `A            OAGNT#    R    2   O  6  9REFFLD(ANAMER/AGNMBR FLGHT400/AGENT-`  →  `A            OAGNT#    R    2   O  6  9REFFLD(ANAMER/AGNMBR AGENT-`
- line 25: `A            OAGNTN    R   25   O  6 14REFFLD(ANAMER/AGNAME FLGHT400/AGENT-`  →  `A            OAGNTN    R   25   O  6 14REFFLD(ANAMER/AGNAME AGENT-`

### QDDSSRCD/FRS402DF

- line 4: `A                                      REF(FLGHT400/FRCITY)`  →  `A                                      REF(FRCITY)`
- line 22: `A            SELIO          1A  I  8  7CHKMSGID(FRS0028 FLGHT400/FRSMSGF)`  →  `A            SELIO          1A  I  8  7CHKMSGID(FRS0028 FRSMSGF)`

### QDDSSRCD/FRS402DFB

- line 4: `A                                      REF(FLGHT400/FRCITY)`  →  `A                                      REF(FRCITY)`
- line 21: `A                                      CHKMSGID(FRS0028 FLGHT400/FRSMSGF)`  →  `A                                      CHKMSGID(FRS0028 FRSMSGF)`
- line 23: `A            SFCTYN    R        O  6 16REFFLD(FRCTYR/FRCNAM FLGHT400/FRCIT-`  →  `A            SFCTYN    R        O  6 16REFFLD(FRCTYR/FRCNAM FRCIT-`

### QDDSSRCD/FRS403DF

- line 4: `A                                      REF(FLGHT400/TOCITY)`  →  `A                                      REF(TOCITY)`
- line 22: `A            SELIO          1A  I  8  7CHKMSGID(FRS0028 FLGHT400/FRSMSGF)`  →  `A            SELIO          1A  I  8  7CHKMSGID(FRS0028 FRSMSGF)`

### QDDSSRCD/FRS404DF

- line 4: `A                                      REF(FLGHT400/FLIGHTSL)`  →  `A                                      REF(FLIGHTSL)`
- line 21: `A                                      CHKMSGID(FRS0028 FLGHT400/FRSMSGF)`  →  `A                                      CHKMSGID(FRS0028 FRSMSGF)`
- line 23: `A            AIRLNM    R    3   O  6  4REFFLD(FLGHTR/AIRLNM FLGHT400/FLIGH-`  →  `A            AIRLNM    R    3   O  6  4REFFLD(FLGHTR/AIRLNM FLIGH-`
- line 25: `A            FLGHTN    R    7   O  6  8REFFLD(FLGHTR/FLGHTN FLGHT400/FLIGH-`  →  `A            FLGHTN    R    7   O  6  8REFFLD(FLGHTR/FLGHTN FLIGH-`
- line 27: `A            DYOFWK    R    2   O  6 17REFFLD(FLGHTR/DYOFWK FLGHT400/FLIGH-`  →  `A            DYOFWK    R    2   O  6 17REFFLD(FLGHTR/DYOFWK FLIGH-`
- line 29: `A            DPTIME    R    8   O  6 21REFFLD(FLGHTR/DPTIME FLGHT400/FLIGH-`  →  `A            DPTIME    R    8   O  6 21REFFLD(FLGHTR/DPTIME FLIGH-`
- line 31: `A            ARTIME    R    8   O  6 30REFFLD(FLGHTR/ARTIME FLGHT400/FLIGH-`  →  `A            ARTIME    R    8   O  6 30REFFLD(FLGHTR/ARTIME FLIGH-`
- line 33: `A            PRICE     R    3   O  6 39REFFLD(FLGHTR/TCKTPR FLGHT400/FLIGH-`  →  `A            PRICE     R    3   O  6 39REFFLD(FLGHTR/TCKTPR FLIGH-`

### QDDSSRCD/FRS405DF

- line 4: `A                                      REF(FLGHT400/CUSTNAME)`  →  `A                                      REF(CUSTNAME)`
- line 22: `A            SELIO          1A  I  8  3CHKMSGID(FRS0028 FLGHT400/FRSMSGF)`  →  `A            SELIO          1A  I  8  3CHKMSGID(FRS0028 FRSMSGF)`
- line 24: `A            CUST#     R    6   O  8  7REFFLD(CUSTR/CUSTNO FLGHT400/CUSTNA-`  →  `A            CUST#     R    6   O  8  7REFFLD(CUSTR/CUSTNO CUSTNA-`
- line 26: `A            CUSTN     R   25   O  8 16REFFLD(CUSTR/CUSTNM FLGHT400/CUSTNA-`  →  `A            CUSTN     R   25   O  8 16REFFLD(CUSTR/CUSTNM CUSTNA-`

### QDDSSRCD/FRS407DF

- line 4: `A                                      REF(FLGHT400/ORDDATE)`  →  `A                                      REF(ORDDATE)`
- line 22: `A            SELIO          1A  I  8  2CHKMSGID(FRS0028 FLGHT400/FRSMSGF)`  →  `A            SELIO          1A  I  8  2CHKMSGID(FRS0028 FRSMSGF)`
- line 24: `A            ORDRN     R        O  8  4REFFLD(ORDDTR/ORDRNO FLGHT400/ORDDA-`  →  `A            ORDRN     R        O  8  4REFFLD(ORDDTR/ORDRNO ORDDA-`
- line 27: `A            CUSTN     R   25   O  8 27REFFLD(ORDDTR/CUSTNM FLGHT400/ORDDA-`  →  `A            CUSTN     R   25   O  8 27REFFLD(ORDDTR/CUSTNM ORDDA-`

### QDDSSRCD/FRS408DF

- line 4: `A                                      REF(FLGHT400/CUSTORD)`  →  `A                                      REF(CUSTORD)`
- line 22: `A            SELIO          1A  I  8  2CHKMSGID(FRS0028 FLGHT400/FRSMSGF)`  →  `A            SELIO          1A  I  8  2CHKMSGID(FRS0028 FRSMSGF)`
- line 24: `A            ORDRN     R        O  8  6REFFLD(CUSNMR/ORDRNO FLGHT400/CUSTO-`  →  `A            ORDRN     R        O  8  6REFFLD(CUSNMR/ORDRNO CUSTO-`
- line 26: `A            CUSTN     R   25   O  8 17REFFLD(CUSNMR/CUSTNM FLGHT400/CUSTO-`  →  `A            CUSTN     R   25   O  8 17REFFLD(CUSNMR/CUSTNM CUSTO-`

### QDDSSRCD/FRS412DF

- line 4: `A                                      REF(FLGHT400/TOCITY)`  →  `A                                      REF(TOCITY)`
- line 21: `A                                      CHKMSGID(FRS0028 FLGHT400/FRSMSGF)`  →  `A                                      CHKMSGID(FRS0028 FRSMSGF)`

### QDDSSRCD/FRS413DF

- line 4: `A                                      REF(FLGHT400/FLIGHTSZ)`  →  `A                                      REF(FLIGHTSZ)`
- line 22: `A            MILES     R    5D00H      REFFLD(FLGHTR/MILES FLGHT400/FLIGHT-`  →  `A            MILES     R    5D00H      REFFLD(FLGHTR/MILES FLIGHT-`
- line 24: `A            SEATS     R    3D00H      REFFLD(FLGHTR/SEATS FLGHT400/FLIGHT-`  →  `A            SEATS     R    3D00H      REFFLD(FLGHTR/SEATS FLIGHT-`
- line 26: `A            FRCITY    R   16   H      REFFLD(FLGHTR/DPCNAM FLGHT400/FLIGH-`  →  `A            FRCITY    R   16   H      REFFLD(FLGHTR/DPCNAM FLIGH-`
- line 28: `A            TOCITY    R   16   H      REFFLD(FLGHTR/ARCNAM FLGHT400/FLIGH-`  →  `A            TOCITY    R   16   H      REFFLD(FLGHTR/ARCNAM FLIGH-`
- line 30: `A            AIRLNF    R   16   H      REFFLD(FLGHTR/AIRLNM FLGHT400/FLIGH-`  →  `A            AIRLNF    R   16   H      REFFLD(FLGHTR/AIRLNM FLIGH-`
- line 32: `A            DYOFW9    R    9   H      REFFLD(FLGHTR/DYOFWK FLGHT400/FLIGH-`  →  `A            DYOFW9    R    9   H      REFFLD(FLGHTR/DYOFWK FLIGH-`
- line 34: `A            SELIO          1A  I  8  2CHKMSGID(FRS0028 FLGHT400/FRSMSGF)`  →  `A            SELIO          1A  I  8  2CHKMSGID(FRS0028 FRSMSGF)`
- line 36: `A            AIRLNM    R    3   O  8  4REFFLD(FLGHTR/AIRLNM FLGHT400/FLIGH-`  →  `A            AIRLNM    R    3   O  8  4REFFLD(FLGHTR/AIRLNM FLIGH-`
- line 38: `A            FLGHTN    R    7   O  8  8REFFLD(FLGHTR/FLGHTN FLGHT400/FLIGH-`  →  `A            FLGHTN    R    7   O  8  8REFFLD(FLGHTR/FLGHTN FLIGH-`
- line 40: `A            DYOFWK    R    2   O  8 16REFFLD(FLGHTR/DYOFWK FLGHT400/FLIGH-`  →  `A            DYOFWK    R    2   O  8 16REFFLD(FLGHTR/DYOFWK FLIGH-`
- line 43: `A            DPTIME    R    8   O  8 23REFFLD(FLGHTR/DPTIME FLGHT400/FLIGH-`  →  `A            DPTIME    R    8   O  8 23REFFLD(FLGHTR/DPTIME FLIGH-`
- line 46: `A            ARTIME    R    8   O  8 36REFFLD(FLGHTR/ARTIME FLGHT400/FLIGH-`  →  `A            ARTIME    R    8   O  8 36REFFLD(FLGHTR/ARTIME FLIGH-`
- line 48: `A            PRICE     R    3   O  8 45REFFLD(FLGHTR/TCKTPR FLGHT400/FLIGH-`  →  `A            PRICE     R    3   O  8 45REFFLD(FLGHTR/TCKTPR FLIGH-`

### QMNUSRC/FRSMAINQQ

- line 2: `0001 CALL FLGHT400/FRS000 PARM('CREATE')`  →  `0001 CALL FRS000 PARM('CREATE')`
- line 3: `0002 CALL FLGHT400/FRS000 PARM('UPDATE')`  →  `0002 CALL FRS000 PARM('UPDATE')`
- line 4: `0003 CALL FLGHT400/FRS000 PARM('DSPLAY')`  →  `0003 CALL FRS000 PARM('DSPLAY')`
- line 5: `0004 CALL FLGHT400/FRS000 PARM('DELETE')`  →  `0004 CALL FRS000 PARM('DELETE')`
- line 6: `0005 CALL FLGHT400/FRS000 PARM('FAX   ')`  →  `0005 CALL FRS000 PARM('FAX   ')`
- line 7: `0010 CALL FLGHT400/FRS000 PARM('MAINT ')`  →  `0010 CALL FRS000 PARM('MAINT ')`
- line 8: `0020 CALL FLGHT400/FRS000 PARM('REPORT')`  →  `0020 CALL FRS000 PARM('REPORT')`

### QMNUSRC/FRSMANTQQ

- line 2: `0001 CALL FLGHT400/FRS024`  →  `0001 CALL FRS024`
- line 3: `0002 CALL FLGHT400/FRS021`  →  `0002 CALL FRS021`
- line 4: `0003 CALL FLGHT400/FRS022`  →  `0003 CALL FRS022`
- line 5: `0004 UPDDTA FLGHT400/AIRLINE`  →  `0004 UPDDTA AIRLINE`
- line 6: `0005 CALL FLGHT400/FRS023`  →  `0005 CALL FRS023`

### QMNUSRC/FRSREPTQQ

- line 2: `0001 SBMJOB CMD(RUNQRY QRY(FLGHT400/ALLAGENTS))`  →  `0001 SBMJOB CMD(RUNQRY QRY(ALLAGENTS))`
- line 3: `0002 RUNQRY QRY(FLGHT400/SELAGENTS) RCDSLT(*YES)`  →  `0002 RUNQRY QRY(SELAGENTS) RCDSLT(*YES)`
- line 4: `0003 RUNQRY QRY(FLGHT400/PRTFLIGHT) RCDSLT(*YES)`  →  `0003 RUNQRY QRY(PRTFLIGHT) RCDSLT(*YES)`
- line 5: `0004 RUNQRY QRY(FLGHT400/DSPFLIGHT) RCDSLT(*YES)`  →  `0004 RUNQRY QRY(DSPFLIGHT) RCDSLT(*YES)`
- `RUNQRY QRY(FLGHT400/ALLAGENTS|SELAGENTS|PRTFLIGHT|DSPFLIGHT)`  →  saved *QRYDFN query objects are not in the source - replaced with ad-hoc RUNQRY QRY(*NONE) over AGENTS / FLIGHTS

### QRPGLESRC/FRS021

- line 89: `msgFile CHAR(20) INZ('FRSMSGF   FLGHT400');`  →  `msgFile CHAR(20) INZ('FRSMSGF   *LIBL   ');`

### QRPGLESRC/FRS401

- line 80: `msgFile char(20) inz('FRSMSGF   FLGHT400  ');`  →  `msgFile char(20) inz('FRSMSGF   *LIBL     ');`

### QRPGLESRC/FRS402

- line 52: `MSGF CHAR(20) INZ('FRSMSGF   FLGHT400  ');`  →  `MSGF CHAR(20) INZ('FRSMSGF   *LIBL     ');`

### QRPGLESRC/FRS402B

- line 38: `MSGF Char(20) Inz('FRSMSGF   FLGHT400  ');`  →  `MSGF Char(20) Inz('FRSMSGF   *LIBL     ');`

### QRPGLESRC/FRS408

- line 66: `MSGF Char(20) Inz('FRSMSGF   FLGHT400  ');`  →  `MSGF Char(20) Inz('FRSMSGF   *LIBL     ');`

### QRPGLESRC/FRS412

- line 55: `msgf CHAR(20) INZ('FRSMSGF   FLGHT400  ');`  →  `msgf CHAR(20) INZ('FRSMSGF   *LIBL     ');`

### QRPGLESRC/FRS413

- line 85: `MSGF CHAR(20) INZ('FRSMSGF   FLGHT400  ');`  →  `MSGF CHAR(20) INZ('FRSMSGF   *LIBL     ');`

### QRPGLESRC/X2FRS024

- line 84: `messageFile CHAR(20) INZ('FRSMSGF   FLGHT400  ');`  →  `messageFile CHAR(20) INZ('FRSMSGF   *LIBL     ');`

### QRPGLESRC/XXFRS024

- line 97: `MsgFile CHAR(20) INZ('FRSMSGF   FLGHT400  ');`  →  `MsgFile CHAR(20) INZ('FRSMSGF   *LIBL     ');`

### QRPGSRC/FRS000

- line 48: `I I            'FRSMSGF   FLGHT400  '    9  28 MSGF`  →  `I I            'FRSMSGF   *LIBL     '    9  28 MSGF`
- line 72: `I I            'GO FLGHT400/FRSMANT'     1  19 GOCMD1`  →  `I I            'GO FRSMANT         '     1  19 GOCMD1`
- line 75: `I I            'GO FLGHT400/FRSREPT'     1  19 GOCMD2`  →  `I I            'GO FRSREPT         '     1  19 GOCMD2`

### QRPGSRC/FRS001

- line 71: `I I            'FRSMSGF   FLGHT400  '    9  28 MSGF`  →  `I I            'FRSMSGF   *LIBL     '    9  28 MSGF`

### QRPGSRC/FRS001T

- line 69: `I I            'FRSMSGF   FLGHT400  '    9  28 MSGF`  →  `I I            'FRSMSGF   *LIBL     '    9  28 MSGF`

### QRPGSRC/FRS001U

- line 69: `I I            'FRSMSGF   FLGHT400  '    9  28 MSGF`  →  `I I            'FRSMSGF   *LIBL     '    9  28 MSGF`

### QRPGSRC/FRS001U2

- line 69: `I I            'FRSMSGF   FLGHT400  '    9  28 MSGF`  →  `I I            'FRSMSGF   *LIBL     '    9  28 MSGF`

### QRPGSRC/FRS001X

- line 79: `I I            'FRSMSGF   FLGHT400  '    9  28 MSGF`  →  `I I            'FRSMSGF   *LIBL     '    9  28 MSGF`

### QRPGSRC/FRS002

- line 90: `I I            'FRSMSGF   FLGHT400  '    9  28 MSGF`  →  `I I            'FRSMSGF   *LIBL     '    9  28 MSGF`

### QRPGSRC/FRS005

- line 55: `I I            'FRSMSGF   FLGHT400  '    9  28 MSGF`  →  `I I            'FRSMSGF   *LIBL     '    9  28 MSGF`

### QRPGSRC/FRS009

- line 59: `MSGF    Char(20)  Pos(9)   Inz('FRSMSGF   FLGHT400  ');`  →  `MSGF    Char(20)  Pos(9)   Inz('FRSMSGF   *LIBL     ');`
- line 219: `QMHSNDPM(MSGID : MSGF : MSGDTA : MSGLEN : MSGTYP : MSGQUE : MSGCTR : MSGKEY :`  →  `line was cut off at column 80 in the save file - re-split and closed with APIERR);`

### QRPGSRC/FRS021

- line 70: `I I            'FRSMSGF   FLGHT400  '    9  28 MSGF`  →  `I I            'FRSMSGF   *LIBL     '    9  28 MSGF`

### QRPGSRC/FRS022

- line 633: `DCL-S messageFile CHAR(20) INZ('FRSMSGF   FLGHT400');`  →  `DCL-S messageFile CHAR(20) INZ('FRSMSGF   *LIBL   ');`

### QRPGSRC/FRS023

- line 58: `I I            'FRSMSGF   FLGHT400  '    9  28 MSGF`  →  `I I            'FRSMSGF   *LIBL     '    9  28 MSGF`

### QRPGSRC/FRS024

- line 60: `I I            'FRSMSGF   FLGHT400  '    9  28 MSGF`  →  `I I            'FRSMSGF   *LIBL     '    9  28 MSGF`

### QRPGSRC/FRS401

- line 33: `I I            'FRSMSGF   FLGHT400  '    9  28 MSGF`  →  `I I            'FRSMSGF   *LIBL     '    9  28 MSGF`

### QRPGSRC/FRS401B

- line 32: `I I            'FRSMSGF   FLGHT400  '    9  28 MSGF`  →  `I I            'FRSMSGF   *LIBL     '    9  28 MSGF`

### QRPGSRC/FRS402

- line 28: `I I            'FRSMSGF   FLGHT400  '    9  28 MSGF`  →  `I I            'FRSMSGF   *LIBL     '    9  28 MSGF`

### QRPGSRC/FRS402B

- line 28: `I I            'FRSMSGF   FLGHT400  '    9  28 MSGF`  →  `I I            'FRSMSGF   *LIBL     '    9  28 MSGF`

### QRPGSRC/FRS403

- line 28: `I I            'FRSMSGF   FLGHT400  '    9  28 MSGF`  →  `I I            'FRSMSGF   *LIBL     '    9  28 MSGF`

### QRPGSRC/FRS404

- line 39: `I I            'FRSMSGF   FLGHT400  '    9  28 MSGF`  →  `I I            'FRSMSGF   *LIBL     '    9  28 MSGF`

### QRPGSRC/FRS404B

- line 39: `I I            'FRSMSGF   FLGHT400  '    9  28 MSGF`  →  `I I            'FRSMSGF   *LIBL     '    9  28 MSGF`

### QRPGSRC/FRS405

- line 31: `I I            'FRSMSGF   FLGHT400  '    9  28 MSGF`  →  `I I            'FRSMSGF   *LIBL     '    9  28 MSGF`

### QRPGSRC/FRS407

- line 38: `I I            'FRSMSGF   FLGHT400  '    9  28 MSGF`  →  `I I            'FRSMSGF   *LIBL     '    9  28 MSGF`

### QRPGSRC/FRS408

- line 38: `I I            'FRSMSGF   FLGHT400  '    9  28 MSGF`  →  `I I            'FRSMSGF   *LIBL     '    9  28 MSGF`

### QRPGSRC/FRS412

- line 28: `I I            'FRSMSGF   FLGHT400  '    9  28 MSGF`  →  `I I            'FRSMSGF   *LIBL     '    9  28 MSGF`

### QRPGSRC/FRS413

- line 42: `I I            'FRSMSGF   FLGHT400  '    9  28 MSGF`  →  `I I            'FRSMSGF   *LIBL     '    9  28 MSGF`
### QRPGSRC/FRS009 (Bob conversion fix)

- `Dcl-F FORDERSZ ...` / `%Found(FORDERSZ)` → `ORDERSZ`. The free-form conversion took the RPG III F-spec letter as part of the file name; there is no file called FORDERSZ.

### QCLPSRC/MSGPGM2

- `DCLF FILE(CBCLIB/MSGPANEL)` → `DCLF FILE(MSGPANEL)` (CBCLIB was a library on the original author's system)
