[[OPT_CARTLSDET2.AOPT-LLOK]]
rem --- Luanch lookup for unpacked picked inventoried lot/serial numbers
	if !callpoint!.getDevObject("non_inventory") then 
		call stbl("+DIR_SYP")+"bac_key_template.bbj","OPT_FILLMNTLSDET","PRIMARY",key_tpl$,rd_table_chans$[all],status$
		dim optFillmntLsDet_key$:key_tpl$
		keyLength=len(optFillmntLsDet_key$)
		dim filter_defs$[7,2]
		filter_defs$[1,0]="OPT_FILLMNTLSDET.FIRM_ID"
		filter_defs$[1,1]="='"+firm_id$ +"'"
		filter_defs$[1,2]="LOCK"
		filter_defs$[2,0]="OPT_FILLMNTLSDET.TRANS_STATUS"
		filter_defs$[2,1]="='E'"
		filter_defs$[2,2]="LOCK"
		filter_defs$[3,0]="OPT_FILLMNTLSDET.AR_TYPE"
		filter_defs$[3,1]="='"+callpoint!.getColumnData("OPT_CARTLSDET2.AR_TYPE")+"'"
		filter_defs$[3,2]="LOCK"
		filter_defs$[4,0]="OPT_FILLMNTLSDET.CUSTOMER_ID"
		filter_defs$[4,1]="='"+callpoint!.getColumnData("OPT_CARTLSDET2.CUSTOMER_ID")+"'"
		filter_defs$[4,2]="LOCK"
		filter_defs$[5,0]="OPT_FILLMNTLSDET.ORDER_NO"
		filter_defs$[5,1]="='"+callpoint!.getColumnData("OPT_CARTLSDET2.ORDER_NO")+"'"
		filter_defs$[5,2]="LOCK"
		filter_defs$[6,0]="OPT_FILLMNTLSDET.AR_INV_NO"
		filter_defs$[6,1]="='"+callpoint!.getColumnData("OPT_CARTLSDET2.AR_INV_NO")+"'"
		filter_defs$[6,2]="LOCK"
		filter_defs$[7,0]="OPT_FILLMNTLSDET.ORDDET_SEQ_REF"
		filter_defs$[7,1]="='"+callpoint!.getColumnData("OPT_CARTLSDET2.ORDDET_SEQ_REF")+"'"
		filter_defs$[7,2]="LOCK"

		call stbl("+DIR_SYP")+"bax_query.bbj",gui_dev,form!,"OP_UNPACKED_LS","",table_chans$[all],optFillmntLsDet_key$,filter_defs$[all]

		rem --- Update lotser_no with selected lot/serial number
		if cvs(optFillmntLsDet_key$,2)<>"" then
			optFillmntLsDet_dev=fnget_dev("OPT_FILLMNTLSDET")
			dim optFillmntLsDet$:fnget_tpl$("OPT_FILLMNTLSDET")
			readrecord(optFillmntLsDet_dev,key=optFillmntLsDet_key$(1,keyLength),knum="PRIMARY")optFillmntLsDet$
			lotser_no$=optFillmntLsDet.lotser_no$
			callpoint!.setColumnData( "OPT_CARTLSDET2.LOTSER_NO",lotser_no$,1)
			qty_picked=num(callpoint!.getDevObject("qty_picked"))
			gosub getUnpacked
			if unpacked>qty_picked then
				callpoint!.setColumnData("OPT_CARTLSDET2.QTY_PACKED",str(qty_picked),1)
			else
				callpoint!.setColumnData("OPT_CARTLSDET2.QTY_PACKED",str(unpacked),1)
			endif

			callpoint!.setStatus("MODIFIED")
		endif
	endif

[[OPT_CARTLSDET2.AREC]]
rem ---Initialize fields needed for CARTON_NO Lot/Serial lookup
	call stbl("+DIR_SYP")+"bac_key_template.bbj","OPT_CARTLSDET2","AO_ORDDET_CART",key_tpl$,table_chans$[all],status$
	dim optCartLsDet2_keyPrefix$:key_tpl$
	optCartLsDet2_keyPrefix$=callpoint!.getKeyPrefix()
	callpoint!.setColumnData("OPT_CARTLSDET2.AR_TYPE",optCartLsDet2_keyPrefix.ar_type$)
	callpoint!.setColumnData("OPT_CARTLSDET2.CUSTOMER_ID",optCartLsDet2_keyPrefix.customer_id$)
	callpoint!.setColumnData("OPT_CARTLSDET2.ORDER_NO",optCartLsDet2_keyPrefix.order_no$)
	callpoint!.setColumnData("OPT_CARTLSDET2.AR_INV_NO",optCartLsDet2_keyPrefix.ar_inv_no$)
	callpoint!.setColumnData("OPT_CARTLSDET2.ORDDET_SEQ_REF",optCartLsDet2_keyPrefix.orddet_seq_ref$)

rem --- Initialize RTP trans_status and created fields
	rem --- TRANS_STATUS set to "E" via form Preset Value
	callpoint!.setColumnData("OPT_CARTLSDET2.CREATED_USER",sysinfo.user_id$)
	callpoint!.setColumnData("OPT_CARTLSDET2.CREATED_DATE",date(0:"%Yd%Mz%Dz"))
	callpoint!.setColumnData("OPT_CARTLSDET2.CREATED_TIME",date(0:"%Hz%mz"))

[[OPT_CARTLSDET2.BEND]]
rem --- Update total qty_packed in the Packing Carton detail grid with the total qty_packed here
	totalPacked=0
	optCartLsDet_dev=fnget_dev("OPT_CARTLSDET")
	dim optCartLsDet$:fnget_tpl$("OPT_CARTLSDET")
	ar_type$=callpoint!.getColumnData("OPT_CARTLSDET2.AR_TYPE")
	customer_id$=callpoint!.getColumnData("OPT_CARTLSDET2.CUSTOMER_ID")
	order_no$=callpoint!.getColumnData("OPT_CARTLSDET2.ORDER_NO")
	ar_inv_no$=callpoint!.getColumnData("OPT_CARTLSDET2.AR_INV_NO")
	carton_no$=callpoint!.getColumnData("OPT_CARTLSDET2.CARTON_NO")
	orddet_seq_ref$=callpoint!.getColumnData("OPT_CARTLSDET2.ORDDET_SEQ_REF")
	optCartLsDet_trip$=firm_id$+"E"+ar_type$+customer_id$+order_no$+ar_inv_no$+carton_no$+orddet_seq_ref$
	read(optCartLsDet_dev,key=optCartLsDet_trip$,knum="AO_STATUS",dom=*next)
	while 1
		thisKey$=key(optCartLsDet_dev,end=*break)
		if pos(optCartLsDet_trip$=thisKey$)<>1 then break
		readrecord(optCartLsDet_dev)optCartLsDet$
		totalPacked=totalPacked+optCartLsDet.qty_packed
	wend
	callpoint!.setDevObject("total_packed",totalPacked)

[[OPT_CARTLSDET2.BSHO]]
rem --- Set a flag for non-inventoried items
	ivmItemMast_dev=fnget_dev("IVM_ITEMMAST")
	dim ivmItemMast$:fnget_tpl$("IVM_ITEMMAST")
	item_id$=callpoint!.getDevObject("item_id")
	findrecord (ivmItemMast_dev,key=firm_id$+item_id$,dom=*next)ivmItemMast$
	if ivmItemMast$.inventoried$<>"Y" or callpoint!.getDevObject("dropship_line")="Y" then
		callpoint!.setDevObject("non_inventory",1)
	else
		callpoint!.setDevObject("non_inventory",0)
	endif

rem --- Set Lot/Serial button up properly
	switch pos(callpoint!.getDevObject("lotser_flag")="LS")
		case 1; callpoint!.setOptionText("LLOK",Translate!.getTranslation("AON_LOT_LOOKUP")); break
		case 2; callpoint!.setOptionText("LLOK",Translate!.getTranslation("AON_SERIAL_LOOKUP")); break
	swend

rem --- No serial/lot lookup for non-inventory items
	if callpoint!.getDevObject("non_inventory") then
		callpoint!.setOptionEnabled("LLOK", 0)
	else
		callpoint!.setOptionEnabled("LLOK", 1)
	endif

[[OPT_CARTLSDET2.BWRI]]
rem --- Initialize RTP modified fields for modified existing records
	if callpoint!.getGridRowNewStatus(callpoint!.getValidationRow())<>"Y" then
		callpoint!.setColumnData("OPT_CARTLSDET2.MOD_USER", sysinfo.user_id$)
		callpoint!.setColumnData("OPT_CARTLSDET2.MOD_DATE", date(0:"%Yd%Mz%Dz"))
		callpoint!.setColumnData("OPT_CARTLSDET2.MOD_TIME", date(0:"%Hz%mz"))
	endif

[[OPT_CARTLSDET2.LOTSER_NO.AVAL]]
rem --- Skip if lotser_no not changed
	lotser_no$=callpoint!.getUserInput()
	if lotser_no$=callpoint!.getColumnData("OPT_CARTLSDET2.LOTSER_NO") then break

rem --- Allow the same lot/serial number only once in the grid
	dim gridrec$:fattr(rec_data$)
	for i=0 to GridVect!.size()-1
		gridrec$=GridVect!.getItem(i)
		if gridrec.lotser_no$=lotser_no$
			msg_id$ = "OP_LOTSER_IN_GRID"
			dim msg_tokens$[1]
			msg_tokens$[1]=cvs(lotser_no$,2)
			gosub disp_message
			callpoint!.setStatus("ABORT")
			break
		endif
	next i

rem --- Validate entered lot/serial number was picked
	lotser_picked=0
	optFillmntLsDet_dev=fnget_dev("OPT_FILLMNTLSDET")
	dim optFillmntLsDet$:fnget_tpl$("OPT_FILLMNTLSDET")
	lotser_no$=pad(lotser_no$,len(optFillmntLsDet.lotser_no$))
	ar_type$=callpoint!.getColumnData("OPT_CARTLSDET2.AR_TYPE")
	customer_id$=callpoint!.getColumnData("OPT_CARTLSDET2.CUSTOMER_ID")
	order_no$=callpoint!.getColumnData("OPT_CARTLSDET2.ORDER_NO")
	ar_inv_no$=callpoint!.getColumnData("OPT_CARTLSDET2.AR_INV_NO")
	orddet_seq_ref$=callpoint!.getColumnData("OPT_CARTLSDET2.ORDDET_SEQ_REF")
	optFillmntLsDet_trip$=firm_id$+"E"+ar_type$+customer_id$+order_no$+ar_inv_no$+orddet_seq_ref$
	read(optFillmntLsDet_dev,key=optFillmntLsDet_trip$,knum="AO_STATUS",dom=*next)
	while 1
		thisKey$=key(optFillmntLsDet_dev,end=*break)
		if pos(optFillmntLsDet_trip$=thisKey$)<>1 then break
		readrecord(optFillmntLsDet_dev)optFillmntLsDet$
		if lotser_no$<>optFillmntLsDet.lotser_no$ then continue
		lotser_picked=1
		break
	wend
	if !lotser_picked then
		msg_id$ = "OP_LS_NOT_PICKED"
		dim msg_tokens$[1]
		msg_tokens$[1] = cvs(lotser_no$,2)
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- Default lot/serial number qty_packed to remaining unpacked picked quantity, if not fully packed
	row=callpoint!.getValidationRow()
	if callpoint!.getGridRowNewStatus(row)="Y" then
		qty_picked=num(callpoint!.getDevObject("qty_picked"))
		gosub getUnpacked
		if unpacked>qty_picked then
			callpoint!.setColumnData("OPT_CARTLSDET2.QTY_PACKED",str(qty_picked),1)
		else
			callpoint!.setColumnData("OPT_CARTLSDET2.QTY_PACKED",str(unpacked),1)
		endif
	endif

[[OPT_CARTLSDET2.QTY_PACKED.AVAL]]
rem --- Entered qty_packed cannot be greater than unpacked quantity picked
	qty_packed=num(callpoint!.getUserInput())
	prev_qty_packed=num(callpoint!.getColumnData("OPT_CARTLSDET2.QTY_PACKED"))
	qty_picked=num(callpoint!.getDevObject("qty_picked"))
	lotser_no$=callpoint!.getColumnData("OPT_CARTLSDET2.LOTSER_NO")
	gosub getUnpacked
	unpacked=unpacked+prev_qty_packed
	if unpacked>qty_picked then
		maxPack=qty_picked
	else
		maxPack=unpacked
	endif
	if qty_packed>maxPack then
		dim msg_tokens$[2]
		msg_id$ = "OP_PACK_EXCEEDS_PICK"
		msg_tokens$[1]=str(qty_packed)
		msg_tokens$[2]=str(maxPack)
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif

[[OPT_CARTLSDET2.<CUSTOM>]]
rem ==========================================================================
getUnpacked: rem --- Get total unpacked lot/serial number quantity. It could be a lot packed in more than one carton.
               rem      IN: lotser_no$
               rem   OUT: already_packed
	       rem         : unpacked
rem ==========================================================================
	already_packed=0
	optCartLsDet2_dev=fnget_dev("OPT_CARTLSDET2")
	dim optCartLsDet2$:fnget_tpl$("OPT_CARTLSDET2")
	ar_type$=callpoint!.getColumnData("OPT_CARTLSDET2.AR_TYPE")
	customer_id$=callpoint!.getColumnData("OPT_CARTLSDET2.CUSTOMER_ID")
	order_no$=callpoint!.getColumnData("OPT_CARTLSDET2.ORDER_NO")
	ar_inv_no$=callpoint!.getColumnData("OPT_CARTLSDET2.AR_INV_NO")
	orddet_seq_ref$=callpoint!.getColumnData("OPT_CARTLSDET2.ORDDET_SEQ_REF")
	optCartLsDet2_trip$=firm_id$+"E"+ar_type$+customer_id$+order_no$+ar_inv_no$+orddet_seq_ref$
	read(optCartLsDet2_dev,key=optCartLsDet2_trip$,knum="AO_ORDDET_CART",dom=*next)
	while 1
		thisKey$=key(optCartLsDet2_dev,end=*break)
		if pos(optCartLsDet2_trip$=thisKey$)<>1 then break
		readrecord(optCartLsDet2_dev)optCartLsDet2$
		if lotser_no$<>optCartLsDet2.lotser_no$ then continue
		already_packed=already_packed+optCartLsDet2.qty_packed
	wend

	optFillmntLsDet_dev=fnget_dev("OPT_FILLMNTLSDET")
	dim optFillmntLsDet$:fnget_tpl$("OPT_FILLMNTLSDET")
	optFillmntLsDet_trip$=firm_id$+"E"+ar_type$+customer_id$+order_no$+ar_inv_no$+orddet_seq_ref$
	read(optFillmntLsDet_dev,key=optFillmntLsDet_trip$,knum="AO_STATUS",dom=*next)
	while 1
		thisKey$=key(optFillmntLsDet_dev,end=*break)
		if pos(optFillmntLsDet_trip$=thisKey$)<>1 then break
		readrecord(optFillmntLsDet_dev)optFillmntLsDet$
		if lotser_no$<>optFillmntLsDet.lotser_no$ then continue
		qty_picked=optFillmntLsDet.qty_picked
		break
	wend

	unpacked=qty_picked-already_packed

	return



