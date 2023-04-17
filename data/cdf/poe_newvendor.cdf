[[POE_NEWVENDOR.AREC]]
rem --- Clear previous vendor info
	callpoint!.setDevObject("new_vendor","")
	callpoint!.setDevObject("new_purchAddr","")

[[POE_NEWVENDOR.ASVA]]
rem --- Pass this vendor info along to next pgm
	vendor_id$=callpoint!.getColumnData("POE_NEWVENDOR.VENDOR_ID")
	purch_addr$=callpoint!.getColumnData("POE_NEWVENDOR.PURCH_ADDR")
	callpoint!.setDevObject("new_vendor",vendor_id$)
	callpoint!.setDevObject("new_purchAddr",purch_addr$)



