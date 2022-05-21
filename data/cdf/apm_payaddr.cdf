[[APM_PAYADDR.ARNF]]
rem --- No pay-to address found for this vendor, so show their master address.
	apmVendMast_dev=fnget_dev("APM_VENDMAST")
	dim apmVendMast$:fnget_tpl$("APM_VENDMAST")
	readrecord(apmVendMast_dev,key=firm_id$+callpoint!.getColumnData("APM_PAYADDR.VENDOR_ID"),dom=*next)apmVendMast$
	callpoint!.setColumnData("APM_PAYADDR.PAY_TO_NAME",apmVendMast.vendor_name$,1)
	callpoint!.setColumnData("APM_PAYADDR.ADDR_LINE_1",apmVendMast.addr_line_1$,1)
	callpoint!.setColumnData("APM_PAYADDR.ADDR_LINE_2",apmVendMast.addr_line_2$,1)
	callpoint!.setColumnData("APM_PAYADDR.CITY",apmVendMast.city$,1)
	callpoint!.setColumnData("APM_PAYADDR.STATE_CODE",apmVendMast.state_code$,1)
	callpoint!.setColumnData("APM_PAYADDR.ZIP_CODE",apmVendMast.zip_code$,1)
	callpoint!.setColumnData("APM_PAYADDR.PHONE_NO",apmVendMast.phone_no$,1)
	callpoint!.setColumnData("APM_PAYADDR.PHONE_EXTEN",apmVendMast.phone_exten$,1)
	callpoint!.setColumnData("APM_PAYADDR.CONTACT_NAME",apmVendMast.contact_name$,1)
	callpoint!.setColumnData("APM_PAYADDR.FAX_NO",apmVendMast.fax_no$,1)
	callpoint!.setColumnData("APM_PAYADDR.CNTRY_ID",apmVendMast.cntry_id$,1)

	callpoint!.setDevObject("noPayToAddr","true")

[[APM_PAYADDR.BEND]]
rem --- Do NOT save pay-to address if it is the same as the vendor's master address.
	apmVendMast_dev=fnget_dev("APM_VENDMAST")
	dim apmVendMast$:fnget_tpl$("APM_VENDMAST")
	readrecord(apmVendMast_dev,key=firm_id$+callpoint!.getColumnData("APM_PAYADDR.VENDOR_ID"),dom=*next)apmVendMast$
	if cvs(callpoint!.getColumnData("APM_PAYADDR.PAY_TO_NAME"),3)=cvs(apmVendMast.vendor_name$,3) and
:	cvs(callpoint!.getColumnData("APM_PAYADDR.ADDR_LINE_1"),3)=cvs(apmVendMast.addr_line_1$,3) and
:	cvs(callpoint!.getColumnData("APM_PAYADDR.ADDR_LINE_2"),3)=cvs(apmVendMast.addr_line_2$,3) and
:	cvs(callpoint!.getColumnData("APM_PAYADDR.CITY"),3)=cvs(apmVendMast.city$,3) and
:	cvs(callpoint!.getColumnData("APM_PAYADDR.STATE_CODE"),3)=cvs(apmVendMast.state_code$,3) and
:	cvs(callpoint!.getColumnData("APM_PAYADDR.ZIP_CODE"),3)=cvs(apmVendMast.zip_code$,3) and
:	cvs(callpoint!.getColumnData("APM_PAYADDR.PHONE_NO"),3)=cvs(apmVendMast.phone_no$,3) and
:	cvs(callpoint!.getColumnData("APM_PAYADDR.PHONE_EXTEN"),3)=cvs(apmVendMast.phone_exten$,3) and
:	cvs(callpoint!.getColumnData("APM_PAYADDR.CONTACT_NAME"),3)=cvs(apmVendMast.contact_name$,3) and
:	cvs(callpoint!.getColumnData("APM_PAYADDR.FAX_NO"),3)=cvs(apmVendMast.fax_no$,3) and
:	cvs(callpoint!.getColumnData("APM_PAYADDR.CNTRY_ID"),3)=cvs(apmVendMast.cntry_id$,3) then
		apmPayAddr_dev=fnget_dev("APM_PAYADDR")
		remove(apmPayAddr_dev,key=firm_id$+callpoint!.getColumnData("APM_PAYADDR.VENDOR_ID"),dom=*next)
	endif

[[APM_PAYADDR.BSHO]]
rem --- Initialize DevObject
	callpoint!.setDevObject("noPayToAddr","false")

[[APM_PAYADDR.PAY_TO_NAME.BINP]]
rem --- Notify when using vendor master address for pay-to address
	if callpoint!.getDevObject("noPayToAddr")="true" then
		msg_id$="AP_VEND_PAYTO"
		gosub disp_message
		if msg_opt$="N" then
			callpoint!.setStatus("EXIT")
		else
			callpoint!.setDevObject("noPayToAddr","false")
		endif
	endif



