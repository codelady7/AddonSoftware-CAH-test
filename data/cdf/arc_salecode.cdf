[[ARC_SALECODE.BDEL]]
rem --- When deleting the Salesperson Code, warn if there are any current/active transactions for the code, and disallow if there are any.
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
		callpoint!.setColumnData("ARC_SALECODE.CODE_INACTIVE","Y",1)
		callpoint!.setStatus("SAVE;ABORT")
		break
	endif

[[ARC_SALECODE.BSHO]]
rem --- This firm using Sales Order Processing?
call stbl("+DIR_PGM")+"adc_application.aon","OP",info$[all]
callpoint!.setDevObject("usingOP",info$[20])

rem --- Open/Lock files
files=4
begfile=1,endfile=files
dim files$[files],options$[files],chans$[files],templates$[files]
files$[1]="ARM_CUSTDET",options$[1]="OTA"
files$[2]="ARM_CUSTSHIP",options$[2]="OTA"
files$[3]="ARS_CUSTDFLT",options$[3]="OTA"
if callpoint!.getDevObject("usingOP")="Y" then
	files$[4]="OPT_INVHDR",options$[4]="OTA"
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

[[ARC_SALECODE.CODE_INACTIVE.AVAL]]
rem --- When deactivating the Salesperson Code, warn if there are any current/active transactions for the code, and disallow if there are any.
	current_inactive$=callpoint!.getUserInput()
	prior_inactive$=callpoint!.getColumnData("ARC_SALECODE.CODE_INACTIVE")
	if current_inactive$="Y" and prior_inactive$<>"Y" then
		gosub check_active_code
		if found then
			callpoint!.setStatus("ABORT")
			break
		endif
	endif

[[ARC_SALECODE.<CUSTOM>]]
rem ==========================================================================
check_active_code: rem --- Warn if there are any current/active transactions for the code
rem ==========================================================================
	found=0
	slspsn_code$=callpoint!.getColumnData("ARC_SALECODE.SLSPSN_CODE")

	checkTables!=BBjAPI().makeVector()
	checkTables!.addItem("ARM_CUSTDET")
	checkTables!.addItem("ARM_CUSTSHIP")
	checkTables!.addItem("ARS_CUSTDFLT")
	if callpoint!.getDevObject("usingOP")="Y" then
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
			if table_tpl.slspsn_code$=slspsn_code$ then
				msg_id$="AD_CODE_IN_USE"
				dim msg_tokens$[2]
				msg_tokens$[1]=Translate!.getTranslation("AON_SALESPERSON")+" "+Translate!.getTranslation("AON_CODE")
				switch (BBjAPI().TRUE)
                				case thisTable$="ARM_CUSTDET"
                    				msg_tokens$[2]=Translate!.getTranslation("DDM_TABLES-ARM_CUSTDET-DD_ATTR_WINT")
                    				break
                				case thisTable$="ARM_CUSTSHIP"
                   				msg_tokens$[2]=Translate!.getTranslation("DDM_TABLES-ARM_CUSTSHIP-DD_ATTR_WINT")
                    				break
                				case thisTable$="ARS_CUSTDFLT"
                    				msg_tokens$[2]=Translate!.getTranslation("DDM_TABLES-ARS_CUSTDFLT-DD_ATTR_WINT")
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
		callpoint!.setColumnData("ARC_SALECODE.CODE_INACTIVE","N",1)
	endif

return



