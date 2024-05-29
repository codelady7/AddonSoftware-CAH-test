[[POE_QAHDR.BSHO]]
rem --- Open Files
	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="APC_TERMSCODE",open_opts$[1]="OTA"

	gosub open_tables

[[POE_QAHDR.TERMS_CODE.AVAL]]
rem --- Don't allow inactive code
	apcTermsCode_dev=fnget_dev("APC_TERMSCODE")
	dim apcTermsCode$:fnget_tpl$("APC_TERMSCODE")
	ap_terms_code$=callpoint!.getUserInput()
	read record(apcTermsCode_dev,key=firm_id$+"C"+ap_terms_code$,dom=*next)apcTermsCode$
	if apcTermsCode.code_inactive$ = "Y"
		msg_id$="AD_CODE_INACTIVE"
		dim msg_tokens$[2]
		msg_tokens$[1]=cvs(apcTermsCode.terms_codeap$,3)
		msg_tokens$[2]=cvs(apcTermsCode.code_desc$,3)
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif



