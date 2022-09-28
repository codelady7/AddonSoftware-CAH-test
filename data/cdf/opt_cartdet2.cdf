[[OPT_CARTDET2.AGDR]]
rem --- Initialize <<DISPLAY>> fields
	warehouse_id$=callpoint!.getColumnData("OPT_CARTDET2.WAREHOUSE_ID")
	callpoint!.setColumnData("<<DISPLAY>>.WHSE_ID_DSP",warehouse_id$,1)
	item_id$=callpoint!.getColumnData("OPT_CARTDET2.ITEM_ID")
	callpoint!.setColumnData("<<DISPLAY>>.ITEM_ID_DSP",item_id$,1)
	order_memo$=callpoint!.getDevObject("order_memo")

rem --- Enable Pack Lot/Serial button for lot/serial items
	if callpoint!.getDevObject("lotser_item")="Y" then
		callpoint!.setOptionEnabled("PKLS",1)
	else
		callpoint!.setOptionEnabled("PKLS",0)
	endif

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
	warehouse_id$=callpoint!.getColumnData("OPT_CARTDET2.WAREHOUSE_ID")
	item_id$=callpoint!.getColumnData("OPT_CARTDET2.ITEM_ID")
	seqRef$=callpoint!.getColumnData("OPT_CARTDET2.INTERNAL_SEQ_NO")
	optCartLsDet_trip$=firm_id$+"E"+ar_type$+customer_id$+order_no$+ar_inv_no$+carton_no$+warehouse_id$+item_id$+seqRef$

	optCartLsDet_dev=fnget_dev("OPT_CARTLSDET")
	dim optCartLsDet$:fnget_tpl$("OPT_CARTLSDET")
	read(optCartLsDet_dev,key=optCartLsDet_trip$,knum="AO_STATUS",dom=*next)
	optCartLsDet_key$=key(optCartLsDet_dev,end=*next)
	if pos(optCartLsDet_trip$=optCartLsDet_key$)=1 then
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
			orddet_seq_ref$=callpoint!.getDevObject("orddet_seq_ref")
			optFillmntDet_key$=firm_id$+"E"+ar_type$+customer_id$+order_no$+ar_inv_no$+orddet_seq_ref$

			read(optFillmntLsDet_dev,key=optFillmntDet_key$,knum="AO_STATUS",dom=*next)
			while 1
				optFillmntLsDet_key$=key(optFillmntLsDet_dev,end=*break)
				if pos(optFillmntDet_key$=optFillmntLsDet_key$)<>1 then break
				readrecord(optFillmntLsDet_dev)optFillmntLsDet$

				rem --- Skip if already fully packed in other cartoons
				alreadyPacked=0
				optCartLsDet_trip$=firm_id$+"E"+ar_type$+customer_id$+order_no$+ar_inv_no$
				read(optCartLsDet_dev,key=optCartLsDet_trip$,knum="AO_STATUS",dom=*next)
				while 1
					optCartLsDet_key$=key(optCartLsDet_dev,end=*break)
					if pos(optCartLsDet_trip$=optCartLsDet_key$)<>1 then break
					readrecord(optCartLsDet_dev)optCartLsDet$
					if optCartLsDet.warehouse_id$+optCartLsDet.item_id$<>warehouse_id$+item_id$ then continue
					if optCartLsDet.lotser_no$<>optFillmntLsDet.lotser_no$ then continue
					alreadyPacked=alreadyPacked+optCartLsDet.qty_packed
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
				optCartLsDet.warehouse_id$=warehouse_id$
				optCartLsDet.item_id$=item_id$
				optCartLsDet.cartdet_seq_ref$=seqRef$
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

		dim dflt_data$[10,1]
		dflt_data$[1,0]="FIRM_ID"
		dflt_data$[1,1]=firm_id$
		dflt_data$[2,0]="TRANS_STATUS"
		dflt_data$[2,1]="E"
		dflt_data$[3,0]="AR_TYPE"
		dflt_data$[3,1]=ar_type$
		dflt_data$[4,0]="CUSTOMER_ID"
		dflt_data$[4,1]=customer_id$
		dflt_data$[5,0]="ORDER_NO"
		dflt_data$[5,1]=order_no$
		dflt_data$[6,0]="AR_INV_NO"
		dflt_data$[6,1]=ar_inv_no$
		dflt_data$[7,0]="CARTON_NO"
		dflt_data$[7,1]=carton_no$
		dflt_data$[8,0]="WAREHOUSE_ID"
		dflt_data$[8,1]=warehouse_id$
		dflt_data$[9,0]="ITEM_ID"
		dflt_data$[9,1]=item_id$
		dflt_data$[10,0]="CARTDET_SEQ_REF"
		dflt_data$[10,1]=seqRef$
		optCartDet_key$=firm_id$+"E"+ar_type$+customer_id$+order_no$+ar_inv_no$+carton_no$+warehouse_id$+item_id$+seqRef$

		rem --- Pass additional info needed in OPT_CARTLSDET
		callpoint!.setDevObject("ar_type",ar_type$)
		callpoint!.setDevObject("customer_id",customer_id$)
		callpoint!.setDevObject("order_no",order_no$)
		callpoint!.setDevObject("ar_inv_no",ar_inv_no$)
		callpoint!.setDevObject("carton_no",carton_no$)
		callpoint!.setDevObject("warehouse_id",warehouse_id$)
		callpoint!.setDevObject("item_id",item_id$)

		call stbl("+DIR_SYP") + "bam_run_prog.bbj", 
:			"OPT_CARTLSDET", 
:			stbl("+USER_ID"), 
:			"MNT" ,
:			optCartDet_key$, 
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

[[OPT_CARTDET2.BWRI]]
rem --- Make sure INTERNAL_SEQ_NO gets initialized
	if cvs(callpoint!.getColumnData("OPT_CARTDET2.INTERNAL_SEQ_NO"),2)="" then
		call stbl("+DIR_SYP")+"bas_sequences.bbj","INTERNAL_SEQ_NO",newInternalSeqNo$,table_chans$[all]
		callpoint!.setColumnData("OPT_CARTDET2.INTERNAL_SEQ_NO",newInternalSeqNo$)
	endif

[[OPT_CARTDET2.CARTON_NO.AVAL]]
rem --- Create new OPT_CARTHDR record if one doesn't already exist for this CARTON_NO 
	call stbl("+DIR_SYP")+"bac_key_template.bbj","OPT_CARTDET2","AO_STATUS",key_tpl$,table_chans$[all],status$
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
	else
		rem --- Allow the same carton number only once in the grid
		dim gridrec$:fattr(rec_data$)
		for i=0 to GridVect!.size()-1
			gridrec$=GridVect!.getItem(i)
			if gridrec.carton_no$=carton_no$
				msg_id$ = "OP_CARTON_IN_GRID"
				dim msg_tokens$[1]
				msg_tokens$[1]=cvs(carton_no$,2)
				gosub disp_message
				callpoint!.setStatus("ABORT")
				break
			endif
		next i
	endif

rem --- Initialize new row
	row=callpoint!.getValidationRow()
	if callpoint!.getGridRowNewStatus(row)="Y" then
		warehouse_id$=callpoint!.getDevObject("warehouse_id")
		callpoint!.setColumnData("<<DISPLAY>>.WHSE_ID_DSP",warehouse_id$,1)
		item_id$=callpoint!.getDevObject("item_id")
		callpoint!.setColumnData("<<DISPLAY>>.ITEM_ID_DSP",item_id$,1)
		order_memo$=callpoint!.getDevObject("order_memo")
		callpoint!.setColumnData("OPT_CARTDET2.ORDER_MEMO",order_memo$,1)
		um_sold$=callpoint!.getDevObject("um_sold")
		callpoint!.setColumnData("OPT_CARTDET2.UM_SOLD",um_sold$,1)

		rem --- For a new row, default QTY_PACKED to the remaining number that still need to be packed.
		alreadyPacked=-num(callpoint!.getColumnData("OPT_CARTDET2.QTY_PACKED"))
		dim optCartDet$:fnget_tpl$("OPT_CARTDET2")
		for i=0 to GridVect!.size()-1
			optCartDet$=GridVect!.getItem(i)
			alreadyPacked=alreadyPacked+optCartDet.qty_packed
		next i
		qty_picked=num(callpoint!.getDevObject("qty_picked"))
		unpackedQty=qty_picked-alreadyPacked
		callpoint!.setDevObject("unpackedQty",unpackedQty)
		callpoint!.setColumnData("OPT_CARTDET2.QTY_PACKED",str(unpackedQty),1)
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



