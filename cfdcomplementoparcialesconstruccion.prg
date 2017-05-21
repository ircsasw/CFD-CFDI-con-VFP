* CFDComplementoParcialesConstruccion
* Implementa el complemento para incorporar información de servicios parciales de construcción de inmuebles destinados a casa habitación
*
DEFINE CLASS CFDComplementoParcialesConstruccion AS ICFDAddenda
 *
 #DEFINE CFD_OPCIONAL		.T. 
 
 nodeName = "Complemento"		&& Define el nombre del nodo (por defecto es Addenda)
 
 NSTag = "servicioparcial"
 NSUrl = "http://www.sat.gob.mx/servicioparcialconstruccion"
 schemaLocation = "http://www.sat.gob.mx/servicioparcialconstruccion http://www.sat.gob.mx/sitio_internet/cfd/servicioparcialconstruccion/servicioparcialconstruccion.xsd"
 
 Version = "1.0"		&& Atributo requerido con valor prefijado a 1.0 que indica la versión del complemento.
 NumPerLicoAut = ""		&& Atributo requerido para expresar el número de permiso, licencia o autorización de construcción proporcionado por el prestatario de los servicios parciales de construcción.

 Inmueble = null		&& Nodo requerido para expresar la información del inmueble en el que se proporcionan los servicios parciales de construcción.
 
 PROCEDURE Init
  DODEFAULT()
  THIS.Inmueble = CREATEOBJECT("CFDComplementoParcialesConstruccionInmueble")
 ENDPROC
 
 PROCEDURE ToString()
  *
  LOCAL oParser,oRoot
  oParser = CREATE("XMLParser")
  oParser.New()
  
  oRoot = oParser.XML.addNode("servicioparcial:parcialesconstruccion")
  
  oRoot.addProp("Version", THIS.version)
  oRoot.addProp("NumPerLicoAut", THIS._fixStr(THIS.NumPerLicoAut))
  
  * - Inmueble
  THIS.Inmueble.ToXml(oRoot)

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


* I N M U E B L E
* CFDComplementoParcialesConstruccionInmueble
* Representa los datos del nodo "parcialesconstruccion.Inmueble
* 
DEFINE CLASS CFDComplementoParcialesConstruccionInmueble AS Custom
 *-- Atributos requeridos
 Calle = ""
 Municipio = ""
 Estado = ""
 CodigoPostal = ""

 *-- Atributos opcionales 
 noExterior = ""
 noInterior = ""
 Colonia = ""
 Localidad = ""
 Referencia = ""
 
 PROCEDURE ToXML(poParentNode)
  LOCAL oNodo as Object
  oNodo = poParentNode.addNode("servicioparcial:Inmueble")
  
  oNodo.addProp("Calle", _fixStr(this.Calle))
  oNodo.addProp("Municipio", _fixStr(this.Municipio))
  oNodo.addProp("Estado", _fixStr(this.Estado))
  oNodo.addProp("CodigoPostal", _fixStr(this.codigoPostal))
  
  oNodo.addProp("noExterior", _fixStr(this.noExterior), CFD_OPCIONAL)
  oNodo.addProp("noInterior", _fixStr(this.noInterior), CFD_OPCIONAL)
  oNodo.addProp("Colonia", _fixStr(this.Colonia), CFD_OPCIONAL)
  oNodo.addProp("Localidad", _fixStr(this.Localidad), CFD_OPCIONAL)
  oNodo.addProp("Referencia", _fixStr(this.Referencia), CFD_OPCIONAL)
 ENDPROC 
ENDDEFINE 
  
  
 *-- _fixStr (Metodo)
 *   Recibe una cadena y realiza los siguientes cambios:
 *   a) Sustituye cualquier caracter invalido por el caracter "."
 *   b) Elimina los espacios en blanco al inicio y al final de la cadena
 *   c) Elimina cualquier secuencia de espacios en blanco repetidos dentro de la cadena
 *   d) Si la cadena resultante contiene al menos 1 caracter, se le anade la cadena
 *      indicada en el parametro pcSep
PROCEDURE _fixStr(puValue, pcSep)
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
