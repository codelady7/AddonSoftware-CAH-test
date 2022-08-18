[[OPT_FILLMNTLSDET.AGDS]]
rem --- Can't use qty_picked from opt_fillmntdet. Must total it up here.
	qty_picked=0
	grid! = Form!.getControl(num(stbl("+GRID_CTL")))
	col_hdr$=callpoint!.getTableColumnAttribute("OPT_FILLMNTLSDET.QTY_PICKED","LABS")
	qtyPicked_column=util.getGridColumnNumber(grid!,col_hdr$)
	if grid!.getNumRows()>0 then
		for row=0 to grid!.getNumRows()-1
			qty_picked=qty_picked+num(grid!.getCellText(row,qtyPicked_column))
		next row
	endif
	left_to_pick=num(callpoint!.getDevObject("item_ship_qty"))-qty_picked
	callpoint!.setDevObject("left_to_pick",left_to_pick)

[[OPT_FILLMNTLSDET.AGRE]]
rem wgh ... 10304 ... stopped here
rem ...					gosub check_avail

[[OPT_FILLMNTLSDET.AREC]]
rem --- Initialize RTP trans_status and created fields
	rem --- TRANS_STATUS set to "E" via form Preset Value
	callpoint!.setColumnData("OPT_FILLMNTLSDET.CREATED_USER",sysinfo.user_id$)
	callpoint!.setColumnData("OPT_FILLMNTLSDET.CREATED_DATE",date(0:"%Yd%Mz%Dz"))
	callpoint!.setColumnData("OPT_FILLMNTLSDET.CREATED_TIME",date(0:"%Hz%mz"))

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
rem wgh ... 10304 ... need callpoint!.setStatus("ABORT") ????
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

[[OPT_FILLMNTLSDET.BWRI]]
rem --- Initialize RTP modified fields for modified existing records
	if callpoint!.getGridRowNewStatus(callpoint!.getValidationRow())<>"Y" then
		callpoint!.setColumnData("OPT_FILLMNTLSDET.MOD_USER", sysinfo.user_id$)
		callpoint!.setColumnData("OPT_FILLMNTLSDET.MOD_DATE", date(0:"%Yd%Mz%Dz"))
		callpoint!.setColumnData("OPT_FILLMNTLSDET.MOD_TIME", date(0:"%Hz%mz"))
	endif



