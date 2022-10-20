[[OPT_CARTDET.AGDR]]
rem --- Initialize <<DISPLAY>> fields
	carton_no$=callpoint!.getColumnData("OPT_CARTDET.CARTON_NO")
	callpoint!.setColumnData("<<DISPLAY>>.CARTON_DSP",carton_no$,1)

rem --- Initialize last warehouse entered
	warehouse_id$=callpoint!.getColumnData("OPT_CARTDET.WAREHOUSE_ID")
	if cvs(warehouse_id$,2)<>"" then callpoint!.setDevObject("lastWhse",warehouse_id$)

rem --- Provide visual warning when quantity packed is less than the remaining number that still need to be packed
	qty_packed=num(callpoint!.getColumnData("OPT_CARTDET.QTY_PACKED"))
	gosub getPickedQty
	gosub getUnpackedQty
	packCartonGrid!=callpoint!.getDevObject("packCartonGrid")
	curr_row=num(callpoint!.getValidationRow())
	packed_col=callpoint!.getDevObject("packed_col")

	if qty_packed<unpackedQty then
		packCartonGrid!.setCellFont(curr_row,packed_col,callpoint!.getDevObject("boldFont"))
		packCartonGrid!.setCellForeColor(curr_row,packed_col,callpoint!.getDevObject("redColor"))
	else
		packCartonGrid!.setCellFont(curr_row,packed_col,callpoint!.getDevObject("plainFont"))
		packCartonGrid!.setCellForeColor(curr_row,packed_col,callpoint!.getDevObject("blackColor"))
	endif

[[OPT_CARTDET.AGDS]]
rem --- Skip if the grid is empty
	if GridVect!.size()=0 then break

rem --- Provide visual warning when quantity packed is less than the remaining number that still need to be packed
	optFillmntDet_dev=fnget_dev("OPT_FILLMNTDET")
	dim optFillmntDet$:fnget_tpl$("OPT_FILLMNTDET")
	dim optCartDet$:fnget_tpl$("OPT_CARTDET")
	optCartDet2_dev=fnget_dev("OPT_CARTDET2")
	dim optCartDet2$:fnget_tpl$("OPT_CARTDET2")
	ar_type$=callpoint!.getColumnData("OPT_CARTDET.AR_TYPE")
	customer_id$=callpoint!.getColumnData("OPT_CARTDET.CUSTOMER_ID")
	order_no$=callpoint!.getColumnData("OPT_CARTDET.ORDER_NO")
	ar_inv_no$=callpoint!.getColumnData("OPT_CARTDET.AR_INV_NO")
	packCartonGrid!=callpoint!.getDevObject("packCartonGrid")
	packed_col=callpoint!.getDevObject("packed_col")
	for row=0 to GridVect!.size()-1
		qty_picked=0
		redim optCartDet$
		optCartDet$=GridVect!.getItem(row)
		orddet_seq_ref$=optCartDet.orddet_seq_ref$
		optFillmntDet_trip$=firm_id$+"E"+ar_type$+customer_id$+order_no$+ar_inv_no$+orddet_seq_ref$
		read(optFillmntDet_dev,key=optFillmntDet_trip$,knum="AO_STATUS_ORDDET",dom=*next)
		while 1
			optFillmntDet_key$=key(optFillmntDet_dev,end=*break)
			if pos(optFillmntDet_trip$=optFillmntDet_key$)<>1 then break
			readrecord(optFillmntDet_dev)optFillmntDet$
			qty_picked=optFillmntDet.qty_picked
			break
		wend

		alreadyPacked=0
		optCartDet2_trip$=firm_id$+"E"+ar_type$+customer_id$+order_no$+ar_inv_no$+orddet_seq_ref$
		read(optCartDet2_dev,key=optCartDet2_trip$,knum="AO_ORDDET_CART",dom=*next)
		while 1
			optCartDet2_key$=key(optCartDet2_dev,end=*break)
			if pos(optCartDet2_trip$=optCartDet2_key$)<>1 then break
			readrecord(optCartDet2_dev)optCartDet2$
			alreadyPacked=alreadyPacked+optCartDet2.qty_packed
		wend
		unpackedQty=qty_picked-alreadyPacked

		if unpackedQty>0 then
			packCartonGrid!.setCellFont(row,packed_col,callpoint!.getDevObject("boldFont"))
			packCartonGrid!.setCellForeColor(row,packed_col,callpoint!.getDevObject("redColor"))
		else
			packCartonGrid!.setCellFont(row,packed_col,callpoint!.getDevObject("plainFont"))
			packCartonGrid!.setCellForeColor(row,packed_col,callpoint!.getDevObject("blackColor"))
		endif
	next row
	read(optFillmntDet_dev,key="",knum="AO_STATUS",dom=*next)

[[OPT_CARTDET.AGRN]]
rem --- Allow skipping warehouse entry once
	callpoint!.setDevObject("skipWHCode","Y")

rem --- Enable Item Lookup button for new lines
	if callpoint!.getGridRowNewStatus(callpoint!.getValidationRow())="Y" then
		callpoint!.setOptionEnabled("ITEM",1)
	else
		callpoint!.setOptionEnabled("ITEM",0)
	endif

rem --- Disable warehouse_id, item_id, and order_memo for existing lines so they can't be changed since there is not seqence_no.
	if callpoint!.getGridRowNewStatus(callpoint!.getValidationRow())<>"Y" then
		callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"OPT_CARTDET.WAREHOUSE_ID",0)
		callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"OPT_CARTDET.ITEM_ID",0)
		callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"OPT_CARTDET.ORDER_MEMO",0)
		callpoint!.setFocus(callpoint!.getValidationRow(),"OPT_CARTDET.QTY_PACKED",0)
	endif

rem --- Get the quantity picked for this item
	if callpoint!.getGridRowNewStatus(callpoint!.getValidationRow())="Y" then
		callpoint!.setDevObject("qty_picked",0)
	else
		optFillmntDet_dev=fnget_dev("OPT_FILLMNTDET")
		dim optFillmntDet$:fnget_tpl$("OPT_FILLMNTDET")
		ar_type$=callpoint!.getColumnData("OPT_CARTDET.AR_TYPE")
		customer_id$=callpoint!.getColumnData("OPT_CARTDET.CUSTOMER_ID")
		order_no$=callpoint!.getColumnData("OPT_CARTDET.ORDER_NO")
		ar_inv_no$=callpoint!.getColumnData("OPT_CARTDET.AR_INV_NO")
		warehouse_id$=callpoint!.getColumnData("OPT_CARTDET.WAREHOUSE_ID")
		item_id$=callpoint!.getColumnData("OPT_CARTDET.ITEM_ID")
		orddet_seq_ref$=callpoint!.getColumnData("OPT_CARTDET.ORDDET_SEQ_REF")
		optFillmntDet_trip$=firm_id$+"E"+ar_type$+customer_id$+order_no$+ar_inv_no$+warehouse_id$+item_id$
		read(optFillmntDet_dev,key=optFillmntDet_trip$,knum="AO_WHSE_ITEM",dom=*next)
		while 1
			optFillmntDet_key$=key(optFillmntDet_dev,end=*break)
			if pos(optFillmntDet_trip$=optFillmntDet_key$)<>1 then break
			readrecord(optFillmntDet_dev)optFillmntDet$
			if optFillmntDet.orddet_seq_ref$<>orddet_seq_ref$ then continue
			callpoint!.setDevObject("qty_picked",optFillmntDet.qty_picked)
			break
		wend
		read(optFillmntDet_dev,key="",knum="AO_STATUS",dom=*next)
	endif

[[OPT_CARTDET.AOPT-ITEM]]
rem --- Luanch lookup for unpacked picked items
	gosub doItemLookup

[[OPT_CARTDET.AOPT-PKLS]]
rem --- Initialize grid with unpacked picked lots/serials in OPT_FILLMNTLSDET
	ar_type$=callpoint!.getColumnData("OPT_CARTDET.AR_TYPE")
	customer_id$=callpoint!.getColumnData("OPT_CARTDET.CUSTOMER_ID")
	order_no$=callpoint!.getColumnData("OPT_CARTDET.ORDER_NO")
	ar_inv_no$=callpoint!.getColumnData("OPT_CARTDET.AR_INV_NO")
	carton_no$=callpoint!.getColumnData("OPT_CARTDET.CARTON_NO")
	orddet_seq_ref$=callpoint!.getColumnData("OPT_CARTDET.ORDDET_SEQ_REF")
	optCartDet_key$=firm_id$+"E"+ar_type$+customer_id$+order_no$+ar_inv_no$+carton_no$+orddet_seq_ref$

	optCartLsDet_dev=fnget_dev("OPT_CARTLSDET")
	dim optCartLsDet$:fnget_tpl$("OPT_CARTLSDET")
	read(optCartLsDet_dev,key=optCartDet_key$,knum="AO_STATUS",dom=*next)
	optCartLsDet_key$=key(optCartLsDet_dev,end=*next)
	if pos(optCartDet_key$=optCartLsDet_key$)=1 then
		rem --- Grid already initialized
	else
		rem --- Ask if they want to pack all remaining unpacked lot/serial numbers picked for this item
		msg_id$ = "OP_PACK_UNPACKED"
		gosub disp_message
		if msg_opt$="Y" then
			rem --- Initialize grid
			optCartLsDet2_dev=fnget_dev("OPT_CARTLSDET2")
			dim optCartLsDet2$:fnget_tpl$("OPT_CARTLSDET2")
			optFillmntLsDet_dev=fnget_dev("OPT_FILLMNTLSDET")
			dim optFillmntLsDet$:fnget_tpl$("OPT_FILLMNTLSDET")
			optFillmntDet_key$=firm_id$+"E"+ar_type$+customer_id$+order_no$+ar_inv_no$+orddet_seq_ref$

			read(optFillmntLsDet_dev,key=optFillmntDet_key$,knum="AO_STATUS",dom=*next)
			while 1
				optFillmntLsDet_key$=key(optFillmntLsDet_dev,end=*break)
				if pos(optFillmntDet_key$=optFillmntLsDet_key$)<>1 then break
				readrecord(optFillmntLsDet_dev)optFillmntLsDet$

				rem --- Skip if already fully packed in other cartoons
				alreadyPacked=0
				optCartLsDet2_trip$=firm_id$+"E"+ar_type$+customer_id$+order_no$+ar_inv_no$+orddet_seq_ref$
				read(optCartLsDet2_dev,key=optCartLsDet2_trip$,knum="AO_ORDDET_CART",dom=*next)
				while 1
					optCartLsDet2_key$=key(optCartLsDet2_dev,end=*break)
					if pos(optCartLsDet2_trip$=optCartLsDet2_key$)<>1 then break
					readrecord(optCartLsDet2_dev)optCartLsDet2$
					if optCartLsDet2.lotser_no$<>optFillmntLsDet.lotser_no$ then continue
					alreadyPacked=alreadyPacked+optCartLsDet2.qty_packed
				wend
				if alreadyPacked>=optFillmntLsDet.qty_picked then continue

				seqNo=seqNo+1
				redim optCartLsDet$
				optCartLsDet.firm_id$=firm_id$
				optCartLsDet.ar_type$=ar_type$
				optCartLsDet.customer_id$=customer_id$
				optCartLsDet.order_no$=order_no$
				optCartLsDet.ar_inv_no$=ar_inv_no$
				optCartLsDet.carton_no$=carton_no$
				optCartLsDet.orddet_seq_ref$=orddet_seq_ref$
				optCartLsDet.sequence_no$=str(seqNo,"000")
				optCartLsDet.lotser_no$=optFillmntLsDet.lotser_no$
				optCartLsDet.created_user$=sysinfo.user_id$
				optCartLsDet.created_date$=date(0:"%Yd%Mz%Dz")
				optCartLsDet.created_time$=date(0:"%Hz%mz")
				optCartLsDet.trans_status$="E"
				optCartLsDet.qty_packed=optFillmntLsDet.qty_picked-alreadyPacked
				writerecord(optCartLsDet_dev)optCartLsDet$
			wend
		endif
	endif

rem --- Launch Packing Carton Lot/Serial Detail grid

	optCartLsDet_key$=firm_id$+"E"+ar_type$+customer_id$+order_no$+ar_inv_no$+carton_no$+orddet_seq_ref$

	call stbl("+DIR_SYP") + "bam_run_prog.bbj", 
:		"OPT_CARTLSDET", 
:		stbl("+USER_ID"), 
:		"MNT" ,
:		optCartLsDet_key$, 
:		table_chans$[all], 
:		dflt_data$[all]

	callpoint!.setStatus("ACTIVATE")

rem --- Has the total quantity packed changed?
	start_qty_packed=num(callpoint!.getColumnData("OPT_CARTDET.QTY_PACKED"))
	total_packed=callpoint!.getDevObject("total_packed")
	if total_packed<>start_qty_packed then
		callpoint!.setColumnData("OPT_CARTDET.QTY_PACKED",str(total_packed),1)
		callpoint!.setStatus("MODIFIED")
		callpoint!.setFocus(callpoint!.getValidationRow(),"OPT_CARTDET.QTY_PACKED",1)

		rem --- Provide visual warning when quantity packed is less than the remaining number that still need to be packed
		gosub getUnpackedQty
		packCartonGrid!=callpoint!.getDevObject("packCartonGrid")
		curr_row=num(callpoint!.getValidationRow())
		packed_col=callpoint!.getDevObject("packed_col")

rem wgh ... 10304 ... need to set color here
		if total_packed<unpackedQty then
			packCartonGrid!.setCellFont(curr_row,packed_col,callpoint!.getDevObject("boldFont"))
			packCartonGrid!.setCellForeColor(curr_row,packed_col,callpoint!.getDevObject("redColor"))
		else
			packCartonGrid!.setCellFont(curr_row,packed_col,callpoint!.getDevObject("plainFont"))
			packCartonGrid!.setCellForeColor(curr_row,packed_col,callpoint!.getDevObject("blackColor"))
		endif
	endif

[[OPT_CARTDET.AREC]]
rem ---Initialize fields needed to pack this carton
	call stbl("+DIR_SYP")+"bac_key_template.bbj","OPT_CARTDET","AO_STATUS",key_tpl$,table_chans$[all],status$
	dim optCartDet_keyPrefix$:key_tpl$
	optCartDet_keyPrefix$=callpoint!.getKeyPrefix()
	callpoint!.setColumnData("OPT_CARTDET.AR_TYPE",optCartDet_keyPrefix.ar_type$)
	callpoint!.setColumnData("OPT_CARTDET.CUSTOMER_ID",optCartDet_keyPrefix.customer_id$)
	callpoint!.setColumnData("OPT_CARTDET.ORDER_NO",optCartDet_keyPrefix.order_no$)
	callpoint!.setColumnData("OPT_CARTDET.AR_INV_NO",optCartDet_keyPrefix.ar_inv_no$)
	callpoint!.setColumnData("OPT_CARTDET.CARTON_NO",optCartDet_keyPrefix.carton_no$)
	callpoint!.setColumnData("<<DISPLAY>>.CARTON_DSP",optCartDet_keyPrefix.carton_no$,1)

rem --- Initialize RTP trans_status and created fields
	rem --- TRANS_STATUS set to "E" via form Preset Value
	callpoint!.setColumnData("OPT_CARTDET.CREATED_USER",sysinfo.user_id$)
	callpoint!.setColumnData("OPT_CARTDET.CREATED_DATE",date(0:"%Yd%Mz%Dz"))
	callpoint!.setColumnData("OPT_CARTDET.CREATED_TIME",date(0:"%Hz%mz"))

rem ---Pack Lot/Serial button starts disabled
	callpoint!.setOptionEnabled("PKLS",0)

rem --- Allow skipping warehouse entry once
	callpoint!.setDevObject("skipWHCode","Y")

rem --- Initialize needed devObjects
	callpoint!.setDevObject("qty_picked",0)

[[OPT_CARTDET.ASHO]]
rem --- Set Lot/Serial button up properly
	switch pos(callpoint!.getDevObject("lotser_flag")="LS")
		case 1; callpoint!.setOptionText("PKLS",Translate!.getTranslation("AON_PACK")+" "+Translate!.getTranslation("AON_LOT")); break
		case 2; callpoint!.setOptionText("PKLS",Translate!.getTranslation("AON_PACK")+" "+Translate!.getTranslation("AON_SERIAL")); break
		case default; callpoint!.setOptionEnabled("PKLS",0); break
	swend

rem --- Get and hold on to column for qty_packed
	packCartonGrid!=Form!.getControl(num(stbl("+GRID_CTL")))
	callpoint!.setDevObject("packCartonGrid",packCartonGrid!)
	packed_hdr$=callpoint!.getTableColumnAttribute("OPT_CARTDET.QTY_PACKED","LABS")
	packed_col=util.getGridColumnNumber(packCartonGrid!,packed_hdr$)
	callpoint!.setDevObject("packed_col",packed_col)

[[OPT_CARTDET.BEND]]
rem --- Skip if the grid is empty
	if GridVect!.size()=0 then break

rem --- Warn if quantity packed for an item is less than the quantity picked for that item.
	optFillmntDet_dev=fnget_dev("OPT_FILLMNTDET")
	dim optFillmntDet$:fnget_tpl$("OPT_FILLMNTDET")
	dim optCartDet$:fnget_tpl$("OPT_CARTDET")
	optCartDet2_dev=fnget_dev("OPT_CARTDET2")
	dim optCartDet2$:fnget_tpl$("OPT_CARTDET2")
	ar_type$=callpoint!.getColumnData("OPT_CARTDET.AR_TYPE")
	customer_id$=callpoint!.getColumnData("OPT_CARTDET.CUSTOMER_ID")
	order_no$=callpoint!.getColumnData("OPT_CARTDET.ORDER_NO")
	ar_inv_no$=callpoint!.getColumnData("OPT_CARTDET.AR_INV_NO")
	for row=0 to GridVect!.size()-1
		if callpoint!.getGridRowDeleteStatus(row)="Y" then continue

		qty_picked=0
		redim optCartDet$
		optCartDet$=GridVect!.getItem(row)
		orddet_seq_ref$=optCartDet.orddet_seq_ref$
		optFillmntDet_trip$=firm_id$+"E"+ar_type$+customer_id$+order_no$+ar_inv_no$+orddet_seq_ref$
		read(optFillmntDet_dev,key=optFillmntDet_trip$,knum="AO_STATUS_ORDDET",dom=*next)
		while 1
			optFillmntDet_key$=key(optFillmntDet_dev,end=*break)
			if pos(optFillmntDet_trip$=optFillmntDet_key$)<>1 then break
			readrecord(optFillmntDet_dev)optFillmntDet$
			qty_picked=optFillmntDet.qty_picked
			break
		wend

		alreadyPacked=0
		optCartDet2_trip$=firm_id$+"E"+ar_type$+customer_id$+order_no$+ar_inv_no$+orddet_seq_ref$
		read(optCartDet2_dev,key=optCartDet2_trip$,knum="AO_ORDDET_CART",dom=*next)
		while 1
			optCartDet2_key$=key(optCartDet2_dev,end=*break)
			if pos(optCartDet2_trip$=optCartDet2_key$)<>1 then break
			readrecord(optCartDet2_dev)optCartDet2$
			alreadyPacked=alreadyPacked+optCartDet2.qty_packed
		wend
		unpackedQty=qty_picked-alreadyPacked

		if unpackedQty>0 then
			msg_id$ = "OP_PACK_QTY_BAD"
			gosub disp_message
			if msg_opt$="N"
				packCartonGrid!=callpoint!.getDevObject("packCartonGrid")
				packed_col=callpoint!.getDevObject("packed_col")
				packCartonGrid!.setSelectedCell(row,packed_col)
				callpoint!.setStatus("ABORT-ACTIVATE")
				break
			else
				break
			endif
		endif
	next row
	read(optFillmntDet_dev,key="",knum="AO_STATUS",dom=*next)

[[OPT_CARTDET.BSHO]]
rem --- Initialize last warehouse entered
	callpoint!.setDevObject("lastWhse","")

[[OPT_CARTDET.BWRI]]
rem --- Don't write if item or non-stock have not been entered.
	if cvs(callpoint!.getColumnData("OPT_CARTDET.ORDDET_SEQ_REF"),2)="" then
		callpoint!.setFocus(num(callpoint!.getValidationRow()),"OPT_CARTDET.ITEM_ID",1)
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- Initialize RTP modified fields for modified existing records
	if callpoint!.getGridRowNewStatus(callpoint!.getValidationRow())<>"Y" then
		callpoint!.setColumnData("OPT_CARTDET.MOD_USER", sysinfo.user_id$)
		callpoint!.setColumnData("OPT_CARTDET.MOD_DATE", date(0:"%Yd%Mz%Dz"))
		callpoint!.setColumnData("OPT_CARTDET.MOD_TIME", date(0:"%Hz%mz"))
	endif

[[<<DISPLAY>>.CARTON_DSP.AVAL]]
rem --- Need to use <<DISPLAY>> field for CARTON_NO because it is part of the key to the primary table OPT_CARTHDR.

[[OPT_CARTDET.ITEM_ID.AVAL]]
rem --- Skip validation if the ITEM_ID was not changed
	item_id$=callpoint!.getUserInput()
	if cvs(item_id$,2)=cvs(callpoint!.getColumnData("OPT_CARTDET.ITEM_ID"),2) then break

rem --- Verify the item is not already packed in this carton.
	gosub checkItemInCarton
	if inCarton then
		callpoint!.setColumnData("OPT_CARTDET.ITEM_ID","")
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- Verify the item was picked for this order from the warehouse
	validItem=0
	optFillmntDet_dev=fnget_dev("OPT_FILLMNTDET")
	dim optFillmntDet$:fnget_tpl$("OPT_FILLMNTDET")
	item_id$=pad(item_id$,len(optFillmntDet.item_id$))
	ar_type$=callpoint!.getColumnData("OPT_CARTDET.AR_TYPE")
	customer_id$=callpoint!.getColumnData("OPT_CARTDET.CUSTOMER_ID")
	order_no$=callpoint!.getColumnData("OPT_CARTDET.ORDER_NO")
	ar_inv_no$=callpoint!.getColumnData("OPT_CARTDET.AR_INV_NO")
	warehouse_id$=callpoint!.getColumnData("OPT_CARTDET.WAREHOUSE_ID")
	optFillmntDet_trip$=firm_id$+"E"+ar_type$+customer_id$+order_no$+ar_inv_no$+warehouse_id$+item_id$
	read(optFillmntDet_dev,key=optFillmntDet_trip$,knum="AO_WHSE_ITEM",dom=*next)
	while 1
		optFillmntDet_key$=key(optFillmntDet_dev,end=*break)
		if pos(optFillmntDet_trip$=optFillmntDet_key$)<>1 then break
		readrecord(optFillmntDet_dev)optFillmntDet$
		validItem=1
		break
	wend
	read(optFillmntDet_dev,key="",knum="AO_STATUS",dom=*next)
	if validItem then
		callpoint!.setColumnData("OPT_CARTDET.ITEM_ID",item_id$)
		callpoint!.setColumnData("OPT_CARTDET.ORDDET_SEQ_REF",optFillmntDet.orddet_seq_ref$)
		callpoint!.setColumnData("OPT_CARTDET.UM_SOLD",optFillmntDet.um_sold$,1)
		callpoint!.setDevObject("qty_picked",optFillmntDet.qty_picked)

		rem --- Disable and skip ORDER_MEMO
		if cvs(item_id$,2)<>"" then
			callpoint!.setColumnData("OPT_CARTDET.ORDER_MEMO",optFillmntDet.order_memo$,1)
			callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"OPT_CARTDET.ORDER_MEMO",0)
			callpoint!.setFocus(num(callpoint!.getValidationRow()),"OPT_CARTDET.QTY_PACKED",1)
		endif
	else
		msg_id$ = "OP_ITEM_NOT_PICKED"
		dim msg_tokens$[2]
		msg_tokens$[1]=cvs(item_id$,2)
		msg_tokens$[2]=callpoint!.getColumnData("OPT_CARTDET.WAREHOUSE_ID")
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif

[[OPT_CARTDET.ITEM_ID.BINQ]]
rem --- Luanch lookup for unpacked picked items
	gosub doItemLookup
	callpoint!.setStatus("ACTIVATE-ABORT")

[[OPT_CARTDET.ORDER_MEMO.AVAL]]
rem --- Skip validation if the non-stock item was not changed
	nonStock_item$=callpoint!.getUserInput()
	if cvs(nonStock_item$,2)<>"" and cvs(nonStock_item$,2)=cvs(callpoint!.getColumnData("OPT_CARTDET.ORDER_MEMO"),2) then break

rem --- Verify the non-stock item was picked for this order from the warehouse
	validNonStock=0
	optFillmntDet_dev=fnget_dev("OPT_FILLMNTDET")
	dim optFillmntDet$:fnget_tpl$("OPT_FILLMNTDET")
	ar_type$=callpoint!.getColumnData("OPT_CARTDET.AR_TYPE")
	customer_id$=callpoint!.getColumnData("OPT_CARTDET.CUSTOMER_ID")
	order_no$=callpoint!.getColumnData("OPT_CARTDET.ORDER_NO")
	ar_inv_no$=callpoint!.getColumnData("OPT_CARTDET.AR_INV_NO")
	warehouse_id$=callpoint!.getColumnData("OPT_CARTDET.WAREHOUSE_ID")
	item_id$=callpoint!.getColumnData("OPT_CARTDET.ITEM_ID")
	optFillmntDet_trip$=firm_id$+"E"+ar_type$+customer_id$+order_no$+ar_inv_no$+warehouse_id$+item_id$
	read(optFillmntDet_dev,key=optFillmntDet_trip$,knum="AO_WHSE_ITEM",dom=*next)
	while 1
		optFillmntDet_key$=key(optFillmntDet_dev,end=*break)
		if pos(optFillmntDet_trip$=optFillmntDet_key$)<>1 then break
		readrecord(optFillmntDet_dev)optFillmntDet$
		if cvs(optFillmntDet.order_memo$,2)<>cvs(nonStock_item$,2) then continue
		validNonStock=1
		break
	wend
	read(optFillmntDet_dev,key="",knum="AO_STATUS",dom=*next)
	if validNonStock then
		callpoint!.setColumnData("OPT_CARTDET.ORDDET_SEQ_REF",optFillmntDet.orddet_seq_ref$)
		callpoint!.setColumnData("OPT_CARTDET.UM_SOLD",optFillmntDet.um_sold$,1)
		callpoint!.setDevObject("qty_picked",optFillmntDet.qty_picked)
	else
		msg_id$ = "OP_NONSTK_NOT_PICKED"
		dim msg_tokens$[1]
		msg_tokens$[1]=callpoint!.getColumnData("OPT_CARTDET.WAREHOUSE_ID")
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- Verify the item is not already packed in this carton.
	gosub checkItemInCarton
	if inCarton then
		callpoint!.getColumnData("OPT_CARTDET.ORDER_MEMO")
		callpoint!.setStatus("ABORT")
		break
	endif

[[OPT_CARTDET.QTY_PACKED.AVAL]]
rem --- Enable Item Lookup button for new lines in case they haven't left the row
	if callpoint!.getGridRowNewStatus(callpoint!.getValidationRow())="Y" then
		callpoint!.setOptionEnabled("ITEM",1)
	endif

rem --- Disable Pack Lot/Serial button except for qty_packed field
	callpoint!.setOptionEnabled("PKLS",0)

rem --- Skip validation if QTY_PACKED wasn't change
	qty_packed=num(callpoint!.getUserInput())
	previous_qty=num(callpoint!.getColumnData("OPT_CARTDET.QTY_PACKED"))
	if qty_packed=previous_qty then break

rem --- QTY_PACKED cannot be negative
	if qty_packed<0 then
		msg_id$ = "OP_PACKED_NEGATIVE"
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- QTY_PACKED cannot be greater than the remaining number that still need to be packed.
	qty_picked=num(callpoint!.getDevObject("qty_picked"))
	unpackedQty=num(callpoint!.getDevObject("unpackedQty"))
	if qty_packed>unpackedQty then
		msg_id$ = "OP_PACK_REMAINING"
		dim msg_tokens$[3]
		msg_tokens$[1]=str(qty_picked-unpackedQty)
		msg_tokens$[2]=str(qty_picked)
		msg_tokens$[3]=str(unpackedQty)
		gosub disp_message

		callpoint!.setColumnData("OPT_CARTDET.QTY_PACKED",str(previous_qty),1)
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- For lot/serial items, item qty_packed must equal sum of lot/serial number qty_packed
	if callpoint!.getDevObject("lotser_item")="Y" then
		lotser_packed=0
		optCartLsDet2_dev=fnget_dev("OPT_CARTLSDET2")
		dim optCartLsDet2$:fnget_tpl$("OPT_CARTLSDET2")
		trans_status$=callpoint!.getColumnData("OPT_CARTDET.TRANS_STATUS")
		ar_type$=callpoint!.getColumnData("OPT_CARTDET.AR_TYPE")
		customer_id$=callpoint!.getColumnData("OPT_CARTDET.CUSTOMER_ID")
		order_no$=callpoint!.getColumnData("OPT_CARTDET.ORDER_NO")
		ar_inv_no$=callpoint!.getColumnData("OPT_CARTDET.AR_INV_NO")
		orddet_seq_ref$=callpoint!.getColumnData("OPT_CARTDET.ORDDET_SEQ_REF")
		carton_no$=callpoint!.getColumnData("OPT_CARTDET.CARTON_NO")
		optCartDet2_key$=firm_id$+trans_status$+ar_type$+customer_id$+order_no$+ar_inv_no$+orddet_seq_ref$+carton_no$
		read(optCartLsDet2_dev,key=optCartDet2_key$,knum="AO_ORDDET_CART",dom=*next)
		while 1
			optCartLsDet2_key$=key(optCartLsDet2_dev,end=*break)
			if pos(optCartDet2_key$=optCartLsDet2_key$)<>1 then break
			readrecord(optCartLsDet2_dev)optCartLsDet2$
			lotser_packed=lotser_packed+optCartLsDet2.qty_packed
		wend

		if qty_packed<>lotser_packed then
			msg_id$ = "OP_SUM_LOTSER_PACKED"
			dim msg_tokens$[1]
			msg_tokens$[1]=str(lotser_packed)
			gosub disp_message
			callpoint!.setStatus("ABORT")
			callpoint!.setColumnData("OPT_CARTDET.QTY_PACKED",str(lotser_packed),1)
			break
		endif
	endif

rem --- Provide visual warning when quantity packed is less than the remaining number that still need to be packed
	packCartonGrid!=callpoint!.getDevObject("packCartonGrid")
	curr_row=num(callpoint!.getValidationRow())
	packed_col=callpoint!.getDevObject("packed_col")

	if qty_packed<unpackedQty then
		packCartonGrid!.setCellFont(curr_row,packed_col,callpoint!.getDevObject("boldFont"))
		packCartonGrid!.setCellForeColor(curr_row,packed_col,callpoint!.getDevObject("redColor"))
	else
		packCartonGrid!.setCellFont(curr_row,packed_col,callpoint!.getDevObject("plainFont"))
		packCartonGrid!.setCellForeColor(curr_row,packed_col,callpoint!.getDevObject("blackColor"))
	endif

[[OPT_CARTDET.QTY_PACKED.BINP]]
rem --- Enable Pack Lot/Serial button for lot/serial items
	item_id$=callpoint!.getColumnData("OPT_CARTDET.ITEM_ID")
	gosub lot_ser_check
	if lotser_item$="Y" then
		callpoint!.setOptionEnabled("PKLS",1)
	else
		callpoint!.setOptionEnabled("PKLS",0)
	endif

rem --- For new line, default QTY_PACKED to the remaining number that still need to be packed.
	gosub getUnpackedQty
	if callpoint!.getGridRowNewStatus(callpoint!.getValidationRow())="Y" then
		if lotser_item$="Y" then
			callpoint!.setColumnData("OPT_CARTDET.QTY_PACKED",str(0),1)
		else
			callpoint!.setColumnData("OPT_CARTDET.QTY_PACKED",str(unpackedQty),1)
		endif
	endif

rem --- Disable Item Lookup botton when qty_packed has focus.
	if callpoint!.getGridRowNewStatus(callpoint!.getValidationRow())="Y" then
		callpoint!.setOptionEnabled("ITEM",0)
	endif

[[OPT_CARTDET.WAREHOUSE_ID.AVAL]]
rem --- Hold on to the last warehouse entered
	warehouse_id$=callpoint!.getUserInput()
	callpoint!.setDevObject("lastWhse",warehouse_id$)

rem --- Verify an item was picked for this order from the warehouse entered
	validWhse=0
	optFillmntDet_dev=fnget_dev("OPT_FILLMNTDET")
	dim optFillmntDet$:fnget_tpl$("OPT_FILLMNTDET")
	ar_type$=callpoint!.getColumnData("OPT_CARTDET.AR_TYPE")
	customer_id$=callpoint!.getColumnData("OPT_CARTDET.CUSTOMER_ID")
	order_no$=callpoint!.getColumnData("OPT_CARTDET.ORDER_NO")
	ar_inv_no$=callpoint!.getColumnData("OPT_CARTDET.AR_INV_NO")
	optFillmntDet_trip$=firm_id$+"E"+ar_type$+customer_id$+order_no$+ar_inv_no$+warehouse_id$
	read(optFillmntDet_dev,key=optFillmntDet_trip$,knum="AO_WHSE_ITEM",dom=*next)
	while 1
		optFillmntDet_key$=key(optFillmntDet_dev,end=*break)
		if pos(optFillmntDet_trip$=optFillmntDet_key$)<>1 then break
		validWhse=1
		break
	wend
	read(optFillmntDet_dev,key="",knum="AO_STATUS",dom=*next)
	if !validWhse then
		msg_id$ = "OP_WHSE_NOT_PICKED"
		dim msg_tokens$[1]
		msg_tokens$[1]=warehouse_id$
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif

[[OPT_CARTDET.WAREHOUSE_ID.BINP]]
rem --- If a warehouse was previously entered for this carton, use it and skip warehouse entry once.
	lastWhse$=callpoint!.getDevObject("lastWhse")
	if cvs(lastWhse$,2)<>"" then
		callpoint!.setColumnData("OPT_CARTDET.WAREHOUSE_ID",lastWhse$,1)

		rem --- Force focus on item when warehouse hasn't been skipped yet
		if callpoint!.getDevObject("skipWHCode") = "Y" then
			callpoint!.setDevObject("skipWHCode","N"); rem --- skip warehouse code entry only once
			callpoint!.setFocus(num(callpoint!.getValidationRow()),"OPT_CARTDET.ITEM_ID",1)
		endif
	else
		rem --- Initialize first warehouse to a warehouse an item was picked from for this order
		default_whse$=""
		optFillmntDet_dev=fnget_dev("OPT_FILLMNTDET")
		dim optFillmntDet$:fnget_tpl$("OPT_FILLMNTDET")
		ar_type$=callpoint!.getColumnData("OPT_CARTDET.AR_TYPE")
		customer_id$=callpoint!.getColumnData("OPT_CARTDET.CUSTOMER_ID")
		order_no$=callpoint!.getColumnData("OPT_CARTDET.ORDER_NO")
		ar_inv_no$=callpoint!.getColumnData("OPT_CARTDET.AR_INV_NO")
		optFillmntDet_trip$=firm_id$+"E"+ar_type$+customer_id$+order_no$+ar_inv_no$
		read(optFillmntDet_dev,key=optFillmntDet_trip$,knum="AO_STATUS",dom=*next)
		while 1
			optFillmntDet_key$=key(optFillmntDet_dev,end=*break)
			if pos(optFillmntDet_trip$=optFillmntDet_key$)<>1 then break
			readrecord(optFillmntDet_dev)optFillmntDet$
			default_whse$=optFillmntDet.warehouse_id$
			break
		wend
		if default_whse$<>"" then
			callpoint!.setColumnData("OPT_CARTDET.WAREHOUSE_ID",default_whse$,1)
			callpoint!.setDevObject("lastWhse",default_whse$)
			callpoint!.setDevObject("skipWHCode","Y")
			callpoint!.setFocus(num(callpoint!.getValidationRow()),"OPT_CARTDET.ITEM_ID",1)
		endif
	endif

[[OPT_CARTDET.<CUSTOM>]]
rem ==========================================================================
getUnpackedQty: rem --- Get the remaining quantity that still need to be packed for the given item.
                             rem --- Must count what is packed in all cartons except the current carton
               rem      IN: -- none --
               rem   OUT: unpackedQty
               rem   OUT: qty_picked
rem ==========================================================================
	alreadyPacked=0
	optCartDet2_dev=fnget_dev("OPT_CARTDET2")
	dim optCartDet2$:fnget_tpl$("OPT_CARTDET2")
	ar_type$=callpoint!.getColumnData("OPT_CARTDET.AR_TYPE")
	customer_id$=callpoint!.getColumnData("OPT_CARTDET.CUSTOMER_ID")
	order_no$=callpoint!.getColumnData("OPT_CARTDET.ORDER_NO")
	ar_inv_no$=callpoint!.getColumnData("OPT_CARTDET.AR_INV_NO")
	orddet_seq_ref$=callpoint!.getColumnData("OPT_CARTDET.ORDDET_SEQ_REF")
	carton_no$=callpoint!.getColumnData("OPT_CARTDET.CARTON_NO")
	optCartDet2_trip$=firm_id$+"E"+ar_type$+customer_id$+order_no$+ar_inv_no$+orddet_seq_ref$
	read(optCartDet2_dev,key=optCartDet2_trip$,knum="AO_ORDDET_CART",dom=*next)
	while 1
		optCartDet2_key$=key(optCartDet2_dev,end=*break)
		if pos(optCartDet2_trip$=optCartDet2_key$)<>1 then break
		readrecord(optCartDet2_dev)optCartDet2$
		if optCartDet2.carton_no$=carton_no$ then continue; rem --- Don't count what is in current carton as packed yet.
		alreadyPacked=alreadyPacked+optCartDet2.qty_packed
	wend

	qty_picked=num(callpoint!.getDevObject("qty_picked"))
	unpackedQty=qty_picked-alreadyPacked
	callpoint!.setDevObject("unpackedQty",unpackedQty)

	return

rem ==========================================================================
getPickedQty: rem --- Get quantity picked for this item
               rem      IN: -- none --
               rem   OUT: qty_picked
rem ==========================================================================
	qty_picked=0
	optFillmntDet_dev=fnget_dev("OPT_FILLMNTDET")
	dim optFillmntDet$:fnget_tpl$("OPT_FILLMNTDET")
	ar_type$=callpoint!.getColumnData("OPT_CARTDET.AR_TYPE")
	customer_id$=callpoint!.getColumnData("OPT_CARTDET.CUSTOMER_ID")
	order_no$=callpoint!.getColumnData("OPT_CARTDET.ORDER_NO")
	ar_inv_no$=callpoint!.getColumnData("OPT_CARTDET.AR_INV_NO")
	orddet_seq_ref$=callpoint!.getColumnData("OPT_CARTDET.ORDDET_SEQ_REF")
	optFillmntDet_trip$=firm_id$+"E"+ar_type$+customer_id$+order_no$+ar_inv_no$+orddet_seq_ref$
	read(optFillmntDet_dev,key=optFillmntDet_trip$,knum="AO_STATUS_ORDDET",dom=*next)
	while 1
		optFillmntDet_key$=key(optFillmntDet_dev,end=*break)
		if pos(optFillmntDet_trip$=optFillmntDet_key$)<>1 then break
		readrecord(optFillmntDet_dev)optFillmntDet$
		qty_picked=optFillmntDet.qty_picked
		break
	wend
	callpoint!.setDevObject("qty_picked",qty_picked)
	read(optFillmntDet_dev,key="",knum="AO_STATUS",dom=*next)

	return

rem ==========================================================================
checkItemInCarton: rem --- Is this item (actually ORDDET_SEQ_REF) already packed in this carton?
               rem      IN: -- none --
               rem   OUT: inCarton
rem ==========================================================================
	inCarton=0
	optCartDet2_dev=fnget_dev("OPT_CARTDET2")
	dim optCartDet2$:fnget_tpl$("OPT_CARTDET2")
	ar_type$=callpoint!.getColumnData("OPT_CARTDET.AR_TYPE")
	customer_id$=callpoint!.getColumnData("OPT_CARTDET.CUSTOMER_ID")
	order_no$=callpoint!.getColumnData("OPT_CARTDET.ORDER_NO")
	ar_inv_no$=callpoint!.getColumnData("OPT_CARTDET.AR_INV_NO")
	orddet_seq_ref$=callpoint!.getColumnData("OPT_CARTDET.ORDDET_SEQ_REF")
	carton_no$=callpoint!.getColumnData("OPT_CARTDET.CARTON_NO")
	optCartDet2_trip$=firm_id$+"E"+ar_type$+customer_id$+order_no$+ar_inv_no$+orddet_seq_ref$+carton_no$
	read(optCartDet2_dev,key=optCartDet2_trip$,knum="AO_ORDDET_CART",dom=*next); inCarton=1
	if inCarton then
		msg_id$ = "OP_ITEM_IN_CARTON"
		gosub disp_message
	endif

	return

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
doItemLookup: rem --- Luanch lookup for unpacked picked items
               rem      IN: -- none --
               rem   OUT: -- none --
rem ==========================================================================
	call stbl("+DIR_SYP")+"bac_key_template.bbj","OPT_FILLMNTDET","PRIMARY",key_tpl$,rd_table_chans$[all],status$
	dim optFillmntDet_key$:key_tpl$
	keyLength=len(optFillmntDet_key$)
	dim filter_defs$[6,2]
	filter_defs$[1,0]="OPT_FILLMNTDET.FIRM_ID"
	filter_defs$[1,1]="='"+firm_id$ +"'"
	filter_defs$[1,2]="LOCK"
	filter_defs$[2,0]="OPT_FILLMNTDET.TRANS_STATUS"
	filter_defs$[2,1]="='E'"
	filter_defs$[2,2]="LOCK"
	filter_defs$[3,0]="OPT_FILLMNTDET.AR_TYPE"
	filter_defs$[3,1]="='"+callpoint!.getColumnData("OPT_CARTDET.AR_TYPE")+"'"
	filter_defs$[3,2]="LOCK"
	filter_defs$[4,0]="OPT_FILLMNTDET.CUSTOMER_ID"
	filter_defs$[4,1]="='"+callpoint!.getColumnData("OPT_CARTDET.CUSTOMER_ID")+"'"
	filter_defs$[4,2]="LOCK"
	filter_defs$[5,0]="OPT_FILLMNTDET.ORDER_NO"
	filter_defs$[5,1]="='"+callpoint!.getColumnData("OPT_CARTDET.ORDER_NO")+"'"
	filter_defs$[5,2]="LOCK"
	filter_defs$[6,0]="OPT_FILLMNTDET.AR_INV_NO"
	filter_defs$[6,1]="='"+callpoint!.getColumnData("OPT_CARTDET.AR_INV_NO")+"'"
	filter_defs$[6,2]="LOCK"

	call stbl("+DIR_SYP")+"bax_query.bbj",gui_dev,form!,"OP_UNPACKED_ITEM","",table_chans$[all],optFillmntDet_key$,filter_defs$[all]

	rem --- Update item_id with selected item
	if cvs(optFillmntDet_key$,2)<>"" then
		optFillmntDet_dev=fnget_dev("OPT_FILLMNTDET")
		dim optFillmntDet$:fnget_tpl$("OPT_FILLMNTDET")
		readrecord(optFillmntDet_dev,key=optFillmntDet_key$(1,keyLength),knum="PRIMARY")optFillmntDet$
		orddet_seq_ref$=optFillmntDet.orddet_seq_ref$
		callpoint!.setColumnData( "OPT_CARTDET.ORDDET_SEQ_REF",orddet_seq_ref$)
		qty_picked=optFillmntDet.qty_picked
		callpoint!.setDevObject("qty_picked",qty_picked)
		gosub getUnpackedQty
		if unpackedQty>qty_picked then
			callpoint!.setColumnData("OPT_CARTDET.QTY_PACKED",str(qty_picked),1)
		else
			callpoint!.setColumnData("OPT_CARTDET.QTY_PACKED",str(unpackedQty),1)
		endif

		callpoint!.setColumnData("OPT_CARTDET.WAREHOUSE_ID",optFillmntDet.warehouse_id$,1)
		callpoint!.setColumnData("OPT_CARTDET.ITEM_ID",optFillmntDet.item_id$,1)
		callpoint!.setColumnData("OPT_CARTDET.ORDER_MEMO",optFillmntDet.order_memo$,1)
		callpoint!.setColumnData("OPT_CARTDET.UM_SOLD",optFillmntDet.um_sold$,1)
		callpoint!.setStatus("MODIFIED")
		callpoint!.setFocus(num(callpoint!.getValidationRow()),"OPT_CARTDET.QTY_PACKED",1)
	endif

	rem --- Verify the item is not already packed in this carton.
	gosub checkItemInCarton
	if inCarton then
		callpoint!.setColumnData("OPT_CARTDET.QTY_PACKED",str(0),1)
		callpoint!.setColumnData("OPT_CARTDET.WAREHOUSE_ID","",1)
		callpoint!.setColumnData("OPT_CARTDET.ITEM_ID","",1)
		callpoint!.setColumnData("OPT_CARTDET.ORDER_MEMO","",1)
		callpoint!.setColumnData("OPT_CARTDET.UM_SOLD","",1)
		callpoint!.setStatus("CLEAR")
		callpoint!.setFocus(callpoint!.getValidationRow(),"OPT_CARTDET.WAREHOUSE_ID",1)
	endif

	return

rem ==========================================================================
rem 	Use util object
rem ==========================================================================
	use ::ado_util.src::util



