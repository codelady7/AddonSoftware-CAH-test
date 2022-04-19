[[ARM_CUSTSHIP.ADIS]]
rem wgh ... 10389 ... need to be able to save the new record
wgh$=callpoint!.getDevObject("createNewShipToAddr")
escape; rem wgh ... 10389 ... testing

[[ARM_CUSTSHIP.ARER]]
rem --- Need to be able to save new records coming from Order/Invoice Entry
	if callpoint!.getDevObject("createNewShipToAddr")<>null() then callpoint!.setStatus("MODIFIED")



