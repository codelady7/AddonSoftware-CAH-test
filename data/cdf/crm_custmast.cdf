[[CRM_CUSTMAST.ARER]]
callpoint!.setColumnData("CRM_CUSTDET.INV_HIST_FLG","Y")

[[CRM_CUSTMAST.BSHO]]
rem  Initializations
	use ::ado_util.src::util

[[CRM_CUSTMAST.PAY_AUTH_EMAIL.AVAL]]
rem --- Validate email address
	email$=callpoint!.getUserInput()
	if !util.validEmailAddress(email$) then
		callpoint!.setStatus("ABORT")
		break
	endif

[[CRM_CUSTMAST.SHIPPING_EMAIL.AVAL]]
rem --- Validate email address
	email$=callpoint!.getUserInput()
	if !util.validEmailAddress(email$) then
		callpoint!.setStatus("ABORT")
		break
	endif



