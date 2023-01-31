[[OPT_CARTHDR.ADGE]]
rem --- Get and hold on to column for shipped_flag
	packShipGrid!=callpoint!.getDevObject("packShipGrid")
	shippedFlag_hdr$=callpoint!.getTableColumnAttribute("OPT_CARTHDR.SHIPPED_FLAG","LABS")
	shippedFlag_col=util.getGridColumnNumber(packShipGrid!,shippedFlag_hdr$)
	callpoint!.setDevObject("shippedFlag_col",shippedFlag_col)

[[OPT_CARTHDR.AGDR]]
rem --- Enable Pack Carton button for existing rows
	callpoint!.setOptionEnabled("CART",1)

rem --- Disable/enable fields depending on shipped_flag
	row=callpoint!.getValidationRow()
	if callpoint!.getColumnData("OPT_CARTHDR.SHIPPED_FLAG")="Y" then
		rem --- Disable fields if carton has been shipped
		callpoint!.setColumnEnabled(row,"OPT_CARTHDR.CARTON_NO",0)
		callpoint!.setColumnEnabled(row,"OPT_CARTHDR.TRACKING_NO",0)
		callpoint!.setColumnEnabled(row,"OPT_CARTHDR.CARRIER_CODE",0)
		callpoint!.setColumnEnabled(row,"OPT_CARTHDR.SCAC_CODE",0)
		callpoint!.setColumnEnabled(row,"OPT_CARTHDR.WEIGHT",0)
		callpoint!.setColumnEnabled(row,"OPT_CARTHDR.FREIGHT_AMT",0)
	else
		rem --- Enable fields if carton has NOT been shipped
		callpoint!.setColumnEnabled(row,"OPT_CARTHDR.CARTON_NO",1)
		callpoint!.setColumnEnabled(row,"OPT_CARTHDR.TRACKING_NO",1)
		callpoint!.setColumnEnabled(row,"OPT_CARTHDR.CARRIER_CODE",1)
		callpoint!.setColumnEnabled(row,"OPT_CARTHDR.SCAC_CODE",1)
		callpoint!.setColumnEnabled(row,"OPT_CARTHDR.WEIGHT",1)
		callpoint!.setColumnEnabled(row,"OPT_CARTHDR.FREIGHT_AMT",1)

		rem --- Disable Freight Amount if using a 3rd Party Shipping ID
		if cvs(callpoint!.getDevObject("shipping_id"),2)<>"" then
			callpoint!.setColumnEnabled(row,"OPT_CARTHDR.FREIGHT_AMT",0)
		endif
	endif

[[OPT_CARTHDR.AGRN]]
rem --- Disable Pack Carton button for new rows
	if callpoint!.getGridRowNewStatus(callpoint!.getValidationRow())="Y" then
		callpoint!.setOptionEnabled("CART",0)
	else
		callpoint!.setOptionEnabled("CART",1)
	endif

rem --- Disable Freight Amount if using a 3rd Party Shipping ID
	row=callpoint!.getValidationRow()
	if cvs(callpoint!.getDevObject("shipping_id"),2)<>"" then
		callpoint!.setColumnEnabled(row,"OPT_CARTHDR.FREIGHT_AMT",0)
	else
		callpoint!.setColumnEnabled(row,"OPT_CARTHDR.FREIGHT_AMT",1)
	endif

rem --- Capture starting freight_amt and weight
	callpoint!.setDevObject("startFreightAmt",num(callpoint!.getColumnData("OPT_CARTHDR.FREIGHT_AMT")))
	callpoint!.setDevObject("startWeight",num(callpoint!.getColumnData("OPT_CARTHDR.WEIGHT")))

[[OPT_CARTHDR.AOPT-CART]]
rem --- Initialize grid with unpacked picked items in OPT_FILLMNTDET
	if callpoint!.getDevObject("all_packed")<>"Y" and callpoint!.getColumnData("OPT_CARTHDR.SHIPPED_FLAG")<>"Y" then
		ar_type$=callpoint!.getColumnData("OPT_CARTHDR.AR_TYPE")
		customer_id$=callpoint!.getColumnData("OPT_CARTHDR.CUSTOMER_ID")
		order_no$=callpoint!.getColumnData("OPT_CARTHDR.ORDER_NO")
		ar_inv_no$=callpoint!.getColumnData("OPT_CARTHDR.AR_INV_NO")
		carton_no$=callpoint!.getColumnData("OPT_CARTHDR.CARTON_NO")
		optCartDet_trip$=firm_id$+"E"+ar_type$+customer_id$+order_no$+ar_inv_no$+carton_no$

		optCartDet_dev=fnget_dev("OPT_CARTDET")
		dim optCartDet$:fnget_tpl$("OPT_CARTDET")
		read(optCartDet_dev,key=optCartDet_trip$,knum="AO_STATUS",dom=*next)
		optCartDet_key$=key(optCartDet_dev,end=*next)
		if pos(optCartDet_trip$=optCartDet_key$)=1 then
			rem --- Grid already initialized
		else
			rem --- Ask if they want to pack all remaining unpacked picked items (must include lot/serial numbers)
			msg_id$ = "OP_PACK_CARTON"
			gosub disp_message
			if msg_opt$="Y" then
				rem --- Initialize grid
				lsSeqNo=0
				optCartDet2_dev=fnget_dev("OPT_CARTDET2")
				dim optCartDet2$:fnget_tpl$("OPT_CARTDET2")
				optCartLsDet2_dev=fnget_dev("OPT_CARTLSDET2")
				dim optCartLsDet2$:fnget_tpl$("OPT_CARTLSDET2")
				optFillmntDet_dev=fnget_dev("OPT_FILLMNTDET")
				dim optFillmntDet$:fnget_tpl$("OPT_FILLMNTDET")
				optFillmntLsDet_dev=fnget_dev("OPT_FILLMNTLSDET")
				dim optFillmntLsDet$:fnget_tpl$("OPT_FILLMNTLSDET")
				optFillmntDet_trip$=firm_id$+"E"+ar_type$+customer_id$+order_no$+ar_inv_no$

				read(optFillmntDet_dev,key=optFillmntDet_trip$,knum="AO_STATUS",dom=*next)
				while 1
					optFillmntDet_key$=key(optFillmntDet_dev,end=*break)
					if pos(optFillmntDet_trip$=optFillmntDet_key$)<>1 then break
					readrecord(optFillmntDet_dev)optFillmntDet$
					orddet_seq_ref$=optFillmntDet.orddet_seq_ref$

					rem --- Skip if already fully packed in other cartoons
					alreadyPacked=0
					optCartDet2_trip$=firm_id$+"E"+ar_type$+customer_id$+order_no$+ar_inv_no$+orddet_seq_ref$
					read(optCartDet2_dev,key=optCartDet2_trip$,knum="AO_ORDDET_CART",dom=*next)
					while 1
						optCartDet2_key$=key(optCartDet2_dev,end=*break)
						if pos(optCartDet2_trip$=optCartDet2_key$)<>1 then break
						readrecord(optCartDet2_dev)optCartDet2$
						alreadyPacked=alreadyPacked+optCartDet2.qty_packed
					wend
					if alreadyPacked>=optFillmntDet.qty_picked then continue

					redim optCartDet2$
					optCartDet2.firm_id$=firm_id$
					optCartDet2.ar_type$=ar_type$
					optCartDet2.customer_id$=customer_id$
					optCartDet2.order_no$=order_no$
					optCartDet2.ar_inv_no$=ar_inv_no$
					optCartDet2.carton_no$=carton_no$
					optCartDet2.orddet_seq_ref$=orddet_seq_ref$
					optCartDet2.warehouse_id$=optFillmntDet.warehouse_id$
					optCartDet2.item_id$=optFillmntDet.item_id$
					optCartDet2.order_memo$=optFillmntDet.order_memo$
					optCartDet2.um_sold$=optFillmntDet.um_sold$
					optCartDet2.created_user$=sysinfo.user_id$
					optCartDet2.created_date$=date(0:"%Yd%Mz%Dz")
					optCartDet2.created_time$=date(0:"%Hz%mz")
					optCartDet2.trans_status$="E"
					optCartDet2.qty_packed=optFillmntDet.qty_picked-alreadyPacked
					writerecord(optCartDet2_dev)optCartDet2$

					rem --- Must include lot/serial numbers
					optFillmntLsDet_trip$=firm_id$+"E"+ar_type$+customer_id$+order_no$+ar_inv_no$+orddet_seq_ref$
					read(optFillmntLsDet_dev,key=optFillmntLsDet_trip$,knum="AO_STATUS",dom=*next)
					while 1
						optFillmntLsDet_key$=key(optFillmntLsDet_dev,end=*break)
						if pos(optFillmntLsDet_trip$=optFillmntLsDet_key$)<>1 then break
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

						lsSeqNo=lsSeqNo+1
						redim optCartLsDet2$
						optCartLsDet2.firm_id$=firm_id$
						optCartLsDet2.ar_type$=ar_type$
						optCartLsDet2.customer_id$=customer_id$
						optCartLsDet2.order_no$=order_no$
						optCartLsDet2.ar_inv_no$=ar_inv_no$
						optCartLsDet2.carton_no$=carton_no$
						optCartLsDet2.orddet_seq_ref$=orddet_seq_ref$
						optCartLsDet2.sequence_no$=str(lsSeqNo,"000")
						optCartLsDet2.lotser_no$=optFillmntLsDet.lotser_no$
						optCartLsDet2.created_user$=sysinfo.user_id$
						optCartLsDet2.created_date$=date(0:"%Yd%Mz%Dz")
						optCartLsDet2.created_time$=date(0:"%Hz%mz")
						optCartLsDet2.trans_status$="E"
						optCartLsDet2.qty_packed=optFillmntLsDet.qty_picked-alreadyPacked
						writerecord(optCartLsDet2_dev)optCartLsDet2$
					wend
				wend
			endif
		endif
	endif

rem --- Launch Carton Packing grid
	ar_type$=callpoint!.getColumnData("OPT_CARTHDR.AR_TYPE")
	cust$=callpoint!.getColumnData("OPT_CARTHDR.CUSTOMER_ID")
	order$=callpoint!.getColumnData("OPT_CARTHDR.ORDER_NO")
	invoice$=callpoint!.getColumnData("OPT_CARTHDR.AR_INV_NO")
	carton$=callpoint!.getColumnData("OPT_CARTHDR.CARTON_NO")

	key_pfx$=firm_id$+"E"+ar_type$+cust$+order$+invoice$+carton$

	rem --- Pass additional info needed in OPT_CARTDET
	if callpoint!.getDevObject("all_packed")="Y" then
		callpoint!.setDevObject("shipped_flag", "Y")
	else
		callpoint!.setDevObject("shipped_flag", callpoint!.getColumnData("OPT_CARTHDR.SHIPPED_FLAG"))
	endif

	call stbl("+DIR_SYP") + "bam_run_prog.bbj", 
:		"OPT_CARTDET", 
:		stbl("+USER_ID"), 
:		"MNT" ,
:		key_pfx$, 
:		table_chans$[all], 
:		dflt_data$[all]

	callpoint!.setStatus("ACTIVATE")

[[OPT_CARTHDR.AREC]]
rem --- Initialize records with the ARC_SHIPVIACODE record for the OPT_FILLMNTHDR.AR_SHIP_VIA.
	arcShipViaCode_dev=fnget_dev("ARC_SHIPVIACODE")
	dim arcShipViaCode$:fnget_tpl$("ARC_SHIPVIACODE")
	ar_ship_via$=callpoint!.getDevObject("ar_ship_via")
	readrecord(arcShipViaCode_dev,key=firm_id$+ar_ship_via$,dom=*next)arcShipViaCode$
	callpoint!.setColumnData("OPT_CARTHDR.CARRIER_CODE",arcShipViaCode.carrier_code$,1)
	callpoint!.setColumnData("OPT_CARTHDR.SCAC_CODE",arcShipViaCode.scac_code$,1)

rem --- Initialize other displayed fields
	callpoint!.setColumnData("OPT_CARTHDR.SHIPPED_FLAG","N",1)
	callpoint!.setColumnData("OPT_CARTHDR.WEIGHT","0",1)
	callpoint!.setColumnData("OPT_CARTHDR.FREIGHT_AMT","0",1)

	if cvs(callpoint!.getDevObject("shipping_id"),2)<>"" then
		callpoint!.setColumnEnabled(row,"OPT_CARTHDR.FREIGHT_AMT",0)
	else
		callpoint!.setColumnEnabled(row,"OPT_CARTHDR.FREIGHT_AMT",1)
	endif

rem --- Initialize RTP trans_status and created fields
	rem --- TRANS_STATUS set to "E" via form Preset Value
	callpoint!.setColumnData("OPT_CARTHDR.CREATED_USER",sysinfo.user_id$)
	callpoint!.setColumnData("OPT_CARTHDR.CREATED_DATE",date(0:"%Yd%Mz%Dz"))
	callpoint!.setColumnData("OPT_CARTHDR.CREATED_TIME",date(0:"%Hz%mz"))

[[OPT_CARTHDR.AUDE]]
rem --- Restore associated OPT_CARTDET/OPT_CARTDET2 and OPT_CARTLSDET/OPT_CARTLSDET2 records, 
	removedOptCartDet! = callpoint!.getDevObject("removedOptCartDet")
	removedOptCartLsDet! = callpoint!.getDevObject("removedOptCartLsDet")
	optCartDet_dev=fnget_dev("OPT_CARTDET")
	optCartLsDet_dev=fnget_dev("OPT_CARTLSDET")
	ar_type$=callpoint!.getColumnData("OPT_CARTHDR.AR_TYPE")
	customer_id$=callpoint!.getColumnData("OPT_CARTHDR.CUSTOMER_ID")
	order_no$=callpoint!.getColumnData("OPT_CARTHDR.ORDER_NO")
	ar_inv_no$=callpoint!.getColumnData("OPT_CARTHDR.AR_INV_NO")
	carton_no$=callpoint!.getColumnData("OPT_CARTHDR.CARTON_NO")

	if removedOptCartDet!.size()>0 then
		optCartHdr_key$=firm_id$+ar_type$+customer_id$+order_no$+ar_inv_no$+carton_no$
		removedOptCartDet_keys! = removedOptCartDet!.keySet()
		removedOptCartDet_iter! = removedOptCartDet_keys!.iterator()
		while removedOptCartDet_iter!.hasNext()
			thisOptCartDet_key$=removedOptCartDet_iter!.next()
			if pos(optCartHdr_key$=thisOptCartDet_key$)<>1 then continue

			if removedOptCartLsDet!.size()>0 then
				removedOptCartLsDet_keys! = removedOptCartLsDet!.keySet()
				removedOptCartLsDet_iter! = removedOptCartLsDet_keys!.iterator()
				while removedOptCartLsDet_iter!.hasNext()
					thisOptCartLsDet_key$=removedOptCartLsDet_iter!.next()
					if pos(thisOptCartDet_key$=thisOptCartLsDet_key$)<>1 then continue

					optCartLsDet_vect! = removedOptCartLsDet!.get(thisOptCartLsDet_key$)
					if optCartLsDet_vect!.size()=0 then continue
					for i=optCartLsDet_vect!.size()-1 to 0 step -1
						optCartLsDet_record$=optCartLsDet_vect!.removeItem(i)
						writerecord(optCartLsDet_dev)optCartLsDet_record$
					next i
					removedOptCartLsDet!.put(thisOptCartLsDet_key$,optCartLsDet_vect!)
				wend
			endif

			optCartDet_vect! = removedOptCartDet!.get(thisOptCartDet_key$)
			if optCartDet_vect!.size()=0 then continue
			for i=optCartDet_vect!.size()-1 to 0 step -1
				optCartDet_record$=optCartDet_vect!.removeItem(i)
				writerecord(optCartDet_dev)optCartDet_record$
			next i
			removedOptCartDet!.put(thisOptCartDet_key$,optCartDet_vect!)
		wend
	endif

	callpoint!.setDevObject("removedOptCartDet",removedOptCartDet!)
	callpoint!.setDevObject("removedOptCartLsDet",removedOptCartLsDet!)

[[OPT_CARTHDR.AWRI]]
rem --- Update the <<DISPLAY>>.FREIGHT_AMT and <<DISPALY>>.WEIGHT on OPT_FILLMNTHDR form
	currentFreighAmt=num(callpoint!.getColumnData("OPT_CARTHDR.FREIGHT_AMT"))
	startFreightAmt=callpoint!.getDevObject("startFreightAmt")
	if currentFreighAmt<>startFreightAmt then
		totalFreightAmtCtrl!=callpoint!.getDevObject("totalFreightAmtCtrl")
		totalFreightAmt=num(totalFreightAmtCtrl!.getText())
		totalFreightAmtCtrl!.setText(str(totalFreightAmt+(currentFreighAmt-startFreightAmt)))

		callpoint!.setDevObject("startFreightAmt",currentFreighAmt)
	endif

	currentWeight=num(callpoint!.getColumnData("OPT_CARTHDR.WEIGHT"))
	startWeight=callpoint!.getDevObject("startWeight")
	if currentWeight<>startWeight then
		totalWeightCtrl!=callpoint!.getDevObject("totalWeightCtrl")
		totalWeight=num(totalWeightCtrl!.getText())
		totalWeightCtrl!.setText(str(totalWeight+(currentWeight-startWeight)))

		callpoint!.setDevObject("startWeight",currentWeight)
	endif

[[OPT_CARTHDR.BDEL]]
rem --- Cannot delete cartons that are shipped
	if callpoint!.getColumnData("OPT_CARTHDR.SHIPPED_FLAG")="Y" then
		msg_id$ = "OP_CARTON_SHIPPED"
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- Delete associated OPT_CARTDET/OPT_CARTDET2 and OPT_CARTLSDET/OPT_CARTLSDET2 records, 
rem --- but save a copy for possible undelete of this record.
	removedOptCartDet! = callpoint!.getDevObject("removedOptCartDet")
	removedOptCartLsDet! = callpoint!.getDevObject("removedOptCartLsDet")
	optCartDet_dev=fnget_dev("OPT_CARTDET")
	dim optCartDet$:fnget_tpl$("OPT_CARTDET")
	optCartLsDet_dev=fnget_dev("OPT_CARTLSDET")
	dim optCartLsDet$:fnget_tpl$("OPT_CARTLSDET")
	ar_type$=callpoint!.getColumnData("OPT_CARTHDR.AR_TYPE")
	customer_id$=callpoint!.getColumnData("OPT_CARTHDR.CUSTOMER_ID")
	order_no$=callpoint!.getColumnData("OPT_CARTHDR.ORDER_NO")
	ar_inv_no$=callpoint!.getColumnData("OPT_CARTHDR.AR_INV_NO")
	carton_no$=callpoint!.getColumnData("OPT_CARTHDR.CARTON_NO")

	optCartDet_vect! = BBjAPI().makeVector()
	optCartDet_trip$=firm_id$+ar_type$+customer_id$+order_no$+ar_inv_no$+carton_no$
	read(optCartDet_dev,key=optCartDet_trip$,knum="PRIMARY",dom=*next)
	while 1
		optCartDet_key$=key(optCartDet_dev,end=*break)
		if pos(optCartDet_trip$=optCartDet_key$)<>1 then break
		readrecord(optCartDet_dev)optCartDet$

		optCartLsDet_vect! = BBjAPI().makeVector()
		optCartLsDet_trip$=optCartDet_trip$+optCartDet.orddet_seq_ref$
		read(optCartLsDet_dev,key=optCartLsDet_trip$,knum="PRIMARY",dom=*next)
		while 1
			optCartLsDet_key$=key(optCartLsDet_dev,end=*break)
			if pos(optCartLsDet_trip$=optCartLsDet_key$)<>1 then break
			readrecord(optCartLsDet_dev)optCartLsDet$

			optCartLsDet_vect!.addItem(optCartLsDet$)
			remove(optCartLsDet_dev,key=optCartLsDet_key$)
		wend
		removedOptCartLsDet!.put(optCartDet_trip$,optCartLsDet_vect!)

		optCartDet_vect!.addItem(optCartDet$)
		remove(optCartDet_dev,key=optCartDet_key$)
	wend
	removedOptCartDet!.put(optCartDet_trip$,optCartDet_vect!)

	callpoint!.setDevObject("removedOptCartDet",removedOptCartDet!)
	callpoint!.setDevObject("removedOptCartLsDet",removedOptCartLsDet!)

[[OPT_CARTHDR.BDGX]]
rem --- Disable detail-only buttons
	callpoint!.setOptionEnabled("CART",0)

[[OPT_CARTHDR.BWRI]]
rem --- Initialize RTP modified fields for modified existing records
	if callpoint!.getGridRowNewStatus(callpoint!.getValidationRow())<>"Y" then
		callpoint!.setColumnData("OPT_CARTHDR.MOD_USER", sysinfo.user_id$)
		callpoint!.setColumnData("OPT_CARTHDR.MOD_DATE", date(0:"%Yd%Mz%Dz"))
		callpoint!.setColumnData("OPT_CARTHDR.MOD_TIME", date(0:"%Hz%mz"))
	endif

[[OPT_CARTHDR.CARTON_NO.AVAL]]
rem --- Enable Pack Carton button for new carton
	if callpoint!.getGridRowNewStatus(callpoint!.getValidationRow())="Y" then callpoint!.setOptionEnabled("CART",1)

[[OPT_CARTHDR.SHIPPED_FLAG.AVAL]]
rem --- Disable/enable fields depending on shipped_flag
	row=callpoint!.getValidationRow()
	if callpoint!.getColumnData("OPT_CARTHDR.SHIPPED_FLAG")="Y" then
		rem --- Disable fields if carton has been shipped
		callpoint!.setColumnEnabled(row,"OPT_CARTHDR.CARTON_NO",0)
		callpoint!.setColumnEnabled(row,"OPT_CARTHDR.TRACKING_NO",0)
		callpoint!.setColumnEnabled(row,"OPT_CARTHDR.CARRIER_CODE",0)
		callpoint!.setColumnEnabled(row,"OPT_CARTHDR.SCAC_CODE",0)
		callpoint!.setColumnEnabled(row,"OPT_CARTHDR.WEIGHT",0)
		callpoint!.setColumnEnabled(row,"OPT_CARTHDR.FREIGHT_AMT",0)
	else
		rem --- Enable fields if carton has not been shipped
		callpoint!.setColumnEnabled(row,"OPT_CARTHDR.CARTON_NO",1)
		callpoint!.setColumnEnabled(row,"OPT_CARTHDR.TRACKING_NO",1)
		callpoint!.setColumnEnabled(row,"OPT_CARTHDR.CARRIER_CODE",1)
		callpoint!.setColumnEnabled(row,"OPT_CARTHDR.SCAC_CODE",1)
		callpoint!.setColumnEnabled(row,"OPT_CARTHDR.WEIGHT",1)
		callpoint!.setColumnEnabled(row,"OPT_CARTHDR.FREIGHT_AMT",1)
	endif

[[OPT_CARTHDR.<CUSTOM>]]

rem ==========================================================================
rem 	Use util object
rem ==========================================================================
	use ::ado_util.src::util



