* --
* -- Este ejemplo genera un CFD version 3.2 utilizando la clase CFD y
* -- mostrando el uso del nodo Complemento de un Comprobante.
* --
** Adaptado al complemento parciales por Arturo Ramos.
**
** ARC	May, 17	- Pruebas del complemento
*

CLOSE ALL
CLEAR ALL
CLEAR

SET CONFIRM OFF
SET SAFETY OFF
SET DATE ITALIAN   

SET PROCEDURE TO cfd
set procedure to CFDComplementoParcialesConstruccion additive 
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
LOCAL oCFD, o, oPercepcion
			   
 ** It is based in guianomina12.pdf		   
oCFD = CREATEOBJECT("CFDComprobante")
WITH oCFD
 *-- Atributos CFD 3.2 
 .Serie = "A"
 .Folio = 25815
 .Fecha = DATETIME()												 	  && Fecha de elaboración del recibo.
 .formaDePago = "En una sola exhibición"
 .condicionesDePago = NULL		 	  && 1.2 It shouldn't exist. 
 .subTotal = 1011.8400											 	 	  && TotalPercepciones + TotalOtrosPagos.
 .Descuento = 0.00													 	  && 1.2 This is the discounts' total amount applied  before taxes. 
 																	 	  && 1.1 Será el Total de las deducciones (suma del total gravado y total exento, 
 																	 	  &&  sin considerar el ISR retenido.)
 .motivoDescuento = NULL	  											  && It shouldn't exist. 
 .TipoCambio = "1"  					 	  							  && It can be omitted, If it is included, it should has as value "1". 
 .Moneda = "MXN"
 .Total = 28550.8400												 	  && 1.2 TotalPercepciones + TotalOtrosPagos - TotalDeducciones.
 																	 	  && 1.1 Pago realizado al trabajador. Será igual al Subtotal menos los Descuentos, 
 																	 	  &&  menos las Retenciones efectuadas.
 .tipoDeComprobante = "egreso"
 .metodoDePago = "NA"          								   	    	  && 1.2 It should be designated "NA".
 .LugarExpedicion = "15900"		 	  									  && 1.2 c_CodigoPostal catalog. [0-9]{5}
 .NumCtaPago = NULL 												 	  && 1.2 It shouldn't exist.
 
 .FolioFiscalOrig = NULL 											 	  && 1.2 It shouldn't exist.
 .SerieFolioFiscalOrig = NULL 										 	  && 1.2 It shouldn't exist. 
 .FechaFolioFiscalOrig = {} 										 	  && 1.2 It shouldn't exist.
 .MontoFolioFiscalOrig = NULL 										 	  && 1.2 It shouldn't exist.

 * Emisor node.
 * Taxpayer's information of payroll receipt as cfdi (Employer).
 .Emisor.RFC = "AAD990814BP7"										 	  && RFC del patrón
 .Emisor.nombre = "ANA CECILIA GOMEZ YAÑEZ" 						 	  && Opcional en 3.2
 
 * 1.2 Issuer's address shouldn't exist
 
 * 1.2 It should exist one node.
 * -- Nuevo y obligatorio en 3.2 (puede ser uno o muchos)
 .Emisor.RegimenFiscal.Regimen = "Actividad Empresarial" 
 
 * Receptor node.
 * - Información del contribuyente receptor del recibo de nómina como CFDI (trabajador).
 .Receptor.RFC = "EAM001231D51"											  && RFC Trabajador
 .Receptor.Nombre = "ENVASADORAS DE AGUAS EN MÉXICO, S. DE R. L. DE C.V." && Opcional en 3.2
 
 * 1.2 Receiver's address shouldn't exist.
 
 * - Detalles del concepto
 o = .Conceptos.Add(1, "Reparaciones al cuarto principal", 1011.84, 1011.84)				  && Quantity 1, valorUnitario, imorte = TotalPercepciones + TotalOtrosPagos.
 o.noIdentificacion = NULL
 o.Unidad = "PIEZA"		

 * 1.2 It only should be registered the taxes as <Impuestos/> o <Impuestos></Impuestos>
ENDWITH


*-- El complemento se implementa asignando una instancia de una clase derivada
*   de ICFDAddenda. En este caso, la clase es CFDComplementoParcialesConstruccion (ver el archivo
*   CFDCOMPLEMENTOPARCIALESCONSTRUCCION.PRG)
*
LOCAL oComplemento
oComplemento = CREATEOBJECT("CFDComplementoParcialesConstruccion")
WITH oComplemento
 .NumPerLicoAut = "47386042"
 
 * - Inmueble
 .Inmueble.Calle = "Calle la Loma"
 .Inmueble.Municipio = "Benito Juárez"
 .Inmueble.Estado = "23"  && Quintana Roo según catálogo de Entidades Federativas
 .Inmueble.CodigoPostal = "77510"
 
 * otros datos no requeridos
 * ...
ENDWITH

oCFD.Addenda = oComplemento		&& Se usa la propiedad Addenda pero en el complemento se define el nombre del nodo

??"...Version " + CFDVersions.ToLongString(CFDVersions.fromString(oCFD.Version))

*-- Se carga la informacion del certificado 
*
LOCAL cArchivoKey, cArchivoCer
* Para pruebas con certificados del SAT
*cArchivoKey = "aaa010101aaa_CSD_01.key"
*cArchivoCer = "aaa010101aaa_CSD_01.cer"
*cPasswrdKey = "a0123456789"

* Certificado de pruebas del PAC - FacturadorElectronico.com
*cArchivoKey = "goya780416gm0_1011181055s.key"
*cArchivoCer = "goya780416gm0.cer"
*cPasswrdKey = "12345678a"

* Certificado de pruebas del PAC - Finkok
cArchivoKey = "Finkok\aad990814bp7_1210261233s.key"
cArchivoCer = "Finkok\aad990814bp7_1210261233s.cer"
cPasswrdKey = "12345678a"

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
*set step on 
oCFD.CrearXML("testcomplementoparcialesconstruccion.xml")



*-- Se vaaida el CFD
*
?"- Validando CFD"
IF NOT CFDValidarXML("testcomplementoparcialesconstruccion.xml",cArchivoKey, cPasswrdKey, "sha1", ".\SSL")
 ?"ERROR: " + CFDConf.ultimoError
 RETURN
ELSE 
  ??" OK"
ENDIF



RETURN



