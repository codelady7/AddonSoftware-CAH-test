[[ARC_CC_REGISTER.BSHO]]
rem  Initializations
	use ::ado_util.src::util

[[ARC_CC_REGISTER.USER_EMAIL.AVAL]]
rem --- Validate email address
	email$=callpoint!.getUserInput()
	if !util.validEmailAddress(email$) then
		callpoint!.setStatus("ABORT")
		break
	endif



