[[OPT_CARTDETHIST.AGDS]]
rem --- Enable Packed Lot/Serial button for lot/serial items
	gosub lot_ser_check
	if lotser_item$="Y" then
		callpoint!.setOptionEnabled("PKLS",1)
	else
		callpoint!.setOptionEnabled("PKLS",0)
	endif

[[OPT_CARTDETHIST.AOPT-PKLS]]
rem --- Launch Order Fulfillment's Historical Carton Lot/Serial Packing grid
	ar_type$=callpoint!.getColumnData("OPT_CARTDETHIST.AR_TYPE")
	customer_id$=callpoint!.getColumnData("OPT_CARTDETHIST.CUSTOMER_ID")
	order_no$=callpoint!.getColumnData("OPT_CARTDETHIST.ORDER_NO")
	ar_inv_no$=callpoint!.getColumnData("OPT_CARTDETHIST.AR_INV_NO")
	key_pfx$=firm_id$+ar_type$+customer_id$+order_no$+ar_inv_no$

	call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:	"OPT_CARTLSHIST",
:       stbl("+USER_ID"),
:       "QRY",
:       key_pfx$,
:       table_chans$[all]

[[OPT_CARTDETHIST.ASHO]]
rem --- Set Lot/Serial button up properly
	switch pos(callpoint!.getDevObject("lotser_flag")="LS")
		case 1; callpoint!.setOptionText("PKLS",Translate!.getTranslation("AON_PACKED","Packed")+" "+Translate!.getTranslation("AON_LOT","Lot")); break
		case 2; callpoint!.setOptionText("PKLS",Translate!.getTranslation("AON_PACKED","Packed")+" "+Translate!.getTranslation("AON_SERIAL","Serial")); break
		case default; callpoint!.setOptionEnabled("PKLS",0); break
	swend

[[OPT_CARTDETHIST.BSHO]]
rem --- Open files
	num_files = 1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]

	open_tables$[1]="IVM_ITEMMAST", open_opts$[1]="OTA"

	gosub open_tables

[[OPT_CARTDETHIST.<CUSTOM>]]
rem ==========================================================================
lot_ser_check: rem --- Check for lotted/serialized item
               rem      IN: --- none ---
               rem   OUT: lotser_item$
rem ==========================================================================
	lotser_item$="N"
	lotser_flag$=callpoint!.getDevObject("lotser_flag")
	if pos(lotser_flag$="LS")=0 then return

	packedItems$=""
	ivmItemMast_dev=fnget_dev("IVM_ITEMMAST")
	dim ivmItemMast$:fnget_tpl$("IVM_ITEMMAST")
	optCartDetHist_dev=fnget_dev("OPT_CARTDETHIST")
	dim optCartDetHist$:fnget_tpl$("OPT_CARTDETHIST")
	ar_type$=callpoint!.getColumnData("OPT_CARTDETHIST.AR_TYPE")
	customer_id$=callpoint!.getColumnData("OPT_CARTDETHIST.CUSTOMER_ID")
	order_no$=callpoint!.getColumnData("OPT_CARTDETHIST.ORDER_NO")
	ar_inv_no$=callpoint!.getColumnData("OPT_CARTDETHIST.AR_INV_NO")

	optCartDetHist_trip$=firm_id$+ar_type$+customer_id$+order_no$+ar_inv_no$
	read(optCartDetHist_dev,key=optCartDetHist_trip$,dom=*next)
	while 1
		optCartDetHist_key$=key(optCartDetHist_dev,end=*break)
		if pos(optCartDetHist_trip$=optCartDetHist_key$)<>1 then break
		readrecord(optCartDetHist_dev)optCartDetHist$
		item_id$=optCartDetHist.item_id$
		if cvs(item_id$,2)="" then continue
		if pos(item_id$+":"=packedItems$) then continue
		packedItems$=packedItems$+item_id$+":"

		readrecord(ivmItemMast_dev,key=firm_id$+item_id$,dom=*continue)ivmItemMast$
		if ivmItemMast.lotser_item$="Y" then
			lotser_item$="Y"
			break
		endif
	wend

	return



