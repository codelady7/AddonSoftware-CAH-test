[[GLC_CYCLECODE.BDEL]]
rem --- When deleting the Journal ID code, warn if there are any current/active transactions for the code, and disallow if there are any.
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
		callpoint!.setColumnData("GLC_CYCLECODE.CODE_INACTIVE","Y",1)
		callpoint!.setStatus("SAVE;ABORT")
		break
	endif

[[GLC_CYCLECODE.BSHO]]
rem --- Open/Lock files
	num_files=2
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="GLE_JRNLHDR",open_opts$[1]="OTA"
	open_tables$[2]="GLE_RECJEHDR",open_opts$[2]="OTA"

	gosub open_tables

[[GLC_CYCLECODE.CODE_INACTIVE.AVAL]]
rem --- When deactivating the Cycle code, warn if there are any current/active transactions for the code, and disallow if there are any.
	current_inactive$=callpoint!.getUserInput()
	prior_inactive$=callpoint!.getColumnData("GLC_CYCLECODE.CODE_INACTIVE")
	if current_inactive$="Y" and prior_inactive$<>"Y" then
		gosub check_active_code
		if found then callpoint!.setStatus("ABORT")
	endif

[[GLC_CYCLECODE.<CUSTOM>]]
#include [+ADDON_LIB]std_missing_params.aon

rem ==========================================================================
check_active_code: rem --- Warn if there are any current/active transactions for the code
rem ==========================================================================
	found=0
	cycle_code$=callpoint!.getColumnData("GLC_CYCLECODE.CYCLE_CODE")

	checkTables!=BBjAPI().makeVector()
	checkTables!.addItem("GLE_JRNLHDR")
	checkTables!.addItem("GLE_RECJEHDR")
	for i=0 to checkTables!.size()-1
		thisTable$=checkTables!.getItem(i)
		table_dev = fnget_dev(thisTable$)
		dim table_tpl$:fnget_tpl$(thisTable$)
		read(table_dev,key=firm_id$,dom=*next)
		while 1
			readrecord(table_dev,end=*break)table_tpl$
			if table_tpl.firm_id$<>firm_id$ then break
			if table_tpl.cycle_code$=cycle_code$ then
				msg_id$="AD_CODE_IN_USE"
				dim msg_tokens$[2]
				msg_tokens$[1]=Translate!.getTranslation("AON_CYCLE_CODE_")
				switch (BBjAPI().TRUE)
                				case thisTable$="GLE_JRNLHDR"
                   				msg_tokens$[2]=Translate!.getTranslation("DDM_TABLES-GLE_JRNLHDR-DD_ATTR_WINT")
                    				break
                				case thisTable$="GLE_RECJEHDR"
                    				msg_tokens$[2]=Translate!.getTranslation("DDM_TABLES-GLE_RECJEHDR-DD_ATTR_WINT")
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
		callpoint!.setColumnData("GLC_CYCLECODE.CODE_INACTIVE","N",1)
	endif

	return



