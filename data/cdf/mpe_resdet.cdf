[[MPE_RESDET.BSHO]]
rem --- Open/Lock tables
	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="BMC_OPCODES",open_opts$[1]="OTA"
	gosub open_tables

[[MPE_RESDET.OP_CODE.AVAL]]
rem --- Don't allow inactive code
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



