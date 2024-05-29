[[GLS_SUSPENSE.BSHO]]
rem --- Open/Lock files
	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="GLC_JOURNALCODE",open_opts$[1]="OTA"

	gosub open_tables

[[GLS_SUSPENSE.GL_ACCOUNT.AVAL]]
rem "GL INACTIVE FEATURE"
   glm01_dev=fnget_dev("GLM_ACCT")
   glm01_tpl$=fnget_tpl$("GLM_ACCT")
   dim glm01a$:glm01_tpl$
   glacctinput$=callpoint!.getUserInput()
   glm01a_key$=firm_id$+glacctinput$
   find record (glm01_dev,key=glm01a_key$,err=*break) glm01a$
   if glm01a.acct_inactive$="Y" then
      call stbl("+DIR_PGM")+"adc_getmask.aon","GL_ACCOUNT","","","",m0$,0,gl_size
      msg_id$="GL_ACCT_INACTIVE"
      dim msg_tokens$[2]
      msg_tokens$[1]=fnmask$(glm01a.gl_account$(1,gl_size),m0$)
      msg_tokens$[2]=cvs(glm01a.gl_acct_desc$,2)
      gosub disp_message
      callpoint!.setStatus("ACTIVATE-ABORT")
   endif

[[GLS_SUSPENSE.JOURNAL_ID.AVAL]]
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

[[GLS_SUSPENSE.USE_SUSPENSE.AVAL]]
if callpoint!.getUserInput()="Y"
 callpoint!.setTableColumnAttribute("GLS_SUSPENSE.GL_ACCOUNT","MINL","1")

endif

[[GLS_SUSPENSE.<CUSTOM>]]
#include [+ADDON_LIB]std_functions.aon



