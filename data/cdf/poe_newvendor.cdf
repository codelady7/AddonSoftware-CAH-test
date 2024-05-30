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

[[POE_NEWVENDOR.BSHO]]
rem --- Open necessary channel
	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="APM_VENDADDR",open_opts$[1]="OTA"
	gosub open_tables

[[POE_NEWVENDOR.PURCH_ADDR.AVAL]]
rem --- Don't allow inactive code
	apmVendAddr_dev=fnget_dev("APM_VENDADDR")
	dim apmVendAddr$:fnget_tpl$("APM_VENDADDR")
	purch_addr$=callpoint!.getUserInput()
	vendor_id$=callpoint!.getColumnData("POE_NEWVENDOR.VENDOR_ID")
	read record(apmVendAddr_dev,key=firm_id$+vendor_id$+purch_addr$,dom=*next)apmVendAddr$
	if apmVendAddr.code_inactive$ = "Y"
		msg_id$="AD_CODE_INACTIVE"
		dim msg_tokens$[2]
		msg_tokens$[1]=cvs(apmVendAddr.purch_addr$,3)
		msg_tokens$[2]=cvs(apmVendAddr.city$,3)
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif



