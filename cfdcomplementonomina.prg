* CFDComplementoNomina
* Implementa el complemento para nominas
*
DEFINE CLASS CFDComplementoNomina AS ICFDAddenda
 *
 #DEFINE CFD_OPCIONAL		.T. 
 
 NSTag = "nomina"
 NSUrl = "http://www.sat.gob.mx/nomina"
 schemaLocation = "http://www.sat.gob.mx/nomina http://www.sat.gob.mx/sitio_internet/cfd/nomina/nomina11.xsd"
 
 version = "1.1"		&& Atributo requerido con valor prefijado a 1.0 que indica la versión del estándar bajo el que se encuentra expresado el complemento concepto al comprobante.
 
 
 
 PROCEDURE ToString()
  *
  LOCAL oParser,oRoot
  oParser = CREATE("XMLParser")
  oParser.New()
  oRoot = oParser.XML.addNode("nomina:Nomina")


  RETURN oRoot.ToString()  
  
  *
 ENDPROC
 
 PROCEDURE Version_Assign(vNewVal)
 ENDPROC 
 *
ENDDEFINE

