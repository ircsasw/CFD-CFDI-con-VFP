*** CFDComplementoImpuestos	ByVigar.	Foxlatino.
*** Marco Vinicio García Vargas		Actualización.
* Implementa el complemento para Impuestoss
** Modified by: Julián May.
** JWM Feb	    2017    - Se modifica el prefijo Impuestos: por Impuestos12. 
* --
** Modified by: Julián May.
** JWM  Ene     2017    - Se agrega el soporte de varios nodos para SubContratacion. 
* --
** Modified by: Julián May
** JMD  Dic     2016      
* --
** Autores: Victor Espina / Arturo Ramos
** 
** ARC  Mar 17, 2014	- Se Agrega soporte para nodos Percepciones, Retenciones, Incapacidades y Horasextras
******* 

DEFINE CLASS CFDComplementoImpuestos AS Custom
 *
 #DEFINE CFD_OPCIONAL       .T.
 
 Base = 0.00
 Impuesto = ''
 TipoFactor = ''
 TasaOCuota = 0.00
 Importe = 0.00

 Traslados = NULL
 
 Retenciones  = NULL
 
 PROCEDURE Init
  DODEFAULT()
  THIS.Traslados  = CREATEOBJECT("CFDComplementoImpuestosTraslados")
  THIS.Retenciones   = CREATEOBJECT("CFDComplementoImpuestosRetenciones")
 ENDPROC 
ENDDEFINE
 
* Traslados 
* CFDComplementoImpuestosTraslados
* Representa los datos del nodo "Impuestos:Traslados"
*
DEFINE CLASS CFDComplementoImpuestosTraslados as Custom
 Base = 0.00
 Impuesto = ''
 TipoFactor = ''
 TasaOCuota = 0.00
 Importe = 0.00

 procedure init()
 endproc 
 
 PROCEDURE Add(pnBase, pcImpuesto, pcTipoFactor, pnTasaOCuota, pnImporte)
 	LOCAL oTraslado 
 	oTraslado = createobject("CFDComplementoImpuestosTraslado", pnBase, pcImpuesto, pcTipoFactor, pnTasaOCuota, pnImporte)
 	RETURN DODEFAULT(oTraslado)
 ENDPROC
    
 PROCEDURE ToXml(poParentNode)
  LOCAL oNodo,i,oTraslado
  oNodo = poParentNode.addNode("Impuestos:Traslados")
  oNodo.createNodeLinks = .F.
  FOR i = 1 to THIS.Count 
   oTraslado = THIS.Items[i]
   oTraslado.ToXml(oNodo)
  ENDFOR 
  
 ENDPROC  
enddefine 

* CFDComplementoImpuestosTraslado
* Representa los datos del nodo "Impuestos:Traslado"
DEFINE CLASS CFDComplementoImpuestosTraslado AS Custom 
 Base = 0.00
 Impuesto = ''
 TipoFactor = ''
 TasaOCuota = 0.00
 Importe = 0.00
 
 PROCEDURE Init(pnBase, pcImpuesto, pcTipoFactor, pnTasaOCuota, pnImporte)
  THIS.Base       = pnBase 
  THIS.Impuesto   = pcImpuesto 
  THIS.TipoFactor = pcTipoFactor
  THIS.TasaOCuota = pnTasaOCuota
  THIS.Importe    = pnImporte
 ENDPROC 

 PROCEDURE ToXML(poParentNode)
  LOCAL oNodo
  oNodo = poParentNode.addNode("Impuestos:Traslado")
  oNodo.addProp("Base", ALLTRIM(STR(THIS.Base,15,2)))
  oNodo.addProp("Impuesto", THIS.Impuesto)
  oNodo.addProp("TipoFactor", THIS.TipoFactor)
  oNodo.addProp("TasaOCuota", ALLTRIM(STR(THIS.TasaOCuota,10,6))) 
  oNodo.addProp("Importe", ALLTRIM(STR(THIS.Importe,15,2)))	
 
 ENDPROC
   
ENDDEFINE 



* Retenciones
* CFDComplementoImpuestosRetenciones
* Representa los datos del nodo "Impuestos:Retenciones"
*
DEFINE CLASS CFDComplementoImpuestosRetenciones as Custom 
 Base = 0.00
 Impuesto = ''
 TipoFactor = ''
 TasaOCuota = 0.00
 Importe = 0.00
 
 PROCEDURE Add(pnBase, pcImpuesto, pcTipoFactor, pnTasaOCuota, pnImporte)
 	LOCAL oRetencion 
 	oRetencion = createobject("CFDComplementoImpuestosRetencion", pnBase, pcImpuesto, pcTipoFactor, pnTasaOCuota, pnImporte)
 	RETURN DODEFAULT(oRetencion)
 ENDPROC

 PROCEDURE ToXML(poParentNode)
  LOCAL oNodo,i,oRetencion
  oNodo = poParentNode.addNode("Impuestos:Retenciones")
  oNodo.createNodeLinks = .F.
  FOR i = 1 TO THIS.Count
   oRetencion = THIS.Items[i]
   oRetencion.ToXml(oNodo)
  ENDFOR
 ENDPROC

ENDDEFINE 

* CFDComplementoImpuestosRetencion
* Representa los datos del nodo "Impuestos:Retencion"
DEFINE CLASS CFDComplementoImpuestosRetencion as Custom
 Base = 0.00
 Impuesto = ''
 TipoFactor = ''
 TasaOCuota = 0.00
 Importe = 0.00

 PROCEDURE Init(pnBase, pcImpuesto, pcTipoFactor, pnTasaOCuota, pnImporte)
  THIS.Base       = pnBase 
  THIS.Impuesto   = pcImpuesto 
  THIS.TipoFactor = pcTipoFactor
  THIS.TasaOCuota = pnTasaOCuota
  THIS.Importe    = pnImporte
 ENDPROC
 
 PROCEDURE ToXml(poParentNode)
  LOCAL oNodo
  oNodo = poParentNode.addNode("Impuestos:Retencion")
  oNodo.addProp("Base", ALLTRIM(STR(THIS.Base,15,2)))
  oNodo.addProp("Impuesto", THIS.Impuesto)
  oNodo.addProp("TipoFactor", THIS.TipoFactor)
  oNodo.addProp("TasaOCuota", ALLTRIM(STR(THIS.TasaOCuota,10,6))) 
  oNodo.addProp("Importe", ALLTRIM(STR(THIS.Importe,15,2)))	
ENDPROC  
ENDDEFINE 


