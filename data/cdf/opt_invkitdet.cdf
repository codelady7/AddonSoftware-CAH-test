[[OPT_INVKITDET.AGRN]]
rem  --- Report component shortages
		gosub reportShortages

[[OPT_INVKITDET.BFMC]]
rem --- Get the kit's item descripton
	dim kitDetailLine$:fnget_tpl$("OPE_ORDDET")
	kitDetailLine$=callpoint!.getDevObject("kitDetailLine")
	ivmItemMast_dev=fnget_dev("IVM_ITEMMAST")
	dim ivmItemMast$:fnget_tpl$("IVM_ITEMMAST")
	findrecord(ivmItemMast_dev,key=firm_id$+kitDetailLine.item_id$)ivmItemMast$
	callpoint!.setDevObject("kitDesc",ivmItemMast.item_desc$)

	rem --- Displaying a kit' description requires the Inventory item description lengths.
	ivsParams_dev=fnget_dev("IVS_PARAMS")
	dim ivsParams$:fnget_tpl$("IVS_PARAMS")
	findrecord(ivsParams_dev,key=firm_id$+"IV00")ivsParams$
	itemDescLen! = BBjAPI().makeVector()
	itemDescLen!.addItem(num(ivsParams.desc_len_01$))
	itemDescLen!.addItem(num(ivsParams.desc_len_02$))
	itemDescLen!.addItem(num(ivsParams.desc_len_03$))
	callpoint!.setDevObject("itemDescLen",itemDescLen!)

rem --- Was this kit just added to the order?
	shortage_vect!=BBjAPI().makeVector()
	if callpoint!.getDevObject("kitRowNew")="Y" then
		rem --- Explode this kit into its components
		bmmBillMat_dev=fnget_dev("BMM_BILLMAT")
		dim bmmBillMat$:fnget_tpl$("BMM_BILLMAT")
		ivm01_dev=fnget_dev("IVM_ITEMMAST")
		dim ivm01a$:fnget_tpl$("IVM_ITEMMAST")
		ivm02_dev=fnget_dev("IVM_ITEMWHSE")
		dim ivm02a$:fnget_tpl$("IVM_ITEMWHSE")
		optInvKitDet_dev=fnget_dev("OPT_INVKITDET")
		dim optInvKitDet$:fnget_tpl$("OPT_INVKITDET")

		kit_item$=kitDetailLine.item_id$
		kit_ordered=kitDetailLine.qty_ordered
		kit_shipped=kitDetailLine.qty_shipped
		nextLineNo=1
		call stbl("+DIR_PGM")+"adc_getmask.aon","","IV","U","",qty_mask$,0,qty_mask
		call stbl("+DIR_PGM")+"adc_getmask.aon","","IV","I","",ivIMask$,0,0
		lineMask$=pad("",len(kitDetailLine.line_no$),"0")

		gosub explodeKit
	endif
	callpoint!.setDevObject("shortageVect",shortage_vect!)

rem --- Was the order for this kit changed?
	if callpoint!.getDevObject("kitRowModified")="Y" and callpoint!.getDevObject("kitRowNew")<>"Y" then
		shortage_vect!=BBjAPI().makeVector()
		round_precision = num(callpoint!.getDevObject("precision"))

		rem --- Update this kit's components for the changes made to the order
		kit_ordered=kitDetailLine.qty_ordered
		kit_shipped=kitDetailLine.qty_shipped
		kit_commit$=kitDetailLine.commit_flag$
		kit_prior_qty=callpoint!.getDevObject("prior_qty")

		optInvKitDet_dev=fnget_dev("OPT_INVKITDET")
		dim optInvKitDet$:fnget_tpl$("OPT_INVKITDET")
		kit_keyPrefix$=cvs(callpoint!.getKeyPrefix(),2)
		read(optInvKitDet_dev,key=kit_keyPrefix$,knum="AO_STAT_CUST_ORD",dom=*next)
		while 1
			thisKey$=key(optInvKitDet_dev,end=*break)
			if pos(kit_keyPrefix$=thisKey$)<>1 then break
			extractrecord(optInvKitDet_dev)optInvKitDet$
			comp_per_kit=optInvKitDet.comp_per_kit
			adjusted_kit_ordered=round(kit_ordered*comp_per_kit,round_precision)

			rem --- If the modified kit record is committed and the existing component record is committed, then …
			if kit_commit$="Y" and optInvKitDet.commit_flag$="Y" then
				rem --- If adjusted kit_ordered>optInvKitDet.qty_ordered then ...
				if adjusted_kit_ordered>optInvKitDet.qty_ordered then
					rem --- Commit adjusted kit_ordered-optInvKitDet.qty_ordered
					call stbl("+DIR_PGM")+"ivc_itemupdt.aon::init",channels[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status

					items$[1]=optInvKitDet.warehouse_id$
					items$[2]=optInvKitDet.item_id$
					refs[0]=adjusted_kit_ordered-optInvKitDet.qty_ordered
					call stbl("+DIR_PGM")+"ivc_itemupdt.aon","CO",channels[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
				endif

				rem --- If adjusted kit_ordered<optInvKitDet.qty_ordered then ...
				if adjusted_kit_ordered<optInvKitDet.qty_ordered then
					rem --- Uncommit optInvKitDet.qty_ordered-adjusted kit_ordered
					call stbl("+DIR_PGM")+"ivc_itemupdt.aon::init",channels[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status

					items$[1]=optInvKitDet.warehouse_id$
					items$[2]=optInvKitDet.item_id$
					refs[0]=optInvKitDet.qty_ordered-adjusted_kit_ordered
					call stbl("+DIR_PGM")+"ivc_itemupdt.aon","UC",channels[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
				endif
			endif

			rem --- If the modified kit record is committed and the existing component record is NOT committed, then ...
			if kit_commit$="Y" and optInvKitDet.commit_flag$<>"Y" then
				rem --- Commit the adjusted kit_ordered
				call stbl("+DIR_PGM")+"ivc_itemupdt.aon::init",channels[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status

				items$[1]=optInvKitDet.warehouse_id$
				items$[2]=optInvKitDet.item_id$
				refs[0]=adjusted_kit_ordered
				call stbl("+DIR_PGM")+"ivc_itemupdt.aon","CO",channels[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
			endif

			rem --- If the modified kit record is NOT committed and the existing component record is committed, then ...
			if kit_commit$<>"Y" and optInvKitDet.commit_flag$="Y" then
				rem --- Uncommit optInvKitDet.qty_ordered
				call stbl("+DIR_PGM")+"ivc_itemupdt.aon::init",channels[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status

				items$[1]=optInvKitDet.warehouse_id$
				items$[2]=optInvKitDet.item_id$
				refs[0]=optInvKitDet.qty_ordered
				call stbl("+DIR_PGM")+"ivc_itemupdt.aon","UC",channels[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
			endif

			rem --- If the modified kit record is NOT committed and the existing component record is NOT committed, then ... 
			if kit_commit$<>"Y" and optInvKitDet.commit_flag$<>"Y" then
				rem --- Do NOT commit/uncommit inventory
			endif

			rem --- Update this kit component record
			optInvKitDet.commit_flag$=kit_commit$
			optInvKitDet.qty_ordered=round(kit_ordered*comp_per_kit,round_precision)
			optInvKitDet.qty_shipped=round(kit_shipped*comp_per_kit,round_precision)
			optInvKitDet.qty_backord=optInvKitDet.qty_ordered-optInvKitDet.qty_shipped
			writerecord(optInvKitDet_dev)optInvKitDet$

			rem --- Warn if ship quantity is more than currently available.
			ivm02_dev=fnget_dev("IVM_ITEMWHSE")
			dim ivm02a$:fnget_tpl$("IVM_ITEMWHSE")
			readrecord(ivm02_dev,key=firm_id$+optInvKitDet.warehouse_id$+optInvKitDet.item_id$,dom=*next)ivm02a$
			shipqty=optInvKitDet.qty_shipped
			available=ivm02a.qty_on_hand-(ivm02a.qty_commit-shipqty); rem --- Note: ivm_itemwhse record read AFTER this component was committed
			if shipqty>available then
				available_vect!=BBjAPI().makeVector()
				available_vect!.addItem(optInvKitDet.item_id$)
				available_vect!.addItem(shipqty)
				available_vect!.addItem(available)
				shortage_vect!.addItem(available_vect!)
			endif
			callpoint!.setDevObject("shortageVect",shortage_vect!)
		wend
	endif

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

[[OPT_INVKITDET.<CUSTOM>]]
rem =========================================================
explodeKit: rem --- Explode kit
	rem    IN:	bmmBillMat_dev
	rem  	bmmBillMat$
	rem  	ivm01_dev
	rem  	ivm01a$
	rem   	ivm02_dev
	rem   	ivm02a$
	rem		optInvKitDet_dev
	rem		optInvKitDet$
	rem		kitDetailLine$
	rem		kit_item$
	rem		kit_ordered
	rem 		kit_shipped
	rem		nextLineNo
	rem 		qty_mask$
	rem 		ivIMask$
	rem 		lineMask$
	rem		shortage_vect!
	rem  OUT: shortage_vect!
rem =========================================================
	round_precision = num(callpoint!.getDevObject("precision"))

	rem --- Explode this kit
	read(bmmBillMat_dev,key=firm_id$+kit_item$,dom=*next)
	while 1
		kitKey$=key(bmmBillMat_dev,end=*break)
		if pos(firm_id$+kit_item$=kitKey$)<>1 then break
		readrecord(bmmBillMat_dev)bmmBillMat$
		redim ivm01a$
		readrecord(ivm01_dev,key=firm_id$+bmmBillMat.item_id$,dom=*next)ivm01a$
		if ivm01a.kit$="Y" then
			explodeKey$=kitKey$
			explodeItem$=kit_item$
			explodeOrdered=kit_ordered
			explodeShipped=kit_shipped
			kit_item$=bmmBillMat.item_id$
			kit_ordered=round(explodeOrdered*bmmBillMat.qty_required,round_precision)
			kit_shipped=round(explodeShipped*bmmBillMat.qty_required,round_precision)
			gosub explodeKit

			read(bmmBillMat_dev,key=explodeKey$)
			kit_item$=explodeItem$
			kit_ordered=explodeOrdered
			kit_shipped=explodeShipped
			continue
		endif

		redim optInvKitDet$
		optInvKitDet.firm_id$=kitDetailLine.firm_id$
		optInvKitDet.ar_type$=kitDetailLine.ar_type$
		optInvKitDet.customer_id$=kitDetailLine.customer_id$
		optInvKitDet.order_no$=kitDetailLine.order_no$
		optInvKitDet.ar_inv_no$=kitDetailLine.ar_inv_no$
		optInvKitDet.orddet_seq_ref$=kitDetailLine.internal_seq_no$
		call stbl("+DIR_SYP")+"bas_sequences.bbj", "INTERNAL_SEQ_NO",int_seq_no$,table_chans$[all]
		optInvKitDet.internal_seq_no$=int_seq_no$

		optInvKitDet.line_no$=str(nextLineNo:lineMask$)
		nextLineNo=nextLineNo+1
		optInvKitDet.trans_status$="E"
		optInvKitDet.line_code$=kitDetailLine.line_code$
		optInvKitDet.kit_id$=kitDetailLine.item_id$
		optInvKitDet.warehouse_id$=kitDetailLine.warehouse_id$
		optInvKitDet.item_id$=bmmBillMat.item_id$
		optInvKitDet.product_type$=ivm01a.product_type$
		optInvKitDet.um_sold$=ivm01a.unit_of_sale$
		optInvKitDet.est_shp_date$=kitDetailLine.est_shp_date$
		optInvKitDet.commit_flag$=kitDetailLine.commit_flag$
		optInvKitDet.pick_flag$=""
		optInvKitDet.man_price$=kitDetailLine.man_price$
		optInvKitDet.vendor_id$=""
		optInvKitDet.dropship$=""

		item$=cvs(fnmask$(optInvKitDet.kit_id$,ivIMask$),3)
		itemDescLen!=callpoint!.getDevObject("itemDescLen")
		itemDesc$=fnitem$(callpoint!.getDevObject("kitDesc"),itemDescLen!.getItem(0),itemDescLen!.getItem(1),itemDescLen!.getItem(2))
		optInvKitDet.memo_1024$=Translate!.getTranslation("AON_KIT","Kit")+": "+item$+" "+itemDesc$
		optInvKitDet.order_memo$=optInvKitDet.memo_1024$

		optInvKitDet.created_user$=kitDetailLine.created_user$
		optInvKitDet.created_date$=kitDetailLine.created_date$
		optInvKitDet.created_time$=kitDetailLine.created_time$
		optInvKitDet.mod_user$=kitDetailLine.mod_user$
		optInvKitDet.mod_date$=kitDetailLine.mod_date$
		optInvKitDet.mod_time$=kitDetailLine.mod_time$
		optInvKitDet.arc_user$=kitDetailLine.arc_user$
		optInvKitDet.arc_date$=kitDetailLine.arc_date$
		optInvKitDet.arc_time$=kitDetailLine.arc_time$
		optInvKitDet.batch_no$=kitDetailLine.batch_no$
		optInvKitDet.audit_number=kitDetailLine.audit_number
		if optInvKitDet.um_sold$=ivm01a.purchase_um$ then
			optInvKitDet.conv_factor=ivm01a.conv_factor
		else
			optInvKitDet.conv_factor=1
		endif
		optInvKitDet.comp_per_kit=bmmBillMat.qty_required*kit_ordered/kitDetailLine.qty_ordered

		redim ivm02a$
		readrecord(ivm02_dev,key=firm_id$+optInvKitDet.warehouse_id$+optInvKitDet.item_id$,dom=*next)ivm02a$
		optInvKitDet.unit_cost=ivm02a.unit_cost
		optInvKitDet.qty_ordered=round(kit_ordered*bmmBillMat.qty_required,round_precision)

		dim pc_files[6]
		pc_files[1] = fnget_dev("IVM_ITEMMAST")
		pc_files[2] = fnget_dev("IVM_ITEMWHSE")
		pc_files[3] = fnget_dev("IVM_ITEMPRIC")
		pc_files[4] = fnget_dev("IVC_PRICCODE")
		pc_files[5] = fnget_dev("ARS_PARAMS")
		pc_files[6] = fnget_dev("IVS_PARAMS")
		call stbl("+DIR_PGM")+"opc_pricing.aon",
:			pc_files[all],
:			firm_id$,
:			optInvKitDet.warehouse_id$,
:			optInvKitDet.item_id$,
:			callpoint!.getDevObject("priceCode"),
:			kitDetailLine.customer_id$,
:			callpoint!.getDevObject("orderDate"),
:			callpoint!.getDevObject("pricingCode"),
:			optInvKitDet.qty_ordered,
:			typeflag$,
:			price,
:			disc,
:			status
		if status=999 then
			typeflag$="N"
			price=0
			disc=0
		endif
		optInvKitDet.unit_price=price

		optInvKitDet.qty_shipped=round(kit_shipped*bmmBillMat.qty_required,round_precision)
		optInvKitDet.qty_backord=optInvKitDet.qty_ordered-optInvKitDet.qty_shipped
		optInvKitDet.std_list_prc=ivm02a.cur_price
		optInvKitDet.ext_price=round(optInvKitDet.qty_shipped * optInvKitDet.unit_price, 2)

		if (callpoint!.getDevObject("lineCodeTaxable")="Y" and ivm01a$.taxable_flag$="Y") or callpoint!.getDevObject("use_tax_service")="Y" then 
			optInvKitDet.taxable_amt=optInvKitDet.ext_price
		else
			optInvKitDet.taxable_amt=0
		endif
		optInvKitDet.disc_percent=disc
		optInvKitDet.comm_percent=0
		optInvKitDet.comm_amt=0
		optInvKitDet.spl_comm_pct=0

		writerecord(optInvKitDet_dev)optInvKitDet$

		rem --- Commit inventory for this component
		if optInvKitDet.commit_flag$="Y" then
			call stbl("+DIR_PGM")+"ivc_itemupdt.aon::init",channels[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status

			items$[1]=optInvKitDet.warehouse_id$
			items$[2]=optInvKitDet.item_id$
			refs[0]=optInvKitDet.qty_ordered
			call stbl("+DIR_PGM")+"ivc_itemupdt.aon","CO",channels[all],ivs01a$,items$[all],refs$[all],refs[all],table_chans$[all],status
		endif

		rem --- Warn if ship quantity is more than currently available.
		shipqty=optInvKitDet.qty_shipped
		available=ivm02a.qty_on_hand-ivm02a.qty_commit; rem --- Note: ivm_itemwhse record read BEFORE this component was committed
		if shipqty>available then
			available_vect!=BBjAPI().makeVector()
			available_vect!.addItem(optInvKitDet.item_id$)
			available_vect!.addItem(shipqty)
			available_vect!.addItem(available)
			shortage_vect!.addItem(available_vect!)
		endif
	wend

	return

rem =========================================================
reportShortages: rem --- Warn if ship quantity is more than currently available.
rem =========================================================
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



