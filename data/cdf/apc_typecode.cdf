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

[[APC_TYPECODE.AREC]]
if callpoint!.getDevObject("multi_dist")<>"Y"
	ap_dist_code$=callpoint!.getDevObject("ap_dist_code")
	callpoint!.setColumnData("APC_TYPECODE.AP_DIST_CODE",ap_dist_code$)
endif

rem --- Initialize default fields
	callpoint!.setColumnData("APC_TYPECODE.IRS1099_TYPE_BOX","X")

[[APC_TYPECODE.BSHO]]
rem --- Open/Lock files

files=3,begfile=1,endfile=files
dim files$[files],options$[files],chans$[files],templates$[files]
files$[1]="APS_PARAMS";rem --- ads-01
files$[2]="APC_DISTRIBUTION";rem --- ads-01
files$[3]="APC_PAYMENTGROUP";rem --- ads-01

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



