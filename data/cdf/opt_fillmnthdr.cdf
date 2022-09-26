[[OPT_FILLMNTHDR.ACUS]]
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

	rem --- The tab control
	if ctl_ID=num(stbl("+TAB_CTL")) then
		switch notice.code
			case 2; rem --- ON_TAB_SELECT
				tabCtrl!=Form!.getControl(ctl_ID)
				tabIndex=tabCtrl!.getSelectedIndex()
				Packing_and_Shipping$=Translate!.getTranslation("DDM_TABLE_TABG-OPT_FILLMNTHDR-02-DD_ATTR_TABG")
				if pos(tabCtrl!.getTitleAt(tabIndex)=Packing_and_Shipping$)=1 then
					rem --- Need to refresh display if a new OPT_CARTHDR record was added via Pick Item button (also see AWRI)
					if callpoint!.getDevObject("refreshRecord") then
						optFillmntHdr_key$=callpoint!.getRecordKey()
						callpoint!.setStatus("RECORD:["+optFillmntHdr_key$+"]")
						callpoint!.setDevObject("refreshRecord",0)
					endif
				endif
			break
		swend
	endif

[[OPT_FILLMNTHDR.ADEL]]
rem --- Set record deleted flag
	callpoint!.setDevObject("recordDeleted",1)

[[OPT_FILLMNTHDR.ADIS]]
rem --- Capture starting record data so can tell later if anything changed
	callpoint!.setDevObject("initial_rec_data$",rec_data$)

rem --- Hold onto ar_ship_via for use in opt_carthdr
	callpoint!.setDevObject("ar_ship_via",callpoint!.getColumnData("OPT_FILLMNTHDR.AR_SHIP_VIA"))

rem --- Initializations
	callpoint!.setDevObject("recordDeleted",0)
	callpoint!.setDevObject("refreshRecord",0)

[[OPT_FILLMNTHDR.AREC]]
rem --- Initialize RTP trans_status and created fields
	rem --- TRANS_STATUS set to "E" via form Preset Value
	callpoint!.setColumnData("OPT_FILLMNTHDR.CREATED_USER",sysinfo.user_id$)
	callpoint!.setColumnData("OPT_FILLMNTHDR.CREATED_DATE",date(0:"%Yd%Mz%Dz"))
	callpoint!.setColumnData("OPT_FILLMNTHDR.CREATED_TIME",date(0:"%Hz%mz"))

rem --- Capture starting record data so can tell later if anything changed
	callpoint!.setDevObject("initial_rec_data$",rec_data$)

rem --- Initializations
	callpoint!.setDevObject("recordDeleted",0)
	callpoint!.setDevObject("refreshRecord",0)

[[OPT_FILLMNTHDR.ARNF]]
rem --- Confirm the Order is ready to be filled.
	msg_id$="OP_ORD_READY_TO_FILL"
	gosub disp_message
	if msg_opt$="N"
		callpoint!.setStatus("ABORT")
		break
	else
		callpoint!.setStatus("ACTIVATE")
	endif

rem --- Initialize inventory item update
	status=999
	call stbl("+DIR_PGM")+"ivc_itemupdt.aon::init",err=*next,chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
	if status then exitto std_exit

rem --- Initialize new Order Fulfillment Entry with corresponding OPE_ORDHDR data
	ar_type$=callpoint!.getColumnData("OPT_FILLMNTHDR.AR_TYPE")
	customer_id$=callpoint!.getColumnData("OPT_FILLMNTHDR.CUSTOMER_ID")
	order_no$=callpoint!.getColumnData("OPT_FILLMNTHDR.ORDER_NO")
	opeOrdHdr_dev=fnget_dev("OPE_ORDHDR")
	dim opeOrdHdr$:fnget_tpl$("OPE_ORDHDR")
	call stbl("+DIR_SYP")+"bac_key_template.bbj","OPT_INVHDR","PRIMARY",key_tpl$,rd_table_chans$[all],status$
	dim opeOrdHdr_key$:key_tpl$
	opeOrdHdr_key.firm_id$=firm_id$
	opeOrdHdr_key.ar_type$=ar_type$
	opeOrdHdr_key.customer_id$=customer_id$
	opeOrdHdr_key.order_no$=order_no$
	opeOrdHdr_key.ar_inv_no$=""

	readrecord(opeOrdHdr_dev,key=opeOrdHdr_key$,knum="PRIMARY",dom=*next)opeOrdHdr$

	optFillmntHdr_dev=fnget_dev("OPT_FILLMNTHDR")
	dim optFillmntHdr$:fnget_tpl$("OPT_FILLMNTHDR")
	optFillmntHdr.firm_id$=firm_id$
	optFillmntHdr.ar_type$=opeOrdHdr.ar_type$
	optFillmntHdr.customer_id$=opeOrdHdr.customer_id$
	optFillmntHdr.order_no$=opeOrdHdr.order_no$
	optFillmntHdr.ar_inv_no$=opeOrdHdr.ar_inv_no$
	optFillmntHdr.shipmnt_date$=opeOrdHdr.shipmnt_date$
	optFillmntHdr.ar_ship_via$=opeOrdHdr.ar_ship_via$
	optFillmntHdr.shipping_id$=opeOrdHdr.shipping_id$
	optFillmntHdr.created_user$=sysinfo.user_id$
	optFillmntHdr.created_date$=date(0:"%Yd%Mz%Dz")
	optFillmntHdr.created_time$=date(0:"%Hz%mz")
	optFillmntHdr.trans_status$="E"
	writerecord(optFillmntHdr_dev)optFillmntHdr$

rem --- Hold onto ar_ship_via for use in opt_carthdr
	callpoint!.setDevObject("ar_ship_via",optFillmntHdr.ar_ship_via$)

rem --- Show total weight and total freight amount
	weight=0
	freight_amt=0
	optCartHdr_dev=fnget_dev("OPT_CARTHDR")
	dim optCartHdr$:fnget_tpl$("OPT_CARTHDR")
	read(optCartHdr_dev,key=opeOrdHdr_key$,knum="PRIMARY",dom=*next)
	while 1
		optCartHdr_key$=key(optCartHdr_dev,end=*break)
		if pos(opeOrdHdr_key$=optCartHdr_key$)<>1 then break
		readrecord(optCartHdr_dev)optCartHdr$
		weight=weight+optCartHdr.weight
		freight_amt=freight_amt+optCartHdr.freight_amt
	wend
	callpoint!.setColumnData("<<DISPLAY>>.WEIGHT",str(weight),1)
	callpoint!.setColumnData("<<DISPLAY>>.FREIGHT_AMT",str(freight_amt),1)

	callpoint!.setStatus("MODIFIED")

rem --- Initialize Picking tab with corresponding OPE_ORDDET data
	optFillmntDet_dev=fnget_dev("OPT_FILLMNTDET")
	dim optFillmntDet$:fnget_tpl$("OPT_FILLMNTDET")
	opeOrdDet_dev=fnget_dev("OPE_ORDDET")
	dim opeOrdDet$:fnget_tpl$("OPE_ORDDET")
	ivmItemWhse_dev=fnget_dev("IVM_ITEMWHSE")
	dim ivmItemWhse$:fnget_tpl$("IVM_ITEMWHSE")
	read(opeOrdDet_dev,key=opeOrdHdr_key$,knum="PRIMARY",dom=*next)
	while 1
		opeOrdDet_key$=key(opeOrdDet_dev,end=*break)
		if pos(opeOrdHdr_key$=opeOrdDet_key$)<>1 then break
		readrecord(opeOrdDet_dev)opeOrdDet$

		rem --- Initialize OPT_FILLMNTLSDET with corresponding OPE_ORDLSDET data
		optFillmntLsDet_dev=fnget_dev("OPT_FILLMNTLSDET")
		dim optFillmntLsDet$:fnget_tpl$("OPT_FILLMNTLSDET")
		opeOrdLsDet_dev=fnget_dev("OPE_ORDLSDET")
		dim opeOrdLsDet$:fnget_tpl$("OPE_ORDLSDET")
		read(opeOrdLsDet_dev,key=opeOrdDet_key$,knum="PRIMARY",dom=*next)
		while 1
			opeOrdLsDet_key$=key(opeOrdLsDet_dev,end=*break)
			if pos(opeOrdDet_key$=opeOrdLsDet_key$)<>1 then break
			readrecord(opeOrdLsDet_dev)opeOrdLsDet$

			redim optFillmntLsDet$
			optFillmntLsDet.firm_id$=firm_id$
			optFillmntLsDet.ar_type$=opeOrdLsDet.ar_type$
			optFillmntLsDet.customer_id$=opeOrdLsDet.customer_id$
			optFillmntLsDet.order_no$=opeOrdLsDet.order_no$
			optFillmntLsDet.ar_inv_no$=opeOrdLsDet.ar_inv_no$
			optFillmntLsDet.orddet_seq_ref$=opeOrdLsDet.orddet_seq_ref$
			optFillmntLsDet.sequence_no$=opeOrdLsDet.sequence_no$
			optFillmntLsDet.lotser_no$=opeOrdLsDet.lotser_no$
			if opeOrdLsDet.qty_ordered>0 then
				rem --- Cannot have an order qty greater than zero unless the lot/serial number was committed in Order Entry 
				optFillmntLsDet.oe_committed$="Y"
			else
				optFillmntLsDet.oe_committed$="N"
			endif
			optFillmntLsDet.created_user$=sysinfo.user_id$
			optFillmntLsDet.created_date$=date(0:"%Yd%Mz%Dz")
			optFillmntLsDet.created_time$=date(0:"%Hz%mz")
			optFillmntLsDet.trans_status$="E"
			optFillmntLsDet.qty_shipped=opeOrdLsDet.qty_shipped
			if status then
				rem --- Wasn't able to uncommit the lot/serial number
				optFillmntLsDet.qty_picked=opeOrdLsDet.qty_shipped
			else
				optFillmntLsDet.qty_picked=0
			endif
			optFillmntLsDet.unit_cost=opeOrdLsDet.unit_cost
			writerecord(optFillmntLsDet_dev)optFillmntLsDet$
		wend

		rem --- Get warehouse location for this item
		redim ivmItemWhse$
		readrecord(ivmItemWhse_dev,key=firm_id$+opeOrdDet.warehouse_id$+opeOrdDet.item_id$,dom=*next)ivmItemWhse$

		redim optFillmntDet$
		optFillmntDet.firm_id$=firm_id$
		optFillmntDet.ar_type$=opeOrdDet.ar_type$
		optFillmntDet.customer_id$=opeOrdDet.customer_id$
		optFillmntDet.order_no$=opeOrdDet.order_no$
		optFillmntDet.ar_inv_no$=opeOrdDet.ar_inv_no$
		optFillmntDet.internal_seq_no$=opeOrdDet.internal_seq_no$
		optFillmntDet.warehouse_id$=opeOrdDet.warehouse_id$
		optFillmntDet.item_id$=opeOrdDet.item_id$
		optFillmntDet.order_memo$=opeOrdDet.order_memo$
		optFillmntDet.memo_1024$=opeOrdDet.memo_1024$
		optFillmntDet.um_sold$=opeOrdDet.um_sold$
		optFillmntDet.location$=ivmItemWhse.location$
		optFillmntDet.created_user$=sysinfo.user_id$
		optFillmntDet.created_date$=date(0:"%Yd%Mz%Dz")
		optFillmntDet.created_time$=date(0:"%Hz%mz")
		optFillmntDet.trans_status$="E"
		optFillmntDet.qty_shipped=opeOrdDet.qty_shipped
		optFillmntDet.qty_picked=0
		optFillmntDet.conv_factor=opeOrdDet.conv_factor
		writerecord(optFillmntDet_dev)optFillmntDet$
	wend

rem --- Relaunch form with all the initialized data
	rec_key$=optFillmntHdr.firm_id$+optFillmntHdr.trans_status$+optFillmntHdr.ar_type$+optFillmntHdr.customer_id$+optFillmntHdr.order_no$+optFillmntHdr.ar_inv_no$
	callpoint!.setStatus("RECORD:["+rec_key$+"]")

[[OPT_FILLMNTHDR.AR_SHIP_VIA.AVAL]]
rem --- Hold onto ar_ship_via for use in opt_carthdr
	callpoint!.setDevObject("ar_ship_via",callpoint!.getUserInput())

[[OPT_FILLMNTHDR.ASHO]]
rem --- Get grid control on each tab
	Picking$=Translate!.getTranslation("DDM_TABLE_TABG-OPT_FILLMNTHDR-01-DD_ATTR_TABG")
	Packing_and_Shipping$=Translate!.getTranslation("DDM_TABLE_TABG-OPT_FILLMNTHDR-02-DD_ATTR_TABG")
	tabCtrl!=Form!.getControl(num(stbl("+TAB_CTL")))
	numTabs=tabCtrl!.getNumTabs()
	for i=0 to numTabs-1
		if pos(tabCtrl!.getTitleAt(i)=Picking$)=1 then
			pickTab!=tabCtrl!.getControlAt(i)
			callpoint!.setDevObject("pickTabIndex",i)
			callpoint!.setDevObject("pickGrid",pickTab!.getControl(num(stbl("+GRID_CTL"))+100*(i+1)))
		endif
		if pos(tabCtrl!.getTitleAt(i)=Packing_and_Shipping$)=1 then
			packShipTab!=tabCtrl!.getControlAt(i)
			callpoint!.setDevObject("packShipTabIndex",i)
			callpoint!.setDevObject("packShipGrid",packShipTab!.getControl(num(stbl("+GRID_CTL"))+100*(i+1)))
		endif
	next i

rem --- Set callback for a tab being selected so can refresh display if a new OPT_CARTHDR record was added via Pick Item button
	tabCtrl!.setCallback(BBjTabCtrl.ON_TAB_SELECT,"custom_event")

[[OPT_FILLMNTHDR.AWRI]]
rem --- Need to refresh display if a new OPT_CARTHDR record was added via Pick Item button (also see ACUS)
	if callpoint!.getDevObject("refreshRecord") then
		optFillmntHdr_key$=callpoint!.getRecordKey()
		callpoint!.setStatus("RECORD:["+optFillmntHdr_key$+"]")
		callpoint!.setDevObject("refreshRecord",0)
	endif

[[OPT_FILLMNTHDR.BDEL]]
rem --- Update qty_commit for deleted inventoried lot/serial numbers, but not for the item itself.
	optFillmntDet_dev=fnget_dev("OPT_FILLMNTDET")
	dim optFillmntDet$:fnget_tpl$("OPT_FILLMNTDET")
	optFillmntLsDet_dev=fnget_dev("OPT_FILLMNTLSDET")
	dim optFillmntLsDet$:fnget_tpl$("OPT_FILLMNTLSDET")
	ivmItemMast_dev=fnget_dev("IVM_ITEMMAST")
	dim ivmItemMast$:fnget_tpl$("IVM_ITEMMAST")
	opeOrdLsDet_dev=fnget_dev("OPE_ORDLSDET")
	optFillmntHdr_key$=callpoint!.getRecordKey()
	read (optFillmntDet_dev,key=optFillmntHdr_key$,knum="AO_STATUS",dom=*next)
	while 1
		optFillMntDet_key$=key(optFillmntDet_dev,end=*break)
		if pos(optFillmntHdr_key$=optFillMntDet_key$)<>1 then break
		readrecord(optFillmntDet_dev)optFillmntDet$

		read(optFillmntLsDet_dev,key=optFillMntDet_key$,knum="AO_STATUS",dom=*next)
		while 1
			optFillMntLsDet_key$=key(optFillmntLsDet_dev,knum="AO_STATUS",end=*break)
			if pos(optFillmntDet_key$=optFillMntLsDet_key$)<>1 then break
			remove_key$=key(optFillmntLsDet_dev,knum="PRIMARY")
			readrecord(optFillmntLsDet_dev,knum="AO_STATUS")optFillmntLsDet$

			rem --- Do Not uncommit if lot/serial number was committed in Order Entry
			if optFillmntLsDet.oe_committed$<>"Y" then
				rem --- Is this an inventoried lot/serial item?
				item$=optFillmntDet.item_id$
				findrecord (ivmItemMast_dev,key=firm_id$+item$,dom=*next)ivmItemMast$
				if ivmItemMast$.inventoried$="Y" then
					status=999
					call stbl("+DIR_PGM")+"ivc_itemupdt.aon::init",err=*next,chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
					if status then exitto std_exit

					rem --- Need to uncommit deleted inventoried lot/serial numbers, but leave the item committed.
					items$[1]=optFillmntDet.warehouse_id$
					items$[2]=optFillmntDet.item_id$
					items$[3]=optFillmntLsDet.lotser_no$
					refs[0]=optFillmntLsDet.qty_shipped
					action$="UC"
					call stbl("+DIR_PGM")+"ivc_itemupdt.aon",action$,chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
					items$[3]=""
					action$="OE"
					call stbl("+DIR_PGM")+"ivc_itemupdt.aon",action$,chan[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
				endif
			endif

			remove(optFillmntLsDet_dev,key=remove_key$)
		wend
	wend

rem wgh ... 10304 ... All carton records need to be deleted when the Order Fulfillment record is deleted

[[OPT_FILLMNTHDR.BREX]]
rem --- Skip warnings if record was deleted
	if callpoint!.getDevObject("recordDeleted") then break

rem --- Are there any items that weren't picked completely
	pickGrid!=callpoint!.getDevObject("pickGrid")
	picked_col=callpoint!.getDevObject("picked_col")
	shipped_col=callpoint!.getDevObject("shipped_col")

	gridRows=pickGrid!.getNumRows()
	if gridRows<2 then break
	pickedOK=1
	dropshipMap!=callpoint!.getDevObject("dropshipMap")
	linetypeMap!=callpoint!.getDevObject("linetypeMap")
	for row=0 to gridRows-2
		qty_picked=num(pickGrid!.getCellText(row,picked_col))
		ship_qty=num(pickGrid!.getCellText(row,shipped_col))
		if qty_picked<>ship_qty and dropshipMap!.get(i)<>"Y" and pos(linetypeMap!.get(i)="MO")=0 then
			pickedOK=0
			break
		endif
	next row

	if !pickedOK then
		tabCtrl!=Form!.getControl(num(stbl("+TAB_CTL")))
		tabCtrl!.setSelectedIndex(callpoint!.getDevObject("pickTabIndex"))

		msg_id$ = "OP_PICK_QTY_BAD"
		gosub disp_message
		if msg_opt$="N"
			pickGrid!.setSelectedCell(row,picked_col)
			callpoint!.setStatus("ABORT-ACTIVATE")
			break
		endif
	endif

[[OPT_FILLMNTHDR.BSHO]]
rem --- Open needed files
	num_files=12
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	
	open_tables$[1]="OPE_ORDHDR",  open_opts$[1]="OTA"
	open_tables$[2]="OPE_ORDDET",  open_opts$[2]="OTA"
	open_tables$[3]="OPE_ORDLSDET",  open_opts$[3]="OTA"
	open_tables$[4]="OPT_FILLMNTDET",  open_opts$[4]="OTA"
	open_tables$[5]="OPT_FILLMNTLSDET",  open_opts$[5]="OTA"
	open_tables$[6]="OPT_CARTHDR",  open_opts$[6]="OTA"
	open_tables$[7]="IVS_PARAMS",   open_opts$[7]="OTA"
	open_tables$[8]="IVM_ITEMMAST",   open_opts$[8]="OTA"
	open_tables$[9]="IVM_ITEMWHSE",   open_opts$[9]="OTA"
	open_tables$[10]="IVM_LSMASTER",   open_opts$[10]="OTA"
	open_tables$[11]="OPC_LINECODE",   open_opts$[11]="OTA"
	open_tables$[12]="ARC_SHIPVIACODE",   open_opts$[12]="OTA"

	gosub open_tables

rem --- Set up Lot/Serial button
	dim ivs01a$:open_tpls$[7]
	read record (num(open_chans$[7]), key=firm_id$+"IV00") ivs01a$
	switch pos(ivs01a.lotser_flag$="LS")
		case 1; callpoint!.setOptionText("LENT",Translate!.getTranslation("AON_LOT_ENTRY")); break
		case 2; callpoint!.setOptionText("LENT",Translate!.getTranslation("AON_SERIAL_ENTRY")); break
		case default; break
	swend
	callpoint!.setOptionEnabled("LENT",0)
	callpoint!.setDevObject("lotser_flag",ivs01a.lotser_flag$)

rem --- Pack Carton button starts disabled
	callpoint!.setOptionEnabled("PACK",0)

rem --- Initializations
	callpoint!.setDevObject("recordDeleted",0)

[[OPT_FILLMNTHDR.BWRI]]
rem --- Initialize RTP modified fields for modified existing records
	if callpoint!.getRecordMode()="C" then
		rem --- For immediate write forms must compare initial record to current record to see if modified.
		dim initial_rec_data$:fattr(rec_data$)
		initial_rec_data$=callpoint!.getDevObject("initial_rec_data$")
		if callpoint!.getColumnData("OPT_FILLMNTHDR.PRINT_STATUS")="Y" then
			callpoint!.setColumnData("OPT_FILLMNTHDR.REPRINT_FLAG","Y",1)
			rec_data.reprint_flag$="Y"
		endif
		if rec_data$<>initial_rec_data$ then
			rec_data.mod_user$=sysinfo.user_id$
			rec_data.mod_date$=date(0:"%Yd%Mz%Dz")
			rec_data.mod_time$=date(0:"%Hz%mz")
			callpoint!.setDevObject("initial_rec_data$",rec_data$)
		endif
	endif

[[OPT_FILLMNTHDR.ORDER_NO.AVAL]]
rem --- Validate this is an existing open Order (not Quote) with a printed Picking List
	orderNo$=callpoint!.getUserInput()
	ar_type$=callpoint!.getColumnData("OPT_FILLMNTHDR.AR_TYPE")
	customer_id$=callpoint!.getColumnData("OPT_FILLMNTHDR.CUSTOMER_ID")
	
	opeOrdHdr_dev=fnget_dev("OPE_ORDHDR")
	dim opeOrdHdr$:fnget_tpl$("OPE_ORDHDR")
	call stbl("+DIR_SYP")+"bac_key_template.bbj","OPT_INVHDR","PRIMARY",key_tpl$,rd_table_chans$[all],status$
	dim opeOrdHdr_key$:key_tpl$
	opeOrdHdr_key.firm_id$=firm_id$
	opeOrdHdr_key.ar_type$=ar_type$
	opeOrdHdr_key.customer_id$=customer_id$
	opeOrdHdr_key.order_no$=orderNo$
	opeOrdHdr_key.ar_inv_no$=""

	rem --- Use of ORDER_NO_LK Element Type guarantees this is an existing open Order or Quote
	readrecord(opeOrdHdr_dev,key=opeOrdHdr_key$,knum="PRIMARY",dom=*next)opeOrdHdr$

	rem --- Must be an Order, not a Quote
	if opeOrdHdr.invoice_type$<>"S" then
		msg_id$ = "OP_NOT_QUOTES"
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif

	rem --- Picking List must have been printed with no pending reprints
	if opeOrdHdr.print_status$<>"Y" or opeOrdHdr.reprint_flag$="Y" then
		msg_id$ = "OP_PICK_LST_REQUIRED"
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif



