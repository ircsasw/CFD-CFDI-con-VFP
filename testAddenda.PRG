close all
clear all
clear

set proc to cfd
xa=create("XMLParser")
xa.createNodeLinks = .F.
xa.New()
oNode = xa.XML.addNode("ALSuper:Documento")
oNode.addProp("Version","1.0")
oNode = oNode.AddNode("ALSuper:Conceptos")

oNode.addNode("ALSuper:Concepto")
oNode.Nodes[1].addProp("codigo","1939393")
oNode.Nodes[1].addProp("nombre","silla ejecutiva")

oNode.addNode("ALSuper:Concepto")
oNode.Nodes[2].addProp("codigo","10680997")
oNode.Nodes[2].addProp("nombre","MESA REUNIONES")

xa.indentString = space(1)
_cliptext = xa.ToString(2)
?_cliptext



