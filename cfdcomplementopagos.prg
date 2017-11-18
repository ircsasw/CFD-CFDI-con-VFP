*** CFDComplementoPagos		ByVigar.	Foxlatino.
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

DEFINE CLASS CFDComplementoPagos AS ICFDAddenda
 *
 #DEFINE CFD_OPCIONAL       .T.
 
 nodeName = "Complemento"		&& Define el nombre del nodo (por defecto es Addenda)
 Version = "1.0"
 
 Pago10 = NULL
 
 PROCEDURE Init
  DODEFAULT()
  THIS.Pago10  = CREATEOBJECT("CFDComplementoPagosPago10")
 ENDPROC 
  
 PROCEDURE Version_Assign(vNewVal)
 ENDPROC 
 *
 
ENDDEFINE
 
* Pago10
* CFDComplementoPagosPago10
* Representa los datos del nodo "Pago10:Pago"
*
DEFINE CLASS CFDComplementoPagosPago10 as Custom
 FechaPago = ''
 FormaDePagoP = ''
 MonedaP = ''
 TipoCambioP = 0.00
 Monto = 0.00
 NumOperacion = ''
 RfcEmisorCtaOrd = ''
 NomBancoOrdExt = ''
 CtaOrdenante = ''
 RfcEmisorCtaBen = ''
 CtaBeneficiario = ''

 pagos = NULL
 
 PROCEDURE Init()
 	DODEFAULT()
 	THIS.pagos = CREATEOBJECT("CFDComplementoPagosxPago10")
 ENDPROC
 
ENDDEFINE

* CFDComplementoPagosPago10
* Representa los datos del nodo "Pago10:Pago"
DEFINE CLASS CFDComplementoPagosxPago10 AS Custom 
 FechaPago = ''
 FormaDePagoP = ''
 MonedaP = ''
 TipoCambioP = 0.00
 Monto = 0.00
 NumOperacion = ''
 RfcEmisorCtaOrd = ''
 NomBancoOrdExt = ''
 CtaOrdenante = ''
 RfcEmisorCtaBen = ''
 CtaBeneficiario = ''
 
 DoctoRelacionado = NULL
 
 PROCEDURE Init()
 	DODEFAULT()
 	THIS.DoctoRelacionado = CREATEOBJECT("CFDComplementoDoctoRelacionado")
 ENDPROC 
   
ENDDEFINE 



* DoctoRelacionado
* CFDComplementoDoctoRelacionados
* Representa los datos del nodo "Pago10:DoctoRelacionado"
*
DEFINE CLASS CFDComplementoDoctoRelacionado as Custom 
 IdDocumento      = ''
 Serie            = ''
 Folio            = ''
 MonedaDR         = ''
 TipoCambioDR     = ''
 MetodoDePagoDR   = ''
 NumParcialidad   = ''
 ImpPagado        = 0.00
 ImpSaldoAnt      = 0.00
 ImpSaldoInsoluto = 0.00
 
 PROCEDURE Init()
	DODEFAULT()
 ENDPROC
 
ENDDEFINE 

