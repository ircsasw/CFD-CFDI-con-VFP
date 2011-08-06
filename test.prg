CLOSE ALL
CLEAR ALL
CLEAR

SET CONFIRM OFF
SET SAFETY OFF
SET DATE ITALIAN   

SET PROCEDURE TO cfd

CFDInit()

?"CFD v" + CFDConf.Version
?"Demo"
?
?

?"- Inicializando..."
WITH CFDConf
 .OpenSSL = ".\SSL"
 .SMTPServer = "smtp.gmail.com" 
 .SMTPPort = 465
 .SMTPUserName = "sucuenta@gmail.com"
 .SMTPPassword = "su-contrasena"
 .MailSender = "sucuenta@gmail.com"
 .modoPruebas = .T.
ENDWITH


?"- Probando OpenSSL..."
IF CFDProbarOpenSSL()
 ??"OK! ("+STRT(CFDConf.ultimoError,CHR(13)+CHR(10),"")+")"
ELSE
 ?"ERROR: "
 ?CFDConf.ultimoError
 RETURN
ENDIF
    
    
?"- Generando CFD..."    
LOCAL oCFD, o
oCFD = CREATEOBJECT("CFDComprobante")
WITH oCFD
 .Serie = "A"
 .Folio = 25810
 .Fecha = DATETIME()
 .noAprobacion = 1
 .anoAprobacion = 2009
 .formaDePago = "Una sola exhibición"
 .condicionesDePago = "A 30 días"
 .metodoDePago = "Cheque"
 .subTotal = 4371.00
 .Total = 4640.00
 .Descuento = 371.00
 .motivoDescuento = "Anticipo"
 .tipoDeComprobante = "ingreso"
 .Emisor.RFC = "EGC980817DF3"
 .Emisor.nombre = "Elit Grupo Comercial, S.A. de C.V." 
 .Emisor.domicilioFiscal.Calle = "Benito Juarez Ote"
 .Emisor.domicilioFiscal.noExterior = "106"
 .Emisor.domicilioFiscal.noInterior = "1" 
 .Emisor.domicilioFiscal.Colonia = "Centro"
 .Emisor.domicilioFiscal.Municipio = "Cd. Guadalupe"
 .Emisor.domicilioFiscal.Localidad = "México" 
 .Emisor.domicilioFiscal.Estado = "Nuevo León"
 .Emisor.domicilioFiscal.Pais = "Mexico"
 .Emisor.domicilioFiscal.codigoPostal = "67100"

 .Emisor.expedidoEn.Calle = "Benito Juarez Ote"
 .Emisor.expedidoEn.noExterior = "106"
 .Emisor.expedidoEn.noInterior = "1" 
 .Emisor.expedidoEn.Colonia = "Centro"
 .Emisor.expedidoEn.Municipio = "Cd. Guadalupe"
 .Emisor.expedidoEn.Localidad = "Cd. Guadalupe" 
 .Emisor.expedidoEn.Estado = "Nuevo León"
 .Emisor.expedidoEn.Pais = "México"	
 .Emisor.expedidoEn.codigoPostal = "67100"
 
 .Receptor.RFC = "EAM001231D51"
 .Receptor.Nombre = "ENVASADORAS DE AGUAS EN MÉXICO, S. DE R. L. DE C.V." 
 .Receptor.domicilioFiscal.Calle = "AVE. LA SILLA"
 .Receptor.domicilioFiscal.noExterior = "7707"
 .Receptor.domicilioFiscal.noInterior = "1" 
 .Receptor.domicilioFiscal.Colonia = "PARQUE INDUSTRIAL LA SILLA"
 .Receptor.domicilioFiscal.Localidad = "GUADALUPE" 
 .Receptor.domicilioFiscal.Municipio = "GUADALUPE"
 .Receptor.domicilioFiscal.Estado = "NUEVO LEÓN"
 .Receptor.domicilioFiscal.Pais = "México"
 .Receptor.domicilioFiscal.codigoPostal = "67190"
 
 .Impuestos.Traslados.Add("IVA",16.00,640.00)
 
 o = .Conceptos.Add(1.000, "ARCO PARA SEGUETA DE ALTA TENS", 176.00, 176.00)    
 o.noIdentificacion = "ABC-12345"
 o.Unidad = "PIEZA"
 o.informacionAduanera.numero = "12345678901" 
 o.informacionAduanera.fecha = CTOD("15-12-2009")
 o.informacionAduanera.aduana = "240"

 o = .Conceptos.Add(1.000, "DOBLATUBO DE PALANCA 1/2", 1696.00, 1696.00)    
 o.noIdentificacion = "XYZ-67890"
 o.Unidad = "PIEZA"
    
 o = .Conceptos.Add(1.000, "CAUTÍN DE ESTACIÓN PROFESIONAL DE 50 WATTS", 2499.00, 2499.00)    
 o.noIdentificacion = "WED4567" 
 o.Unidad = "PIEZA"
 o.informacionAduanera.numero = "12345678901" 
 o.informacionAduanera.fecha = CTOD("15-12-2009")
 o.informacionAduanera.aduana = "240"
 
ENDWITH


*-- Se carga la informacion del certificado 
*
?"- Validando archivos key y cer..."
IF NOT CFDValidarKeyCer("aaa010101aaa_CSD_01.key","aaa010101aaa_CSD_01.cer","a0123456789",".\SSL")
 ?"ERROR: " + CFDConf.ultimoError
 RETURN
ENDIF

?"- Leyendo certificado"
LOCAL oCert
oCert = oCFD.leerCertificado("aaa010101aaa_CSD_01.cer")
IF ISNULL(oCert)
 ?"ERROR: " + CFDConf.ultimoError
 RETURN
ENDIF

IF NOT oCert.Valido
 ?"ERROR: El certificado no es valido"
 RETURN
ENDIF

IF (NOT oCert.Vigente) AND (NOT CFDConf.modoPruebas)
 ?"ERROR: El certificado no esta vigente"
 RETURN
ENDIF



*-- Se sella el CFD
*
?"- Generando sello digital"
IF NOT oCFD.Sellar("aaa010101aaa_CSD_01.key","a0123456789")
 ?"ERROR: " + CFDConf.ultimoError
 RETURN
ENDIF




*-- Se crea el CFD
*
?"- Creando CFD"
oCFD.CrearXML("test.xml")


*-- Se vaaida el CFD
*
?"- Validando CFD"
IF NOT CFDValidarXML("test.xml","aaa010101aaa_CSD_01.key", "a0123456789", "sha1", ".\SSL")
 ?"ERROR: " + CFDConf.ultimoError
 RETURN
ENDIF


*-- Se graba el CFD como PDF (se requiere PDFCreator)
*
?"- Generando PDF"
CFDPrint("test.xml",,.T.,"TEST.PDF")


*-- Se envia el CFD por correo. Configure los parametros apropiados
*   en CFDCOnf al inicio de este programa, y luego quite los comentarios
*   para poder enviar por correo
*
*   El envio por correo se hace usando CDO, asi que en teoria no es necesario
*   instalar ningun software adicional para que funcione
*
*?"- Enviando por correo"
*CFDEnviarPorCorreo("sucuenta@gmail.com","Asunto","Texto","TEST.PDF")


*-- Se imprime el CFD
*
?"- Imprimendo CFD"
CFDPrint("test.xml",.T.)





RETURN


