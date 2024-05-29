[[ADM_AUDITCONTROL.ARNF]]
rem --- no GL Post rec exists for this process (but the process, in adm-19, does exist)
rem --- forward process alias and process program (one or the other will be blank) from adm-19 to glm-06

adm19_dev=fnget_dev("ADM_PROCDETAIL")
dim adm19a$:fnget_tpl$("ADM_PROCDETAIL")

read record (adm19_dev,key=firm_id$+callpoint!.getColumnData("ADM_AUDITCONTROL.PROCESS_ID")+
:	callpoint!.getColumnData("ADM_AUDITCONTROL.SEQUENCE_NO"),dom=*next)adm19a$
callpoint!.setColumnData("ADM_AUDITCONTROL.PROCESS_ALIAS",adm19a.dd_table_alias$)
callpoint!.setColumnData("ADM_AUDITCONTROL.PROCESS_PROGRAM",adm19a.program_name$)

callpoint!.setStatus("REFRESH")

[[ADM_AUDITCONTROL.BSHO]]
rem --- Open/Lock files
	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="GLC_JOURNALCODE",open_opts$[1]="OTA"

	gosub open_tables

[[ADM_AUDITCONTROL.JOURNAL_ID.AVAL]]
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



