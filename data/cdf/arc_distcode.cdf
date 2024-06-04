[[ARC_DISTCODE.AENA]]
pgm_dir$=stbl("+DIR_PGM")

rem --- Disable columns if PO system not installed
call pgm_dir$+"adc_application.aon","PO",info$[all]

if info$[20] = "N"
	ctl_name$="ARC_DISTCODE.GL_INV_ADJ"
	ctl_stat$="I"
	gosub disable_fields
	ctl_name$="ARC_DISTCODE.GL_COGS_ADJ"
	ctl_stat$="I"
	gosub disable_fields
	ctl_name$="ARC_DISTCODE.GL_PURC_ACCT"
	ctl_stat$="I"
	gosub disable_fields
	ctl_name$="ARC_DISTCODE.GL_PPV_ACCT"
	ctl_stat$="I"
	gosub disable_fields
endif

[[ARC_DISTCODE.BDEL]]
rem --- When deleting the Distribution Code, warn if there are any current/active transactions for the code, and disallow if there are any.
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
		callpoint!.setColumnData("ARC_DISTCODE.CODE_INACTIVE","Y",1)
		callpoint!.setStatus("SAVE;ABORT")
		break
	endif

[[ARC_DISTCODE.BSHO]]
rem --- This firm using Inventory Control?
call stbl("+DIR_PGM")+"adc_application.aon","IV",info$[all]
callpoint!.setDevObject("usingIV",info$[20])

rem --- This firm using Purchase Orders?
call stbl("+DIR_PGM")+"adc_application.aon","PO",info$[all]
callpoint!.setDevObject("usingPO",info$[20])

rem --- Open/Lock files
files=10
begfile=1,endfile=files
dim files$[files],options$[files],chans$[files],templates$[files]
files$[1]="ARE_CNVINV",options$[1]="OTA"
files$[2]="ARE_DATECHANGE",options$[2]="OTA"
files$[3]="ARE_FINCHG",options$[3]="OTA"
files$[4]="ARM_CUSTDET",options$[4]="OTA"
files$[5]="ARS_CUSTDFLT",options$[5]="OTA"
if callpoint!.getDevObject("usingIV")="Y" then
	files$[6]="IVC_PRODCODE",options$[6]="OTA"
	files$[7]="IVM_ITEMWHSE",options$[7]="OTA"
	files$[8]="IVS_DEFAULTS",options$[8]="OTA"
endif
if callpoint!.getDevObject("usingPO")="Y" then
	files$[9]="OPC_LINECODE",options$[9]="OTA"
	files$[10]="OPT_INVHDR",options$[10]="OTA"
endif

call stbl("+DIR_SYP")+"bac_open_tables.bbj",begfile,endfile,files$[all],options$[all],
:                                 chans$[all],templates$[all],table_chans$[all],batch,status$

if status$<>"" then
	remove_process_bar:
	bbjAPI!=bbjAPI()
	rdFuncSpace!=bbjAPI!.getGroupNamespace()
	rdFuncSpace!.setValue("+build_task","OFF")
	release
endif

[[ARC_DISTCODE.CODE_INACTIVE.AVAL]]
rem --- When deactivating the Distribution Code, warn if there are any current/active transactions for the code, and disallow if there are any.
	current_inactive$=callpoint!.getUserInput()
	prior_inactive$=callpoint!.getColumnData("ARC_DISTCODE.CODE_INACTIVE")
	if current_inactive$="Y" and prior_inactive$<>"Y" then
		gosub check_active_code
		if found then
			callpoint!.setStatus("ABORT")
			break
		endif
	endif

[[ARC_DISTCODE.GL_AR_ACCT.AVAL]]
gosub gl_inactive

[[ARC_DISTCODE.GL_CASH_ACCT.AVAL]]
gosub gl_inactive

[[ARC_DISTCODE.GL_COGS_ACCT.AVAL]]
gosub gl_inactive

[[ARC_DISTCODE.GL_COGS_ADJ.AVAL]]
gosub gl_inactive

[[ARC_DISTCODE.GL_DISC_ACCT.AVAL]]
gosub gl_inactive

[[ARC_DISTCODE.GL_FRGT_ACCT.AVAL]]
gosub gl_inactive

[[ARC_DISTCODE.GL_INV_ACCT.AVAL]]
gosub gl_inactive

[[ARC_DISTCODE.GL_INV_ADJ.AVAL]]
gosub gl_inactive

[[ARC_DISTCODE.GL_PPV_ACCT.AVAL]]
gosub gl_inactive

[[ARC_DISTCODE.GL_PURC_ACCT.AVAL]]
gosub gl_inactive

[[ARC_DISTCODE.GL_SLS_ACCT.AVAL]]
gosub gl_inactive

[[ARC_DISTCODE.<CUSTOM>]]
#include [+ADDON_LIB]std_functions.aon

gl_inactive:
rem "GL INACTIVE FEATURE"
   glm01_dev=fnget_dev("GLM_ACCT")
   glm01_tpl$=fnget_tpl$("GLM_ACCT")
   dim glm01a$:glm01_tpl$
   glacctinput$=callpoint!.getUserInput()
   glm01a_key$=firm_id$+glacctinput$
   find record (glm01_dev,key=glm01a_key$,err=*return) glm01a$
   if glm01a.acct_inactive$="Y" then
      call stbl("+DIR_PGM")+"adc_getmask.aon","GL_ACCOUNT","","","",m0$,0,gl_size
      msg_id$="GL_ACCT_INACTIVE"
      dim msg_tokens$[2]
      msg_tokens$[1]=fnmask$(glm01a.gl_account$(1,gl_size),m0$)
      msg_tokens$[2]=cvs(glm01a.gl_acct_desc$,2)
      gosub disp_message
      callpoint!.setStatus("ACTIVATE-ABORT")
   endif
return

disable_fields:
rem --- used to disable/enable controls depending on parameter settings
rem --- send in control to toggle (format "ALIAS.CONTROL_NAME"), and D or space to disable/enable

wctl$=str(num(callpoint!.getTableColumnAttribute(ctl_name$,"CTLI")):"00000")
wmap$=callpoint!.getAbleMap()
wpos=pos(wctl$=wmap$,8)
wmap$(wpos+6,1)=ctl_stat$
callpoint!.setAbleMap(wmap$)
callpoint!.setStatus("ABLEMAP-REFRESH")

return

rem ==========================================================================
check_active_code: rem --- Warn if there are any current/active transactions for the code
rem ==========================================================================
	found=0
	ar_dist_code$=callpoint!.getColumnData("ARC_DISTCODE.AR_DIST_CODE")

	checkTables!=BBjAPI().makeVector()
	checkTables!.addItem("ARE_CNVINV")
	checkTables!.addItem("ARE_DATECHANGE")
	checkTables!.addItem("ARE_FINCHG")
	checkTables!.addItem("ARM_CUSTDET")
	checkTables!.addItem("ARS_CUSTDFLT")
	if callpoint!.getDevObject("usingIV")="Y" then
		checkTables!.addItem("IVC_PRODCODE")
		checkTables!.addItem("IVM_ITEMWHSE")
		checkTables!.addItem("IVS_DEFAULTS")
	endif
	if callpoint!.getDevObject("usingPO")="Y" then
		checkTables!.addItem("OPC_LINECODE")
		checkTables!.addItem("OPT_INVHDR")
	endif
	for i=0 to checkTables!.size()-1
		thisTable$=checkTables!.getItem(i)
		table_dev = fnget_dev(thisTable$)
		dim table_tpl$:fnget_tpl$(thisTable$)
		if thisTable$="OPT_INVHDR" then
			read(table_dev,key=firm_id$+"E",knum="AO_STATUS",dom=*next)
		else
			read(table_dev,key=firm_id$,dom=*next)
		endif
		while 1
			readrecord(table_dev,end=*break)table_tpl$
			if table_tpl.firm_id$<>firm_id$ then break
			if thisTable$="OPT_INVHDR" and table_tpl.trans_status$<>"E" then break
			if table_tpl.ar_dist_code$=ar_dist_code$ then
				msg_id$="AD_CODE_IN_USE"
				dim msg_tokens$[2]
				msg_tokens$[1]=Translate!.getTranslation("AON_DISTRIBUTION_CODE")
				switch (BBjAPI().TRUE)
					case thisTable$="ARE_CNVINV"
						msg_tokens$[2]=Translate!.getTranslation("DDM_TABLES-ARE_CNVINV-DD_ATTR_WINT")
						break
                				case thisTable$="ARE_DATECHANGE"
                   				msg_tokens$[2]=Translate!.getTranslation("DDM_TABLES-ARE_DATECHANGE-DD_ATTR_WINT")
                    				break
                				case thisTable$="ARE_FINCHG"
                    				msg_tokens$[2]=Translate!.getTranslation("DDM_TABLES-ARE_FINCHG-DD_ATTR_WINT")
                    				break
                				case thisTable$="ARM_CUSTDET"
                    				msg_tokens$[2]=Translate!.getTranslation("DDM_TABLES-ARM_CUSTDET-DD_ATTR_WINT")
                    				break
                				case thisTable$="ARS_CUSTDFLT"
                    				msg_tokens$[2]=Translate!.getTranslation("DDM_TABLES-ARS_CUSTDFLT-DD_ATTR_WINT")
						break
                				case thisTable$="IVC_PRODCODE"
                    				msg_tokens$[2]=Translate!.getTranslation("DDM_TABLES-IVC_PRODCODE-DD_ATTR_WINT")
						break
                				case thisTable$="IVM_ITEMWHSE"
                    				msg_tokens$[2]=Translate!.getTranslation("DDM_TABLES-IVM_ITEMWHSE-DD_ATTR_WINT")
						break
                				case thisTable$="IVS_DEFAULTS"
                    				msg_tokens$[2]=Translate!.getTranslation("DDM_TABLES-IVS_DEFAULTS-DD_ATTR_WINT")
						break
                				case thisTable$="OPC_LINECODE"
                    				msg_tokens$[2]=Translate!.getTranslation("DDM_TABLES-OPC_LINECODE-DD_ATTR_WINT")
						break
                				case thisTable$="OPT_INVHDR"
						if table_tpl.ordinv_flag$="I" then
                    					msg_tokens$[2]=Translate!.getTranslation("DDM_TABLES-OPE_INVHDR-DD_ATTR_WINT")
						else
                    					msg_tokens$[2]=Translate!.getTranslation("DDM_TABLES-OPE_ORDHDR-DD_ATTR_WINT")
						endif
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
		callpoint!.setColumnData("ARC_DISTCODE.CODE_INACTIVE","N",1)
	endif

return



