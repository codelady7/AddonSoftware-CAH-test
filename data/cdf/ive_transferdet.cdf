[[IVE_TRANSFERDET.AGDR]]
rem wgh ... 10412 ...
	ivm01_dev=fnget_dev("IVM_ITEMMAST")
	dim ivm01a$:fnget_tpl$("IVM_ITEMMAST")
rem ...	findrecord (ivm01_dev, key=firm_id$+item_id$) ivm01a$
rem ...	callpoint!.setColumnData("<<DISPLAY>>.UNIT_OF_SALE",ivm01a.unit_of_sale$,1)

[[IVE_TRANSFERDET.AREC]]
rem --- Initializations for new row
	callpoint!.setDevObject("ls_avail",0)

[[IVE_TRANSFERDET.ITEM_ID.AVAL]]
rem --- Skip if item not changed
	item_id$=callpoint!.getUserInput()
	if item_id$=callpoint!.getColumnData("IVE_TRANSFERDET.ITEM_ID") then break

rem --- Verify not an inactive item
	ivm01_dev=fnget_dev("IVM_ITEMMAST")
	ivm01_tpl$=fnget_tpl$("IVM_ITEMMAST")
	dim ivm01a$:ivm01_tpl$
	ivm01a_key$=firm_id$+item_id$
	find record (ivm01_dev,key=ivm01a_key$,err=*break)ivm01a$
	if ivm01a.item_inactive$="Y" then
		msg_id$="IV_ITEM_INACTIVE"
		dim msg_tokens$[2]
		msg_tokens$[1]=cvs(ivm01a.item_id$,2)
		msg_tokens$[2]=cvs(ivm01a.display_desc$,2)
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif

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
	callpoint!.setColumnData("IVE_TRANSFERDET.INV_XFER_NO","",1)

rem --- Enable/Disable Lot/Serial Number
	if callpoint!.getDevObject("lotser_flag")="Y" and ivm01a.lotser_item$="Y" and ivm01a.inventoried$="Y" then
		callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"IVE_TRANSFERDET.LOTSER_NO",1)
	else
		callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"IVE_TRANSFERDET.LOTSER_NO",0)
	endif

[[IVE_TRANSFERDET.LOTSER_NO.AVAL]]
rem --- Skip if lot/serial not changed
	item_id$=callpoint!.getUserInput()
	if item_id$=callpoint!.getColumnData("IVE_TRANSFERDET.LOTSER_NO") then break

rem wgh ... 10412 ... stopped here
rem --- Validate entered lot/serial#

	whse$  = callpoint!.getColumnData("IVE_TRANSFER.WAREHOUSE_ID")
	item$  = callpoint!.getColumnData("IVE_TRANSFER.ITEM_ID")
	ls_no$ = callpoint!.getUserInput()

	gosub valid_ls

	if !(failed) then 
		callpoint!.setColumnData("IVE_TRANSFER.UNIT_COST", str(ls_rec.unit_cost))
		qty = num( callpoint!.getColumnData("IVE_TRANSFER.TRANS_QTY") )
rem ...		gosub display_ext
	endif

[[IVE_TRANSFERDET.<CUSTOM>]]
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
	endif

	return

rem ===========================================================================
get_item: rem --- Get item master record 
	rem      IN: item_id$
	rem     OUT: ivm01a$ (item mast record)
rem ===========================================================================

	ivm01_dev=fnget_dev("IVM_ITEMMAST")
	dim ivm01a$:fnget_tpl$("IVM_ITEMMAST")
	findrecord (ivm01_dev, key=firm_id$+item_id$) ivm01a$
	callpoint!.setColumnData("<<DISPLAY>>.UNIT_OF_SALE",ivm01a.unit_of_sale$,1)

	return

rem ===========================================================================
valid_ls: rem --- Validate entered lot/serial#
	rem      IN: whse$  = warehouse
	rem            item_id$  = inventory item
	rem            ls_no$ = lot/serial#
	rem     OUT: failed (true/false)
	rem             ivm07a$ (lot/serial mast record)
	rem             user_tpl.avail
rem ===========================================================================

	ivm07_dev=fnget_dev("IVM_LSMASTER")
	dim ivm07a$:fnget_tpl$("IVM_LSMASTER")
	failed=1
	readrecord(ivm07_dev, key=firm_id$ + whse$ + item_id$ + ls_no$, dom=*next) ivm07a$; failed=0
	if failed then
		callpoint!.setMessage("IV_LOT_MUST_EXIST")
	else
		ls_avail = ivm07a.qty_on_hand - ivm07a.qty_commit + ivm07a.prev_qty
	callpoint!.setDevObject("ls_avail",ls_avail)
		if ls_avail = 0 then
			callpoint!.setMessage("IV_LOT_NO_AVAIL")
		endif
	endif
rem wgh ... 10412 ... stopped here

	return



