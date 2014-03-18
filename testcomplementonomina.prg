* --
* -- Este ejemplo genera un CFD version 3.2 utilizando la clase CFD y
* -- mostrando el uso del nodo Complemento de un Comprobante.
* --
** Autores: Victor Espina / Arturo Ramos
** 
** ARC  Mar 17, 2014	- Se Agrega soporte para nodos Percepciones, Deducciones, Incapacidades y Horasextras
** 
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
 
 * - IVA NO APLICA PARA NOMINAS pero retención de ISR si
 *.Impuestos.Traslados.Add("",0,0)
 .Impuestos.Retenciones.Add("ISR", 0)
 
 * - Detalles del pago de nomina
 o = .Conceptos.Add(1.000, "SUELDO DE LA JORNADA", 1500.00, 1500.00)    && Cantidad SIEMPRE 1
 o.noIdentificacion = "SUELDO"
 o.Unidad = "SERVICIO"						&& Se utilizará la expresión "Servicio"
  

ENDWITH

*-- El complemento se implementa asignando una instancia de una clase derivada
*   de ICFDAddenda. En este caso, la clase es CFDComplementoNomina (ver el archivo
*   CFDCOMPLEMENTONOMINA.PRG)
LOCAL oComplemento
oComplemento = CREATEOBJECT("CFDComplementoNomina")
WITH oComplemento
 * 
 .RegistroPatronal = "03030303030"
 .NumEmpleado = "000001"
 .CURP = "PESH880507HVZXRB00"
 .TipoRegimen = 1
 .NumSeguridadSocial = "SRIRIIR00030303"
 .FechaPago = DATE()
 .FechaInicialPago = DATE()
 .FechaFinalPago = DATE()
 .NumDiasPagados = 1
 .Departamento = "Sistemas"
 .CLABE = "000000000000000000"
 .Banco = 10
 .FechaInicioRelLaboral = DATE()
 .Antiguedad = 1
 .Puesto = "Puesto"
 .TipoContrato = "tipocontrato"
 .TipoJornada = "tipojornada"
 .PeriodicidadPago = "SEMANAL"
 .SalarioBaseCotApor = 1
 .RiesgoPuesto = 1
 .SalarioDiarioIntegrado = 1
 
 * - Procesa PERCEPCIONES
 .lIncluirPercepciones = .T.
 .Percepciones.Add("010","00001","CONCEPTO DE INGRESO 1",1.00,1.00)  && pcTipoPercepcion, pcClave, pcConcepto, pnImporteGravado, pnImporteExento
 .Percepciones.Add("010","00001","CONCEPTO DE INGRESO 2",1.00,1.00)  
 
 * - Procesa las DEDUCCIONES
 .lIncluirDeducciones = .T.
 .Deducciones.Add("010","IMSS","PAGO DEL IMSS",1.00,1.00)  && pcTipoDeduccion, pcClave, pcConcepto, pnImporteGravado, pnImporteExento
 .Deducciones.Add("010","INFONAVIT","PAGO DEL INFONAVIT",1.00,1.00)  
 
 * - Procesa las INCAPACIDADES
 .lIncluirIncapacidades = .T.
 .Incapacidades.Add(2, 3, 2)  && pnDiasIncapacidad, pnTipoIncapacidad, pnDescuento
 .Incapacidades.Add(1, 1, 1)
 
 * - Procesa HORASEXTRAS
 .lIncluirHorasExtras = .T.
 .HorasExtras.Add(2, "Dobles", 33, 1)  && pnDias, pcTipoHoras, pnHorasExtra, pnImportePagado
 
ENDWITH

oCFD.Addenda = oComplemento		&& Se usa la propiedad Addenda pero en el complemento se define el nombre del nodo

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
oCFD.CrearXML("testcomplementonomina.xml")



*-- Se vaaida el CFD
*
?"- Validando CFD"
*IF NOT CFDValidarXML("testcomplementoconcepto.xml",cArchivoKey, cPasswrdKey, "sha1", ".\SSL")
* ?"ERROR: " + CFDConf.ultimoError
* RETURN
*ELSE 
*  ??" OK"
*ENDIF



RETURN



