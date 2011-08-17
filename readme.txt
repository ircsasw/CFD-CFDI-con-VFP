CFD.PRG

Libreria de clases para generacion del Comprobante Electronico Digital
en Mexico, segun las indicaciones del SAT


NOTA IMPORTANTE #1
A partir de la version 2.4 de esta libreria, el metodo Sellar() de la clase
CFDComprobante valida que el certificado sea valido y este vigente. Si el 
certificado no pasa estas pruebas, el metodo no generara el sello y devolvera
.F., almacenando en la propiedad CFDConf.ultimoError la descripcion de problema.

Se puede obviar esta validacion almacenando .T. en la propiedad CFDConf.modoPruebas


NOTA IMPORTANTE #2
Si esta teniendo problemas con las funciones o metodos que invocan OpenSSL
y su carpeta SSL esta ubicada en una ruta que contiene nombres largos o 
espacios en blanco, puede que el problema se deba a que la creacion de nombres
cortos (8.3) esta desactivada a nivel de Windows.  Por favor, revise en su
Register la clave:

HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem\NtfsDisable8dot3NameCreation

y asegurese que su valor sea cero. Si esta en "1", haga el cambio y reinicie
su sistema. Si el valor ya estaba en cero o el problema persiste luego de 
cambiarlo a cero, mueva su carpeta SSL a una ruta que no contenga nombres de
mas de 8 caracteters ni contenga espacios en blanco.


NOTA IMPORTANTE #3
La libreria OpenSSL requiere de las librerias de runtime de VC++ 2008, la cual
puede no estar disponible en algunos equipos, causando problemas con el sellado
de los CFDs (y todas las demas funciones de la libreria que dependan de OpenSSL).

Para solucionar este problema, descargue e instale las librerias necesarias desde
este link (cortesia de Carlos Omar Figueroa):

http://www.microsoft.com/downloads/en/details.aspx?familyid=9B2DA534-3E03-4391-8A4D-074B9F2BC1BF&displaylang=en


NOTA IMPORTANTE #4
Para generar la representacion impresa del CFD se utiliza el procedimiento CFDToCursor() para
pasar los nodos del XML a cursores y asi poder reportarlos. Por regla los saltos de linea y
retornos de carro no estan permitidos en un XML, entonces que pasa si hay un concepto en el
comprobante donde sea muy importante mostrar informacion en lineas adicionales sobre todo para
coneptos muy largos donde se desglozan condiciones u otra información.

Para solucionar este problema se incluye un parametro adicional a CFDPrint() con el que podemos
indicar que se va a remplazar los conceptos obtenidos por CFDToCursor() en el cursor QCO por los 
que estan en el entorno de datos; aqui se supone que en el entorno de datos tenemos un cursor 
llamado curConceptos con los conceptos del comprobante tal como se guardaron en la base de datos.