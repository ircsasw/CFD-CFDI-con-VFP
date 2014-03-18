* CFDComplementoNomina
* Implementa el complemento para nominas
*
* --
** Autores: Victor Espina / Arturo Ramos
** 
** ARC  Mar 17, 2014	- Se Agrega soporte para nodos Percepciones, Deducciones, Incapacidades y Horasextras
** 
*

DEFINE CLASS CFDComplementoNomina AS ICFDAddenda
 *
 #DEFINE CFD_OPCIONAL		.T. 
 
 nodeName = "Complemento"		&& Define el nombre del nodo (por defecto es Addenda)
 
 NSTag = "nomina"
 NSUrl = "http://www.sat.gob.mx/nomina"
 schemaLocation = "http://www.sat.gob.mx/nomina http://www.sat.gob.mx/sitio_internet/cfd/nomina/nomina11.xsd"
 
 version = "1.1"		&& Atributo requerido con valor prefijado a 1.0 que indica la versión del estándar bajo el que se encuentra expresado el complemento concepto al comprobante.
 
 RegistroPatronal = ""
 NumEmpleado = ""
 CURP = ""
 TipoRegimen = 0
 NumSeguridadSocial = ""
 FechaPago = ""
 FechaInicialPago = ""
 FechaFinalPago = ""
 NumDiasPagados = ""
 Departamento = ""
 CLABE = ""
 Banco = 0
 FechaInicioRelLaboral = ""
 Antiguedad = 0
 Puesto = ""
 TipoContrato = ""
 TipoJornada = ""
 PeriodicidadPago = ""
 SalarioBaseCotApor = ""
 RiesgoPuesto = 0
 SalarioDiarioIntegrado = ""
 
 lIncluirPercepciones = .F.		&& El nodo de Percepciones es opcional, si es .T. se inlcuye
 Percepciones = NULL
 
 lIncluirDeducciones  = .F.		&& El nodo de Deducciones es opcional, si es .T. se inlcuye
 Deducciones  = NULL
 
 lIncluirIncapacidades = .F.	&& El nodo de Incapacidades es opcional, si es .T. se inlcuye
 Incapacidades = NULL
 
 lIncluirHorasExtras = .F.		&& El nodo de HorasExtras es opcional, si es .T. se inlcuye
 HorasExtras = NULL
 
 PROCEDURE Init
  DODEFAULT()
  THIS.Percepciones  = CREATEOBJECT("CFDComplementoNominaPercepciones")
  THIS.Deducciones   = CREATEOBJECT("CFDComplementoNominaDeducciones")
  THIS.Incapacidades = CREATEOBJECT("CFDComplementoNominaIncapacidades")
  THIS.HorasExtras   = CREATEOBJECT("CFDComplementoNominaHorasExtras")
 ENDPROC
 
 PROCEDURE ToString()
  *
  LOCAL oParser,oRoot
  oParser = CREATE("XMLParser")
  oParser.indentString = ""
  oParser.New()
  
  oRoot = oParser.XML.addNode("nomina:Nomina")
  oRoot.createNodeLinks = .F.
  
  oRoot.addProp("Version", THIS.Version)
  
  oRoot.addProp("RegistroPatronal", THIS._fixStr(THIS.RegistroPatronal), CFD_OPCIONAL)
  oRoot.addProp("NumEmpleado", THIS._fixStr(THIS.NumEmpleado))
  oRoot.addProp("CURP", THIS._fixStr(THIS.CURP))
  oRoot.addProp("TipoRegimen", IIF(THIS.TipoRegimen > 0, ALLTRIM(STR(THIS.TipoRegimen,15,0)), ""))
  oRoot.addProp("NumSeguridadSocial", THIS._fixStr(THIS.NumSeguridadSocial), CFD_OPCIONAL)
  oRoot.addProp("FechaPago", THIS._fixStr(THIS.FechaPago))
  oRoot.addProp("FechaInicialPago", THIS._fixStr(THIS.FechaInicialPago))
  oRoot.addProp("FechaFinalPago", THIS._fixStr(THIS.FechaFinalPago))
  oRoot.addProp("NumDiasPagados", THIS._fixStr(THIS.NumDiasPagados))
  oRoot.addProp("Departamento", THIS._fixStr(THIS.Departamento), CFD_OPCIONAL)
  oRoot.addProp("CLABE", THIS._fixStr(THIS.CLABE), CFD_OPCIONAL)
  oRoot.addProp("Banco", IIF(THIS.Banco > 0, PADL(THIS.Banco,3,"0"), ""),CFD_OPCIONAL)
  oRoot.addProp("FechaInicioRelLaboral", THIS._fixStr(THIS.FechaInicioRelLaboral), CFD_OPCIONAL)
  oRoot.addProp("Antiguedad", IIF(THIS.Antiguedad > 0, ALLTRIM(STR(THIS.Antiguedad,15,0)), ""), CFD_OPCIONAL)
  oRoot.addProp("Puesto", THIS._fixStr(THIS.Puesto), CFD_OPCIONAL)
  oRoot.addProp("TipoContrato", THIS._fixStr(THIS.TipoContrato), CFD_OPCIONAL)
  oRoot.addProp("TipoJornada", THIS._fixStr(THIS.TipoJornada), CFD_OPCIONAL)
  oRoot.addProp("PeriodicidadPago", THIS._fixStr(THIS.PeriodicidadPago))
  oRoot.addProp("SalarioBaseCotApor", THIS._fixStr(THIS.SalarioBaseCotApor), CFD_OPCIONAL)
  oRoot.addProp("RiesgoPuesto", IIF(THIS.RiesgoPuesto > 0, STR(THIS.RiesgoPuesto,1,0), ""), CFD_OPCIONAL)
  oRoot.addProp("SalarioDiarioIntegrado", THIS._fixStr(THIS.SalarioDiarioIntegrado), CFD_OPCIONAL)

  * - PERCEPCIONES
  IF THIS.lIncluirPercepciones THEN 
    THIS.Percepciones.ToXml(oRoot)
  ENDIF 
  
  * - DEDUCCIONES
  IF THIS.lIncluirDeducciones THEN 
    THIS.Deducciones.ToXml(oRoot)
  ENDIF 

  * - INCAPACIDADES
  IF THIS.lIncluirIncapacidades THEN 
    THIS.Incapacidades.ToXml(oRoot)
  ENDIF 
  
  * - HORASEXTRAS
  IF THIS.lIncluirHorasExtras THEN 
    THIS.HorasExtras.ToXml(oRoot)
  ENDIF 
  
  RETURN oRoot.ToString()  
  
  *
 ENDPROC
 
 
 *-- _fixStr (Metodo)
 *   Recibe una cadena y realiza los siguientes cambios:
 *   a) Sustituye cualquier caracter invalido por el caracter "."
 *   b) Elimina los espacios en blanco al inicio y al final de la cadena
 *   c) Elimina cualquier secuencia de espacios en blanco repetidos dentro de la cadena
 *   d) Si la cadena resultante contiene al menos 1 caracter, se le anade la cadena
 *      indicada en el parametro pcSep
 HIDDEN PROCEDURE _fixStr(puValue, pcSep)
  *
  IF PCOUNT() = 1
   pcSep = ""
  ENDIF
  
  LOCAL cType
  cType = VARTYPE(puValue)
  
  DO CASE
     CASE cType = "N" 
          IF EMPTY(puValue)
           RETURN ""
          ENDIF
          RETURN ALLT(STR(puValue,15,2)) + pcSep
          
     CASE cType = "D"
          IF EMPTY(puValue)
           RETURN ""
          ENDIF
          RETURN STR(YEAR(puValue),4) + "-" + PADL(MONTH(puValue),2,"0") + "-" + PADL(DAY(puValue),2,"0") + pcSEP
          
     CASE cType = "T"
          IF EMPTY(puValue)
           RETURN ""
          ENDIF
          RETURN STR(YEAR(puValue),4) + "-" + PADL(MONTH(puValue),2,"0") + "-" + PADL(DAY(puValue),2,"0") + "T" + ;
                 PADL(HOUR(puValue),2,"0") + ":" + PADL(MINUTE(puValue),2,"0") + ":" + PADL(SEC(puValue),2,"0") + pcSEP     
     
     CASE cType = "X"  && Valor NULL
          RETURN ""
  ENDCASE
  
  
  LOCAL cFixed
  cFixed = ALLTRIM(puValue)
  cFixed = STRT(STRT(STRT(STRT(STRT(cFixed,[&],[&amp;]),[<],[&lt;]),[>],[&gt;]),["],[&quot;]),['],[&apos;])
  cFixed = STRT(cFixed, CHR(13)+CHR(10), "")
 
  DO WHILE AT(SPACE(2), cFixed) <> 0
   cFixed = STRTRAN(cFixed,SPACE(2),SPACE(1))
  ENDDO
 
  IF LEN(cFixed) > 0 AND !EMPTY(pcSep)
   cFixed = cFixed + pcSep
  ENDIF
  
  RETURN cFixed
  *
 ENDPROC

 
 PROCEDURE Version_Assign(vNewVal)
 ENDPROC 
 *
ENDDEFINE

* P E R C E P C I O N E S
* CFDComplementoNominaPercepciones
* Representa los datos del nodo "nomina:Percepciones"
*
DEFINE CLASS CFDComplementoNominaPercepciones AS CFDCollection
 TotalGravado = 0.00
 TotalExento = 0.00
 
 PROCEDURE Add(pcTipoPercepcion, pcClave, pcConcepto, pnImporteGravado, pnImporteExento)
  LOCAL oPercepcion
  oPercepcion = CREATEOBJECT("CFDComplementoNominaPercepcion", pcTipoPercepcion, pcClave, pcConcepto, pnImporteGravado, pnImporteExento)
  THIS.TotalGravado = THIS.TotalGravado + pnImporteGravado
  THIS.TotalExento  = THIS.TotalExento + pnImporteExento
  RETURN DODEFAULT(oPercepcion)
 ENDPROC
 
 PROCEDURE ToXML(poParentNode)
  LOCAL oNodo,i,oPercepcion
  oNodo = poParentNode.addNode("nomina:Percepciones")
  oNodo.addProp("TotalGravado",ALLTRIM(STR(THIS.TotalGravado)))
  oNodo.addProp("TotalExento",ALLTRIM(STR(THIS.TotalExento)))
  oNodo.createNodeLinks = .F.
  FOR i = 1 TO THIS.Count
   oPercepcion = THIS.Items[i]
   oPercepcion.ToXml(oNodo)
  ENDFOR
 ENDPROC
ENDDEFINE


* CFDComplementoNominaPercepcion
* Representa los datos del nodo "nomina:Percepcion"
DEFINE CLASS CFDComplementoNominaPercepcion AS Custom
 TipoPercepcion = ""
 Clave = ""
 Concepto = ""
 ImporteGravado = 0.00
 ImporteExento = 0.00
 
 PROCEDURE Init(pcTipoPercepcion, pcClave, pcConcepto, pnImporteGravado, pnImporteExento)
  THIS.TipoPercepcion = pcTipoPercepcion
  THIS.Clave = pcClave
  THIS.Concepto = pcConcepto
  THIS.ImporteGravado = pnImporteGravado
  THIS.ImporteExento = pnImporteExento
 ENDPROC
 
 PROCEDURE ToXml(poParentNode)
  LOCAL oNodo
  oNodo = poParentNode.addNode("nomina:Percepcion")
  oNodo.addProp("TipoPercepcion",THIS.TipoPercepcion)
  oNodo.addProp("Clave", THIS.Clave)
  oNodo.addProp("Concepto", THIS.Concepto)
  oNodo.addProp("ImporteGravado",ALLTRIM(STR(THIS.ImporteGravado)))
  oNodo.addProp("ImporteExento",ALLTRIM(STR(THIS.ImporteExento)))
 ENDPROC
ENDDEFINE


* D E D U C C I O N E S
* CFDComplementoNominaDeducciones
* Representa los datos del nodo "nomina:Deducciones"
*
DEFINE CLASS CFDComplementoNominaDeducciones AS CFDCollection
 TotalGravado = 0.00
 TotalExento = 0.00
 
 PROCEDURE Add(pcTipoDeduccion, pcClave, pcConcepto, pnImporteGravado, pnImporteExento)
  LOCAL oDeduccion
  oDeduccion = CREATEOBJECT("CFDComplementoNominaDeduccion", pcTipoDeduccion, pcClave, pcConcepto, pnImporteGravado, pnImporteExento)
  THIS.TotalGravado = THIS.TotalGravado + pnImporteGravado
  THIS.TotalExento  = THIS.TotalExento + pnImporteExento
  RETURN DODEFAULT(oDeduccion)
 ENDPROC
 
 PROCEDURE ToXML(poParentNode)
  LOCAL oNodo,i,oDeduccion
  oNodo = poParentNode.addNode("nomina:Deducciones")
  oNodo.addProp("TotalGravado",ALLTRIM(STR(THIS.TotalGravado)))
  oNodo.addProp("TotalExento",ALLTRIM(STR(THIS.TotalExento)))
  oNodo.createNodeLinks = .F.
  FOR i = 1 TO THIS.Count
   oDeduccion = THIS.Items[i]
   oDeduccion.ToXml(oNodo)
  ENDFOR
 ENDPROC
ENDDEFINE


* CFDComplementoNominaDeduccion
* Representa los datos del nodo "nomina:Deduccion"
DEFINE CLASS CFDComplementoNominaDeduccion AS Custom
 TipoDeduccion = ""
 Clave = ""
 Concepto = ""
 ImporteGravado = 0.00
 ImporteExento = 0.00
 
 PROCEDURE Init(pcTipoDeduccion, pcClave, pcConcepto, pnImporteGravado, pnImporteExento)
  THIS.TipoDeduccion = pcTipoDeduccion
  THIS.Clave = pcClave
  THIS.Concepto = pcConcepto
  THIS.ImporteGravado = pnImporteGravado
  THIS.ImporteExento = pnImporteExento
 ENDPROC
 
 PROCEDURE ToXml(poParentNode)
  LOCAL oNodo
  oNodo = poParentNode.addNode("nomina:Deduccion")
  oNodo.addProp("TipoDeduccion",THIS.tipoDeduccion)
  oNodo.addProp("Clave", THIS.Clave)
  oNodo.addProp("Concepto", THIS.Concepto)
  oNodo.addProp("ImporteGravado",ALLTRIM(STR(THIS.ImporteGravado)))
  oNodo.addProp("ImporteExento",ALLTRIM(STR(THIS.ImporteExento)))
 ENDPROC
ENDDEFINE


* I N C A P A C I D A D E S
* CFDComplementoNominaIncapacidades
* Representa los datos del nodo "nomina:Incapacidades"
*
DEFINE CLASS CFDComplementoNominaIncapacidades AS CFDCollection
 
 PROCEDURE Add(pnDiasIncapacidad, pnTipoIncapacidad, pnDescuento)
  LOCAL oIncapacidad
  oIncapacidad = CREATEOBJECT("CFDComplementoNominaIncapacidad", pnDiasIncapacidad, pnTipoIncapacidad, pnDescuento)
  RETURN DODEFAULT(oIncapacidad)
 ENDPROC
 
 PROCEDURE ToXML(poParentNode)
  LOCAL oNodo,i,oIncapacidad
  oNodo = poParentNode.addNode("nomina:Incapacidades")
  oNodo.createNodeLinks = .F.
  FOR i = 1 TO THIS.Count
   oIncapacidad = THIS.Items[i]
   oIncapacidad.ToXml(oNodo)
  ENDFOR
 ENDPROC
ENDDEFINE


* CFDComplementoNominaIncapacidad
* Representa los datos del nodo "nomina:Incapacidad"
DEFINE CLASS CFDComplementoNominaIncapacidad AS Custom
 DiasIncapacidad = 0.00
 TipoIncapacidad = 0
 Descuento = 0.00
 
 PROCEDURE Init(pnDiasIncapacidad, pnTipoIncapacidad, pnDescuento)
  THIS.DiasIncapacidad = pnDiasIncapacidad
  THIS.TipoIncapacidad = pnTipoIncapacidad
  THIS.Descuento = pnDescuento
 ENDPROC
 
 PROCEDURE ToXml(poParentNode)
  LOCAL oNodo
  oNodo = poParentNode.addNode("nomina:Incapacidad")
  oNodo.addProp("DiasIncapacidad", ALLTRIM(STR(THIS.DiasIncapacidad)))
  oNodo.addProp("TipoIncapacidad", ALLTRIM(STR(THIS.TipoIncapacidad)))
  oNodo.addProp("Descuento", ALLTRIM(STR(THIS.Descuento)))
 ENDPROC
ENDDEFINE


* H O R A S E X T R A S
* CFDComplementoNominaHorasExtras
* Representa los datos del nodo "nomina:HorasExtras"
*
DEFINE CLASS CFDComplementoNominaHorasExtras AS CFDCollection
 
 PROCEDURE Add(pnImportePagado, pnHorasExtra, pcTipoHoras, pnDias)
  LOCAL oHorasExtra
  oHorasExtra = CREATEOBJECT("CFDComplementoNominaHorasExtra", pnImportePagado, pnHorasExtra, pcTipoHoras, pnDias)
  RETURN DODEFAULT(oHorasExtra)
 ENDPROC
 
 PROCEDURE ToXML(poParentNode)
  LOCAL oNodo,i,oHorasExtra
  oNodo = poParentNode.addNode("nomina:HorasExtras")
  oNodo.createNodeLinks = .F.
  FOR i = 1 TO THIS.Count
   oHorasExtra = THIS.Items[i]
   oHorasExtra.ToXml(oNodo)
  ENDFOR
 ENDPROC
ENDDEFINE


* CFDComplementoNominaHorasExtra
* Representa los datos del nodo "nomina:HorasExtra"
DEFINE CLASS CFDComplementoNominaHorasExtra AS Custom
 Dias = 0
 TipoHoras = ""
 HorasExtra = 0
 ImportePagado = 0.0

 PROCEDURE Init(pnDias, pcTipoHoras, pnHorasExtra, pnImportePagado)
  THIS.Dias = pnDias
  THIS.TipoHoras = pcTipoHoras
  THIS.HorasExtra = pnHorasExtra
  THIS.ImportePagado = pnImportePagado
 ENDPROC
 
 PROCEDURE ToXml(poParentNode)
  LOCAL oNodo
  oNodo = poParentNode.addNode("nomina:HorasExtra")
  oNodo.addProp("Dias", ALLTRIM(STR(THIS.Dias)))
  oNodo.addProp("TipoHoras", THIS.TipoHoras)
  oNodo.addProp("HorasExtra", ALLTRIM(STR(THIS.HorasExtra)))
  oNodo.addProp("ImportePagado", ALLTRIM(STR(THIS.ImportePagado)))
 ENDPROC
ENDDEFINE