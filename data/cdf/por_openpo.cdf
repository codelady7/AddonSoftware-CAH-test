[[POR_OPENPO.ARAR]]
callpoint!.setColumnData("POR_OPENPO.REPORT_SEQUENCE","V")
callpoint!.setColumnData("POR_OPENPO.DATE_TYPE","O")
callpoint!.setStatus("REFRESH")

rem --- Enable/disable Work Order fields depending on if Shop Floor is installed
	call pgmdir$+"adc_application.aon","SF",info$[all]
	sf$=info$[20]

	if sf$<>"Y" then
		rem --- SF not installed, disable WO fields
		callpoint!.setColumnEnabled("POR_OPENPO.WO_NO_1",0)
		callpoint!.setColumnEnabled("POR_OPENPO.WO_NO_2",0)
	else
		rem --- SF installed, enable WO fields
		callpoint!.setColumnEnabled("POR_OPENPO.WO_NO_1",1)
		callpoint!.setColumnEnabled("POR_OPENPO.WO_NO_2",1)
	endif

rem --- Enable/disable Sales Order fields depending on if Order Processing is installed
	call pgmdir$+"adc_application.aon","OP",info$[all]
	op$=info$[20]

	if op$<>"Y" then
		rem --- SF not installed, disable WO fields
		callpoint!.setColumnEnabled("POR_OPENPO.ORDER_NO_1",0)
		callpoint!.setColumnEnabled("POR_OPENPO.ORDER_NO_2",0)
	else
		rem --- SF installed, enable WO fields
		callpoint!.setColumnEnabled("POR_OPENPO.ORDER_NO_1",1)
		callpoint!.setColumnEnabled("POR_OPENPO.ORDER_NO_2",1)
	endif

[[POR_OPENPO.BSHO]]

[[POR_OPENPO.ORDER_NO.BINQ]]
rem --- Sales Order Lookup
	call stbl("+DIR_SYP")+"bac_key_template.bbj","OPT_INVHDR","PRIMARY",key_tpl$,rd_table_chans$[all],status$
	dim optInvHdr_key$:key_tpl$
	dim filter_defs$[4,2]
	filter_defs$[1,0]="OPT_INVHDR.FIRM_ID"
	filter_defs$[1,1]="='"+firm_id$ +"'"
	filter_defs$[1,2]="LOCK"
	filter_defs$[2,0]="OPT_INVHDR.TRANS_STATUS"
	filter_defs$[2,1]="='E'"
	filter_defs$[2,2]="LOCK"
	filter_defs$[3,0]="OPT_INVHDR.ORDINV_FLAG"
	filter_defs$[3,1]="='O'"
	filter_defs$[3,2]="LOCK"
	filter_defs$[4,0]="OPT_INVHDR.INVOICE_TYPE"
	filter_defs$[4,1]="='S'"
	filter_defs$[4,2]="LOCK"
	
	call stbl("+DIR_SYP")+"bax_query.bbj",gui_dev,form!,"OP_ENTRY_1","",table_chans$[all],optInvHdr_key$,filter_defs$[all]

	rem --- Update Sales Order
	if cvs(optInvHdr_key$,2)<>"" then 
		ctrl_1!=callpoint!.getControl("POR_OPENPO.ORDER_NO_1")
		ctrl_2!=callpoint!.getControl("POR_OPENPO.ORDER_NO_2")
		if callpoint!.getControlID()=str(ctrl_1!.getID():"00000") then
			callpoint!.setColumnData("POR_OPENPO.ORDER_NO_1",optInvHdr_key.order_no$,1)
		endif
		if callpoint!.getControlID()=str(ctrl_2!.getID():"00000") then
			callpoint!.setColumnData("POR_OPENPO.ORDER_NO_2",optInvHdr_key.order_no$,1)
		endif
	endif

	callpoint!.setStatus("ACTIVATE-ABORT")



