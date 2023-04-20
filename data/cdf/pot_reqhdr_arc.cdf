[[POT_REQHDR_ARC.ADIS]]
rem --- Set DISPLAY fields
	vendor_id$=callpoint!.getColumnData("POT_REQHDR_ARC.VENDOR_ID")
	purch_addr$=callpoint!.getColumnData("POT_REQHDR_ARC.PURCH_ADDR")
	gosub vendor_info
	gosub disp_vendor_comments
	gosub purch_addr_info
	gosub whse_addr_info

rem --- Depending on whether or not drop-ship flag is selected and OP is installed...
rem --- If drop-ship is selected, load up sales order line#'s for the detail grid's SO reference listbutton
	callpoint!.setDevObject("so_lines_used","")
	if callpoint!.getColumnData("POT_REQHDR_ARC.DROPSHIP")="Y"
		if callpoint!.getDevObject("OP_installed")="Y"
			tmp_customer_id$=callpoint!.getColumnData("POT_REQHDR_ARC.CUSTOMER_ID")
			tmp_order_no$=callpoint!.getColumnData("POT_REQHDR_ARC.ORDER_NO")
			gosub get_dropship_order_lines
		endif
	endif

[[POT_REQHDR_ARC.AOPT-DPRT]]
rem --- Print archived Requisition
	vendor_id$=callpoint!.getColumnData("POT_REQHDR_ARC.VENDOR_ID")
	req_no$=callpoint!.getColumnData("POT_REQHDR_ARC.REQ_NO")
	if cvs(vendor_id$,3)<>"" and cvs(req_no$,3)<>""
		gosub queue_for_printing

		historical_print$="Y"
		call "por_reqprint.aon",vendor_id$,req_no$,historical_print$,table_chans$[all]
	endif

[[POT_REQHDR_ARC.APFE]]
rem --- Set PO  total amount
	total_amt=num(callpoint!.getDevObject("total_amt"))
	callpoint!.setColumnData("<<DISPLAY>>.ORDER_TOTAL",str(total_amt),1)

[[POT_REQHDR_ARC.AREC]]
rem --- Initialize new record
	callpoint!.setDevObject("so_line_type",new Properties())
	callpoint!.setDevObject("ds_orders","")
	callpoint!.setDevObject("so_ldat","")
	callpoint!.setDevObject("so_lines_list","")
	callpoint!.setDevObject("total_amt","0")

[[POT_REQHDR_ARC.BSHO]]
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
	open_tables$[7]="POE_REQPRINT",open_opts$[7]="OTA"

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

rem --- Hold on to detail grid object dtlGrid! for later use
	dtlWin!=Form!.getChildWindow(1109)
	dtlGrid!=dtlWin!.getControl(5900)
	callpoint!.setDevObject("dtl_grid",dtlGrid!)

[[POT_REQHDR_ARC.<CUSTOM>]]
#include [+ADDON_LIB]std_functions.aon

vendor_info: rem --- get and display Vendor Information
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

disp_vendor_comments:	
	rem --- You must pass in vendor_id$ because we don't know whether it's verified or not
	apm_vendmast_dev=fnget_dev("APM_VENDMAST")
	dim apm_vendmast$:fnget_tpl$("APM_VENDMAST")
	readrecord(apm_vendmast_dev,key=firm_id$+vendor_id$,dom=*next)apm_vendmast$		 
	callpoint!.setColumnData("<<DISPLAY>>.comments",apm_vendmast.memo_1024$,1)

	return

purch_addr_info: rem --- get and display Purchase Address Info
	apm05_dev=fnget_dev("APM_VENDADDR")
	dim apm05a$:fnget_tpl$("APM_VENDADDR")
	read record(apm05_dev,key=firm_id$+vendor_id$+purch_addr$,dom=*next)apm05a$
	callpoint!.setColumnData("<<DISPLAY>>.PA_ADDR1",apm05a.addr_line_1$,1)
	callpoint!.setColumnData("<<DISPLAY>>.PA_ADDR2",apm05a.addr_line_2$,1)
	callpoint!.setColumnData("<<DISPLAY>>.PA_CITY",apm05a.city$,1)
	callpoint!.setColumnData("<<DISPLAY>>.PA_STATE",apm05a.state_code$,1)
	callpoint!.setColumnData("<<DISPLAY>>.PA_ZIP_CODE",apm05a.zip_code$,1)
	callpoint!.setColumnData("<<DISPLAY>>.PA_CNTRY_ID",apm05a.cntry_id$,1)

	return

whse_addr_info: rem --- get and display Warehouse Address Info
	ivc_whsecode_dev=fnget_dev("IVC_WHSECODE")
	dim ivc_whsecode$:fnget_tpl$("IVC_WHSECODE")
	if pos("WAREHOUSE_ID.AVAL"=callpoint!.getCallpointEvent())<>0
		warehouse_id$=callpoint!.getUserInput()
	else
		warehouse_id$=callpoint!.getColumnData("POT_REQHDR_ARC.WAREHOUSE_ID")
	endif
	read record(ivc_whsecode_dev,key=firm_id$+"C"+warehouse_id$,dom=*next)ivc_whsecode$
	callpoint!.setColumnData("<<DISPLAY>>.W_ADDR1",ivc_whsecode.addr_line_1$,1)
	callpoint!.setColumnData("<<DISPLAY>>.W_ADDR2",ivc_whsecode.addr_line_2$,1)
	callpoint!.setColumnData("<<DISPLAY>>.W_CITY",ivc_whsecode.city$,1)
	callpoint!.setColumnData("<<DISPLAY>>.W_STATE",ivc_whsecode.state_code$,1)
	callpoint!.setColumnData("<<DISPLAY>>.W_ZIP_CODE",ivc_whsecode.zip_code$,1)

	return

get_dropship_order_lines: rem --- Read thru selected sales order and build list of lines for which line code is marked as drop-ship
	ope_ordhdr_dev=fnget_dev("OPE_ORDHDR")
	ope_orddet_dev=fnget_dev("OPE_ORDDET")
	ivm_itemmast_dev=fnget_dev("IVM_ITEMMAST")
	opc_linecode_dev=fnget_dev("OPC_LINECODE")

	dim ope_ordhdr$:fnget_tpl$("OPE_ORDHDR")
	dim ope_orddet$:fnget_tpl$("OPE_ORDDET")
	dim ivm_itemmast$:fnget_tpl$("IVM_ITEMMAST")
	dim opc_linecode$:fnget_tpl$("OPC_LINECODE")

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

	read (ope_orddet_dev,key=ope_ordhdr_key$,dom=*next)
	while 1
		ope_orddet_key$=key(ope_orddet_dev,end=*break)
		if pos(ope_ordhdr_key$=ope_orddet_key$)<>1 then break
		read record (ope_orddet_dev)ope_orddet$
		if ope_orddet.trans_status$<>"U" then continue
		if pos(ope_orddet.line_code$=callpoint!.getDevObject("oe_ds_line_codes"))<>0
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

	callpoint!.setDevObject("so_line_type",soLineType!)
	if order_lines!.size()=0 
		callpoint!.setDevObject("ds_orders","N")
		callpoint!.setDevObject("so_ldat","")
		callpoint!.setDevObject("so_lines_list","")
		callpoint!.setDevObject("so_line_type",new Properties())
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
	endif	

	return

queue_for_printing:
	poe_reqprint_dev=fnget_dev("POE_REQPRINT")
	dim poe_reqprint$:fnget_tpl$("POE_REQPRINT")

	poe_reqprint.firm_id$=firm_id$
	poe_reqprint.vendor_id$=callpoint!.getColumnData("POT_REQHDR_ARC.VENDOR_ID")
	poe_reqprint.req_no$=callpoint!.getColumnData("POT_REQHDR_ARC.REQ_NO")

	writerecord (poe_reqprint_dev)poe_reqprint$

	return



