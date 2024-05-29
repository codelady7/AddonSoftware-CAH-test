[[GLM_AUDITCONTROL.ARAR]]
ctl_name$="GLM_AUDITCONTROL.GL_POST_MEMO"
ctl_stat$=" "

gosub disable_fields

rem --- for reasons I don't understand, this field, tho' not marked display only, would not wake up;
rem --- so am doing it forcibly here.

callpoint!.setColumnData("<<DISPLAY>>.DISP_AUDIT_NUM",callpoint!.getColumnData("GLM_AUDITCONTROL.AUDIT_NUMBER"))

[[GLM_AUDITCONTROL.BSHO]]
rem --- Open/Lock files
	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="GLC_JOURNALCODE",open_opts$[1]="OTA"

	gosub open_tables

[[GLM_AUDITCONTROL.JOURNAL_ID.AVAL]]
rem --- Don't allow inactive code
	glcJournalCode_dev=fnget_dev("GLC_JOURNALCODE")
	dim glcJournalCode$:fnget_tpl$("GLC_JOURNALCODE")
	journal_id_cd$=callpoint!.getUserInput()
	read record(glcJournalCode_dev,key=firm_id$+journal_id_cd$,dom=*next)glcJournalCode$
	if glcJournalCode.code_inactive$ = "Y"
		msg_id$="AD_CODE_INACTIVE"
		dim msg_tokens$[2]
		msg_tokens$[1]=cvs(glcJournalCode.journal_id$,3)
		msg_tokens$[2]=cvs(glcJournalCode.code_desc$,3)
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif

[[GLM_AUDITCONTROL.<CUSTOM>]]
rem #include disable_fields.src

disable_fields:
	rem --- used to disable/enable controls
	rem --- ctl_name$ sent in with name of control to enable/disable (format "ALIAS.CONTROL_NAME")
	rem --- ctl_stat$ sent in as D or space, meaning disable/enable, respectively

	wctl$=str(num(callpoint!.getTableColumnAttribute(ctl_name$,"CTLI")):"00000")
	wmap$=callpoint!.getAbleMap()
	wpos=pos(wctl$=wmap$,8)
	wmap$(wpos+6,1)=ctl_stat$
	callpoint!.setAbleMap(wmap$)
	callpoint!.setStatus("ABLEMAP-REFRESH-ACTIVATE")

return

rem #endinclude disable_fields.src



