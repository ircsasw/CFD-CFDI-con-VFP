* CFDComplementoIEDU
* Implementa el complemento para instituciones educativas
*
DEFINE CLASS CFDComplementoIEDU AS ICFDAddenda
 *
 #DEFINE CFD_OPCIONAL		.T. 
 
 NSTag = "iedu"
 NSUrl = "http://www.sat.gob.mx/iedu"
 schemaLocation = "http://www.sat.gob.mx/iedu http://www.sat.gob.mx/sitio_internet/cfd/iedu/iedu.xsd"
 
 version = "1.0"		&& Atributo requerido con valor prefijado a 1.0 que indica la versión del estándar bajo el que se encuentra expresado el complemento concepto al comprobante.
 nombreAlumno = ""		&& Atributo requerido para indicar el nombre del Alumno.
 CURP = ""				&& Atributo requerido para indicar la CURP del alumno de la institución educativa. 18 caracteres.
 nivelEducativo = ""	&& Atributo requerido para indicar el nivel educativo que cursa el alumno. Permite: Preescolar, Primaria, Secundaria, Prefesional técnico, Bachillerato o su equivalente.
 autRVOE = ""			&& Atributo requerido para especificar la autorización o reconocimiento de validez oficial de estudios en los términos de la Ley General de Educación que tenga la institución educativa privada donde se realiza el pago.
 rfcPago = ""			&& Atributo opcional para indicar el RFC de quien realiza el pago cuando sea diferente a quien recibe el servicio. De 12-13 caracteres.
 
 PROCEDURE ToString()
  *
  LOCAL oParser,oRoot
  oParser = CREATE("XMLParser")
  oParser.New()
  oRoot = oParser.XML.addNode("iedu:instEducativas")
  oRoot.addProp("version", THIS.version)
  oRoot.addProp("nombreAlumno", THIS.nombreAlumno)
  oRoot.addProp("CURP", THIS.CURP)
  oRoot.addProp("nivelEducativo",THIS.nivelEducativo)
  oRoot.addProp("autRVOE",THIS.autRVOE)
  oRoot.addProp("rfcPago",THIS.rfcPago, CFD_OPCIONAL) && ARC 04/03/14 - rfcPago es opcional

  RETURN oRoot.ToString()  
  
  *
 ENDPROC
 
 PROCEDURE Version_Assign(vNewVal)
 ENDPROC 
 *
ENDDEFINE

