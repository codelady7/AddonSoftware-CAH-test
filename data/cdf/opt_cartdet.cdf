[[OPT_CARTDET.AGDR]]
rem --- Initialize <<DISPLAY>> fields
	carton_no$=callpoint!.getDevObject("carton_no")
	callpoint!.setColumnData("<<DISPLAY>>.CARTON_DSP",carton_no$,1)

rem --- Initialize last warehouse entered
	warehouse_id$=callpoint!.getColumnData("OPT_CARTDET.WAREHOUSE_ID")
	if cvs(warehouse_id$,2)<>"" then callpoint!.setDevObject("lastWhse",warehouse_id$)


rem --- Enable Pack Lot/Serial button for lot/serial items
	callpoint!.setOptionEnabled("PKLS",1)

rem wgh ... 10304 ... Provide visual warning when quantity of lot/serial number packed is less than the quantity packed for the item

[[OPT_CARTDET.AGDS]]
rem wgh ... 10304 ... Provide visual warning when quantity of lot/serial number packed is less than the quantity packed for the item

[[OPT_CARTDET.AGRE]]
rem wgh ... 10304 ... Warning when quantity of lot/serial number packed is less than the quantity packed for the item

[[OPT_CARTDET.AGRN]]
rem --- Disable Pack Lot/Serial button for new lines
	if callpoint!.getGridRowNewStatus(callpoint!.getValidationRow())="Y" then
		callpoint!.setOptionEnabled("PKLS",0)
	else
		callpoint!.setOptionEnabled("PKLS",1)
	endif

rem --- Allow skipping warehouse entry once
	callpoint!.setDevObject("skipWHCode","Y")

[[OPT_CARTDET.AOPT-PKLS]]
rem --- Initialize grid with unpacked picked lots/serials in OPT_FILLMNTLSDET
	ar_type$=callpoint!.getColumnData("OPT_CARTDET.AR_TYPE")
	customer_id$=callpoint!.getColumnData("OPT_CARTDET.CUSTOMER_ID")
	order_no$=callpoint!.getColumnData("OPT_CARTDET.ORDER_NO")
	ar_inv_no$=callpoint!.getColumnData("OPT_CARTDET.AR_INV_NO")
	carton_no$=callpoint!.getColumnData("OPT_CARTDET.CARTON_NO")
	warehouse_id$=callpoint!.getColumnData("OPT_CARTDET.WAREHOUSE_ID")
	item_id$=callpoint!.getColumnData("OPT_CARTDET.ITEM_ID")
	seqRef$=callpoint!.getColumnData("OPT_CARTDET.ORDDET_SEQ_REF")
	optCartDet_key$=firm_id$+"E"+ar_type$+customer_id$+order_no$+ar_inv_no$+carton_no$+warehouse_id$+item_id$+seqRef$

	optCartLsDet_dev=fnget_dev("OPT_CARTLSDET")
	dim optCartLsDet$:fnget_tpl$("OPT_CARTLSDET")
	read(optCartLsDet_dev,key=optCartDet_key$,dom=*next)
	optCartLsDet_key$=key(optCartLsDet_dev,end=*next)
print"optCartDet_key$=",optCartDet_key$
print"optCartLsDet_key$=",optCartLsDet_key$
rem wgh ... 10304 ... testing
	if pos(optCartDet_key$=optCartLsDet_key$)=1 then
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

				rem --- Skip if already full packed in other cartoons
				alreadyPacked=0
				optCartLsDet_trip$=firm_id$+ar_type$+customer_id$+order_no$+ar_inv_no$
				read(optCartLsDet_dev,key=optCartLsDet_trip$,dom=*next)
				while 1
					optCartLsDet_key$=key(optCartLsDet_dev,end=*break)
					if pos(optCartLsDet_trip$=optCartLsDet_key$)<>1 then break
					readrecord(optCartLsDet_dev)optCartLsDet$
					if optCartLsDet.warehouse_id$+optCartLsDet.item_id$<>whse$+item$ then continue
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

		call stbl("+DIR_SYP") + "bam_run_prog.bbj", 
:			"OPT_CARTLSDET", 
:			stbl("+USER_ID"), 
:			"MNT" ,
:			optCartDet_key$, 
:			table_chans$[all], 
:			dflt_data$[all]

[[OPT_CARTDET.AREC]]
rem --- Initialize <<DISPLAY>> fields
	carton_no$=callpoint!.getDevObject("carton_no")
	callpoint!.setColumnData("<<DISPLAY>>.CARTON_DSP",carton_no$,1)

rem --- Initialize RTP trans_status and created fields
	rem --- TRANS_STATUS set to "E" via form Preset Value
	callpoint!.setColumnData("OPT_CARTDET.CREATED_USER",sysinfo.user_id$)
	callpoint!.setColumnData("OPT_CARTDET.CREATED_DATE",date(0:"%Yd%Mz%Dz"))
	callpoint!.setColumnData("OPT_CARTDET.CREATED_TIME",date(0:"%Hz%mz"))

rem --- Buttons start disabled
	callpoint!.setOptionEnabled("PKLS",0)

rem --- Allow skipping warehouse entry once
	callpoint!.setDevObject("skipWHCode","Y")

[[OPT_CARTDET.AWRI]]
rem --- Enable Pack Lot/Serial button for lot/serial items
	if callpoint!.getDevObject("lotser_item")="Y" then callpoint!.setOptionEnabled("PKLS",1)

[[OPT_CARTDET.BEND]]
rem wgh ... 10304 ... Warn when lot/serial numbers haven't been packed

[[OPT_CARTDET.BSHO]]
rem --- Initialize last warehouse entered
	callpoint!.setDevObject("lastWhse","")

[[OPT_CARTDET.BWRI]]
rem --- Initialize RTP modified fields for modified existing records
	if callpoint!.getGridRowNewStatus(callpoint!.getValidationRow())<>"Y" then
		callpoint!.setColumnData("OPT_CARTDET.MOD_USER", sysinfo.user_id$)
		callpoint!.setColumnData("OPT_CARTDET.MOD_DATE", date(0:"%Yd%Mz%Dz"))
		callpoint!.setColumnData("OPT_CARTDET.MOD_TIME", date(0:"%Hz%mz"))
	endif

[[<<DISPLAY>>.CARTON_DSP.AVAL]]
rem --- Need to use <<DISPLAY>> field for CARTON_NO because it is part of the key to the primary table OPT_CARTHDR.

[[OPT_CARTDET.ITEM_ID.AVAL]]
rem wgh ... 10304 ... handle item_id the same as in Order Entry

[[OPT_CARTDET.ITEM_ID.BINP]]
rem wgh ... 10304 ... handle item_id the same as in Order Entry

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
break; rem wgh ... 10304 ... stopped here
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

rem wgh ... 10304 ... Provide visual warning when quantity of lot/serial number packed is less than the quantity packed for the item

[[OPT_CARTDET.QTY_PACKED.BINP]]
rem --- Default QTY_PACKED to the remaining number that still need to be packed.
	alreadyPacked=-num(callpoint!.getColumnData("OPT_CARTDET.QTY_PACKED"))
	dim optCartDet$:fnget_tpl$("OPT_CARTDET")
	for i=0 to GridVect!.size()-1
		optCartDet$=GridVect!.getItem(i)
		alreadyPacked=alreadyPacked+optCartDet.qty_packed
	next i

break; rem wgh ... 10304 ... testing
	qty_picked=num(callpoint!.getDevObject("qty_picked"))
	unpackedQty=qty_picked-alreadyPacked
	callpoint!.setDevObject("unpackedQty",unpackedQty)
	callpoint!.setColumnData("OPT_CARTDET.QTY_PACKED",str(unpackedQty),1)

[[OPT_CARTDET.WAREHOUSE_ID.AVAL]]
rem --- Hold on to the last warehouse entered
	warehouse_id$=callpoint!.getUserInput()
	callpoint!.setDevObject("lastWhse",warehouse_id$)

[[OPT_CARTDET.WAREHOUSE_ID.BINP]]
rem --- If a warehouse was previously entered for this carton, use it and skip warehouse entry once.
	lastWhse$=callpoint!.getDevObject("lastWhse")
	if cvs(lastWhse$,2)<>"" then
		callpoint!.setColumnData("OPT_CARTDET.WAREHOUSE_ID",lastWhse$,1)

rem wgh ... 10304 ... testing
		rem --- Force focus on item when warehouse hasn't been skipped yet
		if callpoint!.getDevObject("skipWHCode") = "Y" then
			callpoint!.setDevObject("skipWHCode","N"); rem --- skip warehouse code entry only once
			callpoint!.setFocus(num(callpoint!.getValidationRow()),"OPT_CARTDET.ITEM_ID",1)
		endif
	endif



