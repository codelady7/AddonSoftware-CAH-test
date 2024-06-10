[[SFE_WOSCHDL.BFMC]]
rem --- open files/init

	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="SFS_PARAMS",open_opts$[1]="OTA"

	gosub open_tables

	sfs_params=num(open_chans$[1])

	dim sfs_params$:open_tpls$[1]

	read record (sfs_params,key=firm_id$+"SF00",dom=std_missing_params)sfs_params$
	bm$=sfs_params.bm_interface$

	if bm$="Y"
		call stbl("+DIR_PGM")+"adc_application.aon","BM",info$[all]
		bm$=info$[20]
	endif
	callpoint!.setDevObject("bm",bm$)

	if bm$<>"Y"
		callpoint!.setTableColumnAttribute("SFE_WOSCHDL.OP_CODE","DTAB","SFC_OPRTNCOD")
	else
		rem --- Open Bill Of Materials tables
		num_files=1
		dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
		open_tables$[1]="BMC_OPCODES",open_opts$[1]="OTA"
		gosub open_tables
	endif

[[SFE_WOSCHDL.OP_CODE.AVAL]]
rem --- Don't allow inactive code
	if callpoint!.getDevObject("bm")="Y" then
		bmm08=fnget_dev("BMC_OPCODES")
		dim bmm08$:fnget_tpl$("BMC_OPCODES")
		op_code$=callpoint!.getUserInput()
		read record (bmm08,key=firm_id$+op_code$,dom=*next)bmm08$
		if bmm08.code_inactive$ = "Y"
			msg_id$="AD_CODE_INACTIVE"
			dim msg_tokens$[2]
			msg_tokens$[1]=cvs(bmm08.op_code$,3)
			msg_tokens$[2]=cvs(bmm08.code_desc$,3)
			gosub disp_message
			callpoint!.setStatus("ABORT")
			break
		endif
	endif

[[SFE_WOSCHDL.<CUSTOM>]]
rem ==========================================================================
#include [+ADDON_LIB]std_missing_params.aon
rem ==========================================================================



