[[ARM_CUSTSHIP.ADIS]]
rem --- Disable Manual Ship-to option for existing records
	callpoint!.setOptionEnabled("MANS",0)
	

[[ARM_CUSTSHIP.AOPT-MANS]]
rem --- Manual ship-to historical address lookup
	call stbl("+DIR_SYP")+"bac_key_template.bbj","OPT_INVHDR","PRIMARY",key_tpl$,rd_table_chans$[all],status$
	dim optInvHdr_key$:key_tpl$
	dim filter_defs$[3,2]
	filter_defs$[1,0]="OPT_INVHDR.FIRM_ID"
	filter_defs$[1,1]="='"+firm_id$ +"'"
	filter_defs$[1,2]="LOCK"
	filter_defs$[2,0]="OPT_INVHDR.CUSTOMER_ID"
	filter_defs$[2,1]="='"+callpoint!.getColumnData("ARM_CUSTSHIP.CUSTOMER_ID")+"'"
	filter_defs$[2,2]="LOCK"
	filter_defs$[3,0]="OPT_INVHDR.SHIPTO_TYPE"
	filter_defs$[3,1]="='M'"
	filter_defs$[3,2]="LOCK"
	
	call stbl("+DIR_SYP")+"bax_query.bbj",gui_dev,form!,"OP_MAN_SHIPTO","",table_chans$[all],optInvHdr_key$,filter_defs$[all]

	rem --- Update manual ship-to address if changed
	if cvs(optInvHdr_key$,2)<>"" then 
		opt31_dev=fnget_dev("OPT_INVSHIP")
		dim opt31a$:fnget_tpl$("OPT_INVSHIP")
		opt31_key$=firm_id$+optInvHdr_key.customer_id$+optInvHdr_key.order_no$+optInvHdr_key.ar_inv_no$+"S"
		readrecord(opt31_dev,key=opt31_key$,dom=*next)opt31a$
		callpoint!.setColumnData("ARM_CUSTSHIP.NAME",opt31a.name$,1)
		callpoint!.setColumnData("ARM_CUSTSHIP.ADDR_LINE_1",opt31a.addr_line_1$,1)
		callpoint!.setColumnData("ARM_CUSTSHIP.ADDR_LINE_2",opt31a.addr_line_2$,1)
		callpoint!.setColumnData("ARM_CUSTSHIP.ADDR_LINE_3",opt31a.addr_line_3$,1)
		callpoint!.setColumnData("ARM_CUSTSHIP.ADDR_LINE_4",opt31a.addr_line_4$,1)
		callpoint!.setColumnData("ARM_CUSTSHIP.CITY",opt31a.city$,1)
		callpoint!.setColumnData("ARM_CUSTSHIP.STATE_CODE",opt31a.state_code$,1)
		callpoint!.setColumnData("ARM_CUSTSHIP.ZIP_CODE",opt31a.zip_code$,1)
		callpoint!.setColumnData("ARM_CUSTSHIP.CNTRY_ID",opt31a.cntry_id$,1)

		sql_prep$="SELECT slspsn_code, territory, tax_code, ar_ship_via, shipping_id, shipping_email "
		sql_prep$=sql_prep$+"FROM opt_invhdr "
		sql_prep$=sql_prep$+"WHERE firm_id='"+firm_id$+"' and customer_id='"+optInvHdr_key.customer_id$+
:			"' and order_no='"+optInvHdr_key.order_no$+"' and ar_inv_no='"+optInvHdr_key.ar_inv_no$+"' "

		sql_chan=sqlunt
		sqlopen(sql_chan,err=*endif)stbl("+DBNAME")
		sqlprep(sql_chan)sql_prep$
		dim read_tpl$:sqltmpl(sql_chan)
		sqlexec(sql_chan)

		read_tpl$ = sqlfetch(sql_chan,end=*endif)
		callpoint!.setColumnData("ARM_CUSTSHIP.SLSPSN_CODE",read_tpl.slspsn_code$,1)
		callpoint!.setColumnData("ARM_CUSTSHIP.TERRITORY",read_tpl.territory$,1)
		callpoint!.setColumnData("ARM_CUSTSHIP.TAX_CODE",read_tpl.tax_code$,1)
		callpoint!.setColumnData("ARM_CUSTSHIP.AR_SHIP_VIA",read_tpl.ar_ship_via$,1)
		callpoint!.setColumnData("ARM_CUSTSHIP.SHIPPING_ID",read_tpl.shipping_id$,1)
		callpoint!.setColumnData("ARM_CUSTSHIP.SHIPPING_EMAIL",read_tpl.shipping_email$,1)

		callpoint!.setStatus("MODIFIED")
	endif

	callpoint!.setStatus("ACTIVATE")

[[ARM_CUSTSHIP.AREC]]
rem --- Disable Manual Ship-to option for existing records
	callpoint!.setOptionEnabled("MANS",0)

[[ARM_CUSTSHIP.ARER]]
rem --- Need to be able to save new records coming from Order/Invoice Entry
	if callpoint!.getDevObject("createNewShipToAddr")<>null() then callpoint!.setStatus("MODIFIED")

[[ARM_CUSTSHIP.ARNF]]
rem -- Enable Manual Ship-to option for new records when OP is installed
	if callpoint!.getDevObject("op_installed")="Y" then callpoint!.setOptionEnabled("MANS",1)

[[ARM_CUSTSHIP.BSHO]]
rem  Initializations
	use ::ado_util.src::util

rem --- Is Sales Order Processing installed for this firm?
	call pgmdir$+"adc_application.aon","OP",info$[all]
	op_installed$=info$[20]; rem ---OP installed?
	callpoint!.setDevObject("op_installed",op_installed$)

rem --- Open needed files

	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]

	if op_installed$="Y" then
		open_tables$[1]="OPT_INVSHIP",  open_opts$[1]="OTA"
	endif

	gosub open_tables

rem --- 10395 ... Disable Manual Ship-to option for existing records
	callpoint!.setOptionEnabled("MANS",0)

[[ARM_CUSTSHIP.SHIPPING_EMAIL.AVAL]]
rem --- Validate email address
	email$=callpoint!.getUserInput()
	if !util.validEmailAddress(email) then
		callpoint!.setStatus("ABORT")
		break
	endif



