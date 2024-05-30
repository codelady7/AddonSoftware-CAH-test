[[APC_TYPECODE.AP_DIST_CODE.AVAL]]
rem --- Don't allow inactive code
	apcDistribution_dev=fnget_dev("APC_DISTRIBUTION")
	dim apcDistribution$:fnget_tpl$("APC_DISTRIBUTION")
	ap_dist_code$=callpoint!.getUserInput()
	read record(apcDistribution_dev,key=firm_id$+"B"+ap_dist_code$,dom=*next)apcDistribution$
	if apcDistribution.code_inactive$ = "Y"
		msg_id$="AD_CODE_INACTIVE"
		dim msg_tokens$[2]
		msg_tokens$[1]=cvs(apcDistribution.ap_dist_code$,3)
		msg_tokens$[2]=cvs(apcDistribution.code_desc$,3)
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif

[[APC_TYPECODE.AP_TERMS_CODE.AVAL]]
rem --- Don't allow inactive code
	apcTermsCode_dev=fnget_dev("APC_TERMSCODE")
	dim apcTermsCode$:fnget_tpl$("APC_TERMSCODE")
	ap_terms_code$=callpoint!.getUserInput()
	read record(apcTermsCode_dev,key=firm_id$+"C"+ap_terms_code$,dom=*next)apcTermsCode$
	if apcTermsCode.code_inactive$ = "Y"
		msg_id$="AD_CODE_INACTIVE"
		dim msg_tokens$[2]
		msg_tokens$[1]=cvs(apcTermsCode.terms_codeap$,3)
		msg_tokens$[2]=cvs(apcTermsCode.code_desc$,3)
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif

[[APC_TYPECODE.AREC]]
if callpoint!.getDevObject("multi_dist")<>"Y"
	ap_dist_code$=callpoint!.getDevObject("ap_dist_code")
	callpoint!.setColumnData("APC_TYPECODE.AP_DIST_CODE",ap_dist_code$)
endif

rem --- Initialize default fields
	callpoint!.setColumnData("APC_TYPECODE.IRS1099_TYPE_BOX","X")

[[APC_TYPECODE.BDEL]]
rem --- When deleting the AP Type Code, warn if there are any current/active transactions for the code, and disallow if there are any.
	gosub check_active_code
	if found then
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- Do they want to deactivate code instead of deleting it?
	msg_id$="AD_DEACTIVATE_CODE"
	gosub disp_message
	if msg_opt$="Y" then
		rem --- Check the CODE_INACTIVE checkbox
		callpoint!.setColumnData("APC_TYPECODE.CODE_INACTIVE","Y",1)
		callpoint!.setStatus("SAVE;ABORT")
		break
	endif

[[APC_TYPECODE.BSHO]]
rem --- This firm using Purchase Orders?
call stbl("+DIR_PGM")+"adc_application.aon","PO",info$[all]
callpoint!.setDevObject("usingPO",info$[20])

rem --- Open/Lock files
files=11
if callpoint!.getDevObject("usingPO")<>"Y" then files=8
begfile=1,endfile=files
dim files$[files],options$[files],chans$[files],templates$[files]
files$[1]="APS_PARAMS";rem --- ads-01
files$[2]="APC_DISTRIBUTION"
files$[3]="APC_PAYMENTGROUP"
files$[4]="APC_TERMSCODE"
files$[5]="APC_TYPECODE"
files$[6]="APE_INVOICEHDR"
files$[7]="APE_MANCHECKHDR"
files$[8]="APE_RECURRINGHDR"
files$[9]="APM_CCVEND"
files$[10]="APM_VENDHIST"
if callpoint!.getDevObject("usingPO")="Y" then
	files$[11]="POE_INVHDR"
endif

for wkx=begfile to endfile
	options$[wkx]="OTA"
next wkx

call stbl("+DIR_SYP")+"bac_open_tables.bbj",begfile,endfile,files$[all],options$[all],
:                                 chans$[all],templates$[all],table_chans$[all],batch,status$

if status$<>"" then
	remove_process_bar:
	bbjAPI!=bbjAPI()
	rdFuncSpace!=bbjAPI!.getGroupNamespace()
	rdFuncSpace!.setValue("+build_task","OFF")
	release
endif

aps01_dev=num(chans$[1])

rem --- Retrieve miscellaneous templates

files=1,begfile=1,endfile=files
dim ids$[files],templates$[files]
ids$[1]="aps-01A:APS_PARAMS"

call stbl("+DIR_PGM")+"adc_template.aon",begfile,endfile,ids$[all],templates$[all],status
if status goto std_exit

rem --- Dimension miscellaneous string templates

dim aps01a$:templates$[1]

rem --- init/parameters

aps01a_key$=firm_id$+"AP00"
find record (aps01_dev,key=aps01a_key$,err=std_missing_params) aps01a$
callpoint!.setDevObject("multi_dist",aps01a.multi_dist$)
callpoint!.setDevObject("ap_dist_code",aps01a.ap_dist_code$)

if aps01a.multi_dist$="Y"
	callpoint!.setColumnEnabled("APC_TYPECODE.AP_DIST_CODE",1)
else
	callpoint!.setColumnEnabled("APC_TYPECODE.AP_DIST_CODE",-1)
endif

rem --- Posting to General Ledger?
	if aps01a.post_to_gl$="Y" then
		callpoint!.setColumnEnabled("APC_TYPECODE.GL_ACCOUNT",1)
	else
		callpoint!.setColumnEnabled("APC_TYPECODE.GL_ACCOUNT",0)
	endif

[[APC_TYPECODE.CODE_INACTIVE.AVAL]]
rem --- When deactivating the AP Type Code, warn if there are any current/active transactions for the code, and disallow if there are any.
	current_inactive$=callpoint!.getUserInput()
	prior_inactive$=callpoint!.getColumnData("APC_TYPECODE.CODE_INACTIVE")
	if current_inactive$="Y" and prior_inactive$<>"Y" then
		gosub check_active_code
		if found then
			callpoint!.setStatus("ABORT")
			break
		endif
	endif

[[APC_TYPECODE.PAYMENT_GRP.AVAL]]
rem --- Don't allow inactive code
	apcPaymentGroup_dev=fnget_dev("APC_PAYMENTGROUP")
	dim apcPaymentGroup$:fnget_tpl$("APC_PAYMENTGROUP")
	payment_grp$=callpoint!.getUserInput()
	read record(apcPaymentGroup_dev,key=firm_id$+"D"+payment_grp$,dom=*next)apcPaymentGroup$
	if apcPaymentGroup.code_inactive$ = "Y"
		msg_id$="AD_CODE_INACTIVE"
		dim msg_tokens$[2]
		msg_tokens$[1]=cvs(apcPaymentGroup.payment_grp$,3)
		msg_tokens$[2]=cvs(apcPaymentGroup.code_desc$,3)
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif

[[APC_TYPECODE.<CUSTOM>]]
#include [+ADDON_LIB]std_missing_params.aon

rem ==========================================================================
check_active_code: rem --- Warn if there are any current/active transactions for the code
rem ==========================================================================
	found=0
	ap_type$=callpoint!.getColumnData("APC_TYPECODE.AP_TYPE")

	checkTables!=BBjAPI().makeVector()
	checkTables!.addItem("APE_INVOICEHDR")
	checkTables!.addItem("APE_MANCHECKHDR")
	checkTables!.addItem("APE_RECURRINGHDR")
	checkTables!.addItem("APM_CCVEND")
	checkTables!.addItem("APM_VENDHIST")
	checkTables!.addItem("APS_PARAMS")
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
			if table_tpl.ap_type$=ap_type$ then
				msg_id$="AD_CODE_IN_USE"
				dim msg_tokens$[2]
				msg_tokens$[1]=Translate!.getTranslation("AON_AP_TYPE")
				switch (BBjAPI().TRUE)
                				case thisTable$="APE_INVOICEHDR"
                   				msg_tokens$[2]=Translate!.getTranslation("DDM_TABLES-APE_INVOICEHDR-DD_ATTR_WINT")
                    				break
               				case thisTable$="APE_MANCHECKHDR"
                    				msg_tokens$[2]=Translate!.getTranslation("DDM_TABLES-APE_MANCHECKHDR-DD_ATTR_WINT")
                    				break
                				case thisTable$="APE_RECURRINGHDR"
                    				msg_tokens$[2]=Translate!.getTranslation("DDM_TABLES-APE_RECURRINGHDR-DD_ATTR_WINT")
                    				break
                				case thisTable$="APM_CCVEND"
                    				msg_tokens$[2]=Translate!.getTranslation("AON_CREDIT_CARDS")+" Master"
                    				break
                				case thisTable$="APM_VENDHIST"
                    				msg_tokens$[2]=Translate!.getTranslation("DDM_TABLES-APM_VENDHIST-DD_ATTR_WINT")
                    				break
                				case thisTable$="APS_PARAMS"
                    				msg_tokens$[2]=Translate!.getTranslation("DDM_TABLES-APS_PARAMS-DD_ATTR_WINT")
						break
                				case thisTable$="POE_INVHDR"
                    				msg_tokens$[2]=Translate!.getTranslation("DDM_TABLES-POE_INVHDR-DD_ATTR_WINT")
						break
                				case default
                    				msg_tokens$[2]="???"
                    				break
            				swend
				gosub disp_message

				found=1
				break
			endif
		wend
		if found then break
	next i

	if found then
		rem --- Uncheck the CODE_INACTIVE checkbox
		callpoint!.setColumnData("APC_TYPECODE.CODE_INACTIVE","N",1)
	endif

return



