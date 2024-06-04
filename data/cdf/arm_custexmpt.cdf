[[ARM_CUSTEXMPT.ADIS]]
rem --- Show ENTITY_USE_CD name
	salesTax!=callpoint!.getDevObject("salesTax")
	if salesTax!<>null() then
		entity_use_cd_desc!=callpoint!.getDevObject("entity_use_cd_desc")
		entityUseCd$=cvs(callpoint!.getColumnData("ARM_CUSTEXMPT.ENTITY_USE_CD"),2)
		if entityUseCd$<>"" then
			salesTax!=callpoint!.getDevObject("salesTax")
			success=0
			name$=salesTax!.getEntityUseCdName(entityUseCd$,err=*next); success=1
			if success then
				if name$<>"" then
					rem --- Good code entered
					entity_use_cd_desc!.setText(name$)
				else
					rem --- Bad code entered
					msg_id$="AR_BAD_ENTITY_CD"
					dim msg_tokens$[1]
					msg_tokens$[1]=entityUseCd$
					gosub disp_message

					entity_use_cd_desc!.setText("?????")
				endif
			else
				rem --- AvaTax call error
				entity_use_cd_desc!.setText("?????")
			endif
		else
			rem --- No code entered, so clear description.
			entity_use_cd_desc!.setText("")
		endif
	endif

[[ARM_CUSTEXMPT.AREC]]
rem --- Clear TAX_SVC_CD description
	salesTax!=callpoint!.getDevObject("salesTax")
	if salesTax!<>null() then
		entity_use_cd_desc!=callpoint!.getDevObject("entity_use_cd_desc")
		entity_use_cd_desc!.setText("")
	endif

[[ARM_CUSTEXMPT.ASHO]]
rem --- Disable ENTITY_USE_CD when OP is not installed
	callpoint!.setDevObject("salesTax",null())
	if callpoint!.getDevObject("op")<>"Y" then
		callpoint!.setColumnEnabled("ARM_CUSTEXMPT.ENTITY_USE_CD",-1)
	else
		rem --- Disable ENTITY_USE_CD when OP is not using a Sales Tax Service
		ops_params_dev=fnget_dev("OPS_PARAMS")
		dim ops_params$:fnget_tpl$("OPS_PARAMS")
		find record (ops_params_dev,key=firm_id$+"AR00",err=std_missing_params)ops_params$
		if cvs(ops_params.sls_tax_intrface$,2)="" then
			callpoint!.setColumnEnabled("ARM_CUSTEXMPT.ENTITY_USE_CD",-1)
		else
			rem --- Get connection to Sales Tax Service
			salesTax!=new AvaTaxInterface(firm_id$)
			if salesTax!.connectClient(Form!,err=connectErr) then
				callpoint!.setDevObject("salesTax",salesTax!)
				callpoint!.setColumnEnabled("ARM_CUSTEXMPT.ENTITY_USE_CD",1)
			else
				callpoint!.setColumnEnabled("ARM_CUSTEXMPT.ENTITY_USE_CD",0)
				salesTax!.close()
			endif
		endif
	endif

	break

connectErr:
	callpoint!.setColumnEnabled("ARM_CUSTEXMPT.ENTITY_USE_CD",0)
	if salesTax!<>null() then salesTax!.close()

	break

[[ARM_CUSTEXMPT.BEND]]
rem --- Close connection to Sales Tax Service
	salesTax!=callpoint!.getDevObject("salesTax")
	if salesTax!<>null() then
		salesTax!.close()
	endif

[[ARM_CUSTEXMPT.BSHO]]
rem --- Inits
	use ::ado_util.src::util
	use ::opo_AvaTaxInterface.aon::AvaTaxInterface

rem --- Is Sales Order Processing installed?
	call dir_pgm1$+"adc_application.aon","OP",info$[all]
	op$=info$[20]
	callpoint!.setDevObject("op",op$)

rem --- Open/Lock files

	if op$="Y" then
		files=2,begfile=1,endfile=files
		dim files$[files],options$[files],chans$[files],templates$[files]
		files$[1]="OPS_PARAMS",options$[1]="OTA"
		files$[2]="ARM_ENTITYUSE",options$[2]="OTA"
		call dir_pgm$+"bac_open_tables.bbj",begfile,endfile,files$[all],options$[all],
:                                 chans$[all],templates$[all],table_chans$[all],batch,status$
		if status$<>"" then
			remove_process_bar:
			bbjAPI!=bbjAPI()
			rdFuncSpace!=bbjAPI!.getGroupNamespace()
			rdFuncSpace!.setValue("+build_task","OFF")
			release
		endif

		rem --- Add static label for displaying ENTITY_USE_CD description
		entity_use_cd!=fnget_control!("ARM_CUSTEXMPT.ENTITY_USE_CD")
		entity_use_cd_x=entity_use_cd!.getX()
		entity_use_cd_y=entity_use_cd!.getY()
		entity_use_cd_height=entity_use_cd!.getHeight()
		entity_use_cd_width=entity_use_cd!.getWidth()
		nxt_ctlID=util.getNextControlID()
		entity_use_cd_desc!=Form!.addStaticText(nxt_ctlID,entity_use_cd_x+entity_use_cd_width+5,entity_use_cd_y+3,200,entity_use_cd_height-3,"")
		callpoint!.setDevObject("entity_use_cd_desc",entity_use_cd_desc!)
	endif

rem --- Remove “Manual Ship To (M)” from SHIPTO_TYPE ListButton
	shipToType!=callpoint!.getControl("ARM_CUSTEXMPT.SHIPTO_TYPE")
	items!=shipToType!.getAllItems()
	for i=0 to items!.size()-1
		item$=cvs(items!.getItem(i),3)
		if item$(len(item$)-2)="(M)" then
			shipToType!.removeItemAt(i)
			break
		endif
	next i

[[ARM_CUSTEXMPT.ENTITY_USE_CD.AVAL]]
rem --- Validate ENTITY_USE_CD
	entityUseCd$=cvs(callpoint!.getUserInput(),2)
	priorEntityUseCd$=cvs(callpoint!.getColumnData("ARM_CUSTEXMPT.ENTITY_USE_CD"),2)
	if entityUseCd$<>priorEntityUseCd$ then
		entity_use_cd_desc!=callpoint!.getDevObject("entity_use_cd_desc")
		if entityUseCd$<>"" then
			salesTax!=callpoint!.getDevObject("salesTax")
			success=0
			name$=salesTax!.getEntityUseCdName(entityUseCd$,err=*next); success=1
			if success then
				if name$="" then
					rem --- Check for custom Entity Use Code
					arm_entityUse_dev=fnget_dev("ARM_ENTITYUSE")
					dim arm_entityUse$:fnget_tpl$("ARM_ENTITYUSE")
					arm_entityUse.entity_use_cd$=entityUseCd$
					findrecord(arm_entityUse_dev,key=firm_id$+arm_entityUse.entity_use_cd$,dom=*next)arm_entityUse$
					name$=cvs(arm_entityUse.name$,2)
				endif
				if name$<>"" then
					rem --- Good code entered
					entity_use_cd_desc!.setText(name$)
				else
					rem --- Bad code entered
					msg_id$="AR_BAD_ENTITY_CD"
					dim msg_tokens$[1]
					msg_tokens$[1]=entityUseCd$
					gosub disp_message

					callpoint!.setColumnData("ARM_CUSTEXMPT.ENTITY_USE_CD",priorEntityUseCd$,1)
					callpoint!.setStatus("ABORT")
				endif
			else
				rem --- AvaTax call error
				callpoint!.setColumnData("ARM_CUSTEXMPT.ENTITY_USE_CD",priorEntityUseCd$,1)
				callpoint!.setStatus("ABORT")
			endif
		else
			rem --- No code entered, so clear description.
			entity_use_cd_desc!.setText("")
		endif
	endif

[[ARM_CUSTEXMPT.SHIPTO_NO.AVAL]]
rem --- Don't allow inactive code
	armCustShip_dev=fnget_dev("ARM_CUSTSHIP")
	dim armCustShip$:fnget_tpl$("ARM_CUSTSHIP")
	shipto_no$=callpoint!.getUserInput()
	customer_id$=callpoint!.getColumnData("ARM_CUSTEXMPT.CUSTOMER_ID")
	read record(armCustShip_dev,key=firm_id$+customer_id$+shipto_no$,dom=*next)armCustShip$
	if armCustShip.code_inactive$ = "Y"
		msg_id$="AD_CODE_INACTIVE"
		dim msg_tokens$[2]
		msg_tokens$[1]=cvs(armCustShip.shipto_no$,3)
		msg_tokens$[2]=cvs(armCustShip.city$,3)
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif

[[ARM_CUSTEXMPT.SHIPTO_TYPE.AVAL]]
rem ---Disable and clear SHIPTO_NO when SHIPTO_TYPE=B (Bill To)
	shipto_type$=callpoint!.getUserInput()
	if shipto_type$="B" then
		callpoint!.setColumnEnabled("ARM_CUSTEXMPT.SHIPTO_NO",0)
		callpoint!.setColumnData("ARM_CUSTEXMPT.SHIPTO_NO","",1)
	else
		callpoint!.setColumnEnabled("ARM_CUSTEXMPT.SHIPTO_NO",1)
	endif

[[ARM_CUSTEXMPT.<CUSTOM>]]
rem #include fnget_control.src
	def fnget_control!(ctl_name$)
	ctlContext=num(callpoint!.getTableColumnAttribute(ctl_name$,"CTLC"))
	ctlID=num(callpoint!.getTableColumnAttribute(ctl_name$,"CTLI"))
	get_control!=SysGUI!.getWindow(ctlContext).getControl(ctlID)
	return get_control!
	fnend
rem #endinclude fnget_control.src

#include [+ADDON_LIB]std_missing_params.aon



