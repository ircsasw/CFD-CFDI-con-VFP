DEFINE CLASS CFDElektraAddenda AS ICFDAddenda
 *
 * Propiedades base
 nodeName = "Addenda"
 NSTag = ""
 NSUrl = ""
 
 * Propiedades personalizadas
 Emisor = ""
 Receptor = ""
 TipoProveedorEKT = ""
 Fecha = ""
 MonedaDoc = ""
 SubTotal = ""
 IVAPCT = ""
 IVA = ""
 SubTotalIVA = ""
 Total = ""
 NumProveedor = ""
 Cantidad = ""
 Concepto = ""
 PUnitario = ""
 Importe = ""
 
 
 * Metodo base
 PROCEDURE ToString()
  *
  LOCAL oParser,oRoot
  oParser = CREATE("XMLParser")
  oParser.New()
  oRoot = oParser.XML.addNode("if:FacturaInterfactura")
  oRoot.addProp("TipoDocumento","Factura")
  oRoot.addProp("xmlns:if","http://www.interfactura.com/schemas/documentos")
  oRoot.addNode("Emisor")
  oRoot._Emisor.addProp("RI",THIS.Emisor)
  oRoot.addNode("Receptor")
  oRoot._Receptor.addProp("RI",THIS.Receptor)
  oRoot.addNode("Encabezado")
  WITH oRoot._Encabezado
   .addProp("TipoProveedorEKT",THIS.tipoProveedorEKT)
   .addProp("Fecha",THIS.FEcha)
   .addProp("MonedaDoc",THIS.MonedaDoc)
   .addProp("SubTotal",THIS.SubTotal)
   .addProp("IVAPCT",THIS.IVAPCT)
   .addProp("Iva",THIS.Iva)
   .addProp("SubTotalIva",THIS.SubTotalIVA)
   .addProp("Total",THIS.Total)
   .addProp("NumProveedor",THIS.NumProveedor)
   .addNode("Cuerpo")
   WITH ._Cuerpo
    .addProp("Cantidad",THIS.Cantidad)
    .addProp("Concepto",THIS.Concepto)
    .addProp("PUnitario",THIS.Punitario)
    .addProp("Importe",THIS.Importe)
   ENDWITH
  ENDWITH

  RETURN oRoot.ToString()  
  *
 ENDPROC
 
 *
ENDDEFINE

