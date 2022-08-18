[[OPT_FILLMNTDET.AGCL]]
rem --- Set up a color to be used when qty picked <> ship qty
	pickGrid!=callpoint!.getDevObject("pickGrid")
	plainFont!=pickGrid!.getRowFont(0)
	boldFont!=sysGUI!.makeFont(plainFont!.getName(),plainFont!.getSize(),3);rem bold italic
	callpoint!.setDevObject("boldFont",boldFont!)
	callpoint!.setDevObject("plainFont",plainFont!)

rem --- Get and hold on to columns for qty_picked_dsp and qty_shipped_dsp
	picked_hdr$=callpoint!.getTableColumnAttribute("<<DISPLAY>>.QTY_PICKED_DSP","LABS")
	picked_col=util.getGridColumnNumber(pickGrid!,picked_hdr$)
	callpoint!.setDevObject("picked_col",picked_col)
	shipped_hdr$=callpoint!.getTableColumnAttribute("<<DISPLAY>>.QTY_SHIPPED_DSP","LABS")
	shipped_col=util.getGridColumnNumber(pickGrid!,shipped_hdr$)
	callpoint!.setDevObject("shipped_col",shipped_col)

[[OPT_FILLMNTDET.AGDS]]
rem --- Provide visual warning when quantity picked is NOT equal to the ship quantity
	pickGrid!=callpoint!.getDevObject("pickGrid")
	picked_col=callpoint!.getDevObject("picked_col")
	shipped_col=callpoint!.getDevObject("shipped_col")

	rows=pickGrid!.getNumRows()
	if rows=0 then break
	for i=0 to rows-1
		qty_picked=num(pickGrid!.getCellText(i,picked_col))
		ship_qty=num(pickGrid!.getCellText(i,shipped_col))
		if qty_picked<>ship_qty then
			pickGrid!.setCellFont(i,picked_col,callpoint!.getDevObject("boldFont"))
			pickGrid!.setCellForeColor(i,picked_col,callpoint!.getDevObject("redColor"))
		else
			pickGrid!.setCellFont(i,picked_col,callpoint!.getDevObject("plainFont"))
			pickGrid!.setCellForeColor(i,picked_col,callpoint!.getDevObject("blackColor"))
		endif
	next i

[[OPT_FILLMNTDET.AGRE]]
rem --- Use UM_SOLD related <DISPLAY> fields to update the real record fields
	gosub update_record_fields

[[OPT_FILLMNTDET.AGRN]]
rem --- Force focus on the row's qty_picked cell
	callpoint!.setFocus(num(callpoint!.getValidationRow()),"<<DISPLAY>>.QTY_PICKED_DSP",1)

 rem --- Enable/disable lotted/serialized button
	item_id$ = callpoint!.getColumnData("OPT_FILLMNTDET.ITEM_ID")
	ship_qty  = num(callpoint!.getColumnData("<<DISPLAY>>.QTY_SHIPPED_DSP"))
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

		dim dflt_data$[7,1]
		dflt_data$[1,0]="FIRM_ID"
		dflt_data$[1,1]=firm_id$
		dflt_data$[2,0]="AR_TYPE"
		dflt_data$[2,1]=ar_type$
		dflt_data$[3,0]="TRANS_STATUS"
		dflt_data$[3,1]="E"
		dflt_data$[4,0]="CUSTOMER_ID"
		dflt_data$[4,1]=cust$
		dflt_data$[5,0]="ORDER_NO"
		dflt_data$[5,1]=order$
		dflt_data$[6,0]="AR_INV_NO"
		dflt_data$[6,1]=invoice$
		dflt_data$[7,0]="ORDDET_SEQ_REF"
		dflt_data$[7,1]=int_seq$
		key_pfx$=firm_id$+"E"+ar_type$+cust$+order$+invoice$+int_seq$

		rem --- Pass additional info needed in OPT_FILLMNTLSDET
		callpoint!.setDevObject("item_ship_qty", callpoint!.getColumnData("<<DISPLAY>>.QTY_SHIPPED_DSP"))

rem wgh ... 10304 ... stopped here
		call stbl("+DIR_SYP") + "bam_run_prog.bbj", 
:			"OPT_FILLMNTLSDET", 
:			stbl("+USER_ID"), 
:			"MNT" ,
:			key_pfx$, 
:			table_chans$[all], 
:			dflt_data$[all]

	endif

rem --- Has the total quantity picked changed?
	start_qty_picked=num(callpoint!.getColumnData("<<DISPLAY>>.QTY_PICKED_DSP"))
	total_picked=callpoint!.getDevObject("total_picked")
	if total_picked<>start_qty_picked then
		callpoint!.setColumnData("<<DISPLAY>>.QTY_PICKED_DSP",str(callpoint!.getDevObject("total_picked")),1)
		callpoint!.setStatus("MODIFIED")
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

[[OPT_FILLMNTDET.BGDR]]
rem --- Initialize UM_SOLD related <DISPLAY> fields
	conv_factor=num(callpoint!.getColumnData("OPT_FILLMNTDET.CONV_FACTOR"))
	if conv_factor=0 then conv_factor=1
	qty_shipped=num(callpoint!.getColumnData("OPT_FILLMNTDET.QTY_SHIPPED"))/conv_factor
	callpoint!.setColumnData("<<DISPLAY>>.QTY_SHIPPED_DSP",str(qty_shipped))
	qty_picked=num(callpoint!.getColumnData("OPT_FILLMNTDET.QTY_PICKED"))/conv_factor
	callpoint!.setColumnData("<<DISPLAY>>.QTY_PICKED_DSP",str(qty_picked))

[[OPT_FILLMNTDET.BWRI]]
rem --- Initialize RTP modified fields for modified existing records
	if callpoint!.getGridRowNewStatus(callpoint!.getValidationRow())<>"Y" then
		callpoint!.setColumnData("OPT_FILLMNTDET.MOD_USER", sysinfo.user_id$)
		callpoint!.setColumnData("OPT_FILLMNTDET.MOD_DATE", date(0:"%Yd%Mz%Dz"))
		callpoint!.setColumnData("OPT_FILLMNTDET.MOD_TIME", date(0:"%Hz%mz"))
	endif

[[<<DISPLAY>>.QTY_PICKED_DSP.AVAL]]
rem --- Provide visual warning when quantity picked is NOT equal to the ship quantity
	qty_picked=num(callpoint!.getUserInput())
	ship_qty=num(callpoint!.getColumnData("<<DISPLAY>>.QTY_SHIPPED_DSP"))
	pickGrid!=callpoint!.getDevObject("pickGrid")
	curr_row=num(callpoint!.getValidationRow())
	picked_col=callpoint!.getDevObject("picked_col")

	if qty_picked<>ship_qty then
		pickGrid!.setCellFont(curr_row,picked_col,callpoint!.getDevObject("boldFont"))
		pickGrid!.setCellForeColor(curr_row,picked_col,callpoint!.getDevObject("redColor"))
	else
		pickGrid!.setCellFont(curr_row,picked_col,callpoint!.getDevObject("plainFont"))
		pickGrid!.setCellForeColor(curr_row,picked_col,callpoint!.getDevObject("blackColor"))
	endif

rem --- Use UM_SOLD related <DISPLAY> fields to update the real record fields
	callpoint!.setColumnData("<<DISPLAY>>.QTY_PICKED_DSP",str(qty_picked))
	gosub update_record_fields

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

rem ==========================================================================
update_record_fields: rem --- Use UM_SOLD related <DISPLAY> fields to update the real record fields
rem ==========================================================================
	conv_factor=num(callpoint!.getColumnData("OPT_FILLMNTDET.CONV_FACTOR"))
	if conv_factor=0 then conv_factor=1
	qty_shipped=num(callpoint!.getColumnData("<<DISPLAY>>.QTY_SHIPPED_DSP"))*conv_factor
	callpoint!.setColumnData("OPT_FILLMNTDET.QTY_SHIPPED",str(qty_shipped))
	qty_picked=num(callpoint!.getColumnData("<<DISPLAY>>.QTY_PICKED_DSP"))*conv_factor
	callpoint!.setColumnData("OPT_FILLMNTDET.QTY_PICKED",str(qty_picked))

	return

rem ==========================================================================
rem 	Use util object
rem ==========================================================================
	use ::ado_util.src::util



