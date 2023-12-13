[[OPT_INVKITDET.AGDS]]
rem  --- Report component shortages
		gosub reportShortages

[[OPT_INVKITDET.BGDR]]
rem --- Initialize UM_SOLD related <DISPLAY> fields
	conv_factor=num(callpoint!.getColumnData("OPT_INVKITDET.CONV_FACTOR"))
	if conv_factor=0 then conv_factor=1
	unit_cost=num(callpoint!.getColumnData("OPT_INVKITDET.UNIT_COST"))*conv_factor
	callpoint!.setColumnData("<<DISPLAY>>.UNIT_COST_DSP",str(unit_cost))
	qty_ordered=num(callpoint!.getColumnData("OPT_INVKITDET.QTY_ORDERED"))/conv_factor
	callpoint!.setColumnData("<<DISPLAY>>.QTY_ORDERED_DSP",str(qty_ordered))
	unit_price=num(callpoint!.getColumnData("OPT_INVKITDET.UNIT_PRICE"))*conv_factor
	callpoint!.setColumnData("<<DISPLAY>>.UNIT_PRICE_DSP",str(unit_price))
	qty_backord=num(callpoint!.getColumnData("OPT_INVKITDET.QTY_BACKORD"))/conv_factor
	callpoint!.setColumnData("<<DISPLAY>>.QTY_BACKORD_DSP",str(qty_backord))
	qty_shipped=num(callpoint!.getColumnData("OPT_INVKITDET.QTY_SHIPPED"))/conv_factor
	callpoint!.setColumnData("<<DISPLAY>>.QTY_SHIPPED_DSP",str(qty_shipped))
	std_list_prc=num(callpoint!.getColumnData("OPT_INVKITDET.STD_LIST_PRC"))*conv_factor
	callpoint!.setColumnData("OPT_INVKITDET.STD_LIST_PRC",str(std_list_prc))

[[OPT_INVKITDET.BSHO]]
rem --- Set column size for memo_1024 field very small so it doesn't take up room, but still available for hover-over of memo contents
	grid!=Form!.getControl(num(stbl("+GRID_CTL")))
	col_hdr$=callpoint!.getTableColumnAttribute("OPT_INVKITDET.MEMO_1024","LABS")
	memo_1024_col=util.getGridColumnNumber(grid!, col_hdr$)
	grid!.setColumnWidth(memo_1024_col,15)

[[OPT_INVKITDET.ITEM_ID.BINQ]]
rem --- Inventory Item/Whse Lookup
	call stbl("+DIR_SYP")+"bac_key_template.bbj","IVM_ITEMWHSE","PRIMARY",key_tpl$,rd_table_chans$[all],status$
	dim ivmItemWhse_key$:key_tpl$
	dim filter_defs$[2,2]
	filter_defs$[1,0]="IVM_ITEMWHSE.FIRM_ID"
	filter_defs$[1,1]="='"+firm_id$ +"'"
	filter_defs$[1,2]="LOCK"
	filter_defs$[2,0]="IVM_ITEMWHSE.WAREHOUSE_ID"
	filter_defs$[2,1]="='"+callpoint!.getColumnData("OPT_INVKITDET.WAREHOUSE_ID")+"'"
	filter_defs$[2,2]=""
	
	call stbl("+DIR_SYP")+"bax_query.bbj",gui_dev,form!,"IV_ITEM_WHSE_LK","",table_chans$[all],ivmItemWhse_key$,filter_defs$[all]

	rem --- Update item_id if changed
	if cvs(ivmItemWhse_key$,2)<>"" and ivmItemWhse_key.item_id$<>callpoint!.getColumnData("OPT_INVKITDET.ITEM_ID") then 
		callpoint!.setColumnData("OPT_INVKITDET.ITEM_ID",ivmItemWhse_key.item_id$,1)
		callpoint!.setStatus("MODIFIED")
		callpoint!.setFocus(num(callpoint!.getValidationRow()),"OPT_INVKITDET.ITEM_ID",1)
	endif

	callpoint!.setStatus("ACTIVATE-ABORT")

[[OPT_INVKITDET.<CUSTOM>]]
rem =========================================================
reportShortages: rem --- Warn if ship quantity is more than currently available.
rem =========================================================
	if callpoint!.getDevObject("warn_not_avail")="Y" then
		rem --- Get needed masks
		call stbl("+DIR_PGM")+"adc_getmask.aon","","IV","U","",qty_mask$,0,qty_mask
		call stbl("+DIR_PGM")+"adc_getmask.aon","","IV","I","",ivIMask$,0,0

		rem --- Report shortages
		shortage_vect!=callpoint!.getDevObject("shortageVect")
		if shortage_vect!.size()>0 then
			warning$=""
			kit_id$=cvs(callpoint!.getColumnData("OPT_INVKITDET.KIT_ID"),3)
			ship$=Translate!.getTranslation("AON_SHIP")+": "
			available$=Translate!.getTranslation("AON_AVAILABLE")+": "
			space=len(ship$)+15
			for i=0 to shortage_vect!.size()-1
				available_vect!=shortage_vect!.getItem(i)
				item_id$=cvs(fnmask$(available_vect!.getItem(0),ivIMask$),3)
				shipqty$=ship$+cvs(str(available_vect!.getItem(1):qty_mask$),3)
				availqty$=available$+cvs(str(available_vect!.getItem(2):qty_mask$),3)
				warning$=warning$+item_id$+"    "+shipqty$+pad("",space-len(shipqty$)," ")+availqty$+$0A$
			next i

			msg_id$="OP_KIT_EXCEEDS_AVAIL"
			dim msg_tokens$[2]
			msg_tokens$[1]=kit_id$
			msg_tokens$[2]=warning$
			gosub disp_message
			callpoint!.setStatus("ACTIVATE")
		endif
	endif
	shortage_vect!=BBjAPI().makeVector()

	return

rem ==========================================================================
rem 	Use util object
rem ==========================================================================

	use ::ado_util.src::util

rem ==========================================================================
rem --- fnmask$: Alphanumeric Masking Function (formerly fnf$)
rem ==========================================================================
    def fnmask$(q1$,q2$)
        if cvs(q1$,2)="" return ""
        if q2$="" q2$=fill(len(q1$),"0")
        if pos("E"=cvs(q1$,4)) goto alpha_mask
:      else return str(-num(q1$,err=alpha_mask):q2$,err=alpha_mask)
alpha_mask:
        q=1
        q0=0
        while len(q2$(q))
            if pos(q2$(q,1)="-()") q0=q0+1 else q2$(q,1)="X"
            q=q+1
        wend
        if len(q1$)>len(q2$)-q0 q1$=q1$(1,len(q2$)-q0)
        return str(q1$:q2$)
    fnend

rem ==========================================================================
rem --- Format inventory item description
rem ==========================================================================
    def fnitem$(q$,q1,q2,q3)
        q$=pad(q$,q1+q2+q3)
        return cvs(q$(1,q1)+" "+q$(q1+1,q2)+" "+q$(q1+q2+1,q3),32)
    fnend



