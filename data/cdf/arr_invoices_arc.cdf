[[ARR_INVOICES_ARC.AREC]]
rem --- use ReportControl object to see if this customer is set up for email/fax statement

	use ::ado_rptControl.src::ReportControl

	rpt_id$=pad("ARR_INVOICES",16);rem use ARR_INVOICES for regular (batch) and on-demand, so customers don't have to be set up multiple times in rpt ctl

rem --- See if this document/recipient is set up in Addon Report Control

	reportControl!=new ReportControl()
	found=reportControl!.getRecipientInfo(rpt_id$,callpoint!.getColumnData("ARR_INVOICES_ARC.CUSTOMER_ID"),"")

	if found and (reportControl!.getEmailYN()="Y" or reportControl!.getFaxYN()="Y")
		callpoint!.setColumnEnabled("ARR_INVOICES_ARC.PICK_CHECK",1)
	else
		callpoint!.setColumnEnabled("ARR_INVOICES_ARC.PICK_CHECK",0)
	endif

	rem --- destroy to close files so they don't get opened repeatedly with each iteration
	reportControl!.destroy()
	reportControl! = null()



