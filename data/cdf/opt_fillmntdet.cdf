[[OPT_FILLMNTDET.AGCL]]
rem --- Set up a color to be used when qty picked <> ship qty
	pickGrid!=callpoint!.getDevObject("pickGrid")
	plainFont!=pickGrid!.getRowFont(0)
	boldFont!=sysGUI!.makeFont(plainFont!.getName(),plainFont!.getSize(),3);rem bold italic
	italicFont!=sysGUI!.makeFont(plainFont!.getName(),plainFont!.getSize(),2);rem italic
	callpoint!.setDevObject("plainFont",plainFont!)
	callpoint!.setDevObject("boldFont",boldFont!)
	callpoint!.setDevObject("italicFont",italicFont!)

	RGB$="255,0,0"
	gosub get_RGB
	callpoint!.setDevObject("redColor",BBjAPI().getSysGui().makeColor(R,G,B))

	RGB$="0,0,0"
	gosub get_RGB
	callpoint!.setDevObject("blackColor",BBjAPI().getSysGui().makeColor(R,G,B))

	RGB$="115,147,179"
	gosub get_RGB
	callpoint!.setDevObject("disabledColor",BBjAPI().getSysGui().makeColor(R,G,B))

rem --- Get and hold on to columns for qty_picked_dsp and qty_shipped_dsp
	picked_hdr$=callpoint!.getTableColumnAttribute("<<DISPLAY>>.QTY_PICKED_DSP","LABS")
	picked_col=util.getGridColumnNumber(pickGrid!,picked_hdr$)
	callpoint!.setDevObject("picked_col",picked_col)
	shipped_hdr$=callpoint!.getTableColumnAttribute("<<DISPLAY>>.QTY_SHIPPED_DSP","LABS")
	shipped_col=util.getGridColumnNumber(pickGrid!,shipped_hdr$)
	callpoint!.setDevObject("shipped_col",shipped_col)

rem --- Create linetypeMap, dropshipMap and unitcostMap HashMaps
	linetypeMap!= new java.util.HashMap()
	callpoint!.setDevObject("linetypeMap",linetypeMap!)
	dropshipMap!= new java.util.HashMap()
	callpoint!.setDevObject("dropshipMap",dropshipMap!)
	unitcostMap!= new java.util.HashMap()
	callpoint!.setDevObject("unitcostMap",unitcostMap!)

rem --- Set Lot/Serial button up properly
	switch pos(callpoint!.getDevObject("lotser_flag")="LS")
		case 1; callpoint!.setOptionText("LENT",Translate!.getTranslation("AON_PICK")+" "+Translate!.getTranslation("AON_LOT")); break
		case 2; callpoint!.setOptionText("LENT",Translate!.getTranslation("AON_PICK")+" "+Translate!.getTranslation("AON_SERIAL")); break
		case default; callpoint!.setOptionEnabled("LENT",0); break
	swend

[[OPT_FILLMNTDET.AGDR]]
rem --- Get corresponding order detail line.
	opeOrdDet_dev=fnget_dev("OPE_ORDDET")
	dim opeOrdDet$:fnget_tpl$("OPE_ORDDET")
	ar_type$=callpoint!.getColumnData("OPT_FILLMNTDET.AR_TYPE")
	customer_id$=callpoint!.getColumnData("OPT_FILLMNTDET.CUSTOMER_ID")
	order_no$=callpoint!.getColumnData("OPT_FILLMNTDET.ORDER_NO")
	ar_inv_no$=callpoint!.getColumnData("OPT_FILLMNTDET.AR_INV_NO")
	internal_seq_no$=callpoint!.getColumnData("OPT_FILLMNTDET.INTERNAL_SEQ_NO")
	opeOrdDet_key$=firm_id$+ar_type$+customer_id$+order_no$+ar_inv_no$+internal_seq_no$
	findrecord(opeOrdDet_dev,key=opeOrdDet_key$,dom=*next)opeOrdDet$

	unitcostMap!=callpoint!.getDevObject("unitcostMap")
	unitcostMap!.put(callpoint!.getValidationRow(),opeOrdDet.unit_cost)

	rem --- Do NOT allow returns!
	qty_picked=num(callpoint!.getColumnData("OPT_FILLMNTDET.QTY_PICKED"))
	ship_qty=num(callpoint!.getColumnData("OPT_FILLMNTDET.QTY_SHIPPED"))

rem --- What is this line type? Is this a dropship detail line?
	curr_row=callpoint!.getValidationRow()
	pickGrid!=callpoint!.getDevObject("pickGrid")
	linetypeMap!=callpoint!.getDevObject("linetypeMap")
	dropshipMap!=callpoint!.getDevObject("dropshipMap")
	opcLineCode_dev=fnget_dev("OPC_LINECODE")
	dim opcLineCode$:fnget_tpl$("OPC_LINECODE")
	findrecord (opcLineCode_dev, key=firm_id$+opeOrdDet.line_code$, dom=*next)opcLineCode$
	linetypeMap!.put(curr_row,opcLineCode.line_type$)
	dropshipMap!.put(curr_row,opcLineCode.dropship$)
	if pos(opcLineCode.line_type$="MO") or opcLineCode.dropship$="Y" or qty_picked<0 or ship_qty<0 then
		pickGrid!.setRowFont(curr_row,callpoint!.getDevObject("italicFont"))
		pickGrid!.setRowForeColor(curr_row,callpoint!.getDevObject("disabledColor"))
		pickGrid!.setCellEditable(curr_row,picked_col,0)
	else
		picked_col=callpoint!.getDevObject("picked_col")
		if qty_picked<>ship_qty then
			pickGrid!.setCellFont(curr_row,picked_col,callpoint!.getDevObject("boldFont"))
			pickGrid!.setCellForeColor(curr_row,picked_col,callpoint!.getDevObject("redColor"))
		else
			pickGrid!.setCellFont(curr_row,picked_col,callpoint!.getDevObject("plainFont"))
			pickGrid!.setCellForeColor(curr_row,picked_col,callpoint!.getDevObject("blackColor"))
		endif
		pickGrid!.setCellEditable(curr_row,picked_col,1)
	endif

[[OPT_FILLMNTDET.AGDS]]
rem --- Provide visual warning when quantity picked is NOT equal to the ship quantity
	pickGrid!=callpoint!.getDevObject("pickGrid")
	rows=pickGrid!.getNumRows()
	if rows<2 then break

	picked_col=callpoint!.getDevObject("picked_col")
	shipped_col=callpoint!.getDevObject("shipped_col")
	dropshipMap!=callpoint!.getDevObject("dropshipMap")
	linetypeMap!=callpoint!.getDevObject("linetypeMap")
	for i=0 to rows-2
		qty_picked=num(pickGrid!.getCellText(i,picked_col))
		ship_qty=num(pickGrid!.getCellText(i,shipped_col))
		if qty_picked<>ship_qty and dropshipMap!.get(i)<>"Y" and pos(linetypeMap!.get(i)="MO")=0 and
:		qty_picked>=0 and ship_qty>=0 then
			pickGrid!.setCellFont(i,picked_col,callpoint!.getDevObject("boldFont"))
			pickGrid!.setCellForeColor(i,picked_col,callpoint!.getDevObject("redColor"))
			pickGrid!.setCellEditable(i,picked_col,1)
		else
			if dropshipMap!.get(i)="Y" or pos(linetypeMap!.get(i)="MO") or qty_picked<0 or ship_qty<0 then
				pickGrid!.setCellFont(i,picked_col,callpoint!.getDevObject("italicFont"))
				pickGrid!.setCellForeColor(i,picked_col,callpoint!.getDevObject("disabledColor"))
				pickGrid!.setCellEditable(i,picked_col,0)
			else
				pickGrid!.setCellFont(i,picked_col,callpoint!.getDevObject("plainFont"))
				pickGrid!.setCellForeColor(i,picked_col,callpoint!.getDevObject("blackColor"))
				pickGrid!.setCellEditable(i,picked_col,0)
			endif
		endif
	next i

[[OPT_FILLMNTDET.AGRE]]
rem --- Use UM_SOLD related <DISPLAY> fields to update the real record fields
	gosub update_record_fields

[[OPT_FILLMNTDET.AGRN]]
rem --- Force focus on the row's qty_picked cell
	row=callpoint!.getValidationRow()
	callpoint!.setFocus(row,"<<DISPLAY>>.QTY_PICKED_DSP",1)

rem --- Get order detail line unit_cost
	unitcostMap!=callpoint!.getDevObject("unitcostMap")
	callpoint!.setDevObject("unit_cost",unitcostMap!.get(row))

rem --- Is this a dropship detail line?
	dropshipMap!=callpoint!.getDevObject("dropshipMap")
	if dropshipMap!.get(row)="Y" then
		callpoint!.setDevObject("dropship_line","Y")
	else
		callpoint!.setDevObject("dropship_line","N")
	endif

 rem --- Enable/disable lotted/serialized button
	item_id$ = callpoint!.getColumnData("OPT_FILLMNTDET.ITEM_ID")
	ship_qty  = num(callpoint!.getColumnData("<<DISPLAY>>.QTY_SHIPPED_DSP"))
	gosub lot_ser_check

	if callpoint!.isEditMode() and lotser_item$="Y" and ship_qty>0 and dropshipMap!.get(row)<>"Y"  then
		callpoint!.setOptionEnabled("LENT",1)
	else
		callpoint!.setOptionEnabled("LENT",0)
	endif

rem --- Enable Pack Carton button if, and only if, the QTY_PICKED_DSP is enabled
	linetypeMap!=callpoint!.getDevObject("linetypeMap")
	qty_picked=num(callpoint!.getColumnData("<<DISPLAY>>.QTY_PICKED_DSP"))
	if !callpoint!.isEditMode() or ship_qty<=0 or qty_picked<0 or dropshipMap!.get(row)="Y" or  pos(linetypeMap!.get(row)="MO") then
		callpoint!.setOptionEnabled("PACK",0)
	else
		callpoint!.setOptionEnabled("PACK",1)
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
		dflt_data$[2,0]="TRANS_STATUS"
		dflt_data$[2,1]="E"
		dflt_data$[3,0]="AR_TYPE"
		dflt_data$[3,1]=ar_type$
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
		callpoint!.setDevObject("wh",callpoint!.getColumnData("OPT_FILLMNTDET.WAREHOUSE_ID"))
		callpoint!.setDevObject("item_id",callpoint!.getColumnData("OPT_FILLMNTDET.ITEM_ID"))
		callpoint!.setDevObject("ship_qty",callpoint!.getColumnData("<<DISPLAY>>.QTY_SHIPPED_DSP"))

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

[[OPT_FILLMNTDET.AOPT-PACK]]
rem --- Launch Packing Carton Detail grid
		ar_type$=callpoint!.getColumnData("OPT_FILLMNTDET.AR_TYPE")
		cust$=callpoint!.getColumnData("OPT_FILLMNTDET.CUSTOMER_ID")
		order$=callpoint!.getColumnData("OPT_FILLMNTDET.ORDER_NO")
		invoice$=callpoint!.getColumnData("OPT_FILLMNTDET.AR_INV_NO")
		warehouse_id$=callpoint!.getColumnData("OPT_FILLMNTDET.WAREHOUSE_ID")
		item_id$=callpoint!.getColumnData("OPT_FILLMNTDET.ITEM_ID")

		dim dflt_data$[8,1]
		dflt_data$[1,0]="FIRM_ID"
		dflt_data$[1,1]=firm_id$
		dflt_data$[2,0]="TRANS_STATUS"
		dflt_data$[2,1]="E"
		dflt_data$[3,0]="AR_TYPE"
		dflt_data$[3,1]=ar_type$
		dflt_data$[4,0]="CUSTOMER_ID"
		dflt_data$[4,1]=cust$
		dflt_data$[5,0]="ORDER_NO"
		dflt_data$[5,1]=order$
		dflt_data$[6,0]="AR_INV_NO"
		dflt_data$[6,1]=invoice$
		dflt_data$[7,0]="WAREHOUSE_ID"
		dflt_data$[7,1]=warehouse_id$
		dflt_data$[8,0]="ITEM_ID"
		dflt_data$[8,1]=item_id$
		key_pfx$=firm_id$+"E"+ar_type$+cust$+order$+invoice$+warehouse_id$+item_id$

		rem --- Pass additional info needed in OPT_CARTDET
		callpoint!.setDevObject("orddet_seq_ref",callpoint!.getColumnData("OPT_FILLMNTDET.INTERNAL_SEQ_NO"))
		callpoint!.setDevObject("warehouse_id",callpoint!.getColumnData("OPT_FILLMNTDET.WAREHOUSE_ID"))
		callpoint!.setDevObject("item_id",callpoint!.getColumnData("OPT_FILLMNTDET.ITEM_ID"))
		callpoint!.setDevObject("order_memo",callpoint!.getColumnData("OPT_FILLMNTDET.ORDER_MEMO"))
		callpoint!.setDevObject("um_sold", callpoint!.getColumnData("OPT_FILLMNTDET.UM_SOLD"))
		callpoint!.setDevObject("qty_picked", callpoint!.getColumnData("OPT_FILLMNTDET.QTY_PICKED"))

		call stbl("+DIR_SYP") + "bam_run_prog.bbj", 
:			"OPT_CARTDET2", 
:			stbl("+USER_ID"), 
:			"MNT" ,
:			key_pfx$, 
:			table_chans$[all], 
:			dflt_data$[all]

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
	callpoint!.setColumnData("<<DISPLAY>>.QTY_SHIPPED_DSP",str(qty_shipped),1)
	qty_picked=num(callpoint!.getColumnData("OPT_FILLMNTDET.QTY_PICKED"))/conv_factor
	callpoint!.setColumnData("<<DISPLAY>>.QTY_PICKED_DSP",str(qty_picked),1)

[[OPT_FILLMNTDET.BWRI]]
rem --- Initialize RTP modified fields for modified existing records
	if callpoint!.getGridRowNewStatus(callpoint!.getValidationRow())<>"Y" then
		callpoint!.setColumnData("OPT_FILLMNTDET.MOD_USER", sysinfo.user_id$)
		callpoint!.setColumnData("OPT_FILLMNTDET.MOD_DATE", date(0:"%Yd%Mz%Dz"))
		callpoint!.setColumnData("OPT_FILLMNTDET.MOD_TIME", date(0:"%Hz%mz"))
	endif

[[<<DISPLAY>>.QTY_PICKED_DSP.AVAL]]
rem --- Do not allow returns
	qty_picked=num(callpoint!.getUserInput())
	if qty_picked<0 then
		msg_id$ = "OP_INV_FOR_RETURNS"
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- For inventoried lot/serial items, item qty_picked must equal sum of lot/serial number qty_picked
	ivmItemMast_dev=fnget_dev("IVM_ITEMMAST")
	dim ivmItemMast$:fnget_tpl$("IVM_ITEMMAST")
	item$=callpoint!.getColumnData("OPT_FILLMNTDET.ITEM_ID")
	findrecord (ivmItemMast_dev,key=firm_id$+item$,dom=*next)ivmItemMast$
	if ivmItemMast$.inventoried$="Y" then
		lotser_picked=0
		optFillmntLsDet_dev=fnget_dev("OPT_FILLMNTLSDET")
		dim optFillmntLsDet$:fnget_tpl$("OPT_FILLMNTLSDET")
		trans_status$=callpoint!.getColumnData("OPT_FILLMNTDET.TRANS_STATUS")
		ar_type$=callpoint!.getColumnData("OPT_FILLMNTDET.AR_TYPE")
		customer_id$=callpoint!.getColumnData("OPT_FILLMNTDET.CUSTOMER_ID")
		order_no$=callpoint!.getColumnData("OPT_FILLMNTDET.ORDER_NO")
		ar_inv_no$=callpoint!.getColumnData("OPT_FILLMNTDET.AR_INV_NO")
		internal_seq_no$=callpoint!.getColumnData("OPT_FILLMNTDET.INTERNAL_SEQ_NO")
		optFillmntDet_key$=firm_id$+trans_status$+ar_type$+customer_id$+order_no$+ar_inv_no$+internal_seq_no$
		read(optFillmntLsDet_dev,key=optFillmntDet_key$,knum="AO_STATUS",dom=*next)
		while 1
			optFillmntLsDet_key$=key(optFillmntLsDet_dev,end=*break)
			if pos(optFillmntDet_key$=optFillmntLsDet_key$)<>1 then break
			readrecord(optFillmntLsDet_dev)optFillmntLsDet$
			lotser_picked=lotser_picked+optFillmntLsDet.qty_picked
		wend

		if qty_picked<>lotser_picked then
			msg_id$ = "OP_SUM_LOTSER_PICKED"
			dim msg_tokens$[1]
			msg_tokens$[1]=str(lotser_picked)
			gosub disp_message
			callpoint!.setStatus("ABORT")
			callpoint!.setColumnData("<<DISPLAY>>.QTY_PICKED_DSP",str(lotser_picked),1)
			break
		endif
	endif

rem --- Provide visual warning when quantity picked is NOT equal to the ship quantity
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
	callpoint!.setDevObject("lotser_item",lotser_item$)

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
get_RGB: rem --- Parse Red, Green and Blue segments from RGB$ string
	rem --- input: RGB$
	rem --- output: R
	rem --- output: G
	rem --- output: B
rem ==========================================================================
	comma1=pos(","=RGB$,1,1)
	comma2=pos(","=RGB$,1,2)
	R=num(RGB$(1,comma1-1))
	G=num(RGB$(comma1+1,comma2-comma1-1))
	B=num(RGB$(comma2+1))

	return

rem ==========================================================================
rem 	Use util object
rem ==========================================================================
	use ::ado_util.src::util



