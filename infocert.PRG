CLOSE ALL
CLEAR ALL
CLEAR

SET CONFIRM OFF
SET SAFETY OFF
SET DATE ITALIAN   

SET PROCEDURE TO cfd

CFDInit()

?"CFD v" + CFDConf.Version
?"Info de certificado"
?
?

?"- Probando OpenSSL..."
IF CFDProbarOpenSSL()
 ??"OK! ("+STRT(CFDConf.ultimoError,CHR(13)+CHR(10),"")+")"
ELSE
 ?"ERROR: "
 ?CFDConf.ultimoError
 RETURN
ENDIF
    

*-- Se carga la informacion del certificado 
*
LOCAL cArchivoCer,oInfo
cArchivoCer = "aaa010101aaa_CSD_01.cer"
oInfo = CFDLeerCertificado(cArchivoCer)
?"- Serial certificado: " + oInfo.Serial



