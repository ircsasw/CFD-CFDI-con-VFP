****************************************************************************
** CFD.PRG
**
** Libreria de clases para generacion del Comprobante Electronico Digital
** en Mexico, segun las indicaciones del SAT
**
** Autores: Victor Espina / Arturo Ramos / Baltazar Moreno
**
** Version: 3.7
** 
** Basado en colaboraciones de:
** - Halcon Divino
** - Carlos Figueroa
** - DanielCB
** 
**
** NOTA IMPORTANTE #1
** A partir de la version 2.4 de esta libreria, el metodo Sellar() de la clase
** CFDComprobante valida que el certificado sea valido y este vigente. Si el 
** certificado no pasa estas pruebas, el metodo no generara el sello y devolvera
** .F., almacenando en la propiedad CFDConf.ultimoError la descripcion de problema.
**
** Se puede obviar esta validacion almacenando .T. en la propiedad CFDConf.modoPruebas
**
** 
** NOTA IMPORTANTE #2
** Si esta teniendo problemas con las funciones o metodos que invocan OpenSSL
** y su carpeta SSL esta ubicada en una ruta que contiene nombres largos o 
** espacios en blanco, puede que el problema se deba a que la creacion de nombres
** cortos (8.3) esta desactivada a nivel de Windows.  Por favor, revise en su
** Register la clave:
**
** HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem\NtfsDisable8dot3NameCreation
**
** y asegurese que su valor sea cero. Si esta en "1", haga el cambio y reinicie
** su sistema. Si el valor ya estaba en cero o el problema persiste luego de 
** cambiarlo a cero, mueva su carpeta SSL a una ruta que no contenga nombres de
** mas de 8 caracteters ni contenga espacios en blanco.
**
**
** NOTA IMPORTANTE #3
** La libreria OpenSSL requiere de las librerias de runtime de VC++ 2008, la cual
** puede no estar disponible en algunos equipos, causando problemas con el sellado
** de los CFDs (y todas las demas funciones de la libreria que dependan de OpenSSL).
**
** Para solucionar este problema, descargue e instale las librerias necesarias desde
** este link (cortesia de Carlos Omar Figueroa):
**
** http://www.microsoft.com/downloads/en/details.aspx?familyid=9B2DA534-3E03-4391-8A4D-074B9F2BC1BF&displaylang=en
**
**
** NOTA IMPORTANTE #4
** Para generar la representación impresa del CFD se utiliza el procedimiento CFDToCursor() para
** pasar los nodos del XML a cursores y así poder reportarlos. Por regla los saltos de línea y
** retornos de carro no estan permitidos en un XML, entonces que pasa si hay un concepto en el
** comprobante donde sea muy importante mostrar información en líneas adicionales sobre todo para
** coneptos muy largos donde se desglozan condiciones u otra información.
** 
** Para solucionar este problema se incluye un parametro adicional a CFDPrint() con el que podemos
** indicar que se va a remplazar los conceptos obtenidos por CFDToCursor() en el cursor QCO por los 
** que estan en el entorno de datos; aquí se supone que en el entorno de datos tenemos un cursor 
** llamado curConceptos con los conceptos del comprobante tal como se guardaron en la base de datos.
**
**
** NOTA IMPORTANTE #5
** A partir de la version 3.2 la propiedad Addenda de la clase CFDComprobante cambia su funcionamiento
** completamente, por lo que ya no es compatible con su uso en versiones anteriores. Ver archivo
** "ADDENDAS.TXT" para informacion sobre como generar addendas.
**
**
****************************************************************************
**       H I S T O R I A L    D E    M O D I F I C A C I O N E S
****************************************************************************
**
** VES  Ago 3, 2012		- Correccion al crear el XML con mas de un complemento de concepto
**
** VES  Jul 30, 2012	- Nueva version 3.7
**						= Nueva funcion CFDCreateQR() basada en el DLL barcodelibrary.dll
**
** VES  Jul 27, 2012	- Nuevas columnas IANUMERO, IAFECHA e IAADUANA en cursor QCO
**						- Cambios en funcion CFDTOCURSOR para llenar columnas IANUMERO, IAFECHA, IAADUANA e INFOADUANA
**						- Se elimino el mensaje de debug "Cached!"
**
** VES  Jul 25, 2012	- Inclusion de la libreria Print2PDF de Paul James (paulj@lifecyc.com)
**       				- Nueva propiedad "usarPrint2PDF" en clase CFDConf
**						- Cambios en CFDPrint para usar la libreria Print2PDF para generar PDFs
**					
** VES  Jul 21, 2012	- Cambio en CFDPrint() para que retorne .T. o .F. al mandar a generar un PDF
**
** ARC  Jun 13, 2012    - Se modifica CFDToCursor para que reciba CFD 2.2 y CFDI 3.2
**                      - Se modifica CFDPrint para contener los datos del régimen fiscal dentro
**                        del cursor general QDG en el campo REGSFIS para la representación impresa
**
** VES  Abr 27, 2012	- Nuevos parametros opcionales pcMoneda, pcPrefijo y pcSufijo en funcion
** 						  CFDNTOCESP() (Colaboracion de DanielCB)
**						- Nuevas propiedades NTOCMoneda, NTOCPrefijo y NTOCSufijo en objeto CFDConf
**						
** VES  Feb 2, 2012     - Correccion de error en metodo Validate de CFDVersionsEnum
**   					- Actualizacion de la propiedad Version de CFDConf
**
** ARC  Ene 14, 2012    - Se repara error en CFDVersionsEnum que no permitia generar CFDI 3.0
** 
** VES  Ene 12, 2012	- Nueva version 3.6
**                      - Modificacion a la funcion CFDExtraerCadenaOriginal a fin de usar la version 
**                        indicada en el comprobante y NO la indicada en CFDConf.XMLVersion a fin de
**                        determinar el XSLT a utilizar para generar la cadena original.
**                      - Nueva propiedad RegimenFiscal en CFDPersona
**                      - Nuevas clases CFDRegimenFiscalCollection y CFDRegimenFiscal
**                      - Nueva propiedad Complemento en clase CFDConcepto
**						- Cambios en metodo CrearXML() para implementar las nuevas propiedades RegimenFiscal y Complemento (Concepto)
**
** ARC  Ene 03, 2012    - nombre de emisor es opcional en 2.2 y 3.2
**                      - nombre de receptor es opcional en todas las versiones
**                      - domicilio de receptor es opcional en 3.0, 2.2 y 3.2
**
** VES	Dic 30, 2011	- Nueva enumeracion CFDVersions (CFDVersionsEnum)
**						- Se cambio el objeto CFDConf de buffer a instancia de clase para poder implementar
**						  un validador para la propiedad XMLVersion.
**						- La propiedad Version de CFDConf ahora es solo-lectura.
**                      - Evento Assign en propiedad Version de CFDComprobante y XMLVersion de CFDConf
**						  para verificar que el valor indicado sea correcto.
**						- Modificacion en constructor de CFDComprobante para asignar por omision el valor
**						  de CFDConf.XMLVersion a la propiedad Version.
**						
**
** ARC  Dic 27, 2011    - Beta de la generacion de comprobantes en version 2.2 y 3.2
**                      - Se modifica CFDExtraerCadenaOriginal para adaptarla a las versiones 2.2 y 3.2
**                      - Se modifica CFDValidarXML para adaptarla a las versiones 2.2 y 3.2
**
** ARC  Dic 20, 2011    - Version 3.5
**                      - Inician los cambios para adaptar a las reformas 'no oficiales' para los formatos
**                        de comprobantes 2.2 y 3.2
**                      - Se cambia la condicion para validar si se crea el nodo DomiciolioFiscal del Emisor, 
**                        se verificaba que exista el atributo calle, este atributo es opcional, puede no estar 
**                        y si requerir el nodo, el unico atributo requerido en el nodo es Pais.
**                      - Se crea la clase CFDRegimenFiscal para el nodo RegimenFiscal del Emisor requerido en 
**                        las versiones 2.2 y 3.2
**
** VES  Nov 21, 2011    - Nuevo metodo getProp() en clase XMLNodeClass
**
** VES  Nov 16, 2011    - Cambios en el metodo CrearXML y la funcion CFDToCursor para eliminar
**                        espacios en blanco dentro del valor RFC
**
** VES  Nov 14, 2011    - Cambios en metodo CrearXML para incluir el manejo de addendas
**                      - Nuevas propiedades nodeName y schemaLocation de la clase ICFDAddenda
**   
** VES  Nov 12, 2011	- Version 3.4
**						- Nuevo uso de la propiedad CFDAddenda de CFDComprobante
**						- Eliminacion de la propiedad CFDAddendas y la clase homonima, introducidos en Oct 10, 2011
**						- Mejoras en el metodo CrearXML() para incluir la generacion del nodo Addenda y/o Comprobante
**                      - Nueva funcion CFDBuffer()
**
** VES  Nov 11, 2011    - Version 3.3
**                      - Nuevas propiedades nameSpace, nodeName y createNodeLInks en clase XMLNOdeClass
**                      - Nueva propiedad createNodeLinks en clase XMLParser, para permitir multiples nodos hermanos con el mismo nombre
**                      - Nuevo metodo ToString() en clase XMLParser
**                      - Mejoras en metodos Open(), Save() e iSaveNode() en clase XMLParser para manejar NameSpaces
**                      - Mejoras en metodo AddNode() de XMLNodeClass para manejar NameSpaces
**                      - Mejoras en el metodo CrearXML() de la clase CFD para implementar las mejoras en las clases XMLParser y XMLNodeClass
**
** VES  Oct 10, 2011	- Nueva clase ICFDAddenda
**                      - Nueva clase CFDAddendas 
**                      - Nueva propiedad Addendas en CFDComprobante
**						- Cambio en CFDPrint() para sustituir uso de clausula READWRITE para matener la compatibilidad con versiones anteriores de VFP 
**
** BMJ  Oct 7, 2011		- Nueva función CFDGoogleQR() que genera un archivo PNG con el QR del CFDI
**                        Parámetros: tcDato, que es la cadena que contendrá codificada el CBB.
**                        Ésta función se ayuda de otra: CFDGetEscaped() la cual convierte los 
**						  caracteres recibidos como parámetro recibido que no son soportados en 
**                        una URL por su secuencia de escape.
**
** ARC  Oct 7, 2011		- Nueva función CFDEnviarPorCorreoAdjuntos para envier por correo
**						  Parámetros: pcDestinatario, pcAsunto, pcCuerpo, pcCFD, pcPDF
**						  Envia CFD y PDF por correo. A diferencia de CFDEnviarPorCorreo esta permite
**   					  adjuntar el PDF ya creado lo cuál es útil cuando se utilizan diferente
**						  formatos para la representación impresa o para enviar comprobantes
**					      que no generó nuestro sistema como puede ser el caso de algunos PACs
**						  que junto con el timbre regresan el PDF
**
** ARC  Oct 6, 2011		- Nueva función CFDCadenaCBB(pcArchivoXML) para obtener la cadena
**						  necesaria para generar el CBB para la representación
**						  impresa de un CFDI desde un XML timbrado
**
** ARC  Ago 7, 2011		- Adaptaciones en CFDValidarXML para poder validar CFDI
**
** ARC  Ago 6, 2011		- Nueva propiedad XMLVersion de la clase CFDConf
**						- Nueva propiedad incluirBOM de la clase CFDConf
**						- Nuevo atributo Moneda de la clase CFDComprobante para CFDI
**						- Nuevo atributo TipoCambio de la clase CFDComprobante para CFDI
**
** ARC  Jul 13, 2011	- Se modifica en CrearXML() que se incluya el BOM en el XML
** 
** VES  Ene 10, 2011	- Cambios en formato CFD
**
** VES  Ene 6, 2011		- Correcciones varias en funcion CrearFactura().
** 						- Se incluyeron los atributos opcionales totalImpuestosRetenidos
**              		  y totalImpuestosTrasladados al generar el XML.
**
** VES	Ene 5, 2011		- Nueva funcion CFDProbarOpenSSL()
**						- Nueva propiedad formatoImpresion de CFDConf
**						- Modificaciones varias en la funcion CFDPrint()
**						- Mejoras en el metodo Sellar() de CFDComprobante
**
** VES	Ene 4, 2011		- Se reprogramo el metodo _GenCadenaOriginal de CFDComprobante
**						  para utilizar la funcion CFDExtraerCadenaOriginal()
** 						- Nuevo objeto CFDCertificado
**						- Nueva propiedad "ultimoCertificado" de la clase CFDConf
**						- Nueva funcion de cache en el metodo LeerCertificado() de la
**						  clase CFDComprobante.
** 						- Se incluyo una nueva seccion de retenciones en el formato CFD.FRX
**						- Modificaciones para permitir la extraccion de la cadena original
**						  en modo offline
**
** VES 	Ene 3, 2011		- Se corrigio un problema en la rutina CFDPrint() que dejaba
**						  la impresora PDFCreator pre-configurada para auto-save.
**						- Se incluyo una descripción por defecto cuando se indica
**						  un descuento pero no un motivo.
**						- Correccion menor en la funcion CFDValidarXML().
**						- Modificacion en _FixStr() para eliminar los saltos de linea.
**
** VES	Dic 30, 2010	- Se renombre la funcion NTOCESP() por CFDNTOCESP()
**						- Nueva clase CFDReporteMensual
**						- Nueva propiedad ubicacionRepositorio en CFDConf
**
** VES	Dic 29, 2010	- Nueva funcion CFDVigenciaCert().
**						- Nueva propiedad UltimoError en CFDConf
**						- Nueva propiedad modoPruebas en CFDConf
**						- Nueva propiedad Version en CFDConf
**                      - Nueva funcion CFDLeerCertificado()
**						- Cambios en metodo LeerCertificado() de CFDComprobante
**						- Cambios en el metodo Sellar() de CFDComprobante para
**						  verificar la valide del certificado antes de sellar
**						- Nueva funcion CFDValidarXML()
**                      - Nueva funcion CFDGenerarSello()
**						- Nueva propiedad "MetodoDigest" de CFDConf
** 						- Correcciones varias en CFDExtraerCadenaOriginal()
**
** VES 	Dic 28, 2010	- Cambios en varias rutinas para manejar el tema
**						  de los nombres de archivo largos
**						- Cambios en la funcion NTOCESP() para adaptarla
**						  a los usos en Mexico
**
** VES 	Dic 27, 2010	- Nueva Utilidad CFDToCursor()
**                      - Nueva utilidadd CFDPrint()
**                      - Correccion en genCadenaOriginal para el caso de
**						- importe cero en impuestos
**						- Nueva utilidad CFDExtraerCadenaOriginal()\
**                      - Nuevo procedure CFDInit()
**                      - Nuevo procedure CFDEnviarPorCorreo()
**
** VES	Dic 20, 2010	Version original
**
****************************************************************************
**  I N T E R F A C E
****************************************************************************
*!*	LEYENDA:

*!*	Clase {Clase Base}
*!*	==================
*!*	+Atributo-Obligatorio [{Clase-Atributo}]
*!*	-Atributo-Opcional
*!*	=Propiedad [nota]
*!*	@Metodo(parametros) [ = {Tipo-valor-retornado}]



*!*	CFDComprobante {Custom}
*!*	=======================
*!*	+Version = "2.0"
*!*	+Folio 
*!*	+Fecha 
*!*	+Sello [1]
*!*	+noAprobacion 
*!*	+anoAprobacion
*!*	+formaDePago
*!*	+noCertificado 
*!*	+subTotal 
*!*	+Total 
*!*	+tipoDeComprobante 
*!*	+Emisor {CFDPersona}
*!*	+Receptor {CFDPersona}
*!*	+Conceptos {CFDConceptos}
*!*	-Serie
*!*	-Certificado 
*!*	-condicionesDePago 
*!*	-Descuento 
*!*	-motivoDescuento 
*!*	-metodoDePago 
*!*	+Impuestos {CFDImpuestos}
*!*	-Addenda {ICFDAddenda}
*!*	=cadenaOriginal [2]
*!* =ubicacionOpenSSL [3]
*!*	@Sellar(archivo-key, password) [4]
*!*	@crearXml(archivo-destino)
*!*	@importarXml(archivo-origen) = {True | False}
*!*	@exportarDbf(ruta-destino)
*!*	@enviarPorCorreo(remitente, destinatario, asunto, texto)

*!*	[1] El valor de este atributo sera llenado automaticamente por la clase al invocar el metodo Sellar()
*!*	[2] Esta propiedad es de solo lectura y devuelve la cadena original en base al contenido de los atributos de la clase
*!* [3] Esta propiedad contiene la carpeta donde esta instalado el OpenSSL
*!* [4] El metodo devuelve .T. si se pudo sellar el certificado o .F. si no fue posible. La propiedad ultimoError de CFDConf
*!*     contendra la explicacion de porque no se pudo sellar


*!*	CFDPersona {Custom}
*!*	===================
*!*	+RFC
*!*	+Nombre
*!*	+domicilioFiscal {CFDDireccion}  [3]
*!*	-expedidoEn {CFDDireccion} [4]
*!* -RegimenFiscal {CFDRegimenFiscalCollection} [5]

*!*	[3] En el caso del receptor, este atributo se utiliza para el atributo "Domicilio" en el XML
*!*	[4] En el caso del receptor, este atrbuto no es tomado en cuenta
*!* [5] En el caso del receptor, este atributo no es tomado en cuenta


*!*	CFDDireccion {Custom}
*!*	=====================
*!*	+Calle
*!*	+Municipio
*!*	+Estado
*!*	+Pais
*!*	+codigoPostal
*!*	-noExterior
*!*	-noInterior
*!*	-Colonia
*!*	-Localidad
*!*	-Referencia


*!*	CFDConceptos {CFDCollection}
*!*	============================
*!*	@Add(cantidad, descripcion, precioUnitario, importe) = {CFDConcepto}


*!*	CFDConcepto {Custom}
*!*	====================
*!*	+Cantidad
*!*	+Descripcion
*!*	+valorUnitario
*!*	+Importe
*!*	-noIdentificacion
*!*	-informacionAduanera {CFDInformacionAduanera}
*!*	-cuentaPredial {CFDCuentaPredial}
*!* -Complemento {ICFDAddenda}


*!*	CFDInformacionAduanera {Custom}
*!*	===============================
*!*	+Numero
*!*	+Fecha
*!*	+Aduana


*!*	CFDCuentaPredial {Custom}
*!*	=========================
*!*	+Numero


*!*	CFDRegimenFiscalCollection {CFDCollection}
*!*	==========================================
*!*	@Add(regimenFiscal) = {CFDRegimenFiscal}


*!*	CFDRegimenFiscal (Custom)
*!*	============================
*!*	+Regimen


*!*	CFDImpuestos {Custom}
*!*	=====================
*!*	=totalImpuestosRetenidos
*!*	=totalImpuestosTrasladados
*!*	-Retenciones {CFDRetenciones}
*!*	-Traslados {CFDTraslados}


*!*	CFDRetenciones {CFDCollection}
*!*	==============================
*!*	@Add(impuesto, importe) = {CFDRetencion}


*!*	CFDTraslados {CFDCollection}
*!*	============================
*!*	@Add(impuesto, tasa, importe) = {CFDTraslado}


*!*	CFDRetencion {Custom}
*!*	=====================
*!*	+Impuesto
*!*	+Importe


*!*	CFDTraslado {Custom}
*!*	====================
*!*	+Impuesto
*!*	+Tasa
*!*	+Importe


*!*	CFDAddenda {CFDCollection}  (Obsoleto)
*!*	==========================
*!*	@Add(nombre, valor)



*!*	CFDCollection {Custom}
*!*	======================
*!*	=Count
*!*	=Items[1..Count]
*!*	@Add(item)


*!*	CFDCertificado (Custom)
*!*	=======================
*!*	=Valido		
*!*	=Vigente	
*!*	=Certificado

	
*!*	ICFDAddenda [Custom]
*!*	===================
*!* -nodeName
*!* -schemaLocation
*!*	-NSTag
*!*	-NSUrl
*!*	@ToString()




****************************************************************************
**  U T I L I D A D E S
****************************************************************************
**
** CFDInit()
** Inicializacion de las distintas rutinas contenidas en la libreria. Se debe
** invocar una vez antes de acceder al resto de las clases y funciones. Este
** procedure crea un objeto publico llamado CFDConf, el cual contiene las
** siguiente propiedades configurables:
**
** Version					Version actual de la libreria CFD
** OpenSSL					Ubicacion del archivo OPENSSL.EXE
** SMTPServer				Servidor SMTP a utilizar para el envio de correos
** SMTPPort					Puerto a utilizar dentro del servidor SMTP
** SMTPUseSSL				Boolean. Indica si se utilizar SSL o no para enviar el correo
** SMTPUserName				Nombre del usuario con el que se autenticara la session en el servidor SMTP
** SMTPPassword				Contrasena del usuario para autenticacion en el servidor SMTP
** MailSender				Direccion electronica del remitente del correo
** ultimoError				Contiene el texto del ultimo error ocurrido
** modoPruebas				Indica si se esta trabajando en modo de pruebas		
** metodoDigest				Ultimo metodo utilizado para la firma del sello digital
** ubicacionRepositorio		Incia la ubicacion del repositorio de CFDs
** ultimoCertificado		Instancia de la clase CFDCertificado con los datos del ultimo certificado utilizado
** formatoImpresion			Formato de impresion a utilizar. Por defecto es CFD.FRX
** XMLversion				Define la versión del XML a crear. Por defecto es versión 2. (2 = CFD y 3 = CFDI)
** icluirBOM				Agrega el BOM correspondiente a los archivos codificados en UTF-8. Por defecto es falso
**
**
** CFDOpenSSL([pcOpenSSL])
** Permite determinar si la libreria OpenSSL esta bien instalada y funciona correctamente. El parametro
** opcional pcOpenSSL permite indicar la ruta donde esta instalada la libreria OpenSSL; si no se
** indica se asume el valor de CFDConf.openSSL. La funcion retorna .T. si la libreria OpenSSL esta
** instalada y funciona correctamente, o .F. en caso contrario. Si la libreria funciona correctamente
** la funcion almacena en CFDConf.ultimoError la version actual de la libreria; si ocurrio algun error
** con la prueba, la descripcion del error ocurrido se almacena tambien en CFDConf.ultimoError.
**
**
** CFDToCursor(pcXML [,pcPrefix])
** Recibe un CFD en formato XML y genera varios cursores contentivos de los
** datos del CFD. El parametro opcion pcPrefix permite indicar el prefijo
** que se desea utilizar para los nombres de los cursores. Si no se indica
** se asume "Q". La funcion crea 5 cursores, a saber:
**
** QDG	Datos generales
** QCO	Conceptos
** QAD	Informacion aduanala
** QRT	Retenciones
** QTR	Traslados
**
**
** CFDPrint(pcXML [, plPreview, plPDFMode, pcPDFTarget, plReplaceCO])
** Recibe un CFD en formato XML y genera una representacion impresora del
** mismo. El parametro opcion plPreview permite mostrar una vista previa
** del comprobante antes de imprimirlo. El parametro opcional plPDFMode permite
** indicar que se desea generar una representacion del CFD en formato PDF. Si
** se indica .T. en este parametro, se debe indicar el nombre y ubicacion del
** archivo PDF a generar en el parametro pcPDFTarget. El parametro opcional
** plReplaceCO indica que los conceptos sean reemplazados por los almacenados
** en el cursor curConceptos para poder utilizar saltos de línea y retornos
** de carro en la descripción de los conceptos ya que estos no son válidos
** en el XML.
**
** IMPORTANTE: Para utilizar la funcion de generar un CFD en formato PDF se
** requiere instalar el producto gratuito PDFCreator (www.pdfcreator.com).
**
**
** CFDExtraerCadenaOriginal(pcXML, pcRutaOpenSSL)
** Permite extraer la cadena original de un CFD indicado. El parametro
** ocRutaOpenSSL contiana la ruta completa a la carpeta donde este
** instalado el OpenSSL.EXE
**
**
** CFDEnviarPorCorreo(pcDestinatario, pcAsunto, pcTexto, pcCFD [,plAdjuntarPDF])
** Permita enviar por correo un CFD generado. Si se indica .T. en el parametro
** opcion plAdjuntarPDF, se asumira que e parametro pcCFD contiene el nombre
** de un CFD en formato XML, y se utilizara el mismo para generar una representacion
** en PDF del comprobante y se anexara tambien al correo.
**
**
** CFDValidarKeyCer(pcArchivoKEY, pcArchivoCER, pcPassword [, pcOpenSSL])
** Permite determinar si el archivp KEY corresponde con el archivo CER
** indicados. Si no se indica el parametro opcion pcOpenSSL, se asume el
** valor de la propiedad CFDConf.openSSL. La fnucion retorna .T. si los
** archivos KEY y CER son complementarios o .F. si no lo son u ocurrio algun
** error. La descripcion del ultimo error ocurrido se almacena en CFDConf.ultimoError
**
**
** CFDLeerCertificado(pcARchivoCER [,pcOpenSSL])
** Lee un certificado indicado y devuelve un objeto con informacion del mismo. 
**
**
** CFDValidarXML(pcArchivoXML, pcArchivoKey, pcPassword, pcMetodo, pcOpenSSL)
** Determina si el XML indicado esta bien formado y cumple con las especificaciones
** del SAT. Adicionalmente valida que el sello este correcto.
**
**
** CFDGenerarSello(pcCadenaOriginal, pcArchivoKey, pcPassword, pcMetodo, pcOpenSSL)
** Permite generar un sello a partir de una cadena original dada. 
** 
** CFDEnviarPorCorreoAdjuntos(pcDestinatario, pcAsunto, pcCuerpo, pcCFD, pcPDF)
** Permite enviar correo adjuntando XML y PDF (sin regenerarlo)
**
** CFDCadenaCBB(pcArchivoXML)
** Genera la cadena para convertir a QR Code (CBB)
*****************************************************************************

#DEFINE CRLF	 CHR(13)+CHR(10)
#DEFINE True	.T.
#DEFINE False	.F.


*-- CFDInit (Procedure)
*   Crea el objeto public CFDConf, el cual contiene
*   configuraciones generales de uso en varios de 
*   los metodos y funciones de la libreria
*
*   VES Dic 30, 2011
*   Se aprovecha para declarar algunas enumeraciones de
*   uso en la clase
*
PROCEDURE CFDInit
 *
 PUBLIC CFDVersions,CFDConf
 CFDVersions = CREATE("CFDVersionsEnum")
 CFDConf = CREATE("CFDConf")
 
 DECLARE Sleep IN kernel32 INTEGER dwMilliseconds  
 
 DECLARE INTEGER GetShortPathName IN kernel32;
    STRING    lpszLongPath,;
    STRING  @ lpszShortPath,;
    INTEGER   cchBuffer
    
DECLARE INTEGER GenerateFile ;
	  IN BarCodeLibrary.dll;
	  STRING   cData, ;
	  STRING   cFileName 

    
 *
ENDPROC


*-- CFDVersionsEnum (Enumeracion)
*   Lista de valores validos para Version
*
DEFINE CLASS CFDVersionsEnum AS Custom
 *
 CFD_20 = 2
 CFD_22 = 22
 CFDi_30 = 3
 CFDi_32 = 32
 validVersionList = "[2][22][3][32]"

 PROCEDURE ToString(pnVersion)
  DO CASE
     CASE pnVersion = THIS.CFD_20
          RETURN "2.0"
          
     CASE pnVersion = THIS.CFD_22
          RETURN "2.2"
          
     CASE pnVersion = THIS.CFDi_30
          RETURN "3.0"
          
     CASE pnVersion = THIS.CFDi_32
          RETURN "3.2"
          
     OTHERWISE
          RETURN ""
  ENDCASE
 ENDPROC

 PROCEDURE FromString(pcVersion)
  DO CASE
     CASE pcVersion = "2.0"
          RETURN THIS.CFD_20
          
     CASE pcVersion = "2.2"
          RETURN THIS.CFD_22

     CASE pcVersion = "3.0"
          RETURN THIS.CFDi_30

     CASE pcVersion = "3.2"
          RETURN THIS.CFDi_32
          
     OTHERWISE
          RETURN 0
  ENDCASE
 ENDPROC
 
 PROCEDURE ToLongString(pcVersion)
  DO CASE
     CASE pcVersion = THIS.CFD_20
          RETURN "CFD 2.0"
          
     CASE pcVersion = THIS.CFD_22
          RETURN "CFD 2.2"
          
     CASE pcVersion = THIS.CFDi_30
          RETURN "CFDi 3.0"
          
     CASE pcVersion = THIS.CFDi_32
          RETURN "CFDi 3.2"
          
     OTHERWISE
          RETURN "Valor incorrecto (" + pcVersion + ")"
  ENDCASE
 ENDPROC
 
 PROCEDURE Validate(vNewVal, puCurValue)
  *
  LOCAL uValue
  IF VARTYPE(m.vNewVal)="N"
   m.vNEwVal = CFDVersions.ToString(m.vNewVal)
  ENDIF
  uValue = CFDVersions.FromString(m.vNewVal)
  IF EMPTY(uValue)
   uValue = puCurValue
   MESSAGEBOX("El valor de version indicado no es correcto.",16,"CFD") 
  ENDIF

  RETURN uValue  
  *
 ENDPROC
 *
ENDDEFINE


*-- CFDConf (Clase)
*   Configuraciones generales de uso en la libreria
*
DEFINE CLASS CFDConf AS Custom
 *
 Version = "3.7"
 OpenSSL = ""
 SMTPServer = ""
 SMTPPort = ""
 SMTPUseSSL = .T.
 SMTPAuthenticate = .T.
 SMTPUserName = ""
 SMTPPassword = ""
 MailSender = ""
 UltimoError = ""
 modoPruebas = .F.
 metodoDigest = "md5"
 ubicacionRepositorio = ".\CFD"
 ultimoCertificado = NULL
 formatoImpresion = "CFD.FRX"
 XMLVersion = 0
 incluirBOM = .F.
 NTOCMoneda = "Pesos"
 NTOCPrefijo = ""
 nTOCSufijo = "M.N."
 usarPrint2PDF = .T.

 PROCEDURE Init
  THIS.Version = CFDVersions.CFDi_32
  THIS.OpenSSL = ADDBS(FULLPATH(".\SSL"))
  THIS.XMLVersion = CFDVersions.CFDi_32
 ENDPROC
  
 PROCEDURE Version_Assign(vNEwVal)
 ENDPROC
 
 PROCEDURE XMLVersion_Assign(vNewVal)
  THIS.XMLVersion = CFDVersions.Validate(m.vNewVal, THIS.XMLVersion)
 ENDPROC
 *
ENDDEFINE




*-- CFDComprobante (Clase)
*   Representa a un comprobante digital
*
DEFINE CLASS CFDComprobante AS Custom
 *
 *-- Atributos requeridos
 * 
 *   ARC Dic 20, 2011: Se agregan las nuevas versiones
 *
 Version = ""  && VES Dic 30, 2011: Se elimino el valor por omision para establecerlo en el constructor
 Folio = 0
 Fecha = {}
 Sello = ""
 noAprobacion = 0
 anoAprobacion = 0
 formaDePago = "Pago en una sola exhibición"
 noCertificado = ""
 subTotal = 0.00
 Total = 0.00
 tipoDeComprobante = ""
 Emisor = NULL
 Receptor = NULL
 Conceptos = NULL
  
 
 *-- Atributos opcionales
 Serie = "" 
 Certificado = "" 
 condicionesDePago = "" 
 Descuento = 0.00
 motivoDescuento = ""
 Impuestos = NULL
 Addenda = NULL
 

 *-- Atributos CFD 2.2 y CFDI 3.2 opcionales 
 MontoFolioFiscalOrig = NULL
 FechaFolioFiscalOrig = {}
 SerieFolioFiscalOrig = NULL
 FolioFiscalOrig = NULL
 NumCtaPago = NULL 
 Moneda = NULL
 TipoCambio = NULL
 
 *-- Atributos CFD 2.2 y CFDI 3.2 requeridos 
 LugarExpedicion = NULL
 metodoDePago = ""  && ARC Dic 20, 2011: es requerido en CFD 2.2 y CFDI 3.2
 
 *-- Propiedades
 cadenaOriginal = ""   && Solo-lectura
 ubicacionOpenSSL = ".\SSL"
  
 
 *-- Getters / Setters
 PROCEDURE cadenaOriginal_Access
  RETURN THIS._genCadenaOriginal()
 ENDPROC
 PROCEDURE cadenaPriginal_Assign(vNewVal)
 ENDPROC 
 
 
 *-- Constructor de la clase
 *   
 *   VES Dic 30, 2011: Se incluyo el parametro opcional pnVersion
 *
 PROCEDURE Init(pnVersion)
  *
  IF PCOUNT() = 0   && Si no se indico una version, se asume la version indicada en CFDConf.XMLVersion
   pnVersion = CFDConf.XMLVersion
  ENDIF
  
  THIS.Version = pnVersion
  THIS.Emisor = CREATEOBJECT("CFDPersona")
  THIS.Receptor = CREATEOBJECT("CFDPersona")
  THIS.Conceptos = CREATEOBJECT("CFDConceptos")
  THIS.Impuestos = CREATEOBJECT("CFDImpuestos")
  THIS.ubicacionOpenSSL = CFDConf.OpenSSL
  *
 ENDPROC
 
 
 *-- Setter para propiedad Version
 *
 PROCEDURE Version_Assign(vNewVal)
  LOCAL nVersion
  nVersion = CFDVersions.Validate(m.vNewVal, 0)
  IF nVersion > 0
   THIS.Version = CFDVersions.ToString(nVersion)
  ENDIF
 ENDPROC

 
 
 
 *-- Metodos
 
 *-- _genCadenaOriginal (Metodo)
 *   Genera la cadena original que sirve de base para generar el sello digital. El codigo original
 *   pertenece al amigo Halcon Divino, y fue adaptado para el uso dentro de esta clase.
 *
 *   VES Ene 4, 2011
 *   Se cambio el codigo para obtener la cadena original directametne del XML aplicando el archivo
 *   XSLT proporcionado por el SAT. De esta forma nos garantizamos que no haya diferencia entre
 *   la cadena original generada por la clase y la que genera el SAT a partir del XML, lo cual 
 *   elimina los problemas de sellado por diferencia en la cadena original.
 *
 PROCEDURE _genCadenaOriginal()
  *
  LOCAL cTempFile
  cTempFile = GetTempFile("XML")
  THIS.CrearXML(cTempFile)
  
  LOCAL cStr
  cStr = CFDExtraerCadenaOriginal(cTempFile)
  
  ERASE (cTempFile)
  
  RETURN cStr
  *
 ENDPROC
 
 
 *-- _fixStr (Metodo)
 *   Recibe una cadena y realiza los siguientes cambios:
 *   a) Sustituye cualquier caracter invalido por el caracter "."
 *   b) Elimina los espacios en blanco al inicio y al final de la cadena
 *   c) Elimina cualquier secuencia de espacios en blanco repetidos dentro de la cadena
 *   d) Si la cadena resultante contiene al menos 1 caracter, se le anade la cadena
 *      indicada en el parametro pcSep
 *
 *   La funcion fue reeacrita a partir de la funcion QtarChrInval() de Halcon Divino, a fin
 *   de simplificar el codigo y depurarlo. El metodo utilizado por Halcon Divino para incluir
 *   cada elemento en la cadena original implicaba una doble llamada a QtarChrInval() para 
 *   cada valor en la cadena:
 *
 *   cStr  = cStr  + Iif(Len(QtarChrInval(valor)) = 0, "" ,QtarChrInval(valor) + "|") 
 *
 *   Este codigo se simplifica y mejora haciendo una sola invocacion a fixStr:
 *
 *   cStr = cStr + THIS._fixStr(valor, "|")
 *
 *   Adicionalmente se incluyo codigo para permitir que la funcion reciba cualquier tipo
 *   de datos, haciendo la conversion adecuada segun el tipo. En los casos donde el parametro
 *   de entraada no sea un string, no se realiza la verificacion de caracteres invalidos
 *
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
 

 *-- Sellar (Metodo)
 *   Genera el sello digital del comprobante y actualiza los atributos apropiados
 *
 PROCEDURE Sellar(pcArchivoKey, pcPassword)
  *
  CFDConf.ultimoError = ""

  *-- Si la fecha del comprobante es igual o posterior al 1-1-2011, se cambia
  *   el metodo MD5 por SHA-1
  *
  LOCAL cMetodo
  cMetodo = "md5"
  IF YEAR(THIS.fecha) > 2010 
   cMetodo = "sha1"
  ENDIF
  CFDConf.metodoDigest = cMetodo
  
  *-- Se obtiene la cadena original
  *
  LOCAL cCadenaOriginal
  cCadenaOriginal = THIS.cadenaOriginal
  IF EMPTY(cCadenaOriginal)
   CFDConf.ultimoError = "No se pudo obtener la cadena original. Utilize CFDProbarOpenSSL() para verificar el funcionamiento de la libreria OpenSSL"
   RETURN .F.
  ENDIF
  
  
  *-- Se genera el sello para la cadena original
  *
  THIS.Sello = CFDGenerarSello(cCadenaOriginal, pcArchivoKey, pcPassword, cMetodo, THIS.ubicacionOpenSSL)
  
  RETURN !EMPTY(THIS.Sello)
  *
 ENDPROC
 
 
 *-- leerCertificado
 *   Lee el archivo de certificado indicado y actualiza
 *   los atributos apropiados
 *
 *   VES Ene 4, 2011
 *   Se utiliza la propiedad CFDConf.ultimoCertificado como
 *   un "cache" para evitar leer innecesariamente el mismo
 *   certificado varias veces seguidas
 *
 PROCEDURE leerCertificado(pcArchivoCER)
  *
  *-- Se lee el certificado (solo si es necesario)
  LOCAL oCert  
  IF ISNULL(CFDConf.ultimoCertificado) OR CFDConf.ultimoCertificado.Archivo <> LOWER(pcArchivoCER)
   oCert = CFDLeerCertificado(pcArchivoCER)
   IF ISNULL(oCert)
    RETURN NULL
   ENDIF  
   CFDConf.ultimoCertificado = oCert
  ELSE
   oCert = CFDConf.ultimoCertificado 
   *?"Cached!"
  ENDIF 
  
  IF oCert.Valido AND (oCert.Vigente OR CFDConf.modoPruebas)
   THIS.Certificado = oCert.Certificado
   THIS.noCertificado = oCert.Serial
  ENDIF
  
  RETURN oCert
  *
 ENDPROC
 
 
 *-- CrearXML (Metodo)
 *   Crea el archivo XML que representa el comprobante
 *
 PROCEDURE CrearXML(pcArchivo, plValidar, pcArchivoKey, pcPassword, pcMetodo)
  *
  #DEFINE CFD_OPCIONAL		.T.  
  
  CFDConf.ultimoError = ""

  LOCAL oParser,nVersion
  oParser = CREATEOBJECT("XmlParser")
  nVersion = CFDVersions.fromString(THIS.Version)
  WITH oParser
   *
   .indentString = ""
   .New()
   
   *-- Nodo "Comprobante"
   .XML.addNode("Comprobante")
   IF INLIST(nVersion, CFDVersions.CFDi_30, CFDVersions.CFDi_32)
    .XML._Comprobante.NameSpace = "cfdi"  && Al anadir el NS "Cfdi" al nodo comprobante, todos los subnodos lo heredaran automaticamente
   ENDIF
   WITH .XML._Comprobante
    DO CASE 
      CASE nVersion = CFDVersions.CFD_20
    	.addProp("xmlns","http://www.sat.gob.mx/cfd/2")
    	.addProp("xmlns:xsi","http://www.w3.org/2001/XMLSchema-instance")
   		.addProp("xsi:schemaLocation","http://www.sat.gob.mx/cfd/2 http://www.sat.gob.mx/sitio_internet/cfd/2/cfdv2.xsd")
   		
      CASE nVersion = CFDVersions.CFDi_30
   		.addProp("xmlns:cfdi","http://www.sat.gob.mx/cfd/3")
    	.addProp("xmlns:xsi","http://www.w3.org/2001/XMLSchema-instance")
   		.addProp("xsi:schemaLocation","http://www.sat.gob.mx/cfd/3 http://www.sat.gob.mx/sitio_internet/cfd/3/cfdv3.xsd")
   		
   	  CASE nVersion = CFDVersions.CFD_22
    	.addProp("xmlns","http://www.sat.gob.mx/cfd/2")
    	.addProp("xmlns:xsi","http://www.w3.org/2001/XMLSchema-instance")
   		.addProp("xsi:schemaLocation","http://www.sat.gob.mx/cfd/2 http://www.sat.gob.mx/sitio_internet/cfd/2/cfdv22.xsd")
   		
      CASE nVersion = CFDVersions.CFDi_32
   		.addProp("xmlns:cfdi","http://www.sat.gob.mx/cfd/3")
    	.addProp("xmlns:xsi","http://www.w3.org/2001/XMLSchema-instance")
   		.addProp("xsi:schemaLocation","http://www.sat.gob.mx/cfd/3 http://www.sat.gob.mx/sitio_internet/cfd/3/cfdv32.xsd")
   	ENDCASE  
    .addProp("version",THIS._fixStr(THIS.version))
    .addProp("serie",THIS._fixStr(THIS.serie),CFD_OPCIONAL)
    .addProp("folio",THIS._fixStr(STR(THIS.folio,10,0)))
    .addProp("fecha",THIS._fixStr(THIS.fecha))
    IF INLIST(nVersion, CFDVersions.CFD_20, CFDVersions.CFD_22)
	    .addProp("noAprobacion",THIS._fixStr(STR(THIS.noAprobacion,10,0)))
    	.addProp("anoAprobacion",THIS._fixStr(STR(THIS.anoAprobacion,10,0)))
    ENDIF 
    IF INLIST(nVersion, CFDVersions.CFD_22, CFDVersions.CFDi_30, CFDVErsions.CFDi_32)
    	.addProp("Moneda",THIS._fixStr(THIS.moneda),CFD_OPCIONAL)
    	.addProp("TipoCambio",THIS._fixStr(THIS.tipocambio),CFD_OPCIONAL)
    ENDIF  
    IF INLIST(nVersion, CFDVersions.CFD_22, CFDVersions.CFDi_32)
    	.addProp("MontoFolioFiscalOrig",THIS._fixStr(THIS.MontoFolioFiscalOrig),CFD_OPCIONAL)
    	.addProp("FechaFolioFiscalOrig",THIS._fixStr(THIS.FechaFolioFiscalOrig),CFD_OPCIONAL)
    	.addProp("SerieFolioFiscalOrig",THIS._fixStr(THIS.SerieFolioFiscalOrig),CFD_OPCIONAL)
    	.addProp("FolioFiscalOrig",THIS._fixStr(THIS.FolioFiscalOrig),CFD_OPCIONAL)
    	.addProp("NumCtaPago",THIS._fixStr(THIS.NumCtaPago),CFD_OPCIONAL)
    	.addProp("LugarExpedicion",THIS._fixStr(THIS.LugarExpedicion))
    ENDIF 
   	.addProp("metodoDePago",THIS._fixStr(THIS.metodoDePago),CFD_OPCIONAL)
    .addProp("formaDePago",THIS._fixStr(THIS.formaDePago))
    *.addProp("",THIS._fixStr(THIS.))
    .addProp("condicionesDePago",THIS._fixStr(THIS.condicionesDePago),CFD_OPCIONAL)
    .addProp("subTotal",THIS._fixStr(STR(THIS.subTotal,15,2)))
    .addProp("descuento",THIS._fixStr(TRANSFORM(THIS.Descuento,"@Z 999999999999.99")),CFD_OPCIONAL)
    .addProp("motivoDescuento",THIS._fixStr(THIS.motivoDescuento),CFD_OPCIONAL)
    .addProp("total",THIS._fixStr(STR(THIS.total,15,2)))
    .addProp("tipoDeComprobante",THIS._fixStr(THIS.tipoDeComprobante))
    .addProp("noCertificado",THIS.noCertificado)
    .addProp("certificado",THIS.Certificado)
    .addProp("sello",THIS.sello)
   ENDWITH
  
   *-- Nodo "Emisor"
   .XML._Comprobante.addNode("Emisor")
   WITH .XML._Comprobante._Emisor
    .addProp("rfc",CHRT(THIS._fixStr(THIS.Emisor.rfc),".- ",""))  && VES Nov 16, 2011
    IF INLIST(nVersion, CFDVersions.CFD_20, CFDVersions.CFDi_30)  && ARC Ene 03, 2012: Nombre de Emisor opcional en 2.2 y 3.2
      .addProp("nombre",THIS._fixStr(THIS.Emisor.nombre))
    ELSE 
      IF NOT EMPTY(THIS.Emisor.nombre)
        .addProp("nombre",THIS._fixStr(THIS.Emisor.nombre))
      ENDIF 
    ENDIF 
    
    IF NOT EMPTY(THIS.Emisor.domicilioFiscal.Pais) && ARC Dic 27, 2011: domiciolio del emisor es opcional en 2.2 y 3.2
      .addNode("DomicilioFiscal")
      WITH ._DomicilioFiscal
       .addProp("calle",THIS._fixStr(THIS.Emisor.DomicilioFiscal.Calle))
       .addProp("noExterior",THIS._fixStr(THIS.Emisor.DomicilioFiscal.noExterior),CFD_OPCIONAL)
       .addProp("noInterior",THIS._fixStr(THIS.Emisor.DomicilioFiscal.noInterior),CFD_OPCIONAL)
       .addProp("colonia",THIS._fixStr(THIS.Emisor.DomicilioFiscal.colonia),CFD_OPCIONAL)
       .addProp("localidad",THIS._fixStr(THIS.Emisor.DomicilioFiscal.localidad),CFD_OPCIONAL)
       .addProp("referencia",THIS._fixStr(THIS.Emisor.DomicilioFiscal.referencia),CFD_OPCIONAL)
       .addProp("municipio",THIS._fixStr(THIS.Emisor.DomicilioFiscal.municipio))
       .addProp("estado",THIS._fixStr(THIS.Emisor.DomicilioFiscal.estado))
       .addProp("pais",THIS._fixStr(THIS.Emisor.DomicilioFiscal.pais))
       .addProp("codigoPostal",THIS._fixStr(THIS.Emisor.DomicilioFiscal.codigoPostal),CFD_OPCIONAL)
      ENDWITH
    ENDIF 

    IF NOT EMPTY(THIS.Emisor.ExpedidoEn.Pais) && ARC Dic 27, 2011: Ya que Pais es el unico atributo requerido
     .addNode("ExpedidoEn")
     WITH ._ExpedidoEn
      .addProp("calle",THIS._fixStr(THIS.Emisor.ExpedidoEn.Calle))
      .addProp("noExterior",THIS._fixStr(THIS.Emisor.ExpedidoEn.noExterior),CFD_OPCIONAL)
      .addProp("noInterior",THIS._fixStr(THIS.Emisor.ExpedidoEn.noInterior),CFD_OPCIONAL)
      .addProp("colonia",THIS._fixStr(THIS.Emisor.ExpedidoEn.colonia),CFD_OPCIONAL)
      .addProp("localidad",THIS._fixStr(THIS.Emisor.ExpedidoEn.localidad),CFD_OPCIONAL)
      .addProp("referencia",THIS._fixStr(THIS.Emisor.ExpedidoEn.referencia),CFD_OPCIONAL)
      .addProp("municipio",THIS._fixStr(THIS.Emisor.ExpedidoEn.municipio))
      .addProp("estado",THIS._fixStr(THIS.Emisor.ExpedidoEn.estado))
      .addProp("pais",THIS._fixStr(THIS.Emisor.ExpedidoEn.pais))
      .addProp("codigoPostal",THIS._fixStr(THIS.Emisor.ExpedidoEn.codigoPostal),CFD_OPCIONAL)
     ENDWITH
    ENDIF
    
    IF INLIST(nVersion, CFDVersions.CFD_22, CFDVersions.CFDi_32)
      LOCAL nRegimen,oRegimen,oNodoRegimen   && VES Ene 12, 2012
      FOR nRegimen = 1 TO THIS.Emisor.RegimenFiscal.Count
       oRegimen = THIS.Emisor.RegimenFiscal.Items[nRegimen]
       oNodoRegimen = .addNode("RegimenFiscal")
       oNodoRegimen.addProp("Regimen",THIS._fixStr(oRegimen.Regimen))
      ENDFOR
    ENDIF 
   ENDWITH
   
   
   *-- Nodo "Receptor"
   .XML._Comprobante.addNode("Receptor")
   WITH .XML._Comprobante._Receptor
    .addProp("rfc",CHRT(THIS._fixStr(THIS.Receptor.rfc),".- ",""))   && VES Nov 16, 2011
    IF NOT EMPTY(THIS.Receptor.nombre)   && ARC Ene 03, 2012: Nombre de Receptor es opcional
      .addProp("nombre",THIS._fixStr(THIS.Receptor.nombre))
    ENDIF 
    
    IF NOT EMPTY(THIS.Receptor.DomicilioFiscal.pais) && ARC Ene 03, 2012: Ya que Pais es el unico atributo requerido
      .addNode("Domicilio")  && Es opcional en 3.0, 2.2 y 3.2
      WITH ._Domicilio
       .addProp("calle",THIS._fixStr(THIS.Receptor.DomicilioFiscal.Calle),CFD_OPCIONAL)
       .addProp("noExterior",THIS._fixStr(THIS.Receptor.DomicilioFiscal.noExterior),CFD_OPCIONAL)
       .addProp("noInterior",THIS._fixStr(THIS.Receptor.DomicilioFiscal.noInterior),CFD_OPCIONAL)
       .addProp("colonia",THIS._fixStr(THIS.Receptor.DomicilioFiscal.colonia),CFD_OPCIONAL)
       .addProp("localidad",THIS._fixStr(THIS.Receptor.DomicilioFiscal.localidad),CFD_OPCIONAL)
       .addProp("referencia",THIS._fixStr(THIS.Receptor.DomicilioFiscal.referencia),CFD_OPCIONAL)
       .addProp("municipio",THIS._fixStr(THIS.Receptor.DomicilioFiscal.municipio),CFD_OPCIONAL)
       .addProp("estado",THIS._fixStr(THIS.Receptor.DomicilioFiscal.estado),CFD_OPCIONAL)
       .addProp("pais",THIS._fixStr(THIS.Receptor.DomicilioFiscal.pais))
       .addProp("codigoPostal",THIS._fixStr(THIS.Receptor.DomicilioFiscal.codigoPostal),CFD_OPCIONAL)
      ENDWITH
    ENDIF 
   ENDWITH
   
   
   *-- Nodo "Conceptos"
   *   
   *   La clase XmlParser no reconoce que un nodo pueda contener dos subnodos con el mismo nombre. Para
   *   solucionar este impase, se le anade un contador al nombre de cada nodo Concepto, de modo que quede 
   *   asi:
   *
   *   <Conceptos>
   *     <Concepto001 ... />
   *     <Concepto002 ... />
   *   </Conceptos>
   *
   *   Una vez generado el Xml, se cargara en memoria para quitar las secuencias y asi corregir el problema
   *
   *   VES Nov 11, 2011
   *   La nueva propiedad createNodeLinks en la clas XMLNodeClass permite superar este problema
   *
   LOCAL i,oItem,oNodo
   .XML._Comprobante.addNode("Conceptos")
   WITH .XML._Comprobante._Conceptos
    .createNodeLinks = .F.   && Nov 11, 2011
    FOR i = 1 TO THIS.Conceptos.Count
     oItem = THIS.Conceptos.Items(i)
     oNodo = .addNode("Concepto")
     WITH oNodo
      .addProp("cantidad",THIS._fixStr(STR(oItem.cantidad,10,2)))
      .addProp("unidad",THIS._fixStr(oItem.unidad),CFD_OPCIONAL)
      .addProp("noIdentificacion",THIS._fixStr(oItem.noIdentificacion),CFD_OPCIONAL)
      .addProp("descripcion",THIS._fixStr(oItem.descripcion))
      .addProp("valorUnitario",THIS._fixStr(STR(oItem.valorUnitario,15,2)))
      .addProp("importe",THIS._fixStr(STR(oItem.Importe,15,2)))
      
      IF !EMPTY(oItem.informacionAduanera.Numero)
       .addNode("InformacionAduanera")
       WITH .Nodes[1]  && VES Nov 11, 2011
        .addProp("numero",THIS._fixStr(oItem.informacionAduanera.numero))
        .addProp("fecha",THIS._fixStr(oItem.informacionAduanera.fecha))        
        .addProp("aduana",THIS._fixStr(oItem.informacionAduanera.aduana))        
       ENDWITH
      ENDIF

      IF !EMPTY(oItem.CuentaPredial.Numero)
       .addNode("CuentaPredial")
       WITH ._CuentaPredial
        .addProp("numero",THIS._fixStr(oItem.CuentaPredial.numero))
       ENDWITH
      ENDIF
     
     
      *-- VES Ene 12, 2012: Si el concepto contiene un complemento, se inserta como si
      *   fuera una addenda en el concepto
      IF !ISNULL(oItem.Complemento) AND LOWER(oItem.Complemento.ParentClass) == "icfdaddenda"
       oNodo = .addNode("ComplementoConcepto")
       oNodo.Data = oItem.Complemento.ToString() 
       IF !EMPTY(oItem.Complemento.NSTag)
        * VES Ago 3, 2012: Se valida que no se haya declarado el Namespace anteriormente, antes
        * de anadir su declaracion en las propiedades del nodo Comprobante 
        IF NOT oParser.XML._Comprobante.isProp("xmlns:" + oItem.Complemento.NSTag)
         oParser.XML._Comprobante.addProp("xmlns:" + oItem.Complemento.NSTag, oItem.Complemento.NSUrl)
        ENDIF
       ENDIF
       IF !EMPTY(oItem.Complemento.schemaLocation)
        WITH oParser.XML._Comprobante.Props["xsi:schemaLocation"]
         .Value = .Value + SPACE(1) + oItem.Complemento.schemaLocation
        ENDWITH
       ENDIF
      ENDIF 
     
      
     ENDWITH
    ENDFOR
   ENDWITH
   
   
   *-- Nodo "Impuestos"
   *
   *   Tanto para los subnodos de Retenciones como de Impuestos se aplico la misma tecnica de enumeracion
   *   aplicada con los subnodos de Conceptos
   *
   *   VES Nov 11, 2011
   *   Se aplica la nueva propiedad createNodeLinks para evitar este problema
   *
   .XML._Comprobante.addNode("Impuestos")
   WITH .XML._Comprobante._Impuestos
    IF THIS.Impuestos.Retenciones.Count > 0
     .addProp("totalImpuestosRetenidos",THIS._fixStr(STR(THIS.Impuestos.totalImpuestosRetenidos,15,2)))
     .addNode("Retenciones")
     WITH ._Retenciones
     .createNodeLinks = .F.   && Nov 11, 2011     
      FOR i = 1 TO THIS.Impuestos.Retenciones.Count
       oItem = THIS.Impuestos.Retenciones.Items(i)
       oNodo = .addNode("Retencion")
       oNodo.addProp("impuesto",THIS._fixStr(oItem.Impuesto))
       oNodo.addProp("importe",THIS._fixStr(STR(oItem.Importe,15,2)))
      ENDFOR
     ENDWITH
    ENDIF
    
    IF THIS.Impuestos.Traslados.Count > 0
     .addProp("totalImpuestosTrasladados",THIS._fixStr(STR(THIS.Impuestos.totalImpuestosTrasladados,15,2))) 
     .addNode("Traslados")
     WITH ._Traslados
      .createNodeLinks = .F.  && Nov 11, 2011
      FOR i = 1 TO THIS.Impuestos.Traslados.Count
       oItem = THIS.Impuestos.Traslados.Items(i)
       oNodo = .addNode("Traslado")
       oNodo.addProp("impuesto",THIS._fixStr(oItem.Impuesto))
       oNodo.addProp("tasa",THIS._fixStr(STR(oItem.tasa,6,2)))       
       oNodo.addProp("importe",THIS._fixStr(STR(oItem.Importe,15,2)))
      ENDFOR
     ENDWITH
    ENDIF
    
   ENDWITH



   *-- Nodo "Addenda"
   *
   *   VES Nov 14, 2011
   *   Se reprogramo esta rutina para hacer uso de la nueva clase ICFDAddenda
   *
   IF !ISNULL(THIS.Addenda) AND LOWER(THIS.Addenda.ParentClass) == "icfdaddenda"
    oNodo = oParser.XML._Comprobante.addNode(THIS.Addenda.nodeName)
    oNodo.Data = THIS.Addenda.ToString() 
    IF !EMPTY(THIS.Addenda.NSTag)
     oParser.XML._Comprobante.addProp("xmlns:" + THIS.Addenda.NSTag, THIS.Addenda.NSUrl)
    ENDIF
    IF !EMPTY(THIS.Addenda.schemaLocation)
     WITH oParser.XML._Comprobante.Props["xsi:schemaLocation"]
      .Value = .Value + SPACE(1) + THIS.Addenda.schemaLocation
     ENDWITH
    ENDIF
   ENDIF 

   

   *-- Se crea el archivo Xml
   .Save(pcArchivo)
   
   
   *-- Se carga el Xml en memoria de nuevo para eliminar los tags consecutivos
   *   de los nodos Concepto, Retenciones y Traslados, asi como eliminar los
   *   CRLF
   LOCAL cBuff
   cBuff = FILETOSTR(pcArchivo)
*!*	   FOR i = 1 TO THIS.Conceptos.Count
*!*	    cBuff = STRT(cBuff,"<Concepto" + PADL(i,3,"0"),"<Concepto")
*!*	    cBuff = STRT(cBuff,"</Concepto" + PADL(i,3,"0"),"</Concepto")    
*!*	   ENDFOR
*!*	   FOR i = 1 TO THIS.Impuestos.Retenciones.Count
*!*	    cBuff = STRT(cBuff,"<Retencion" + PADL(i,2,"0"),"<Retencion")
*!*	   ENDFOR
*!*	   FOR i = 1 TO THIS.Impuestos.Traslados.Count
*!*	    cBuff = STRT(cBuff,"<Traslado" + PADL(i,2,"0"),"<Traslado")
*!*	   ENDFOR
   cBuff = STRT(cBuff, ">" + CHR(13)+CHR(10), ">")
   cBuff = STRT(cBuff, "?>", "?>" + CHR(13) + CHR(10))
   
   
   *-- Si es CFDI se agrega a los nodos el prefijo 'cfdi:'
   *
   *   VES Nov 11, 2011
   *   Solucionado con la nueva propiedad NameSpace de la clase XMLNodeClass
   *
*!*	   IF ALLTRIM(THIS.version) = "3.0"
*!*		cBuff = STRT(cBuff, "<Comprobante", "<cfdi:Comprobante")	   
*!*			cBuff = STRT(cBuff, "<Emisor", "<cfdi:Emisor")
*!*				cBuff = STRT(cBuff, "<DomicilioFiscal", "<cfdi:DomicilioFiscal")
*!*				cBuff = STRT(cBuff, "<ExpedidoEn", "<cfdi:ExpedidoEn")
*!*			cBuff = STRT(cBuff, "</Emisor>", "</cfdi:Emisor>")
*!*			cBuff = STRT(cBuff, "<Receptor", "<cfdi:Receptor")
*!*				cBuff = STRT(cBuff, "<Domicilio", "<cfdi:Domicilio")
*!*			cBuff = STRT(cBuff, "</Receptor>", "</cfdi:Receptor>")
*!*			cBuff = STRT(cBuff, "<Conceptos>", "<cfdi:Conceptos>")
*!*				cBuff = STRT(cBuff, "<Concepto ", "<cfdi:Concepto ")
*!*					cBuff = STRT(cBuff, "<InformacionAduanera", "<cfdi:InformacionAduanera")
*!*					cBuff = STRT(cBuff, "<CuentaPredial", "<cfdi:CuentaPredial")
*!*					cBuff = STRT(cBuff, "<ComplementoConcepto", "<cfdi:ComplementoConcepto")
*!*					cBuff = STRT(cBuff, "<Parte", "<cfdi:Parte")
*!*				cBuff = STRT(cBuff, "</Concepto>", "</cfdi:Concepto>")
*!*			cBuff = STRT(cBuff, "</Conceptos>", "</cfdi:Conceptos>")
*!*			cBuff = STRT(cBuff, "<Impuestos", "<cfdi:Impuestos")
*!*				cBuff = STRT(cBuff, "<Retenciones>", "<cfdi:Retenciones>")
*!*					cBuff = STRT(cBuff, "<Retencion", "<cfdi:Retencion")
*!*				cBuff = STRT(cBuff, "</Retenciones>", "</cfdi:Retenciones>")
*!*				cBuff = STRT(cBuff, "<Traslados>", "<cfdi:Traslados>")
*!*					cBuff = STRT(cBuff, "<Traslado", "<cfdi:Traslado")
*!*				cBuff = STRT(cBuff, "</Traslados>", "</cfdi:Traslados>")
*!*			cBuff = STRT(cBuff, "</Impuestos>", "</cfdi:Impuestos>")
*!*			cBuff = STRT(cBuff, "<Addenda>", "<cfdi:Addenda>")
*!*		cBuff = STRT(cBuff, "</Comprobante>", "</cfdi:Comprobante>")
*!*	   ENDIF 
   
   
   *-- Se graba de nuevo el Xml ya en su forma final
   cBuff = CFDAsc2UTF8(cBuff)
   
   *-- El 4 del tercer parámetro en STRTOFILE() agrega el BOM al XML en UTF-8
   IF CFDConf.incluirBOM
      * VES Jul 25, 2012
      * Se sustituyo el codigo original por un codigo compatible con VFP 6
      *
      * Codigo original:
      *STRTOFILE(cBuff,pcArchivo,4)
      LOCAL cBOM
      cBOM = CHR(0xEF) + CHR(0xBB) + CHR(0xBF)
      STRTOFILE(cBOM + cBuff, pcArchivo)
   ELSE 
      STRTOFILE(cBuff,pcArchivo)
   ENDIF 
   cBuff=""
   
   
   *-- Si se indico el parametro plValidar, se verifica que el XML este bien formado y que el sello sea valido
   *
   IF plValidar
    *
    *-- Se valida la sintaxis del XML
    IF NOT CFDValidarXML(pcArchivo, pcArchivoKey, pcPassword, pcMetodo, THIS.ubicacionOpenSSL)
     RETURN .F.
    ENDIF
    *
   ENDIF
   
   
   RETURN .T.
   *
  ENDWITH 
  
  *
 ENDPROC
 *

ENDDEFINE


*-- CFDRegimenFiscal
*   Datos de un regimen fiscal
*
DEFINE CLASS CFDRegimenFiscal AS Custom
 *
 Regimen = ""
 *
ENDDEFINE


*-- CFDRegimenFiscalCollection (Clase)
*   Lista de regimenes fiscales de una persona
*
DEFINE CLASS CFDRegimenFiscalCollection AS CFDCollection
 *
 Regimen = ""   && Regimen por omision
 
 *-- Regimen (Setter)
 PROCEDURE Regimen_Assign(vNewVal)
  IF THIS.Count = 0
   THIS.Add(m.vNewVal)
  ENDIF
 ENDPROC
 
 *-- Regimen (Getter)
 PROCEDURE Regimen_Access
  IF THIS.Count > 0
   RETURN THIS.Items[1].Regimen
  ELSE
   RETURN ""
  ENDIF
 ENDPROC
 
 
 *-- Add (Metodo)
 *   Incluye un nuevo elemento en la coleccion
 PROCEDURE Add(pcRegimen)
  *
  LOCAL oItem
  oItem = CREATEOBJECT("CFDRegimenFiscal")
  WITH oItem
   .Regimen = pcRegimen
  ENDWITH
  
  RETURN DODEFAULT(oItem)
  *
 ENDPROC
 
 *
ENDDEFINE



*-- CFDPersona (Clase)
*   Representa los datos de una persona juridica especifica
*   dentro de un comprobante digital
*
DEFINE CLASS CFDPersona AS Custom
 *
 *-- Atributos requeridos
 RFC = ""
 RegimenFiscal = NULL	&& ARC Dic 20, 2011: Requerido solo para Emisor
 
 *-- Atributos opcionales
 expedidoEn = NULL
 Nombre = ""
 domicilioFiscal = NULL
 
 *-- Contructor de la clase
 PROCEDURE Init
  THIS.domicilioFiscal = CREATEOBJECT("CFDDireccion")
  THIS.expedidoEn = CREATEOBJECT("CFDDireccion")  
  THIS.RegimenFiscal = CREATEOBJECT("CFDRegimenFiscalCollection")
 ENDPROC
 *
ENDDEFINE



*-- CFDDireccion (Clase)
*   Representa una direccion fiscal dentro de un
*   comprobante digital
*
DEFINE CLASS CFDDireccion AS Custom
 *
 *-- Atributos requeridos
 Calle = ""
 Municipio = ""
 Estado = ""
 Pais = ""
 codigoPostal = ""

 *-- Atributos opcionales 
 noExterior = ""
 noInterior = ""
 Colonia = ""
 Localidad = ""
 Referencia = ""
 *
ENDDEFINE




*-- CFDConceptos (Clase)
*   Representa la lista de conceptos contenidos en el comprobante
*
DEFINE CLASS CFDConceptos AS CFDCollection
 *
 *-- Add (Metodo)
 *   Incluye un nuevo elemento en la coleccion
 *
 PROCEDURE Add(pnCantidad, pcDescripcion, pnPU, pnImporte)
  *
  LOCAL oConcepto
  oConcepto = CREATEOBJECT("CFDConcepto")
  WITH oConcepto
   .Cantidad = pnCantidad
   .Descripcion = pcDescripcion
   .valorUnitario = pnPU
   .Importe = pnImporte
  ENDWITH
  
  RETURN DODEFAULT(oConcepto)
  *
 ENDPROC
 *
ENDDEFINE



*-- CFDConcepto (Clase)
*   Representa una linea de la factura dentro de un comprobante digital
*
DEFINE CLASS CFDConcepto AS Custom
 *
 *-- Atributos requeridos
 Cantidad = 0.00
 Descripcion = ""
 valorUnitario = 0.00
 Importe = 0.00
 Unidad = ""
 
 
 *-- Atributos opcionales
 noIdentificacion = ""
 informacionAduanera = NULL
 cuentaPredial = NULL
 Complemento = NULL   && VES Ene 12, 2012

 *-- Constructor de la clase
 PROCEDURE Init
  THIS.informacionAduanera = CREATEOBJECT("CFDInformacionAduanera")
  THIS.cuentaPredial = CREATEOBJECT("CFDCuentaPredial")
  THIS.Complemento = NULL  && VES Ene 12, 2012
 ENDPROC 
 *
ENDDEFINE



*-- CFDInformacionAduanera (Clase)
*   Representa la informacion de aduana de un concepto especifico
*
DEFINE CLASS CFDInformacionAduanera AS Custom
 *
 *-- Atributos obligatorios
 Numero = ""
 Fecha = {}
 
 *-- Atributos opcionales
 Aduana = ""
 *
ENDDEFINE



*-- CFDCuentaPredial (Clase)
*   Representa la informacion de la cuenta predial asociada a un concepto (aplica
*   principalmente a inmuebles).
*
DEFINE CLASS CFDCuentaPredial AS Custom
 *
 *-- Atributos obligatorios 
 Numero = ""
 
 *-- Atributos opcionales 
 *
ENDDEFINE



*-- CFDImpuestos (Clase)
*   Representa los datos de impuestos del comprobante
*
DEFINE CLASS CFDImpuestos AS Custom
 *
 *-- Atributos obligatorios 
  
 
 *-- Atributos opcionales 
 totalImpuestosRetenidos = 0.00  && Solo lectura
 totalImpuestosTrasladados = 0.00  && Solo lectura
 Retenciones = NULL
 Traslados = NULL
 
 
 *-- Getters / Setters
 PROCEDURE totalImpuestosRetenidos_Access
  *
  LOCAL i, nTotal
  nTotal = 0.00
  FOR i = 1 TO THIS.Retenciones.Count
   nTotal = nTotal + THIS.Retenciones.Items(i).Importe
  ENDFOR
  
  RETURN nTotal
  *
 ENDPROC
 PROCEDURE totalImpuestosRetenidos_Assign(vNewVal)
 ENDPROC
 
 PROCEDURE totalImpuestosTrasladados_Access
  *
  LOCAL i, nTotal
  nTotal = 0.00
  FOR i = 1 TO THIS.Traslados.Count
   nTotal = nTotal + THIS.Traslados.Items(i).Importe
  ENDFOR
  
  RETURN nTotal
  *
 ENDPROC
 PROCEDURE totalImpuestosTrasladados_Assign(vNewVal)
 ENDPROC

 
 *-- Constructor de la clase
 PROCEDURE Init
  THIS.Retenciones = CREATEOBJECT("CFDRetenciones")
  THIS.Traslados = CREATEOBJECT("CFDTraslados")
 ENDPROC
 *
ENDDEFINE



*-- CFDRetenciones (Clase)
*   Representa la lista de retenciones de impuestos del comprobante
*
DEFINE CLASS CFDRetenciones AS CFDCollection
 *
 *-- Add (Metodo)
 *   Incluye una nueva retencion en la lista
 *
 PROCEDURE Add(pcImpuesto, pnImporte)
  *
  LOCAL oRetencion
  oRetencion = CREATEOBJECT("CFDRetencion")
  WITH oRetencion
   .Impuesto = pcImpuesto
   .Importe = pnImporte
  ENDWITH
  
  RETURN DODEFAULT(oRetencion)
  *
 ENDPROC
 *
ENDDEFINE



*-- CFDTraslados (Clase)
*   Representa la lista de impuestos trasladados del comprobante
*
DEFINE CLASS CFDTraslados AS CFDCollection
 *
 *-- Add (Metodo)
 *   Incluye un nuevo traslado en la lista
 *
 PROCEDURE Add(pcImpuesto, pnTasa, pnImporte)
  *
  LOCAL oTraslado
  oTraslado = CREATEOBJECT("CFDTraslado")
  WITH oTraslado
   .Impuesto = pcImpuesto
   .Tasa = pnTasa
   .Importe = pnImporte
  ENDWITH
  
  RETURN DODEFAULT(oTraslado)
  *
 ENDPROC
 *
ENDDEFINE



*-- CFDRetencion (Clase)
*   Representa los datos de una retencion de impuestos
*
DEFINE CLASS CFDRetencion AS Custom
 *
 *-- Atributos obligatorios 
 Impuesto = ""
 Importe = 0.00
 
 *-- Atributos opcionales 
 *
ENDDEFINE



*-- CFDTraslado (Clase)
*   Representa los datos de un impuesto trasladado
*
DEFINE CLASS CFDTraslado AS Custom
 *
 *-- Atributos obligatorios 
 Impuesto = ""
 Tasa = 0.00
 Importe = 0.00
 
 *-- Atributos opcionales 
 *
ENDDEFINE



*-- CFDAddenda (Clase)
*   Representa una lista de pares (nombre, valor) que representa datos
*   adicionales a ser incluidos en la seccion Addenda del comprobante
*
*   VES Nov 12, 2011
*   A partir de la version 3.4, esta clase se queda obsoleta y ya no 
*   tiene efecto cobre el CFD. En su lugar, debe usarse la interfaz
*   ICFDAddenda y las propiedades Addenda y Complemento de la clase
*   CFDComprobante.
*
DEFINE CLASS CFDAddenda AS CFDCollection
 *
 *-- Add (Metodo)
 *   Incluye un nuevo elemento en la lista de addendas (se mantiene por
 *   compatibilidad con versiones anteriores)
 *
 PROCEDURE Add(pcNombre, pcValor)
  *
  LOCAL oItem
  oItem = CREATEOBJECT("Custom")
  oItem.addProperty("Nombre",pcNombre)
  oItem.addProperty("Valor",pcValor)
  
  DODEFAULT(oItem)
  *
 ENDPROC
 *
ENDDEFINE



*-- CFDCollection (Clase)
*   Representa una coleccion de elementos
*
DEFINE CLASS CFDCollection AS Custom


	HIDDEN ncount
	ncount = 0
	HIDDEN leoc
	leoc = .T.
	HIDDEN lboc
	lboc = .T.
	*-- Indica la posición actual dentro de la colección
	listindex = 0
	*-- Nombre de la clase a instanciar al llamar al método New.
	newitemclass = ""
	Name = "cbasiccollection"

	*-- Nro. de elementos en la colección
	count = .F.

	*-- Indica si se ha llegado al final de la colección
	eoc = .F.

	*-- Indica si se ha llegado al tope de la colección.
	boc = .F.

	*-- Devuelve el valor actual en la colección
	current = .F.

	*-- Lista de elementos en la colección
	DIMENSION items[1,1]
	PROTECTED aitems[1,1]


	PROCEDURE items_access
		LPARAMETERS m.nIndex1, m.nIndex2

		if type("m.nIndex1")="C"
		 m.nIndex1=this.FindItem(m.nIndex1)
		endif

		RETURN THIS.aItems[m.nIndex1]
	ENDPROC


	PROCEDURE items_assign
		LPARAMETERS vNewVal, m.nIndex1, m.nIndex2

		if type("m.nIndex1")="C"
		 m.nIndex1=this.FindItem(m.nIndex1)
		endif

		if between(m.nIndex1,1,THIS.Count)
		 THIS.aItems[m.nIndex1]=m.vNewVal
		endif
	ENDPROC


	PROCEDURE count_access

		RETURN THIS.nCount
	ENDPROC


	PROCEDURE count_assign
		LPARAMETERS vNewVal
	ENDPROC


	*-- Añade un elemento a la colección
	PROCEDURE add
		lparameters puValue

		if parameters()=0
		 return .F.
		endif

		this.nCount=this.nCount + 1
		dimen this.aItems[this.nCount]
		this.aItems[this.nCount]=puValue
		this.lEOC=.F.
		this.lBOC=.F.

		if this.ListIndex=0
		 this.ListIndex=1
		endif

		return puValue
	ENDPROC


	*-- Elimina un elemento de la colección
	PROCEDURE remove
		lparameters puValue

		if parameters()=0 
		 return .F.
		endif

		local nIndex
		nIndex=this.FindItem(puValue)
		if nIndex > 0
		 return this.RemoveItem(nIndex)
		else
		 return .F.
		endif
	ENDPROC


	*-- Limpia la colección
	PROCEDURE clear
		local i,uItem
		for i=1 to this.nCount
		 uItem=this.aItems[i]
		 if type("uItem")="O"
		  release uItem
		  this.aItems[i]=NULL
		 endif
		endfor

		dimen this.aItems[1]
		this.aItems[1]=NULL
		this.nCount=0
		this.lBOC=.T.
		this.lEOC=.T.
		this.ListIndex=0
	ENDPROC


	*-- Determina si un elemento dado forma parte de la colección.
	PROCEDURE isitem
		lparameters puValue,pcSearchProp

		if parameters()=0
		 return .F.
		endif

		return (this.FindItem(puValue,pcSearchProp)<>0)
	ENDPROC


	*-- Devuelve la posición en la colección donde se encuentra el elemento indicado
	PROCEDURE finditem
		lparameters puValue,pcSearchProp


		if parameters()=0 or this.nCount=0
		 return 0
		endif

		if vartype(pcSearchProp)<>"C"
		 pcSearchProp=""
		endif

		local i,uItem,cType1,nPos
		nPos=0
		cType1=type("puValue")
		for i=1 to this.nCount
		 uItem=this.aItems[i]
		 if type("uItem")="O" 
		  if (cType1="O" and type("uItem.Name")="C" and type("puVale.Name")="C" and upper(uItem.Name)==upper(puValue.Name)) or ;
		     (cType1="C" and type("uItem.Name")="C" and upper(uItem.Name)==upper(puValue)) or ;
		     (cType1<>"O" and not empty(pcSearchProp) and type("uItem."+pcSearchProp)=cType1 and eval("uItem."+pcSearchProp)==puValue)
		   nPos=i
		   exit
		  endif 
		 else
		  if type("uItem")=cType1 and ((cType1<>"C" and uItem=puValue) or (cType1="C" and uItem==puValue))
		   nPos=i
		   exit
		  endif
		 endif
		endfor

		return nPos
	ENDPROC


	*-- Elimina un item por su posición
	PROCEDURE removeitem
		LPARAMETERS nIndex

		if parameters()=0 or not between(nIndex,1,this.nCount)
		 return .f.
		endif

		local uItem
		uItem=this.aItems[nIndex]

		if type("uItem")="O"
		 release uItem
		 this.aItems[nIndex]=NULL
		endif

		adel(this.aItems,nIndex)

		this.nCount=this.nCount - 1
		if this.nCount > 0 
		 dimen this.aItems[this.nCount]
		 if this.nCount > this.ListIndex
		  this.ListIndex=this.nCount
		 endif
		else
		 this.aItems[1]=NULL
		 this.lEOC=.T.
		 this.lBOC=.T.
		 this.ListIndex=0
		endif
	ENDPROC


	PROCEDURE eoc_access

		RETURN THIS.lEOC
	ENDPROC


	PROCEDURE eoc_assign
		LPARAMETERS vNewVal
	ENDPROC


	PROCEDURE boc_access

		RETURN THIS.lBOC
	ENDPROC


	PROCEDURE boc_assign
		LPARAMETERS vNewVal
	ENDPROC


	*-- Ir al primer elemento en la colección
	PROCEDURE first
		if this.nCount=0
		 return
		endif

		this.ListIndex=1
		this.lBOC=.F.
		this.lEOC=.F.
	ENDPROC


	*-- Ir al siguiente elemento en la colección
	PROCEDURE next
		if this.nCount=0
		 return
		endif

		if this.ListIndex < this.nCount
		 this.ListIndex=this.ListIndex + 1
		 this.lBOC=.F.
		 this.lEOC=.F.
		else
		 this.lBOC=(this.nCount=1)
		 this.lEOC=.T.
		endif
	ENDPROC


	*-- Ir al último elemento en la colección
	PROCEDURE last
		if this.nCount=0
		 return
		endif

		this.ListIndex=this.nCount
		this.lBOC=.F.
		this.lEOC=.F.
	ENDPROC


	*-- Ir al elemento anterior en la colección
	PROCEDURE previous
		if this.nCount=0
		 return
		endif

		if this.ListIndex > 1
		 this.ListIndex=this.ListIndex - 1
		 this.lBOC=.F.
		 this.lEOC=.F.
		else
		 this.lBOC=.T.
		 this.lEOC=(this.nCount=1) 
		endif
	ENDPROC


	PROCEDURE listindex_assign
		LPARAMETERS vNewVal

		if type("m.vNewVal")="N" and between(m.vNewVal,1,this.nCount)
		 THIS.ListIndex = m.vNewVal
		 THIS.lEOC=.F.
		 this.lBOC=.F.
		endif
	ENDPROC


	PROCEDURE current_access
		if this.ListIndex=0
		 return NULL
		else
		 RETURN THIS.aItems[this.ListIndex]
		endif
	ENDPROC


	PROCEDURE current_assign
		LPARAMETERS vNewVal

		if this.ListIndex > 0
		 THIS.aItems[this.ListIndex]=m.vNewVal
		endif
	ENDPROC


	*-- Crea una instancia de la clase indicada en NewItemClass y devuelve una referencia al mismo.
	PROCEDURE new
		if empty(this.NewItemClass)
		 return NULL
		endif

		local oItem
		oItem=Kernel.CC.New(this.NewItemClass)

		return oItem
	ENDPROC


	*-- Permite añadir un item a la colección, solo si el mismo no existe.
	PROCEDURE addifnew
		lparameters puValue

		if parameters()=0
		 return .F.
		endif

		if not this.IsItem(puValue)
		 this.Add(puValue)
		endif

		return puvalue
	ENDPROC


ENDDEFINE



*-- CFDTraslado (Clase)
*   Representa los datos de un certificado
*
DEFINE CLASS CFDCertificado AS Custom
 *
 Archivo = ""			&& Nombre y ubicacion del archivo .CER
 Valido = .F.			&& Indica si el certificado es valido o no
 Vigente = .F.			&& Indica si el certificado esta vigente o no
 Certificado = ""		&& Contenido del certificado
 Serial = ""			&& Serial del certificado
 VigenteDesde = {//::}	&& Inicio de la vigencia
 vigenteHasta = {//::}	&& Fin de la vigencia
 *
ENDDEFINE


*-- ICFDAddenda (Clase)
*   Interfaz para addendas. Esta clase no debe instanciarse directamente sino servir
*   de base a otras clases mas especializadas, las cuales deben implementar el metodo
*   ToString()
*
DEFINE CLASS ICFDAddenda AS Custom
 *
 nodeName = "Addenda"   && Nombre del nodo: Addenda o Complemento 
 schemaLocation = ""    && Ubicacion del schema
 NSTag = ""             && Tag del NameSpace 
 NSUrl = ""             && Url del XSLT asociado al NameSpace
   
 PROCEDURE ToString()
 ENDPROC
 *
ENDDEFINE






********************************************************
**
**  X M L P A R S E R
**
**  Clase para creacion y lectura de archivos XML 
**  mediante una interfaz OOP.
**
**  Autor: Victor Espina
**
*********************************************************

DEFINE CLASS XmlParser AS custom


	*-- Cadena utilizada para indentar un archivo XML al generarlo (TAB por omisión)
	indentstring = ((CHR(9)))
	Name = "xmlparser"

	*-- Nombre del archivo XML en uso
	filename = .F.

	*-- Apuntador al objeto que contiene la estructura del archivo XML actual
	xml = .F.

    *-- VES Nov 11, 2011: nueva propiedad para controlar si se genera o no
    *   los alias de nodo
    createNodeLinks = .T.


	*-- Prepara un nuevo archivo XML
	PROCEDURE new
		THIS.XML=CREATEOBJECT("XMLNodeClass")
		THIS.XML.Name="ROOT"
		THIS.XML.createNodeLinks = THIS.createNodeLinks  && Nov 11, 2011
		THIS.XML.indentString = THIS.indentString && Nov 11, 2011
		THIS.FileName=""
		  
		RETURN THIS.XML
	ENDPROC


	*-- Abre un archivo XML y lo carga en memoria en la propiedad XML.
	PROCEDURE open
		LPARAMETERS pcFileName


		  *-- Se carga el XML en memoria
		  *
		  LOCAL nPos,cData,nSize
		  LOCAL ARRAY XMLData[1]
		  cData=FILETOSTR(pcFileName)
		  IF ATC("<?XML ",cData)<>0
		   nPos=ATC("?>",cData)
		   cData=SUBS(cData,nPos + 2)
		  ENDIF
		  nSize=ALINES(XMLData,cData)  
		  THIS.FileName=pcFileName


		  *-- Se lee el XML y se carga en forma de objetos
		  *
		  LOCAL i,j,k,cLin,cText,oNode,oParent,nOpenTag,nCloseTag1,nCloseTag2,nCloseTag3
		  LOCAL cProps,cData,lPropMode,lDataMode,lClosedTag,lEndedTag,cName
		  oParent=CREATEOBJECT("XMLNodeClass")
		  oParent.Name="ROOT"
		  
		  FOR i=1 TO nSize
		   *
		   cLin=XMLData[i]
		   nOpenTag=AT("<",cLin)
		   nCloseTag1=AT("</",cLin)
		   nCloseTag2=AT(">",cLin)
		   nCloseTag3=AT("/>",cLin)
		  
		 
		   DO CASE
		      CASE nOpenTag<>0 and (nCloseTag1=0 or nCloseTag1 > nOpenTag)         && Nuevo nodo
		           *-- Se instancia el Nodo
		           oNode=CREATEOBJECT("XMLNodeClass")
		           oNode.cProps=""
		           oNode.cData=""
		           oNode.lPropMode=False
		           oNode.lDataMode=False
		           oNode.createNodeLinks = THIS.createNodeLinks
		           
		      
		           *-- Se aisla de la cadena la parte que corresponde al nombre del nodo
		           *   y una posible lista de propiedades
		           cText=SUBS(cLin,nOpenTag + 1)
		           j=AT("/>",cText)
		           j=IIF(j=0,AT(">",cText),j)
		           lClosedTag=(j<>0)
		           IF lClosedTag
		            cText=LEFT(cText,j - 1)
		           ENDIF
		           
		           *-- Se obtiene el nombre del nodo y se aisla la 
		           *   posible lista de parámetros
		           cName=""
		           j=AT(" ",cText)
		           IF j=0
		            cName=ALLT(cText)
		           ELSE
		            cName=ALLT(LEFT(cText,j - 1))
		            oNode.cProps=SUBS(cText,j + 1)
		            oNode.lPropMode=(NOT lClosedTag)
		           ENDIF
		           
		           IF AT(":",cName) = 0   && Nov 11, 2011
		            oNode.Name=cName
		            oNode.nameSpace = ""
		           ELSE
		            oNode.Name = SUBS(cName,AT(":",cName) + 1)
		            oNode.nameSpace = LEFT(cName,AT(":",cName) - 1)
		           ENDIF 
		           
		          
		           *-- Si hay un nodo padre activo, se añade el nodo a dicho padre
		           IF NOT ISNULL(oParent)
		            oParent.AddNode(oNode)
		           ENDIF
		            
		           
		           *-- Si hay una lista de propiedades y el nodo estaba cerrado
		           *   se carga la lista de propiedades del nodo
		           IF (NOT EMPTY(oNode.cProps)) AND (NOT oNode.lPropMode)
		            THIS.iSplitProps(oNode.cProps,oNode)
		           ENDIF
		           
		           
		           *-- Se aisla la posible DATA del nodo (si el nodo está cerrado)
		           IF lClosedTag AND nCloseTag3=0
		            *
		            cText=SUBS(cLin,nCloseTag2 + 1)
		            
		            *-- Si la linea contiene el fin del nodo, se aisla la DATA y se cierra el nodo
		            *   de lo contrario, se activa la modalidad lDataMode
		            IF nCloseTag1<>0AND OCCURS("</",cText)=1 AND ATC("</"+oNode.Name+">",cText)<>0
		             cText=LEFT(cText,AT("</",cText) - 1)
		             oNode.Data=cText
		             oNode.lDataMode=False
		            ELSE
		             oNode.cData=cText
		             oNode.lDataMode=True
		            ENDIF
		            *
		           ENDIF
		           
		           *-- Si el nodo fué completamente procesado, se retorna el control al nodo
		           *   padre; de lo contrario se asume el nodo actual como nuevo nodo padre
		           IF oNode.lPropMode OR oNode.lDataMode
		            oParent=oNode
		           ELSE
		            IF NOT ISNULL(oNode.ParentNode)
		             oParent=oNode.ParentNode
		            ENDIF 
		           ENDIF
		          
		           
		      CASE ISNULL(oParent)
		           *-- No se requiere acción     
		           
		      CASE oParent.lPropMode AND nCloseTag1=0 AND nCloseTag2=0     && Linea de propiedades sin fin ni cierre de nodo  ( Prop=Valor )
		           oParent.cProps=oParent.cProps + " " + cLin
		           
		      CASE oParent.lPropMode AND nCloseTag1=0 AND nCloseTag2<>0    && Linea de propiedades con cierre de nodo  ( Prop=Valor> )
		           oParent.cProps=oParent.cProps + " " + LEFT(cLin,nCloseTag2 - 1)
		           oParent.lPropMode=False
		           THIS.iSplitProps(oParent.cProps,oParent)

		           cText=SUBS(cLin,nCloseTag2+1)
		           oNode.cData=cText
		           oNode.lDataMode=True
		                        
		      CASE oParent.lPropMode AND nCloseTag1<>0 AND nCloseTag2<>0   && Linea de propiedades con fin de nodo   ( Prop=Valor> </nodo>)
		           oParent.cProps=oParent.cProps + " " + LEFT(cLin,nCloseTag2 - 1)
		           oParent.lPropMode=False
		           THIS.iSplitProps(oParent.cProps,oParent)
		           
		           cText=SUBS(cLin,nCloseTag2+1)
		           cText=SUBS(cText,AT("</",cText) - 1)
		           oNode.cData=cText

		           *-- Se retorna el control al nodo padre
		           IF NOT ISNULL(oParent.ParentNode)
		            oParent=oParent.ParentNode
		           ENDIF 

		           
		      CASE oParent.lDataMode AND nCloseTag1=0    && Linea de datos sin fin de nodo ( data )
		           oParent.cData=oParent.cData + IIF(EMPTY(oParent.cData),"",CRLF) + cLin
		           
		      CASE oParent.lDataMode AND nCloseTag1<>0   && Linea de datos con fin de modo ( data </nodo> )
		           oParent.cData=oParent.cData + IIF(EMPTY(oParent.cData),"",CRLF) + LEFT(cLin,nCloseTag1 - 1)
		           oParent.Data=oParent.cData     
		           oParent.lDataMode=False

		           *-- Se retorna el control al nodo padre
		           IF NOT ISNULL(oParent.ParentNode)
		            oParent=oParent.ParentNode
		           ENDIF 
		           
		           
		      OTHERWISE
		           *-- Se obvia la linea                
		   ENDCASE
		   *
		  ENDFOR
		  
		  THIS.XML=oParent
		  
		  RETURN THIS.XML
	ENDPROC


	*-- Genera un archivo XML en base a los datos cargados en memoria
	PROCEDURE save
		LPARAMETERS pcFileName

		  IF VARTYPE(pcFileName)="C"
		   THIS.FileName=pcFileName
		  ENDIF
		  IF EMPTY(THIS.FileName)
		   RETURN False
		  ENDIF
		  
		  SET TEXTMERGE TO (THIS.FileName) NOSHOW
		  SET TEXTMERGE ON
		  \\<?xml version="1.0" encoding="UTF-8"?>
		  LOCAL i
		  FOR i=1 TO THIS.XML.NodeCount
		   THIS.iSaveNode(THIS.XML.Nodes(i))
		  ENDFOR 
		  SET TEXTMERGE OFF
		  SET TEXTMERGE TO
	ENDPROC


	*-- Genera un string con el XML
	PROCEDURE ToString()
		LPARAMETERS pnMargin
          LOCAL cXML,cCRLF,i
          cCRLF = CHR(13)+CHR(10)
          cXML = ""
          FOR i = 1 TO THIS.XML.NodeCount
           IF i > 1
            cXML = cXML + cCRLF
           ENDIF
           cXML = cXML + THIS.XML.Nodes[i].ToString(pnMargin)
          ENDFOR
		  RETURN cXML
	ENDPROC


	*-- Salva un nodo del XML
	HIDDEN PROCEDURE isavenode
		LPARAMETERS poNode,pnMargin

		  LOCAL nDeep,cAlign,i,uValue
		  nDeep=OCCURS("\",poNode.FullPath) 
		  cAlign=REPL(THIS.IndentString,nDeep)
		  IF CFDEVL(pnMargin,0) > 0
		   cAlign = REPL(THIS.indentString,pnMargin) + cAlign
		  ENDIF
		  
		  \<<cAlign>><<"<"+poNode.nodeName>>
		  
		  FOR i=1 TO poNode.PropCount
		   IF i=1
		    \\<<space(1)>>
		   ENDIF
		   uValue=poNode.Props(i).Value
		   DO CASE
		      CASE VARTYPE(uValue)="C"
		           uValue=["]+uValue+["]
		      CASE VARTYPE(uValue)="D"
		           uValue=[{]+DTOC(uValue)+[}]
		      CASE VARTYPE(uValue)="T"
		           uValue=[{]+TTOC(uValue)+[}]
		      CASE VARTYPE(uValue)="N" AND INT(uValue)<>uValue
		           uValue=ALLT(STR(uValue,30,6))
		      CASE VARTYPE(uValue)="N" AND INT(uValue)=uValue
		           uValue=ALLT(STR(uValue,30))
		      CASE VARTYPE(uValue)="L"
		           uValue=IIF(uValue,".T.",".F.")
		      OTHERWISE
		            uValue=TRANS(uValue,"")
		   ENDCASE
		   \\<<poNode.Props(i).Id>>=<<uValue>>
		   IF i < poNode.PropCount
		    \\<<space(1)>>
		    *\<<cAlign+SPACE(5)>>
		   ENDIF
		  ENDFOR

		  IF poNode.PropCount=0 AND poNode.NodeCount=0
		   *
		   IF ISNULL(poNode.Data)
		    \\<<"/>">>
		   ELSE
		    \\<<">">><<poNode.Data>><<+"</"+poNode.nodeName+">">>
		   ENDIF
		   *
		  ELSE          
		   *
		   IF poNode.NodeCount=0
		    IF ISNULL(poNode.Data)
		     \\/>
		    ELSE
		     \\><<poNode.Data>><<"</"+poNode.Id+">">>
		    ENDIF    
		   ELSE
		    IF ISNULL(poNode.Data)
		     \\>
		    ELSE
		     \\><<poNode.Data>>
		    ENDIF    
		    FOR i=1 TO poNode.NodeCount
		     THIS.iSaveNode(poNode.Nodes(i), pnMargin)
		    ENDFOR 
		    \<<cAlign>><<"</"+poNode.nodeNAme+">">>
		   ENDIF 
		   *
		  ENDIF         
	ENDPROC


	*-- Lee una linea de propiedades dada y la convierte en propiedades de un objeto XMLNodeClass dado.
	HIDDEN PROCEDURE isplitprops
		LPARAMETERS pcParamLine,poNode

		 
		  *-- Se recorre la cadena pcParamLine para cambiar los caracteres "=" que no esten
		  *   encerrados en algun "bloque" (ej: (..=..), '..=..', "..=..") por el car. "|". Esto 
		  *   permitirá identificar apropiadamente los pares PROP=VALUE que esten contenidos
		  *   en la cadena pcTagOptions.
		  *   
		  local i,nCount,nBlockDeepth,cChar,lQuoted,lDoubleQuoted
		  nCount=len(pcParamLine)
		  nBlockDeepth=0
		  lQuoted=.F.
		  lDoubleQuoted=.F.
		  for i=1 to nCount
		   cChar=subs(pcParamLine,i,1)
		   do case
		      case inlist(cChar,"(","{","[")
		           nBlockDeepth=nBlockDeepth + 1

		      case inlist(cChar,")","}","]") and nBlockDeepth > 0
		           nBlockDeepth=nBlockDeepth - 1
		          
		      case cChar $ ["]
		           lDoubleQuoted=(NOT lDoubleQuoted)

		      case cChar $ [']
		           lQuoted=(NOT lQuoted)
		          
		      case cChar="=" and nBlockDeepth <= 0 and (not lQuoted) and not (lDoubleQuoted)
		           pcParamLine=stuff(pcParamLine,i,1,"|")
		          
		      case cChar="=" and nBlockDeepth > 0 or lQuoted or lDoubleQuoted
		           * Nothing
		   endcase         
		  endfor


		  *-- Se procesan todas las apariciones del caracter "|"
		  *
		  local cProp,cValue,nPos,cData,j,oProp
		  cData=pcParamLine
		  nCount=occurs("|",cData)
		  for i=1 to nCount
		   *
		   nPos=at("|",cData)
		   cProp=allt(left(cData,nPos - 1))
		   cValue=subs(cData,nPos + 1)
		  
		   if i < nCount
		    nPos=at("|",cValue)
		    j=nPos - 1
		    do while j>1 and not empty(subs(cValue,j,1))
		     j=j - 1
		    enddo
		    if j>1
		     cData=subs(cValue,j+1)
		     cValue=allt(left(cValue,j))
		    endif
		   endif 

		   poNode.AddProp(cProp,EVAL(cValue))  
		   *
		  endfor
	ENDPROC



ENDDEFINE


DEFINE CLASS XmlNodeClass AS custom


	*-- Data asociada al nodo (texto entre  los tags <nodo> y </nodo>)
	data = .NULL.
	*-- Apuntador al nodo padre
	parentnode = .NULL.
	*-- Nro. de propiedades en el nodo
	propcount = 0
	*-- Nro. de subnodos en el nodo
	nodecount = 0
	HIDDEN npropcount
	npropcount = 0
	HIDDEN nnodecount
	nnodecount = 0
	cprops = ""
	cdata = ""
	*-- Ruta completa de acceso al nodo actual.
	fullpath = ""
	Name = "xmlnodeclass"
	lpropmode = .F.
	ldatamode = .F.
	NameSpace = ""  && Nov 11, 2011
	NodeName = "" && Nov 11, 2011
	createNodeLinks = .T.  && Nov 11,2011
	indentString = "" && Nov 11, 2011
	

	*-- Colección de propiedades del nodo
	DIMENSION props[1,1]

	*-- Colección de subnodos del nodo
	DIMENSION nodes[1,1]


	HIDDEN PROCEDURE propcount_access
		RETURN THIS.npropcount
	ENDPROC


	HIDDEN PROCEDURE propcount_assign
		LPARAMETERS vNewVal
	ENDPROC


	HIDDEN PROCEDURE nodecount_access
		RETURN THIS.nnodecount
	ENDPROC


	HIDDEN PROCEDURE nodecount_assign
		LPARAMETERS vNewVal
	ENDPROC


	HIDDEN PROCEDURE props_access
		LPARAMETERS puIndex

		  IF THIS.PropCount=0
		   RETURN NULL
		  ENDIF
		  IF VARTYPE(puIndex)="N"
		   RETURN THIS.Props[puIndex]
		  ELSE
		   RETURN THIS.Props[THIS.FindProp(puIndex)]
		  ENDIF
	ENDPROC


	HIDDEN PROCEDURE nodes_access
		LPARAMETERS puIndex

		  IF THIS.NodeCount=0
		   RETURN NULL
		  ENDIF
		  
		  LOCAL nIndex,i
		  IF TYPE("puIndex")="N"
		   nIndex=puIndex
		  ELSE
		   *
		   IF atc("\",puIndex)=0
		    nIndex=THIS.FindNode(puIndex)
		   ELSE
		    nIndex=THIS.GetNode(puIndex)
		   ENDIF
		   *
		  ENDIF
		  

		  RETURN THIS.Nodes[nIndex]
	ENDPROC

	HIDDEN PROCEDURE nodeName_access
		RETURN IIF(EMPTY(THIS.nameSpace),"",THIS.nameSpace + ":") + THIS.Name
	ENDPROC


	HIDDEN PROCEDURE nodeName_assign
		LPARAMETERS vNewVal
	ENDPROC


	*-- Devuelve la posición dentro de la colección Props[...] para una propiedad dada.
	PROCEDURE findprop
		LPARAMETERS pcPropName

		  LOCAL i,nIndex
		  nIndex=0
		  FOR i=1 TO THIS.PropCount
		   IF UPPER(ALLT(THIS.Props[i].Id))==UPPER(ALLT(pcPropName))
		    nIndex=i
		    EXIT
		   ENDIF
		  ENDFOR
		  
		  RETURN nIndex
	ENDPROC


	*-- Determina si una propiedad dada existe en el nodo o no.
	PROCEDURE isprop
		LPARAMETERS pcPropName

		RETURN (THIS.FindProp(pcPropName)<>0)
	ENDPROC


	*-- Añade una nueva propiedad al nodo.
	PROCEDURE addprop
		LPARAMETERS pcName,puValue,plOptional

          IF EMPTY(puValue) AND plOptional
           RETURN NULL
          ENDIF
           
		  LOCAL oProp,nCount,i
		  LOCAL ARRAY aProps[1]
		  nCount=ALINES(aProps,STRT(pcName,",",CRLF))
		  
		  FOR i=1 TO nCount
		   oProp=CREATEOBJECT("XMLPropClass")
		   oProp.ID=aProps[i]
		   oProp.Value=puValue
		   THIS.nPropCount=THIS.nPropCount + 1
		   DIMENSION THIS.Props[THIS.nPropCount]
		   THIS.Props[THIS.nPropCount]=oProp
		  ENDFOR 
		  
		  RETURN oProp
	ENDPROC


	*-- Elimina una propiedad del nodo
	PROCEDURE removeprop
		LPARAMETERS puIndex

		  IF VARTYPE(puIndex)="C"
		   puIndex=THIS.FindProp(puIndex)
		  ENDIF
		  IF BETWEEN(puIndex,1,THIS.nPropCount)
		   THIS.Props[puIndex]=NULL
		   ADEL(THIS.Props,puIndex)
		   THIS.nPropCount=THIS.nPropCount - 1
		  ENDIF
	ENDPROC
	
	
	*-- Devuelve el contenido de una propiedad, si la misma existe
	PROCEDURE getProp
		LPARAMETERS pcPropName, puDefaultValue

        IF PCOUNT() = 1
         puDefaultValue = ""
        ENDIF
        
        LOCAL nIndex
        nIndex = THIS.FindProp(pcPropName) 
        IF nIndex > 0
         RETURN THIS.Props[nIndex].Value
        ELSE
         RETURN puDefaultValue
        ENDIF
	ENDPROC
	


	*-- Permite actualizar el valor de las propiedades del nodo en base a las propiedades del mismo nombre de otro objeto dado.
	PROCEDURE copypropsfrom
		LPARAMETERS poData

		  LOCAL i,cProp
		  FOR i=1 TO THIS.PropCount
		   cProp=THIS.Props(i).Id
		   IF TYPE("poData."+cProp)<>"U"
		    THIS.Props(cProp).Value=EVAL("poData."+cProp)
		   ENDIF
		  ENDFOR
		  
	ENDPROC


	*-- Devuelve una referencia al objeto XMLNodeClass que representa a un nodo dado.
	PROCEDURE getnode
		LPARAMETERS pcNodeFullPath

		  LOCAL ARRAY aNodes[1]
		  LOCAL i,nCount,nIndex
		  nCount=ALINES(aNodes,STRT(pcNodeFullPath,"\",CRLF))
		  oNode=THIS
		  FOR i=1 TO nCount
		   IF UPPER(aNodes[i])==UPPER(THIS.Name)
		    LOOP
		   ENDIF
		   nIndex=oNode.FindNode(aNodes[i])
		   IF nIndex=0
		    EXIT
		   ENDIF
		   oNode=oNode.Nodes(nIndex)
		  ENDFOR
		  
		  RETURN oNode
	ENDPROC


	*-- Devuelve la posición dentro de la colección Nodes[...]  para un nodo indicado.
	PROCEDURE findnode
		LPARAMETERS pcNodeName

		  LOCAL i,nIndex
		  nIndex=0
		  FOR i=1 TO THIS.NodeCount
		   IF UPPER(ALLT(THIS.Nodes[i].Name))==UPPER(ALLT(pcNodeName))
		    nIndex=i
		    EXIT
		   ENDIF
		  ENDFOR
		  
		  RETURN nIndex
	ENDPROC


	*-- Determina si existe un subnodo en el nodo actual con el nombre indicado.
	PROCEDURE isnode
		LPARAMETERS pcPropName

		RETURN (THIS.FindNode(pcPropName)<>0)
	ENDPROC


	*-- Añade un nuevo subnodo al nodo actual
	PROCEDURE addnode
		LPARAMETERS poNode,pcData

		  DO CASE
		     CASE PCOUNT()=0
		          poNode=CREATE("XMLNodeClass")
		          
		     CASE VARTYPE(poNode)="C"
		          LOCAL cName,cNameSpace
		          cName=poNode
		          cNameSpace = ""
		          IF AT(":",cName)<>0
		           cNameSpace = LEFT(cName,AT(":",cName) - 1)
		           cName = SUBS(cName,AT(":",cNAme) + 1)
		          ENDIF
		          poNode=CREATE("XMLNodeClass")
		          poNode.Name = cName
		          poNode.NameSpace = cNameSpace
		  ENDCASE
		  poNode.createNodeLinks = THIS.createNodeLinks
		  poNode.indentString = THIS.indentString
		  
		  *-- Si el nodo no tiene namespace pero el padre si, se asume el 
		  *   namespace del padre (VES Nov 11, 2011)
		  IF EMPTY(poNode.nameSpace)
		   poNode.nameSpace = THIS.nameSpace
		  ENDIF
		  
		  THIS.nNodeCount=THIS.nNodeCount + 1
		  DIMENSION THIS.Nodes[THIS.nNodeCount]
		  THIS.Nodes[THIS.nNodeCount]=poNode
		  poNode.ParentNode=THIS
		  IF PCOUNT()=2
		   poNode.Data=pcData
		  ENDIF
		  
		  IF THIS.createNodeLinks  && Nov 11, 2011
 		   LOCAL cNodeLink
		   cNodeLink="_"+poNode.Name
		   IF TYPE("THIS."+cNodeLink)="U"
		    THIS.AddProperty(cNodeLink,poNode)
		   ELSE
		    STORE poNode TO ("THIS."+cNodeLink) 
		   ENDIF
		  ENDIF
		  
		  RETURN poNode
	ENDPROC


	*-- Elimina un subnodo del nodo actual
	PROCEDURE removenode
		LPARAMETERS puIndex

		  IF VARTYPE(puIndex)="C"
		   puIndex=THIS.FindNode(puIndex)
		  ENDIF
		  
		  IF BETWEEN(puIndex,1,THIS.nNodeCount)
		   *
		   LOCAL cNodeLink
		   cNodeLink="_"+THIS.Nodes[puIndex].Name
		   STORE NULL TO ("THIS."+cNodeLink)
		   
		   THIS.Nodes[puIndex]=NULL
		   ADEL(THIS.Nodes,puIndex)
		   THIS.nNodeCount=THIS.nNodeCount - 1
		   *
		  ENDIF
	ENDPROC


	HIDDEN PROCEDURE fullpath_access
		  LOCAL cPath,oNode
		  cPath=PROPER(THIS.Name)
		  oNode=THIS
		  DO WHILE (NOT ISNULL(oNode.ParentNode)) 
		   IF oNode.ParentNode.Name<>"ROOT"
		    cPath=PROPER(oNode.ParentNode.Name) + "\" + cPath
		   ENDIF 
		   oNode=oNode.ParentNode
		  ENDDO
		  
		  RETURN cPath
	ENDPROC


	HIDDEN PROCEDURE fullpath_assign
		LPARAMETERS vNewVal
	ENDPROC



    * ToString (VES Nov 12, 2011)
    * Devuelve una representacion en string del nodo y su contenido
    *  
    PROCEDURE ToString(pnMargin)
     *
		  LOCAL nDeep,cAlign,i,uValue,cResult
		  nDeep=OCCURS("\",THIS.FullPath) 
		  cCRLF = CHR(13) + CHR(10)
		  cAlign=REPL(THIS.IndentString,nDeep)
		  IF CFDEVL(pnMargin,0) > 0
		   cAlign = REPL(THIS.indentString,pnMargin) + cAlign
		  ENDIF
		  
		  cResult = cAlign + "<" + THIS.nodeName
		  
		  FOR i=1 TO THIS.PropCount
		   IF i=1
		    cResult = cResult + SPACE(1)
		   ENDIF
		   uValue=THIS.Props(i).Value
		   DO CASE
		      CASE VARTYPE(uValue)="C"
		           uValue=["]+uValue+["]
		      CASE VARTYPE(uValue)="D"
		           uValue=[{]+DTOC(uValue)+[}]
		      CASE VARTYPE(uValue)="T"
		           uValue=[{]+TTOC(uValue)+[}]
		      CASE VARTYPE(uValue)="N" AND INT(uValue)<>uValue
		           uValue=ALLT(STR(uValue,30,6))
		      CASE VARTYPE(uValue)="N" AND INT(uValue)=uValue
		           uValue=ALLT(STR(uValue,30))
		      CASE VARTYPE(uValue)="L"
		           uValue=IIF(uValue,".T.",".F.")
		      OTHERWISE
		            uValue=TRANS(uValue,"")
		   ENDCASE
		   cResult = cResult + THIS.Props[i].Id + "=" + uValue
		   IF i < THIS.PropCount
		    cResult = cResult + SPACE(1)
		   ENDIF
		  ENDFOR

		  IF THIS.PropCount=0 AND THIS.NodeCount=0
		   *
		   IF ISNULL(THIS.Data)
		    cResult = cResult + "/>"
		   ELSE
		    cResult = cResult + ">" + THIS.Data + "</" + THIS.nodeName + ">"
		   ENDIF
		   *
		  ELSE          
		   *
		   IF THIS.NodeCount=0
		    IF ISNULL(THIS.Data)
		     cResult = cResult + "/>"
		    ELSE
		     cResult = cResult + ">" + THIS.Data + "</" + THIS.nodeName + ">"
		    ENDIF    
		   ELSE
		    IF ISNULL(THIS.Data)
		     cResult = cResult + ">"
		    ELSE
		     cResult = cResult + ">" + THIS.Data
		    ENDIF    
		    LOCAL cChildren
		    FOR i=1 TO THIS.NodeCount
		      cChildren = THIS.Nodes[i].ToString(pnMargin)
		      cResult = cResult + CRLF + cChildren
		    ENDFOR 
		    cResult = cResult + cCRLF + cAlign + "</" + THIS.nodeName + ">"
		   ENDIF 
		   *
		  ENDIF         
     
          RETURN cResult
     *
    ENDPROC
ENDDEFINE


DEFINE CLASS XmlPropClass AS custom

	*-- Valor de la propiedad
	Value = "NULL"
	Id = "xmlpropclass"

ENDDEFINE




*-----------------------------------------------------------------------------
* HEXUTILS.PRG
* Funciones varias relacionadas con el sistema hexadecimal
*
* Autor: Victor Espina
* Fecha: 10-OCT-2002
*
* Contenido:
* Dec2Hex(pnDec)		Convierte un número decimal en hexadecimal
* Hex2Dec(pcHex)		Inverso de Dec2Hex
* Str2Hex(pcStr)		Convierte una cadena en su expresión hexadecimal
* Hex2Str(pcHexStr)		Inverso de Str2Hex
*
*-----------------------------------------------------------------------------


*-- DEC2HEX
*   Convierte un nro. decimal y hexagesimal
*
PROC Dec2Hex(nDec)
 *
 local nResto,cHex,nDig
 nResto=nDec
 cHex=""
 do while nResto > 15
  nDig=mod(nResto,16)
  if nDig < 10
   cHex=str(nDig,1) + cHex
  else
   cHex=chr(55+nDig) + cHex
  endif
  nResto=int(nResto / 16)
 enddo

 nDig=nResto 
 if nDig < 10
  cHex=str(nDig,1) + cHex
 else
  cHex=chr(55+nDig) + cHex
 endif
 
 
 return cHex
 *
ENDPROC


*-- HEX2DEC
*   Convierte un nro hexagesimal en decimal
*
PROC Hex2Dec(cHex)
 *
 local nDec,nDig,i,nExp
 nDec=0
 for i=1 to len(cHex)
  nExp=len(cHex)-i
  nDig=subs(cHex,i,1)
  if nDig $ "ABCDEF"
   nDig=asc(nDig) - 55
  else
   nDig=int(val(nDig))
  endif  
  nDec=nDec + ( nDig*(16^nExp) )
 endfor
 
 return nDec
 *
ENDPROC


*-- STR2HEX
*   Convierte una cadena en su expresión hexadecimal, llevando a Hexadecimal el valor
*   ASCII de cada uno de sus caracteres.
*
PROC Str2Hex(pcStr)
 *
 local cHex,nLen,i
 cHex=""
 nLen=len(pcStr)
 for i=1 to nLen
  cHex=cHex + padl( Dec2Hex( asc(subs(pcStr,i,1)) ) ,2,"0")
 endfor
 
 return cHex
 *
ENDPROC


*-- HEX2STR
*   Inverso de Str2Hex
*
PROC Hex2Str(pcHexStr)
 *
 local nLen,cDec,i
 nLen=len(pcHexStr)
 cDec=""
 for i=1 to nLen step 2
  cDec=cDec + chr( Hex2Dec( subs(pcHexStr,i,2) ) )
 endfor
 
 return cDec
 *
ENDPROC


*-- CFDAsc2UTF8
*   Toma una cadena en formato AscII / ANSI y devuelve
*   su equivalente en formato UTF-8
*
*   Autor: V. Espina
*   Fecha: Dic 2010
*   
*   Basado en un articulo de elem_125 en everything2.com:
*   http://everything2.com/title/Converting+ASCII+to+UTF-8
*
PROCEDURE CFDAsc2UTF8(pcString)
 *
 LOCAL cBuff, c, i, h, l 
 cBuff = ""
 
 FOR i = 1 TO LEN(pcString)
  c = ASC(SUBS(pcString,i,1))
  IF c < 128
   cBuff = cBuff + CHR(c)
  ELSE
   h = BITOR(BITRSHIFT(c,6),0xC0)
   l = BITOR(BITAND(c,0x3F),0x80)
   cBuff = cBuff + CHR(h) + CHR(l)
  ENDIF 
 ENDFOR

 RETURN cBuff
 *
ENDPROC



*-- CFDUTF82Asc
*   Toma una cadena en formato AscII / ANSI y devuelve
*   su equivalente en formato UTF-8
*
*   Autor: V. Espina
*   Fecha: Dic 2010
*   
*   Basado en informacion de wikipedia:
*   http://en.wikipedia.org/wiki/UTF-8
*
PROCEDURE CFDUTF82Asc(pcString)
 *
 LOCAL cBuff, i, nAsc, c
 nAsc = 0
 cBuff = ""
 FOR i = 1 TO LEN(pcString)
  *
  c = ASC(SUBS(pcString,i,1))
  IF c < 128
   IF nAsc > 0
    cBuff = cBuff + CHR(nAsc)
    nAsc = 0
   ENDIF 
   cBuff = cBuff + CHR(c)
  ELSE
   IF BITTEST(c,6) 
    nSize = BITRSHIFT(BITAND(c,0x60),5)
    nAsc = BITLSHIFT(BITCLEAR(BITCLEAR(c,7),6),6 * (nSize - 1))
   ELSE
    nAsc = BITOR(nAsc, BITCLEAR(BITCLEAR(c,7),6))
   ENDIF 
  ENDIF 
  *
 ENDFOR
 
 RETURN cBuff
 *
ENDPROC



* -----------------------------------------------------------------------------------
* IRCSA Software
* Arturo Ramos
* www.ircsasoftware.com.mx
*
* Programa para lee un CFD/CFDI y pasarlo a cursores .... v 1.0.0 - Noviembre 2010
* 
* Dic 23, 2010
* Cambios varios realizados por Victor Espina para adaptarlo al uso en VFP6 y permitir
* crear los cursores con un prefijo configurable.
*
* Dic 27, 2010
* Se incluyo un 3er parametro opcional llamado pcOpenSSL, el cual indica la ruta
* hacia el archivo OPENSSL.EXE, el cual es necesario para la funcion CFDExtraerCadenaOriginal.
*
* Si no se indica, se asume .\SSL
*
* Ago  7, 2010 - Arturo Ramos
* Se adapta para poder recibir un CFDI.
*
* Jun 13, 2012 - Arturo Ramos
* Se adapta para poder recibir CFD 2.2 y CFDI 3.2, para lo que se requiere
* un nuevo cursor para contener los regimenes fiscales del emisor
*
* Parametros de entrada
* ---------------------
* ArchivoXML				Archivo XML a cargar en cursores (si no se proporciona lo pide)
*
* Cursores de salida
* ------------------
* <prefijo>DG			Contiene el nodo Comprobante
* <prefijo>CO			Contiene los nodos Conceptos
* <prefijo>AD			Contiene los nodos informacionAduanera
* <prefijo>RE			Contiene los nodos Retenciones
* <prefijo>TR			Contiene los nodos Traslados
* <prefijo>RF			Contiene los nodos RegimenFiscal
*
* -----------------------------------------------------------------------------------
PROCEDURE CFDToCursor
PARAMETERS pArchivoXML, pcCursorPreFix, pcOpenSSL

CFDConf.ultimoError = ""

IF PCOUNT() = 2
 pcOpenSSL = CFDConf.openSSL
ENDIF

LOCAL ArchivoXML

IF TYPE('pArchivoXML') != 'C' THEN 
	ArchivoXML = GETFILE("Comprobante digital(*.xml):XML", "Comprobante", "Abrir", 0, "Abrir archivo")
	IF EMPTY(ArchivoXML)
  	    CFDConf.ultimoError = "Debe indicar el comprobante digital a leer"
  	    RETURN .F.
	ENDIF 
ELSE 
	ArchivoXML = pArchivoXML
ENDIF 	


 *-- VES Dic 23, 2010
 *   Se define los nombres de los cursores
 *
 PRIVATE cGenerales, cConceptos, cAduanas, cRetenciones, cTraslados
 IF EMPTY(pcCursorPrefix)
  pcCursorPrefix="Q"
 ENDIF
 cGenerales = pcCursorPrefix + "DG" 
 cConceptos = pcCursorPrefix + "CO" 
 cAduanas = pcCursorPrefix + "AD"  
 cRetenciones = pcCursorPrefix + "RE" 
 cTraslados = pcCursorPrefix + "TR"   
 cRegimenes =  pcCursorPrefix + "RF"   


LOCAL olNodes 

* Crea los cursores para contener los datos
DO CreaFactura 

* Datos Generales de la Factura 
SELECT (cGenerales)
INSERT INTO ;
	(cGenerales) (folio) ; && Se da de alta un registro en blanco 
	Value ("   ") 

* Se utiliza MSXML para cargar y leer el XML
* Web de MSXML DOM http://msdn.microsoft.com/en-us/library/ms760218%28v=VS.85%29.aspx
* Estandar XML w3  http://www.w3schools.com/xml/default.asp
* Manaul XML DOM   http://www.w3schools.com/dom/dom_intro.asp

xdoc=CREATEOBJECT('MSXML2.DOMdocument')

xdoc.LOAD(ArchivoXML)
If (xdoc.parseError.errorCode <> 0) Then
   myErr = xdoc.parseError
   CFDConf.ultimoError = myErr.reason
   RETURN .F.
ENDIF 

*-- Obtiene el nombre del nodo root, puede ser 'Comprobante' para CFD o 'cfdi:Comprobante' para CFDI
oRootNode = xdoc.documentElement
cRootTagName = oRootNode.tagName

IF cRootTagName = "cfdi:Comprobante"
 lcPrefijo = "cfdi:"
ELSE 
 lcPrefijo = ""
ENDIF


* ---------------------------------------------------------------------------
* <Comprobante>
* Estándar para la expresión de comprobantes fiscales digitales.
*
* VES Julio 2012: se almacena el valor de la propiedad Version para
* usarla luego en validaciones
* ---------------------------------------------------------------------------
LOCAL cveVersionXML  && VES Jul 21, 2012
cveVersionXML = ""   &&
olNodes = xdoc.selectNodes("//"+lcPrefijo+"Comprobante")
IF olNodes.LENGTH <= 0 THEN 
    CFDConf.ultimoError = "Comprobante inválido. Nodo <"+lcPrefijo+"Comprobante> no presente."
	RETURN .F.
ENDIF 
FOR i = 0 TO olNodes.LENGTH - 1
	FOR j = 0 TO olNodes.ITEM(i).ATTRIBUTES.LENGTH - 1
		sAtributeName = olNodes.ITEM(i).ATTRIBUTES.ITEM(j).nodeName
		sAtributeValues = olNodes.ITEM(i).ATTRIBUTES.ITEM(j).TEXT
		*? i,j,sAtributeName + "=" + sAtributeValues	&& Quitar comentario para ver el valor regresado.
		
		DO CASE 
			CASE sAtributeName = "version"
				UPDATE (cGenerales) SET versions   = sAtributeValues		&& Atributo requerido con valor prefijado a 2.0 que indica la versión del estándar bajo el que se encuentra expresado el comprobante.
				cveVersionXML = sAtributeValues  && VES Jul 21, 2012
			CASE sAtributeName = "serie"
				UPDATE (cGenerales) SET serie      = sAtributeValues		&& Atributo opcional para precisar la serie a la que corresponde el comprobante. Este atributo acepta una cadena de caracteres alfabéticos de 1 a 10 caracteres sin incluir caracteres acentuados.
			CASE sAtributeName = "folio"
				UPDATE (cGenerales) SET folio      = sAtributeValues		&& Atributo requerido que acepta un valor numérico entero superior a 0 que expresa el folio del comprobante.
			CASE sAtributeName = "fecha"
				UPDATE (cGenerales) SET fecha      = sAtributeValues		&& Atributo requerido para la expresión de la fecha y hora de expedición del comprobante fiscal. Se expresa en la forma aaaa-mm-ddThh:mm:ss, de acuerdo con la especificación ISO 8601.
			CASE sAtributeName = "sello"
				UPDATE (cGenerales) SET sello      = sAtributeValues		&& Atributo requerido para contener el sello digital del comprobante fiscal, al que hacen referencia las reglas de resolución miscelánea aplicable. El sello deberá ser expresado cómo una cadena de texto en formato Base 64.
			CASE sAtributeName = "noAprobacion"
				UPDATE (cGenerales) SET noAprobaci = sAtributeValues		&& CFD: Atributo requerido para precisar el número de aprobación emitido por el SAT, para el rango de folios al que pertenece el folio particular que ampara el comprobante fiscal digital.
			CASE sAtributeName = "anoAprobacion"
				UPDATE (cGenerales) SET anoAprobac = sAtributeValues		&& CFD: Atributo requerido para precisar el año en que se solicito el folio que se están utilizando para emitir el comprobante fiscal digital.
			CASE sAtributeName = "formaDePago"
				UPDATE (cGenerales) SET formaDePag = sAtributeValues		&& Atributo requerido para precisar la forma de pago que aplica para este comprobante fiscal digital. Se utiliza para expresar Pago en una sola exhibición o número de parcialidad pagada contra el total de parcialidades, Parcialidad 1 de X.
			CASE sAtributeName = "noCertificado"
				UPDATE (cGenerales) SET noCertific = sAtributeValues		&& Atributo requerido para expresar el número de serie del certificado de sello digital que ampara al comprobante, de acuerdo al acuse correspondiente a 20 posiciones otorgado por el sistema del SAT.
			CASE sAtributeName = "certificado"
				UPDATE (cGenerales) SET certific   = sAtributeValues		&& Atributo opcional que sirve para expresar el certificado de sello digital que ampara al comprobante como texto, en formato base 64.
			CASE sAtributeName = "condicionesDePago"
				UPDATE (cGenerales) SET condicione = sAtributeValues		&& Atributo opcional para expresar las condiciones comerciales aplicables para el pago del comprobante fiscal digital.
			CASE sAtributeName = "subTotal"
				UPDATE (cGenerales) SET subTotal   = VAL(sAtributeValues)&& Atributo requerido para representar la suma de los importes antes de descuentos e impuestos.
			CASE sAtributeName = "descuento"
				UPDATE (cGenerales) SET descuento  = VAL(sAtributeValues)&& Atributo opcional para representar el importe total de los descuentos aplicables antes de impuestos.
			CASE sAtributeName = "motivoDescuento"
				UPDATE (cGenerales) SET motivoDesc = sAtributeValues		&& Atributo opcional para expresar el motivo del descuento aplicable.
			CASE sAtributeName = "total"
				UPDATE (cGenerales) SET total      = VAL(sAtributeValues)&& Atributo requerido para representar la suma del subtotal, menos los descuentos aplicables, más los impuestos trasladados, menos los impuestos retenidos.
			CASE sAtributeName = "metodoDePago"
				UPDATE (cGenerales) SET metodoDePa = sAtributeValues		&& Atributo opcional de texto libre para expresar el método de pago de los bienes o servicios amparados por el comprobante. Se entiende como método de pago leyendas tales como: cheque, tarjeta de crédito o debito, depósito en cuenta, etc.
			CASE sAtributeName = "tipoDeComprobante"
				UPDATE (cGenerales) SET tipoDeComp = sAtributeValues		&& Atributo requerido para expresar el efecto del comprobante fiscal para el contribuyente emisor.
			CASE sAtributeName = "TipoCambio"
				UPDATE (cGenerales) SET TipoCambio = sAtributeValues		&& CFDI: Atributo opcional para representar el tipo de cambio conforme a la moneda usada
			CASE sAtributeName = "Moneda"
				UPDATE (cGenerales) SET Moneda     = sAtributeValues		&& CFDI: Atributo opcional para expresar la moneda utilizada para expresar los montos
			
			*-- Arturo Ramos - Junio 2012
			CASE sAtributeName = "MontoFolioFiscalOrig"
				UPDATE (cGenerales) SET MFolioFO	= VAL(sAtributeValues)
			CASE sAtributeName = "FechaFolioFiscalOrig"
				UPDATE (cGenerales) SET FFolioFO	= sAtributeValues
			CASE sAtributeName = "SerieFolioFiscalOrig"
				UPDATE (cGenerales) SET SFolioFO	= sAtributeValues
			CASE sAtributeName = "FolioFiscalOrig"
				UPDATE (cGenerales) SET FolioFO		= sAtributeValues
			CASE sAtributeName = "NumCtaPago"
				UPDATE (cGenerales) SET NumCtaPago	= sAtributeValues
			CASE sAtributeName = "LugarExpedicion"
				UPDATE (cGenerales) SET LugarExp	= sAtributeValues
		ENDCASE 
	NEXT j
NEXT i

*-- Arturo Ramos
*   Si hay un monto de descuento pero no un motivo, se asigna un motivo generico
SELECT (cGenerales)
IF descuento > 0 AND EMPTY(motivoDesc)
 REPLACE motivoDesc WITH "Descuento"
ENDIF

* ---------------------------------------------------------------------------
* <Comprobante> -- <Emisor>
* Nodo requerido para expresar la información del contribuyente emisor del comprobante.
* ---------------------------------------------------------------------------
olNodes = xdoc.selectNodes("//"+lcPrefijo+"Comprobante/"+lcPrefijo+"Emisor")
IF olNodes.LENGTH <= 0 THEN 
    CFDConf.ultimoError = "Comprobante inválido. Nodo <"+lcPrefijo+"Emisor> no presente."
	RETURN .F.
ENDIF 
FOR i = 0 TO olNodes.LENGTH - 1
	FOR j = 0 TO olNodes.ITEM(i).ATTRIBUTES.LENGTH - 1
		sAtributeName = olNodes.ITEM(i).ATTRIBUTES.ITEM(j).nodeName
		sAtributeValues = olNodes.ITEM(i).ATTRIBUTES.ITEM(j).TEXT
		*? i,j,sAtributeName + "=" + sAtributeValues	&& Quitar comentario para ver el valor regresado.
		
		DO CASE 
			CASE sAtributeName = "rfc"
			    sAtributeValues = CHRT(sAtributeValues,".- ","")   && VES Nov 16, 2011   
				UPDATE (cGenerales) SET Erfc       = sAtributeValues		&& Atributo requerido para la Clave del Registro Federal de Contribuyentes correspondiente al contribuyente emisor del comprobante sin guiones o espacios.
			CASE sAtributeName = "nombre"
				UPDATE (cGenerales) SET Enombre    = sAtributeValues		&& Atributo requerido para el nombre o razón social del contribuyente emisor del comprobante.
		ENDCASE 
	NEXT j
NEXT i

* ---------------------------------------------------------------------------
* <Comprobante> -- <Emisor> -- <DomicilioFiscal>
* Nodo requerido para precisar la información de ubicación del domicilio fiscal del contribuyente emisor.
*
* VES Julio 2012: este nodo pasa a ser opcional en CFD 2.2 y CFD 3.2
* ---------------------------------------------------------------------------
olNodes = xdoc.selectNodes("//"+lcPrefijo+"Comprobante/"+lcPrefijo+"Emisor/"+lcPrefijo+"DomicilioFiscal")
IF olNodes.LENGTH > 0 THEN   && VES Jul 21, 2012
	FOR i = 0 TO olNodes.LENGTH - 1
		FOR j = 0 TO olNodes.ITEM(i).ATTRIBUTES.LENGTH - 1
			sAtributeName = olNodes.ITEM(i).ATTRIBUTES.ITEM(j).nodeName
			sAtributeValues = olNodes.ITEM(i).ATTRIBUTES.ITEM(j).TEXT
			*? i,j,sAtributeName + "=" + sAtributeValues	&& Quitar comentario para ver el valor regresado.
			
			DO CASE 
				CASE sAtributeName = "calle"
					UPDATE (cGenerales) SET Ecalle     = sAtributeValues		&& Este atributo requerido sirve para precisar la avenida, calle, camino o carretera donde se da la ubicación.
				CASE sAtributeName = "noExterior"
					UPDATE (cGenerales) SET EnoExterio = sAtributeValues		&& Este atributo opcional sirve para expresar el número particular en donde se da la ubicación sobre una calle dada.
				CASE sAtributeName = "noInterior"
					UPDATE (cGenerales) SET EnoInterio = sAtributeValues		&& Este atributo opcional sirve para expresar información adicional para especificar la ubicación cuando calle y número exterior (noExterior) no resulten suficientes para determinar la ubicación de forma precisa.
				CASE sAtributeName = "colonia"
					UPDATE (cGenerales) SET Ecolonia   = sAtributeValues		&& Este atributo opcional sirve para precisar la colonia en donde se da la ubicación cuando se desea ser más específico en casos de ubicaciones urbanas.
				CASE sAtributeName = "localidad"
					UPDATE (cGenerales) SET Elocalidad = sAtributeValues		&& Atributo opcional que sirve para precisar la ciudad o población donde se da la ubicación.
				CASE sAtributeName = "referencia"
					UPDATE (cGenerales) SET Ereferen   = sAtributeValues		&& Atributo opcional para expresar una referencia de ubicación adicional.
				CASE sAtributeName = "municipio"
					UPDATE (cGenerales) SET Emunicipio = sAtributeValues		&& Atributo requerido que sirve para precisar el municipio o delegación (en el caso del Distrito Federal) en donde se da la ubicación.
				CASE sAtributeName = "estado"
					UPDATE (cGenerales) SET Eestado    = sAtributeValues		&& Atributo requerido que sirve para precisar el estado o entidad federativa donde se da la ubicación.
				CASE sAtributeName = "pais"
					UPDATE (cGenerales) SET Epais      = sAtributeValues		&& Atributo requerido que sirve para precisar el país donde se da la ubicación.
				CASE sAtributeName = "codigoPostal"
					UPDATE (cGenerales) SET EcodigoPos = sAtributeValues		&& Atributo requerido que sirve para asentar el código postal en donde se da la ubicación.
			ENDCASE 
		NEXT j
	NEXT i
ELSE
  IF INLIST(cveVersionXML,"2.0","3.0")  && VES Jul 21, 2012
    CFDConf.ultimoError = "Comprobante inválido. Nodo <"+lcPrefijo+"DomicilioFiscal> del Emisor no presente."
	RETURN .F.
  ENDIF	
ENDIF 

* ---------------------------------------------------------------------------
* <Comprobante> -- <Emisor> -- <ExpedidoEn>
* Nodo opcional para precisar la información de ubicación del domicilio en donde es emitido el comprobante fiscal en caso de que sea distinto del domicilio fiscal del contribuyente emisor.
* ---------------------------------------------------------------------------
olNodes = xdoc.selectNodes("//"+lcPrefijo+"Comprobante/"+lcPrefijo+"Emisor/"+lcPrefijo+"ExpedidoEn")
FOR i = 0 TO olNodes.LENGTH - 1
	FOR j = 0 TO olNodes.ITEM(i).ATTRIBUTES.LENGTH - 1
		sAtributeName = olNodes.ITEM(i).ATTRIBUTES.ITEM(j).nodeName
		sAtributeValues = olNodes.ITEM(i).ATTRIBUTES.ITEM(j).TEXT
		*? i,j,sAtributeName + "=" + sAtributeValues	&& Quitar comentario para ver el valor regresado.
		
		DO CASE
			CASE sAtributeName = "calle"
				UPDATE (cGenerales) SET Xcalle     = sAtributeValues		&& Este atributo requerido sirve para precisar la avenida, calle, camino o carretera donde se da la ubicación.
			CASE sAtributeName = "noExterior"
				UPDATE (cGenerales) SET XnoExterio = sAtributeValues		&& Este atributo opcional sirve para expresar el número particular en donde se da la ubicación sobre una calle dada.
			CASE sAtributeName = "noInterior"
				UPDATE (cGenerales) SET XnoInterio = sAtributeValues		&& Este atributo opcional sirve para expresar información adicional para especificar la ubicación cuando calle y número exterior (noExterior) no resulten suficientes para determinar la ubicación de forma precisa.
			CASE sAtributeName = "colonia"
				UPDATE (cGenerales) SET Xcolonia   = sAtributeValues		&& Este atributo opcional sirve para precisar la colonia en donde se da la ubicación cuando se desea ser más específico en casos de ubicaciones urbanas.
			CASE sAtributeName = "localidad"
				UPDATE (cGenerales) SET Xlocalidad = sAtributeValues		&& Atributo opcional que sirve para precisar la ciudad o población donde se da la ubicación.
			CASE sAtributeName = "referencia"
				UPDATE (cGenerales) SET Xreferen   = sAtributeValues		&& Atributo opcional para expresar una referencia de ubicación adicional.
			CASE sAtributeName = "municipio"
				UPDATE (cGenerales) SET Xmunicipio = sAtributeValues		&& Atributo requerido que sirve para precisar el municipio o delegación (en el caso del Distrito Federal) en donde se da la ubicación.
			CASE sAtributeName = "estado"
				UPDATE (cGenerales) SET Xestado    = sAtributeValues		&& Atributo requerido que sirve para precisar el estado o entidad federativa donde se da la ubicación.
			CASE sAtributeName = "pais"
				UPDATE (cGenerales) SET Xpais      = sAtributeValues		&& Atributo requerido que sirve para precisar el país donde se da la ubicación.
			CASE sAtributeName = "codigoPostal"
				UPDATE (cGenerales) SET XcodigoPos = sAtributeValues		&& Atributo requerido que sirve para asentar el código postal en donde se da la ubicación.
		ENDCASE 
	NEXT j
NEXT i

* ---------------------------------------------------------------------------
* <Comprobante> -- <Emisor> -- <RegimenFiscal>
* Atributo requerido para incorporar el nombre del régimen en el que tributa el contribuyente emisor.
* ---------------------------------------------------------------------------
SELECT (cRegimenes)
olNodes = xdoc.selectNodes("//"+lcPrefijo+"Comprobante/"+lcPrefijo+"Emisor")
IF olNodes.LENGTH <= 0 THEN 
    CFDConf.ultimoError = "Comprobante inválido. Nodo <"+lcPrefijo+"Emisor> no presente."
	RETURN .F.
ENDIF 
LeerDatos(xdoc.selectNodes("//"+lcPrefijo+"Comprobante/"+lcPrefijo+"Emisor"))	&& Función que recorre cada nodo hijo de un nodo padre dado.
SELECT (cGenerales)


* ---------------------------------------------------------------------------
* <Comprobante> -- <Receptor>
* Nodo requerido para precisar la información del contribuyente receptor del comprobante.
* ---------------------------------------------------------------------------
olNodes = xdoc.selectNodes("//"+lcPrefijo+"Comprobante/"+lcPrefijo+"Receptor")
IF olNodes.LENGTH <= 0 THEN 
    CFDConf.ultimoError = "Comprobante inválido. Nodo <"+lcPrefijo+"Receptor> no presente."
	RETURN .F.
ENDIF 
FOR i = 0 TO olNodes.LENGTH - 1
	FOR j = 0 TO olNodes.ITEM(i).ATTRIBUTES.LENGTH - 1
		sAtributeName = olNodes.ITEM(i).ATTRIBUTES.ITEM(j).nodeName
		sAtributeValues = olNodes.ITEM(i).ATTRIBUTES.ITEM(j).TEXT
		*? i,j,sAtributeName + "=" + sAtributeValues	&& Quitar comentario para ver el valor regresado.
		
		DO CASE
			CASE sAtributeName = "rfc"
				sAtributeValues = CHRT(sAtributeValues,".- ","")   && VES Nov 16, 2011
				UPDATE (cGenerales) SET Rrfc       = sAtributeValues		&& Atributo requerido para precisar la Clave del Registro Federal de Contribuyentes correspondiente al contribuyente receptor del comprobante.
			CASE sAtributeName = "nombre"
				UPDATE (cGenerales) SET Rnombre    = sAtributeValues		&& Atributo opcional para precisar el nombre o razón social del contribuyente receptor.
		ENDCASE 
	NEXT j
NEXT i


* ---------------------------------------------------------------------------
* <Comprobante> -- <Receptor> -- <Domicilio>
* Nodo opcional para la definición de la ubicación donde se da el domicilio del receptor del comprobante fiscal.
* ---------------------------------------------------------------------------
olNodes = xdoc.selectNodes("//"+lcPrefijo+"Comprobante/"+lcPrefijo+"Receptor/"+lcPrefijo+"Domicilio")
FOR i = 0 TO olNodes.LENGTH - 1
	FOR j = 0 TO olNodes.ITEM(i).ATTRIBUTES.LENGTH - 1
		sAtributeName = olNodes.ITEM(i).ATTRIBUTES.ITEM(j).nodeName
		sAtributeValues = olNodes.ITEM(i).ATTRIBUTES.ITEM(j).TEXT
		*? i,j,sAtributeName + "=" + sAtributeValues	&& Quitar comentario para ver el valor regresado.
		
		DO CASE
			CASE sAtributeName = "calle"
				UPDATE (cGenerales) SET Rcalle     = sAtributeValues		&& Este atributo opcional sirve para precisar la avenida, calle, camino o carretera donde se da la ubicación.
			CASE sAtributeName = "noExterior"
				UPDATE (cGenerales) SET RnoExterio = sAtributeValues		&& Este atributo opcional sirve para expresar el número particular en donde se da la ubicación sobre una calle dada.
			CASE sAtributeName = "noInterior"
				UPDATE (cGenerales) SET RnoInterio = sAtributeValues		&& Este atributo opcional sirve para expresar información adicional para especificar la ubicación cuando calle y número exterior (noExterior) no resulten suficientes para determinar la ubicación de forma precisa.
			CASE sAtributeName = "colonia"
				UPDATE (cGenerales) SET Rcolonia   = sAtributeValues		&& Este atributo opcional sirve para precisar la colonia en donde se da la ubicación cuando se desea ser más específico en casos de ubicaciones urbanas.
			CASE sAtributeName = "localidad"
				UPDATE (cGenerales) SET Rlocalidad = sAtributeValues		&& Atributo opcional que sirve para precisar la ciudad o población donde se da la ubicación.
			CASE sAtributeName = "referencia"
				UPDATE (cGenerales) SET Rreferen   = sAtributeValues		&& Atributo opcional para expresar una referencia de ubicación adicional.
			CASE sAtributeName = "municipio"
				UPDATE (cGenerales) SET Rmunicipio = sAtributeValues		&& Atributo opcional que sirve para precisar el municipio o delegación (en el caso del Distrito Federal) en donde se da la ubicación.
			CASE sAtributeName = "estado"
				UPDATE (cGenerales) SET Restado    = sAtributeValues		&& Atributo opcional que sirve para precisar el estado o entidad federativa donde se da la ubicación.
			CASE sAtributeName = "pais"
				UPDATE (cGenerales) SET Rpais      = sAtributeValues		&& Atributo requerido que sirve para precisar el país donde se da la ubicación.
			CASE sAtributeName = "codigoPostal"
				UPDATE (cGenerales) SET RcodigoPos = sAtributeValues		&& Atributo opcional que sirve para asentar el código postal en donde se da la ubicación.
		ENDCASE 
	NEXT j
NEXT i

* ---------------------------------------------------------------------------
* <Comprobante> -- <Conceptos>
* Nodo requerido para enlistar los conceptos cubiertos por el comprobante.
* ---------------------------------------------------------------------------
SELECT (cConceptos)
olNodes = xdoc.selectNodes("//"+lcPrefijo+"Comprobante/"+lcPrefijo+"Conceptos")
IF olNodes.LENGTH <= 0 THEN 
    CFDConf.ultimoError = "Comprobante inválido. Nodo <"+lcPrefijo+"Conceptos> no presente."
	RETURN .F.
ENDIF 
LeerDatos(xdoc.selectNodes("//"+lcPrefijo+"Comprobante/"+lcPrefijo+"Conceptos"))	&& Función que recorre cada nodo hijo de un nodo padre dado.
SELECT (cGenerales)

* ---------------------------------------------------------------------------
* <Comprobante> -- <Impuestos>
* Nodo requerido para capturar los impuestos aplicables.
* ---------------------------------------------------------------------------
olNodes = xdoc.selectNodes("//"+lcPrefijo+"Comprobante/"+lcPrefijo+"Impuestos/")
IF olNodes.LENGTH <= 0 THEN 
	  CFDConf.ultimoError = "Comprobante inválido. Nodo <"+lcPrefijo+"Impuestos> no presente."
	RETURN .F.
ENDIF 
FOR i = 0 TO olNodes.LENGTH - 1
	FOR j = 0 TO olNodes.ITEM(i).ATTRIBUTES.LENGTH - 1
		sAtributeName = olNodes.ITEM(i).ATTRIBUTES.ITEM(j).nodeName
		sAtributeValues = olNodes.ITEM(i).ATTRIBUTES.ITEM(j).TEXT
		*? i,j,sAtributeName + "=" + sAtributeValues	&& Quitar comentario para ver el valor regresado.
		
		DO CASE
			CASE sAtributeName = "totalImpuestosTrasladados"
				UPDATE (cGenerales) SET TotImpTras = VAL(sAtributeValues) && Atributo opcional para expresar el total de los impuestos trasladados que se desprenden de los conceptos expresados en el comprobante fiscal digital.
			CASE sAtributeName = "totalImpuestosRetenidos"
				UPDATE (cGenerales) SET TotImpRet  = VAL(sAtributeValues) && Atributo opcional para expresar el total de los impuestos retenidos que se desprenden de los conceptos expresados en el comprobante fiscal digital.
		ENDCASE 
	NEXT j
NEXT i


* ---------------------------------------------------------------------------
* <Comprobante> -- <Impuestos> -- <Retenciones> -- <Retencion>  <<-- Uno para ISR y otro para IVA
* Nodo opcional para asentar o referir los impuestos trasladados aplicables.
* ---------------------------------------------------------------------------
SELECT (cRetenciones)
LeerDatos(xdoc.selectNodes("//"+lcPrefijo+"Comprobante/"+lcPrefijo+"Impuestos/"+lcPrefijo+"Retenciones"))	&& Función que recorre cada nodo hijo de un nodo padre dado.
GO TOP 
SCAN 
	DO CASE 
		CASE ALLTRIM(EVAL(cRetenciones+".impuesto")) = "ISR"
			UPDATE (cGenerales) SET ;
				RetISR = "ISR", ;
				TotRetISR = EVAL(cRetenciones+".importe")
		CASE ALLTRIM(EVAL(cRetenciones+".impuesto")) = "IVA"
			UPDATE (cGenerales) SET ;
				RetIVA = "IVA", ;
				TotRetIVA = EVAL(cRetenciones+".importe")
	ENDCASE 			
ENDSCAN 
SELECT (cGenerales)


* ---------------------------------------------------------------------------
* <Comprobante> -- <Impuestos> -- <Traslados> -- <Traslado>  <<-- Puede ser IVA (0%, 11% o 16%) o IEPS
* Nodo opcional para asentar o referir los impuestos trasladados aplicables.
* ---------------------------------------------------------------------------
SELECT (cTraslados)
LeerDatos(xdoc.selectNodes("//"+lcPrefijo+"Comprobante/"+lcPrefijo+"Impuestos/"+lcPrefijo+"Traslados"))	&& Función que recorre cada nodo hijo de un nodo padre dado.
GO TOP 
SCAN 
	DO CASE 
		CASE ALLTRIM(EVAL(cTraslados+".impuesto")) = "IVA"
			UPDATE (cGenerales) SET ;
				impuesto = "IVA", ;
				tasa = EVAL(cTraslados+".tasa"), ;
				importe = EVAL(cTraslados+".importe")
		CASE ALLTRIM(EVAL(cTraslados+".impuesto")) = "IEPS"
			UPDATE (cGenerales) SET ;
				TraIEPS = "IEPS", ;
				TraTasIEPS = EVAL(cTraslados+".tasa"), ;
				TotTraIEPS = EVAL(cTraslados+".importe")
	ENDCASE 			
ENDSCAN 
SELECT (cGenerales)


* ---------------------------------------------------------------------------
* <Comprobante> -- <Complemento> -- <TimbreFiscalDigital>
* Nodo opcional donde se incluirá el complemento Timbre Fiscal Digital de manera
* obligatoria y los nodos complementarios determinados por el SAT, de acuerdo a las
* disposiciones particulares a un sector o actividad especifica.
* ---------------------------------------------------------------------------
olNodes = xdoc.selectNodes("//"+lcPrefijo+"Comprobante/"+lcPrefijo+"Complemento/"+lcPrefijo+"TimbreFiscalDigital/")
FOR i = 0 TO olNodes.LENGTH - 1
	FOR j = 0 TO olNodes.ITEM(i).ATTRIBUTES.LENGTH - 1
		sAtributeName = olNodes.ITEM(i).ATTRIBUTES.ITEM(j).nodeName
		sAtributeValues = olNodes.ITEM(i).ATTRIBUTES.ITEM(j).TEXT
		*? i,j,sAtributeName + "=" + sAtributeValues	&& Quitar comentario para ver el valor regresado.
		
		DO CASE
			CASE sAtributeName = "version"
				UPDATE (cGenerales) SET versionTFD = sAtributeValues
			CASE sAtributeName = "FechaTimbrado"
				UPDATE (cGenerales) SET fechaTFD  = sAtributeValues
			CASE sAtributeName = "selloCFD"
				UPDATE (cGenerales) SET selloCFD  = sAtributeValues
			CASE sAtributeName = "noCertificadoSAT"
				UPDATE (cGenerales) SET certSAT  = sAtributeValues
			CASE sAtributeName = "selloSAT"
				UPDATE (cGenerales) SET selloSAT  = sAtributeValues
			CASE sAtributeName = "UUID"
				UPDATE (cGenerales) SET UUID  = sAtributeValues
		ENDCASE 
	NEXT j
NEXT i
SELECT (cGenerales)

* --------------------------------------------------------------------------------
* Genera la cadena original
* --------------------------------------------------------------------------------
LOCAL strOriginal
strOriginal = CFDExtraerCadenaOriginal(ArchivoXML,pcOpenSSL)
UPDATE (cGenerales) SET cadenaOrig = strOriginal

* Muestra los datos
* Quitar comentarios para ver cursores creados
*!*	SELECT (cRetenciones)
*!*	BROWSE 
*!*	SELECT (cTraslados)
*!*	BROWSE
*!*	SELECT (cConceptos)
*!*	BROWSE
*!*	SELECT (cGenerales)
*!*	BROWSE 
*!*	SELECT (cRegimenes)
*!*	BROWSE


RETURN 




* --------------------------------------------------------------------------------
* Función para obtener cada atributo de cada nodo hijo dado un nodo padre
* --------------------------------------------------------------------------------
FUNCTION LeerDatos
	LPARAMETERS root

	LOCAL CHILD 

	*!* Aqui se procesan los nodos
	FOR EACH CHILD IN root
		*? CHILD.nodeName
		
		DO CASE 
			CASE CHILD.nodeName == lcPrefijo+"Concepto"
				INSERT INTO (cConceptos) (cantidad) VALUES (0)
				FOR j = 0 TO CHILD.ATTRIBUTES.LENGTH - 1
					sAtributeName = CHILD.ATTRIBUTES.ITEM(j).nodeName
					sAtributeValues = CHILD.ATTRIBUTES.ITEM(j).TEXT
					*? j,sAtributeName + "=" + sAtributeValues
					DO CASE 
						CASE sAtributeName = "cantidad"
							REPLACE cantidad WITH VAL(sAtributeValues) IN (cConceptos)
						CASE sAtributeName = "unidad"
							REPLACE unidad WITH sAtributeValues IN (cConceptos)
						CASE sAtributeName = "noIdentificacion"
							REPLACE noID WITH sAtributeValues IN (cConceptos)
						CASE sAtributeName = "descripcion"
							REPLACE descripcio WITH sAtributeValues IN (cConceptos)
						CASE sAtributeName = "valorUnitario"
							REPLACE valorUnita WITH VAL(sAtributeValues) IN (cConceptos)
						CASE sAtributeName = "importe"
							REPLACE importe WITH VAL(sAtributeValues) IN (cConceptos)
					ENDCASE 
				ENDFOR
				
			
			CASE CHILD.nodeName == lcPrefijo+"Retencion"
				INSERT INTO (cRetenciones) (impuesto) VALUES (" ")
				FOR j = 0 TO CHILD.ATTRIBUTES.LENGTH - 1
					sAtributeName = CHILD.ATTRIBUTES.ITEM(j).nodeName
					sAtributeValues = CHILD.ATTRIBUTES.ITEM(j).TEXT
					*? j,sAtributeName + "=" + sAtributeValues
					DO CASE 
						CASE sAtributeName = "impuesto"
							REPLACE impuesto WITH sAtributeValues IN (cRetenciones)		&& Atributo requerido para señalar el tipo de impuesto retenido. ISR o IVA.
						CASE sAtributeName = "importe"
							REPLACE importe WITH VAL(sAtributeValues) IN (cRetenciones)	&& Atributo requerido para señalar el importe o monto del impuesto retenido.						
					ENDCASE 
				ENDFOR 
				
			CASE CHILD.nodeName == lcPrefijo+"Traslado"
				INSERT INTO (cTraslados) (impuesto) VALUES (" ")
				FOR j = 0 TO CHILD.ATTRIBUTES.LENGTH - 1
					sAtributeName = CHILD.ATTRIBUTES.ITEM(j).nodeName
					sAtributeValues = CHILD.ATTRIBUTES.ITEM(j).TEXT
					*? j,sAtributeName + "=" + sAtributeValues
					DO CASE 
						CASE sAtributeName = "impuesto"
							REPLACE impuesto WITH sAtributeValues IN (cTraslados)		&& Atributo requerido para señalar el tipo de impuesto retenido. ISR o IVA.
						CASE sAtributeName = "importe"
							REPLACE importe WITH VAL(sAtributeValues) IN (cTraslados)	&& Atributo requerido para señalar el importe o monto del impuesto retenido.
						CASE sAtributeName = "tasa"
							REPLACE tasa WITH VAL(sAtributeValues) IN (cTraslados)	&& Atributo requerido para señalar el importe o monto del impuesto retenido.
					ENDCASE 
				ENDFOR
			
			CASE CHILD.nodeName == lcPrefijo+"RegimenFiscal"
				INSERT INTO (cRegimenes) (regimen) VALUES (" ")
				FOR j = 0 TO CHILD.ATTRIBUTES.LENGTH - 1
					sAtributeName = CHILD.ATTRIBUTES.ITEM(j).nodeName
					sAtributeValues = CHILD.ATTRIBUTES.ITEM(j).TEXT
					*? j,sAtributeName + "=" + sAtributeValues
					IF sAtributeName = "Regimen"
						REPLACE regimen WITH sAtributeValues IN (cRegimenes)	&& Nodo requerido para incorporar los regímenes en los que tributa el contribuyente emisor. Puede contener más de un régimen.
					ENDIF 
				ENDFOR

			CASE CHILD.nodeName == lcPrefijo+"InformacionAduanera"
			    SELECT (cConceptos)
				FOR j = 0 TO CHILD.ATTRIBUTES.LENGTH - 1
					sAtributeName = CHILD.ATTRIBUTES.ITEM(j).nodeName
					sAtributeValues = CHILD.ATTRIBUTES.ITEM(j).TEXT
					*? j,sAtributeName + "=" + sAtributeValues
					DO CASE 
						CASE sAtributeName = "numero"
							REPLACE ianumero WITH sAtributeValues
						CASE sAtributeName = "fecha"
							REPLACE iafecha WITH sAtributeValues 
						CASE sAtributeName = "aduana"
							REPLACE iaaduana WITH sAtributeValues 
					ENDCASE 
				ENDFOR
				LOCAL oIA
				SCATTER NAME oIA
				INSERT INTO (cAduanas) VALUES (oIA.noid, oIA.ianumero, oIA.iafecha, oIA.iaaduana)


		ENDCASE  
		*** Si el nodo que estamos procesando tiene descendencia volvemos a llamar a la función LeerDatos pasandole el nodo actual
		IF CHILD.hasChildNodes
			LeerDatos(CHILD.childNodes)
		ENDIF
	ENDFOR
ENDFUNC


* --------------------------------------------------------------------------------
* Procedimiento que crea el entorno de datos para contener la información del comprobante
* --------------------------------------------------------------------------------
PROCEDURE CreaFactura

	swError = .T.

	* Datos Generales de la Factura 
	CREATE CURSOR (cGenerales)    ;
	   (                    ;
	    versions   C(005)  ,; 
	    serie      C(020)  ,; 	&& De 1 a 10 Caracteres para CFD / hasta 20 para CFDI
	    folio      C(010)  ,; 	&& 10 Caracteres de 1 al 2147483647
	    fecha      C(020)  ,; 
	    noAprobaci C(014)  ,; 	&& 14 Máximo para CFDs
	    anoAprobac C(004)  ,; 	&& 4 Dígitos
	    formaDePag C(080)  ,; 
	    condicione C(250)  ,; 
	    metodoDePa C(250)  ,; 
	    motivoDesc C(250)  ,; 
	    subTotal   N(10,6) ,; 	&& Tipo especial: t_importe de 2 a 6 decimales
	    descuento  N(10,6) ,; 	&& Tipo especial: t_importe de 2 a 6 decimales
	    total      N(10,6) ,; 	&& Tipo especial: t_importe de 2 a 6 decimales
	    tipoDeComp C(010)  ,; 
	    noCertific C(030)  ,; 	&& Hasta 20 segun Anexo 20
	    sello      M       ,; 
	    certific   M       ,; 
	    cadenaorig M       ,; 
	    Enombre    C(150)  ,; 	&& 
	    Erfc       C(013)  ,;   && Tipo especial: t_RFC de 12-13 Caracteres
	    Ecalle     C(100)  ,; 
	    EcodigoPos C(010)  ,; 
	    Ecolonia   C(100)  ,; 	&& 
	    Ereferen   C(250)  ,; 
	    Eestado    C(050)  ,; 	&& 
	    Elocalidad C(050)  ,; 
	    Emunicipio C(050)  ,; 
	    EnoExterio C(050)  ,; 	&&
	    EnoInterio C(050)  ,; 	&&
	    Epais      C(010)  ,; 
	    Xcalle     C(100)  ,; 
	    XcodigoPos C(010)  ,; 
	    Xcolonia   C(100)  ,; 	&&
	    Xestado    C(050)  ,; 	&&
	    Xlocalidad C(050)  ,; 
	    Xreferen   C(250)  ,; 
	    Xmunicipio C(050)  ,; 
	    XnoExterio C(050)  ,; 	&&
	    XnoInterio C(050)  ,; 	&&
	    Xpais      C(010)  ,; 
	    Rnombre    C(150)  ,; 	&&
	    Rrfc       C(013)  ,; 	&& Tipo especial: t_RFC de 12-13 Caracteres
	    Rcalle     C(100)  ,; 
	    RcodigoPos C(010)  ,; 
	    Rcolonia   C(100)  ,; 	&& 
	    Rreferen   C(250)  ,; 	&& 
	    Restado    C(050)  ,; 	&& 
	    Rlocalidad C(050)  ,; 
	    Rmunicipio C(050)  ,;  
	    RnoExterio C(050)  ,; 	&& 
	    RnoInterio C(050)  ,; 	&& 
	    Rpais      C(010)  ,; 
	    TotImpTras N(10,6) ,; 	&& Tipo especial: t_importe de 2 a 6 decimales
	    RetISR     C(010)  ,; 
	    TotRetISR  N(10,6) ,; 	&& Tipo especial: t_importe de 2 a 6 decimales
	    RetIVA     C(010)  ,; 
	    TotRetIVA  N(10,6) ,; 	&& Tipo especial: t_importe de 2 a 6 decimales
	    TotImpRet  N(10,6) ,; 	&& Tipo especial: t_importe de 2 a 6 decimales
	    impuesto   C(010)  ,; 
	    tasa       N(10,6) ,; 	&& Tipo especial: t_importe de 2 a 6 decimales
	    importe    N(10,6) ,; 	&& Tipo especial: t_importe de 2 a 6 decimales
	    TraIEPS    C(004)  ,; 
		TraTasIEPS N(10,6) ,; 	&& Tipo especial: t_importe de 2 a 6 decimales
		TotTraIEPS N(10,6) ,; 	&& Tipo especial: t_importe de 2 a 6 decimales
	    referencia C(010)  ,; 
	    TipoCambio C(013)  ,;
	    Moneda     C(020)  ,; 
	    cliente    C(010)  ,; 
	    pedido     C(010)  ,; 
	    agente     C(010)  ,; 
	    embarque   C(020)  ,; 
	    proveedor  C(010)  ,; 
	    ordencompr C(010)  ,; 
	    rTelefono  C(030)  ,; 
	    eTelefono  C(030)  ,; 
	    eWeb       C(050)  ,; 
	    eMail      C(050)  ,; 
	    totalletra C(250)  ,; 
	    Notas      C(250)  ,; 
	    fechaCFD   C(050)  ,; 
	    fechaVence C(050)  ,; 
	    versionTFD c(010)  ,;
	    fechaTFD   c(020)  ,;
	    selloCFD   M       ,;
	    selloSAT   M       ,;
	    certSAT    c(030)  ,;
	    UUID       C(036)  ,;
	    MFolioFO   N(10,6) ,;	&& Tipo especial: t_importe de 2 a 6 decimales
	    FFolioFO   C(20)   ,;
	    SFolioFO   C(20)   ,;
	    FolioFO    C(10)   ,;
	    NumCtaPago C(250)  ,;
	    LugarExp   C(250)   ;
	   )

	* Datos de las partidas o conceptos que forman la factura
	CREATE CURSOR (cConceptos) ;
	   (                      ;
	    cantidad    N(10,3) ,; 
	    noID        C(020)  ,; 
	    descripcio  M		,;
	    InfoAduana  C(250)  ,; 
	    importe     N(10,6) ,; 	&& Tipo especial: t_importe de 2 a 6 decimales
	    unidad      C(010)  ,; 
	    valorUnita  N(10,6) ,; 	&& Tipo especial: t_importe de 2 a 6 decimales
	    nopredio    C(050)  ,;
	    ianumero	C(50)   ,;  && Informacion aduanera - numero
	    iafecha		C(10)	,;  && Informacion aduanera - fecha
	    iaaduana	C(50)	;   && Informacion aduanera - aduana	 
	   )
	
	* Datos de retenciones
	CREATE CURSOR (cRetenciones) ;
		(                   ;
		 impuesto   C(004) ,; 	&& Puede ser ISR o IVA
		 importe    N(10,6) ; 	&& && Tipo especial: t_importe de 2 a 6 decimales
		)
		
	* Datos de traslados
	CREATE CURSOR (cTraslados) ;
		(                   ;
		 impuesto   C(004) ,; 	&& Puede ser IVA o IEPS
		 tasa       N(10,6),; 	&& Tipo especial: t_importe de 2 a 6 decimales
		 importe    N(10,6) ; 	&& Tipo especial: t_importe de 2 a 6 decimales
		)
		
	* Datos de información aduanera 
	CREATE CURSOR (cAduanas) ;
	   (                      ;
	    noID        C(020) ,; 
	    numero      C(020) ,; 
	    fecha       C(010) ,; 
	    aduana      C(020)  ;
	   )
	   
	* Datos de los regimenes fiscales
	CREATE CURSOR (cRegimenes) ;
	   (						;
	    regimen		C(250) ;
	   ) 

	swError = .F.
	
RETURN 




*-- CFDDomicilio
*   Toma los distintos valores de un domicilio fiscal y los junta
*   en una sola cadena
*
PROCEDURE CFDDomicilio(pcCalle, pcNoExterior, pcNoInterior, pcReferencia, pcColonia, ;
                       pcLocalidad, pcMunicipio, pcEstado, pcCodPostal, pcPais)
 *
 LOCAL cDireccion
 cDireccion = ALLT(pcCalle) + " " + ALLT(pcNoExterior) + " " + ALLT(pcNoInterior) + "," + ;
              ALLT(pcReferencia) + "," + IIF(EMPTY(pcColonia),"","Col. "+ALLT(pcColonia)) + "," + ;
              IIF(EMPTY(pcCodPostal),"","CP "+ALLT(pcCodPostal)) + "," + ALLT(pcLocalidad) + "," + ;
              ALLT(pcMunicipio) + "," + ALLT(pcEstado) + "," + ALLT(pcPais)
              
 cDireccion = ALLT(cDireccion)
 DO WHILE AT(SPACE(2),cDireccion) > 0
  cDireccion = STRT(cDireccion,SPACE(2),SPACE(1))
 ENDDO
 DO WHILE AT(" ,",cDireccion) > 0
  cDireccion = STRT(cDireccion," ,",",")
 ENDDO
 DO WHILE AT(",,",cDireccion) > 0
  cDireccion = STRT(cDireccion,",,",",")
 ENDDO
 IF LEFT(cDireccion,1) = ","
  SUBS(cDireccion,2)
 ENDIF
 cDireccion = STRT(cDireccion,",",", ")
 
 RETURN cDireccion
 *
ENDPROC




*-- CFDPrint
*   Genera una representacion impresa de un CFD dado
*
*   Autor: V. Espina
*   Fecha: Dic 2010
*
PROCEDURE CFDPrint(pcXML, plPreview, plPDFMode, pcPDFTarget, plReplaceCO)
 *
  *-- Se lee el XML y se cargan los datos en cursores
  *
  IF NOT CFDToCursor(pcXML) 
   RETURN .F.
  ENDIF
  
  *-- Se anade una columna REGSFIS al cursor de datos generales
  *
  ALTER TABLE QDG ADD regsfis M
  SELECT QRF
  SCAN
    REPLACE regsfis WITH ALLTRIM(regsfis)+" "+ALLTRIM(QRF.regimen) IN QDG
  ENDSCAN
  
  *-- Se reemplazan los conceptos por los que estan en el entorno (curConceptos)
  *
  *   VES Oct 10, 2011: Se elimino la clausula READWRITE para usar una tecnica 
  *   compatible con versiones de VFP anteriores a la 9
  *
  IF plReplaceCO
    SELECT cantidad, codigo as noId, descripcion as descripcio, "" as infoaduana, ;
  		   importe, unidad, precio_unit as valorunita, cuentapredial as nopredio ;
      FROM curConceptos ;
      INTO CURSOR QCOTEMP
    SELECT 0
    USE (DBF("QCOTEMP")) ALIAS QCO AGAIN
    USE IN QCOTEMP
  ENDIF 

  *-- Se anade una columna BANDA al cursor de conceptos
  *
  ALTER TABLE QCO ADD banda N (1)
  UPDATE QCO SET banda = 1


  *-- Se genera la banda de subtotal y descuento
  *
  INSERT INTO QCO (banda, descripcio, valorunita, importe) ;
           VALUES (2, "Sub / Total", 0.00, QDG.subtotal)

  IF QDG.descuento > 0
   INSERT INTO QCO (banda, descripcio, valorunita, importe) ;
            VALUES (2, QDG.motivoDesc, 0.00, -QDG.descuento)
  ENDIF



  *-- Se pasa la informacion de iva trasladado a la tabla de conceptos como banda-3
  *
  LOCAL cImpuesto,nTasa,nImporte
  SELECT QTR
  GO TOP
  SCAN
   *
   cImpuesto=impuesto
   nTasa=tasa
   nImporte=importe

   INSERT INTO QCO (banda, descripcio, valorunita, importe) ;
            VALUES (3, cImpuesto, nTasa, nImporte)
   *
   SELECT QTR
  ENDSCAN


  *-- Se pasa la informacion de retenciones a la tabla de conceptos como banda-4
  *
  LOCAL cImpuestoR,nImporteR
  SELECT QRE
  GO TOP
  SCAN
   *
   cImpuestoR="RET. " + ALLTRIM(impuesto)
   nImporteR=importe

   INSERT INTO QCO (banda, descripcio, valorunita, importe) ;
            VALUES (4, cImpuestoR, 0.00, nImporteR)
   *
   SELECT QRE
  ENDSCAN


  *-- Se genera la banda de total
  *
  INSERT INTO QCO (banda, descripcio, valorunita, importe) ;
           VALUES (5, "Total", 0.00, QDG.total)



  *-- Se prepara el cursor principal
  *
  SELECT QCO
  GO TOP
  

  *-- Se emite el reporte
  *
  *   VES Jul 21, 2012
  *   Se define una variable lResult para determinar en el caso
  *   especifico del modo PDF, si fue posible generar el archivo
  *   PDF o no
  *
  LOCAL cFormat, lResult
  cFormat = ALLT(CFDConf.formatoImpresion)
  lResult = .T.   && VES Jul 21, 2012
  
  DO CASE
     CASE plPreview
          REPORT FORM (cFormat) NOCONSOLE PREVIEW
          
     CASE plPDFMode AND CFDConf.usarPrint2PDF   && VES Jul 25, 2012
          Print2PDF(pcPDFTarget, cFormat)
          lResult = FILE(pcPDFTarget)  && VES Jul 25, 2012
          
     CASE plPDFMode AND !CFDConf.usarPrint2PDF   && Se utiliza PDFCreator
          pcPDFTarget = FULLPATH(pcPDFTarget)  && VES Ene 5, 2011
          LOCAL oPDF
          oPDF=CREATEOBJECT("PDFCreator.clsPDFCreator")
          oPDF.cStart()
          oPDF.cVisible=False
          oPDF.cClearCache()
          oPDF.cPrinterStop=False
          oPDF.cOption("AutosaveDirectory")=JUSTPATH(pcPDFTarget)
          oPDF.cOption("AutosaveFileName")=JUSTFNAME(pcPDFTarget)
          oPDF.cOption("UseAUtosave")=1
          oPDF.cOption("UseAutosaveDirectory")=1
          oPDF.cOption("AutosaveFormat")=0
          oPDF.cSaveOptions()

          SET PRINTER TO NAME PDFCreator
          REPORT FORM (cFormat) NOCONSOLE TO PRINT
          SET PRINTER TO
          
          SLEEP(3000)
          oPDF.cOption("UseAUtosave") = 0
          oPDF.cSaveOptions()
        
          lResult = FILE(pcPDFTarget)  && VES Jul 21, 2012
        
    
     
     OTHERWISE
          REPORT FORM (cFormat) NOCONSOLE PREVIEW IN SCREEN TO PRINT PROMPT
  ENDCASE
  
  
  *-- Se cierrn los cursores
  *
  USE IN QDG
  USE IN QCO
  USE IN QRE
  USE IN QTR
  USE IN QAD
  
 RETURN lResult   && VES Jul 21, 2012
 *
ENDPROC



*-- CFDNTOCESP
*   Convierte una cifra en letras en español, adaptado al uso especifico
*   en Mexico
*
*   Autor: V. Espina
*
PROC CFDNTOCESP(pnNumero,pcMoneda,pcPrefijo,pcSufijo)
 *
 *-- Se inicializan los parametros opcionales
 pcMoneda = IIF(VARTYPE(pcMoneda)="C",pcMoneda,CFDConf.NTOCMoneda)
 pcPrefijo = IIF(VARTYPE(pcPrefijo)="C",pcPrefijo,CFDConf.NTOCPrefijo)
 pcSufijo = IIF(VARTYPE(pcSufijo)="C",pcSufijo,CFDConf.NTOCSufijo)
 
 *-- Se definen algunos datos necesarios
 *
 dimen aFactores[4],aCentenas[10],aDecenas[10],aUnidades[10],aEspeciales[5]
 aFactores[1]=""
 aFactores[2]="MIL"
 aFactores[3]="MILLON"
 aFactores[4]="MIL MILLONES"
 aCentenas[1]=""
 aCentenas[2]="CIENTO"
 aCentenas[3]="DOSCIENTOS"
 aCentenas[4]="TRESCIENTOS"
 aCentenas[5]="CUATROCIENTOS"
 aCentenas[6]="QUINIENTOS"
 aCentenas[7]="SEISCIENTOS"
 aCentenas[8]="SETECIENTOS"
 aCentenas[9]="OCHOCIENTOS"
 aCentenas[10]="NOVECIENTOS"
 aDecenas[1]=""
 aDecenas[2]="DIEZ"
 aDecenas[3]="VEINTE"
 aDecenas[4]="TREINTA"
 aDecenas[5]="CUARENTA"
 aDecenas[6]="CINCUENTA"
 aDecenas[7]="SESENTA"
 aDecenas[8]="SETENTA"
 aDecenas[9]="OCHENTA"
 aDecenas[10]="NOVENTA"
 aUnidades[1]=""
 aUnidades[2]="UNO"
 aUnidades[3]="DOS"
 aUnidades[4]="TRES"
 aUnidades[5]="CUATRO"
 aUnidades[6]="CINCO"
 aUnidades[7]="SEIS"
 aUnidades[8]="SIETE"
 aUnidades[9]="OCHO"
 aUnidades[10]="NUEVE"
 aEspeciales[1]="ONCE"
 aEspeciales[2]="DOCE"
 aEspeciales[3]="TRECE"
 aEspeciales[4]="CATORCE"
 aEspeciales[5]="QUINCE"
   
   
   
 *-- Se construye la parte entera de la cifra
 *
 local cCifra1,cLetras,nFact,nTercio,nCount,nFactor,nCentana,nDecena,nUnidad
 cCifra1=","+ltrim(trans(int(pnNumero),"999,999,999,999,999,999"))
 nCount=occurs(",",cCifra1)
 cLetras=""
   
 for nTercio=1 to nCount
  cTercio=subs(cCifra1,rat(",",cCifra1)+1,3)
  cCifra1=subs(cCifra1,1,rat(",",cCifra1)-1)
  nBase=int(val(cTercio))
   
  nCentena=int(nBase / 100)
  nBase=nBase - (int(nBase / 100) * 100)
  nDecena=int(nBase / 10)
  nUnidad=nBase - (int(nBase / 10) * 10)
  cFactor=aFactores[nTercio]
  if nTercio=3 and (nBase > 1 OR nDecena > 0 OR nCentena > 0)
   cFactor="MILLONES"
  endif
   
  cCentena=aCentenas[nCentena + 1]
  if nDecena > 1 or nUnidad=0
   cDecena=aDecenas[nDecena + 1]
   cUnidad=aUnidades[nUnidad + 1]
  else
   if nDecena=1 and between(nUnidad,1,5)
    cDecena=aEspeciales[nUnidad]
    cUnidad=""
   else
    cDecena=iif(nDecena=1,"DIEZ","")
    cUnidad=aUnidades[nUnidad + 1]
   endif
  endif
   
  do case
     case nCentena > 0 and nDecena=0 and nUnidad=0
          if nCentena = 1
           cTercio="CIEN "
          else
           cTercio=cCentena + " "
          endif
   
     case nCentena=0 and nDecena=0
          if nUnidad = 1
           if not empty(cFactor)
            cTercio="UN "
           else
            cTercio="UNO "
           endif
          else
           cTercio=cUnidad + " "
          endif
   
     otherwise
 		 cTercio=iif(not empty(cCentena),cCentena + " ","") + ;
 		         iif(not empty(cDecena),cDecena + " ","") + ;
 		         iif(not empty(cUnidad),iif(empty(cDecena),cUnidad,"Y "+cUnidad)+" ","")
  endcase
   
  if not empty(cTercio) 
   cLetras=cTercio + cFactor + " " + cLetras
  endif
   
 endfor
   
   
 *-- Se añaden los decimales
 *
 local nDec
 nDec=(pnNumero - int(pnNumero)) * 100
   
 cLetras=pcPrefijo + " " + PROPER(RTRIM(cLetras)) + " " + pcMoneda + " con "+PADL(INT(nDec),2,"0") + "/100 " + pcSufijo
 
 cLetras=ALLTRIM(STRT(cLetras,"  "," "))
   
 return cLetras
 *
ENDPROC




*-- CFDExtraerCadenaOriginal (Funcion)
*   Permite extraer la cadena original de un comprobante en formato XML
*
*   Basado en el codigo original de Arturo Ramos
*
FUNCTION CFDExtraerCadenaOriginal(pcXML, pcOpenSSL)
 *
 CFDConf.ultimoError = ""  
 
 *-- Se verifica que el archivo exista
 IF EMPTY(pcXML) OR NOT FILE(pcXML) 
  CFDConf.ultimoError = "El archivo indicado no existe"
  RETURN ""
 ENDIF
 
 *-- Se verifica que la carpeta indicada contenga el archivo OPENSSL.EXE
 IF EMPTY(pcOpenSSL)
  pcOpenSSL = CFDConf.openSSL
 ENDIF
 IF EMPTY(pcOpenSSL) OR NOT FILE(ADDBS(pcOpenSSL) + "OPENSSL.EXE")
  CFDConf.ultimoError = "No se encontro el archivo OPENSSL.EXE en la ruta indicada"
  RETURN ""
 ENDIF
 pcOpenSSL = ADDBS(FULLPATH(pcOpenSSL))
 
 
 
 *-- Se prepara un archivo BAT con los comandos a ejecutar
 LOCAL cBATFile,cCADFile,cXSLFile,cXSLTProc,cBuff
 cBATFile = GetTempfile("BAT") 
 cCADFile = FORCEEXT(cBATFile,"CAD")
 cXSLFile = FORCEEXT(cBATFile,"XSLT")
 cXSLTProc = GetShortName(pcOpenSSL + "XSLTPROC.EXE")
 
 
 *-- VES Ene 12, 2011: Se obtiene la version del XML. Esto se hace porque puede
 *   pasar que la version del XML difiera de la version indicada en CFDConf.XMLVersion
 LOCAL cBuff,nXMLVersion
 cBuff=FILETOSTR(pcXML)
 cBuff=SUBS(cBuff,AT("Comprobante ",cBuff))
 cBuff=LEFT(cBuff,AT(">",cBuff))
 cBuff=SUBS(cBuff,ATC("version",cBuff))
 cBuff=LEFT(cBuff,AT(" ",cBuff) - 1)
 cBuff=CHRT(LOWER(cBuff),[version="],"")
 nXMLVersion = CFDVersions.fromString(cBuff) 

 
  
 *-- ARC Dic 27, 2011: Define el XSLT local a utilizar
 *   VES Ene 12, 2012: Se cambio CFDConf.XMLVersion por nXMLVersion
 DO CASE 
 	CASE nXMLversion = CFDVErsions.CFD_20
 		cXsltFile = "cadenaoriginal_2_0_local.xslt"
 	CASE nXMLversion = CFDVersions.CFDi_30
 		cXsltFile = "cadenaoriginal_3_0_local.xslt"
 	CASE nXMLversion = CFDVersions.CFD_22
 		cXsltFile = "cadenaoriginal_2_2_local.xslt"
 	CASE nXMLversion = CFDVersions.CFDi_32
 		cXsltFile = "cadenaoriginal_3_2_local.xslt"
 ENDCASE 
 cBuff = FILETOSTR(pcOpenSSL + cXsltFile)
 cBuff = STRT(cBuff,"<ssl-path>",CHRT(pcOpenSSL,"\","/"))
 STRTOFILE(cBuff, cXSLFile)

 cBuff = cXSLTProc + " {xsltFile} {xmlFile} > {cadFile}" + CRLF
 cBuff = STRT(cBuff,"{xsltFile}",GetShortName(FULLPATH(cXSLFile)))
 cBuff = STRT(cBuff,"{xmlFile}",GetShortName(FULLPATH(pcXML))) 
 cBuff = STRT(cBuff,"{cadFile}",cCADFile)  
 STRTOFILE(cBuff,cBATFile)


 *-- Se ejecuta el BAT
 LOCAL oWSH
 oWSH = CREATEOBJECT("WScript.Shell") 
 oWSH.Run(cBATFile, 0, .T.)
 
 *-- Se obtiene la cadena original
 LOCAL cCadenaOriginal
 cCadenaOriginal = ""
 IF FILE(cCADFile)
  cCadenaOriginal = CFDUTF82Asc(FILETOSTR(cCADFile))
 ELSE
  CFDConf.ultimoError = "Ocurrio un error inesperado al obtener la cadena original"
  cCadenaOriginal=""
 ENDIF
 
 ERASE (cCADFile)
 IF !EMPTY(cCadenaOriginal)
  ERASE (cBATFile)
  ERASE (cXSLFile)
 ENDIF 
 
 RETURN cCadenaOriginal
 *
ENDPROC




*-- CFDEnviarPorCorreo
*   Envia CFD por correo. Si se indica .T. en el parametro opcional plAdjuntarPDF, se asumira
*   que el archivo indicado en pcCFD es un XML y se procedera a generar una representacion 
*   PDF del mismo, que se adjuntara conjuntamente con el XML.
*
PROCEDURE CFDEnviarPorCorreo(pcDestinatario, pcAsunto, pcCuerpo, pcCFD, plAdjuntarPDF)
 *
 * Se prepara la configuracion a utilizar
 *
 LOCAL lcSchema, loConfig, loMsg
 lcSchema = "http://schemas.microsoft.com/cdo/configuration/"
 loConfig = CREATEOBJECT("CDO.Configuration")
 WITH loConfig.FIELDS
  .ITEM(lcSchema + "smtpserver") = CFDConf.SMTPServer
  .ITEM(lcSchema + "smtpserverport") = CFDConf.SMTPPort
  .ITEM(lcSchema + "sendusing") = 2
  .ITEM(lcSchema + "smtpauthenticate") = .T.
  .ITEM(lcSchema + "smtpusessl") = CFDConf.SMTPUseSSL
  .ITEM(lcSchema + "sendusername") = CFDConf.SMTPUserName
  .ITEM(lcSchema + "sendpassword") = CFDConf.SMTPPassword
  .UPDATE()
 ENDWITH


 * Se prepara el mensaje
 *
 loMsg = CREATEOBJECT("CDO.Message")
 WITH loMsg
  .Configuration = loConfig
  .FROM = CFDConf.MailSender
  .TO = pcDestinatario
  .Subject = pcAsunto
  .HTMLBody = pcCuerpo
  .addAttachment(FULLPATH(pcCFD))
 ENDWITH
 
 
 *-- Si se indico el parametro plAdjuntarPDF se genera un PDF
 *   del CDF y se adjunta al correo
 *
 IF plAdjuntarPDF
  *
  LOCAL cPDF
  cPDF = FORCEEXT(pcCFD,"PDF")
  CFDPrint(pcCFD,,.T.,cPDF)
  loMsg.addAttachment(FULLPATH(cPDF))
  *
 ENDIF


 * Se envia el mensaje
 *
 loMsg.Send()


 *-- Se liberan recursos
 loMsg = NULL
 loConfig = NULL
 *
ENDPROC


*-- CFDEnviarPorCorreoAdjuntos
*   Envia CFD por correo. A diferencia de CFDEnviarPorCorreo esta permite
*   adjuntar el PDF ya creado lo cuál es útil cuando se utilizan diferente
*   formatos para la representación impresa o para enviar comprobantes
*   que no generó nuestro sistema como puede ser el caso de algunos PACs
*   que junto con el timbre regresan el PDF
*
PROCEDURE CFDEnviarPorCorreoAdjuntos(pcDestinatario, pcAsunto, pcCuerpo, pcCFD, pcPDF)
 *
 * Se prepara la configuracion a utilizar
 *
 LOCAL lcSchema, loConfig, loMsg
 lcSchema = "http://schemas.microsoft.com/cdo/configuration/"
 loConfig = CREATEOBJECT("CDO.Configuration")
 WITH loConfig.FIELDS
  .ITEM(lcSchema + "smtpserver") = CFDConf.SMTPServer
  .ITEM(lcSchema + "smtpserverport") = CFDConf.SMTPPort
  .ITEM(lcSchema + "sendusing") = 2
  .ITEM(lcSchema + "smtpauthenticate") = .T.
  .ITEM(lcSchema + "smtpusessl") = CFDConf.SMTPUseSSL
  .ITEM(lcSchema + "sendusername") = CFDConf.SMTPUserName
  .ITEM(lcSchema + "sendpassword") = CFDConf.SMTPPassword
  .UPDATE()
 ENDWITH


 * Se prepara el mensaje
 *
 loMsg = CREATEOBJECT("CDO.Message")
 WITH loMsg
  .Configuration = loConfig
  .FROM = CFDConf.MailSender
  .TO = pcDestinatario
  .Subject = pcAsunto
  .HTMLBody = pcCuerpo
  IF FILE(FULLPATH(pcCFD))
    .addAttachment(FULLPATH(pcCFD))
  ENDIF 
  IF FILE(FULLPATH(pcPDF))
    .addAttachment(FULLPATH(pcPDF))
  ENDIF 
 ENDWITH
 
 
 * Se envia el mensaje
 *
 loMsg.Send()


 *-- Se liberan recursos
 loMsg = NULL
 loConfig = NULL
 *
ENDPROC





*-- GetShortName
*   Devuelve un nombre de archivo en formato 8.3 para
*   un nombre de archivo largo dado
*
PROCEDURE GetShortName(pcLongPath)
 *
 IF NOT FILE(pcLongPath)
  MESSAGEBOX("No se pudo encontrar el archivo:" + REPL(CHR(13) + CHR(10),2) + LOWER(pcLongPath),16,"GetShortName")
  RETURN pcLongPath
 ENDIF
 
 LOCAL oFSO, oFI, cShortPath
 oFSO = CreateObject("Scripting.FileSystemObject")
 oFI = oFSO.getFile(pcLongPath)
 cShortPath = oFI.shortPath
 oFI = NULL
 oFSO = NULL
 
 RETURN cShortPath 
 *
ENDPROC




*-- GetTempFile
*   Crea un archivo temporal con la extension indicada
*
FUNCTION GetTempFile(pcExt)
 *
 IF PCOUNT() = 0
  pcExt = "TMP"
 ENDIF
 
 LOCAL cTempFile
 DO WHILE .T.
  cTempFile = FULLPATH(LEFT(SYS(2015),8) + "." + pcExt)
  IF NOT FILE(cTempFile)
   STRTOFILE("",cTempFile)
   EXIT
  ENDIF
 ENDDO  
 
 RETURN GetShortName(cTempFile)
 *
ENDFUNC


********************************************************************************************


*-- CFDLeerCertificado (Funcion)
*   Lee un certificado indicado y devuelve una instancia de la clase CFDCertificado.
*
*   Autor: Arturo Ramos / Victor Espina
*
FUNCTION CFDLeerCertificado(pcArchivoCER, pcOpenSSL)
 *
 CFDConf.UltimoError = ""
  
 *-- Se verifica que la carpeta indicada contenga el archivo OPENSSL.EXE
 IF EMPTY(pcOpenSSL)
  pcOpenSSL = CFDConf.openSSL
 ENDIF
 IF EMPTY(pcOpenSSL) OR NOT FILE(ADDBS(pcOpenSSL) + "OPENSSL.EXE")
  CFDConf.ultimoError = "No se encontro el archivo OPENSSL.EXE en la ruta indicada"
  RETURN NULL
 ENDIF
 pcOpenSSL = GetShortName(ADDBS(FULLPATH(pcOpenSSL)) + "OPENSSL.EXE")
 
 
 *-- Se prepara un archivo BAT con los comandos a ejecutar
 LOCAL cBATFile,cTempFile
 cBATFile = GetTempFile("BAT")
 cTempFile = JUSTSTEM(cBATFile)
 
 LOCAL cBuff
 cBuff = pcOpenSSL + " x509 -inform DER -outform PEM -in {cerFile} -pubkey > {tempFile}.pem " + CRLF + ;
         pcOpenSSL + " x509 -in {tempFile}.pem -serial -noout > {tempFile}.ser" + CRLF + ;
         pcOpenSSL + " x509 -inform DER -in {cerFile} -noout -startdate > {tempFile}.sta" +  + CRLF + ;
 		 pcOpenSSL + " x509 -inform DER -in {cerFile} -noout -enddate > {tempFile}.end" + CRLF 
 		 
 cBuff = STRT(cBuff,"{cerFile}",GetShortName(FULLPATH(pcArchivoCER)))
 cBuff = STRT(cBuff,"{tempFile}",cTempFile)
 STRTOFILE(cBuff,cBATFile)
 
 *-- Se ejecuta el BAT
 LOCAL oWSH
 oWSH = CREATEOBJECT("WScript.Shell") 
 oWSH.Run(cBATFile, 0, .T.)
 
 IF !FILE(cTempFile + ".PEM") OR !FILE(cTempFile + ".SER") OR !FILE(cTempFile + ".STA") OR !FILE(cTempFile + ".END")
  CFDConf.ultimoError = "Ocurrio un error al intentar leer el certificado indicado"
  ERASE (cTempFile + ".*")
  RETURN NULL
 ENDIF
 
 
 *-- Se crea el objeto a devolver
 LOCAL oData
 oData = CREATEOBJECT("CFDCertificado")
 oData.Archivo = ALLT(LOWER(pcArchivoCER))
 oData.Valido = .F.
 oData.Vigente = .F.
 oData.Certificado = ""
 oData.Serial = ""
 oData.vigenteDesde = {//::}
 oData.vigenteHasta = {//::}
 
 
 *-- Se extrae la informacion del certificado 
 LOCAL cCert
 cCert = FILETOSTR(cTempFile + ".PEM")
 cCert = SUBS(cCert,AT("-----BEGIN CERTIFICATE-----",cCert))
 cCert = STRTRAN(cCert,"-----BEGIN CERTIFICATE-----","")
 cCert = STRTRAN(cCert,"-----END CERTIFICATE-----","")
 *-- Quita saltos de linea y retornos de carro del certificado
 cCert = STRTRAN(cCert,CHR(13))
 cCert = STRTRAN(cCert,CHR(10))
 oData.Certificado = cCert


 *-- Se extrae el numero de serie del certificado
 LOCAL cSerie
 cSerie = FILETOSTR(cTempfile + ".SER")  
 cSerie = STRTRAN(cSerie,"serial=","")
 cSerie = STRTRAN(cSerie,CHR(10),"")
 cSerie = HEX2STR(cSerie)
 oData.Serial = cSerie
 
 
 *-- Se extraen las fechas de vigencia
 oData.vigenteDesde = FCTOT(cTempFile + ".STA")
 oData.vigenteHasta = FCTOT(cTempFile + ".END") 


 *-- Se completan algunos datos
 oData.Valido = (!EMPTY(oData.certificado))
 oData.Vigente = BETWEEN(DATETIME(), oData.vigenteDesde, oData.vigenteHasta)

 *-- Se eliminan los temporales creados
 ERASE (cTempFile + ".*")
 
 
 RETURN oData
 * 
ENDFUNC


*-- CFDVigenciaCert (Funcion)
*   Permite validar la caducidad del certificado
*   
*   Autor: Arturo Ramos / Victor Espina
*
FUNCTION CFDVigenciaCert(pcCER, ptFechaComp, pcOpenSSL)
 *
 * pcCER 		- archivo .cer
 * pcFechaComp 	- fecha de emisión del comprobante
 * pcOpenSSL	- path del openssl.exe
  
 *-- Se obtiene la informacion del certificado
 LOCAL oCert
 oCert = CFDLeerCertificado(pcCer,pcOpenSSL)
 IF ISNULL(oCert)
  RETURN .F.
 ENDIF
   
 CFDConf.UltimoError = ""
 
 
 *-- Se validan las fechas
 LOCAL lResult
 lResult = .T.

 IF VARTYPE(ptFechaComp) = "D"
  ptFechaComp = DTOT(ptFechaComp)
 ENDIF
  
 IF ptFechaComp < oCert.vigenteDesde THEN 
    CFDConf.ultimoError = "La fecha del comprobante es anterior a la vigencia del certificado."
 	lResult = .F.
 ENDIF 
 
 IF ptFechaComp > oCert.vigenteHasta THEN 
 	CFDConf.ultimoError = "La fecha del comprobante es posterior a la vigencia del certificado."
 	lResult = .F.
 ENDIF 
 	 
 RETURN lResult
 *
ENDPROC


*-- FCTOT (función)
*   Regresa Fecha y hora del archivo de vigencia generado con openssl obtenido del certificado
*   Al verificar la vigencia del certificado se obtienen dos archivos de texto que se pasan como parametro a la función
*   openssl.exe x509 -inform DER -in "aaa010101aaa_CSD_01.cer" -noout -enddate > "FinVigencia.txt"
*   openssl.exe x509 -inform DER -in "aaa010101aaa_CSD_01.cer" -noout -startdate > "IniciaVigencia.txt"
*
*   Basado en el código de Hugo Carlos Aguilar / Juan francisco Castro
*
*   Simplificado y adaptado a VFP6 por Victor Espina
*
Function FCTOT(pcArchivo)
 *
 LOCAL cData,cYY,cMM,cDD,cTT
 cData = CHRT(FILETOSTR(pcArchivo),CHR(13)+CHR(10),"")
 cData = SUBS(cData, AT("=",cData) + 1)
 cData = ALLT(STRT(cData,"GMT",""))
 
 cYY = RIGHT(cData,4)
 cMM = UPPER(LEFT(cData,3))
 cMM = STRT(STRT(STRT(STRT(STRT(STRT(cMM,"JAN","01"),"FEB","02"),"MAR","03"),"APR","04"),"MAY","05"),"JUN","06")
 cMM = STRT(STRT(STRT(STRT(STRT(STRT(cMM,"JUL","07"),"AUG","08"),"SEP","09"),"OCT","10"),"NOV","11"),"DEC","12")
 cDD = ALLT(SUBS(cData,5))
 cDD = PADL(LEFT(cDD,AT(" ",cDD) - 1),2,"0")
 cTT = LEFT(SUBS(cData,AT(":",cData) - 2),8)
 
 LOCAL cSetDate,tFechaHora
 cSetDate = SET("DATE")
 SET DATE YMD
 tFechaHora = CTOT(cYY + "-" + cMM + "-" + cDD + " " + cTT)
 IF cSetDate<>"YMD"
  SET DATE (cSetDate)
 ENDIF
 
 RETURN tFechaHora
 *
Endfunc



*-- CFDValidarKeyCer (Funcion)
*   Valida que los archivos KEY y CER indicados sean complementarios
*
*   Autor: Victor Espina
*
FUNCTION CFDValidarKeyCer(pcArchivoKEY, pcArchivoCER, pcPassword, pcOpenSSL)
 *
 CFDConf.UltimoError = ""
  
 *-- Se verifica que la carpeta indicada contenga el archivo OPENSSL.EXE
 IF EMPTY(pcOpenSSL)
  pcOpenSSL = CFDConf.openSSL
 ENDIF
 IF EMPTY(pcOpenSSL) OR NOT FILE(ADDBS(pcOpenSSL) + "OPENSSL.EXE")
  CFDConf.ultimoError = "No se encontro el archivo OPENSSL.EXE en la ruta indicada"
  RETURN .F.
 ENDIF
 pcOpenSSL = GetShortName(ADDBS(FULLPATH(pcOpenSSL)) + "OPENSSL.EXE")
 
 
 *-- Se prepara un archivo BAT con los comandos a ejecutar
 LOCAL cBATFile,cTempFile
 cBATFile = GetTempFile("BAT")
 cTempFile = JUSTSTEM(cBATFile)
 
 LOCAL cBuff
 cBuff = pcOpenSSL + " x509 -inform DER -in {cerFile} -noout -modulus > {tempFile}.m1" + CRLF + ;
         pcOpenSSL + " pkcs8 -inform DER -in {keyFile} -passin pass:{password} -out {tempFile}.pem" + CRLF + ;
         pcOpenSSL + " rsa -in {tempFile}.pem -noout -modulus > {tempFile}.m2" + CRLF + ;
         "DEL {tempFile}.pem" + CRLF
 		 
 cBuff = STRT(cBuff,"{cerFile}",GetShortName(FULLPATH(pcArchivoCER)))
 cBuff = STRT(cBuff,"{keyFile}",GetShortName(FULLPATH(pcArchivoKEY)))
 cBuff = STRT(cBuff,"{password}",pcPassword)
 cBuff = STRT(cBuff,"{tempFile}",cTempFile)
 STRTOFILE(cBuff,cBATFile)
 

 
 *-- Se ejecuta el BAT
 LOCAL oWSH
 oWSH = CREATEOBJECT("WScript.Shell") 
 oWSH.Run(cBATFile, 0, .T.)
 
 IF !FILE(cTempFile + ".M1") OR !FILE(cTempFile + ".M2") 
  CFDConf.ultimoError = "Ocurrio un error al intentar validar los archivos KEY y/o CER"
  ERASE (cTempFile + ".*")
  RETURN .F.
 ENDIF

 LOCAL cCerMod, cKeyMod
 cCerMod = FILETOSTR(cTempFile + ".m1")
 cKeyMod = FILETOSTR(cTempFile + ".m2")
 
 IF EMPTY(cCerMod)
  CFDConf.ultimoError = "No se pudo obtener el modulus del archivo CER"
  ERASE (cTempFile + ".*")
  RETURN .F.
 ENDIF 
 
 IF EMPTY(cKeyMod)
  CFDConf.ultimoError = "No se pudo obtener el modulus del archivo KEY (verifique la contraseña)"
  ERASE (cTempFile + ".*")
  RETURN .F.
 ENDIF 
 
 LOCAL lValid
 lValid = (cCerMod == cKeyMod)
 IF NOT lValid
  CFDConf.ultimoError = "El archivo KEY no corresponde con el archivo CER indicado"
 ENDIF
 

 *-- Se eliminan los temporales creados
 ERASE (cTempFile + ".*")
 
 
 RETURN lValid
 * 
ENDFUNC




*-- CFDValidarXML (Funcion)
*   Analiza un XML indicado y verifica que este bien formado y que
*   cumpla con los requisitos del SAT
*
*   El parametro pcMetodo debe ser "md5" o "sha1"
*
*   NOTA IMPORTANTE: Esta función valida el sello del comprobante cuando se
*   tiene el archivo .key (con su password) con el que se sello el comprobante originalmente.
*
FUNCTION CFDValidarXML(pcArchivoXML, pcArchivoKey, pcPassword, pcMetodo, pcOpenSSL)
 *
 CFDConf.ultimoError = ""
 
 *-- Se verifica que la carpeta indicada contenga el archivo OPENSSL.EXE
 IF EMPTY(pcOpenSSL)
  pcOpenSSL = CFDConf.openSSL
 ENDIF
 IF EMPTY(pcOpenSSL) OR NOT FILE(ADDBS(pcOpenSSL) + "OPENSSL.EXE")
  CFDConf.ultimoError = "No se encontro el archivo OPENSSL.EXE en la ruta indicada"
  RETURN .F.
 ENDIF
 pcOpenSSL = GetShortName(ADDBS(FULLPATH(pcOpenSSL)) + "OPENSSL.EXE")



 *-- Se verifica que el XML este bien formado
 LOCAL oXML
 oXML = CREATEOBJECT('MSXML2.DOMdocument')
 oXML.Load(GetShortName(pcArchivoXML))
 IF oXML.parseError.errorCode <> 0
  CFDConf.ultimoError = "Estructura XML mal armada. "+oXML.parseError.reason
  RETURN .F.
 ENDIF

 *-- Obtiene el nombre del nodo root, puede ser 'Comprobante' para CFD o 'cfdi:Comprobante' para CFDI
 *
 *   ARC Dic 27, 2011: Se adapta para obtener la version del comprobante desde el atributo version del XML
 *                     el atributo puede ser del nodo Comprobante para CFD 2.0 y 2.2 o del
 *                     nodo cfdi:Comprobante para CFDI 3.0 y 3.2
 *
 oRootNode = oXML.documentElement
 cRootTagName = oRootNode.tagName
 
 * Selecciona el nodo root para sacar el atributo version
 olNode = oXML.selectSingleNode("//"+cRootTagName)
 IF ISNULL(olNode) THEN 
   MESSAGEBOX("XML inválido."+CHR(13)+"Nodo //"+cRootTagName+" no presente.", 16, "Sistema")
   lResult = .F.
   RETURN .F.
 ENDIF

 sAtributeValue = olNode.getAttribute("version")

 DO CASE 
   CASE sAtributeValue = "2.0"
     lcXSDFilev = "cfdv2.xsd"
     lcURLXSDv = "http://www.sat.gob.mx/sitio_internet/cfd/2/cfdv2.xsd"
     lcURLXNSv  = "http://www.sat.gob.mx/cfd/2"   

   CASE sAtributeValue = "3.0"
     lcXSDFilev = "cfdv3.xsd"
     lcURLXSDv  = "http://www.sat.gob.mx/sitio_internet/cfd/3/cfdv3.xsd"
     lcURLXNSv  = "http://www.sat.gob.mx/cfd/3"
    
   CASE sAtributeValue = "2.2"
     lcXSDFilev = "cfdv22.xsd"
     lcURLXSDv = "http://www.sat.gob.mx/sitio_internet/cfd/2/cfdv22.xsd"
     lcURLXNSv  = "http://www.sat.gob.mx/cfd/2"   

   CASE sAtributeValue = "3.2"
     lcXSDFilev = "cfdv32.xsd"
     lcURLXSDv  = "http://www.sat.gob.mx/sitio_internet/cfd/3/cfdv32.xsd"
     lcURLXNSv  = "http://www.sat.gob.mx/cfd/3"
 ENDCASE  
 
 
 *-- Si no se cuenta con una copia local del XSD, se descarga
 IF NOT FILE(lcXSDFilev)
  STRTOFILE(GetURL(lcURLXSDv), lcXSDFilev)
 ENDIF
 
 *-- Se valida el XML cumpla con los standares del CFD/CFDI
 LOCAL lResult
 lResult = .F.
 DO CASE
    CASE FILE(ADDBS(JUSTPATH(pcOpenSSL)) + "CFDVALIDATOR.EXE") AND ;
         FILE(ADDBS(JUSTPATH(pcOpenSSL)) + "Interop.MSXML2.dll")
		 LOCAL cBATFile,cTempFile
		 cBATFile = GetTempFile("BAT")
		 cTempFile = JUSTSTEM(cBATFile)
		 
		 LOCAL cValidator,cBuff
		 cValidator = GetShortName(ADDBS(JUSTPATH(pcOpenSSL)) + "CFDVALIDATOR.EXE")
		 cBuff = cValidator + " -xml:{xmlFile} -xsd:{xsdFile} -xns:{xnsURL} > {tempFile}.out" + CRLF
		 		 
		 cBuff = STRT(cBuff,"{xmlFile}",GetShortName(pcArchivoXML))
		 cBuff = STRT(cBuff,"{xsdFile}",GetShortName(FULLPATH(lcXSDFilev)))
		 cBuff = STRT(cBuff,"{xnsURL}",lcURLXNSv)
		 cBuff = STRT(cBuff,"{tempFile}",cTempFile)
		 STRTOFILE(cBuff,cBATFile)

		 LOCAL oWSH
		 oWSH = CREATEOBJECT("WScript.Shell") 
		 oWSH.Run(cBATFile, 0, .T.)
		 
		 IF NOT FILE(cTempFile + ".OUT")
		  lResult = .F.
		  CFDConf.ultimoError = "Ocurrio un error al intentar validar el XML indicado"
		 ELSE 
		  CFDConf.ultimoError = FILETOSTR(cTempFile + ".OUT")
		  CFDConf.ultimoError = "Estructura XML mal armada. "+STRT(CFDConf.ultimoError,"[FATAL]","[ERROR]")
		  lResult = (AT("[ERROR]",CFDConf.ultimoError) = 0)
		 ENDIF
		 
		 ERASE (cTempFile + ".*")
    
    
    
    OTHERWISE
		 LOCAL oXmlDoc, oXmlSchema
		 oXmlSchema = CREATEOBJECT("MSXML2.XMLSchemaCache.6.0")
		 oXmlSchema.validateOnLoad = .T.
		 oXmlSchema.Add(lcURLXNSv, FULLPATH(lcXSDFilev))
		 oXmlDoc = CREATEOBJECT("MSXML2.DOMDocument.6.0")
		 oXmlDoc.validateOnParse = .T.
		 oXmlDoc.schemas = oXmlSchema
		 oXmlDoc.async = .F.
		 IF NOT oXmlDoc.Load(GetShortName(pcArchivoXML))
		  CFDConf.ultimoError = oXmlDoc.parseError.reason
		  lResult = .F.
		 ELSE
		  lResult = .T. 
		 ENDIF
		 oXmlDoc = NULL
		 oXmlSchema = NULL
    
 ENDCASE
 
 
 *-- Se valida el sello (solo si el XML esta OK)
 *
 IF lResult AND !EMPTY(pcArchivoKey)
  *
  LOCAL cSelloActual,cCadenaOriginal,cSelloCorrecto
  cSelloActual = MSXMLGetAttribute(oXML.selectNodes("//"+cRootTagName), "sello")
  cCadenaOriginal = CFDExtraerCadenaOriginal(pcArchivoXML, JUSTPATH(pcOpenSSL))
  cSelloCorrecto = CFDGenerarSello(cCadenaOriginal, pcArchivoKey, pcPassword, pcMetodo, JUSTPATH(pcOpenSSL))
 
  IF NOT cSelloActual == cSelloCorrecto
   CFDConf.ultimoError = CFDConf.ultimoError + ;
                         IIF(EMPTY(CFDConf.ultimoError),"",CHR(13)+CHR(10))+ ;
                         "[ERROR] El sello no es valido para este certificado." + CHR(13) + CHR(10)
   _cliptext = cCadenaOriginal
   lResult = .F.
  ENDIF
  *
 ENDIF
 
 
 RETURN lResult
 *
ENDFUNC




***********************************************
** GETURL.PRG
** Devuelve el contenido de un URL dado.
**
** Versión: 1.0
**
** Autor: Victor Espina (vespinas@cantv.net)
**        Walter Valle (wvalle@develcomp.com)
**        (basado en código original de Pablo Almunia)
*
** Fecha: 20-Agosto-2003
**
**
** Sintáxis:
** cData = GetURL(pcURL[,plVerbose])
**
** Donde:
** cData	 Contenido (texto o binario) del recurso
**			 indicado en cURL. Si ocurre algún error
**           se devolverá la cadena vacia.
** pcURL	 Dirección URL del recurso o archivo a obtener
** plVerbose Opcional. Si se establece en True, se mostrará
**		     información visual sobre el avance del proceso.
**
** Ejemplo:
** cHTML=GetURL("http://www.portalfox.com")
**
*************************************************
**
** GETURL.PRG
** Returns the contains of any given URL
**
** Version: 1.0
**
** Author: Victor Espina (vespinas@cantv.net)
**         Walter Valle (wvalle@develcomp.com)
**         (based on original source code from Pablo Almunia)
*
** Date: August 20, 2003
**
**
** Syntax:
** cData = GetURL(pcURL[,plVerbose])
**
** Where:
** cData	 Contents (text or binary) of requested URL.
** pcURL	 URL of the requested resource or file. If an
**           error occurs, a empty string will be returned.
** plVerbose Optional. If setted to True, progress info
**			 will be shown.
**
** Example:
** cHTML=GetURL("http://www.portalfox.com")
**
**************************************************
PROCEDURE GetURL
LPARAMETER pcURL,plVerbose
 *
 *-- Se definen las funciones API necesarias
 *
 #DEFINE INTERNET_OPEN_TYPE_PRECONFIG     0
 DECLARE LONG GetLastError IN WIN32API
 DECLARE INTEGER InternetCloseHandle IN "wininet.dll" ;
	LONG hInet
 DECLARE LONG InternetOpen IN "wininet.dll" ;
  STRING   lpszAgent, ;
  LONG     dwAccessType, ;
  STRING   lpszProxyName, ;
  STRING   lpszProxyBypass, ;
  LONG     dwFlags
 DECLARE LONG InternetOpenUrl IN "wininet.dll" ;
    LONG    hInet, ;
 	STRING  lpszUrl, ;
	STRING  lpszHeaders, ;
    LONG    dwHeadersLength, ;
    LONG    dwFlags, ;
    LONG    dwContext
 DECLARE LONG InternetReadFile IN "wininet.dll" ;
	LONG     hFtpSession, ;
	STRING  @lpBuffer, ;
	LONG     dwNumberOfBytesToRead, ;
	LONG    @lpNumberOfBytesRead
	
	
 *-- Se establece la conexión con internet
 *
 IF plVerbose
  WAIT "Opening Internet connection..." WINDOW NOWAIT
 ENDIF
 
 LOCAL nInetHnd
 nInetHnd = InternetOpen("GETURL",INTERNET_OPEN_TYPE_PRECONFIG,"","",0)
 IF nInetHnd = 0
  RETURN ""
 ENDIF
 
 
 *-- Se establece la conexión con el recurso
 *
 IF plVerbose
  WAIT "Opening connection to URL..." WINDOW NOWAIT
 ENDIF
 
 LOCAL nURLHnd
 nURLHnd = InternetOpenUrl(nInetHnd,pcURL,NULL,0,0,0)
 IF nURLHnd = 0
  InternetCloseHandle( nInetHnd )
  RETURN ""
 ENDIF


 *-- Se lee el contenido del recurso
 *
 LOCAL cURLData,cBuffer,nBytesReceived,nBufferSize
 cURLData=""
 cBuffer=""
 nBytesReceived=0
 nBufferSize=0

 DO WHILE .T.
  *
  *-- Se inicializa el buffer de lectura (bloques de 2 Kb)
  cBuffer=REPLICATE(CHR(0),2048)
  
  *-- Se lee el siguiente bloque
  InternetReadFile(nURLHnd,@cBuffer,LEN(cBuffer),@nBufferSize)
  IF nBufferSize = 0
   EXIT
  ENDIF
  
  *-- Se acumula el bloque en el buffer de datos
  cURLData=cURLData + SUBSTR(cBuffer,1,nBufferSize)
  nBytesReceived=nBytesReceived + nBufferSize
  
  IF plVerbose
   WAIT WINDOW ALLTRIM(TRANSFORM(INT(nBytesReceived / 1024),"999,999")) + " Kb received..." NOWAIT
  ENDIF
  *
 ENDDO
 IF plVerbose
  WAIT CLEAR
 ENDIF

 
 *-- Se cierra la conexión a Internet
 *
 InternetCloseHandle( nInetHnd )

 *-- Se devuelve el contenido del URL
 *
 RETURN cURLData
 *
ENDPROC



*-- CFDGenerarSello (Funcion)
*   Genera el sello digital en base a la cadena original dada
*
PROCEDURE CFDGenerarSello(pcCadenaOriginal, pcArchivoKey, pcPassword, pcMetodo, pcOpenSSL)
 *
 CFDConf.ultimoError = ""
 

 *-- Se verifica que la carpeta indicada contenga el archivo OPENSSL.EXE
 IF EMPTY(pcOpenSSL)
  pcOpenSSL = CFDConf.openSSL
 ENDIF
 IF EMPTY(pcOpenSSL) OR NOT FILE(ADDBS(pcOpenSSL) + "OPENSSL.EXE")
  CFDConf.ultimoError = "No se encontro el archivo OPENSSL.EXE en la ruta indicada"
  RETURN ""
 ENDIF
 pcOpenSSL = GetShortName(ADDBS(FULLPATH(pcOpenSSL)) + "OPENSSL.EXE")
 
  
 *-- Obtenemos un archivo temporal que no exista, con extension .BAT
 LOCAL cBatFile,cTempFile
 cBatFile = GetTempFile("BAT")
  
  
 *-- Tomamos solo la parte del nombre del archivo. Este nombre se utilizara para
 *   crear otros archivos temporales, con distintas extensiones. Esto evita que
 *   dos estaciones puedan "cruzarse" al intentar sellar al mismo tiempo
 cTempFile = JUSTSTEM(cBatFile)
  
  
 *-- Se genera el contenido del archivo BAT para generar el sello
 LOCAL cBuff
 cBuff = pcOpenSSL + " pkcs8 -inform DER -in {keyFile} -passin pass:{password} -out {tempFile}.pem" + CRLF + ;
         pcOpenSSL + " dgst -{metodo} -sign {tempFile}.pem {tempFile}.cad | " + pcOpenSSL + " enc -base64 -A > {tempFile}.sea" + CRLF + ;
         "del {tempFile}.cad" + CRLF + ;
         "del {tempFile}.pem" + CRLF  && Metodo correcto
         

 *-- Se crea el archivo STR con la cadena original
 STRTOFILE(CFDAsc2UTF8(pcCadenaOriginal),cTempFile + ".cad")
  
 *-- Se crea el archivo BAT personalizado para esta operacion
 cBuff = STRT(cBuff,"{keyFile}",GetShortName(pcArchivoKey))
 cBuff = STRT(cBuff,"{password}",pcPassword)
 cBuff = STRT(cBuff,"{tempFile}",cTempFile)
 cBuff = STRT(cBuff,"{metodo}",pcMetodo)
 STRTOFILE(cBuff,cBatFile)

 *-- Se ejecuta el archivo BAT
 LOCAL oWSH
 oWSH = CREATEOBJECT("WScript.Shell")
 oWSH.Run(cBatFile,0,.T.)
 
 
 *-- Si todo salio bien, tenemos un archivo .SEA con el sello
 LOCAL cSello
 IF FILE(cTempFile + ".SEA")
  cSello = FILETOSTR(cTempFile + ".SEA")
 ELSE
  CFDConf.ultimoError = "Ocurrio un error al calcular el sello digital"
  cSello = "" 
 ENDIF
 ERASE (cTempFile + ".*")  
 
 RETURN cSello
 *
ENDPROC



*-- MSXMLGetAttribute
*   Devuelve el valor de un atributo dado en un nodo XML especifico
*
*   Autor: Victor Espina
*   Fecha: Dic 29, 2010
*
FUNCTION MSXMLGetAttribute(poNodo, pcAttribute)
 *
 LOCAL nCount, i, cValue
 nCount = poNodo.Item(0).Attributes.Length - 1
 cValue = ""
 pcAttribute = UPPER(pcAttribute)
 FOR i = 0 TO nCount
  IF UPPER(poNodo.Item(0).Attributes.Item(i).nodeName) == pcAttribute
   cValue = poNodo.Item(0).Attributes.Item(i).TEXT
  ENDIF
 ENDFOR
 
 RETURN cValue
 *
ENDFUNC


DEFINE CLASS CFDReporteMensual AS Custom
 *
 RFCEmisor = ""
 Mes = ""
 Ano = ""
 Registros = NULL
 dataCursor = ""
 
 *-- Constructor
 *
 PROCEDURE Init
  *
  THIS.dataCursor = SYS(2015)
  SELECT 0
  CREATE CURSOR (THIS.dataCursor) ;
   ( ;
     rfc       C (13),;
     serie     C (10),;
     folio     N (10),;
     noAprob   C (20),;
     anoAprob  C (4),;
     fechahora T,;
     fecha     D,;
     total     N (15,2),;
     traslados N (15,2),;
     excento   L,;
     estado    C (1),;
     efecto    C (1),;
     pedimento C (254),;
     fechapedi C (254),;
     aduanaped C (254) ;
   )
  *
 ENDPROC
 
 
 *-- Add (Metodo)
 *   Permite incluir un registro en el reporte con los minimos datos posibles
 *
 PROCEDURE Add(pcRFC, pcSerie, pnFolio, pcNoAprobacion, pcAnoAprobacion, ptFecha, pnTotal, pnTraslados, pcEstado, pcEfecto, pcPedimentos, pcFechaPedimentos, pcAduanaPedimentos)
  *
  SELECT (THIS.dataCursor)
  APPEND BLANK
  REPLACE rfc       WITH pcRFC,;
          serie     WITH pcSerie,;
          folio     WITH pnFolio,;
          noAprob   WITH pcNoAprobacion,;
          anoAprob  WITH pcAnoAprobacion,;
          fechahora WITH ptFecha,;
          fecha     WITH TTOD(ptFecha),;
          total     WITH pnTotal,;
          traslados WITH NVL(pnTraslados,0.00),;
          excento   WITH ISNULL(pnTraslados),;
          estado    WITH IIF(VARTYPE(pnEstado)<>"C","1",pcEstado),;
          efecto    WITH IIF(VARTYPE(pcEfecto)<>"C","I",pcEFecto),;
          pedimento WITH IIF(EMPTY(pcPedimentos),"",pcPedimentos),;
          fechapedi WITH IIF(EMPTY(pcFechaPedimentos),"",pcFechaPedimentos),;
          aduanaped WITH IIF(EMPTY(pcAduanaPedimentos),"",pcAduanaPedimentos)
          
  LOCAL oRow
  SCATTER NAME oRow
  
  RETURN oRow
  *
 ENDPROC
 
 
 
 *-- generarTXT (Metodo)
 *   Genera el TXT para el SAT 
 *
 PROCEDURE generarTXT(pcDestino)
  *
  *-- Se construye el nombre del archivo
  LOCAL cFileName
  cFileName = "1" + RTRIM(THIS.rfcEmisor) + PADL(THIS.Mes,2,"0") + PADL(THIS.Ano,4,"0") + ".TXT"
  
  *-- Si no se indico la ruta, se asume la actual
  IF EMPTY(pcDestino) OR NOT DIRECTORY(pcDestino)
   pcDestino = SET("DEFAULT") + CURDIR()
  ENDIF
  cFileName = ADDBS(pcDestino) + cFileName


  *-- Se obtiene un cursor ordenado con los datos a reportar
  LOCAL cCursor1
  cCursor1 = THIS.dataCursor + "_Q1"
  SELECT * ;
    FROM (THIS.dataCursor)  ;
   ORDER BY serie, folio ;
    INTO CURSOR (cCursor1)
 
 
  *-- Se genera el contenido del archivo
  LOCAL cBuff,i,oRow,cLine
  cBuff = ""
  
  SELECT (cCursor1)
  GO TOP
  SCAN
   cLine = THIS._fixStr(rfc) + "|" + ;
           THIS._fixStr(serie) + "|" + ;
           THIS._fixStr(STR(folio)) + "|" + ;
           THIS._fixStr(ALLT(anoAprob)+ALLT(noAprob)) + "|" + ;
           PADL(DAY(fechahora),2,"0") + "/" + PADL(MONTH(fechahora),2,"0") + "/" + STR(YEAR(fechahora),4) + " " + ;
           PADL(HOUR(fechahora),2,"0") + ":" + PADL(MINUTE(fechahora),2,"0") + ":" + PADL(SEC(fechahora),2,"0") + "|" + ;
           THIS._fixStr(STR(total,15,2)) + "|" + ;
           IIF(excento,"",THIS._fixStr(STR(traslados,15,2))) + "|" + ;
           THIS._fixStr(estado) + "|" + ;
           THIS._fixStr(efecto) + "|" + ;
           THIS._fixStr(pedimento) + "|" + ;
           THIS._fixStr(fechapedi) + "|" + ;
           THIS._fixStr(aduanaped) 
                  
   cBuff = cBuff + "|" + cLine + "|" + CRLF               
  ENDSCAN
  USE IN (cCursor1)
  
  STRTOFILE(cBuff, cFileName)  
  
  RETURN cFileName
  *
 ENDPROC
 
 
 *-- _fixStr (Metodo)
 *   Elimina cualquier valor incorrecto en la cadena dada
 *
 HIDDEN PROCEDURE _FixStr(pcString)
  *
  IF ISNULL(pcString)
   RETURN ""
  ENDIF
  
  pcString = ALLT(CHRT(pcString,"|",""))
  
  RETURN pcString
  *
 ENDPROC
 *
ENDDEFINE


*-- CFDRegistroReporteMensual (Clase)
*   Representa un registro dentro del reporte mensual de CFD
*
DEFINE CLASS CFDLineaReporteMensual AS Custom
 *
 RFC = ""
 Serie = ""
 Folio = 0
 noAprobacion = ""
 anoAprobacion = ""
 FechaHora = {//::}
 Total = 0.00
 Traslados = 0.00
 Estado = 0
 Efecto = ""
 Pedimento = ""
 FechaPedimento = ""
 Aduana = ""
 *
ENDDEFINE



*-- CFDProbarOpenSSL (Funcion)
*   Verifica el correcto funcionamiento de OpenSSL
*
PROCEDURE CFDProbarOpenSSL(pcOpenSSL)
 *
 CFDConf.ultimoError = ""
 

 *-- Se verifica que la carpeta indicada contenga el archivo OPENSSL.EXE
 IF EMPTY(pcOpenSSL)
  pcOpenSSL = CFDConf.openSSL
 ENDIF
 IF EMPTY(pcOpenSSL) OR NOT FILE(ADDBS(pcOpenSSL) + "OPENSSL.EXE")
  CFDConf.ultimoError = "No se encontro el archivo OPENSSL.EXE en la ruta indicada"
  RETURN .F.
 ENDIF
 pcOpenSSL = GetShortName(ADDBS(FULLPATH(pcOpenSSL)) + "OPENSSL.EXE")
 
  
 *-- Obtenemos un archivo temporal que no exista, con extension .BAT
 LOCAL cBatFile,cTempFile
 cBatFile = GetTempFile("BAT")
  
  
 *-- Tomamos solo la parte del nombre del archivo. Este nombre se utilizara para
 *   crear otros archivos temporales, con distintas extensiones. Esto evita que
 *   dos estaciones puedan "cruzarse" al intentar sellar al mismo tiempo
 cTempFile = JUSTSTEM(cBatFile)
  
  
 *-- Se genera el contenido del archivo BAT para generar el sello
 LOCAL cBuff
 cBuff = pcOpenSSL + " version > {tempFile}.out" + CRLF 
         

 *-- Se crea el archivo BAT personalizado para esta operacion
 cBuff = STRT(cBuff,"{tempFile}",cTempFile)
 STRTOFILE(cBuff,cBatFile)

 *-- Se ejecuta el archivo BAT
 LOCAL oWSH
 oWSH = CREATEOBJECT("WScript.Shell")
 oWSH.Run(cBatFile,0,.T.)
 
 
 *-- Si todo salio bien, tenemos un archivo .OUT con la informacion de version del OpenSSL
 LOCAL cResult,lOk
 cResult = FILETOSTR(cTempFile + ".OUT")
 ERASE (cTempFile + ".*")
 
 lOk = (ATC("OpenSSL",cResult)<>0)
 CFDConf.ultimoError = cResult
 
 RETURN lOk
 *
ENDPROC

*-- CFDITimbraFacturaxion
*   Envia el xml a timbrar con la empresa Facturaxion
*	www.facturaxion.com
*   Autor: Rulo
*   Fecha: 26 Ago 2011
*	Parametros: 
*	cXMLCFD			Cadena que contiene el XML sin timbrar (y sin addendas)
*	cCodUsuarioProv	Codigo del usuario ante el proveedor
*	cCodUsuario		Codigo del usuario
*	cIDSucursal		Id de Sucursal
FUNCTION CFDITimbraFacturaxion
PARAMETERS cXMLCFD, cCodUsuarioProv, cCodUsuario, cIDSucursal

ENDFUNC



*-- CFDCadenaCBB (Funcion)
*   Analiza un XML indicado (con timbre) y regresa la cadena para generar el CBB
*   según los requisitos del SAT
*
*
FUNCTION CFDCadenaCBB(pcArchivoXML)
	* -- Codigo de barras QRCode
	* Anexo 20
	* 1. RFC del emisor
	* 2. RFC del receptor
	* 3. Total (a 6 decimales fijos)
	* 4. Identificador único del timbre (UUID) asignado
	* 
	* 95 caracteres conformados de la siguiente manera
	* -> RFC del Emisor, a 12/13 posiciones, precedido por el texto / ?re= / 17 caracteres
	* -> RFC del Receptor, a 12/13 posiciones, precedido por el texto / &rr= / 17 caracteres
	* -> Total del comprobante a 17 posiciones (10 para los enteros, 
	*      1 para carácter “.”, 6 para los decimales), precedido por el texto / &tt= / 21 caracteres
	* -> UUID del comprobante, precedido por el texto / &id= / 40 caracteres
	*
	* -- Genera la cadena a codificar
	LOCAL cCodifica, cRFCEmisor, cRFCReceptor, cTotal, cUUID
	cCodifica = ''
	
	* Lee desde el XML del CFDI
	oCFDI = CREATEOBJECT('MSXML2.DOMdocument')
	oCFDI.load(pcArchivoXML)
	IF (oCFDI.parseError.errorCode <> 0) THEN 
	   myErr = oXML.parseError
	   CFDConf.ultimoError = myErr.reason
	  *MESSAGEBOX("Estructura XML del comprobante mal armado: " + myErr.reason, 16, "Sistema")
	   cCodifica = ''
	ELSE 
		* Selecciona el nodo Emisor para sacar el atributo RFC
		olNode = oCFDI.selectSingleNode("//cfdi:Comprobante/cfdi:Emisor")
		IF ISNULL(olNode) THEN 
			CFDConf.ultimoError = "XML inválido. Nodo <cfdi:Emisor> no presente."
			*MESSAGEBOX("XML inválido."+CHR(13)+"Nodo <cfdi:Emisor> no presente.", 16, "Sistema")
			cCodifica = ''
		ELSE 
			cRFCEmisor = olNode.getAttribute("rfc")
		ENDIF
		
		* Selecciona el nodo Receptor para sacar el atributo RFC
		olNode = oCFDI.selectSingleNode("//cfdi:Comprobante/cfdi:Receptor")
		IF ISNULL(olNode) THEN 
			CFDConf.ultimoError = "XML inválido. Nodo <cfdi:Receptor> no presente."
			*MESSAGEBOX("XML inválido."+CHR(13)+"Nodo <cfdi:Receptor> no presente.", 16, "Sistema")
			cCodifica = ''
		ELSE 
			cRFCReceptor = olNode.getAttribute("rfc")
		ENDIF
		
		* Selecciona el nodo Comprobante para sacar el atributo RFC
		olNode = oCFDI.selectSingleNode("//cfdi:Comprobante")
		IF ISNULL(olNode) THEN 
			CFDConf.ultimoError = "XML inválido. Nodo <cfdi:Comprobante> no presente."
			*MESSAGEBOX("XML inválido."+CHR(13)+"Nodo <cfdi:Comprobante> no presente.", 16, "Sistema")
			cCodifica = ''
		ELSE 
			cTotal = olNode.getAttribute("total")
			cTotal = PADL(SUBSTR(cTotal, 1, ATC('.', cTotal)-1), 10, '0')+'.'+PADR(RIGHT(cTotal, LEN(cTotal)-ATC('.', cTotal)), 6, '0')
		ENDIF
		
		* Selecciona el nodo TimbreFiscalDigital para sacar el atributo UUID
		olNode = oCFDI.selectSingleNode("//cfdi:Comprobante/cfdi:Complemento/tfd:TimbreFiscalDigital")
		IF ISNULL(olNode) THEN 
			CFDConf.ultimoError = "XML inválido. Nodo <tfd:TimbreFiscalDigital> no presente."
			*MESSAGEBOX("XML inválido."+CHR(13)+"Nodo <tfd:TimbreFiscalDigital> no presente.", 16, "Sistema")
			cCodifica = ''
		ELSE 
			cUUID = olNode.getAttribute("UUID")
		ENDIF
		
	ENDIF
	
	cCodifica = '?re='+cRFCEmisor+'&rr='+cRFCReceptor+'&tt='+cTotal+'&id='+cUUID
	
	RETURN cCodifica
ENDFUNC 


* -----------------------------------------
FUNCTION CFDGoogleQR(tcDato, tcDestino) 
* -----------------------------------------
* Esta funcion genera un código de barras bidimensional
* utilizando la Api de Google: http://code.google.com/intl/es-AR/apis/chart/docs/gallery/qr_codes.html
*
* Recibe de parámetro la cadena a codificar y 
* regresa el nombre del png generado.
* 
* La idea es agregarlo al formato gráfico, para que se genere la imagen, con algo así:
*
* CFDGoogleQR(CFDCadenaCBB(pcArchivoXML))
*
* Autor: Baltazar Moreno
* Fecha: Octubre 07, 2011
* 
* VES Jul 30, 2012
* Se hicieron cambios en el codigo para usar
* archivos temporales unicos en lugar de un
* archivo fijo.
* -----------------------------------------

	lcDimensiones = '200x200'
	*lcImagen = ADDBS(SYS(2023)) + SYS(2015)+"_googleQR.png"   && En temporal de windows
	IF VARTYPE(tcDestino)<>"C"
 	 lcImagen = GetTempFile("PNG")
 	ELSE
 	 lcImagen = tcDestino
 	ENDIF 

*	WAIT WINDOW "Generando y descargando Código QR, espere por favor..." NOWAIT 
	DECLARE Long URLDownloadToFile IN "urlmon"; 
	  Long pCaller,; 
	  String szURL,; 
	  String szFileName,; 
	  Long dwReserved,; 
	  Long lpfnCB 
	lcURL ="https://chart.googleapis.com/chart?cht=qr&chs=" + ;
	      lcDimensiones + "&chld=M&chl=" + CFDGetEscaped(tcDato, 0x2000) 
	nRetVal = URLDownloadToFile (0, lcURL, lcImagen, 0, 0) 
*	WAIT CLEAR 

    IF nRetVAL <> 0
     CFDConf.ultimoError = "ERROR " + TRANS(nRetVal,"")
    ENDIF

	RETURN IIF( nRetVal == 0 , lcImagen	, "" )

ENDFUNC
* -----------------------------------------


* -----------------------------------------
FUNCTION CFDCreateQR(tcDato, tcDestino) 
* -----------------------------------------
* Esta funcion esta basada en el aporte de
* Baltazar Moreno (http://bmorenoj.blogspot.mx/2012/07/codigos-de-barra-qr-sin-usar-la-api-de.html)
*
* La function externa GenerateFile es declarada
* en CFDInit()
* -----------------------------------------

	IF VARTYPE(tcDestino)<>"C"
 	 lcImagen = GetTempFile("PNG")
 	ELSE
 	 lcImagen = tcDestino
 	ENDIF 

    GenerateFile(tcDato, lcImagen)

    RETURN lcImagen
ENDFUNC
* -----------------------------------------



* -----------------------------------------
FUNCTION CFDGetEscaped(tcSource, tnFlag)
* -----------------------------------------
* Esta funcion convierte los caracteres no soportados en la URL
* En sus cadenas de escape, más info:
* http://www.news2news.com/vfp/?example=396&function=617&PHPSESSID=0e0804f1a28f0d2e8d8a0af3b257f808
* 
* Autor: Baltazar Moreno
* Fecha: Octubre 07, 2011
* -----------------------------------------
    DECLARE INTEGER UrlEscape IN shlwapi;
        STRING pszURL, STRING @pszEscaped,;
        INTEGER @pcchEscaped, INTEGER dwFlags
 
    LOCAL cTarget, nBufsize
    nBufsize = Len(tcSource) * 4
    cTarget = Repli(Chr(0), nBufsize)
    = UrlEscape(tcSource, @cTarget, @nBufsize, tnFlag)
RETURN Left(cTarget, nBufsize)
ENDFUNC 
* -----------------------------------------


*-- CFDEVL
*   Implementacion de la funcion EVL()
* 
*   Autor: V Espina
*   Fecha: 11 Nov 2011
*
PROCEDURE CFDEVL(puValue, puDefault)
 RETURN IIF(EMPTY(puValue),puDEfault,puValue)
ENDPROC


*-- CFDBuffer
*   Funcion para crear un buffer de datos e inicializarlo
*
*   Autor: V Espina
*   Fecha: Nov 12, 2011
*
*   Ejemplo:
*   oBuff = CFDBuffer("Nombre,Apellido","Victor","Espina")
*   ?oBuff.Nombre -> "Victor"
*   ?oBuff.Apellido -> "Espina"
*
PROCEDURE CFDBuffer
LPARAMETERS pcItemList,p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19
 *
 LOCAL oBuff,i,cProp
 oBuff=CREATEOBJECT("Custom")

 LOCAL cPropName,uPropValue,nCount
 LOCAL ARRAY aProps[1]
 nCount = ALINES(aProps,STRT(pcItemList,",",CHR(13)+CHR(10)))
 FOR i=1 TO MIN(nCount,20)
  cPropName = aProps[i]
  uPropValue = EVALUATE("P" + ALLTRIM(STR(i - 1)))
  oBuff.AddProperty(cPropName, uPropValue)
 ENDFOR
 
 RETURN oBuff
 *
ENDPROC


* obtenVersion
* Se mantiene por compatibilidad. En su lugar, debe usarse
* el metodo ToString() de CFDVersions
*
PROCEDURE obtenVersion(pnVersion)
 RETURN CFDVersions.ToString(pnVersion)
ENDPROC


*******************************************************************
**
**                     P R I N T 2 P D F
**
*******************************************************************
PROCEDURE Print2PDF
parameters pcFileName, pcReport

*******************************************************************************
* Print2PDF.PRG  Version 1.3
*
* Parms: 	pcReport 				= Name of VFP report to run
*			pcOutputFile 			= Name of finished PDF file to create.
*
* Author:	Paul James (Life-Cycle Technologies, Inc.) mailto:paulj@lifecyc.com
* "Standing on the shoulders of giants", I incorporated the hard work of many
* talented individuals into one program (with my own additions, enhancements, etc.).
* This file is free for anyone to use and distribute.  
* If you plan any commercial distribution, please contact the appropriate people.
*
*
****** MANY THANKS:
* This program is based off the public domain work of:
* Sergey Berezniker		mailto:sergeyb@isgcom.com					(Automating Ghostscript DLLs)
* Bob Lee 				WWW.1amsoftware.com 		(pdfMaker)		(Original version of this program)
* Ed Rauh 				mailto:edrauh@earthlink.net (clsheap.prg)	(Variables for DLLs, etc.)
*
*
****** PURPOSE:
* This program will run a VFP report and output it to a postscript file (temporary filename, temp folder).
* This part of the code uses the Adobe postscript printer driver.
* (It will automatically select the appropriate Postscript printer driver.)
* It will then turn that postscript file into a PDF file (named whatever you want in whatever folder you want).
* This part of the code calls the Ghostscript DLL to turn the postscript file into a PDF.
*
*
****** REQUIREMENTS/SETUP:
*	The "Zip" file this file was included in, contains everything you need to start creating PDF's.
*	Just run the "Demo" program (P2Demo.prg) and it will automatically walk you through installing
*	Ghostscript and the Adobe Postscript driver.  It will then "print" a demo VFP report to a PDF!
*
*
****** COLOR PRINTING:
*	If you want to have "color" in your PDF's, you will need an additional file.
*	 The "Zip" file includes this file.  It is a "Generic Color PostScript" PPD from Adobe.

*	When you are installing the Adobe PostScript driver:
*		In the install dialogue, choose Local Printer.
*		Choose an output port of FILE.
*		When prompted to "Select Printer Model", click the "Browse" button, 
*		locate the file (included with this program) named DEFPSCOL.PPD,
*		Choose the "Generic Color Printer" from the printer list.
*
*	The following web page has excellent additional documentation: 
*		http://www.ep.ph.bham.ac.uk/general/printing/winsetup.html
*
*
****** NOTES:
*	If an Error ocurrs, a .False. return code will be returned, but you should check the .lError property.
*	If .lError is .True., then the .cError property will have text explaining the error.
*
*	Because this is a class, you can either call the Main() method to execute all logic,
*	or you can set the properties yourself and call individual methods as needed (sweet).
*
*
****** EXAMPLE CALLS:
*	1.	*A one line call (nice and neat)
*		loPDF = createobject("Print2PDF", lcMyPDFName, lcMyVFPReport, .t.)
*
*	2.	*This is probably the most typical example.
*		set procedure to Print2PDF.prg additive
*		loPDF = createobject("Print2PDF")
*		if isnull(loPDF)
*			=messagebox("Could not setup PDF class!",48,"Error")
*			return .f.
*		endif
*
*		with loPDF
*			.cINIFile 		= gcCommonPath+"\Print2PDF.ini"
*			.cOutputFile 	= "C:\Output\myfile.pdf"
*			.cReport		= "C:\Myapp\Reports\MyVFPReport.frx"
*			llResult 		= .Main()
*		endwith
*
*		if !llResult or loPDF.lError
*			=messagebox("This error ocurred creating the PDF:"+chr(13)+;
*						alltrim(loPDF.cError),48,"Error Message")
*		endif
*
*	3.	*This example shows manually setting some properties.
*		loPDF = createobject("Print2PDF")
*		loPDF.cReport = "C:\MyApp\Reports\MyVfpReport.frx"
*		loPDF.cOutputFile = "C:\Output\myfile.pdf"
*		loPDF.cPSPrinter = "My PS Printer Name"
*		llResult = loPDF.Main()
*
*	4.	*This example assumes you have created the (.ps) Postscript file yourself and just want to create the PDF.
*		loPDF = createobject("Print2PDF")
*		loPDF.ReadIni()
*		loPDF.cOutputFile = "C:\Output\myfile.pdf"
*		loPDF.cPSFile = "C:\temp\myfile.ps"
*		llResult = loPDF.MakePDF()
*
*
****** OTHER LINKS:
*	If you want to make sure you have a recent copy of the Adobe Generic Postscript printer driver:
*		http://www.adobe.com/support/downloads/detail.jsp?ftpID=1500
*		This link changes periodically, so you might also just try:
*		http://www.adobe.com/support/downloads/product.jsp?product=44&platform=Windows
*
*	Main Ghostscript Web Site:	http://www.ghostscript.com/doc/AFPL/index.htm
*	Licensing Page: http://www.ghostscript.com/doc/cvs/New-user.htm#Find_Ghostscript
*
*
****** GHOSTSCRIPT:
*	Ghostscript does NOT register it's DLL file with Windows, so this code has a function called GSFind()
*	that will try to find the Ghostscript DLL.  Here is what it does:
*	1. See if it is in the VFP Path.
*	2. Grab the location out of the Print2PDF.INI file (if it exists)
*	3. Look in the default installation folder of C:\GS\
*	If the program uses option #3 (my preference) then it will automatically detect the
*	subfolder used to contain the DLL.  Since I am running version 7.04, my
*	folder is "C:\gs\gs7.04\bin\".  The program looks for "C:\GS\GSxxxxx\bin\"
*
*	GhostScript's job (in this class) is to take a "postscript file" (.ps) and turn
*	it into a PDF file (compatible with Adobe 3.x and above).  A "postscript file"
*	is basically a file that contains all of the "printer commands" necessary to
*	print the document, including fonts, pictures, etc.  You could go to a DOS prompt
*	and "copy" a postscript file to your printer port, and it should print the document
*	(providing your printer was Postscript Level 2 capable).  Ghostscript has many other
*	abilities, including converting a PDF back into a postscript file.
*
*	Ghostscript ONLY "prints" what is in the postscript file.  What gets into the
*	postscript file is determined by the "Postscript Printer Driver" that you are
*	using.  If you want COLOR for example, you must use a driver that supports color.
*	Also, because it is setup in Windows like any other 'printer', you can use the
*	Printer Control Panel to change the settings of the driver (cool).
*
*	The "Aladdin Free Public License" (AFPL) version of Ghostscript is "free" as long as
*	it is not a commercial package.
*	The Ghostscript web site has the most recent "publicly released" version.  Also,
*	you can download the actual Source Code for Ghostscript (written in C), and you
*	also get the developer's documentation which describes all parameters, etc.  The
*	parms used here are pretty generally acceptable, but if you need higher resolution,
*	debug messages, printer specific stuff, etc. it's good to have.
*
*	Once you install Ghostscript (usually C:\gs\), you can run it (gswin32.exe)
*	It's main interface is a "command prompt" where you can interactively enter GS commands.
*	You can also enter "devicenames ==" at the GS command prompt to get a current list
*	of all "output devices" currently supported (DEVICE=pdfwrite, DEVICE=laserject, etc.)
*
*	The calls to the Ghostscript DLL interfaces use Ed Rauh's "clsheap.prg" program.  
*	It must be in your VFP path.  It is included in the ZIP file with this code 
*	(thanks Ed), or you can get it from the Universal Thread...
*		http://www.universalthread.com/wconnect/wc.dll?FournierTransformation~2,2,9482
*
*
****** REVISION HISTORY:
*	Version 1.2
*	---------------------------------------------------------------------------------
*	Turned this "thing" into a Class.
*	Added Flags and logic to allow the user to install Postscript on-the-fly.
*	Added Flags and logic to allow the user to install Ghostscript on-the-fly.
*	Added Flags and logic to allow the user to install Adobe Acrobat on-the-fly.
*	Added the ability to read most setting from the .INI file.
*
*	Version 1.3
*	---------------------------------------------------------------------------------
*	Corrected some logic bugs, and bugs in the .ini processing.
*	Changed .ini setting names to be the same as the variable names for clarity**.
*	Added all new properties to .ini file.
*	Added "cStartFolder" property to hold the folder the program is running from.
*	Added "cTempPath" property to hold the folder for storing temporary files.
*	Added support for printing "color" in pdf.
*		Added "lUseColor" to determine color printer use.
*		Added "cColorPrinter" property (and .ini setting) to hold color printer driver.
*	Added "cPrintResolution" so you can change printer resolution on-the-fly.
*	Added the ability to use "dynamic" or "variable" paths in the Install Paths (including this.cStartFolder)
*	Made this file callable as a "procedure".
*	Included Demo program, dbf, report.
*	Included Ghostscript and Postscript installs.
******************************************************************************************************************


*************************************************************************************************
*** The following code allows you to call the Print2PDF class as a Function/Procedure,
*** just pass in the Output Filename and the Report Filename like:
***		Do Print2PDF with "MyPdfFile" "MyVfpReport"
*** If you use Print2PDF as a class, this code NEVER gets hit!
*************************************************************************************************
if vartype(pcFileName) <> "C" or vartype(pcReport) <> "C" or empty(pcFileName) or empty(pcReport)
	=messagebox("No Parms passed to Print2PDF",48,"Error")
	return .f.
endif

local loPDF
loPDF = .NULL.

loPDF = createobject("Print2PDF")

if isnull(loPDF)
	=messagebox("Could not setup PDF class!",48,"Error")
	return .f.
endif

with loPDF
	.cOutputFile 	= pcFileName
	.cReport		= pcReport
	llResult 		= .Main()
endwith

if !llResult or loPDF.lError
	=messagebox("This error ocurred creating the PDF:"+chr(13)+alltrim(loPDF.cError),48,"Error Message")
endif

loPDF = .NULL.
release loPDF

return .t.



**************************************************************************************
** Class Definition :: Print2PDF
**************************************************************************************
define class Print2PDF as relation
	**Please note that any of these properties can be set by you in your code.
	**You can also set most of them by using the .ini file.

	**Set these properties (required)
	cReport			= space(0)	&&Name of VFP report to Run
	cOutputFile		= space(0)	&&Name of finished PDF file to create.

	**User-Definable properties (most of these can be set in the .ini file)
	cStartFolder	= justpath(sys(16))+iif(right(justpath(sys(16)),1)="\","","\")	&&Folder this program started from.
	cTempPath		= space(0)	&&Folder for Temporary Files (default = VFP temp path)
	cExtraRptClauses= space(0)	&&Any extra reporting clauses for the "report form" command
	lReadINI		= .t.		&&Do you want to pull settings out of Print2PDF.ini file?
	cINIFile		= this.cStartFolder+"Print2PDF.ini"	&&Name of INI file to use.  If not in current folder or VFP path, specify full path.
	lFoundPrinter	= .f.		&&Was the PS printer found?
	lFoundGS		= .f.		&&Was Ghostscript found?
	cPSPrinter		= space(0)	&&Name of the Windows Printer that is the Postscript Printer (default = "GENERIC POSTSCRIPT PRINTER")
	cPSColorPrinter	= space(0)	&&Name of the Windows Printer that is the Postscript Printer (default = "GENERIC COLOR POSTSCRIPT")
	lUseColor		= .f.		&&Use "color" printer driver?
	cPrintResolution= space(0)	&&Printer resolution string (300, 600x600, etc.) (default = "300")
	cPSFile			= space(0)	&&Path/Filename for Postscript file (auto-created if not passed)
	lErasePSFile	= .t.		&&Erase the .ps file after conversion?
	cPDFFile		= space(0)	&&Path/Filename for PDF file		(auto-created if not passed)
	cGSFolder		= space(0)	&&Path where Ghostscript DLLs exist	(auto-populated if not passed)


	**Internal properties
	lError			= .f.		&&Indicates that this class had an error.
	cError			= ""		&&Error message generated by this class
	cOrigSafety		= space(0)	&&Original "set safety" settting
	cOrigPrinter	= space(0)	&&Original "Set printer" setting


	**AutoInstall properties	&&See the ReadINI method for more details
	iInstallCount	= 1			&&Number of programs setup for AutoInstallation

	dimension aInstall[1, 7]

	aInstall[1,1] = space(0)	&&Program Identifier (used to find program in array)
	aInstall[1,2] = .t.			&&Can we install this product
	aInstall[1,3] = space(0)	&&Product Name (for user)
	aInstall[1,4] = space(0)	&&Description of product for user
	aInstall[1,5] = space(0)	&&Folder where install files are stored
	aInstall[1,6] = space(0)	&&Setup Executable name
	aInstall[1,7] = space(0)	&&Notes to show user before installing


	**************************************************************************************
	** Class Methods
	**************************************************************************************
	**********************
	** Init Method
	**********************
	function init(pcFileName, pcReport, plRunNow)
		with this
			.cOrigSafety = set("safety")
			.cOrigPrinter = set("Printer", 3)
			
			.cStartFolder = FULLPATH(".")                       && VES Jul 25, 2012
			.cINIFile = ADDBS(.cStartFolder) + "PRINT2PDF.INI"  && VES Jul 25, 2012

			.lError = .f.
			.cError = ""

			if type("pcFileName") = "C" and !empty(pcFileName)
				.cOutputFile = alltrim(pcFileName)
			endif

			if type("pcReport") = "C" and !empty(pcReport)
				.cReport = alltrim(pcReport)
			endif
		endwith

		set safety off

		**Did User pass in parm to autostart the Main method?
		if type("plRunNow") = "L" and plRunNow = .t.
			return this.main()
		endif
	endfunc


	**********************************************************************
	** Cleanup Method
	** 	Make sure all objects are released, etc.
	**********************************************************************
	function CleanUp
		local lcOrigPrinter, lcOrigSafety

		with this
			lcOrigSafety = .cOrigSafety
			lcOrigPrinter = .cOrigPrinter
		endwith

		if !empty(lcOrigSafety)
			set safety &lcOrigSafety
		endif

		if !empty(lcOrigPrinter)
			set printer to
			set printer to name "&lcOrigPrinter"
		endif

		return
	endfunc


	**********************************************************************
	** ResetError Method
	** 	Call this method on each subsequent call to SendFax or CheckLog
	**********************************************************************
	function ResetError
		with this
			.lError = .f.
			.iError = 0
			.cError = ""
		endwith
		return .t.
	endfunc



	**************************************************************************************
	* Main Method - Main code
	*	If you wanted to run each piece seperately, you can make your own calls
	*	to each of the methods called below from within your program and not
	*	call this method at all.  That way, you could execute only the methods you want.
	*	For example, if your postscript file already existed, you could simply set
	*	the properties for the file location, then skip the calls that create the PS file
	*	and go straight to the MakePDF() method.
	**************************************************************************************
	function main(pcFileName, pcReport)
		local x
		store 0 to x
	 	with this
			if type("pcFileName") = "C" and !empty(pcFileName)
				.cOutputFile = alltrim(pcFileName)
			endif

			if type("pcReport") = "C" and !empty(pcReport)
				.cReport = alltrim(pcReport)
			endif

			if empty(.cReport) or empty(.cOutputFile)
				.lError = .t.
				.cError(".cReport and/or .cOutputFile empty",48,"Error")
				return .f.
			endif

			**Get values from Print2Pdf.ini file
			**Also sets default values even if .ini is not used.
			if !.lError
				=.ReadINI()
			endif

			**Set printer to PostScript
			if !.lError
				=.SetPrinter()
			endif

			**Create the Postscript file
			if !.lError
				=.MakePS()
			endif

			**Make sure Ghostscript DLLs can be found
			if !.lError
				=.GSFind()
			endif

			**Turn Postscript into PDF
			if !.lError
				=.MakePDF()
			endif

			**Install PDF Reader
			if !.lError
				=.InstPDFReader()
			endif

			.CleanUp()
		endwith

		return !this.lError
	endfunc



	**************************************************************************************
	* ReadIni()	-	Function to open/read contents of Print2PDF.INI file.
	*			-	If the .ReadINI property is .False., this method will not run
	*			-	This method examines each property, it will not overwrite a property
	*				with a value from the .INI that you have already populated via code.
	**************************************************************************************
	function ReadINI()
		local lcTmp
		store "" to lcTmp

		**If we're not supposed to read the INI, make sure default values are set
		if this.lReadINI = .t.
			**Win API declaration
			declare integer GetPrivateProfileString ;
				in WIN32API ;
				string cSection,;
				string cEntry,;
				string cDefault,;
				string @cRetVal,;
				integer nSize,;
				string cFileName


			**Read INI settings
			with this
				**General Properties
				**Postscript Printer Driver Name
				if empty(.cPSPrinter)
					.cPSPrinter = .ReadIniSetting("PostScript", "cPSPrinter")
				endif

				**Color Postscript Printer Driver Name
				if empty(.cPSColorPrinter)
					.cPSColorPrinter = .ReadIniSetting("PostScript", "cPSColorPrinter")
				endif
		
				**Name of PostScript file
				if empty(.cPSFile)
					.cPSFile = .ReadIniSetting("PostScript", "cPSFile")
				endif

				**Name of folder to hold Temporary postscript files
				if empty(.cTempPath)
					.cTempPath = .ReadIniSetting("PostScript", "cTempPath")
				endif

				**Name of PDF file
				if empty(.cPDFFile)
					.cPDFFile = .ReadIniSetting("GhostScript", "cPDFFile")
				endif

				**Name of Ghostscript folder (where installed to)
				if empty(.cGSFolder)
					.cGSFolder = .ReadIniSetting("GhostScript", "cGSFolder")
				endif

				**Resolution for PDF files
				if empty(.cPrintResolution)
					.cPrintResolution = .ReadIniSetting("PostScript", "cPrintResolution")
				endif

				**Installation Packages
				**# of packages to store settings for
				lcTmp = .ReadIniSetting("Install", "iInstallCount")
				if !empty(lcTmp)
					.iInstallCount = val(lcTmp)

					if .iInstallCount > 1
						dimension .aInstall[.iInstallCount, 7]
					endif

					for x = 1 to .iInstallCount
						**What is the "programmatic" ID for this package
						.aInstall[x,1] = upper(.ReadIniSetting("Install", "cInstID"+transform(x)))

						**Can we install this package?
						lcTmp = upper(.ReadIniSetting("Install", "lAllowInst"+transform(x)))
						.aInstall[x,2] = iif("T" $ lcTmp or "Y" $ lcTmp, .t., .f.)

						**Product Name
						.aInstall[x,3] = .ReadIniSetting("Install", "cInstProduct"+transform(x))

						**Description of Product to show user
						.aInstall[x,4] = .ReadIniSetting("Install", "cInstUserDescr"+transform(x))

						**Folder where installation files exist
						.aInstall[x,5] = .ReadIniSetting("Install", "cInstFolder"+transform(x))

						**Executable file to start installation
						.aInstall[x,6] = .ReadIniSetting("Install", "cInstExe"+transform(x))
						
						**Instructions to User
						.aInstall[x,7] = .ReadIniSetting("Install", "cInstInstr"+transform(x))
					endfor
				endif
			ENDWITH
		ENDIF
		
		**Make sure these basic settings are not blank
		if empty(.cPSPrinter)
			.cPSPrinter	= "GENERIC POSTSCRIPT PRINTER"
		endif
		if empty(.cPSColorPrinter)
			.cPSColorPrinter = "GENERIC COLOR POSTSCRIPT"
		ENDIF
		if empty(.cTempPath)
			.cTempPath = sys(2023) + iif(right(sys(2023),1)="\","","\")
		endif
		if empty(.cPrintResolution)
			.cPrintResolution= "300"
		endif
		return .t.
	endfunc



	**************************************************************************************
	* ReadIniSetting() - Returns the value of a "setting" from an "INI" file (text file)
	*				 	 (returns "" if string is not found)
	*	Parms:	pcSection	= The "section" in the INI file to look in...	[Section Name]
	*			pcSetting	= The "setting" to return the value of			Setting="MySetting"
	**************************************************************************************
	function ReadIniSetting(pcSection, pcSetting)
		local lcRetValue, lnNumRet, lcFile
		
		lcFile = alltrim(this.cIniFile)

		lcRetValue = space(8196)

		**API call to get string
		lnNumRet = GetPrivateProfileString(pcSection, pcSetting, "[MISSING]", @lcRetValue, 8196, lcFile)

		
		lcRetValue = alltrim(substr(lcRetValue, 1, lnNumRet))
		
		if lcRetValue == "[MISSING]"
			lcRetValue = ""
		endif
		
		return lcRetValue
	endfunc



	**************************************************************************************
	* SetPrinter() - Set the printer to the PostScript Printer
	**************************************************************************************
	function SetPrinter()
		local x, lcPrinter
		x = 0
		lcPrinter = ""
		
		with this
			if empty(.cPSPrinter)
				.cPSPrinter = "GENERIC POSTSCRIPT PRINTER"
			endif
			if empty(.cPSColorPrinter)
				.cPSColorPrinter = "GENERIC COLOR POSTSCRIPT"
			endif

			if .lUseColor = .t.
				lcPrinter = .cPSColorPrinter
			else
				lcPrinter = .cPSPrinter
			ENDIF
			lcPrinter = UPPER(lcPrinter) && VES Jul 25, 2012
			
			.lFoundPrinter = .f.

			***Make sure a Postscript printer exists on this PC
			if aprinters(laPrinters) > 0
				for x = 1 to alen(laPrinters)
					if alltrim(upper(laPrinters[x])) == lcPrinter
						.lFoundPrinter = .t.
					endif
				endfor

				if !.lFoundPrinter
					.cError = lcPrinter+" is not installed!!"
					.lError = .t.
				endif
			else
				.cError = "NO printer drivers are installed!!"
				.lError = .t.
			endif

			if .lFoundPrinter
				*** Set the printer to Generic Postscript Printer
				lcEval = "SET PRINTER TO NAME '" +lcPrinter+"'"
				&lcEval

				if alltrim(upper(set("PRINTER",3))) == alltrim(upper(lcPrinter))
				else
					.cError = "Could not set printer to: "+alltrim(lcPrinter)
					.lError = .t.
					.lFoundPrinter = .f.
				endif
			endif

			**Auto-Install, If no PS printer was found.
			if !.lFoundPrinter
				if this.Install("POSTSCRIPT")	&&Install PS driver
					return this.SetPrinter()	&&Call this function again
				endif
			endif
		endwith

		return .lFoundPrinter
	endfunc



	**************************************************************************************
	* MakePS() - Run the VFP report to a PostScript file
	**************************************************************************************
	function MakePS()
		local lcReport, lcExtra, lcPSFile

		set safety off

		with this
			**If no PS printer was found yet, find it
			if !.lFoundPrinter
				if !.SetPrinter()
					return .f.
				endif
			endif

			lcReport	= .cReport
			lcExtra		= .cExtraRptClauses

			if empty(lcReport)
				.cError = "No Report File was specified."
				.lError = .t.
				return .f.
			endif

			if empty(.cPSFile)
				*** We'll create a Postscript Output File (use VFP temporary path and temp filename)
				.cPSFile = .cTempPath + sys(2015) + ".ps"
			endif

			lcPSFile = .cPSFile

			*** Make sure we erase existing file first
			erase (lcPSFile)

			report form (lcReport) &lcExtra noconsole to file &lcPSFile

			if !file(lcPSFile)
				.cError = "Could create PDF file"
				.lError = .t.
				return .f.
			endif
		endwith

		return .t.
	endfunc



	**************************************************************************************
	* GSFind() - Finds the Ghostscript DLL path and adds it to the VFP path
	**************************************************************************************
	function GSFind()
		local x, lcPath
		store "" to lcPath
		store 0 to x

		with this
			.lFoundGS = .f.

			**Look for Ghostscript DLL files.  If not in the VFP path, then GSFind().
			if file("gsdll32.dll")
				.lFoundGS = .t.
				return .t.
			endif

			**Try location specified in INI file
			if !empty(.cGSFolder)
				lcTmp = .cGSFolder + "gsdll32.dll"			&&Make sure the DLL file can be found
				if !file(lcTmp)
					.cGSFolder = ""
				endif
			endif

			*Look for them to exist in C:\gs\gsX.XX\bin\
			if empty(.cGSFolder)
				if !directory("C:\gs")
					return .f.
				endif

				liGS = adir(laGSFolders, "C:\gs\*.*","D")
				if liGS < 1
					return .f.
				endif

				for x = 1 to alen(laGSFolders,1)
					lcTmp = alltrim(upper(laGSFolders[x,1]))
					if "GS" = left(lcTmp,2) and "D" $ laGSFolders[x,5]
						.cGSFolder = lcTmp
						exit
					endif
				endfor

				if empty(.cGSFolder)
					return .f.
				endif

				.cGSFolder = "c:\gs\"+alltrim(.cGSFolder)+"\bin\"
			endif

			if !empty(.cGSFolder)
				lcTmp = .cGSFolder + "gsdll32.dll"			&&Make sure the DLL file can be found
				if !file(lcTmp)
					.cGSFolder = ""
				endif
			endif

			if empty(.cGSFolder)
				return .f.
			else
				.lFoundGS = .t.
			endif
		endwith

		lcPath = alltrim(set("Path"))
		set path to lcPath + ";" + .cGSFolder

		return .t.
	endfunc




	**************************************************************************************
	* MakePDF() - Run Ghostscript to create PDF file from the Postscript file
	**************************************************************************************
	function MakePDF()
		local lcPDFFile, lcOutputFile, lcPSFile

		set safety off

		with this
			**Make sure Ghostscript DLLs have been found (or install them)
			if !.lFoundGS
				if !.GSFind()

					**Auto-Install, Ghostscript
					if .Install("GHOSTSCRIPT")
						if !.GSFind()	&&Call function again
							.cError = "Could not Install Ghostscript!"
							.lError = .t.
							return .f.
						endif
					endif
				endif
			endif

			lcOutputFile	= .cOutputFile
			lcPSFile		= .cPSFile

			if empty(.cPDFFile)
				.cPDFFile = juststem(lcPSFile) + ".pdf"
			endif

			lcPDFFile = .cPDFFile
			erase (lcPDFFile)

			if !.GSConvertFile(lcPSFile, lcPDFFile)
				.cError = "Could not create: "+lcPDFFile
				.lError = .t.
			endif

			if !file(lcPDFFile)
				.cError = "Could not create: "+lcPDFFile
				.lError = .t.
			endif

			**Get rid of .ps file
			if .lErasePSFile
				erase (lcPSFile)
			endif

			**Make sure output file does not exist already
			erase (lcOutputFile)

			*** Move the temp file to the actual file name by renaming
			rename (lcPDFFile) to (lcOutputFile)

			if !file(lcOutputFile)
				.cError = "Could not rename file to "+lcOutputFile
				.lError = .t.
			endif
		endwith
		return !this.lError
	endfunc



	**************************************************************************************
	* GSConvert() - Sets up arguments that will be passed to Ghostscript DLL, calls GSCall
	**************************************************************************************
	function GSConvertFile(tcFileIn, tcFileOut)
		local lnGSInstanceHandle, lnCallerHandle, loHeap, lnElementCount, lcPtrArgs, lnCounter, lnReturn
		dimension  laArgs[11]

		store 0 to lnGSInstanceHandle, lnCallerHandle, lnElementCount, lnCounter, lnReturn
		store null to loHeap
		store "" to lcPtrArgs

		set safety off
		loHeap = createobject('Heap')

		**Declare Ghostscript DLLs
		
		** VES Jul 25 2012
		** Se comento este codigo porque en VFP6 el CLEAR DLLS no acepta
		** parametros adicionales, causando que se eliminaran todas las
		** declaraciones API existentes
		**
		**clear dlls "gsapi_new_instance", "gsapi_delete_instance", "gsapi_init_with_args", "gsapi_exit"

		declare long gsapi_new_instance in gsdll32.dll ;
			long @lngGSInstance, long lngCallerHandle
		declare long gsapi_delete_instance in gsdll32.dll ;
			long lngGSInstance
		declare long gsapi_init_with_args in gsdll32.dll ;
			long lngGSInstance, long lngArgumentCount, ;
			long lngArguments
		declare long gsapi_exit in gsdll32.dll ;
			long lngGSInstance

		laArgs[1] = "dummy" 			&&You could specify a text file here with commands in it (NOT USED)
		laArgs[2] = "-dNOPAUSE"			&&Disables Prompt and Pause after each page
		laArgs[3] = "-dBATCH"			&&Causes GS to exit after processing file(s)
		laArgs[4] = "-dSAFER"			&&Disables the ability to deletefile and renamefile externally
		laArgs[5] = "-r"+this.cPrintResolution	&&Printer Resolution (300x300, 360x180, 600x600, etc.)
		laArgs[6] = "-sDEVICE=pdfwrite"	&&Specifies which "Device" (output type) to use.  "pdfwrite" means PDF file.
		laArgs[7] = "-sOutputFile=" + tcFileOut	&&Name of the output file
		laArgs[8] = "-c"				&&Interprets arguments as PostScript code up to the next argument that begins with "-" followed by a non-digit, or with "@". For example, if the file quit.ps contains just the word "quit", then -c quit on the command line is equivalent to quit.ps there. Each argument must be exactly one token, as defined by the token operator
		laArgs[9] = ".setpdfwrite"		&&If this file exists, it uses it as command-line input?
		laArgs[10] = "-f"				&&(ends the -c argument started in laArgs[8])
		laArgs[11] = tcFileIn			&&Input File name (.ps file)

		* Load Ghostscript and get the instance handle
		lnReturn = gsapi_new_instance(@lnGSInstanceHandle, @lnCallerHandle)
		if (lnReturn < 0)
			loHeap = null
			RELEASE loHeap
			this.lError = .t.
			this.cError = "Could not start Ghostscript."
			return .f.
		endif

		* Convert the strings to null terminated ANSI byte arrays
		* then get pointers to the byte arrays.
		lnElementCount = alen(laArgs)
		lcPtrArgs = ""
		for lnCounter = 1 to lnElementCount
			lcPtrArgs = lcPtrArgs + NumToLONG(loHeap.AllocString(laArgs[lnCounter]))
		endfor
		lnPtr = loHeap.AllocBlob(lcPtrArgs)

		lnReturn = gsapi_init_with_args(lnGSInstanceHandle, lnElementCount, lnPtr)
		if (lnReturn < 0)
			loHeap = null
			RELEASE loHeap
			this.lError = .t.
			this.cError = "Could not Initilize Ghostscript."
			return .f.
		endif

		* Stop the Ghostscript interpreter
		lnReturn=gsapi_exit(lnGSInstanceHandle)
		if (lnReturn < 0)
			loHeap = null
			RELEASE loHeap
			this.lError = .t.
			this.cError = "Could not Exit Ghostscript."
			return .f.
		endif


		* release the Ghostscript instance handle'
		=gsapi_delete_instance(lnGSInstanceHandle)

		loHeap = null
		RELEASE loHeap

		if !file(tcFileOut)
			this.lError = .t.
			this.cError = "Ghostscript could not create the PDF."
			return .f.
		endif

		return .t.
	endfunc



	**************************************************************************************
	* InstPDFReader Method - Installs the PDFReader if needed
	**************************************************************************************
	function InstPDFReader()
		**Make sure the PDF file has been created
		if !file(.cOutputFile)
			return .f.
		endif

		**Ask Windows which EXE is associated with this file (extension)
		lcExe = .AssocExe(.cOutputFile)

		if empty(lcExe)
			**Install the PDF Reader
			return .Install("PDFREADER")
		else
			return .t.
		endif
	endfunc


	**************************************************************************************
	* AssocExe Method - Returns the Executable File associated with a file
	**************************************************************************************
	function AssocExe(pcFile)
		local lcExeFile
		store "" to lcExeFile

		declare integer FindExecutable in shell32;
			string   lpFile,;
			string   lpDirectory,;
			string @ lpResult

		lcExeFile = space(250)

		if FindExecutable(pcFile, "", @lcExeFile) > 32
			lcExeFile = left(lcExeFile, at(chr(0), lcExeFile) -1)
		else
			lcExeFile = ""
		endif

		return lcExeFile
	endfunc


	**************************************************************************************
	* Install Method - Installs software on the PC
	**************************************************************************************
	function Install(pcID)
		local llFound, x, lcEval, lcProduct, lcDesc, lcTmp, ;
				lcFolder, lcInstEXE, lcInstruct, llDynaPath
		store "" to lcEval, lcProduct, lcAbbr, lcDesc, lcTmp, lcFolder, lcInstEXE, lcInstruct
		store .f. to llFound, llDynaPath

		with this
			pcID = alltrim(upper(pcID))

			**See if this Installation ID is in our array
			for x = 1 to alen(.aInstall,1)
				if alltrim(upper(.aInstall[x,1])) == pcID
					llFound = .t.
					exit
				endif
			endfor

			if !llFound
				.lError = .t.
				.cError = "Installation parms do not exist for ID: "+pcID
				return .f.
			endif

			**Copy array contents to variables
			llDoInst	= .aInstall[x,2]
			lcProduct	= .aInstall[x,3]
			lcDesc		= .aInstall[x,4]
			lcFolder	= .aInstall[x,5]
			lcInstEXE	= .aInstall[x,6]
			if !empty(.aInstall[x,7])
				lcInstruct	= ALLTRIM(.aInstall[x,7])
				if "+" $ lcInstruct
					lcInstruct = &lcInstruct
				endif
			else
				lcInstruct	= "Please accept the 'Default Values'"+chr(13)+"during the installation."
			endif

			**See if the path is "dynamically" generated based on variables
			if "+" $ lcFolder
				llDynaPath = .t.
			else
				llDynaPath = .f.
			endif
			
			**Are we allowed to install this product?
			if llDoInst = .t.
				**Make sure we have the Folder and Executable to install from?
				if !empty(lcFolder) and !empty(lcInstEXE)
					if llDynaPath
						lcFolder = alltrim(lcFolder)
						lcEval = &lcFolder
						lcEval = lcEval+alltrim(lcInstEXE)	&&command string
					else
						if right(lcFolder,1) <> "\"				&&Make sure the final backslash exists
							lcFolder = lcFolder + "\"
						endif
				
						lcEval = alltrim(lcFolder)+alltrim(lcInstEXE)	&&command string
					endif

					**Make sure install .exe exists in the path given
					if !llDynaPath and !file(lcEval)
						.cError = "Could not find installer for "+lcProduct+" in:"+chr(13)+alltrim(lcEval)
						.lError = .t.
					else
						if 7=messagebox(lcProduct+" needs to be installed on your computer."+chr(13)+;
								lcDesc+chr(13)+;
								"Is it OK to install now?",36,"Confirmation")
							.lError = .t.
							.cError = "User cancelled "+lcProduct+" Installation."
							return .f.
						endif

						=messagebox(lcInstruct,64,"Instructions")

						**Do the Installation
						.aInstall[x,2] = .f.		&&Do not allow ourselves to get into a loop
						lcEval = "run /n "+lcEval
						&lcEval

						=messagebox("When the Installation has finished"+chr(13)+;
							"COMPLETELY, please click OK...",64,"Waiting for Installation...")

						**Did it work?
						if 7=messagebox("Was the installation successfull?"+chr(13)+chr(13)+;
								"If no errors ocurred during the Installation"+chr(13)+;
								"and everything went OK, please click 'Yes'...",36,"Everything OK?")
							.lError = .t.
							.cError = "Errors ocurred during "+lcProduct+" Installation."
							return .f.
						else
							.lError = .f.
							.cError = ""
							return .t.
						endif
					endif
				endif
			endif
		endwith
		return .f.
	endfunc

enddefine

*** End of Class Print2PDF ***




**************************************************
*-- Class:        heap 
*-- ParentClass:  custom
*-- BaseClass:    custom
*
*  Another in the family of relatively undocumented sample classes I've inflicted on others
*  Warning - there's no error handling in here, so be careful to check for null returns and
*  invalid pointers.  Unless you get frisky, or you're resource-tight, it should work well.
*
*	Please read the code and comments carefully.  I've tried not to assume much knowledge about
*	just how pointers work, or how memory allocation works, and have tried to explain some of the
*	basic concepts behing memory allocation in the Win32 environment, without having gone into
*	any real details on x86 memory management or the Win32 memory model.  If you want to explore
*	these things (and you should), start by reading Jeff Richter's _Advanced Windows_, especially
*	Chapters 4-6, which deal with the Win32 memory model and virtual memory -really- well.
*
*	Another good source iss Walter Oney's _Systems Programming for Windows 95_.  Be warned that 
*	both of these books are targeted at the C programmer;  to someone who has only worked with
*	languages like VFP or VB, it's tough going the first couple of dozen reads.
*
*	Online resources - http://www.x86.org is the Intel Secrets Homepage.  Lots of deep, dark
*	stuff about the x86 architecture.  Not for the faint of heart.  Lots of pointers to articles
*	from DDJ (Doctor Dobbs Journal, one of the oldest and best magazines on microcomputing.)
*
*   You also might want to take a look at the transcripts from my "Pointers on Pointers" chat
*   sessions, which are available in the WednesdayNightLectureSeries topic on the Fox Wiki,
*   http://fox.wikis.com - the Wiki is a great Web site;  it provides a vast store of information
*   on VFP and related topics, and is probably the best tool available now to develop topics in
*   a collaborative environment.  Well worth checking out - it's a very different mechanism for
*   ongoing discussion of a subject.  It's an on-line message base or chat;  I find
*   myself hitting it when I have a question to see if an answer already exists.  It's
*   much like using a FAQ, except that most things on the Wiki are editable...
*
*	Post-DevCon 2000 revisions:
*
*	After some bizarre errors at DevCon, I reworked some of the methods to
*	consistently return a NULL whenever a bad pointer/inactive pointer in the
*	iaAllocs member array was encountered.  I also implemented NumToLong
*	using RtlMoveMemory(), relying on a BITOR() to recast what would otherwise
*	be a value with the high-order bit set.  The result is it's faster, and
*  an anomaly reported with values between 0xFFFFFFF1-0xFFFFFFFF goes away,
*	at the expense of representing these as negative numbers.  Pointer math
*	still works.
*
*****
*	How HEAP works:
*
*	Overwhelming guilt hit early this morning;  maybe I should explain the 
*	concept of the Heap class	and give an example of how to use it, in 
*	conjunction with the add-on functions that follow in this proc library.
*
*	Windows allocates memory from several places;  it also provides a 
*	way to define your own small corner of the universe where you can 
*	allocate and deallocate blocks of memory for your own purposes.  These
*	public or private memory areas are referred to commonly as heaps.
*
*	VFP is great in most cases;  it provides flexible allocation and 
*	alteration of variables on the fly in a program.  You don't need to 
*	know much about how things are represented internally. This makes 
*	most programming tasks easy.  However, in exchange for VFP's flexibility 
*	in memory variable allocation, we give up several things, the most 
*	annoying of which are not knowing the exact location of a VFP 
*	variable in memory, and not knowing exactly how things are constructed 
*	inside a variable, both of which make it hard to define new kinds of 
*	memory structures within VFP to manipulate as a C-style structure.
*
*	Enter Heap.  Heap creates a growable, private heap, from which you 
*	can allocate blocks of memory that have a known location and size 
*	in your memory address space.  It also provides a way of transferring
*	data to and from these allocated blocks.  You build structures in VFP 
*	strings, and parse the content of what is returned in those blocks by 
*	extracting substrings from VFP strings.
*
*	Heap does its work using a number of Win32 API functions;  HeapCreate(), 
*	which sets up a private heap and assigns it a handle, is invoked in 
*	the Init method.  This sets up the 'heap', where block allocations
*	for the object will be constructed.  I set up the heap to use a base 
*	allocation size of twice the size of a swap file 'page' in the x86 
*	world (8K), and made the heap able to grow;  it adds 8K chunks of memory
*	to itself as it grows.  There's no fixed limit (other than available 
*	-virtual- memory) on the size of the heap constructed;  just realize 
*	that huge allocations are likely to bump heads with VFP's own desire
*	for mondo RAM.
*
*	Once the Heap is established, we can allocate blocks of any size we 
*	want in Heap, outside of VFP's memory, but within the virtual 
*	address space owned by VFP.  Blocks are allocated by HeapAlloc(), and a
*	pointer to the block is returned as an integer.  
*
*	KEEP THE POINTER RETURNED BY ANY Alloc method, it's the key to 
*	doing things with the block in the future.  In addition to being a
*	valid pinter, it's the key to finding allocations tracked in iaAllocs[]
*
*	Periodically, we need to load things into the block we've created.  
*	Thanks to work done by Christof Lange, George Tasker and others, 
*	we found a Win32API call that will do transfers between memory 
*	locations, called RtlMoveMemory().  RtlMoveMemory() acts like the 
*	Win32API MoveMemory() call;  it takes two pointers (destination 
*	and source) and a length.  In order to make life easy, at times 
*	we DECLARE the pointers as INTEGER (we pass a number, which is 
*	treated as a DWORD (32 bit unsigned integer) whose content is the
*	address to use), and at other times as STRING @, which passes the 
*	physical address of a VFP string variable's contents, allowing 
*	RtlMoveMemory() to read and write VFP strings without knowing how 
*	to manipulate VFP's internal variable structures.  RtlMoveMemory() 
*	is used by both the CopyFrom and CopyTo methods, and the enhanced
*	Alloc methods.
*
*	At some point, we're finished with a block of memory.  We can free up 
*	that memory via HeapFree(), which releases a previously-allocated 
*	block on the heap.  It does not compact or rearrange the heap allocations
*	but simply makes the memory allocated no longer valid, and the 
*	address could be reused by another Alloc operation.  We track the 
*	active state of allocations in a member array iaAllocs[] which has 
*	3 members per row;  the pointer, which is used as a key, the actual 
*	size of the allocation (sometimes HeapAlloc() gives you a larger block 
*	than requested;  we can see it here.  This is the property returned 
*	by the SizeOfBlock method) and whether or not it's active and available.
*
*	When we're done with a Heap, we need to release the allocations and 
*	the heap itself.  HeapDestroy() releases the entire heap back to the 
*	Windows memory pool.  This is invoked in the Destroy method of the 
*	class to ensure that it gets explcitly released, since it remains alive 
*	until it is explicitly released or the owning process is released.  I 
*	put this in the Destroy method to ensure that the heap went away when 
*	the Heap object went out of scope.
*
*	The original class methods are:
*
*		Init					Creates the heap for use
*		Alloc(nSize)		Allocates a block of nSize bytes, returns an nPtr 
*								to it.  nPtr is NULL if fail
*		DeAlloc(nPtr)		Releases the block whose base address is nPtr.  
*								Returns .T./.F.
*		CopyTo(nPtr,cSrc)	Copies the Content of cSrc to the buffer at nPtr, 
*								up to the smaller of LEN(cSrc) or the length of 
*								the block (we look in the iaAllocs[] array).  
*								Returns .T./.F.
*		CopyFrom(nPtr)		Copies the content of the block at nPtr (size is 
*								from iaAllocs[]) and returns it as a VFP string.  
*								Returns a string, or NULL if fail
*		SizeOfBlock(nPtr)	Returns the actual allocated size of the block 
*								pointed to by nPtr.  Returns NULL if fail 
*		Destroy()			DeAllocs anything still active, and then frees 
*								the heap.
*****
*  New methods added 2/12/99 EMR -	Attack of the Creeping Feature Creature, 
*												part I
*
*	There are too many times when you know what you want to put in 
*	a buffer when you allocate it, so why not pass what you want in 
*	the buffer when you allocate it?  And we may as well add an option to
*	init the memory to a known value easily, too:
*
*		AllocBLOB(cSrc)	Allocate a block of SizeOf(cSrc) bytes and 
*								copy cSrc content to it
*		AllocString(cSrc)	Allocate a block of SizeOf(cSrc) + 1 bytes and 
*								copy cSrc content to it, adding a null (CHR(0)) 
*								to the end to make it a standard C-style string
*		AllocInitAs(nSize,nVal)
*								Allocate a block of nSize bytes, preinitialized 
*								with CHR(nVal).  If no nVal is passed, or nVal 
*								is illegal (not a number 0-255), init with nulls
*
*****
*	Property changes 9/29/2000
*
*	iaAllocs[] is now protected
*
*****
*	Method modifications 9/29/2000:
*
*	All lookups in iaAllocs[] are now done using the new FindAllocID()
*	method, which returns a NULL for the ID if not found active in the
*	iaAllocs[] entries.  Result is less code and more consistent error
*	handling, based on checking ISNULL() for pointers.
*
*****
*	The ancillary goodies in the procedure library are there to make life 
*	easier for people working with structures; they are not optimal 
*	and infinitely complete, but they do the things that are commonly 
*	needed when dealing with stuff in structures.  The functions are of 
*	two types;  converters, which convert standard C structures to an
*	equivalent VFP numeric, or make a string whose value is equivalent 
*	to a C data type from a number, so that you can embed integers, 
*	pointers, etc. in the strings used to assemble a structure which you 
*	load up with CopyTo, or pull out pointers and integers that come back 
*	embedded in a structure you've grabbed with CopyFrom.
*
*	The second type of functions provided are memory copiers.  The 
*	CopyFrom and CopyTo methods are set up to work with our heap, 
*	and nPtrs must take on the values of block addresses grabbed 
*	from our heap.  There will be lots of times where you need to 
*	get the content of memory not necessarily on our heap, so 
*	SetMem, GetMem and GetMemString go to work for us here.  SetMem 
*	copies the content of a string into the absolute memory block
*	at nPtr, for the length of the string, using RtlMoveMemory(). 
*	BE AWARE THAT MISUSE CAN (and most likely will) RESULT IN 
*	0xC0000005 ERRORS, memory access violations, or similar OPERATING 
*	SYSTEM level errors that will smash VFP like an empty beer can in 
*	a trash compactor.
*
*	There are two functions to copy things from a known address back 
*	to the VFP world.  If you know the size of the block to grab, 
*	GetMem(nPtr,nSize) will copy nSize bytes from the address nPtr 
*	and return it as a VFP string.  See the caveat above.  
*	GetMemString(nPtr) uses a different API call, lstrcpyn(), to 
*	copy a null terminated string from the address specified by nPtr. 
*	You can hurt yourself with this one, too.
*
*	Functions in the procedure library not a part of the class:
*
*	GetMem(nPtr,nSize)	Copy nSize bytes at address nPtr into a VFP string
*	SetMem(nPtr,cSource)	Copy the string in cSource to the block beginning 
*								at nPtr
*	GetMemString(nPtr)	Get the null-terminated string (up to 512 bytes) 
*								from the address at nPtr
*
*	DWORDToNum(cString)	Convert the first 4 bytes of cString as a DWORD 
*								to a VFP numeric (0 to 2^32)
*	SHORTToNum(cString)	Convert the first 2 bytes of cString as a SHORT 
*								to a VFP numeric (-32768 to 32767)
*	WORDToNum(cString)	Convert the first 2 bytes of cString as a WORD 
*								to a VFP numeric  (0 to 65535)
*	NumToDWORD(nInteger)	Converts nInteger into a string equivalent to a 
*								C DWORD (4 byte unsigned)
*	NumToWORD(nInteger)	Converts nInteger into a string equivalent to a 
*								C WORD (2 byte unsigned)
*	NumToSHORT(nInteger)	Converts nInteger into a string equivalent to a 
*								C SHORT ( 2 byte signed)
*
******
*	New external functions added 2/13/99
*
*	I see a need to handle NetAPIBuffers, which are used to transfer 
*	structures for some of the Net family of API calls;  their memory 
*	isn't on a user-controlled heap, but is mapped into the current 
*	application address space in a special way.  I've added two 
*	functions to manage them, but you're responsible for releasing 
*	them yourself.  I could implement a class, but in many cases, a 
*	call to the API actually performs the allocation for you.  The 
*	two new calls are:
*
*	AllocNetAPIBuffer(nSize)	Allocates a NetAPIBuffer of at least 
*										nBytes, and returns a pointer
*										to it as an integer.  A NULL is returned 
*										if allocation fails.
*	DeAllocNetAPIBuffer(nPtr)	Frees the NetAPIBuffer allocated at the 
*										address specified by nPtr.  It returns 
*										.T./.F. for success and failure
*
*	These functions are only available under NT, and will return 
*	NULL or .F. under Win9x
*
*****
*	Function changes 9/29/2000
*
*	NumToDWORD(tnNum)		Redirected to NumToLONG()
*	NumToLONG(tnNum)		Generates a 32 bit LONG from the VFP number, recast
*								using BITOR() as needed
*	LONGToNum(tcLong)		Extracts a signed VFP INTEGER from a 4 byte string
*
*****
*	That's it for the docs to date;  more stuff to come.  The code below 
*	is copyright Ed Rauh, 1999;  you may use it without royalties in 
*	your own code as you see fit, as long as the code is attributed to me.
*
*	This is provided as-is, with no implied warranty.  Be aware that you 
*	can hurt yourself with this code, most *	easily when using the 
*	SetMem(), GetMem() and GetMemString() functions.  I will continue to 
*	add features and functions to this periodically.  If you find a bug, 
*	please notify me.  It does no good to tell me that "It doesn't work 
*	the way I think it should..WAAAAH!"  I need to know exactly how things 
*	fail to work with the code I supplied.  A small code snippet that can 
*	be used to test the failure would be most helpful in trying
*	to track down miscues.  I'm not going to run through hundreds or 
*	thousands of lines of code to try to track down where exactly 
*	something broke.  
*
*	Please post questions regarding this code on Universal Thread;  I go out 
*	there regularly and will generally respond to questions posed in the
*	message base promptly (not the Chat).  http://www.universalthread.com
*	In addition to me, there are other API experts who frequent UT, and 
*	they may well be able to help, in many cases better than I could.  
*	Posting questions on UT helps not only with getting support
*	from the VFP community at large, it also makes the information about 
*	the problem and its solution available to others who might have the 
*	same or similar problems.
*
*	Other than by UT, especially if you have to send files to help 
*	diagnose the problem, send them to me at edrauh@earthlink.net or 
*	erauh@snet.net, preferably the earthlink.net account.
*
*	If you have questions about this code, you can ask.  If you have 
*	questions about using it with API calls and the like, you can ask.  
*	If you have enhancements that you'd like to see added to the code, 
*	you can ask, but you have the source, and ought to add them yourself.
*	Flames will be ignored.  I'll try to answer promptly, but realize 
*	that support and enhancements for this are done in my own spare time.  
*	If you need specific support that goes beyond what I feel is 
*	reasonable, I'll tell you.
*
*	Do not call me at home or work for support.  Period. 
*	<Mumble><something about ripping out internal organs><Grr>
*
*	Feel free to modify this code to fit your specific needs.  Since 
*	I'm not providing any warranty with this in any case, if you change 
*	it and it breaks, you own both pieces.
*
DEFINE CLASS heap AS custom


	PROTECTED inHandle, inNumAllocsActive,iaAllocs[1,3]
	inHandle = NULL
	inNumAllocsActive = 0
	iaAllocs = NULL
	Name = "heap"

	PROCEDURE Alloc
		*  Allocate a block, returning a pointer to it
		LPARAMETER nSize
		DECLARE INTEGER HeapAlloc IN WIN32API AS HAlloc;
			INTEGER hHeap, ;
			INTEGER dwFlags, ;
			INTEGER dwBytes
		DECLARE INTEGER HeapSize IN WIN32API AS HSize ;
			INTEGER hHeap, ;
			INTEGER dwFlags, ;
			INTEGER lpcMem
		LOCAL nPtr
		WITH this
			nPtr = HAlloc(.inHandle, 0, @nSize)
			IF nPtr # 0
				*  Bump the allocation array
				.inNumAllocsActive = .inNumAllocsActive + 1
				DIMENSION .iaAllocs[.inNumAllocsActive,3]
				*  Pointer
				.iaAllocs[.inNumAllocsActive,1] = nPtr
				*  Size actually allocated - get with HeapSize()
				.iaAllocs[.inNumAllocsActive,2] = HSize(.inHandle, 0, nPtr)
				*  It's alive...alive I tell you!
				.iaAllocs[.inNumAllocsActive,3] = .T.
			ELSE
				*  HeapAlloc() failed - return a NULL for the pointer
				nPtr = NULL
			ENDIF
		ENDWITH
		RETURN nPtr
	ENDPROC

*	new methods added 2/11-2/12;  pretty simple, actually, but they make 
*	coding using the heap object much cleaner.  In case it isn't clear, 
*	what I refer to as a BString is just the normal view of a VFP string 
*	variable;  it's any array of char with an explicit length, as opposed 
*	to the normal CString view of the world, which has an explicit
*	terminator (the null char at the end.)

	FUNCTION AllocBLOB
		*	Allocate a block of memory the size of the BString passed.  The 
		*	allocation will be at least LEN(cBStringToCopy) off the heap.
		LPARAMETER cBStringToCopy
		LOCAL nAllocPtr
		WITH this
			nAllocPtr = .Alloc(LEN(cBStringToCopy))
			IF ! ISNULL(nAllocPtr)
				.CopyTo(nAllocPtr,cBStringToCopy)
			ENDIF
		ENDWITH
		RETURN nAllocPtr
	ENDFUNC
	
	FUNCTION AllocString
		*	Allocate a block of memory to fill with a null-terminated string
		*	make a null-terminated string by appending CHR(0) to the end
		*	Note - I don't check if a null character precedes the end of the
		*	inbound string, so if there's an embedded null and whatever is
		*	using the block works with CStrings, it might bite you.
		LPARAMETER cString
		RETURN this.AllocBLOB(cString + CHR(0))
	ENDFUNC
	
	FUNCTION AllocInitAs
		*  Allocate a block of memory preinitialized to CHR(nByteValue)
		LPARAMETER nSizeOfBuffer, nByteValue
		IF TYPE('nByteValue') # 'N' OR ! BETWEEN(nByteValue,0,255)
			*	Default to initialize with nulls
			nByteValue = 0
		ENDIF
		RETURN this.AllocBLOB(REPLICATE(CHR(nByteValue),nSizeOfBuffer))
	ENDFUNC

*	This is the end of the new methods added 2/12/99

	PROCEDURE DeAlloc
		*  Discard a previous Allocated block
		LPARAMETER nPtr
		DECLARE INTEGER HeapFree IN WIN32API AS HFree ;
			INTEGER hHeap, ;
			INTEGER dwFlags, ;
			INTEGER lpMem
		LOCAL nCtr
		* Change to use .FindAllocID() and return !ISNULL() 9/29/2000 EMR
		nCtr = NULL
		WITH this
			nCtr = .FindAllocID(nPtr)
			IF ! ISNULL(nCtr)
				=HFree(.inHandle, 0, nPtr)
				.iaAllocs[nCtr,3] = .F.
			ENDIF
		ENDWITH
		RETURN ! ISNULL(nCtr)
	ENDPROC


	PROCEDURE CopyTo
		*  Copy a VFP string into a block
		LPARAMETER nPtr, cSource
		*  ReDECLARE RtlMoveMemory to make copy parameters easy
		DECLARE RtlMoveMemory IN WIN32API AS RtlCopy ;
			INTEGER nDestBuffer, ;
			STRING @pVoidSource, ;
			INTEGER nLength
		LOCAL nCtr
		nCtr = NULL
		* Change to use .FindAllocID() and return ! ISNULL() 9/29/2000 EMR
		IF TYPE('nPtr') = 'N' AND TYPE('cSource') $ 'CM' ;
		   AND ! (ISNULL(nPtr) OR ISNULL(cSource))
			WITH this
				*  Find the Allocation pointed to by nPtr
				nCtr = .FindAllocID(nPtr)
				IF ! ISNULL(nCtr)
					*  Copy the smaller of the buffer size or the source string
					=RtlCopy((.iaAllocs[nCtr,1]), ;
							cSource, ;
							MIN(LEN(cSource),.iaAllocs[nCtr,2]))
				ENDIF
			ENDWITH
		ENDIF
		RETURN ! ISNULL(nCtr)
	ENDPROC


	PROCEDURE CopyFrom
		*  Copy the content of a buffer back to the VFP world
		LPARAMETER nPtr
		*  Note that we reDECLARE RtlMoveMemory to make passing things easier
		DECLARE RtlMoveMemory IN WIN32API AS RtlCopy ;
			STRING @DestBuffer, ;
			INTEGER pVoidSource, ;
			INTEGER nLength
		LOCAL nCtr, uBuffer
		uBuffer = NULL
		nCtr = NULL
		* Change to use .FindAllocID() and return NULL 9/29/2000 EMR
		IF TYPE('nPtr') = 'N' AND ! ISNULL(nPtr)
			WITH this
				*  Find the allocation whose address is nPtr
				nCtr = .FindAllocID(nPtr)
				IF ! ISNULL(nCtr)
					* Allocate a buffer in VFP big enough to receive the block
					uBuffer = REPL(CHR(0),.iaAllocs[nCtr,2])
					=RtlCopy(@uBuffer, ;
							(.iaAllocs[nCtr,1]), ;
							(.iaAllocs[nCtr,2]))
				ENDIF
			ENDWITH
		ENDIF
		RETURN uBuffer
	ENDPROC
	
	PROTECTED FUNCTION FindAllocID
	 	*   Search for iaAllocs entry matching the pointer
	 	*   passed to the function.  If found, it returns the 
	 	*   element ID;  returns NULL if not found
	 	LPARAMETER nPtr
	 	LOCAL nCtr
	 	WITH this
			FOR nCtr = 1 TO .inNumAllocsActive
				IF .iaAllocs[nCtr,1] = nPtr AND .iaAllocs[nCtr,3]
					EXIT
				ENDIF
			ENDFOR
			RETURN IIF(nCtr <= .inNumAllocsActive,nCtr,NULL)
		ENDWITH
	ENDPROC

	PROCEDURE SizeOfBlock
		*  Retrieve the actual memory size of an allocated block
		LPARAMETERS nPtr
		LOCAL nCtr, nSizeOfBlock
		nSizeOfBlock = NULL
		* Change to use .FindAllocID() and return NULL 9/29/2000 EMR
		WITH this
			*  Find the allocation whose address is nPtr
			nCtr = .FindAllocID(nPtr)
			RETURN IIF(ISNULL(nCtr),NULL,.iaAllocs[nCtr,2])
		ENDWITH
	ENDPROC

	PROCEDURE Destroy
		DECLARE HeapDestroy IN WIN32API AS HDestroy ;
		  INTEGER hHeap

		LOCAL nCtr
		WITH this
			FOR nCtr = 1 TO .inNumAllocsActive
				IF .iaAllocs[nCtr,3]
					.Dealloc(.iaAllocs[nCtr,1])
				ENDIF
			ENDFOR
			HDestroy[.inHandle]
		ENDWITH
		DODEFAULT()
	ENDPROC


	PROCEDURE Init
		DECLARE INTEGER HeapCreate IN WIN32API AS HCreate ;
			INTEGER dwOptions, ;
			INTEGER dwInitialSize, ;
			INTEGER dwMaxSize
		#DEFINE SwapFilePageSize  4096
		#DEFINE BlockAllocSize    2 * SwapFilePageSize
		WITH this
			.inHandle = HCreate(0, BlockAllocSize, 0)
			DIMENSION .iaAllocs[1,3]
			.iaAllocs[1,1] = 0
			.iaAllocs[1,2] = 0
			.iaAllocs[1,3] = .F.
			.inNumAllocsActive = 0
		ENDWITH
		RETURN (this.inHandle # 0)
	ENDPROC


ENDDEFINE
*
*-- EndDefine: heap
**************************************************
*
*  Additional functions for working with structures and pointers and stuff
*
FUNCTION SetMem
LPARAMETERS nPtr, cSource
*  Copy cSource to the memory location specified by nPtr
*  ReDECLARE RtlMoveMemory to make copy parameters easy
*  nPtr is not validated against legal allocations on the heap
DECLARE RtlMoveMemory IN WIN32API AS RtlCopy ;
	INTEGER nDestBuffer, ;
	STRING @pVoidSource, ;
	INTEGER nLength

RtlCopy(nPtr, ;
		cSource, ;
		LEN(cSource))
RETURN .T.

FUNCTION GetMem
LPARAMETERS nPtr, nLen
*  Copy the content of a memory block at nPtr for nLen bytes back to a VFP string
*  Note that we ReDECLARE RtlMoveMemory to make passing things easier
*  nPtr is not validated against legal allocations on the heap
DECLARE RtlMoveMemory IN WIN32API AS RtlCopy ;
	STRING @DestBuffer, ;
	INTEGER pVoidSource, ;
	INTEGER nLength
LOCAL uBuffer
* Allocate a buffer in VFP big enough to receive the block
uBuffer = REPL(CHR(0),nLen)
=RtlCopy(@uBuffer, ;
		 nPtr, ;
		 nLen)
RETURN uBuffer

FUNCTION GetMemString
LPARAMETERS nPtr, nSize
*  Copy the string at location nPtr into a VFP string
*  We're going to use lstrcpyn rather than RtlMoveMemory to copy up to a terminating null
*  nPtr is not validated against legal allocations on the heap
*
*	Change 9/29/2000 - second optional parameter nSize added to allow an override
*	of the string length;  no major expense, but probably an open invitation
*	to cliff-diving, since variant CStrings longer than 511 bytes, or less
*	often, 254 bytes, will generally fall down go Boom!
*
DECLARE INTEGER lstrcpyn IN WIN32API AS StrCpyN ;
	STRING @ lpDestString, ;
	INTEGER lpSource, ;
	INTEGER nMaxLength
LOCAL uBuffer
IF TYPE('nSize') # 'N' OR ISNULL(nSize)
	nSize = 512
ENDIF
*  Allocate a buffer big enough to receive the data
uBuffer = REPL(CHR(0), nSize)
IF StrCpyN(@uBuffer, nPtr, nSize-1) # 0
	uBuffer = LEFT(uBuffer, MAX(0,AT(CHR(0),uBuffer) - 1))
ELSE
	uBuffer = NULL
ENDIF
RETURN uBuffer

FUNCTION SHORTToNum
	* Converts a 16 bit signed integer in a structure to a VFP Numeric
 	LPARAMETER tcInt
	LOCAL b0,b1,nRetVal
	b0=asc(tcInt)
	b1=asc(subs(tcInt,2,1))
	if b1<128
		*
		*  positive - do a straight conversion
		*
		nRetVal=b1 * 256 + b0
	else
		*
		*  negative value - take twos complement and negate
		*
		b1=255-b1
		b0=256-b0
		nRetVal= -( (b1 * 256) + b0)
	endif
	return nRetVal

FUNCTION NumToSHORT
*
*  Creates a C SHORT as a string from a number
*
*  Parameters:
*
*	tnNum			(R)  Number to convert
*
	LPARAMETER tnNum
	*
	*  b0, b1, x hold small ints
	*
	LOCAL b0,b1,x
	IF tnNum>=0
		x=INT(tnNum)
		b1=INT(x/256)
		b0=MOD(x,256)
	ELSE
		x=INT(-tnNum)
		b1=255-INT(x/256)
		b0=256-MOD(x,256)
		IF b0=256
			b0=0
			b1=b1+1
		ENDIF
	ENDIF
	RETURN CHR(b0)+CHR(b1)

FUNCTION DWORDToNum
	* Take a binary DWORD and convert it to a VFP Numeric
	* use this to extract an embedded pointer in a structure in a string to an nPtr
	LPARAMETER tcDWORD
	LOCAL b0,b1,b2,b3
	b0=asc(tcDWORD)
	b1=asc(subs(tcDWORD,2,1))
	b2=asc(subs(tcDWORD,3,1))
	b3=asc(subs(tcDWORD,4,1))
	RETURN ( ( (b3 * 256 + b2) * 256 + b1) * 256 + b0)

*!*	FUNCTION NumToDWORD
*!*	*
*!*	*  Creates a 4 byte binary string equivalent to a C DWORD from a number
*!*	*  use to embed a pointer or other DWORD in a structure
*!*	*  Parameters:
*!*	*
*!*	*	tnNum			(R)  Number to convert
*!*	*
*!*	 	LPARAMETER tnNum
*!*	 	*
*!*	 	*  x,n,i,b[] will hold small ints
*!*	 	*
*!*	 	LOCAL x,n,i,b[4]
*!*		x=INT(tnNum)
*!*		FOR i=3 TO 0 STEP -1
*!*			b[i+1]=INT(x/(256^i))
*!*			x=MOD(x,(256^i))
*!*		ENDFOR
*!*		RETURN CHR(b[1])+CHR(b[2])+CHR(b[3])+CHR(b[4])
*			Redirected to NumToLong() using recasting;  comment out
*			the redirection and uncomment NumToDWORD() if original is needed
FUNCTION NumToDWORD
	LPARAMETER tnNum
	RETURN NumToLong(tnNum)
*			End redirection

FUNCTION WORDToNum
	*	Take a binary WORD (16 bit USHORT) and convert it to a VFP Numeric
	LPARAMETER tcWORD
	RETURN (256 *  ASC(SUBST(tcWORD,2,1)) ) + ASC(tcWORD)

FUNCTION NumToWORD
*
*  Creates a C USHORT (WORD) from a number
*
*  Parameters:
*
*	tnNum			(R)  Number to convert
*
	LPARAMETER tnNum
	*
	*  x holds an int
	*
	LOCAL x
	x=INT(tnNum)
	RETURN CHR(MOD(x,256))+CHR(INT(x/256))
	
FUNCTION NumToLong
*
*  Creates a C LONG (signed 32-bit) 4 byte string from a number
*  NB:  this works faster than the original NumToDWORD(), which could have
*	problems with trunaction of values > 2^31 under some versions of VFP with
*	#DEFINEd or converted constant values in excess of 2^31-1 (0x7FFFFFFF).
*	I've redirected NumToDWORD() and commented it out; NumToLong()
*	expects to work with signed values and uses BITOR() to recast values
*  in the range of -(2^31) to (2^31-1), 0xFFFFFFFF is not the same
*  as -1 when represented in an N-type field.  If you don't need to
*  use constants with the high-order bit set, or are willing to let
*  the UDF cast the value consistently, especially using pointer math 
*	on the system's part of the address space, this and its counterpart 
*	LONGToNum() are the better choice for speed, or to save to an I-field.
*
*  To properly cast a constant/value with the high-order bit set, you
*  can BITOR(nVal,0);  0xFFFFFFFF # -1 but BITOR(0xFFFFFFFF,0) = BITOR(-1,0)
*  is true, and converts the N-type in the range 2^31 - (2^32-1) to a
*  twos-complement negative integer value.  You can disable BITOR() casting
*  in this function by commenting the proper line in this UDF();  this 
*	results in a slight speed increase.
*
*  Parameters:
*
*  tnNum			(R)	Number to convert
*
	LPARAMETER tnNum
	DECLARE RtlMoveMemory IN WIN32API AS RtlCopyLong ;
		STRING @pDestString, ;
		INTEGER @pVoidSource, ;
		INTEGER nLength
	LOCAL cString
	cString = SPACE(4)
*	Function call not using BITOR()
*	=RtlCopyLong(@cString, tnNum, 4)
*  Function call using BITOR() to cast numerics
   =RtlCopyLong(@cString, BITOR(tnNum,0), 4)
	RETURN cString
	
FUNCTION LongToNum
*
*	Converts a 32 bit LONG to a VFP numeric;  it treats the result as a
*	signed value, with a range -2^31 - (2^31-1).  This is faster than
*	DWORDToNum().  There is no one-function call that causes negative
*	values to recast as positive values from 2^31 - (2^32-1) that I've
*	found that doesn't take a speed hit.
*
*  Parameters:
*
*  tcLong			(R)	4 byte string containing the LONG
*
	LPARAMETER tcLong
	DECLARE RtlMoveMemory IN WIN32API AS RtlCopyLong ;
		INTEGER @ DestNum, ;
		STRING @ pVoidSource, ;
		INTEGER nLength
	LOCAL nNum
	nNum = 0
	=RtlCopyLong(@nNum, tcLong, 4)
	RETURN nNum
	
FUNCTION AllocNetAPIBuffer
*
*	Allocates a NetAPIBuffer at least nBtes in Size, and returns a pointer
*	to it as an integer.  A NULL is returned if allocation fails.
*	The API call is not supported under Win9x
*
*	Parameters:
*
*		nSize			(R)	Number of bytes to allocate
*
LPARAMETER nSize
IF TYPE('nSize') # 'N' OR nSize <= 0
	*	Invalid argument passed, so return a null
	RETURN NULL
ENDIF
IF ! 'NT' $ OS()
	*	API call only supported under NT, so return failure
	RETURN NULL
ENDIF
DECLARE INTEGER NetApiBufferAllocate IN NETAPI32.DLL ;
	INTEGER dwByteCount, ;
	INTEGER lpBuffer
LOCAL  nBufferPointer
nBufferPointer = 0
IF NetApiBufferAllocate(INT(nSize), @nBufferPointer) # 0
	*  The call failed, so return a NULL value
	nBufferPointer = NULL
ENDIF
RETURN nBufferPointer

FUNCTION DeAllocNetAPIBuffer
*
*	Frees the NetAPIBuffer allocated at the address specified by nPtr.
*	The API call is not supported under Win9x
*
*	Parameters:
*
*		nPtr			(R) Address of buffer to free
*
*	Returns:			.T./.F.
*
LPARAMETER nPtr
IF TYPE('nPtr') # 'N'
	*	Invalid argument passed, so return failure
	RETURN .F.
ENDIF
IF ! 'NT' $ OS()
	*	API call only supported under NT, so return failure
	RETURN .F.
ENDIF
DECLARE INTEGER NetApiBufferFree IN NETAPI32.DLL ;
	INTEGER lpBuffer
RETURN (NetApiBufferFree(INT(nPtr)) = 0)

Function CopyDoubleToString
LPARAMETER nDoubleToCopy
*  ReDECLARE RtlMoveMemory to make copy parameters easy
DECLARE RtlMoveMemory IN WIN32API AS RtlCopyDbl ;
	STRING @DestString, ;
	DOUBLE @pVoidSource, ;
	INTEGER nLength
LOCAL cString
cString = SPACE(8)
=RtlCopyDbl(@cString, nDoubleToCopy, 8)
RETURN cString

FUNCTION DoubleToNum
LPARAMETER cDoubleInString
DECLARE RtlMoveMemory IN WIN32API AS RtlCopyDbl ;
	DOUBLE @DestNumeric, ;
	STRING @pVoidSource, ;
	INTEGER nLength
LOCAL nNum
*	Christof Lange pointed out that there's a feature of VFP that results
*	in the entry in the NTI retaining its precision after updating the value
*	directly;  force the resulting precision to a large value before moving
*	data into the temp variable
nNum = 0.000000000000000000
=RtlCopyDbl(@nNum, cDoubleInString, 8)
RETURN nNum


*** End of CLSHEAP ***