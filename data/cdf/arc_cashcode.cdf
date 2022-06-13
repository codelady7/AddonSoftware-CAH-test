[[ARC_CASHCODE.ADEL]]
rem --- delete corresponding ars_cc_custsvc, ars_cc_custpmt, if applicable

	ars_cc_custpmt=fnget_dev("ARS_CC_CUSTPMT")
	ars_cc_custsvc=fnget_dev("ARS_CC_CUSTSVC")

	remove(ars_cc_custpmt,key=firm_id$+callpoint!.getColumnData("ARC_CASHCODE.CASH_REC_CD"),dom=*next)
	remove(ars_cc_custsvc,key=firm_id$+callpoint!.getColumnData("ARC_CASHCODE.CASH_REC_CD"),dom=*next)

[[ARC_CASHCODE.ADIS]]
codeinactive$=callpoint!.getColumnData("ARC_CASHCODE.CODE_INACTIVE")
discountactive$=callpoint!.getColumnData("ARC_CASHCODE.DISC_FLAG")


gosub disable_inactive

[[ARC_CASHCODE.AOPT-CSVC]]
rem --- launch params for AR (customer service) credit card payments

	cash_cd$=callpoint!.getColumnData("ARC_CASHCODE.CASH_REC_CD")

	dim dflt_data$[1,1]
	dflt_data$[0,0]="FIRM_ID"
	dflt_data$[0,1]=firm_id$
	dflt_data$[1,0]="CASH_REC_CD"
	dflt_data$[1,1]=cash_cd$

	key_pfx$=firm_id$+cash_cd$

	call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:		"ARS_CC_CUSTSVC",
:		stbl("+USER_ID"),
:		"",
:		key_pfx$,
:		table_chans$[all],
:		"",
:		dflt_data$[all]

[[ARC_CASHCODE.AOPT-CUST]]
rem --- launch params for online customer credit card payments

	cash_cd$=callpoint!.getColumnData("ARC_CASHCODE.CASH_REC_CD")

	dim dflt_data$[1,1]
	dflt_data$[0,0]="FIRM_ID"
	dflt_data$[0,1]=firm_id$
	dflt_data$[1,0]="CASH_REC_CD"
	dflt_data$[1,1]=cash_cd$

	key_pfx$=firm_id$+cash_cd$

	call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:		"ARS_CC_CUSTPMT",
:		stbl("+USER_ID"),
:		"",
:		key_pfx$,
:		table_chans$[all],
:		"",
:		dflt_data$[all]

[[ARC_CASHCODE.BDEL]]
if callpoint!.getColumnData("ARC_CASHCODE.CODE_INACTIVE") <> "Y"
	msg_id$="AR_INACTIVE_OPTION"
	gosub disp_message
	If msg_opt$="N" then
		callpoint!.setStatus("ABORT")
endif
		
  

[[ARC_CASHCODE.BSHO]]
rem --- Disable Pos Cash Type if OP not installed
	call stbl("+DIR_PGM")+"adc_application.aon","OP",info$[all]
	if info$[20] = "N"then
		callpoint!.setColumnEnabled("ARC_CASHCODE.TRANS_TYPE",-1)
    
    		cash_sales$="N"
		op_installed$="N"
	else
		op_installed$="Y"
		num_files=1
		dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
		open_tables$[1]="OPS_PARAMS",open_opts$[1]="OTA"
		gosub open_tables

		ops_params_dev=num(open_chans$[1] )
		dim ops_params$:open_tpls$[1]

		readrecord (ops_params_dev,key=firm_id$+"AR00",err=std_missing_params)ops_params$
		callpoint!.setDevObject("op_installed",op_installed$)
		callpoint!.setDevObject("cash_sales",ops_params.cash_sale$)
		if op_installed$ = "Y" and ops_params.cash_sale$ = "Y" then
			num_files=1
			dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
			open_tables$[1]="OPT_INVCASH",open_opts$[1]="OTA"
			gosub open_tables
		endif

	endif

	rem --- Disable G/L Accounts if G/L not installed
	call stbl("+DIR_PGM")+"adc_application.aon","GL",info$[all]
	if info$[20] = "N"
		callpoint!.setColumnEnabled("ARC_CASHCODE.GL_CASH_ACCT",-1)
		callpoint!.setColumnEnabled("ARC_CASHCODE.GL_DISC_ACCT",-1)
	endif

rem --- Open credit card param files for ADEL
rem --- also to check current transactions

	num_files=5
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="ARS_CC_CUSTPMT",open_opts$[1]="OTA"
	open_tables$[2]="ARS_CC_CUSTSVC",open_opts$[2]="OTA"
	open_tables$[3]="ARE_CASHHDR",open_opts$[3]="OTA"
	open_tables$[4]="ART_DEPOSIT",open_opts$[4]="OTA"
	open_tables$[5]="ARS_PARAMS",open_opts$[5]="OTA"

	gosub open_tables

[[ARC_CASHCODE.CODE_INACTIVE.AVAL]]
codeinactive$=callpoint!.getUserInput()
discountactive$ = callpoint!.getColumnData("ARC_CASHCODE.DISC_FLAG")

gosub disable_inactive

rem --- if cash receipt code set to inactive, check for active cash receipts 
rem --- if cash receipt code set to inactive and bank reconciliation is on, check for active bank deposits
rem --- if cash receipt code set to inactive and op is installed and cash sales are allowed then check for active cash sales
rem --- if active transactions exist, disallow inactivation of cash receipt code
rem --- if no active transactions, then check to see if there are active credit card parameters set up
rem --- if active credit card parameters, warn before allowing inactivation
rem --- if cash receipt code inactivated, set accepts credit cards to no on related credit card parameters

if callpoint!.getUserInput()="Y"

	active_trans_found$="N"

	ars_params=fnget_dev("ARS_PARAMS")
   	dim ars_params$:fnget_tpl$("ARS_PARAMS")

    	find record (ars_params,key=firm_id$+"AR00",err=std_missing_params) ars_params$
  	br$=ars_params.br_interface$

	are_cashhdr=fnget_dev("ARE_CASHHDR")
   	dim are_cashhdr$:fnget_tpl$("ARE_CASHHDR")
    	read(are_cashhdr,key=firm_id$+callpoint!.getColumnData("ARC_CASHCODE.CASH_REC_CD"),knum="AO_RECCD_RCPTDAT",dom=*next)
        wk$=key(are_cashhdr,err=*next)

	if pos(firm_id$+callpoint!.getColumnData("ARC_CASHCODE.CASH_REC_CD")=wk$)=1
		msg_id$="AR_ACTIVE_CASH_RCPTS"
		gosub disp_message
		callpoint!.setUserInput("N")
		active_trans_found$="Y"
		break
	endif

	if callpoint!.getDevObject("cash_sales") = "Y" then

		opt_invcash=fnget_dev("OPT_INVCASH")
	   	dim opt_invcash$:fnget_tpl$("OPT_INVCASH")
    	 
		read(opt_invcash,key=firm_id$,dom=*next)
		active_cash_sale_found$ = "N"

		while 1
			readrecord(opt_invcash,end=*break)opt_invcash$

			if opt_invcash.firm_id$<>firm_id$ then break
			if opt_invcash.cash_rec_cd$=callpoint!.getColumnData("ARC_CASHCODE.CASH_REC_CD") and opt_invcash.trans_status$ = "E" then 
	
				active_cashsale_found$ = "Y"
				break
			endif

		wend

		if active_cashsale_found$ = "Y"
			msg_id$="AR_ACTIVE_CASH_SALE"
			gosub disp_message
			callpoint!.setUserInput("N")
			active_trans_found$="Y"
			break
		endif
	endif
	
	if br$="Y" then
		art_deposit=fnget_dev("ART_DEPOSIT")
  	 	dim art_deposit$:fnget_tpl$("ART_DEPOSIT")


		read(art_deposit,key=firm_id$,dom=*next)
		active_deposit_found$ = "N"

		while 1
			readrecord(art_deposit,end=*break)art_deposit$
			if art_deposit.firm_id$<>firm_id$ then break
			if art_deposit.cash_rec_cd$=callpoint!.getColumnData("ARC_CASHCODE.CASH_REC_CD") and art_deposit.trans_status$ = "E" then 
	
				active_deposit_found$ = "Y"
				break
			endif
		wend

		if active_deposit_found$ = "Y"
			msg_id$="AR_ACTIVE_BANK_DEPS"
			gosub disp_message
			callpoint!.setUserInput("N")
			active_trans_found$="Y"
			break
		endif
	endif


	if active_trans_found$="N" then
    		found=0
    		ars_cc_custpmt=fnget_dev("ARS_CC_CUSTPMT")
   		dim ars_cc_custpmt$:fnget_tpl$("ARS_CC_CUSTPMT")
    		found=0
    		readrecord(ars_cc_custpmt,key=firm_id$+callpoint!.getColumnData("ARC_CASHCODE.CASH_REC_CD"),dom=*next)ars_cc_custpmt$;found=1
    		if found = 1
        			if ars_cc_custpmt.allow_cust_cc$="Y"
				msg_id$="AR_ACCEPT_CC_PARAMS"
				gosub disp_message
				if msg_opt$="Y" then
		
        					extractrecord(ars_cc_custpmt,key=firm_id$+callpoint!.getColumnData("ARC_CASHCODE.CASH_REC_CD"))ars_cc_custpmt$; rem --- something wrong if record is missing here
            				ars_cc_custpmt.allow_cust_cc$="N"
            				writerecord(ars_cc_custpmt)ars_cc_custpmt$
				else
					callpoint!.setUserInput("N")

					break
				endif
        			endif
    		endif

		ars_cc_custsvc=fnget_dev("ARS_CC_CUSTSVC")
 	  	dim ars_cc_custsvc$:fnget_tpl$("ARS_CC_CUSTSVC")
 	   	found=0
  	  	readrecord(ars_cc_custsvc,key=firm_id$+callpoint!.getColumnData("ARC_CASHCODE.CASH_REC_CD"),dom=*next)ars_cc_custsvc$;found=1
		if found = 1

      			if ars_cc_custsvc.use_custsvc_cc$="Y"
				msg_id$="AR_ACCEPT_CC_PARAMS"
				gosub disp_message
				if msg_opt$="Y" then
     		      			extractrecord(ars_cc_custsvc,key=firm_id$+callpoint!.getColumnData("ARC_CASHCODE.CASH_REC_CD"))ars_cc_custsvc$; rem --- something wrong if record is missing here
        	   				ars_cc_custsvc.use_custsvc_cc$="N"
            				writerecord(ars_cc_custsvc)ars_cc_custsvc$
				else
					callpoint!.setUserInput("N")
					break
				endif
        			endif
   		endif
    
    	endif 
endif

if callpoint!.getUserInput()="N"
	found=0
    	ars_cc_custpmt=fnget_dev("ARS_CC_CUSTPMT")
   	dim ars_cc_custpmt$:fnget_tpl$("ARS_CC_CUSTPMT")
    	found=0
    	readrecord(ars_cc_custpmt,key=firm_id$+callpoint!.getColumnData("ARC_CASHCODE.CASH_REC_CD"),dom=*next)ars_cc_custpmt$;found=1
    	if found = 1
		msg_id$="AR_REVIEW_CC_PARAMS"
		gosub disp_message
		break
	endif
	if found = 1 then
		ars_cc_custsvc=fnget_dev("ARS_CC_CUSTSVC")
 		dim ars_cc_custsvc$:fnget_tpl$("ARS_CC_CUSTSVC")
 		foundtwo=0
  		readrecord(ars_cc_custsvc,key=firm_id$+callpoint!.getColumnData("ARC_CASHCODE.CASH_REC_CD"),dom=*next)ars_cc_custsvc$;foundtwo=1
		if foundtwo = 1
			msg_id$="AR_REVIEW_CC_PARAMS"
			gosub disp_message
			break
		endif
	endif
endif

[[ARC_CASHCODE.DISC_FLAG.AVAL]]
discountactive$=callpoint!.getUserInput()
codeinactive$=callpoint!.getColumnData("ARC_CASHCODE.CODE_INACTIVE")

gosub disable_inactive

[[ARC_CASHCODE.GL_CASH_ACCT.AVAL]]
gosub gl_inactive

[[ARC_CASHCODE.GL_DISC_ACCT.AVAL]]
gosub gl_inactive

[[ARC_CASHCODE.<CUSTOM>]]
#include [+ADDON_LIB]std_functions.aon
#include [+ADDON_LIB]std_missing_params.aon

gl_inactive:

rem "GL INACTIVE FEATURE"
   glm01_dev=fnget_dev("GLM_ACCT")
   glm01_tpl$=fnget_tpl$("GLM_ACCT")
   dim glm01a$:glm01_tpl$
   glacctinput$=callpoint!.getUserInput()
   glm01a_key$=firm_id$+glacctinput$
   find record (glm01_dev,key=glm01a_key$,err=*return) glm01a$
   if glm01a.acct_inactive$="Y" then
      call stbl("+DIR_PGM")+"adc_getmask.aon","GL_ACCOUNT","","","",m0$,0,gl_size
      msg_id$="GL_ACCT_INACTIVE"
      dim msg_tokens$[2]
      msg_tokens$[1]=fnmask$(glm01a.gl_account$(1,gl_size),m0$)
      msg_tokens$[2]=cvs(glm01a.gl_acct_desc$,2)
      gosub disp_message
      callpoint!.setStatus("ACTIVATE-ABORT")
   endif
return

disable_inactive:

rem - Disable columns if code is Inactive

if codeinactive$<>"Y"
	 enable_flag = 1
else
	enable_flag = 0
endif
		
callpoint!.setOptionEnabled("CSVC",enable_flag)
callpoint!.setOptionEnabled("CUST",enable_flag)
callpoint!.setColumnEnabled("ARC_CASHCODE.CODE_DESC",enable_flag)
callpoint!.setColumnEnabled("ARC_CASHCODE.GL_CASH_ACCT",enable_flag)
callpoint!.setColumnEnabled("ARC_CASHCODE.ARGLBOTH",enable_flag)
callpoint!.setColumnEnabled("ARC_CASHCODE.CASH_FLAG",enable_flag)
callpoint!.setColumnEnabled("ARC_CASHCODE.DISC_FLAG",enable_flag)
callpoint!.setColumnEnabled("ARC_CASHCODE.GL_DISC_ACCT",enable_flag)
callpoint!.setColumnEnabled("ARC_CASHCODE.TRANS_TYPE",enable_flag)

if discountactive$<>"Y" and codeinactive$<>"Y"
	callpoint!.setColumnEnabled("ARC_CASHCODE.GL_DISC_ACCT",0)


endif

return



