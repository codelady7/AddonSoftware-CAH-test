[[ARS_CC_CUSTPMT.ADIS]]
rem --- if accepting credit card payments for this cash rec code, populate list of supported gateways based on the interface type

	interface_tp$=callpoint!.getColumnData("ARS_CC_CUSTPMT.INTERFACE_TP")
	gosub get_gateways
		
	callpoint!.setStatus("REFRESH")


	gateway$=cvs(callpoint!.getColumnData("ARS_CC_CUSTPMT.GATEWAY_ID"),3)
	if gateway$<>""
		callpoint!.setOptionEnabled("GTWY",1)
	else
		callpoint!.setOptionEnabled("GTWY",0)
	endif

[[ARS_CC_CUSTPMT.ALLOW_CUST_CC.AVAL]]
rem --- cannot set allow_cust_cc if any other record has it set
rem --- currently the customer cc payment form (are_cc_csthst) only supports one cash rec code, therefore one ars_cc_custpmt record

	if callpoint!.getUserInput()="Y"
		ars_cc_custpmt=fnget_dev("@ARS_CC_CUSTPMT")
		dim ars_cc_custpmt$:fnget_tpl$("@ARS_CC_CUSTPMT")

		check_count=0
		check_codes$=""

		read(ars_cc_custpmt,key=firm_id$,dom=*next)

		while 1
			readrecord(ars_cc_custpmt,end=*break)ars_cc_custpmt$
			if ars_cc_custpmt.firm_id$<>firm_id$ then break
			if ars_cc_custpmt.cash_rec_cd$<>callpoint!.getColumnData("ARS_CC_CUSTPMT.CASH_REC_CD") and ars_cc_custpmt.allow_cust_cc$="Y"
				check_count=check_count+1
				check_codes$=check_codes$+ars_cc_custpmt.cash_rec_cd$+","
			endif
		wend

		if check_count >= 1
			msg_id$="GENERIC_WARN"
			dim msg_tokens$[1]
			msg_tokens$[1]=Translate!.getTranslation("AON_ONLY_ONE_ARS_CC_CUSTPMT_ALLOWED","A different Cash Receipt Code has already been designated for customer credit card payments."+$0A$+"Delete the code listed below, or uncheck its 'Accept Credit Card Payments' box.",1)+ $0A$+"Code: "+check_codes$(1,len(check_codes$)-1)
			gosub disp_message
			callpoint!.setStatus("ABORT")
		endif

		cashcode_dev=fnget_dev("ARC_CASHCODE")
		dim cashcode_tpl$:fnget_tpl$("ARC_CASHCODE")


		cash_rec_cd$=callpoint!.getColumnData("ARS_CC_CUSTPMT.CASH_REC_CD")
		findrecord(cashcode_dev,key=firm_id$+"C"+cash_rec_cd$,dom=*next)cashcode_tpl$

		if cashcode_tpl.code_inactive$ = "Y" 
			callpoint!.setColumnData("ARS_CC_CUSTPMT.ALLOW_CUST_CC","N",1)
		
			msg_id$="AR_CODE_INACTIVE"
			gosub disp_message
		
			break
		endif

	endif

[[ARS_CC_CUSTPMT.ALLOW_CUST_CC.BINP]]
rem --- Enable Configure Web App additional option when in edit mode
	if callpoint!.isEditMode() then callpoint!.setOptionEnabled("WEBA",1)

[[ARS_CC_CUSTPMT.AOPT-GTWY]]
rem --- launch config form for selected gateway

	gateway$=callpoint!.getColumnData("ARS_CC_CUSTPMT.GATEWAY_ID")

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

[[ARS_CC_CUSTPMT.AOPT-WEBA]]
rem --- Get database name, Barista home directory, etc. for this installation
	dbName$=stbl("+DBNAME_API")
	if dbName$="AddonSoftware" then
		sscpName$="addon"
	else
		sscpName$=cvs(dbName$,11)
	endif
	barDir$=dsk("")+dir("")

rem --- Get location of this Addon installation
	ddm_systems=fnget_dev("DDM_SYSTEMS")
	dim ddm_systems$:fnget_tpl$("DDM_SYSTEMS")
	readrecord(ddm_systems,key=pad("ADDON",16),knum="SYSTEM_ID",err=*next)ddm_systems$
	aonDir$=ddm_systems.mount_dir$

rem --- Get current user credentials using AdminAPI
	user_id$=stbl("+USER_ID",err=*next)
	thisAdmin!=BBjAPI().getGroupNamespace().getValue("+bar_admin_"+cvs(user_id$,11),err=*next)

	if thisAdmin!=null() then
		sysGUI!=BBjAPI().getSysGui()
		call stbl("+DIR_SYP")+"bac_em_login.bbj",sysGUI!,null(),thisAdmin!,status$
	endif

rem --- Get gateway server
	gatewayServer$=""
	ars_gatewaydet=fnget_dev("ARS_GATEWAYDET")
	dim ars_gatewaydet$:fnget_tpl$("ARS_GATEWAYDET")
	gateway_id$=callpoint!.getColumnData("ARS_CC_CUSTPMT.GATEWAY_ID")
	read(ars_gatewaydet,key=firm_id$+gateway_id$,knum=0,dom=*next)
	while 1
		readrecord(ars_gatewaydet,end=*break)ars_gatewaydet$
		if pos(firm_id$+gateway_id$=ars_gatewaydet$)<>1 then continue
		if cvs(ars_gatewaydet.config_attr$,2)<>"server" then continue
		encryptor! = new Encryptor()
		config_id$ = "GATEWAY_AUTH"
		encryptor!.setConfiguration(config_id$)
		gatewayServer$=encryptor!.decryptData(cvs(ars_gatewaydet.config_value$,3))
		break
	wend

rem --- Configure CreditCardLogin web app
	appName$="CreditCardLogin_"+cvs(dbName$,11)+"_"+firm_id$
	program$=(new File(aonDir$+"/web/aro_CCLoginManager.aon")).getAbsolutePath()
	css$=(new File(aonDir$+"/htdocs/CCLogin.css")).getAbsolutePath()
	gosub configureWebApp

rem --- CreditCardConfirmation web app
	appName$="CreditCardConfirmation_"+cvs(dbName$,11)+"_"+firm_id$
	program$=(new File(aonDir$+"/web/aro_CCRegistrationConfirmationManager.aon")).getAbsolutePath()
	css$=(new File(aonDir$+"/htdocs/CCLogin.css")).getAbsolutePath()
	gosub configureWebApp

rem --- CreditCardPassword web app
	appName$="CreditCardPassword_"+cvs(dbName$,11)+"_"+firm_id$
	program$=(new File(aonDir$+"/web/aro_CCForgotPasswordManager.aon")).getAbsolutePath()
	css$=(new File(aonDir$+"/htdocs/CCLogin.css")).getAbsolutePath()
	gosub configureWebApp

rem --- Initialize Payment URL
	field$="ARS_CC_CUSTPMT.PAYMENT_URL"
	default_URL$="https://"+gatewayServer$+"/"+cvs(dbName$,11)+"/apps/CreditCardLogin_"+ cvs(dbName$,11) +"_"+firm_id$
	gosub configureURL

rem --- Initialize Registration URL
	field$="ARS_CC_CUSTPMT.REGISTER_URL"
	default_URL$="https://"+gatewayServer$+"/"+cvs(dbName$,11)+"/apps/CreditCardConfirmation_"+ cvs(dbName$,11) +"_"+firm_id$
	gosub configureURL

rem --- Initialize Password Reset URL
	field$="ARS_CC_CUSTPMT.PASSWORD_URL"
	default_URL$="https://"+gatewayServer$+"/"+cvs(dbName$,11)+"/apps/CreditCardPassword_"+ cvs(dbName$,11) +"_"+firm_id$
	gosub configureURL

rem --- Task completed
	aopts$=callpoint!.getTableAttribute("AOPT")
	webaAopt$=aopts$(1,pos("WEBAM;"=aopts$)-1)
	webaAopt$=cvs(webaAopt$(pos(";"=webaAopt$,-1)+1),3)
	msg_id$="AD_TASK_COMPLETED"
	dim msg_tokens$[1]
	msg_tokens$[1]="'"+webaAopt$+"' "
	gosub disp_message

[[ARS_CC_CUSTPMT.AREC]]
rem --- Disable additional options
	callpoint!.setOptionEnabled("GTWY",0)
	callpoint!.setOptionEnabled("WEBA",0)

[[ARS_CC_CUSTPMT.BSHO]]
rem --- use

	use java.io.File

	use com.basis.api.admin.BBjAdminAppDeploymentApplication
	use com.basis.api.admin.BBjAdminAppDeploymentResource

	use ::ado_func.src::func
	use ::aro_CCUtil.aon::CCUtil
	use ::sys/prog/bao_encryptor.bbj::Encryptor

rem --- open tables

	num_files=7
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="ARS_GATEWAYHDR",open_opts$[1]="OTA"
	open_tables$[2]="ARS_PARAMS",open_opts$[2]="OTA"
	open_tables$[3]="ADM_PROCMASTER",open_opts$[3]="OTA"
	open_tables$[4]="ADM_PROCDETAIL",open_opts$[4]="OTA"
	open_tables$[5]="ARS_CC_CUSTPMT",open_opts$[5]="OTA@";rem separate open for allow_cust_cc aval
	open_tables$[6]="ARS_GATEWAYDET",open_opts$[6]="OTA"
	open_tables$[7]="DDM_SYSTEMS",open_opts$[7]="OTA"
	gosub open_tables

	ars_params=num(open_chans$[2])
	adm_procmaster=num(open_chans$[3])
	adm_procdetail=num(open_chans$[4])

	dim ars_params$:open_tpls$[2]
	dim adm_procmaster$:open_tpls$[3]
	dim adm_procdetail$:open_tpls$[4]

rem --- enable/disable deposit description based on whether using bank rec or not
	read record(ars_params,key=firm_id$+"AR00",err=std_missing_params)ars_params$
	callpoint!.setColumnEnabled("ARS_CC_CUSTPMT.DEPOSIT_DESC",iff(ars_params.br_interface$="Y",1,-1))

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
	callpoint!.setColumnEnabled("ARS_CC_CUSTPMT.BATCH_DESC",iff(adm_procmaster.batch_entry$="Y",1,-1))

[[ARS_CC_CUSTPMT.DEPOSIT_DESC.BINP]]
rem --- Enable Configure Web App additional option when in edit mode
	if callpoint!.isEditMode() then callpoint!.setOptionEnabled("WEBA",1)

[[ARS_CC_CUSTPMT.GATEWAY_ID.AVAL]]
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
		if pos(firm_id$+gateway_id$=ars_gatewaydet$)<>1 then continue
		cfg_value$=encryptor!.decryptData(cvs(ars_gatewaydet.config_value$,3))
		if pos("token>"=cfg_value$) or cvs(cfg_value$,3)=""
			dim msg_tokens$[1]
			msg_tokens$[0]=Translate!.getTranslation("AON_INVALID_GATEWAY_CONFIG","One or more configuration values for the payment gateway are invalid.",1)+$0A$+"("+gateway_id$+")"
			msg_id$="GENERIC_WARN"
			gosub disp_message
			break
		endif
	wend

[[ARS_CC_CUSTPMT.GATEWAY_ID.BINP]]
rem --- Enable Configure Web App additional option when in edit mode
	if callpoint!.isEditMode() then callpoint!.setOptionEnabled("WEBA",1)

[[ARS_CC_CUSTPMT.INTERFACE_TP.AVAL]]
rem --- populate list of supported gateways based on the interface type

	interface_tp$=callpoint!.getUserInput()
	if cvs(interface_tp$,3)<>"" and interface_tp$<>callpoint!.getColumnData("ARS_CC_CUSTPMT.INTERFACE_TP")
		gosub get_gateways
	endif

[[ARS_CC_CUSTPMT.INTERFACE_TP.BINP]]
rem --- Enable Configure Web App additional option when in edit mode
	if callpoint!.isEditMode() then callpoint!.setOptionEnabled("WEBA",1)

[[ARS_CC_CUSTPMT.PAYMENT_URL.BINP]]
rem --- Enable Configure Web App additional option when in edit mode
	if callpoint!.isEditMode() then callpoint!.setOptionEnabled("WEBA",1)

[[ARS_CC_CUSTPMT.REGISTER_URL.BINP]]
rem --- Enable Configure Web App additional option when in edit mode
	if callpoint!.isEditMode() then callpoint!.setOptionEnabled("WEBA",1)

[[ARS_CC_CUSTPMT.<CUSTOM>]]
rem ============================================================
get_gateways:rem --- load up listbutton with supported gateways for given or selected interface type
rem --- in: interface_tp$
rem ============================================================

	ars_gatewayhdr=fnget_dev("ARS_GATEWAYHDR")
	dim ars_gatewayhdr$:fnget_tpl$("ARS_GATEWAYHDR")

	column$="ARS_CC_CUSTPMT.GATEWAY_ID"

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

rem ============================================================
configureWebApp: rem --- Configure web apps
rem --- in: appName$
rem --- in: program$
rem --- in: css$
rem --- in: sscpName$
rem ============================================================

	use ::aro_CCExpiredRequestReaper.aon::CCExpiredRequestReaper

	rem --- Use Admin API (BBjAdminBase) instead of BBjAPI() methods
	adminBase!=CCUtil.getAdmin()
	remoteConfig!=adminBase!.getRemoteConfiguration()
	remoteApps! = remoteConfig!.getApplications()
	foundApplication=0
	appsIter!=remoteApps!.iterator()
	while appsIter!.hasNext()
		thisApp!=appsIter!.next()
		if thisApp!.getString(BBjAdminAppDeploymentApplication.NAME)=appName$ then
			foundApplication=1
			break
		endif
	wend
	if foundApplication then
		rem --- Warn that web app already exists
		msg_id$="AD_WEBAPP_EXISTS_1"
		dim msg_tokens$[1]
		msg_tokens$[1]=appName$
		gosub disp_message
		if msg_opt$="Y" then
			rem --- Make sure it's okay to replace existing web app with defaults
			msg_id$="AD_WEBAPP_EXISTS_2"
			dim msg_tokens$[1]
			msg_tokens$[1]=appName$
			gosub disp_message
			if msg_opt$="Y" then
				doWebApp=1
			else
				doWebApp=0
			endif
		else
			doWebApp=0
		endif
	else
		doWebApp=1
	endif

	if doWebApp then
		newApp!=remoteConfig!.createApplication()
		newApp!.setString(BBjAdminAppDeploymentApplication.NAME,appName$)
		newApp!.setString(BBjAdminAppDeploymentApplication.PROGRAM,"sys/prog/bax_launch_task.bbj")
		newApp!.setString(BBjAdminAppDeploymentApplication.CONFIG_FILE,barDir$+stbl("+FILE_CFG"))
		newApp!.setString(BBjAdminAppDeploymentApplication.WORKING_DIRECTORY,barDir$)
		newApp!.setString(BBjAdminAppDeploymentApplication.CLASSPATH,sscpName$)

		progArgs! = newApp!.getArguments()
		progArgs!.add("-yA")
		progArgs!.add("-tDDM_TABLES")
		progArgs!.add("-a"+program$+" -f"+firm_id$)
		progArgs!.add("-u[APP1]")
		progArgs!.add("-p[APP2]")

		newApp!.setBoolean(BBjAdminAppDeploymentApplication.QUIET,1)
		newApp!.setBoolean(BBjAdminAppDeploymentApplication.BUI_ENABLED,1)
		newApp!.setBoolean(BBjAdminAppDeploymentApplication.EXE_ENABLED,0)
		newApp!.setBoolean(BBjAdminAppDeploymentApplication.SHOW_BROWSER_WARNING_USE_DEFAULT,0)
		newApp!.setBoolean(BBjAdminAppDeploymentApplication.SHOW_CONFIRM_CLOSE_DIALOG_USE_DEFAULT ,0)
		newApp!.setBoolean(BBjAdminAppDeploymentApplication.MANAGE_BROWSER_HISTORY_USE_DEFAULT,0)
		newApp!.setBoolean(BBjAdminAppDeploymentApplication.DISALLOW_CONSOLE_USE_DEFAULT,0)
		newApp!.setBoolean(BBjAdminAppDeploymentApplication.DISALLOW_CONSOLE,1)
		newApp!.setBoolean(BBjAdminAppDeploymentApplication.DEVELOPMENT_MODE_USE_DEFAULT,0)
		newApp!.setBoolean(BBjAdminAppDeploymentApplication.OMIT_BASIS_CSS_USE_DEFAULT,0)

		resourceList!=remoteConfig!.getResources()
		foundResource=0
		resourceIter!=resourceList!.iterator()
		while resourceIter!.hasNext()
			resource!=resourceIter!.next()
			if resource!.getString(BBjAdminAppDeploymentResource.SOURCE_FILE_NAME)=css$ then
				foundResource=1
				break
			endif
		wend
		if !foundResource then
			rem --- Create a resource entry for a CSS
			resource!=remoteConfig!.createResource()
			resource!.setString(BBjAdminAppDeploymentResource.SOURCE_FILE_NAME,css$)
			remoteConfig!.getResources().add(resource!)
			remoteConfig!.commit()
		endif
		rem --- Set the CSS to the resource we created above
		newApp!.setString(BBjAdminAppDeploymentApplication.CSS_RESOURCE_ID,resource!.getString(BBjAdminAppDeploymentResource.RESOURCE_ID))

		newApp!.setString(BBjAdminAppDeploymentApplication.CONTEXT,cvs(dbName$,11))
		newApp!.commit()

		REM Schedule the reaper process to get rid of old user registrations
		declare CCExpiredRequestReaper reaper!
		reaper!=new CCExpiredRequestReaper() 
		reaper!.scheduleReaperProcess() 
		
	endif

	return


rem ============================================================
configureURL: rem --- Configure URLs
rem --- in: field$
rem --- in: default_URL$
rem ============================================================

	url$=cvs(callpoint!.getColumnData(field$),2)
	if url$="" then
    		doURL=1
	else
		if url$<>default_URL$ then
   		 	rem --- Warn that Payment URL already exists
			msg_id$="AD_URL_EXISTS"
    			dim msg_tokens$[1]
   			msg_tokens$[1]="'"+callpoint!.getTableColumnAttribute(field$,"LABL")+"'"
   			gosub disp_message
			if msg_opt$="Y" then
				doURL=1
			else
				doURL=0
			endif
		else
			doURL=0
		endif
	endif
	if doURL then
		callpoint!.setColumnData(field$,default_URL$,1)
		callpoint!.setStatus("MODIFIED")
	endif

	return

#include [+ADDON_LIB]std_functions.aon
#include [+ADDON_LIB]std_missing_params.aon



