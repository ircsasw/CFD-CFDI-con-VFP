* --
* -- Este ejemplo genera un CFD version 3.2 utilizando la clase CFD y
* -- mostrando el uso del nodo Complemento de un Comprobante.
* --
*
CLOSE ALL
CLEAR ALL
CLEAR

SET CONFIRM OFF
SET SAFETY OFF
SET DATE ITALIAN   

SET PROCEDURE TO cfd
SET PROCEDURE TO CFDComplementoNomina ADDITIVE  && Implementacion del complemento Nomina

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
 .XMLversion = CFDVersions.CFDi_32
 *.XMLversion = CFDVersions.CFD_20
 .incluirBOM = .F.
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
 .Fecha = DATETIME()						&& Fecha de elaboración del recibo.
 .formaDePago = "Una sola exhibición"
 .condicionesDePago = "Contado"
 .subTotal = -911.8400						&& Sumatoria de los importes de los conceptos.
 .Total = -879.8400							&& Pago realizado al trabajador. Será igual al Subtotal menos los Descuentos, menos las Retenciones efectuadas.
 .Descuento = 0.00							&& Será el Total de las deducciones (suma del total gravado y total exento, sin considerar el ISR retenido.)
 .motivoDescuento = "Deducciones nómina"	&& Utilizar "Deducciones nómina"
 .tipoDeComprobante = "egreso"				&& Egreso
 
 *-- Atributos CFD 3.2 opcionales 
 .Serie = "A"
 .Folio = 25815
 .MontoFolioFiscalOrig = NULL
 .FechaFolioFiscalOrig = {}
 .SerieFolioFiscalOrig = NULL
 .FolioFiscalOrig = NULL
 .NumCtaPago = NULL
 .Moneda = "MXN"
 .TipoCambio = NULL
 
 *-- Atributos CFD 3.2 requeridos 
 .LugarExpedicion = "Cancún, Q.Roo"			&& Señalar el lugar de la plaza en donde labore el empleado
 .metodoDePago = "Efectivo"
 
 
 * - Información del contribuyente emisor del recibo de nómina como CFDI (Patrón).
 .Emisor.RFC = "GOYA780416GM0"				&& RFC del patrón
 .Emisor.nombre = "ANA CECILIA GOMEZ YAÑEZ" && Opcional en 3.2
 
 * -- DomicilioFiscal Opcional en 3.2
 .Emisor.domicilioFiscal.Calle = "Benito Juarez Ote"
 .Emisor.domicilioFiscal.noExterior = "106"
 .Emisor.domicilioFiscal.noInterior = "1" 
 .Emisor.domicilioFiscal.Colonia = "Centro"
 .Emisor.domicilioFiscal.Municipio = "Cd. Guadalupe"
 .Emisor.domicilioFiscal.Localidad = "México" 
 .Emisor.domicilioFiscal.Estado = "Nuevo León"
 .Emisor.domicilioFiscal.Pais = "Mexico"   && Único Requerido si DomicilioFiscal esta presente
 .Emisor.domicilioFiscal.codigoPostal = "67100"

 * -- ExpedidoEn Opcional
 .Emisor.expedidoEn.Calle = "Benito Juarez Ote"
 .Emisor.expedidoEn.noExterior = "106"
 .Emisor.expedidoEn.noInterior = "1" 
 .Emisor.expedidoEn.Colonia = "Centro"
 .Emisor.expedidoEn.Municipio = "Cd. Guadalupe"
 .Emisor.expedidoEn.Localidad = "Cd. Guadalupe" 
 .Emisor.expedidoEn.Estado = "Nuevo León"
 .Emisor.expedidoEn.Pais = "México"	
 .Emisor.expedidoEn.codigoPostal = "67100"
 
 * -- Nuevo y obligatorio en 3.2 (puede ser uno o muchos)
 .Emisor.RegimenFiscal.Regimen = "Actividad Empresarial" 
 
 
 * - Información del contribuyente receptor del recibo de nómina como CFDI (trabajador).
 .Receptor.RFC = "EAM001231D51"				&& RFC Trabajador
 .Receptor.Nombre = "ENVASADORAS DE AGUAS EN MÉXICO, S. DE R. L. DE C.V."   && Opcional en 3.2
 
 * -- Domicilio de Receptor opcional en 3.2
 .Receptor.domicilioFiscal.Calle = "AVE. LA SILLA"
 .Receptor.domicilioFiscal.noExterior = "7707"
 .Receptor.domicilioFiscal.noInterior = "1" 
 .Receptor.domicilioFiscal.Colonia = "PARQUE INDUSTRIAL LA SILLA"
 .Receptor.domicilioFiscal.Localidad = "GUADALUPE" 
 .Receptor.domicilioFiscal.Municipio = "GUADALUPE"
 .Receptor.domicilioFiscal.Estado = "NUEVO LEÓN"
 .Receptor.domicilioFiscal.Pais = "México"    && Único Requerido si Domicilio esta presente
 .Receptor.domicilioFiscal.codigoPostal = "67190"
 
 * - IVA NO APLICA PARA NOMINAS
 *.Impuestos.Traslados.Add("IVA",16.00,640.00)
 
 * - Detalles del pago de nomina
 o = .Conceptos.Add(1.000, "SUELDO DE LA JORNADA", 1500.00, 1500.00)    && Cantidad SIEMPRE 1
 o.noIdentificacion = "SUELDO"
 o.Unidad = "SERVICIO"						&& Se utilizará la expresión "Servicio"
  

 *-- El complemento se implementa asignando una instancia de una clase derivada
 *   de ICFDAddenda. En este caso, la clase es CFDComplementoNomina (ver el archivo
 *   CFDCOMPLEMENTONOMINA.PRG)
 .Complemento = CREATEOBJECT("CFDComplementoNomina")
 WITH .Complemento
  * 
  
 ENDWITH

ENDWITH
??"...Version " + CFDVersions.ToLongString(CFDVersions.fromString(oCFD.Version))

*-- Se carga la informacion del certificado 
*
LOCAL cArchivoKey, cArchivoCer
* Para pruebas con certificados del SAT
cArchivoKey = "aaa010101aaa_CSD_01.key"
cArchivoCer = "aaa010101aaa_CSD_01.cer"
cPasswrdKey = "a0123456789"

* Certificado de pruebas del PAC
*cArchivoKey = "goya780416gm0_1011181055s.key"
*cArchivoCer = "goya780416gm0.cer"
*cPasswrdKey = "12345678a"


?"- Validando archivos key y cer..."
IF NOT CFDValidarKeyCer(cArchivoKey, cArchivoCer, cPasswrdKey,".\SSL")
 ?"ERROR: " + CFDConf.ultimoError
 RETURN
ENDIF

?"- Leyendo certificado"
LOCAL oCert
oCert = oCFD.leerCertificado(cArchivoCer)
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
IF NOT oCFD.Sellar(cArchivoKey,cPasswrdKey)
 ?"ERROR: " + CFDConf.ultimoError
 RETURN
ENDIF



*-- Se crea el CFD
*
?"- Creando CFD"
oCFD.CrearXML("testcomplementoconcepto.xml")



*-- Se vaaida el CFD
*
?"- Validando CFD"
IF NOT CFDValidarXML("testcomplementoconcepto.xml",cArchivoKey, cPasswrdKey, "sha1", ".\SSL")
 ?"ERROR: " + CFDConf.ultimoError
 RETURN
ELSE 
  ??" OK"
ENDIF



RETURN



