[[OPT_CARTHDR.AREC]]
rem --- Initialize records with the ARC_SHIPVIACODE record for the OPT_FILLMNTHDR.AR_SHIP_VIA.
	arcShipViaCode_dev=fnget_dev("ARC_SHIPVIACODE")
	dim arcShipViaCode$:fnget_tpl$("ARC_SHIPVIACODE")
	ar_ship_via$=callpoint!.getDevObject("ar_ship_via")
	readrecord(arcShipViaCode_dev,key=firm_id$+ar_ship_via$,dom=*next)arcShipViaCode$
	callpoint!.setColumnData("OPT_CARTHDR.CARRIER_CODE",arcShipViaCode.carrier_code$,1)
	callpoint!.setColumnData("OPT_CARTHDR.SCAC_CODE",arcShipViaCode.scac_code$,1)

rem --- Initialize RTP trans_status and created fields
	rem --- TRANS_STATUS set to "E" via form Preset Value
	callpoint!.setColumnData("OPT_CARTHDR.CREATED_USER",sysinfo.user_id$)
	callpoint!.setColumnData("OPT_CARTHDR.CREATED_DATE",date(0:"%Yd%Mz%Dz"))
	callpoint!.setColumnData("OPT_CARTHDR.CREATED_TIME",date(0:"%Hz%mz"))



