[[OPT_FILLMNTLSDET.AGDS]]
rem --- Can't use qty_shipped and qty_picked from opt_fillmntdet. Must total them up here.
	qty_shipped=0
	qty_picked=0
	grid! = Form!.getControl(num(stbl("+GRID_CTL")))
	col_hdr$=callpoint!.getTableColumnAttribute("OPT_FILLMNTLSDET.QTY_SHIPPED","LABS")
	qtyShipped_column=util.getGridColumnNumber(grid!,col_hdr$)
	col_hdr$=callpoint!.getTableColumnAttribute("OPT_FILLMNTLSDET.QTY_PICKED","LABS")
	qtyPicked_column=util.getGridColumnNumber(grid!,col_hdr$)
	if grid!.getNumRows()>1 then
		for row=0 to grid!.getNumRows()-2
			qty_shipped=qty_shipped+num(grid!.getCellText(row,qtyShipped_column))
			qty_picked=qty_picked+num(grid!.getCellText(row,qtyPicked_column))
		next row
	endif
	left_to_ship=num(callpoint!.getDevObject("item_ship_qty"))-qty_shipped
	callpoint!.setDevObject("left_to_ship",left_to_ship)
	left_to_pick=num(callpoint!.getDevObject("item_ship_qty"))-qty_picked
	callpoint!.setDevObject("left_to_pick",left_to_pick)

[[OPT_FILLMNTLSDET.AGRE]]
rem wgh ... 10304 ... stopped here
rem ...					gosub check_avail

[[OPT_FILLMNTLSDET.AGRN]]
rem --- Keep track of starting qty picked for this line, so we can accurately check avail qty minus what's already been committed
	callpoint!.setDevObject("prev_qtyPicked",num(callpoint!.getColumnData("OPT_FILLMNTLSDET.QTY_PICKED")))
	callpoint!.setDevObject("prior_lot",callpoint!.getColumnData("OPT_FILLMNTLSDET.LOTSER_NO"))

[[OPT_FILLMNTLSDET.AREC]]
rem --- Initialize RTP trans_status and created fields
	rem --- TRANS_STATUS set to "E" via form Preset Value
	callpoint!.setColumnData("OPT_FILLMNTLSDET.CREATED_USER",sysinfo.user_id$)
	callpoint!.setColumnData("OPT_FILLMNTLSDET.CREATED_DATE",date(0:"%Yd%Mz%Dz"))
	callpoint!.setColumnData("OPT_FILLMNTLSDET.CREATED_TIME",date(0:"%Hz%mz"))

[[OPT_FILLMNTLSDET.AUDE]]
rem wgh ... 10304 ... stopped here
rem ...		gosub commit_lots

[[OPT_FILLMNTLSDET.BDEL]]
rem wgh ... 10304 ... stopped here
rem ...		gosub commit_lots

[[OPT_FILLMNTLSDET.BEND]]
rem --- Get the total quantity picked
	declare BBjVector GridVect!
	qtyPicked=0
	aborted=0

	dim gridrec$:fattr(rec_data$)
	numrecs=GridVect!.size()
	if numrecs>0 then 
		for reccnt=0 to numrecs-1
			gridrec$=str(GridVect!.getItem(reccnt))
			if cvs(gridrec$,3)<>"" and callpoint!.getGridRowDeleteStatus(reccnt)<>"Y" then 
				rem --- Check available
				qty_shipped=gridrec.qty_shipped
				qty_picked=gridrec.qty_picked
				if callpoint!.getGridRowNewStatus(reccnt)="Y" or callpoint!.getGridRowModifyStatus(reccnt)="Y"  then
					lot_qty=qty_picked
rem wgh ... 10304 ... stopped here
rem ...					gosub check_avail
					if aborted then break
				endif

				rem --- Total lines
				qtyPicked=qtyPicked+gridrec.qty_picked
			endif
		next reccnt
		if aborted then break; rem --- exit callpoint
	endif

rem --- Warn if quantity picked does not match item's ship quantity
	item_ship_qty=num(callpoint!.getDevObject("item_ship_qty"))
	if qtyPicked<>item_ship_qty then
		msg_id$ = "OP_BAD_PICK_QTY"
		dim msg_tokens$[2]
		msg_tokens$[1] = str(qtyPicked)
		msg_tokens$[2] = str(item_ship_qty)
		gosub disp_message
		if msg_opt$="N"
			callpoint!.setStatus("ABORT")
			break
		endif
	endif

rem --- Send back total quantity picked
	callpoint!.setDevObject("total_picked",qtyPicked)

[[OPT_FILLMNTLSDET.BSHO]]
rem --- Use util object
	use ::ado_util.src::util

rem wgh ... 10304 ... stopped here
rem --- Set Lot/Serial button up properly

rem --- Set a flag for non-inventoried items
	ivmItemMast_dev=fnget_dev("IVM_ITEMMAST")
	dim ivmItemMast$:fnget_tpl$("IVM_ITEMMAST")
	item$=callpoint!.getDevObject("item")
	findrecord (ivmItemMast_dev,key=firm_id$+item$,dom=*next)ivmItemMast$
	if ivmItemMast$.inventoried$<>"Y" or callpoint!.getDevObject("dropship_line")="Y" then
		callpoint!.setDevObject("non_inventory",1)
	else
		callpoint!.setDevObject("non_inventory",0)
	endif

rem wgh ... 10304 ... stopped here

[[OPT_FILLMNTLSDET.BWRI]]
rem --- Initialize RTP modified fields for modified existing records
	if callpoint!.getGridRowNewStatus(callpoint!.getValidationRow())<>"Y" then
		callpoint!.setColumnData("OPT_FILLMNTLSDET.MOD_USER", sysinfo.user_id$)
		callpoint!.setColumnData("OPT_FILLMNTLSDET.MOD_DATE", date(0:"%Yd%Mz%Dz"))
		callpoint!.setColumnData("OPT_FILLMNTLSDET.MOD_TIME", date(0:"%Hz%mz"))
	endif

[[OPT_FILLMNTLSDET.LOTSER_NO.AVAL]]
rem --- Skip if lotser_no not changed
 	ls_no$=callpoint!.getUserInput()
	if ls_no$=callpoint!.getColumnData("OPT_FILLMNTLSDET.LOTSER_NO") then break

rem --- Get lot/serial record fields
	wh$=callpoint!.getDevObject("wh")
	item$=callpoint!.getDevObject("item")
	item_ship_qty=num( callpoint!.getDevObject("item_ship_qty") )

rem --- Non-inventoried items do not have to exist (but can't be blank)
	if callpoint!.getDevObject("non_inventory") then
		if cvs(ls_no$,2)="" then
			msg_id$ = "IV_SERLOT_BLANK"
			gosub disp_message
			callpoint!.setStatus("ABORT")
			break
		endif

		callpoint!.setColumnData("OPT_FILLMNTLSDET.UNIT_COST", str(callpoint!.getDevObject("unit_cost")))
	endif

rem --- Validate open lot number
	ivmLsMaster_dev = fnget_dev("IVM_LSMASTER")
	dim ivmLsMaster$:fnget_tpl$("IVM_LSMASTER")
	if !callpoint!.getDevObject("non_inventory") then
		read record (ivmLsMaster_dev, key=firm_id$+wh$+item$+ls_no$, dom=*next) ivmLsMaster$
		if cvs(ivmLsMaster.lotser_no$,2)="" then
			msg_id$ = "IV_LOT_MUST_EXIST"
			gosub disp_message
			callpoint!.setStatus("ABORT")
			break; rem --- exit callpoint
		endif

		if ivmLsMaster.closed_flag$ = "C" and item_ship_qty > 0 then
			msg_id$ = "IV_SERLOT_CLOSED"
			gosub disp_message
			callpoint!.setStatus("ABORT")
			break; rem --- exit callpoint
		endif

		if ivmLsMaster.qty_on_hand - ivmLsMaster.qty_commit <= 0 and item_ship_qty > 0 then
			msg_id$="IV_LOT_NO_AVAIL"
			gosub disp_message
			callpoint!.setStatus("ABORT")
			break; rem --- exit callpoint
		endif

		if callpoint!.getDevObject("lotser_flag")="S" and ivmLsMaster.qty_on_hand > 0 and item_ship_qty < 0 then
			msg_id$="OP_LOT_RTN_AVAIL";rem --- cannot return serialized item that is still on hand
			gosub disp_message
			callpoint!.setStatus("ABORT")
			break; rem --- exit callpoint
		endif
	endif

rem --- Set defaults
	if num(callpoint!.getColumnData("OPT_FILLMNTLSDET.QTY_SHIPPED")) = 0 then
		left_to_ship=callpoint!.getDevObject("left_to_ship")
		if callpoint!.getDevObject("lotser_flag")="S" then
			if item_ship_qty>0
				callpoint!.setColumnData("OPT_FILLMNTLSDET.QTY_SHIPPED","1",1)
				left_to_ship = left_to_ship - 1
			else
				callpoint!.setColumnData("OPT_FILLMNTLSDET.QTY_SHIPPED","-1",1)
				left_to_ship = left_to_ship + 1			
			endif
		else
			if callpoint!.getDevObject("non_inventory") then
				ship_qty = left_to_ship
			else
				ship_qty = min(ivmLsMaster.qty_on_hand, left_to_ship)
			endif
			callpoint!.setColumnData("OPT_FILLMNTLSDET.QTY_SHIPPED", str(ship_qty),1)
		endif
		callpoint!.setDevObject("left_to_ship",left_to_ship)
	endif

	if num(callpoint!.getColumnData("OPT_FILLMNTLSDET.QTY_PICKED")) = 0 then
		if callpoint!.getDevObject("lotser_flag")="S" then
			if item_ship_qty>0
				callpoint!.setColumnData("OPT_FILLMNTLSDET.QTY_PICKED","1",1)
			else
				callpoint!.setColumnData("OPT_FILLMNTLSDET.QTY_PICKED","-1",1)
			endif
		else
			callpoint!.setColumnData("OPT_FILLMNTLSDET.QTY_PICKED",callpoint!.getColumnData("OPT_FILLMNTLSDET.QTY_SHIPPED"),1)
		endif
	endif

	if num(callpoint!.getColumnData("OPT_FILLMNTLSDET.UNIT_COST")) = 0 then
		callpoint!.setColumnData("OPT_FILLMNTLSDET.UNIT_COST", ivmLsMaster.unit_cost$)
	endif

[[OPT_FILLMNTLSDET.QTY_PICKED.AVAL]]
rem --- Skip if qty_picked not changed
	qty_picked=num(callpoint!.getUserInput())
	prev_qtyPicked=num(callpoint!.getColumnData("OPT_FILLMNTLSDET.QTY_PICKED"))
	if qty_picked=prev_qtyPicked then break

rem --- Warn if quantity picked is more than ship quantity
	ship_qty=num(callpoint!.getColumnData("OPT_FILLMNTLSDET.QTY_SHIPPED"))
	if qty_picked>ship_qty then
		msg_id$="OP_PICK_EXCEEDS_SHIP"
		dim msg_tokens$[2]
		msg_tokens$[1]=str(qty_picked)
		msg_tokens$[2]=str(ship_qty)
		gosub disp_message
		if msg_opt$="C" then
			callpoint!.setUserInput(str(prev_qtyPicked))
			callpoint!.setStatus("ABORT-REFRESH")
			break; rem --- exit callpoint
		endif
	endif

[[OPT_FILLMNTLSDET.QTY_SHIPPED.AVAL]]
rem --- Skip if qty_ordered not changed
	ship_qty=num(callpoint!.getUserInput())
	prev_shipqty=num(callpoint!.getColumnData("OPT_FILLMNTLSDET.QTY_SHIPPED"))
	if ship_qty = prev_shipqty then break

rem ---- If serial (as opposed to lots), qty must be 1 or -1
	if callpoint!.getDevObject("lotser_flag")="S" and cvs(callpoint!.getColumnData("OPT_FILLMNTLSDET.LOTSER_NO"),2)<>"" and
:	abs(ship_qty) <> 1 then 
		msg_id$ = "IV_SERIAL_ONE"
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- Check quantity ordered against what's available on the Lot
	ivmLsMaster_dev = fnget_dev("IVM_LSMASTER")
	dim ivmLsMaster$:fnget_tpl$("IVM_LSMASTER")
	wh$=callpoint!.getDevObject("wh")
	item$=callpoint!.getDevObject("item")
 	ls_no$=callpoint!.getColumnData("OPT_FILLMNTLSDET.LOTSER_NO")

	read record (ivmLsMaster_dev, key=firm_id$+wh$+item$+ls_no$, dom=*next)ivmLsMaster$
	if cvs(ivmLsMaster.lotser_no$,2)<>"" then
		if ivmLsMaster.qty_on_hand - ivmLsMaster.qty_commit - ship_qty < 0
			dim msg_tokens$[1]
			msg_tokens$[0]=str(ivmLsMaster.qty_on_hand - ivmLsMaster.qty_commit)
			msg_id$="IV_QTY_OVER_AVAIL"
			gosub disp_message
			callpoint!.setStatus("ABORT")
			break; rem --- exit callpoint
		endif
	endif

rem --- Update qty left to ship
	left_to_ship=callpoint!.getDevObject("left_to_ship")
	left_to_ship = left_to_ship + callpoint!.getDevObject("prev_qtyPicked") - ship_qty 
	callpoint!.setDevObject("left_to_ship",left_to_ship)

rem --- Set picked default for new line
	if callpoint!.getGridRowNewStatus(callpoint!.getValidationRow())="Y" then
		callpoint!.setColumnData("OPT_FILLMNTLSDET.QTY_PICKED", str(ship_qty),1)
	endif



