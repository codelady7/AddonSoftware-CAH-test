[[OPT_FILLMNTHDR.ARNF]]
rem --- Confirm the Order is ready to be filled.
	msg_id$="OP_ORD_READY_TO_FILL"
	gosub disp_message
	if msg_opt$="N"
		callpoint!.setStatus("ABORT")
		break
	endif

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
	callpoint!.setColumnData("OPT_FILLMNTHDR.SHIPMNT_DATE",opeOrdHdr.shipmnt_date$,1)
	callpoint!.setColumnData("OPT_FILLMNTHDR.AR_SHIP_VIA",opeOrdHdr.ar_ship_via$,1)
	callpoint!.setColumnData("OPT_FILLMNTHDR.SHIPPING_ID",opeOrdHdr.shipping_id$,1)
	callpoint!.setColumnData("OPT_FILLMNTHDR.TRANS_STATUS","E",1)

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
	read(opeOrdDet_dev,key=opeOrdHdr_key$,knum="PRIMARY",dom=*next)
	while 1
		opeOrdDet_key$=key(opeOrdDet_dev,end=*break)
		if pos(opeOrdHdr_key$=opeOrdDet_key$)<>1 then break
		readrecord(opeOrdDet_dev)opeOrdDet$

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
		optFillmntDet.trans_status$="E"
		optFillmntDet.qty_shipped=opeOrdDet.qty_shipped
		optFillmntDet.qty_picked=0
		writerecord(optFillmntDet_dev)optFillmntDet$
	wend

	callpoint!.setStatus("REFGRID")

rem --- Initialize OPT_FILLMNTLSDET with corresponding OPE_ORDLSDET data
	optFillmntLsDet_dev=fnget_dev("OPT_FILLMNTLSDET")
	dim optFillmntLsDet$:fnget_tpl$("OPT_FILLMNTLSDET")
	opeOrdLsDet_dev=fnget_dev("OPE_ORDLSDET")
	dim opeOrdLsDet$:fnget_tpl$("OPE_ORDLSDET")
	read(opeOrdLsDet_dev,key=opeOrdHdr_key$,knum="PRIMARY",dom=*next)
	while 1
		opeOrdLsDet_key$=key(opeOrdLsDet_dev,end=*break)
		if pos(opeOrdHdr_key$=opeOrdLsDet_key$)<>1 then break
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
		optFillmntLsDet.trans_status$="E"
		optFillmntLsDet.qty_shipped=opeOrdLsDet.qty_shipped
		optFillmntLsDet.qty_picked=0
		optFillmntLsDet.unit_cost=opeOrdLsDet.unit_cost
		writerecord(optFillmntLsDet_dev)optFillmntLsDet$
	wend

[[OPT_FILLMNTHDR.BSHO]]
rem --- Open needed files
	num_files=8
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	
	open_tables$[1]="OPE_ORDHDR",  open_opts$[1]="OTA"
	open_tables$[2]="OPE_ORDDET",  open_opts$[2]="OTA"
	open_tables$[3]="OPE_ORDLSDET",  open_opts$[3]="OTA"
	open_tables$[4]="OPT_FILLMNTDET",  open_opts$[4]="OTA"
	open_tables$[5]="OPT_FILLMNTLSDET",  open_opts$[5]="OTA"
	open_tables$[6]="OPT_CARTHDR",  open_opts$[6]="OTA"
	open_tables$[7]="IVS_PARAMS",   open_opts$[7]="OTA"
	open_tables$[8]="IVM_ITEMMAST",   open_opts$[8]="OTA"

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



