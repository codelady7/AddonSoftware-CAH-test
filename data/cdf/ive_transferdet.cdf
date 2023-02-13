[[IVE_TRANSFERDET.ADGE]]
rem --- Disable Lot/Serial lookup
		callpoint!.setOptionEnabled("LOTS",0)

[[IVE_TRANSFERDET.AGDR]]
rem --- Enable/disable fields
	if cvs(callpoint!.getColumnData("IVE_TRANSFERDET.LOTSER_NO"),2)="" then
		callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"IVE_TRANSFERDET.LOTSER_NO",0)
	endif

rem --- Set/display item data
	item_id$=callpoint!.getColumnData("IVE_TRANSFERDET.ITEM_ID")
	gosub get_item
	if pos(callpoint!.getDevObject("lotser_flag")="LS") and callpoint!.getDevObject("lotser_item")="Y" and
:	callpoint!.getDevObject("inventoried")="Y" then
		callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"IVE_TRANSFERDET.TRANS_QTY",0)
	endif

[[IVE_TRANSFERDET.AGRN]]
rem --- Skip if not an existing row
	if callpoint!.getGridRowNewStatus(callpoint!.getValidationRow())="Y" then break

rem --- Initializations for this row
	callpoint!.setDevObject("qty_ok","")

rem --- Set 'previous' qty
	callpoint!.setDevObject("prev_qty",num( callpoint!.getColumnData("IVE_TRANSFERDET.TRANS_QTY")))

rem --- Get item data
	item_id$=callpoint!.getColumnData("IVE_TRANSFERDET.ITEM_ID")
	gosub get_item

rem --- Get from-whse data
	whse$ = callpoint!.getHeaderColumnData("IVE_TRANSFERHDR.WAREHOUSE_ID")
	gosub check_item_whse

rem --- Get lot/serial# if necessary
	ls_no$=callpoint!.getColumnData("IVE_TRANSFERDET.LOTSER_NO")
	if cvs(ls_no$,2)<>"" then gosub valid_ls

[[IVE_TRANSFERDET.AOPT-LOTS]]
rem --- Need AOPT-LOTS to get a button on the form.
rem --- Actual lookup done in LOTSER_NO AVAL when input is blank, which it is when lot/serial button is clicked.
rem --- Lookup is done here when there is an existing valid LOTSER_NO entered.
	if callpoint!.getDevObject("skip_ls_lookup") then break

rem --- Call the lot/serial lookup window
	item_id$ = callpoint!.getColumnData("IVE_TRANSFERDET.ITEM_ID")
	whse$ = callpoint!.getHeaderColumnData("IVE_TRANSFERHDR.WAREHOUSE_ID")
	if item_id$ <> "" and whse$ <> "" then 
		dim dflt_data$[3,1]
		dflt_data$[1,0] = "ITEM_ID"
		dflt_data$[1,1] = item_id$
		dflt_data$[2,0] = "WAREHOUSE_ID"
		dflt_data$[2,1] = whse$
		dflt_data$[3,0] = "LOTS_TO_DISP"
		dflt_data$[3,1] = "O"; rem --- Open lots only

		rem --- Call the lookup form
		call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:	                       "IVC_LOTLOOKUP",
:	                       stbl("+USER_ID"),
:	                       "",
:	                       "",
:	                       table_chans$[all],
:	                       "",
:	                       dflt_data$[all]

		rem --- Set the detail grid to the data selected in the lookup
		if callpoint!.getDevObject("selected_lot") <> null() then
			callpoint!.setColumnData("IVE_TRANSFERDET.LOTSER_NO",str(callpoint!.getDevObject("selected_lot")),1)
			callpoint!.setDevObject("qty_avail",num(callpoint!.getDevObject("selected_lot_avail")))
			callpoint!.setStatus("MODIFIED")
		endif
	else
		callpoint!.setMessage("IV_NO_ITEM_WHSE")
		callpoint!.setStatus("ABORT")
		break
	endif

[[IVE_TRANSFERDET.AREC]]
rem --- Initializations for new row
	callpoint!.setDevObject("qty_avail",0)
	callpoint!.setDevObject("prev_qty",0)
	callpoint!.setDevObject("qty_ok","")

	callpoint!.setColumnEnabled("IVE_TRANSFERDET.LOTSER_NO",0)

[[IVE_TRANSFERDET.AWRI]]
rem --- Commit inventory
	prev_qty = callpoint!.getDevObject("prev_qty")
	curr_qty = num( callpoint!.getColumnData("IVE_TRANSFERDET.TRANS_QTY") )
	if prev_qty <> curr_qty then 
		rem --- Initialize Inventory Item Update
		status = 999
		call stbl("+DIR_PGM") + "ivc_itemupdt.aon::init",
:			err=*next,
:			chan[all],
:			ivs01a$,
:			items$[all],
:			refs$[all],
:			refs[all],
:			table_chans$[all],
:			status
		if status then
			rem --- Error updating inventory
			message$=Translate!.getTranslation("AON_ERROR")
			message$=message$+" "+Translate!.getTranslation("AON_UPDATING")
			message$=message$+" "+Translate!.getTranslation("AON_INVENTORY")

			msg_id$="GENERIC_WARN"
			dim msg_tokens$[1]
			msg_tokens$[1]=message$
			gosub disp_message
			callpoint!.setStatus("ABORT")
			break
		endif

		rem --- From warehouse: uncommit previous qty, if any
		action$ = "UC"
		qty = prev_qty
		if qty then gosub item_update

		rem --- Commit current qty
		action$ = "CO"
		qty = curr_qty
		gosub item_update
	endif

[[IVE_TRANSFERDET.BDEL]]
rem --- Uncommit inventory
	qty = num( callpoint!.getColumnData("IVE_TRANSFERDET.TRANS_QTY") )
	if qty then 
		rem --- Initialize Inventory Item Update
		status = 999
		call stbl("+DIR_PGM") + "ivc_itemupdt.aon::init",
:			err=*next,
:			chan[all],
:			ivs01a$,
:			items$[all],
:			refs$[all],
:			refs[all],
:			table_chans$[all],
:			status
		if status then
			rem --- Error updating inventory
			message$=Translate!.getTranslation("AON_ERROR")
			message$=message$+" "+Translate!.getTranslation("AON_UPDATING")
			message$=message$+" "+Translate!.getTranslation("AON_INVENTORY")

			msg_id$="GENERIC_WARN"
			dim msg_tokens$[1]
			msg_tokens$[1]=message$
			gosub disp_message
			callpoint!.setStatus("ABORT")
			break
		endif

		rem --- Uncommit qty
		action$ = "UC"
		if qty then gosub item_update
	endif

[[IVE_TRANSFERDET.BDGX]]
rem --- Disable Lot/Serial lookup
		callpoint!.setOptionEnabled("LOTS",0)

[[IVE_TRANSFERDET.BUDE]]
rem --- Re-commit inventory
	qty = num( callpoint!.getColumnData("IVE_TRANSFERDET.TRANS_QTY") )
	if qty then 
		rem --- Initialize Inventory Item Update
		status = 999
		call stbl("+DIR_PGM") + "ivc_itemupdt.aon::init",
:			err=*next,
:			chan[all],
:			ivs01a$,
:			items$[all],
:			refs$[all],
:			refs[all],
:			table_chans$[all],
:			status
		if status then
			rem --- Error updating inventory
			message$=Translate!.getTranslation("AON_ERROR")
			message$=message$+" "+Translate!.getTranslation("AON_UPDATING")
			message$=message$+" "+Translate!.getTranslation("AON_INVENTORY")

			msg_id$="GENERIC_WARN"
			dim msg_tokens$[1]
			msg_tokens$[1]=message$
			gosub disp_message
			callpoint!.setStatus("ABORT")
			break
		endif

		rem --- Commit qty
		action$ = "CO"
		if qty then gosub item_update
	endif

[[IVE_TRANSFERDET.BWRI]]
rem --- Check item against both warehouses
	item_id$  = callpoint!.getColumnData("IVE_TRANSFERDET.ITEM_ID")
	whse$ = callpoint!.getHeaderColumnData("IVE_TRANSFERHDR.WAREHOUSE_ID_TO")
	gosub check_item_whse
	if failed then 
		callpoint!.setStatus("ABORT")
		break
	endif

	rem --- We check 'from whse' second so that ivm02a$ is set correctly
	whse$ = callpoint!.getHeaderColumnData("IVE_TRANSFERHDR.WAREHOUSE_ID")
	gosub check_item_whse
	if failed then 
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- Validate entered lot/serial#
	ls_no$=callpoint!.getColumnData("IVE_TRANSFERDET.LOTSER_NO")
	if cvs(ls_no$,2)<>"" then
		gosub valid_ls
		if failed or callpoint!.getDevObject("qty_avail")<1 then
			callpoint!.setStatus("ABORT")
			break
		endif
	endif

rem --- Check trans qty against available
	trans_qty = num(callpoint!.getColumnData("IVE_TRANSFERDET.TRANS_QTY"))
	gosub check_qty
	if failed then
		callpoint!.setStatus("ABORT")
		break
	endif

[[IVE_TRANSFERDET.ITEM_ID.AVAL]]
rem --- Skip if item not changed
	item_id$=callpoint!.getUserInput()
	if item_id$=callpoint!.getColumnData("IVE_TRANSFERDET.ITEM_ID") then break

rem --- Don't allow changing committed items
	if callpoint!.getGridRowNewStatus(callpoint!.getValidationRow())<>"Y" then
		msg_id$="IV_COMMIT_NOT_CHANGE"
		dim msg_tokens$[1]
		msg_tokens$[1]=Translate!.getTranslation("AON_ITEM_ID")
		gosub disp_message

		item_id$=callpoint!.getColumnData("IVE_TRANSFERDET.ITEM_ID")
		callpoint!.setColumnData("IVE_TRANSFERDET.ITEM_ID",item_id$,1)
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- Verify not an inactive item
	ivm01_dev=fnget_dev("IVM_ITEMMAST")
	ivm01_tpl$=fnget_tpl$("IVM_ITEMMAST")
	dim ivm01a$:ivm01_tpl$
	ivm01a_key$=firm_id$+item_id$
	find record (ivm01_dev,key=ivm01a_key$,err=*next)ivm01a$
	if ivm01a.item_inactive$="Y" then
		msg_id$="IV_ITEM_INACTIVE"
		dim msg_tokens$[2]
		msg_tokens$[1]=cvs(ivm01a.item_id$,2)
		msg_tokens$[2]=cvs(ivm01a.display_desc$,2)
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	else
		if cvs(ivm01a.item_id$,2)="" then
			callpoint!.setStatus("ABORT")
			break
		endif
	endif
	gosub get_item 

rem --- Check item against both warehouse
	whse$ = callpoint!.getHeaderColumnData("IVE_TRANSFERHDR.WAREHOUSE_ID_TO")
	gosub check_item_whse
	if failed then 
		callpoint!.setStatus("ABORT")
		break
	endif

	rem --- We check 'from whse' second so that ivm02a$ is set correctly
	whse$ = callpoint!.getHeaderColumnData("IVE_TRANSFERHDR.WAREHOUSE_ID")
	gosub check_item_whse
	if failed then 
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- Initialize row fields
	callpoint!.setColumnData("IVE_TRANSFERDET.LOTSER_NO","",1)
	callpoint!.setColumnData("<<DISPLAY>>.UNIT_OF_SALE",ivm01a.unit_of_sale$,1)
	callpoint!.setColumnData("IVE_TRANSFERDET.UNIT_COST", str(ivm02a.unit_cost),1)
	callpoint!.setColumnData("IVE_TRANSFERDET.TRANS_QTY",str(0),1)
	callpoint!.setColumnData("IVE_TRANSFERDET.EXT_COST",str(0),1)

rem --- Enable/Disable Lot/Serial Number and Transfer Qty
	callpoint!.setColumnData("IVE_TRANSFERDET.ITEM_ID",item_id$)
	if pos(callpoint!.getDevObject("lotser_flag")="LS") and callpoint!.getDevObject("lotser_item")="Y" then
		trans_qty=1
		callpoint!.setColumnData("IVE_TRANSFERDET.TRANS_QTY",str(trans_qty),1)
		callpoint!.setColumnData("IVE_TRANSFERDET.EXT_COST", str(ivm02a.unit_cost * trans_qty),1)

		if callpoint!.getDevObject("inventoried")="Y" then
			callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"IVE_TRANSFERDET.LOTSER_NO",1)
			callpoint!.setFocus(callpoint!.getValidationRow(),"IVE_TRANSFERDET.LOTSER_NO",1)
			callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"IVE_TRANSFERDET.TRANS_QTY",0)
		else
			callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"IVE_TRANSFERDET.LOTSER_NO",0)
			callpoint!.setFocus(callpoint!.getValidationRow(),"IVE_TRANSFERDET.TRANS_QTY",1)
		endif
	else
		callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"IVE_TRANSFERDET.LOTSER_NO",0)
		callpoint!.setFocus(callpoint!.getValidationRow(),"IVE_TRANSFERDET.TRANS_QTY",1)
	endif

[[IVE_TRANSFERDET.LOTSER_NO.AVAL]]
rem --- Disable Lot/Serial lookup
		callpoint!.setOptionEnabled("LOTS",0)

rem --- Call the lot/serial lookup if LOTSER_NO not entered
	ls_no$=callpoint!.getUserInput()
	if cvs(ls_no$,2)="" then
		callpoint!.setDevObject("skip_ls_lookup",1); rem --- Skip AOPT-LOTS
		item_id$ = callpoint!.getColumnData("IVE_TRANSFERDET.ITEM_ID")
		whse$ = callpoint!.getHeaderColumnData("IVE_TRANSFERHDR.WAREHOUSE_ID")
		if item_id$ <> "" and whse$ <> "" then 
			dim dflt_data$[3,1]
			dflt_data$[1,0] = "ITEM_ID"
			dflt_data$[1,1] = item_id$
			dflt_data$[2,0] = "WAREHOUSE_ID"
			dflt_data$[2,1] = whse$
			dflt_data$[3,0] = "LOTS_TO_DISP"
			dflt_data$[3,1] = "O"; rem --- Open lots only

			rem --- Call the lookup form
			call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:	                       "IVC_LOTLOOKUP",
:	                       stbl("+USER_ID"),
:	                       "",
:	                       "",
:	                       table_chans$[all],
:	                       "",
:	                       dflt_data$[all]

			rem --- Set user input to selected lot/serial
			if callpoint!.getDevObject("selected_lot") <> null() then
				callpoint!.setColumnData("IVE_TRANSFERDET.LOTSER_NO",str(callpoint!.getDevObject("selected_lot")),1)
			endif
		else
			callpoint!.setMessage("IV_NO_ITEM_WHSE")
		endif

		callpoint!.setStatus("ABORT")
		break
	endif

rem --- Skip if lot/serial not changed
	ls_no$=callpoint!.getUserInput()
	if ls_no$=callpoint!.getColumnData("IVE_TRANSFERDET.LOTSER_NO") then
		callpoint!.setFocus(callpoint!.getValidationRow(),"IVE_TRANSFERDET.TRANS_QTY",1)
		break
	endif

rem --- Don't allow changing committed lot/serial
	if callpoint!.getGridRowNewStatus(callpoint!.getValidationRow())<>"Y" then
		msg_id$="IV_COMMIT_NOT_CHANGE"
		dim msg_tokens$[1]
		msg_tokens$[1]=Translate!.getTranslation("AON_LOT/SERIAL_NUMBER")
		gosub disp_message

		ls_no$=callpoint!.getColumnData("IVE_TRANSFERDET.LOTSER_NO")
		callpoint!.setColumnData("IVE_TRANSFERDET.LOTSER_NO",ls_no$,1)
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- Validate entered lot/serial#
	whse$  = callpoint!.getColumnData("IVE_TRANSFERDET.WAREHOUSE_ID")
	item_id$  = callpoint!.getColumnData("IVE_TRANSFERDET.ITEM_ID")
	gosub valid_ls
	if failed or callpoint!.getDevObject("qty_avail")<1 then
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- Set UNIT_COST
	callpoint!.setColumnData("IVE_TRANSFERDET.UNIT_COST", str(ivm07a.unit_cost),1)
	if callpoint!.getDevObject("lotser_flag")="S" then
		rem --- Set TRANS_QTY and EXT_COST for serialized items
		trans_qty=1
		callpoint!.setColumnData("IVE_TRANSFERDET.TRANS_QTY",str(trans_qty),1)
		callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"IVE_TRANSFERDET.TRANS_QTY",0)

		callpoint!.setColumnData("IVE_TRANSFERDET.EXT_COST", str(ivm07a.unit_cost * trans_qty),1)
	endif
	callpoint!.setFocus(callpoint!.getValidationRow(),"IVE_TRANSFERDET.TRANS_QTY",1)

[[IVE_TRANSFERDET.LOTSER_NO.BINP]]
rem --- Enable Lot/Serial lookup
	callpoint!.setOptionEnabled("LOTS",1)
	callpoint!.setDevObject("skip_ls_lookup",0)

[[IVE_TRANSFERDET.TRANS_QTY.AVAL]]
rem --- Check trans qty against available
	trans_qty = num(callpoint!.getUserInput())
	gosub check_qty
	if failed then
		callpoint!.setStatus("ABORT")
		break
	endif

	rem --- Update EXT_COST
	unit_cost = num( callpoint!.getColumnData("IVE_TRANSFERDET.UNIT_COST") )
	callpoint!.setColumnData("IVE_TRANSFERDET.EXT_COST", str( unit_cost*trans_qty))

[[IVE_TRANSFERDET.<CUSTOM>]]
rem ===========================================================================
get_item: rem --- Get item master record 
	rem      IN: item_id$
	rem     OUT: ivm01a$ (item mast record)
rem ===========================================================================

	ivm01_dev=fnget_dev("IVM_ITEMMAST")
	dim ivm01a$:fnget_tpl$("IVM_ITEMMAST")
	findrecord (ivm01_dev, key=firm_id$+item_id$) ivm01a$
	callpoint!.setColumnData("<<DISPLAY>>.UNIT_OF_SALE",ivm01a.unit_of_sale$,1)

	callpoint!.setDevObject("lotser_item",ivm01a.lotser_item$)
	callpoint!.setDevObject("inventoried",ivm01a.inventoried$)

	return

rem ===========================================================================
check_item_whse: rem --- Check that a warehouse record exists for this item
 	rem      IN: whse$
	rem           item_id$
	rem     OUT: failed  (true/false)
	rem             ivm02a$ (item/whse record)
rem ===========================================================================

	ivm02_dev=fnget_dev("IVM_ITEMWHSE")
	dim ivm02a$:fnget_tpl$("IVM_ITEMWHSE")
	failed=1
	readrecord(ivm02_dev,key=firm_id$+whse$+item_id$,dom=*next) ivm02a$; failed=0
	if failed then
		callpoint!.setMessage("IV_ITEM_WHSE_INVALID:" + whse$ )
	else
		qty_avail = ivm02a.qty_on_hand - ivm02a.qty_commit + callpoint!.getDevObject("prev_qty")
		callpoint!.setDevObject("qty_avail",qty_avail)
	endif

	return

rem ===========================================================================
valid_ls: rem --- Validate entered lot/serial#
	rem      IN: whse$  = warehouse
	rem            item_id$  = inventory item
	rem            ls_no$ = lot/serial#
	rem     OUT: failed (true/false)
	rem             ivm07a$ (lot/serial mast record)
rem ===========================================================================

	ivm07_dev=fnget_dev("IVM_LSMASTER")
	dim ivm07a$:fnget_tpl$("IVM_LSMASTER")
	failed=1
	readrecord(ivm07_dev, key=firm_id$ + whse$ + item_id$ + ls_no$, dom=*next) ivm07a$; failed=0
	if failed then
		callpoint!.setMessage("IV_LOT_MUST_EXIST")
	else
		qty_avail = ivm07a.qty_on_hand - ivm07a.qty_commit + callpoint!.getDevObject("prev_qty")
		callpoint!.setDevObject("qty_avail",qty_avail)
		if qty_avail = 0 then
			callpoint!.setMessage("IV_LOT_NO_AVAIL")
			failed=1
		endif
	endif

	return

rem ===========================================================================
check_qty: rem --- Is qty valid?
           rem      IN: trans_qty
           rem     OUT: failed = true/false
rem ===========================================================================

	failed = 0

	rem --- Quantity can't be negative or zero
	if trans_qty <= 0 then
		callpoint!.setMessage("IV_QTY_GT_ZERO")
		failed = 1
	endif

	rem --- Quantity can only be 1 for serial#'s
	if !failed then
		if trans_qty<>1 and  callpoint!.getDevObject("lotser_flag")="S" and callpoint!.getDevObject("lotser_item")="Y" and
:		callpoint!.getDevObject("inventoried")="Y" then
			callpoint!.setMessage("IV_SER_JUST_ONE")
			failed = 1
		endif
	endif

	rem --- Qty can't be more than available
	if !failed then
		if trans_qty>callpoint!.getDevObject("qty_avail") and callpoint!.getDevObject("qty_ok")<>"Y" then
			msg_id$ = "IV_QTY_OVER_AVAIL"
			dim msg_tokens$[1]
			msg_tokens$[1]=str(callpoint!.getDevObject("qty_avail"))
			gosub disp_message
			if pos("PASSVALID"=msg_opt$)=0
				failed = 1
			else
				callpoint!.setDevObject("qty_ok","Y")
			endif
		endif
	endif

	return

rem ===========================================================================
item_update: rem --- Commit or uncommit inventory
             rem      IN: action$ = "CO" (commit), "UC" (uncommit)
             rem          qty = quantity to commit
rem ===========================================================================

	items$[1] = callpoint!.getHeaderColumnData("IVE_TRANSFERHDR.WAREHOUSE_ID")
	items$[2] = callpoint!.getColumnData("IVE_TRANSFERDET.ITEM_ID")
	items$[3] = callpoint!.getColumnData("IVE_TRANSFERDET.LOTSER_NO")
	refs[0]   = qty

	if items$[1] <> "" and items$[2] <> "" and refs[0] then
		call stbl("+DIR_PGM") + "ivc_itemupdt.aon",
:			action$,	
:			chan[all],
:			ivs01a$,
:			items$[all],
:			refs$[all],
:			refs[all],
:			table_chans$[all],
:			status
		if status then
			rem --- Error updating inventory
			message$=Translate!.getTranslation("AON_ERROR")
			message$=message$+" "+Translate!.getTranslation("AON_UPDATING")
			message$=message$+" "+Translate!.getTranslation("AON_INVENTORY")

			msg_id$="GENERIC_WARN"
			dim msg_tokens$[1]
			msg_tokens$[1]=message$
			gosub disp_message
			callpoint!.setStatus("ABORT")
			break
		endif
	endif

	items$[1] = ""
	items$[2] = ""
	items$[3] = ""
	refs[0] = 0

	return



