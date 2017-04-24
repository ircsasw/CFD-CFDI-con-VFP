## Change Log: CFD

## Versión 4

**Fecha:** ARC Abr 24, 2017
- Inicio de cambios para versión CFD 3.3


## Versión 3.8

**Fecha:** ARC	Feb 14, 2014	
- Correccion al crear comprobante no incluia el nodo CuentaPredial
- Cambios en CFDtoCursor para guardar el dato de la cuenta predial en cConcepto.nopredio
- Cambios en CFDToCursor para leer y guardar los datos del complemento iedu:instEducativas en los campos ieduNomAl, ieduCURP, ieduNivEd, ieduRVOE, ieduRFCPa del cursor de conceptos

**Fecha:** VES	Ago 23, 2012
- Correccion al crear el XML cuando no se indica valor en la propiedad opcional "Aduana"

**Fecha:** VES  Ago 3, 2012
- Correccion al crear el XML con mas de un complemento de concepto

## Version 3.7

**Fecha:** VES  Jul 30, 2012
- Nueva funcion CFDCreateQR() basada en el DLL barcodelibrary.dll

**Fecha:** VES  Jul 27, 2012
- Nuevas columnas IANUMERO, IAFECHA e IAADUANA en cursor QCO
- Cambios en funcion CFDTOCURSOR para llenar columnas IANUMERO, IAFECHA, IAADUANA e INFOADUANA
- Se elimino el mensaje de debug "Cached!"

**Fecha:** VES  Jul 25, 2012
- Inclusion de la libreria Print2PDF de Paul James (paulj@lifecyc.com)
- Nueva propiedad "usarPrint2PDF" en clase CFDConf
- Cambios en CFDPrint para usar la libreria Print2PDF para generar PDFs

**Fecha:** VES  Jul 21, 2012
- Cambio en CFDPrint() para que retorne .T. o .F. al mandar a generar un PDF

**Fecha:** ARC  Jun 13, 2012
- Se modifica CFDToCursor para que reciba CFD 2.2 y CFDI 3.2
- Se modifica CFDPrint para contener los datos del régimen fiscal dentro del cursor general QDG en el campo REGSFIS para la representación impresa

**Fecha:** VES  Abr 27, 2012
- Nuevos parametros opcionales pcMoneda, pcPrefijo y pcSufijo en funcion CFDNTOCESP() (Colaboracion de DanielCB)
- Nuevas propiedades NTOCMoneda, NTOCPrefijo y NTOCSufijo en objeto CFDConf

**Fecha:** VES  Feb 2, 2012
- Correccion de error en metodo Validate de CFDVersionsEnum
- Actualizacion de la propiedad Version de CFDConf

**Fecha:** ARC  Ene 14, 2012
- Se repara error en CFDVersionsEnum que no permitia generar CFDI 3.0

## Versión 3.6

**Fecha:** VES  Ene 12, 2012
- Modificacion a la funcion CFDExtraerCadenaOriginal a fin de usar la version indicada en el comprobante y NO la indicada en CFDConf.XMLVersion a fin de determinar el XSLT a utilizar para generar la cadena original.
- Nueva propiedad RegimenFiscal en CFDPersona
- Nuevas clases CFDRegimenFiscalCollection y CFDRegimenFiscal
- Nueva propiedad Complemento en clase CFDConcepto
- Cambios en metodo CrearXML() para implementar las nuevas propiedades RegimenFiscal y Complemento (Concepto)

**Fecha:** ARC  Ene 03, 2012
- nombre de emisor es opcional en 2.2 y 3.2
- nombre de receptor es opcional en todas las versiones
- domicilio de receptor es opcional en 3.0, 2.2 y 3.2

**Fecha:** VES	Dic 30, 2011
- Nueva enumeracion CFDVersions (CFDVersionsEnum)
- Se cambio el objeto CFDConf de buffer a instancia de clase para poder implementar un validador para la propiedad XMLVersion.
- La propiedad Version de CFDConf ahora es solo-lectura.
- Evento Assign en propiedad Version de CFDComprobante y XMLVersion de CFDConf para verificar que el valor indicado sea correcto.
- Modificacion en constructor de CFDComprobante para asignar por omision el valor de CFDConf.XMLVersion a la propiedad Version.

**Fecha:** ARC  Dic 27, 2011
- Beta de la generacion de comprobantes en version 2.2 y 3.2
- Se modifica CFDExtraerCadenaOriginal para adaptarla a las versiones 2.2 y 3.2
- Se modifica CFDValidarXML para adaptarla a las versiones 2.2 y 3.2

## Version 3.5

**Fecha:** ARC  Dic 20, 2011
- Inician los cambios para adaptar a las reformas 'no oficiales' para los formatosde comprobantes 2.2 y 3.2
- Se cambia la condicion para validar si se crea el nodo DomiciolioFiscal del Emisor, se verificaba que exista el atributo calle, este atributo es opcional, puede no estar y si requerir el nodo, el unico atributo requerido en el nodo es Pais.
- Se crea la clase CFDRegimenFiscal para el nodo RegimenFiscal del Emisor requerido en las versiones 2.2 y 3.2

**Fecha:** VES  Nov 21, 2011
- Nuevo metodo getProp() en clase XMLNodeClass

**Fecha:** VES  Nov 16, 2011
- Cambios en el metodo CrearXML y la funcion CFDToCursor para eliminar espacios en blanco dentro del valor RFC

**Fecha:** VES  Nov 14, 2011
- Cambios en metodo CrearXML para incluir el manejo de addendas
- Nuevas propiedades nodeName y schemaLocation de la clase ICFDAddenda

## Version 3.4

**Fecha:** VES  Nov 12, 2011
- Nuevo uso de la propiedad CFDAddenda de CFDComprobante
- Eliminacion de la propiedad CFDAddendas y la clase homonima, introducidos en Oct 10, 2011
- Mejoras en el metodo CrearXML() para incluir la generacion del nodo Addenda y/o Comprobante
- Nueva funcion CFDBuffer()

## Versión 3.3
**Fecha:** VES  Nov 11, 2011
- Nuevas propiedades nameSpace, nodeName y createNodeLInks en clase XMLNOdeClass
- Nueva propiedad createNodeLinks en clase XMLParser, para permitir multiples nodos hermanos con el mismo nombre
- Nuevo metodo ToString() en clase XMLParser
- Mejoras en metodos Open(), Save() e iSaveNode() en clase XMLParser para manejar NameSpaces
- Mejoras en metodo AddNode() de XMLNodeClass para manejar NameSpaces
- Mejoras en el metodo CrearXML() de la clase CFD para implementar las mejoras en las clases XMLParser y XMLNodeClass

**Fecha:** VES  Oct 10, 2011
- Nueva clase ICFDAddenda
- Nueva clase CFDAddendas 
- Nueva propiedad Addendas en CFDComprobante
- Cambio en CFDPrint() para sustituir uso de clausula READWRITE para matener la compatibilidad con versiones anteriores de VFP 

**Fecha:** BMJ  Oct 7, 2011
- Nueva función CFDGoogleQR() que genera un archivo PNG con el QR del CFDI
Parámetros: tcDato, que es la cadena que contendrá codificada el CBB.
Ésta función se ayuda de otra: CFDGetEscaped() la cual convierte los caracteres recibidos como parámetro recibido que no son soportados en una URL por su secuencia de escape.

**Fecha:** ARC  Oct 7, 2011
- Nueva función CFDEnviarPorCorreoAdjuntos para envier por correo
Parámetros: pcDestinatario, pcAsunto, pcCuerpo, pcCFD, pcPDF
Envia CFD y PDF por correo. A diferencia de CFDEnviarPorCorreo esta permite adjuntar el PDF ya creado lo cuál es útil cuando se utilizan diferente formatos para la representación impresa o para enviar comprobantes que no generó nuestro sistema como puede ser el caso de algunos PACs que junto con el timbre regresan el PDF

**Fecha:** ARC  Oct 6, 2011
- Nueva función CFDCadenaCBB(pcArchivoXML) para obtener la cadena necesaria para generar el CBB para la representación impresa de un CFDI desde un XML timbrado

**Fecha:** ARC  Ago 7, 2011
- Adaptaciones en CFDValidarXML para poder validar CFDI

**Fecha:** ARC  Ago 6, 2011
- Nueva propiedad XMLVersion de la clase CFDConf
- Nueva propiedad incluirBOM de la clase CFDConf
- Nuevo atributo Moneda de la clase CFDComprobante para CFDI
- Nuevo atributo TipoCambio de la clase CFDComprobante para CFDI

**Fecha:** ARC  Jul 13, 2011
- Se modifica en CrearXML() que se incluya el BOM en el XML

**Fecha:** VES  Ene 10, 2011
- Cambios en formato CFD

**Fecha:** VES  Ene 6, 2011
- Correcciones varias en funcion CrearFactura().
- Se incluyeron los atributos opcionales totalImpuestosRetenidos y totalImpuestosTrasladados al generar el XML.

**Fecha:** VES	Ene 5, 2011
- Nueva funcion CFDProbarOpenSSL()
- Nueva propiedad formatoImpresion de CFDConf
- Modificaciones varias en la funcion CFDPrint()
- Mejoras en el metodo Sellar() de CFDComprobante

**Fecha:** VES	Ene 4, 2011
- Se reprogramo el metodo _GenCadenaOriginal de CFDComprobante para utilizar la funcion CFDExtraerCadenaOriginal()
- Nuevo objeto CFDCertificado
- Nueva propiedad "ultimoCertificado" de la clase CFDConf
- Nueva funcion de cache en el metodo LeerCertificado() de la clase CFDComprobante.
- Se incluyo una nueva seccion de retenciones en el formato CFD.FRX
- Modificaciones para permitir la extraccion de la cadena original en modo offline

**Fecha:** VES 	Ene 3, 2011
- Se corrigio un problema en la rutina CFDPrint() que dejaba la impresora PDFCreator pre-configurada para auto-save.
- Se incluyo una descripción por defecto cuando se indica un descuento pero no un motivo.
- Correccion menor en la funcion CFDValidarXML().
- Modificacion en _FixStr() para eliminar los saltos de linea.

**Fecha:** VES	Dic 30, 2010
- Se renombre la funcion NTOCESP() por CFDNTOCESP()
- Nueva clase CFDReporteMensual
- Nueva propiedad ubicacionRepositorio en CFDConf

**Fecha:** VES	Dic 29, 2010
- Nueva funcion CFDVigenciaCert().
- Nueva propiedad UltimoError en CFDConf
- Nueva propiedad modoPruebas en CFDConf
- Nueva propiedad Version en CFDConf
- Nueva funcion CFDLeerCertificado()
- Cambios en metodo LeerCertificado() de CFDComprobante
- Cambios en el metodo Sellar() de CFDComprobante para verificar la valide del certificado antes de sellar
- Nueva funcion CFDValidarXML()
- Nueva funcion CFDGenerarSello()
- Nueva propiedad "MetodoDigest" de CFDConf
- Correcciones varias en CFDExtraerCadenaOriginal()

**Fecha:** VES 	Dic 28, 2010
- Cambios en varias rutinas para manejar el tema de los nombres de archivo largos
- Cambios en la funcion NTOCESP() para adaptarla a los usos en Mexico

**Fecha:** VES 	Dic 27, 2010
- Nueva Utilidad CFDToCursor()
- Nueva utilidadd CFDPrint()
- Correccion en genCadenaOriginal para el caso de
- importe cero en impuestos
- Nueva utilidad CFDExtraerCadenaOriginal()\
- Nuevo procedure CFDInit()
- Nuevo procedure CFDEnviarPorCorreo()
