[[APM_CCVEND.AREC]]
rem --- Initialize CREDITCARD_ID to start with the letter "C"
	callpoint!.setColumnData("APM_CCVEND.CREDITCARD_ID","C",1)

[[APM_CCVEND.AWIN]]
rem --- Inits
	use ::ado_func.src::func

[[APM_CCVEND.BDEL]]
rem --- Record cannot be deleted if the CREDITCARD_ID is in APE_INVOICEHDR
	gosub checkIfActive

	if ccID_active$="Y" then
		callpoint!.setColumnData("APM_CCVEND.CODE_INACTIVE","N",1)
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- Do they want to deactivate code instead of deleting it?
	msg_id$="AD_DEACTIVATE_CODE"
	gosub disp_message
	if msg_opt$="Y" then
		rem --- Check the CODE_INACTIVE checkbox
		callpoint!.setColumnData("APM_CCVEND.CODE_INACTIVE","Y",1)
		callpoint!.setStatus("SAVE;ABORT")
		break
	endif

[[APM_CCVEND.BSHO]]
rem --- This firm using Purchase Orders?
	call stbl("+DIR_PGM")+"adc_application.aon","PO",info$[all]
	callpoint!.setDevObject("usingPO",info$[20])

rem --- Open needed files
	num_files=5
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	
	open_tables$[1]="APE_INVOICEHDR",  open_opts$[1]="OTA"
	open_tables$[2]="APM_VENDMAST",  open_opts$[2]="OTA"
	open_tables$[3]="APM_VENDHIST",  open_opts$[3]="OTA"
	open_tables$[4]="APC_TYPECODE",  open_opts$[4]="OTA"
	if callpoint!.getDevObject("usingPO")="Y" then
		open_tables$[5]="POE_INVHDR",  open_opts$[5]="OTA"
	endif

	gosub open_tables

[[APM_CCVEND.CC_APTYPE.AVAL]]
rem --- Don't allow inactive code
	apcTypeCode_dev=fnget_dev("APC_TYPECODE")
	dim apcTypeCode$:fnget_tpl$("APC_TYPECODE")
	ap_type$=callpoint!.getUserInput()
	read record(apcTypeCode_dev,key=firm_id$+"A"+ap_type$,dom=*next)apcTypeCode$
	if apcTypeCode.code_inactive$ = "Y"
		msg_id$="AD_CODE_INACTIVE"
		dim msg_tokens$[2]
		msg_tokens$[1]=cvs(apcTypeCode.ap_type$,3)
		msg_tokens$[2]=cvs(apcTypeCode.code_desc$,3)
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif

[[APM_CCVEND.CC_VENDOR.AVAL]]
rem --- Entered CC_VENDOR cannot be inactive.
	vendor$=callpoint!.getUserInput()
	apmVendMast_dev=fnget_dev("APM_VENDMAST")
	dim apmVendMast$:fnget_tpl$("APM_VENDMAST")
	findrecord(apmVendMast_dev,key=firm_id$+vendor$,dom=*next)apmVendMast$
	if apmVendMast.vend_inactive$="Y" then
		call stbl("+DIR_PGM")+"adc_getmask.aon","VENDOR_ID","","","",m0$,0,vendor_size
		msg_id$="AP_VEND_INACTIVE"
		dim msg_tokens$[2]
		msg_tokens$[1]=fnmask$(apmVendMast.vendor_id$(1,vendor_size),m0$)
		msg_tokens$[2]=cvs(apmVendMast.vendor_name$,2)
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- Entered CC_VENDOR must be for the entered CC_APTYPE.
	cc_aptype$=callpoint!.getColumnData("APM_CCVEND.CC_APTYPE")
	apmVendHist_dev=fnget_dev("APM_VENDHIST")
	goodVendor=0
	read(apmVendHist_dev,key=firm_id$+vendor$+cc_aptype$,dom=*next); goodVendor=1
	if !goodVendor then
		msg_id$="AP_VEND_BAD_APTYPE"
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif

[[APM_CCVEND.CC_VENDOR.BINP]]
rem --- CC_APTYEP must be entered before CC_VENDOR
	if cvs(callpoint!.getColumnData("APM_CCVEND.CC_APTYPE"),2)="" then callpoint!.setFocus("APM_CCVEND.CC_APTYPE",1)

[[APM_CCVEND.CC_VENDOR.BINQ]]
rem --- In lookup only show vendors of given AP Type
	dim filter_defs$[2,2]
	filter_defs$[0,0]="APM_VENDMAST.FIRM_ID"
	filter_defs$[0,1]="='"+firm_id$+"'"
	filter_defs$[0,2]="LOCK"
	filter_defs$[1,0]="APM_VENDHIST.AP_TYPE"
	filter_defs$[1,1]="='"+callpoint!.getColumnData("APM_CCVEND.CC_APTYPE")+"'"
	filter_defs$[1,2]="LOCK"

	call STBL("+DIR_SYP")+"bax_query.bbj",
:		gui_dev, 
:		form!,
:		"AP_VEND_LK",
:		"DEFAULT",
:		table_chans$[all],
:		sel_key$,
:		filter_defs$[all]

	if sel_key$<>""
		call stbl("+DIR_SYP")+"bac_key_template.bbj",
:			"APM_VENDMAST",
:			"PRIMARY",
:			apm_vend_key$,
:			table_chans$[all],
:			status$
		dim apm_vend_key$:apm_vend_key$
		apm_vend_key$=sel_key$
		callpoint!.setColumnData("APM_CCVEND.CC_VENDOR",apm_vend_key.vendor_id$,1)
	endif	
	callpoint!.setStatus("ACTIVATE-ABORT")

[[APM_CCVEND.CODE_INACTIVE.AVAL]]
rem --- Record cannot be marked inactive if the CREDITCARD_ID is in APE_INVOICEHDR
	inactive$=callpoint!.getUserInput()
	if inactive$="Y" then
		gosub checkIfActive

		if ccID_active$="Y" then
			callpoint!.setColumnData("APM_CCVEND.CODE_INACTIVE","N",1)
			callpoint!.setStatus("ABORT")
		endif
	endif

[[APM_CCVEND.CREDITCARD_ID.AVAL]]
rem --- Force CREDITCARD_ID entry to start with the letter "C"
	ccID$=callpoint!.getUserInput()
	if ccID$(1,1)<>"C" then
		if len(ccID$)=7 then
			msg_id$="AP_CC_ID"
			gosub disp_message
			callpoint!.setStatus("ABORT")
			break
		else
			callpoint!.setUserInput("C"+ccID$)
		endif
	endif

[[APM_CCVEND.<CUSTOM>]]
#include [+ADDON_LIB]std_functions.aon

checkIfActive: rem --- Ceck if the CREDITCARD_ID is currently active in APE_INVOICEHDR
	ccID_active$="N"
	ccID$=callpoint!.getColumnData("APM_CCVEND.CREDITCARD_ID")
	checkTables!=BBjAPI().makeVector()
	checkTables!.addItem("APE_INVOICEHDR")
	if callpoint!.getDevObject("usingPO")="Y" then
		checkTables!.addItem("POE_INVHDR")
	endif
	for i=0 to checkTables!.size()-1
		thisTable$=checkTables!.getItem(i)
		table_dev = fnget_dev(thisTable$)
		dim table_tpl$:fnget_tpl$(thisTable$)
		read(table_dev,key=firm_id$,dom=*next)
		while 1
			readrecord(table_dev,end=*break)table_tpl$
			if table_tpl.firm_id$<>firm_id$ then break
			if table_tpl.creditcard_id$=ccID$ then
				msg_id$="AD_CODE_IN_USE"
				dim msg_tokens$[2]
				msg_tokens$[1]=Translate!.getTranslation("AON_CREDIT_CARD_NO")
				switch (BBjAPI().TRUE)
                				case thisTable$="APE_INVOICEHDR"
                   				msg_tokens$[2]=Translate!.getTranslation("DDM_TABLES-APE_INVOICEHDR-DD_ATTR_WINT")
                    				break
                				case thisTable$="POE_INVHDR"
                    				msg_tokens$[2]=Translate!.getTranslation("DDM_TABLES-POE_INVHDR-DD_ATTR_WINT")
						break
                				case default
                    				msg_tokens$[2]="???"
                    				break
            			swend
				gosub disp_message

				ccID_active$="Y"
				break
			endif
		wend
		if ccID_active$="Y" then break
	next i

	return



