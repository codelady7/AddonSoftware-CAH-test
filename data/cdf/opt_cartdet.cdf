[[OPT_CARTDET.AGDR]]
rem --- Disable display only columns
	packShipGrid!=callpoint!.getDevObject("packShipGrid")
	itemId_col=callpoint!.getDevObject("itemId_col")
	packShipGrid!.setColumnEditable(itemId_col,0)
	warehouseId_col=callpoint!.getDevObject("warehouseId_col")
	packShipGrid!.setColumnEditable(warehouseId_col,0)
	orderMemo_col=callpoint!.getDevObject("orderMemo_col")
	packShipGrid!.setColumnEditable(orderMemo_col,0)

[[OPT_CARTDET.AGRN]]
rem --- Disable display only columns
	row=callpoint!.getValidationRow()
	callpoint!.setColumnEnabled(row,"OPT_CARTDET.ITEM_ID",0)
	callpoint!.setColumnEnabled(row,"OPT_CARTDET.WAREHOUSE_ID",0)
	callpoint!.setColumnEnabled(row,"OPT_CARTDET.ORDER_MEMO",0)

[[OPT_CARTDET.AREC]]
rem --- Initialize new record
	warehouse_id$=callpoint!.getDevObject("warehouse_id")
	callpoint!.setColumnData("OPT_CARTDET.WAREHOUSE_ID",warehouse_id$,1)
	item_id$=callpoint!.getDevObject("item_id")
	callpoint!.setColumnData("OPT_CARTDET.ITEM_ID",item_id$,1)
	order_memo$=callpoint!.getDevObject("order_memo")
	callpoint!.setColumnData("OPT_CARTDET.ORDER_MEMO",order_memo$,1)
	um_sold$=callpoint!.getDevObject("um_sold")
	callpoint!.setColumnData("OPT_CARTDET.UM_SOLD",um_sold$,1)

rem --- Initialize RTP trans_status and created fields
	rem --- TRANS_STATUS set to "E" via form Preset Value
	callpoint!.setColumnData("OPT_CARTDET.CREATED_USER",sysinfo.user_id$)
	callpoint!.setColumnData("OPT_CARTDET.CREATED_DATE",date(0:"%Yd%Mz%Dz"))
	callpoint!.setColumnData("OPT_CARTDET.CREATED_TIME",date(0:"%Hz%mz"))

[[OPT_CARTDET.BSHO]]
rem --- Get and hold on to column positions
	packShipGrid!=callpoint!.getDevObject("packShipGrid")

	itemId_hdr$=callpoint!.getTableColumnAttribute("OPT_CARTDET.ITEM_ID","LABS")
	itemId_col=util.getGridColumnNumber(packShipGrid!,itemId_hdr$)
	callpoint!.setDevObject("itemId_col",itemId_col)

	warehouseId_hdr$=callpoint!.getTableColumnAttribute("OPT_CARTDET.WAREHOUSE_ID","LABS")
	warehouseId_col=util.getGridColumnNumber(packShipGrid!,warehouseId_hdr$)
	callpoint!.setDevObject("warehouseId_col",warehouseId_col)

	orderMemo_hdr$=callpoint!.getTableColumnAttribute("OPT_CARTDET.ORDER_MEMO","LABS")
	orderMemo_col=util.getGridColumnNumber(packShipGrid!,orderMemo_hdr$)
	callpoint!.setDevObject("orderMemo_col",orderMemo_col)

[[OPT_CARTDET.CARTON_NO.AVAL]]
rem --- Create new OPT_CARTHDR record if one doesn't already exist for this CARTON_NO 
	call stbl("+DIR_SYP")+"bac_key_template.bbj","OPT_CARTDET","AO_STATUS",key_tpl$,table_chans$[all],status$
	dim optCartDet_keyPrefix$:key_tpl$
	optCartDet_keyPrefix$=callpoint!.getKeyPrefix()

	optCartHdr_dev=fnget_dev("OPT_CARTHDR")
	dim optCartHdr$:fnget_tpl$("OPT_CARTHDR")
	ar_type$=optCartDet_keyPrefix.ar_type$
	customer_id$=optCartDet_keyPrefix.customer_id$
	order_no$=optCartDet_keyPrefix.order_no$
	ar_inv_no$=optCartDet_keyPrefix.ar_inv_no$
	carton_no$=pad(callpoint!.getUserInput(),len(optCartHdr.carton_no$))
	optCartHdr_key$=firm_id$+"E"+ar_type$+customer_id$+order_no$+ar_inv_no$+carton_no$
	readrecord(optCartHdr_dev,key=optCartHdr_key$,knum="AO_STATUS",dom=*next)optCartHdr$
	if cvs(optCartHdr.customer_id$,2)="" then
		rem --- Create new OPT_CARTHDR record for this CARTON_NO
		optCartHdr.firm_id$=firm_id$
		optCartHdr.ar_type$=ar_type$
		optCartHdr.customer_id$=customer_id$
		optCartHdr.order_no$=order_no$
		optCartHdr.ar_inv_no$=ar_inv_no$
		optCartHdr.carton_no$=callpoint!.getUserInput()
		optCartHdr.trans_status$="E"
		optCartHdr.created_user$=sysinfo.user_id$
		optCartHdr.created_date$=date(0:"%Yd%Mz%Dz")
		optCartHdr.created_time$=date(0:"%Hz%mz")
		optCartHdr.weight=0
		optCartHdr.freight_amt=0

		rem --- Initialize new OPT_CARTHDR record with the ARC_SHIPVIACODE record for the OPT_FILLMNTHDR.AR_SHIP_VIA.
		arcShipViaCode_dev=fnget_dev("ARC_SHIPVIACODE")
		dim arcShipViaCode$:fnget_tpl$("ARC_SHIPVIACODE")
		ar_ship_via$=callpoint!.getDevObject("ar_ship_via")
		readrecord(arcShipViaCode_dev,key=firm_id$+ar_ship_via$,dom=*next)arcShipViaCode$
		optCartHdr.carrier_code$=arcShipViaCode.carrier_code$
		optCartHdr.scac_code$=arcShipViaCode.scac_code$

		writerecord(optCartHdr_dev)optCartHdr$
		callpoint!.setDevObject("refreshRecord",1)
	endif

[[OPT_CARTDET.QTY_PACKED.AVAL]]
rem --- QTY_PACKED cannot be negative
	qty_packed=num(callpoint!.getUserInput())
	previous_qtyPacked=num(callpoint!.getColumnData("OPT_CARTDET.QTY_PACKED"))
	if qty_packed=previous_qtyPacked then break
	if qty_packed<0 then
		msg_id$ = "OP_PACKED_NEGATIVE"
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- QTY_PACKED cannot be greater than the remaining number that still need to be packed.
	qty_picked=num(callpoint!.getDevObject("qty_picked"))
	unpackedQty=callpoint!.getDevObject("unpackedQty")
	if qty_packed>unpackedQty then
		msg_id$ = "OP_PACK_REMAINING"
		dim msg_tokens$[3]
		msg_tokens$[1]=str(qty_picked-unpackedQty)
		msg_tokens$[2]=str(qty_picked)
		msg_tokens$[3]=str(unpackedQty)
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif

[[OPT_CARTDET.QTY_PACKED.BINP]]
rem --- Default QTY_PACKED to the remaining number that still need to be packed.
	alreadyPacked=-num(callpoint!.getColumnData("OPT_CARTDET.QTY_PACKED"))
	dim optCartDet$:fnget_tpl$("OPT_CARTDET")
	for i=0 to GridVect!.size()-1
		optCartDet$=GridVect!.getItem(i)
		alreadyPacked=alreadyPacked+optCartDet.qty_packed
	next i

	qty_picked=num(callpoint!.getDevObject("qty_picked"))
	unpackedQty=qty_picked-alreadyPacked
	callpoint!.setDevObject("unpackedQty",unpackedQty)
	callpoint!.setColumnData("OPT_CARTDET.QTY_PACKED",str(unpackedQty),1)

[[OPT_CARTDET.<CUSTOM>]]
rem ==========================================================================
rem 	Use util object
rem ==========================================================================
	use ::ado_util.src::util



