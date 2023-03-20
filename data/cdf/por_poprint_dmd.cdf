[[POR_POPRINT_DMD.AREC]]
rem --- use ReportControl object to see if this vendor is set up for email/fax of the PO

	use ::ado_rptControl.src::ReportControl

	rpt_id$=pad("POR_POPRINT",16);rem use POR_POPRINT for regular (batch) POs and on-demand, so vendor recipients don't need to be set up multiple times

rem --- See if this document/recipient is set up in Addon Report Control

	reportControl!=new ReportControl()
	found=reportControl!.getRecipientInfo(rpt_id$,"",callpoint!.getColumnData("POR_POPRINT_DMD.VENDOR_ID"))
	
	if found and (reportControl!.getEmailYN()="Y" or reportControl!.getFaxYN()="Y")
		callpoint!.setColumnEnabled("POR_POPRINT_DMD.RPT_CONTROL",1)
	else
		callpoint!.setColumnEnabled("POR_POPRINT_DMD.RPT_CONTROL",0)
	endif

	rem --- destroy to close files so they don't get opened repeatedly with each iteration
	reportControl!.destroy()
	reportControl! = null()

rem --- Set historical print flag
	if callpoint!.getDevObject("historical_print")<>null() then
		historical_print$=callpoint!.getDevObject("historical_print")
		callpoint!.setColumnData("POR_POPRINT_DMD.HISTORICAL_PRINT",historical_print$)
	else
		callpoint!.setColumnData("POR_POPRINT_DMD.HISTORICAL_PRINT","")
	endif



