[[POT_POHDR_ARC.ADIS]]
rem --- Set DISPLAY fields
	vendor_id$=callpoint!.getColumnData("POT_POHDR_ARC.VENDOR_ID")
	purch_addr$=callpoint!.getColumnData("POT_POHDR_ARC.PURCH_ADDR")
	gosub vendor_info
	gosub disp_vendor_comments
	gosub purch_addr_info
	gosub whse_addr_info

rem --- Depending on whether or not drop-ship flag is selected and OP is installed...
rem --- If drop-ship is selected, load up sales order line#'s for the detail grid's SO reference listbutton
	callpoint!.setDevObject("so_lines_used","")
	if callpoint!.getColumnData("POT_POHDR_ARC.DROPSHIP")="Y"
		if callpoint!.getDevObject("OP_installed")="Y"
			tmp_customer_id$=callpoint!.getColumnData("POT_POHDR_ARC.CUSTOMER_ID")
			tmp_order_no$=callpoint!.getColumnData("POT_POHDR_ARC.ORDER_NO")
			gosub get_dropship_order_lines
		endif
	endif

rem --- Show Purchase Order Print Report Controls
	admRptCtlRcp=fnget_dev("ADM_RPTCTL_RCP")
	dim admRptCtlRcp$:fnget_tpl$("ADM_RPTCTL_RCP")
	admRptCtlRcp.dd_table_alias$="POR_POPRINT"
	vendor_id$=callpoint!.getColumnData("POT_POHDR_ARC.VENDOR_ID")
	readrecord(admRptCtlRcp,key=firm_id$+vendor_id$+admRptCtlRcp.dd_table_alias$,knum="AO_VEND_ALIAS",dom=*next)admRptCtlRcp$
	if admRptCtlRcp.email_yn$<>"Y" and admRptCtlRcp.fax_yn$<>"Y" then
		callpoint!.setColumnData("<<DISPLAY>>.RPT_CTL",Translate!.getTranslation("AON_NONE"))
	else
		if admRptCtlRcp.email_yn$="Y" and admRptCtlRcp.fax_yn$="Y" then
			callpoint!.setColumnData("<<DISPLAY>>.RPT_CTL",Translate!.getTranslation("AON_EMAIL")+" + "+Translate!.getTranslation("AON_FAX"))
		else
			if admRptCtlRcp.email_yn$="Y" then
				callpoint!.setColumnData("<<DISPLAY>>.RPT_CTL",Translate!.getTranslation("AON_EMAIL")+" "+Translate!.getTranslation("AON_ONLY"))
			else
				callpoint!.setColumnData("<<DISPLAY>>.RPT_CTL",Translate!.getTranslation("AON_FAX")+" "+Translate!.getTranslation("AON_ONLY"))
			endif
		endif
	endif

[[POT_POHDR_ARC.AOPT-DPRT]]
rem ---Print archived PO
	vendor_id$=callpoint!.getColumnData("POT_POHDR_ARC.VENDOR_ID")
	po_no$=callpoint!.getColumnData("POT_POHDR_ARC.PO_NO")
	if cvs(vendor_id$,3)<>"" and cvs(po_no$,3)<>""
		gosub queue_for_printing

		callpoint!.setDevObject("historical_print","Y")
		dim dflt_data$[2,1]
		dflt_data$[1,0]="PO_NO"
		dflt_data$[1,1]=po_no$
		dflt_data$[2,0]="VENDOR_ID"
		dflt_data$[2,1]=vendor_id$
		call stbl("+DIR_SYP")+"bam_run_prog.bbj","POR_POPRINT_DMD",stbl("+USER_ID"),"","",table_chans$[all],"",dflt_data$[all]
	endif

[[POT_POHDR_ARC.APFE]]
rem --- Set PO  total amount
	total_amt=num(callpoint!.getDevObject("total_amt"))
	callpoint!.setColumnData("<<DISPLAY>>.ORDER_TOTAL",str(total_amt),1)

[[POT_POHDR_ARC.AREC]]
rem --- Initialize new record
	callpoint!.setDevObject("so_line_type",new Properties())
	callpoint!.setDevObject("ds_orders","")
	callpoint!.setDevObject("so_ldat","")
	callpoint!.setDevObject("so_lines_list","")
	callpoint!.setDevObject("total_amt","0")

[[POT_POHDR_ARC.BSHO]]
rem --- Initializations
	use java.util.Properties

rem --- Open Files
	num_files=7
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="IVM_ITEMMAST",open_opts$[1]="OTA"
	open_tables$[2]="POE_LINKED",open_opts$[2]="OTA"
	open_tables$[3]="APM_VENDMAST",open_opts$[3]="OTA"
	open_tables$[4]="APM_VENDADDR",open_opts$[4]="OTA"
	open_tables$[5]="ADM_RPTCTL_RCP",open_opts$[5]="OTA"
	open_tables$[6]="IVC_WHSECODE",open_opts$[6]="OTA"
	open_tables$[7]="POE_POPRINT",open_opts$[7]="OTA"

	gosub open_tables

rem --- Call adc_application to see if OP is installed; if so, open a couple tables for potential use if linking PO to SO for dropship
	dim info$[20]
	call stbl("+DIR_PGM")+"adc_application.aon","OP",info$[all]
	callpoint!.setDevObject("OP_installed",info$[20])
	if info$[20]="Y"
		num_files=4
		dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
		open_tables$[1]="OPE_ORDSHIP",open_opts$[1]="OTA"
		open_tables$[2]="OPE_ORDHDR",open_opts$[2]="OTA"
		open_tables$[3]="OPE_ORDDET",open_opts$[3]="OTA"
		open_tables$[4]="OPC_LINECODE",open_opts$[4]="OTA"

		gosub open_tables
	
		opc_linecode_dev=num(open_chans$[4])
		dim opc_linecode$:open_tpls$[4]
		let oe_dropship$=""
		read record (opc_linecode_dev,key=firm_id$,dom=*next)
		while 1
			read record (opc_linecode_dev,end=*break)opc_linecode$
			if opc_linecode.firm_id$<>firm_id$ then break
			if opc_linecode.dropship$="Y" then oe_dropship$=oe_dropship$+opc_linecode.line_code$
		wend
		callpoint!.setDevObject("oe_ds_line_codes",oe_dropship$)
	else
		rem --- Sale order number not allowed without OP
		callpoint!.setColumnEnabled("POT_POHDR_ARC.ORDER_NO",-1)
	endif

[[POT_POHDR_ARC.<CUSTOM>]]
#include [+ADDON_LIB]std_functions.aon

vendor_info: rem --- Get and display Vendor Information
	apm01_dev=fnget_dev("APM_VENDMAST")
	dim apm01a$:fnget_tpl$("APM_VENDMAST")
	read record(apm01_dev,key=firm_id$+vendor_id$,dom=*next)apm01a$
	callpoint!.setColumnData("<<DISPLAY>>.V_ADDR1",apm01a.addr_line_1$,1)
	callpoint!.setColumnData("<<DISPLAY>>.V_ADDR2",apm01a.addr_line_2$,1)
	if cvs(apm01a.city$+apm01a.state_code$+apm01a.zip_code$,3)<>""
		callpoint!.setColumnData("<<DISPLAY>>.V_CITY",cvs(apm01a.city$,3)+", "+apm01a.state_code$+"  "+apm01a.zip_code$,1)
	else
		callpoint!.setColumnData("<<DISPLAY>>.V_CITY","",1)
	endif
	callpoint!.setColumnData("<<DISPLAY>>.V_CNTRY_ID",apm01a.cntry_id$,1)
	callpoint!.setColumnData("<<DISPLAY>>.V_CONTACT",apm01a.contact_name$,1)
	callpoint!.setColumnData("<<DISPLAY>>.V_PHONE",apm01a.phone_no$,1)
	callpoint!.setColumnData("<<DISPLAY>>.V_FAX",apm01a.fax_no$,1)

	return

disp_vendor_comments:	rem --- Get and display Vendor Comments
	apm_vendmast_dev=fnget_dev("APM_VENDMAST")
	dim apm_vendmast$:fnget_tpl$("APM_VENDMAST")
	readrecord(apm_vendmast_dev,key=firm_id$+vendor_id$,dom=*next)apm_vendmast$		 
	callpoint!.setColumnData("<<DISPLAY>>.comments",apm_vendmast.memo_1024$,1)

	return

purch_addr_info: rem --- Get and display Purchase Address Info
	apm05_dev=fnget_dev("APM_VENDADDR")
	dim apm05a$:fnget_tpl$("APM_VENDADDR")
	read record(apm05_dev,key=firm_id$+vendor_id$+purch_addr$,dom=*next)apm05a$
	callpoint!.setColumnData("<<DISPLAY>>.PA_ADDR1",apm05a.addr_line_1$,1)
	callpoint!.setColumnData("<<DISPLAY>>.PA_ADDR2",apm05a.addr_line_2$,1)
	callpoint!.setColumnData("<<DISPLAY>>.PA_CITY",apm05a.city$,1)
	callpoint!.setColumnData("<<DISPLAY>>.PA_STATE",apm05a.state_code$,1)
	callpoint!.setColumnData("<<DISPLAY>>.PA_ZIP",apm05a.zip_code$,1)
	callpoint!.setColumnData("<<DISPLAY>>.PA_CNTRY_ID",apm05a.cntry_id$,1)

	return

whse_addr_info: rem --- Get and display Warehouse Address Info when not a dropship
	ivc_whsecode_dev=fnget_dev("IVC_WHSECODE")
	dim ivc_whsecode$:fnget_tpl$("IVC_WHSECODE")
	if callpoint!.getColumnData("POT_POHDR_ARC.DROPSHIP")<>"Y" then
		warehouse_id$=callpoint!.getColumnData("POT_POHDR_ARC.WAREHOUSE_ID")
		read record(ivc_whsecode_dev,key=firm_id$+"C"+warehouse_id$,dom=*next)ivc_whsecode$
	endif
	callpoint!.setColumnData("<<DISPLAY>>.W_ADDR1",ivc_whsecode$.addr_line_1$,1)
	callpoint!.setColumnData("<<DISPLAY>>.W_ADDR2",ivc_whsecode$.addr_line_2$,1)
	callpoint!.setColumnData("<<DISPLAY>>.W_CITY",ivc_whsecode$.city$,1)
	callpoint!.setColumnData("<<DISPLAY>>.W_STATE",ivc_whsecode$.state_code$,1)
	callpoint!.setColumnData("<<DISPLAY>>.W_ZIP",ivc_whsecode$.zip_code$,1)

	return

get_dropship_order_lines: rem --- Read thru selected sales order and build list of lines for which line code is marked as drop-ship
	ope_ordhdr_dev=fnget_dev("OPE_ORDHDR")
	ope_orddet_dev=fnget_dev("OPE_ORDDET")
	ivm_itemmast_dev=fnget_dev("IVM_ITEMMAST")
	opc_linecode_dev=fnget_dev("OPC_LINECODE")
	poe_linked_dev=fnget_dev("POE_LINKED")

	dim ope_ordhdr$:fnget_tpl$("OPE_ORDHDR")
	dim ope_orddet$:fnget_tpl$("OPE_ORDDET")
	dim ivm_itemmast$:fnget_tpl$("IVM_ITEMMAST")
	dim opc_linecode$:fnget_tpl$("OPC_LINECODE")
	dim poe_linked$:fnget_tpl$("POE_LINKED")

	order_lines!=SysGUI!.makeVector()
	order_items!=SysGUI!.makeVector()
	order_list!=SysGUI!.makeVector()
	callpoint!.setDevObject("ds_orders","N")
	soLineType!=callpoint!.getDevObject("so_line_type")

	found_ope_ordhdr=0
	read(ope_ordhdr_dev,key=firm_id$+ope_ordhdr.ar_type$+tmp_customer_id$+tmp_order_no$,knum="PRIMARY",dom=*next)
	while 1
		ope_ordhdr_key$=key(ope_ordhdr_dev,end=*break)
		if pos(firm_id$+ope_ordhdr.ar_type$+tmp_customer_id$+tmp_order_no$=ope_ordhdr_key$)<>1 then break
		read record (ope_ordhdr_dev)ope_ordhdr$
		if ope_ordhdr.trans_status$<>"U" then continue
		found_ope_ordhdr=1
		break; rem --- new order can have at most just one new invoice, if any
	wend
	if !found_ope_ordhdr then return

	so_on_another_po=0
	po_no$=callpoint!.getColumnData("POT_POHDR_ARC.PO_NO")
	read (ope_orddet_dev,key=ope_ordhdr_key$,dom=*next)
	while 1
		ope_orddet_key$=key(ope_orddet_dev,end=*break)
		if pos(ope_ordhdr_key$=ope_orddet_key$)<>1 then break
		read record (ope_orddet_dev)ope_orddet$
		if ope_orddet.trans_status$<>"U" then continue
		if pos(ope_orddet.line_code$=callpoint!.getDevObject("oe_ds_line_codes"))<>0
			rem --- Check poe_linked to see if this SO detail line is on another PO
			dim poe_linked$:fattr(poe_linked$)
			readrecord(poe_linked_dev,key=firm_id$+tmp_customer_id$+tmp_order_no$+ope_orddet.internal_seq_no$,knum="AO_CUST_ORD",dom=*next)poe_linked$
			if cvs(poe_linked.po_no$,2)<>"" and poe_linked.po_no$<>po_no$ then
				rem --- Skip this SO detail line since it's already on another PO
				so_on_another_po=1
				continue
			endif

			if cvs(ope_orddet.item_id$,2)="" then
				rem --- Non-stock item
				order_lines!.addItem(ope_orddet.internal_seq_no$)
				nonstk_list$=nonstk_list$+ope_orddet.order_memo$
				work_var=pos(ope_orddet.order_memo$=item_list$,len(ope_orddet.order_memo$),0)
				if work_var>1
					work_var$=cvs(ope_orddet.order_memo$,2)+"("+str(work_var)+")"
				else
					work_var$=cvs(ope_orddet.order_memo$,2)
				endif
				order_items!.addItem(work_var$)
				order_list!.addItem(Translate!.getTranslation("AON_NON-STOCK")+": "+work_var$)
			else
				rem --- Inventoried item
				read record (ivm_itemmast_dev,key=firm_id$+ope_orddet.item_id$,dom=*next)ivm_itemmast$
				order_lines!.addItem(ope_orddet.internal_seq_no$)
				item_list$=item_list$+ope_orddet.item_id$
				work_var=pos(ope_orddet.item_id$=item_list$,len(ope_orddet.item_id$),0)
				if work_var>1
					work_var$=cvs(ope_orddet.item_id$,2)+"("+str(work_var)+")"
				else
					work_var$=cvs(ope_orddet.item_id$,2)
				endif
				order_items!.addItem(work_var$)
				order_list!.addItem(Translate!.getTranslation("AON_ITEM:_")+work_var$+" "+cvs(ivm_itemmast.display_desc$,3))
			endif

			rem --- Get Line Type for this drop ship OP detail line
			dim opc_linecode$:fattr(opc_linecode$)
			read record (opc_linecode_dev,key=firm_id$+ope_orddet.line_code$,dom=*next)opc_linecode$
			soLineType!.setProperty(ope_orddet.internal_seq_no$,opc_linecode.line_type$)
		endif
	wend
	read(poe_linked_dev,key=firm_id$,knum="PRIMARY",dom=*next); rem --- Reset poe_linked key to PRIMARY

	callpoint!.setDevObject("so_line_type",soLineType!)
	if order_lines!.size()=0 
		callpoint!.setDevObject("ds_orders","N")
		callpoint!.setDevObject("so_ldat","")
		callpoint!.setDevObject("so_lines_list","")
		callpoint!.setDevObject("so_line_type",new Properties())

		if so_on_another_po then
			callpoint!.setDevObject("so_lines_used","ALL")
		endif
	else 
		ldat$=""
		descVect!=BBjAPI().makeVector()
		codeVect!=BBjAPI().makeVector()
		for x=0 to order_lines!.size()-1
			descVect!.addItem(order_items!.getItem(x))
			codeVect!.addItem(order_lines!.getItem(x))
		next x
		ldat$=func.buildListButtonList(descVect!,codeVect!)

		callpoint!.setDevObject("ds_orders","Y")		
		callpoint!.setDevObject("so_ldat",ldat$)
		callpoint!.setDevObject("so_lines_list",order_list!)

		if so_on_another_po then
			callpoint!.setDevObject("so_lines_used","SOME")
		endif
	endif	

	return

queue_for_printing:
	poe_poprint_dev=fnget_dev("POE_POPRINT")
	dim poe_poprint$:fnget_tpl$("POE_POPRINT")
	poe_poprint.firm_id$=firm_id$
	poe_poprint.vendor_id$=callpoint!.getColumnData("POT_POHDR_ARC.VENDOR_ID")
	poe_poprint.po_no$=callpoint!.getColumnData("POT_POHDR_ARC.PO_NO")
	writerecord (poe_poprint_dev)poe_poprint$

	return



