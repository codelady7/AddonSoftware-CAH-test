[[GLR_RECURRING.ARAR]]
rem --- Initialize Posting Month and Posting Year with system date
	dim sysinfo$:stbl("+SYSINFO_TPL")
	sysinfo$=stbl("+SYSINFO")
	callpoint!.setColumnData("GLR_RECURRING.POSTING_MONTH",sysinfo.system_date$(5,2),1)
	callpoint!.setColumnData("GLR_RECURRING.POSTING_YEAR",sysinfo.system_date$(1,4),1)

[[GLR_RECURRING.BSHO]]
rem --- Open/Lock files
	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="GLC_CYCLECODE",open_opts$[1]="OTA"

	gosub open_tables

[[GLR_RECURRING.CYCLE_CODE.AVAL]]
rem --- Warn about inactive code Cycle Code
	glcCycleCode_dev=fnget_dev("GLC_CYCLECODE")
	dim glcCycleCode$:fnget_tpl$("GLC_CYCLECODE")
	cycle_code$=callpoint!.getUserInput()
	findrecord(glcCycleCode_dev,key=firm_id$+cycle_code$,dom=*next)glcCycleCode$
	if glcCycleCode.code_inactive$ = "Y"
		msg_id$="AD_CODE_INACTIVE_OK"
		dim msg_tokens$[2]
		msg_tokens$[1]=cvs(glcCycleCode.cycle_code$,3)
		msg_tokens$[2]=cvs(glcCycleCode.code_desc$,3)
		gosub disp_message
		if msg_opt$="C" then callpoint!.setStatus("ABORT")
		break
	endif



