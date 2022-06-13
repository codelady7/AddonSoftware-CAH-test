[[ARS_CC_CUSTSVC.ADIS]]
rem --- if accepting credit card payments for this cash rec code, populate list of supported gateways based on the interface type

	interface_tp$=callpoint!.getColumnData("ARS_CC_CUSTSVC.INTERFACE_TP")
	gosub get_gateways
		
	callpoint!.setStatus("REFRESH")


	gateway$=cvs(callpoint!.getColumnData("ARS_CC_CUSTSVC.GATEWAY_ID"),3)
	if gateway$<>""
		callpoint!.setOptionEnabled("GTWY",1)
	else
		callpoint!.setOptionEnabled("GTWY",0)
	endif

[[ARS_CC_CUSTSVC.AOPT-GTWY]]
rem --- launch config form for selected gateway

	gateway$=callpoint!.getColumnData("ARS_CC_CUSTSVC.GATEWAY_ID")

	dim dflt_data$[1,1]
	dflt_data$[0,0]="FIRM_ID"
	dflt_data$[0,1]=firm_id$
	dflt_data$[1,0]="GATEWAY_ID"
	dflt_data$[1,1]=gateway$

	key_pfx$=firm_id$+gateway$

	call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:		"ARS_GATEWAYHDR",
:		stbl("+USER_ID"),
:		"",
:		key_pfx$,
:		table_chans$[all],
:		"",
:		dflt_data$[all]

[[ARS_CC_CUSTSVC.AREC]]
rem --- disable gateway button

	callpoint!.setOptionEnabled("GTWY",0)

[[ARS_CC_CUSTSVC.BSHO]]
rem --- use

	use ::ado_func.src::func
	use ::sys/prog/bao_encryptor.bbj::Encryptor

rem --- open tables

	num_files=5
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="ARS_GATEWAYHDR",open_opts$[1]="OTA"
	open_tables$[2]="ARS_PARAMS",open_opts$[2]="OTA"
	open_tables$[3]="ADM_PROCMASTER",open_opts$[3]="OTA"
	open_tables$[4]="ADM_PROCDETAIL",open_opts$[4]="OTA"
	open_tables$[5]="ARS_GATEWAYDET",open_opts$[5]="OTA"
	gosub open_tables

	ars_params=num(open_chans$[2])
	adm_procmaster=num(open_chans$[3])
	adm_procdetail=num(open_chans$[4])

	dim ars_params$:open_tpls$[2]
	dim adm_procmaster$:open_tpls$[3]
	dim adm_procdetail$:open_tpls$[4]

rem --- enable/disable deposit description based on whether using bank rec or not
	read record(ars_params,key=firm_id$+"AR00",err=std_missing_params)ars_params$
	callpoint!.setColumnEnabled("ARS_CC_CUSTSVC.DEPOSIT_DESC",iff(ars_params.br_interface$="Y",1,-1))

rem --- get process_id for Cash Receipts to see if batching is turned on; enable/disable batch description accordingly
	proc_key_val$=firm_id$+pad("ARE_CASHHDR",len(adm_procdetail.dd_table_alias$))
	read record (adm_procdetail,key=proc_key_val$,knum="AO_TABLE_PROCESS",dom=*next)
	while 1
		k$=key(adm_procdetail,end=*break)
		if pos(proc_key_val$=k$)<>1 break
		readrecord(adm_procdetail,end=*break)adm_procdetail$
		proc_id$=adm_procdetail.process_id$
		break
	wend
	read record (adm_procmaster,key=firm_id$+proc_id$,dom=*next)adm_procmaster$
	callpoint!.setColumnEnabled("ARS_CC_CUSTSVC.BATCH_DESC",iff(adm_procmaster.batch_entry$="Y",1,-1))

[[ARS_CC_CUSTSVC.GATEWAY_ID.AVAL]]
rem --- check config for specified gateway and warn if not set up

	ars_gatewaydet=fnget_dev("ARS_GATEWAYDET")
	dim ars_gatewaydet$:fnget_tpl$("ARS_GATEWAYDET")

	encryptor! = new Encryptor()
	config_id$ = "GATEWAY_AUTH"
	encryptor!.setConfiguration(config_id$)

	gateway_id$=callpoint!.getUserInput()

	read(ars_gatewaydet,key=firm_id$+gateway_id$,knum=0,dom=*next)

	while 1
		readrecord(ars_gatewaydet,end=*break)ars_gatewaydet$
		if pos(firm_id$+gateway_id$=ars_gatewaydet$)<>1 then break
		cfg_value$=encryptor!.decryptData(cvs(ars_gatewaydet.config_value$,3))
		if pos("token>"=cfg_value$) or cvs(cfg_value$,3)=""
			dim msg_tokens$[1]
			msg_tokens$[0]=Translate!.getTranslation("AON_INVALID_GATEWAY_CONFIG","One or more configuration values for the payment gateway are invalid.",1)+$0A$+"("+gateway_id$+")"
			msg_id$="GENERIC_WARN"
			gosub disp_message
		endif
	wend

[[ARS_CC_CUSTSVC.INTERFACE_TP.AVAL]]
rem --- populate list of supported gateways based on the interface type

	interface_tp$=callpoint!.getUserInput()
	gosub get_gateways

[[ARS_CC_CUSTSVC.USE_CUSTSVC_CC.AVAL]]
 if callpoint!.getUserInput()="Y"	
	cashcode_dev=fnget_dev("ARC_CASHCODE")
	dim cashcode_tpl$:fnget_tpl$("ARC_CASHCODE")


	cash_rec_cd$=callpoint!.getColumnData("ARS_CC_CUSTSVC.CASH_REC_CD")
	findrecord(cashcode_dev,key=firm_id$+"C"+cash_rec_cd$,dom=*next)cashcode_tpl$

	if cashcode_tpl.code_inactive$ = "Y" 
		callpoint!.setColumnData("ARS_CC_CUSTSVC.USE_CUSTSVC_CC","N",1)
		
		msg_id$="AR_CODE_INACTIVE"
		gosub disp_message
		
		break
	endif
endif

[[ARS_CC_CUSTSVC.<CUSTOM>]]
rem ============================================================
get_gateways:rem --- load up listbutton with supported gateways for given or selected interface type
rem --- in: interface_tp$
rem ============================================================

	ars_gatewayhdr=fnget_dev("ARS_GATEWAYHDR")
	dim ars_gatewayhdr$:fnget_tpl$("ARS_GATEWAYHDR")

	column$="ARS_CC_CUSTSVC.GATEWAY_ID"

	ldat$=""

	codeVect!=BBjAPI().makeVector()
	descVect!=BBjAPI().makeVector()

	read(ars_gatewayhdr,key=firm_id$,dom=*next)
	while 1
		readrecord(ars_gatewayhdr,end=*break)ars_gatewayhdr$
		if pos(firm_id$=ars_gatewayhdr$)<>1 then break
		if pos(ars_gatewayhdr.interface_tp$=interface_tp$+"B")
			codeVect!.add(ars_gatewayhdr.gateway_id$)
			descVect!.add(ars_gatewayhdr.description$)
		endif
	wend

	ldat$=func.buildListButtonList(descVect!,codeVect!)
	callpoint!.setTableColumnAttribute(column$,"LDAT",ldat$)
	c!=callpoint!.getControl(column$)
	c!.removeAllItems()
	c!.insertItems(0,descVect!)

	return

#include [+ADDON_LIB]std_functions.aon
#include [+ADDON_LIB]std_missing_params.aon



