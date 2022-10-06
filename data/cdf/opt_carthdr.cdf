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
rem wgh ... 10304 ... Ask if they want to pack all remaining unpacked picked items (must include lot/serial numbers)

rem --- Launch Carton Packing grid
	ar_type$=callpoint!.getColumnData("OPT_CARTHDR.AR_TYPE")
	cust$=callpoint!.getColumnData("OPT_CARTHDR.CUSTOMER_ID")
	order$=callpoint!.getColumnData("OPT_CARTHDR.ORDER_NO")
	invoice$=callpoint!.getColumnData("OPT_CARTHDR.AR_INV_NO")
	carton$=callpoint!.getColumnData("OPT_CARTHDR.CARTON_NO")

	key_pfx$=firm_id$+"E"+ar_type$+cust$+order$+invoice$+carton$

	rem --- Pass additional info needed in OPT_CARTDET
	callpoint!.setDevObject("carton_no",carton$)

	call stbl("+DIR_SYP") + "bam_run_prog.bbj", 
:		"OPT_CARTDET", 
:		stbl("+USER_ID"), 
:		"MNT" ,
:		key_pfx$, 
:		table_chans$[all], 
:		dflt_data$[all]

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



