[[ARM_EMAILFAX.BSHO]]
rem  Initializations
	use ::ado_util.src::util

[[ARM_EMAILFAX.EMAIL_BCC.AVAL]]
rem --- Validate bcc email address
	email_bcc$=callpoint!.getUserInput()
	if !util.validEmailAddress(email_bcc$) then
		callpoint!.setStatus("ABORT")
		break
	endif

[[ARM_EMAILFAX.EMAIL_CC.AVAL]]
rem --- Validate cc email address
	email_cc$=callpoint!.getUserInput()
	if !util.validEmailAddress(email_cc$) then
		callpoint!.setStatus("ABORT")
		break
	endif

[[ARM_EMAILFAX.EMAIL_TO.AVAL]]
rem --- Validate TO email address
	email_to$=callpoint!.getUserInput()
	if !util.validEmailAddress(email_to$) then
		callpoint!.setStatus("ABORT")
		break
	endif

[[ARM_EMAILFAX.WEB_PAGE.AVAL]]
if cvs(callpoint!.getUserInput(),2)<>""
	if pos("."=callpoint!.getUserInput())=0
		callpoint!.setMessage("INVALID_WEBPAGE")
		callpoint!.setStatus("ABORT")
	endif
endif

[[ARM_EMAILFAX.<CUSTOM>]]



