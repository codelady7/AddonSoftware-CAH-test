[[APS_REPORT.BSHO]]
rem --- if running V6Hybrid, constrain address/city input lengths

while 1
	v6h$=stbl("+V6DATA",err=*break)
	if v6h$<>""
		callpoint!.setTableColumnAttribute("APS_REPORT.ADDR_LINE_1","MAXL","24")
		addr1!=callpoint!.getControl("APS_REPORT.ADDR_LINE_1")
		addr1!.setLength(24)
		callpoint!.setTableColumnAttribute("APS_REPORT.ADDR_LINE_2","MAXL","24")
		addr2!=callpoint!.getControl("APS_REPORT.ADDR_LINE_2")
		addr2!.setLength(24)
		callpoint!.setTableColumnAttribute("APS_REPORT.CITY","MAXL","24")
		city!=callpoint!.getControl("APS_REPORT.CITY")
		city!.setLength(24)
	endif
	break
wend



