[[OPT_CARTLSDET.AOPT-LLOK]]
rem wgh ... 10304 ... stopped here
rem ... OP_UNPACKED_LS

[[OPT_CARTLSDET.BEND]]
rem wgh ... 10304 ... update total qty_packed in the Packing Carton Lot/Serial Detail grid with the total qty_packed here

[[OPT_CARTLSDET.BSHO]]
rem --- Set a flag for non-inventoried items
	ivmItemMast_dev=fnget_dev("IVM_ITEMMAST")
	dim ivmItemMast$:fnget_tpl$("IVM_ITEMMAST")
	item_id$=callpoint!.getDevObject("item_id")
	findrecord (ivmItemMast_dev,key=firm_id$+item_id$,dom=*next)ivmItemMast$
	if ivmItemMast$.inventoried$<>"Y" or callpoint!.getDevObject("dropship_line")="Y" then
		callpoint!.setDevObject("non_inventory",1)
	else
		callpoint!.setDevObject("non_inventory",0)
	endif

rem --- Set Lot/Serial button up properly
	switch pos(callpoint!.getDevObject("lotser_flag")="LS")
		case 1; callpoint!.setOptionText("LLOK",Translate!.getTranslation("AON_LOT_LOOKUP")); break
		case 2; callpoint!.setOptionText("LLOK",Translate!.getTranslation("AON_SERIAL_LOOKUP")); break
		case default; callpoint!.setOptionEnabled("LLOK",0); break
	swend

rem --- No Serial/lot lookup for non-inventory items
	if callpoint!.getDevObject("non_inventory") then callpoint!.setOptionEnabled("LLOK", 0)

[[OPT_CARTLSDET.LOTSER_NO.AVAL]]
rem wgh ... 10304 ... validate entered lot/serial number and set default qty_packed

[[OPT_CARTLSDET.QTY_PACKED.AVAL]]
rem wgh ... 10304 ... validate entered qty_packed



