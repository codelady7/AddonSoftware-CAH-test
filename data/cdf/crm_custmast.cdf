[[CRM_CUSTMAST.ARER]]
callpoint!.setColumnData("CRM_CUSTDET.INV_HIST_FLG","Y")

[[CRM_CUSTMAST.BSHO]]
rem  Initializations
	use ::ado_util.src::util

rem --- Open/Lock files
	files=1,begfile=1,endfile=files
	dim files$[files],options$[files],chans$[files],templates$[files]
	files$[1]="ARC_CUSTTYPE",options$[1]="OTA"
	call dir_pgm$+"bac_open_tables.bbj",begfile,endfile,files$[all],options$[all],
:       	chans$[all],templates$[all],table_chans$[all],batch,status$
	if status$<>"" then
		remove_process_bar:
		bbjAPI!=bbjAPI()
		rdFuncSpace!=bbjAPI!.getGroupNamespace()
		rdFuncSpace!.setValue("+build_task","OFF")
		release
	endif

[[CRM_CUSTDET.CUSTOMER_TYPE.AVAL]]
rem --- Don't allow inactive code
	arcCustType_dev=fnget_dev("ARC_CUSTTYPE")
	dim arcCustType$:fnget_tpl$("ARC_CUSTTYPE")
	customer_type$=callpoint!.getUserInput()
	read record(arcCustType_dev,key=firm_id$+"L"+customer_type$,dom=*next)arcCustType$
	if arcCustType.code_inactive$ = "Y"
		msg_id$="AD_CODE_INACTIVE"
		dim msg_tokens$[2]
		msg_tokens$[1]=cvs(arcCustType.customer_type$,3)
		msg_tokens$[2]=cvs(arcCustType.code_desc$,3)
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif

[[CRM_CUSTMAST.PAY_AUTH_EMAIL.AVAL]]
rem --- Validate email address
	email$=callpoint!.getUserInput()
	if !util.validEmailAddress(email$) then
		callpoint!.setStatus("ABORT")
		break
	endif

[[CRM_CUSTMAST.SHIPPING_EMAIL.AVAL]]
rem --- Validate email address
	email$=callpoint!.getUserInput()
	if !util.validEmailAddress(email$) then
		callpoint!.setStatus("ABORT")
		break
	endif



