[[GLC_JOURNALCODE.BDEL]]
rem --- When deleting the Journal ID code, warn if there are any current/active transactions for the code, and disallow if there are any.
	gosub check_active_code
	if found then callpoint!.setStatus("ABORT")

rem --- Do they want to deactivate code instead of deleting it?
	msg_id$="AD_DEACTIVATE_CODE"
	gosub disp_message
	if msg_opt$="Y" then
		rem --- Check the CODE_INACTIVE checkbox
		row=callpoint!.getValidationRow()
		grid!=Form!.getControl(num(stbl("+GRID_CTL")))
		grid!.setCellState(row,5,1)

		callpoint!.setColumnData("GLC_JOURNALCODE.CODE_INACTIVE","Y",1)
		callpoint!.setStatus("SAVE;ABORT")
	endif

[[GLC_JOURNALCODE.BSHO]]
rem --- Open/Lock files
	num_files=5
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="ADM_AUDITCONTROL",open_opts$[1]="OTA"
	open_tables$[2]="GLE_JRNLHDR",open_opts$[2]="OTA"
	open_tables$[3]="GLE_RECJEHDR",open_opts$[3]="OTA"
	open_tables$[4]="GLS_SUSPENSE",open_opts$[4]="OTA"
	open_tables$[5]="GLX_CLSDYRADJHDR",open_opts$[5]="OTA"

	gosub open_tables

[[GLC_JOURNALCODE.CODE_INACTIVE.AVAL]]
rem --- When deactivating the Journal ID code, warn if there are any current/active transactions for the code, and disallow if there are any.
	current_inactive$=callpoint!.getUserInput()
	prior_inactive$=callpoint!.getColumnData("GLC_JOURNALCODE.CODE_INACTIVE")
	if current_inactive$="Y" and prior_inactive$<>"Y" then
		gosub check_active_code
		if found then callpoint!.setStatus("ABORT")
	endif

[[GLC_JOURNALCODE.<CUSTOM>]]
#include [+ADDON_LIB]std_missing_params.aon

rem ==========================================================================
check_active_code: rem --- Warn if there are any current/active transactions for the code
rem ==========================================================================
	found=0
	journal_id$=callpoint!.getColumnData("GLC_JOURNALCODE.JOURNAL_ID")

	checkTables!=BBjAPI().makeVector()
	checkTables!.addItem("ADM_AUDITCONTROL")
	checkTables!.addItem("GLE_JRNLHDR")
	checkTables!.addItem("GLE_RECJEHDR")
	checkTables!.addItem("GLS_SUSPENSE")
	checkTables!.addItem("GLX_CLSDYRADJHDR")
	for i=0 to checkTables!.size()-1
		thisTable$=checkTables!.getItem(i)
		table_dev = fnget_dev(thisTable$)
		dim table_tpl$:fnget_tpl$(thisTable$)
		read(table_dev,key=firm_id$,dom=*next)
		while 1
			readrecord(table_dev,end=*break)table_tpl$
			if table_tpl.firm_id$<>firm_id$ then break
			if table_tpl.journal_id$=journal_id$ then
				msg_id$="AD_CODE_IN_USE"
				dim msg_tokens$[2]
				msg_tokens$[1]=Translate!.getTranslation("AON_JOURNAL_ID_")
				switch (BBjAPI().TRUE)
					case thisTable$="ADM_AUDITCONTROL"
						msg_tokens$[2]=Translate!.getTranslation("DDM_TABLES-ADM_AUDITCONTROL-DD_ATTR_WINT")
						break
                				case thisTable$="GLE_JRNLHDR"
                   				msg_tokens$[2]=Translate!.getTranslation("DDM_TABLES-GLE_JRNLHDR-DD_ATTR_WINT")
                    				break
                				case thisTable$="GLE_RECJEHDR"
                    				msg_tokens$[2]=Translate!.getTranslation("DDM_TABLES-GLE_RECJEHDR-DD_ATTR_WINT")
                    				break
                				case thisTable$="GLS_SUSPENSE"
                    				msg_tokens$[2]=Translate!.getTranslation("DDM_TABLES-GLS_SUSPENSE-DD_ATTR_WINT")
                    				break
                				case thisTable$="GLX_CLSDYRADJHDR"
                    				msg_tokens$[2]="Closed Fiscal Year Adjustments Utility"
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
		row=callpoint!.getValidationRow()
		grid!=Form!.getControl(num(stbl("+GRID_CTL")))
		grid!.setCellState(row,5,0)

		callpoint!.setColumnData("GLC_JOURNALCODE.CODE_INACTIVE","N",1)
	endif

	return



