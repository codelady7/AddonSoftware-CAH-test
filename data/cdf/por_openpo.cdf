[[POR_OPENPO.ARAR]]
callpoint!.setColumnData("POR_OPENPO.REPORT_SEQUENCE","V")
callpoint!.setColumnData("POR_OPENPO.DATE_TYPE","O")
callpoint!.setStatus("REFRESH")

rem --- Enable/disable Work Order fields depending on if Shop Floor is installed
	call pgmdir$+"adc_application.aon","SF",info$[all]
	sf$=info$[20]

	if sf$<>"Y" then
		rem --- SF not installed, disable WO fields
		callpoint!.setColumnEnabled("POR_OPENPO.WO_NO_1",0)
		callpoint!.setColumnEnabled("POR_OPENPO.WO_NO_2",0)
	else
		rem --- SF installed, enable WO fields
		callpoint!.setColumnEnabled("POR_OPENPO.WO_NO_1",1)
		callpoint!.setColumnEnabled("POR_OPENPO.WO_NO_2",1)
	endif

[[POR_OPENPO.BSHO]]



