[[OPT_CARTHDR.AGDR]]
rem --- Enable Pack Carton button for existing rows
	callpoint!.setOptionEnabled("CART",1)

[[OPT_CARTHDR.AGRN]]
rem --- Disable Pack Carton button for new rows
	if callpoint!.getGridRowNewStatus(callpoint!.getValidationRow())="Y" then
		callpoint!.setOptionEnabled("CART",0)
	else
		callpoint!.setOptionEnabled("CART",1)
	endif

[[OPT_CARTHDR.AOPT-CART]]
rem --- Initialize grid with unpacked picked items in OPT_FILLMNTDET
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

rem --- Launch Carton Packing grid
	ar_type$=callpoint!.getColumnData("OPT_CARTHDR.AR_TYPE")
	cust$=callpoint!.getColumnData("OPT_CARTHDR.CUSTOMER_ID")
	order$=callpoint!.getColumnData("OPT_CARTHDR.ORDER_NO")
	invoice$=callpoint!.getColumnData("OPT_CARTHDR.AR_INV_NO")
	carton$=callpoint!.getColumnData("OPT_CARTHDR.CARTON_NO")

	key_pfx$=firm_id$+"E"+ar_type$+cust$+order$+invoice$+carton$

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

rem --- Initialize RTP trans_status and created fields
	rem --- TRANS_STATUS set to "E" via form Preset Value
	callpoint!.setColumnData("OPT_CARTHDR.CREATED_USER",sysinfo.user_id$)
	callpoint!.setColumnData("OPT_CARTHDR.CREATED_DATE",date(0:"%Yd%Mz%Dz"))
	callpoint!.setColumnData("OPT_CARTHDR.CREATED_TIME",date(0:"%Hz%mz"))

[[OPT_CARTHDR.AUDE]]
rem wgh ... 10304 ... Need to restore corresponding OPT_CARTLSDET records

[[OPT_CARTHDR.BDEL]]
rem wgh ... 10304 ... Need to delete corresponding OPT_CARTLSDET records

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



