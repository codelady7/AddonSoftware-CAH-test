[[OPT_FILLMNTDET.AGRN]]
rem --- Force focus on the row's qty_picked cell
	callpoint!.setFocus(num(callpoint!.getValidationRow()),"OPT_FILLMNTDET.QTY_PICKED",1)

 rem --- Enable/disable lotted/serialized button
	item_id$ = callpoint!.getColumnData("OPT_FILLMNTDET.ITEM_ID")
	ship_qty  = num(callpoint!.getColumnData("OPT_FILLMNTDET.QTY_SHIPPED"))
	gosub lot_ser_check

	if lotser_item$="Y" and ship_qty<>0 and callpoint!.isEditMode() then
		callpoint!.setOptionEnabled("LENT",1)
	else
		callpoint!.setOptionEnabled("LENT",0)
	endif

[[OPT_FILLMNTDET.AOPT-LENT]]
rem --- Is this item lot/serial?
	item_id$=callpoint!.getColumnData("OPT_FILLMNTDET.ITEM_ID")
	gosub lot_ser_check
	if lotser_item$="Y" then
		ar_type$=callpoint!.getColumnData("OPT_FILLMNTDET.AR_TYPE")
		cust$=callpoint!.getColumnData("OPT_FILLMNTDET.CUSTOMER_ID")
		order$=callpoint!.getColumnData("OPT_FILLMNTDET.ORDER_NO")
		invoice$=callpoint!.getColumnData("OPT_FILLMNTDET.AR_INV_NO")
		int_seq$=callpoint!.getColumnData("OPT_FILLMNTDET.INTERNAL_SEQ_NO")

		dim dflt_data$[6,1]
		dflt_data$[1,0]="AR_TYPE"
		dflt_data$[1,1]=ar_type$
		dflt_data$[2,0]="TRANS_STATUS"
		dflt_data$[2,1]="E"
		dflt_data$[3,0]="CUSTOMER_ID"
		dflt_data$[3,1]=cust$
		dflt_data$[4,0]="ORDER_NO"
		dflt_data$[4,1]=order$
		dflt_data$[5,0]="AR_INV_NO"
		dflt_data$[5,1]=invoice$
		dflt_data$[6,0]="ORDDET_SEQ_REF"
		dflt_data$[6,1]=int_seq$
		key_pfx$ = firm_id$+"E"+ar_type$+cust$+order$+invoice$+int_seq$

rem wgh ... 10304 ... stopped here
		call stbl("+DIR_SYP") + "bam_run_prog.bbj", 
:			"OPT_FILLMNTLSDET", 
:			stbl("+USER_ID"), 
:			"MNT" ,
:			key_pfx$, 
:			table_chans$[all], 
:			dflt_data$[all]

	endif

[[OPT_FILLMNTDET.AREC]]
rem --- Initialize RTP trans_status and created fields
	rem --- TRANS_STATUS set to "E" via form Preset Value
	callpoint!.setColumnData("OPT_FILLMNTDET.CREATED_USER",sysinfo.user_id$)
	callpoint!.setColumnData("OPT_FILLMNTDET.CREATED_DATE",date(0:"%Yd%Mz%Dz"))
	callpoint!.setColumnData("OPT_FILLMNTDET.CREATED_TIME",date(0:"%Hz%mz"))

rem --- Buttons start disabled
	callpoint!.setOptionEnabled("LENT",0)

[[OPT_FILLMNTDET.BDGX]]
rem --- Disable detail-only buttons
	callpoint!.setOptionEnabled("LENT",0)

[[OPT_FILLMNTDET.BWRI]]
rem --- Initialize RTP modified fields for modified existing records
	if callpoint!.getGridRowNewStatus(callpoint!.getValidationRow())<>"Y" then
		callpoint!.setColumnData("OPT_FILLMNTDET.MOD_USER", sysinfo.user_id$)
		callpoint!.setColumnData("OPT_FILLMNTDET.MOD_DATE", date(0:"%Yd%Mz%Dz"))
		callpoint!.setColumnData("OPT_FILLMNTDET.MOD_TIME", date(0:"%Hz%mz"))
	endif

[[OPT_FILLMNTDET.QTY_PICKED.AVAL]]
rem --- Warn when quantity picked is NOT equal to the ship quantity
	qty_picked=num(callpoint!.getUserInput())
	ship_qty=num(callpoint!.getColumnData("OPT_FILLMNTDET.QTY_SHIPPED"))
	if qty_picked<>ship_qty then
		msg_id$="OP_PICK_QTY_BAD"
		gosub disp_message
		if msg_opt$="N"
			callpoint!.setStatus("ABORT")
			break
		endif
	endif

[[OPT_FILLMNTDET.<CUSTOM>]]
rem ==========================================================================
lot_ser_check: rem --- Check for lotted/serialized item
               rem      IN: item_id$
               rem   OUT: lotser_item$
rem ==========================================================================
	lotser_item$="N"
	lotser_flag$=callpoint!.getDevObject("lotser_flag")
	if cvs(item_id$, 2)<>"" and pos(lotser_flag$ = "LS") then 
		ivm01_dev=fnget_dev("IVM_ITEMMAST")
		dim ivm01a$:fnget_tpl$("IVM_ITEMMAST")
		read record (ivm01_dev, key=firm_id$+item_id$, dom=*endif) ivm01a$
		if ivm01a.lotser_item$="Y" then lotser_item$="Y"
	endif

	return



