[[GLC_JOURNALCODE.BDEL]]
rem --- When deleting the Journal ID code, warn if there are any current/active transactions for the code, and disallow if there are any.
	gosub check_active_code
	if found then callpoint!.setStatus("ABORT")

[[GLC_JOURNALCODE.BSHO]]
rem --- Open/Lock files
	num_files=13
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="GLE_JRNLHDR",open_opts$[1]="OTA"
	open_tables$[2]="GLE_RECJEHDR",open_opts$[2]="OTA"
	open_tables$[3]="GLX_CLSDYRADJHDR",open_opts$[3]="OTA"

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
rem ==========================================================================
check_active_code: rem --- Warn if there are any current/active transactions for the code
rem ==========================================================================
	found=0
	journal_id$=callpoint!.getColumnData("GLC_JOURNALCODE.JOURNAL_ID")

	gleJrnlHdr_dev=fnget_dev("GLE_JRNLHDR")
	read(gleJrnlHdr_dev,key=firm_id$+journal_id$,dom=*next)
	gleJrnlHdr_key$=key(gleJrnlHdr_dev,end=*next)
	if pos(firm_id$+journal_id$=gleJrnlHdr_key$)=1 then found=1
	if found then
		msg_id$="AD_CODE_IN_USE"
		dim msg_tokens$[2]
		msg_tokens$[1]=Translate!.getTranslation("AON_JOURNAL_ID_")
		msg_tokens$[2]=Translate!.getTranslation("AON_JOURNAL_ENTRY")
		gosub disp_message
	endif

	if !found then
		gleRecJEHdr_dev=fnget_dev("GLE_RECJEHDR")
		read(gleRecJEHdr_dev,key=firm_id$+journal_id$,dom=*next)
		gleRecJEHdr_key$=key(gleRecJEHdr_dev,end=*next)
		if pos(firm_id$+journal_id$=gleRecJEHdr_key$)=1 then found=1
		if found then
			msg_id$="AD_CODE_IN_USE"
			dim msg_tokens$[2]
			msg_tokens$[1]=Translate!.getTranslation("AON_JOURNAL_ID_")
			msg_tokens$[2]=Translate!.getTranslation("AON_RECURRING_JOURNAL_ENTRY")
			gosub disp_message
		endif
	endif

	if !found then
		glxClsdYrAdjHdr_dev=fnget_dev("GLX_CLSDYRADJHDR")
		read(glxClsdYrAdjHdr_dev,key=firm_id$+journal_id$,dom=*next)
		glxClsdYrAdjHdr_key$=key(glxClsdYrAdjHdr_dev,end=*next)
		if pos(firm_id$+journal_id$=glxClsdYrAdjHdr_key$)=1 then found=1
		if found then
			msg_id$="AD_CODE_IN_USE"
			dim msg_tokens$[2]
			msg_tokens$[1]=Translate!.getTranslation("AON_JOURNAL_ID_")
			msg_tokens$[2]="Closed Fiscal Year Adjustments Utility"
			gosub disp_message
		endif
	endif

	if found then
		rem --- Uncheck the CODE_INACTIVE checkbox
		row=callpoint!.getValidationRow()
		grid!=Form!.getControl(num(stbl("+GRID_CTL")))
		grid!.setCellState(row,5,0)

		callpoint!.setColumnData("GLC_JOURNALCODE.CODE_INACTIVE","N",1)
	endif

	return

#include [+ADDON_LIB]std_missing_params.aon



