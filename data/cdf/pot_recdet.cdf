[[POT_RECDET.AGCL]]
rem --- Set column size for memo_1024 field very small so it doesn't take up room, but still available for hover-over of memo contents

	grid! = util.getGrid(Form!)
	col_hdr$=callpoint!.getTableColumnAttribute("POT_RECDET.MEMO_1024","LABS")
	memo_1024_col=util.getGridColumnNumber(grid!, col_hdr$)
	grid!.setColumnWidth(memo_1024_col,15)

[[POT_RECDET.AGDR]]
rem --- store extended amount for display in header

	ext_amt=round(num(callpoint!.getColumnData("POT_RECDET.UNIT_COST"))*num(callpoint!.getColumnData("POT_RECDET.QTY_RECEIVED")),2)
	callpoint!.setDevObject("header_tot",str(num(callpoint!.getDevObject("header_tot"))+ext_amt))

[[POT_RECDET.AGDS]]
rem --- update header tot

	tot_received=0
	tot_received=num(callpoint!.getDevObject("header_tot"),err=*next)
	totReceived!=callpoint!.getDevObject("totReceived")
	totReceived!.setText(str(tot_received))
	callpoint!.setHeaderColumnData("<<DISPLAY>>.ORDER_TOTAL",str(tot_received))

[[POT_RECDET.AGRN]]
rem --- Enable/disable Lot/Serial button
	item_id$   = callpoint!.getColumnData("POT_RECDET.ITEM_ID")
	qty_ord = num(callpoint!.getColumnData("POT_RECDET.QTY_ORDERED"))
	if cvs(item_id$,2)="" or qty_ord=0 then break

	rem --- Check for lotted/serialized item
	ivmItemMast_dev=fnget_dev("IVM_ITEMMAST")
	dim ivmItemMast$:fnget_tpl$("IVM_ITEMMAST")
	readrecord(ivmItemMast_dev, key=firm_id$+item_id$, dom=*endif) ivmItemMast$
	if pos(ivmItemMast.lotser_flag$="LS") and ivmItemMast.inventoried$="Y" then
		callpoint!.setOptionEnabled("LENT",1)
	else
		callpoint!.setOptionEnabled("LENT",0)
	endif

[[POT_RECDET.AOPT-LENT]]
rem --- Lot/Serial button is disabled except for inventoried lot/serial items
	call stbl("+DIR_SYP")+"bac_key_template.bbj","POT_RECLSDET","PRIMARY",key_tpl$,rd_table_chans$[all],status$
	dim potRecLsDet_key$:key_tpl$
	dim filter_defs$[3,2]
	filter_defs$[1,0]="POT_RECLSDET.FIRM_ID"
	filter_defs$[1,1]="='"+firm_id$ +"'"
	filter_defs$[1,2]="LOCK"
	filter_defs$[2,0]="POT_RECLSDET.RECEIVER_NO"
	filter_defs$[2,1]="='"+callpoint!.getColumnData("POT_RECDET.RECEIVER_NO")+"'"
	filter_defs$[2,2]="LOCK"
	filter_defs$[3,0]="POT_RECLSDET.PO_INT_SEQ_REF"
	filter_defs$[3,1]="='"+callpoint!.getColumnData("POT_RECDET.PO_INT_SEQ_REF")+"'"
	filter_defs$[3,2]="LOCK"

	call stbl("+DIR_SYP")+"bax_query.bbj",gui_dev,form!,"PO_HIST_REC_LS","",table_chans$[all],potRecLsDet_key$,filter_defs$[all]

[[POT_RECDET.BDGX]]
rem --- Disable detail-only buttons
	callpoint!.setOptionEnabled("LENT",0)

[[POT_RECDET.BGDS]]
rem --- initialize storage for header total

	callpoint!.setDevObject("header_tot","0")

[[POT_RECDET.ITEM_ID.AVAL]]
rem "Inventory Inactive Feature"
item_id$=callpoint!.getUserInput()
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
   callpoint!.setStatus("ACTIVATE")
endif

[[POT_RECDET.<CUSTOM>]]
rem ==========================================================================
#include [+ADDON_LIB]std_missing_params.aon
rem ==========================================================================

rem ==========================================================================
rem 	Use util object
rem ==========================================================================

	use ::ado_util.src::util



