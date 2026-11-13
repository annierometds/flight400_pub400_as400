PGM

DCL        &CHKFLD *CHAR    1 VALUE('N')

CHKOBJ     OBJ(FLDS) OBJTYPE(*DTAARA)
MONMSG     MSGID(CPF9801) EXEC(CHGVAR &CHKFLD 'Y')
IF         (&CHKFLD *EQ 'Y') DO
                             CRTDTAARA  DTAARA(FLDS) +
                                        TYPE(*CHAR) +
                                        LEN(5) VALUE('CLEAR')
                             ENDDO
IF         (&CHKFLD *EQ 'N') DO
                             CHGDTAARA  DTAARA(FLDS (1 5)) +
                                        VALUE('CLEAR')
                             ENDDO

DSPDTAARA  DTAARA(FLDS)

ENDPGM
