[[CRM_CONTACTS.EMAIL_ADDR.AVAL]]
rem --- Validate email address
	email$=callpoint!.getUserInput()
	if !util.validEmailAddress(email) then
		callpoint!.setStatus("ABORT")
		break
	endif



