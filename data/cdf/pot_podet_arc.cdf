[[POT_PODET_ARC.ADGE]]
rem --- If there are order lines to display/access in the sales order line item listbutton, set the LDAT and list display.
rem --- Get the detail grid, then get the listbutton within the grid; set the list on the listbutton, and put the listbutton back in the grid.

	order_list!=callpoint!.getDevObject("so_lines_list")
	ldat$=callpoint!.getDevObject("so_ldat")

	if ldat$<>""
		callpoint!.setTableColumnAttribute("POE_PODET.SO_INT_SEQ_REF","LDAT",ldat$)
		g!=callpoint!.getDevObject("dtl_grid")
		col_hdr$=callpoint!.getTableColumnAttribute("POE_PODET.SO_INT_SEQ_REF","LABS")
		col_ref=util.getGridColumnNumber(g!, col_hdr$)
		c!=g!.getColumnListControl(col_ref)
		c!.removeAllItems()
		c!.insertItems(0,order_list!)
		g!.setColumnListControl(col_ref,c!)
	endif 

[[POT_PODET_ARC.AGDR]]
rem --- Sum PO total amount
	total_amt=num(callpoint!.getDevObject("total_amt"))
	total_amt=total_amt+round(num(callpoint!.getColumnData("POT_PODET_ARC.QTY_ORDERED"))*num(callpoint!.getColumnData("POT_PODET_ARC.UNIT_COST")),2)
	callpoint!.setDevObject("total_amt",str(total_amt))



