[[APM_VENDADDR.BSHO]]
rem --- if running V6Hybrid, constrain address/city input lengths

while 1
	v6h$=stbl("+V6DATA",err=*break)
	if v6h$<>""
		callpoint!.setTableColumnAttribute("APM_VENDADDR.ADDR_LINE_1","MAXL","24")
		addr1!=callpoint!.getControl("APM_VENDADDR.ADDR_LINE_1")
		addr1!.setLength(24)
		callpoint!.setTableColumnAttribute("APM_VENDADDR.ADDR_LINE_2","MAXL","24")
		addr2!=callpoint!.getControl("APM_VENDADDR.ADDR_LINE_2")
		addr2!.setLength(24)
		callpoint!.setTableColumnAttribute("APM_VENDADDR.CITY","MAXL","24")
		city!=callpoint!.getControl("APM_VENDADDR.CITY")
		city!.setLength(24)
	endif
	break
wend

[[APM_VENDADDR.PURCH_ADDR.AINP]]
if cvs(callpoint!.getUserInput(),2)="" callpoint!.setStatus("ABORT")

if num(callpoint!.getUserInput())=0 callpoint!.setStatus("ABORT")



