[[ARM_CUSTSHIP.ARER]]
rem --- Need to be able to save new records coming from Order/Invoice Entry
	if callpoint!.getDevObject("createNewShipToAddr")<>null() then callpoint!.setStatus("MODIFIED")



