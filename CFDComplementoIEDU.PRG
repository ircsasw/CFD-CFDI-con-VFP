* CFDComplementoIEDU
* Implementa el complemento para instituciones educativas
*
DEFINE CLASS CFDComplementoIEDU AS ICFDAddenda
 *
 NSTag = "iedu"
 NSUrl = "http://www.sat.gob.mx/iedu"
 
 nombreAlumno = ""
 CURP = ""
 nivelEducativo = ""
 autRVOE = ""
 rfcPago = ""
 
 PROCEDURE ToString()
  *
  LOCAL oParser,oRoot
  oParser = CREATE("XMLParser")
  oParser.New()
  oRoot = oParser.XML.addNode("iedu:instEducativas")
  oRoot.addProp("xsi:schemaLocation","http://www.sat.gob.mx/iedu http://www.sat.gob.mx/sitio_internet/cfd/iedu/iedu.xsd")
  oRoot.addProp("nombreAlumno", THIS.nombreAlumno)
  oRoot.addProp("CURP", THIS.CURP)
  oRoot.addProp("nivelEducativo",THIS.nivelEducativo)
  oRoot.addProp("autRVOE",THIS.autRVOE)
  oRoot.addProp("rfcPago",THIS.rfcPago)

  RETURN oRoot.ToString()  
  
  *
 ENDPROC
 *
ENDDEFINE

