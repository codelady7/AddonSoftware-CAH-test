[[OPT_CARTDET2.AGDR]]
rem --- Initialize CARTON_DSP with CARTON_NO
	callpoint!.setColumnData("<<DISPLAY>>.CARTON_DSP",callpoint!.getColumnData("OPT_CARTDET2.CARTON_NO"),1)

rem --- Enable Pack Lot/Serial button for lot/serial items
	if callpoint!.getDevObject("lotser_item")="Y" then
		callpoint!.setOptionEnabled("PKLS",1)
	else
		callpoint!.setOptionEnabled("PKLS",0)
	endif

rem wgh ... 10304 ... Provide visual warning when quantity of lot/serial number packed is less than the quantity packed for the item

[[OPT_CARTDET2.AGDS]]
rem wgh ... 10304 ... Provide visual warning when quantity of lot/serial number packed is less than the quantity packed for the item

[[OPT_CARTDET2.AGRN]]
rem --- Disable Pack Lot/Serial button for new lines
	if callpoint!.getGridRowNewStatus(callpoint!.getValidationRow())="Y" then
		callpoint!.setOptionEnabled("PKLS",0)
	else
		rem --- Enable Pack Lot/Serial button for lot/serial items
		if callpoint!.getDevObject("lotser_item")="Y" then
			callpoint!.setOptionEnabled("PKLS",1)
		else
			callpoint!.setOptionEnabled("PKLS",0)
		endif
	endif

[[OPT_CARTDET2.AOPT-PKLS]]
rem --- Initialize grid with unpacked picked lots/serials in OPT_FILLMNTLSDET
	ar_type$=callpoint!.getColumnData("OPT_CARTDET2.AR_TYPE")
	customer_id$=callpoint!.getColumnData("OPT_CARTDET2.CUSTOMER_ID")
	order_no$=callpoint!.getColumnData("OPT_CARTDET2.ORDER_NO")
	ar_inv_no$=callpoint!.getColumnData("OPT_CARTDET2.AR_INV_NO")
	carton_no$=callpoint!.getColumnData("OPT_CARTDET2.CARTON_NO")
	orddet_seq_ref$=callpoint!.getColumnData("OPT_CARTDET2.ORDDET_SEQ_REF")
	optCartLsDet2_trip$=firm_id$+"E"+ar_type$+customer_id$+order_no$+ar_inv_no$+orddet_seq_ref$+carton_no$

	optCartLsDet2_dev=fnget_dev("OPT_CARTLSDET2")
	dim optCartLsDet2$:fnget_tpl$("OPT_CARTLSDET2")
	read(optCartLsDet2_dev,key=optCartLsDet2_trip$,knum="AO_ORDDET_CART",dom=*next)
	optCartLsDet2_key$=key(optCartLsDet2_dev,end=*next)
	if pos(optCartLsDet2_trip$=optCartLsDet2_key$)=1 then
		rem --- Grid already initialized
	else
		rem --- Ask if they want to pack all remaining unpacked lot/serial numbers picked for this item
		msg_id$ = "OP_PACK_UNPACKED"
		gosub disp_message
		if msg_opt$="Y" then
			rem --- Initialize grid
			optFillmntLsDet_dev=fnget_dev("OPT_FILLMNTLSDET")
			dim optFillmntLsDet$:fnget_tpl$("OPT_FILLMNTLSDET")
			rem --- NOTE: orddet_seq_ref gets set in opt_fillmntdet, so this will be null unless coming from there
			optFillmntDet_key$=firm_id$+"E"+ar_type$+customer_id$+order_no$+ar_inv_no$+orddet_seq_ref$

			read(optFillmntLsDet_dev,key=optFillmntDet_key$,knum="AO_STATUS",dom=*next)
			while 1
				optFillmntLsDet_key$=key(optFillmntLsDet_dev,end=*break)
				if pos(optFillmntDet_key$=optFillmntLsDet_key$)<>1 then break
				readrecord(optFillmntLsDet_dev)optFillmntLsDet$

				rem --- Skip if already fully packed in other cartoons
				alreadyPacked=0
				optCartLsDet2_trip$=firm_id$+"E"+ar_type$+customer_id$+order_no$+ar_inv_no$
				read(optCartLsDet2_dev,key=optCartLsDet2_trip$,knum="AO_ORDDET_CART",dom=*next)
				while 1
					optCartLsDet2_key$=key(optCartLsDet2_dev,end=*break)
					if pos(optCartLsDet2_trip$=optCartLsDet2_key$)<>1 then break
					readrecord(optCartLsDet2_dev)optCartLsDet2$
					if optCartLsDet2.orddet_seq_ref$<>orddet_seq_ref$ then continue
					if optCartLsDet2.lotser_no$<>optFillmntLsDet.lotser_no$ then continue
					alreadyPacked=alreadyPacked+optCartLsDet2.qty_packed
				wend
				if alreadyPacked>=optFillmntLsDet.qty_picked then continue

				seqNo=seqNo+1
				redim optCartLsDet2$
				optCartLsDet2.firm_id$=firm_id$
				optCartLsDet2.ar_type$=ar_type$
				optCartLsDet2.customer_id$=customer_id$
				optCartLsDet2.order_no$=order_no$
				optCartLsDet2.ar_inv_no$=ar_inv_no$
				optCartLsDet2.carton_no$=carton_no$
				optCartLsDet2.orddet_seq_ref$=orddet_seq_ref$
				optCartLsDet2.sequence_no$=str(seqNo,"000")
				optCartLsDet2.lotser_no$=optFillmntLsDet.lotser_no$
				optCartLsDet2.created_user$=sysinfo.user_id$
				optCartLsDet2.created_date$=date(0:"%Yd%Mz%Dz")
				optCartLsDet2.created_time$=date(0:"%Hz%mz")
				optCartLsDet2.trans_status$="E"
				optCartLsDet2.qty_packed=optFillmntLsDet.qty_picked-alreadyPacked
				writerecord(optCartLsDet2_dev)optCartLsDet2$
			wend
		endif
	endif

rem --- Launch Packing Carton Lot/Serial Detail grid

		optCartLsDet2_key$=firm_id$+"E"+ar_type$+customer_id$+order_no$+ar_inv_no$+orddet_seq_ref$+carton_no$

		rem --- Pass additional info needed in OPT_CARTLSDET
		callpoint!.setDevObject("item_id",callpoint!.getColumnData("OPT_CARTDET2.ITEM_ID"))

		call stbl("+DIR_SYP") + "bam_run_prog.bbj", 
:			"OPT_CARTLSDET2", 
:			stbl("+USER_ID"), 
:			"MNT" ,
:			optCartLsDet2_key$, 
:			table_chans$[all], 
:			dflt_data$[all]

rem --- Has the total quantity packed changed?
	start_qty_packed=num(callpoint!.getColumnData("OPT_CARTDET2.QTY_PACKED"))
	total_packed=callpoint!.getDevObject("total_packed")
	if total_packed<>start_qty_packed then
		callpoint!.setColumnData("OPT_CARTDET2.QTY_PACKED",str(total_packed),1)
		callpoint!.setStatus("MODIFIED")
	endif

[[OPT_CARTDET2.AREC]]
rem ---Initialize fields needed for CARTON_NO lookup
	call stbl("+DIR_SYP")+"bac_key_template.bbj","OPT_CARTDET2","AO_ORDDET_CART",key_tpl$,table_chans$[all],status$
	dim optCartDet2_keyPrefix$:key_tpl$
	optCartDet2_keyPrefix$=callpoint!.getKeyPrefix()
	callpoint!.setColumnData("OPT_CARTDET2.AR_TYPE",optCartDet2_keyPrefix.ar_type$)
	callpoint!.setColumnData("OPT_CARTDET2.CUSTOMER_ID",optCartDet2_keyPrefix.customer_id$)
	callpoint!.setColumnData("OPT_CARTDET2.ORDER_NO",optCartDet2_keyPrefix.order_no$)
	callpoint!.setColumnData("OPT_CARTDET2.AR_INV_NO",optCartDet2_keyPrefix.ar_inv_no$)
	callpoint!.setColumnData("OPT_CARTDET2.ORDDET_SEQ_REF",optCartDet2_keyPrefix.orddet_seq_ref$)

rem --- Initialize RTP trans_status and created fields
	rem --- TRANS_STATUS set to "E" via form Preset Value
	callpoint!.setColumnData("OPT_CARTDET2.CREATED_USER",sysinfo.user_id$)
	callpoint!.setColumnData("OPT_CARTDET2.CREATED_DATE",date(0:"%Yd%Mz%Dz"))
	callpoint!.setColumnData("OPT_CARTDET2.CREATED_TIME",date(0:"%Hz%mz"))

rem --- Buttons start disabled
	callpoint!.setOptionEnabled("PKLS",0)

[[OPT_CARTDET2.ASHO]]
rem --- Set Lot/Serial button up properly
	switch pos(callpoint!.getDevObject("lotser_flag")="LS")
		case 1; callpoint!.setOptionText("PKLS",Translate!.getTranslation("AON_PACK")+" "+Translate!.getTranslation("AON_LOT")); break
		case 2; callpoint!.setOptionText("PKLS",Translate!.getTranslation("AON_PACK")+" "+Translate!.getTranslation("AON_SERIAL")); break
		case default; callpoint!.setOptionEnabled("PKLS",0); break
	swend

[[OPT_CARTDET2.AWRI]]
rem --- Enable Pack Lot/Serial button for lot/serial items
	if callpoint!.getDevObject("lotser_item")="Y" then callpoint!.setOptionEnabled("PKLS",1)

[[OPT_CARTDET2.BEND]]
rem --- Get the total quantity packed
	qtyPacked=0
	dim gridrec$:fattr(rec_data$)
	numrecs=GridVect!.size()
	if numrecs>0 then 
		for reccnt=0 to numrecs-1
			gridrec$=GridVect!.getItem(reccnt)
			qtyPacked=qtyPacked+gridrec.qty_packed
		next reccnt
	endif

rem --- Warn if quantity packed is less than the quantity picked.
	qty_picked=num(callpoint!.getDevObject("qty_picked"))
	if qtyPacked<qty_picked
		msg_id$ = "OP_BAD_PACK_QTY"
		dim msg_tokens$[2]
		msg_tokens$[1] = str(qtyPacked)
		msg_tokens$[2] = str(qty_picked)
		gosub disp_message
		if msg_opt$="N"
			callpoint!.setStatus("ABORT")
			break
		endif
	endif

rem wgh ... 10304 ... Warning when quantity of lot/serial number packed is less than the quantity packed for the item

[[OPT_CARTDET2.BWRI]]
rem --- Make sure CARTON_NO is set to CARTON_DSP
	callpoint!.setColumnData("OPT_CARTDET2.CARTON_NO",callpoint!.getColumnData("<<DISPLAY>>.CARTON_DSP"))

rem --- Initialize RTP modified fields for modified existing records
	if callpoint!.getGridRowNewStatus(callpoint!.getValidationRow())<>"Y" then
		callpoint!.setColumnData("OPT_CARTDET2.MOD_USER", sysinfo.user_id$)
		callpoint!.setColumnData("OPT_CARTDET2.MOD_DATE", date(0:"%Yd%Mz%Dz"))
		callpoint!.setColumnData("OPT_CARTDET2.MOD_TIME", date(0:"%Hz%mz"))
	endif

[[<<DISPLAY>>.CARTON_DSP.AVAL]]
rem --- Need to use <<DISPLAY>> field for CARTON_NO because it is part of the key to the primary table OPT_CARTHDR.
rem --- OPT_CARTDET2 doesn't need to have a primary table because OPT_CARTHDR deletes cascade to OPT_CARTDET.
rem --- However, for maintainability, CARTON_DSP is being used in both OPT_CARTDET and OPT_CARTDET2.

rem --- Initialize new row
	if callpoint!.getGridRowNewStatus(num(callpoint!.getValidationRow()))="Y" then
		carton_no$=callpoint!.getUserInput()
		callpoint!.setColumnData("OPT_CARTDET2.CARTON_NO",carton_no$)
		warehouse_id$=callpoint!.getDevObject("warehouse_id")
		callpoint!.setColumnData("OPT_CARTDET2.warehouse_ID",warehouse_id$,1)
		item_id$=callpoint!.getDevObject("item_id")
		callpoint!.setColumnData("OPT_CARTDET2.ITEM_ID",item_id$,1)
		order_memo$=callpoint!.getDevObject("order_memo")
		callpoint!.setColumnData("OPT_CARTDET2.ORDER_MEMO",order_memo$,1)
		um_sold$=callpoint!.getDevObject("um_sold")
		callpoint!.setColumnData("OPT_CARTDET2.UM_SOLD",um_sold$,1)

		rem --- Refresh Packing & Shipping grid in case a new carton was entered
		callpoint!.setDevObject("refreshRecord",1)
	endif

[[OPT_CARTDET2.QTY_PACKED.AVAL]]
rem --- QTY_PACKED cannot be negative
	qty_packed=num(callpoint!.getUserInput())
	previous_qtyPacked=num(callpoint!.getColumnData("OPT_CARTDET2.QTY_PACKED"))
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
	if qty_packed>unpackedQty+previous_qtyPacked then
		msg_id$ = "OP_PACK_REMAINING"
		dim msg_tokens$[3]
		msg_tokens$[1]=str(qty_picked-unpackedQty)
		msg_tokens$[2]=str(qty_picked)
		msg_tokens$[3]=str(unpackedQty+previous_qtyPacked)
		gosub disp_message

		callpoint!.setColumnData("OPT_CARTDET2.QTY_PACKED",str(previous_qtyPacked),1)
		callpoint!.setStatus("ABORT")
		break
	endif

rem wgh ... 10304 ... Provide visual warning when quantity of lot/serial number packed is less than the quantity packed for the item

[[OPT_CARTDET2.QTY_PACKED.BINP]]
rem --- Default QTY_PACKED to the remaining number that still need to be packed for new lines
	alreadyPacked=0
	dim gridrec$:fattr(rec_data$)
	numrecs=GridVect!.size()
	if numrecs>0 then 
		for reccnt=0 to numrecs-1
			gridrec$=GridVect!.getItem(reccnt)
			alreadyPacked=alreadyPacked+gridrec.qty_packed
		next reccnt
	endif
	qty_picked=num(callpoint!.getDevObject("qty_picked"))
	unpackedQty=qty_picked-alreadyPacked
	callpoint!.setDevObject("unpackedQty",unpackedQty)
	if callpoint!.getGridRowNewStatus(num(callpoint!.getValidationRow()))="Y" then
		callpoint!.setColumnData("OPT_CARTDET2.QTY_PACKED",str(unpackedQty),1)
		callpoint!.setDevObject("unpackedQty",0)
	endif



