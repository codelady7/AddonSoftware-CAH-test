[[APR_CHECKS.ACUS]]
rem --- Process custom event
rem This routine is executed when callbacks have been set to run a 'custom event'.
rem Analyze gui_event$ and notice$ to see which control's callback triggered the event, and what kind of event it is.
rem See basis docs notice() function, noticetpl() function, notify event, grid control notify events for more info.

	dim gui_event$:tmpl(gui_dev)
	dim notify_base$:noticetpl(0,0)
	gui_event$=SysGUI!.getLastEventString()
	ctl_ID=dec(gui_event.ID$)

	notify_base$=notice(gui_dev,gui_event.x%)
	dim notice$:noticetpl(notify_base.objtype%,gui_event.flags%)
	notice$=notify_base$

	rem --- The CHECK_ACCTS ListButton
	chkAcctCtl!=callpoint!.getControl("APR_CHECKS.CHECK_ACCTS")
	if ctl_ID=chkAcctCtl!.getID() then
		switch notice.code
			case 2; rem --- ON_LIST_SELECT
				rem --- Initialize CHECK_NO for the selected checking account
				index=chkAcctCtl!.getSelectedIndex()
				nextChkList!=callpoint!.getDevObject("nextCheckList")
				callpoint!.setColumnData("APR_CHECKS.CHECK_NO",nextChkList!.getItem(index),1)

				rem --- Hold on to selected Bank Account Code, i.e. Checking Account
				bnkAcctCdList!=callpoint!.getDevObject("bnkAcctCdList")
				bnkAcctCd$=bnkAcctCdList!.getItem(index)
				callpoint!.setDevObject("bnkAcctCd",bnkAcctCd$)
			break
		swend
	endif

[[APR_CHECKS.ADIS]]
rem --- Refresh Checking Account ListButton when using previously saved selections.
	gosub initCheckAccts

[[APR_CHECKS.ARER]]
rem --- Use default check form order if available
	default_form_order$=callpoint!.getDevObject("default_form_order")
	if cvs(default_form_order$,2)<>"" then
		callpoint!.setColumnData("APR_CHECKS.FORM_ORDER",default_form_order$,1)
		formorderListButton!=callpoint!.getControl("APR_CHECKS.FORM_ORDER")
		formorderVector!=formorderListButton!.getAllItems()
		for i=0 to formorderVector!.size()-1
			if pos(default_form_order$=formorderVector!.getItem(i)) then
				formorderListButton!.selectIndex(i)
				break
			endif
		next i
	endif

rem --- Initialize and enable/disable prnt_signature and signature_file
	if callpoint!.getDevObject("use_pay_auth") then
		rem --- Use Payment Authorization signature file(s)
		callpoint!.setColumnData("APR_CHECKS.PRNT_SIGNATURE","Y",1)
		callpoint!.setColumnEnabled("APR_CHECKS.PRNT_SIGNATURE",0)
		callpoint!.setColumnData("APR_CHECKS.SIGNATURE_FILE","",1)
		callpoint!.setColumnEnabled("APR_CHECKS.SIGNATURE_FILE",0)
	else
		if callpoint!.getDevObject("aps01_prnt_signature")="Y" then
			rem --- Use AP Parameters signature file
			callpoint!.setColumnData("APR_CHECKS.PRNT_SIGNATURE","Y",1)
			callpoint!.setColumnEnabled("APR_CHECKS.PRNT_SIGNATURE",1)
			callpoint!.setColumnData("APR_CHECKS.SIGNATURE_FILE",str(callpoint!.getDevObject("aps01_signature_file")),1)
			callpoint!.setColumnEnabled("APR_CHECKS.SIGNATURE_FILE",1)
		else
			rem --- Not using signature file(s)
			callpoint!.setColumnData("APR_CHECKS.PRNT_SIGNATURE","N",1)
			callpoint!.setColumnEnabled("APR_CHECKS.PRNT_SIGNATURE",0)
			callpoint!.setColumnData("APR_CHECKS.SIGNATURE_FILE","",1)
			callpoint!.setColumnEnabled("APR_CHECKS.SIGNATURE_FILE",0)
		endif
	endif

rem --- Initialize Checking Account ListButton for all selected invoices
	gosub initCheckAccts

rem --- Set the defalut AP Type when not multi-type
	if callpoint!.getDevObject("multi_types")="N" then
		dflt_ap_type$=callpoint!.getDevObject("dflt_ap_type")
		callpoint!.setColumnData("APR_CHECKS.AP_TYPE",dflt_ap_type$)
	endif

[[APR_CHECKS.ASVA]]
rem --- Validate Check Number unless only ACH payments selected, i.e. there are no printed checks
if num(callpoint!.getColumnData("APR_CHECKS.CHECK_NO")) = 0 then
	if callpoint!.getDevObject("ach_allowed") then
	rem --- Were any non-ACH payments selected, i.e. are there any printed checks?
		ape04_dev=fnget_dev("APE_CHECKS")
		dim ape04a$:fnget_tpl$("APE_CHECKS")
		apm01_dev=fnget_dev("APM_VENDMAST")
		dim apm01a$:fnget_tpl$("APM_VENDMAST")

		needCheckNumber=0
		read(ape04_dev,key=firm_id$,dom=*next)
		while 1
			readrecord(ape04_dev,end=*break)ape04a$
			if ape04a.firm_id$<>firm_id$ then break
			readrecord(apm01_dev,key=firm_id$+ape04a.vendor_id$,dom=*continue)apm01a$
			if apm01a.payment_type$<>"P" then continue
			needCheckNumber=1
			break
		wend
	else
		needCheckNumber=1
	endif

	if needCheckNumber then
		msg_id$="ENTRY_INVALID"
		dim msg_tokens$[1]
		msg_tokens$[1]=Translate!.getTranslation("AON_CHECK_NUMBER")
		msg_opt$=""
		gosub disp_message
		callpoint!.setStatus("ABORT")
		rem --- Set focus on the Check Number field
		callpoint!.setFocus("APR_CHECKS.CHECK_NO")
		break
	endif
endif

rem --- Don't allow re-using an unwanted check number
if callpoint!.getDevObject("reuse_check_num")="N" then
	rem --- Set focus on the Check Number field
	callpoint!.setFocus("APR_CHECKS.CHECK_NO")
	break
endif

rem --- Validate Check Date
check_date$=callpoint!.getColumnData("APR_CHECKS.CHECK_DATE")
check_date=1
			
if cvs(check_date$,2)<>""
	check_date=0
	check_date=jul(num(check_date$(1,4)),num(check_date$(5,2)),num(check_date$(7,2)),err=*next)
endif
			
if len(cvs(check_date$,2))<>8 or check_date=0
	msg_id$="INVALID_DATE"
	dim msg_tokens$[1]
	msg_opt$=""
	gosub disp_message
	callpoint!.setStatus("ABORT")
	rem --- Set focus on the Check Date field
	callpoint!.setFocus("APR_CHECKS.CHECK_DATE")
	break
endif
rem --- validate Check Date
gl$="N"
status=0
source$=pgm(-2)
call stbl("+DIR_PGM")+"glc_ctlcreate.aon",err=*next,source$,"AP",glw11$,gl$,status
call stbl("+DIR_PGM")+"glc_datecheck.aon",check_date$,"Y",per$,yr$,status
if status>100
	callpoint!.setStatus("ABORT")
	rem --- Set focus on the Check Date field
	callpoint!.setFocus("APR_CHECKS.CHECK_DATE")
	break
endif

rem --- If all is well, write the softlock so only one jasper printing per firm can be run at a time
	currstatus$=callpoint!.getStatus()

	if len(cvs(currstatus$,2))=0
		menu_option_id$=callpoint!.getTableAttribute("ALID")

		adxlocks_dev=fnget_dev("ADX_LOCKS")
		dim adxlocks$:fnget_tpl$("ADX_LOCKS")

		adxlocks.firm_id$=firm_id$
		adxlocks.menu_option_id$=menu_option_id$

		extract record(adxlocks_dev,key=firm_id$+menu_option_id$,dom=*next)dummy$; rem Advisory Locking
		write record(adxlocks_dev)adxlocks$
	endif

[[APR_CHECKS.BEND]]
rem --- Make sure softlock is cleared when exiting/aborting
	adxlocks_dev=fnget_dev("ADX_LOCKS")
	dim adxlocks$:fnget_tpl$("ADX_LOCKS")
	menu_option_id$=pad(callpoint!.getTableAttribute("ALID"),len(adxlocks.menu_option_id$))

	remove (adxlocks_dev,key=firm_id$+menu_option_id$,dom=*next)

[[APR_CHECKS.BSHO]]
rem --- Inits
	use ::ado_func.src::func
	use java.io.File
	use java.util.HashMap

rem --- See if we need to disable AP Type
rem --- and see if a print run in currently running
	num_files=10
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="APS_PARAMS",open_opts$[1]="OTA"
	open_tables$[2]="ADX_LOCKS",   open_opts$[2]="OTA"
	open_tables$[3]="APT_CHECKHISTORY",open_opts$[3]="OTA"
	open_tables$[4]="APS_ACH",open_opts$[4]="OTA"
	open_tables$[5]="APM_VENDMAST",open_opts$[5]="OTA"
	open_tables$[6]="APE_CHECKS",open_opts$[6]="OTA"
	open_tables$[7]="APS_PAYAUTH",open_opts$[7]="OTA"
	open_tables$[8]="APT_INVOICEHDR",open_opts$[8]="OTA"
	open_tables$[9]="APC_DISTRIBUTION",open_opts$[9]="OTA"
	open_tables$[10]="ADC_BANKACCTCODE",open_opts$[10]="OTA"
	gosub open_tables

	aps01_dev=fnget_dev("APS_PARAMS")
	adxlocks_dev=fnget_dev("ADX_LOCKS")
	apsACH_dev=fnget_dev("APS_ACH")
	apsPayAuth_dev=fnget_dev("APS_PAYAUTH")

	dim aps01a$:fnget_tpl$("APS_PARAMS")
	dim adxlocks$:fnget_tpl$("ADX_LOCKS")
	dim apsACH$:fnget_tpl$("APS_ACH")
	dim apsPayAuth$:fnget_tpl$("APS_PAYAUTH")

rem --- Get parameters
	aps01_key$=firm_id$+"AP00"
	readrecord(aps01_dev,key=aps01_key$,dom=std_missing_params)aps01a$
	callpoint!.setDevObject("post_to_gl",aps01a.post_to_gl$)
	callpoint!.setDevObject("multi_types",aps01a.multi_types$)
	callpoint!.setDevObject("dflt_ap_type",aps01a.ap_type$)
	callpoint!.setDevObject("default_form_order",aps01a.form_order$)
	callpoint!.setDevObject("aps01_prnt_signature",aps01a.prnt_signature$)
	callpoint!.setDevObject("aps01_signature_file",aps01a.signature_file$)
	if aps01a.multi_types$ <> "Y" then
		ctl_name$="APR_CHECKS.AP_TYPE"
		ctl_stat$="I"
		gosub disable_fields
	endif

	if aps01a.post_to_gl$="Y" then
		num_files=1
		dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
		open_tables$[1]="GLM_BANKMASTER",open_opts$[1]="OTA"
		gosub open_tables
	endif

	readrecord(apsACH_dev,key=firm_id$+"AP00",dom=*next)apsACH$
	callpoint!.setDevObject("ach_allowed",iff(cvs(apsACH.bnk_acct_cd$,2)="",0,1))

	readrecord(apsPayAuth_dev,key=firm_id$+"AP00",dom=*next)apsPayAuth$
	callpoint!.setDevObject("use_pay_auth",apsPayAuth.use_pay_auth)

rem --- Abort if a check run is actively running
	pgm_name_fattr$=fattr(adxlocks$,"MENU_OPTION_ID")
	len_pgm_name_fattr=dec(pgm_name_fattr$(10,2))
	
	dim taskname$(len_pgm_name_fattr)
	taskname$(1)=callpoint!.getTableAttribute("ALID")

	while 1
		extract record(adxlocks_dev, key=firm_id$+taskname$, dom=*break)
		
		msg_id$="AP_CHKS_PRINTING"
		dim msg_tokens$[1]
		msg_opt$=""
		gosub disp_message
		if pos("PASSVALID"=msg_opt$)=0
			callpoint!.setStatus("EXIT")		
		endif

		break
	wend

rem --- Initializations
	callpoint!.setDevObject("reuse_check_num","")		

rem --- Set callback for ON_LIST_SELECT event from CHECK_ACCTS ListButton
	chkAcctCtl!=callpoint!.getControl("APR_CHECKS.CHECK_ACCTS")
	chkAcctCtl!.setCallback(BBjListButton.ON_LIST_SELECT,"custom_event")

[[APR_CHECKS.CHECK_NO.AVAL]]
rem --- Warn if this check number has been previously used
	check_no$=callpoint!.getUserInput()
	aptCheckHistory_dev=fnget_dev("APT_CHECKHISTORY")
	dim aptCheckHistory$:fnget_tpl$("APT_CHECKHISTORY")
	ap_type$=pad(callpoint!.getColumnData("APR_CHECKS.AP_TYPE"),len(aptCheckHistory.ap_type$))

	next_ap_type$=ap_type$
	read(aptCheckHistory_dev,key=firm_id$+next_ap_type$+check_no$,dom=*next)
	while 1
		readrecord(aptCheckHistory_dev,end=*break)aptCheckHistory$
		if aptCheckHistory.firm_id$<>firm_id$ then break
		callpoint!.setDevObject("reuse_check_num","")		
		if aptCheckHistory.ap_type$+aptCheckHistory.check_no$=next_ap_type$+check_no$ then
			rem --- This check number was previously used
			msg_id$="AP_CHECK_NUM_USED"
			dim msg_tokens$[1]
			msg_tokens$[1]=check_no$
			gosub disp_message
			if msg_opt$="C" then
				callpoint!.setStatus("ABORT")
				callpoint!.setDevObject("reuse_check_num","N")
			else
				callpoint!.setDevObject("reuse_check_num","Y")		
			endif
		else
			rem --- Must check all AP Types when ap_type is blank/empty
			if cvs(ap_type$,2)="" then
				aptCheckHistory_key$=key(aptCheckHistory_dev,end=*break)
				if pos(firm_id$=aptCheckHistory_key$)<>1 then break
				if pos(firm_id$+next_ap_type$=aptCheckHistory_key$)=1 then
					rem --- Skip ahead to next ap_type
					read(aptCheckHistory_dev,key=firm_id$+aptCheckHistory.ap_type$+$FF$,dom=*next)
				endif
				readrecord(aptCheckHistory_dev,end=*break)aptCheckHistory$
				if aptCheckHistory.firm_id$<>firm_id$ then break
				next_ap_type$=aptCheckHistory.ap_type$
				read(aptCheckHistory_dev,key=firm_id$+next_ap_type$+check_no$,dom=*continue)
			endif
		endif
		break
	wend

[[APR_CHECKS.PRNT_SIGNATURE.AVAL]]
rem --- Enable/disable signature_file
	prnt_signature$=callpoint!.getUserInput()
	if callpoint!.getDevObject("use_pay_auth") then
		rem --- Use Payment Authorization signature file(s)
		callpoint!.setColumnData("APR_CHECKS.SIGNATURE_FILE","",1)
		callpoint!.setColumnEnabled("APR_CHECKS.SIGNATURE_FILE",0)
	else
		if callpoint!.getDevObject("aps01_prnt_signature")="Y" then
			rem --- Use AP Parameters signature file
			callpoint!.setColumnData("APR_CHECKS.SIGNATURE_FILE",str(callpoint!.getDevObject("aps01_signature_file")),1)
			callpoint!.setColumnEnabled("APR_CHECKS.SIGNATURE_FILE",1)
		else
			rem --- Not using signature file(s)
			callpoint!.setColumnData("APR_CHECKS.SIGNATURE_FILE","",1)
			callpoint!.setColumnEnabled("APR_CHECKS.SIGNATURE_FILE",0)
		endif
	endif

[[APR_CHECKS.SIGNATURE_FILE.AVAL]]
rem --- Verify signature file exists
	signature_file$=callpoint!.getUserInput()
	sigFile!=new File(signature_file$)
	if ! sigFile!.exists() or sigFile!.isDirectory() then
		msg_id$="AD_FILE_NOT_FOUND"
		dim msg_tokens$[1]
		msg_tokens$[1]=signature_file$
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif

[[APR_CHECKS.VENDOR_ID.AVAL]]
rem "VENDOR INACTIVE - FEATURE"
vendor_id$ = callpoint!.getUserInput()
apm01_dev=fnget_dev("APM_VENDMAST")
apm01_tpl$=fnget_tpl$("APM_VENDMAST")
dim apm01a$:apm01_tpl$
apm01a_key$=firm_id$+vendor_id$
find record (apm01_dev,key=apm01a_key$,err=*break) apm01a$
if apm01a.vend_inactive$="Y" then
   call stbl("+DIR_PGM")+"adc_getmask.aon","VENDOR_ID","","","",m0$,0,vendor_size
   msg_id$="AP_VEND_INACTIVE"
   dim msg_tokens$[2]
   msg_tokens$[1]=fnmask$(apm01a.vendor_id$(1,vendor_size),m0$)
   msg_tokens$[2]=cvs(apm01a.vendor_name$,2)
   gosub disp_message
   callpoint!.setStatus("ACTIVATE")
endif

[[APR_CHECKS.VENDOR_ID.BINQ]]
rem --- Set filter_defs$[] to only show vendors of given AP Type

ap_type$=callpoint!.getColumnData("APR_CHECKS.AP_TYPE")

dim filter_defs$[2,2]
filter_defs$[0,0]="APM_VENDMAST.FIRM_ID"
filter_defs$[0,1]="='"+firm_id$+"'"
filter_defs$[0,2]="LOCK"

filter_defs$[1,0]="APM_VENDHIST.AP_TYPE"
filter_defs$[1,1]="='"+ap_type$+"'"
filter_defs$[1,2]="LOCK"


call STBL("+DIR_SYP")+"bax_query.bbj",
:		gui_dev, 
:		form!,
:		"AP_VEND_LK",
:		"DEFAULT",
:		table_chans$[all],
:		sel_key$,
:		filter_defs$[all]

if sel_key$<>""
	call stbl("+DIR_SYP")+"bac_key_template.bbj",
:		"APM_VENDMAST",
:		"PRIMARY",
:		apm_vend_key$,
:		table_chans$[all],
:		status$
	dim apm_vend_key$:apm_vend_key$
	apm_vend_key$=sel_key$
	callpoint!.setColumnData("APR_CHECKS.VENDOR_ID",apm_vend_key.vendor_id$,1)
endif	
callpoint!.setStatus("ACTIVATE-ABORT")

[[APR_CHECKS.<CUSTOM>]]
rem ==========================================================================
initCheckAccts: rem --- Initialize Checking Account ListButton for all selected invoices
rem ==========================================================================
	acctInvMap!=new HashMap()
	chkAcctList!=BBjAPI().makeVector()
	bnkAcctCdList!=BBjAPI().makeVector()
	nextChkLIst!=BBjAPI().makeVector()
	codeList!=BBjAPI().makeVector()
	if callpoint!.getDevObject("post_to_gl")="Y" then
		rem --- AP using GL
		ape04_dev=fnget_dev("APE_CHECKS")
		dim ape04a$:fnget_tpl$("APE_CHECKS")
		apt01_dev=fnget_dev("APT_INVOICEHDR")
		dim apt01a$:fnget_tpl$("APT_INVOICEHDR")
		apcDist_dev=fnget_dev("APC_DISTRIBUTION")
		dim apcDist$:fnget_tpl$("APC_DISTRIBUTION")
		glm05_dev=fnget_dev("GLM_BANKMASTER")
		dim glm05$:fnget_tpl$("GLM_BANKMASTER")
		adcBnkAcct_dev=fnget_dev("ADC_BANKACCTCODE")
		dim adcBnkAcct$:fnget_tpl$("ADC_BANKACCTCODE")

		read(ape04_dev,key=firm_id$,dom=*next)
		while 1
			readrecord(ape04_dev,end=*break)ape04a$
			if ape04a.firm_id$<>firm_id$ then break

			redim apt01a$
			ape01_key$=firm_id$+ape04a.ap_type$+ape04a.vendor_id$+ape04a.ap_inv_no$
			readrecord(apt01_dev,key=ape01_key$,dom=*next)apt01a$
			if cvs(apt01a.ap_dist_code$,2)<>"" then
				redim apcDist$
				readrecord(apcDist_dev,key=firm_id$+"B"+apt01a.ap_dist_code$,dom=*next)apcDist$
				if cvs(apcDist.gl_cash_acct$,2)<>"" then
					redim glm05$
					readrecord(glm05_dev,key=firm_id$+apcDist.gl_cash_acct$,dom=*next)glm05$
					if cvs(glm05.bnk_acct_cd$,2)<>"" then
						redim adcBnkAcct$
						readrecord(adcBnkAcct_dev,key=firm_id$+glm05.bnk_acct_cd$,dom=*next)adcBnkAcct$
						if adcBnkAcct.bnk_acct_type$="C" then
							if acctInvMap!.containsKey(glm05.bnk_acct_cd$)
								invVect!=acctInvMap!.get(glm05.bnk_acct_cd$)
							else
								invVect!=BBjAPI().makeVector()
								bnkAcctCdList!.addItem(glm05.bnk_acct_cd$)
								chkAcctList!.addItem(adcBnkAcct.acct_desc$)
								nextChkList!.addItem(adcBnkAcct.nxt_check_no$)
								codeList!.addItem("")
							endif
							invVect!.addItem(ape04a.ap_type$+ape04a.vendor_id$+ape04a.ap_inv_no$)
							acctInvMap!.put(glm05.bnk_acct_cd$,invVect!)
						endif
					endif
				endif
			endif
		wend
	else
		rem --- AP is not using GL
		adcBnkAcct_dev=fnget_dev("ADC_BANKACCTCODE")
		dim adcBnkAcct$:fnget_tpl$("ADC_BANKACCTCODE")
		read(adcBnkAcct_dev,key=firm_id$,dom=*next)
		while 1
			readrecord(adcBnkAcct_dev,end=*break)adcBnkAcct$
			if adcBnkAcct.firm_id$<>firm_id$ then break
			if adcBnkAcct.bnk_acct_type$="C" then
				bnkAcctCdList!.addItem(adcBnkAcct.bnk_acct_cd$)
				chkAcctList!.addItem(adcBnkAcct.acct_desc$)
				nextChkList!.addItem(adcBnkAcct.nxt_check_no$)
				codeList!.addItem("")
			endif
		wend
	endif
	callpoint!.setDevObject("acctInvMap",acctInvMap!)
	callpoint!.setDevObject("bnkAcctCdList",bnkAcctCdList!)
	callpoint!.setDevObject("nextCheckList",nextChkList!)

	chkAcctCtl!=callpoint!.getControl("APR_CHECKS.CHECK_ACCTS")
	chkAcctCtl!.removeAllItems()
	chkAcctCtl!.insertItems(0,chkAcctList!)
	chkAcctCtl!.selectIndex(0)
	ldat$=func.buildListButtonList(chkAcctList!,codeList!)
	callpoint!.setTableColumnAttribute("APR_CHECKS.CHECK_ACCTS","LDAT",ldat$)

	if chkAcctList!.size()>0 then
		if chkAcctList!.size()=1 then
			callpoint!.setColumnEnabled("APR_CHECKS.CHECK_ACCTS",0)
		else
			callpoint!.setColumnEnabled("APR_CHECKS.CHECK_ACCTS",1)
		endif

		rem --- Initialize CHECK_NO for the first Checking Account in ListButton
		callpoint!.setColumnData("APR_CHECKS.CHECK_NO",nextChkList!.getItem(0))

		rem --- Hold on to selected Bank Account Code, i.e. Checking Account
		bnkAcctCd$=bnkAcctCdList!.getItem(0)
		callpoint!.setDevObject("bnkAcctCd",bnkAcctCd$)
	else
		callpoint!.setColumnEnabled("APR_CHECKS.CHECK_ACCTS",0)

		rem --- Clear CHECK_NO
		callpoint!.setColumnData("APR_CHECKS.CHECK_NO","")

		rem --- Hold on to selected Bank Account Code, i.e. Checking Account
		callpoint!.setDevObject("bnkAcctCd","")
	endif
	callpoint!.setStatus("REFRESH")
return

disable_fields:
rem --- used to disable/enable controls depending on parameter settings
rem --- send in control to toggle (format "ALIAS.CONTROL_NAME"), and D or space to disable/enable
	wctl$=str(num(callpoint!.getTableColumnAttribute(ctl_name$,"CTLI")):"00000")
	wmap$=callpoint!.getAbleMap()
	wpos=pos(wctl$=wmap$,8)
	wmap$(wpos+6,1)=ctl_stat$
	callpoint!.setAbleMap(wmap$)
	callpoint!.setStatus("ABLEMAP-REFRESH")
return

#include [+ADDON_LIB]std_missing_params.aon
#include [+ADDON_LIB]std_functions.aon



