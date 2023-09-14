rem ----------------------------------------------------------------------------
rem --- OP Pack List Header Printing
rem --- Program: OPPACKLIST_HDR.prc 

rem --- Copyright BASIS International Ltd.
rem --- All Rights Reserved

rem --- This SPROC is called from the OPPackListHdr Jasper report

rem ----------------------------------------------------------------------------

    seterr sproc_error
    
rem --- Use statements and Declares
    use ::ado_func.src::func
    use ::sys/prog/bao_option.bbj::Option
    
    declare Option option!
    declare BBjVector custIds!
    declare BBjVector orderNos!
    declare BBjStoredProcedureData sp!
    declare BBjRecordSet rs!
    declare BBjRecordData data!

rem --- Get the infomation object for the Stored Procedure
    sp! = BBjAPI().getFileSystem().getStoredProcedureData()

rem --- get SPROC parameters
    firm_id$ =     sp!.getParameter("FIRM_ID")
    ar_type$ =     sp!.getParameter("AR_TYPE")
    customer_id$ = sp!.getParameter("CUSTOMER_ID")
    order_no$ =    sp!.getParameter("ORDER_NO")
    ar_inv_no$ =   sp!.getParameter("AR_INV_NO")
    cust_mask$ =   sp!.getParameter("CUST_MASK")
    cust_size = num(sp!.getParameter("CUST_SIZE"))
    barista_wd$ =  sp!.getParameter("BARISTA_WD")
    
    chdir barista_wd$

rem --- create the in memory recordset for return
    dataTemplate$ = ""
    dataTemplate$ = dataTemplate$ + "order_no:C(9),order_date:C(10),"
    datatemplate$ = datatemplate$ + "bill_addr_line1:C(30),bill_addr_line2:C(30),bill_addr_line3:C(30),"
    datatemplate$ = datatemplate$ + "bill_addr_line4:C(30),bill_addr_line5:C(30),bill_addr_line6:C(30),"
    datatemplate$ = datatemplate$ + "bill_addr_line7:C(30),"
    datatemplate$ = datatemplate$ + "ship_addr_line1:C(30),ship_addr_line2:C(30),ship_addr_line3:C(30),"
    datatemplate$ = datatemplate$ + "ship_addr_line4:C(30),ship_addr_line5:C(30),ship_addr_line6:C(30),"
    datatemplate$ = datatemplate$ + "ship_addr_line7:C(30),"
    dataTemplate$ = dataTemplate$ + "salesrep_code:C(3),salesrep_desc:C(20),cust_po_num:C(20),ship_via:C(10),shipping_id:C(15),"
    dataTemplate$ = dataTemplate$ + "fob:C(15),ship_date:C(10),terms_code:C(3),terms_desc:C(20),"
    datatemplate$ = datatemplate$ + "inv_std_message:C(1024*=1)"
    
    rs! = BBJAPI().createMemoryRecordSet(dataTemplate$)

rem --- Retrieve the program path
    pgmdir$=""
    pgmdir$=stbl("+DIR_PGM",err=*next)
    sypdir$=""
    sypdir$=stbl("+DIR_SYP",err=*next)

rem --- Open Files    
rem --- Note 'files' and 'channels[]' are used in close loop, so don't re-use
    files=10,begfile=1,endfile=files
    dim files$[files],options$[files],ids$[files],templates$[files],channels[files]    

    files$[1]="arc_salecode",   ids$[1]="ARC_SALECODE"
    files$[2]="arc_termcode",   ids$[2]="ARC_TERMCODE"
    files$[3]="arm-01",         ids$[3]="ARM_CUSTMAST"
    files$[4]="ars_params",     ids$[4]="ARS_PARAMS"
    files$[5]="opc_message",    ids$[5]="OPC_MESSAGE"
    files$[6]="opt-31",         ids$[6]="OPE_ORDSHIP"
    files$[7]="opm-09",         ids$[7]="OPM_CUSTJOBS"
    files$[8]="opt_fillmnthdr", ids$[8]="OPT_FILLMNTHDR"
    files$[9]="opt-01",         ids$[9]="OPT_INVHDR"
    files$[10]="arm-03",        ids$[10]="ARM_CUSTSHIP"

	call pgmdir$+"adc_fileopen.aon",action,begfile,endfile,files$[all],options$[all],ids$[all],templates$[all],channels[all],batch,status

    if status then
        seterr 0
        x$=stbl("+THROWN_ERR","TRUE")   
        throw "File open error.",1001
    endif
    
	files_opened = files; rem used in loop to close files

    arm10f_dev = channels[1]
    arm10a_dev = channels[2]
    arm01_dev = channels[3]
    arsParams_dev = channels[4]
    opcMessage_dev = channels[5]
    ope31_dev = channels[6]
    opm09_dev = channels[7]
    optFillmntHdr_dev = channels[8]
    opeInvHdr_dev = channels[9]
    arm03_dev = channels[10]

    dim arm10f$:templates$[1]
    dim arm10a$:templates$[2]
    dim arm01a$:templates$[3]
    dim arsParams$:templates$[4]
    dim opcMessage$:templates$[5]
    dim ope31a$:templates$[6]
    dim opm09a$:templates$[7]
    dim optFillmntHdr$:templates$[8]
    dim opeInvHdr$:templates$[9]
    dim arm03a$:templates$[10]
	
rem --- Initialize Data
    dim table_chans$[512,6]

	max_stdMsg_lines = 10
	stdMsg_len = 40
	rem dim stdMessage$(max_stdMsg_lines * stdMsg_len)
	
	max_billAddr_lines = 6
	bill_addrLine_len = 30
	dim b$(max_billAddr_lines * bill_addrLine_len)
	
	max_custAddr_lines = 6
	cust_addrLine_len = 30	
	dim c$(max_custAddr_lines * bill_custLine_len)
	
	order_date$ =   ""
	slspsn_code$ =  ""
	slspsn_desc$ =  ""
	cust_po_no$ =   ""
	ship_via$ =     ""
    shipping_id$ =  ""
	fob$ =          ""
	ship_date$ =    ""
	terms_code$ =   ""
	terms_desc$ =   ""
	discount_amt$ = ""
    tax_amt$ =      ""
    freight_amt$ =  ""
	
	paid_desc$ =    ""
	paid_text1$ =   ""
	paid_text2$ =   ""
	
rem --- Main Read
    findrecord(opeInvHdr_dev,key=firm_id$+"E"+ar_type$+customer_id$+order_no$+ar_inv_no$,knum="AO_STATUS",dom=all_done)opeInvHdr$
	ar_inv_no$ =    opeInvHdr.ar_inv_no$
	order_date$ =   func.formatDate(opeInvHdr.order_date$)
	cust_po_no$ =   opeInvHdr.customer_po_no$
	fob$ =          opeInvHdr.fob$

    findrecord(optFillmntHdr_dev,key=firm_id$+"E"+ar_type$+customer_id$+order_no$+ar_inv_no$,knum="AO_STATUS",dom=all_done)optFillmntHdr$
    ship_via$ =     optFillmntHdr.ar_ship_via$
    shipping_id$ =  optFillmntHdr.shipping_id$
    ship_date$ =    func.formatDate(optFillmntHdr.shipmnt_date$)

rem --- Heading (bill-to address)
    declare BBjTemplatedString arm01!
    declare BBjTemplatedString arm03!
    declare BBjTemplatedString ope31!
    
    arm01! = BBjAPI().makeTemplatedString(fattr(arm01a$))
    arm03! = BBjAPI().makeTemplatedString(fattr(arm03a$))
    ope31! = BBjAPI().makeTemplatedString(fattr(ope31a$))

    found = 0
    start_block = 1

    if start_block then
        read record (arm01_dev, key=firm_id$+opeInvHdr.customer_id$, dom=*endif) arm01!
        needAddress=1
        read record (ope31_dev, key=firm_id$+opeInvHdr.customer_id$+opeInvHdr.order_no$+opeInvHdr.ar_inv_no$+"B", dom=*next) ope31!; needAddress=0
        if !needAddress then
            b$ = func.formatAddress(table_chans$[all], ope31!, bill_addrLine_len, max_billAddr_lines-1)
            b$ = pad(arm01!.getFieldAsString("CUSTOMER_NAME"), bill_addrLine_len) + b$
        else
            b$ = func.formatAddress(table_chans$[all], arm01!, bill_addrLine_len, max_billAddr_lines-1)
        endif

        if cvs(b$((max_billAddr_lines-1)*bill_addrLine_len),2)="" then
                b$ = pad(func.alphaMask(arm01!.getFieldAsString("CUSTOMER_ID"), cust_mask$), bill_addrLine_len) + b$
        endif
        found = 1
    endif

    if !found then
        b$ = pad("Customer not found", bill_addrLine_len*max_billAddr_lines)
    endif
        
rem --- Ship-To
    
    c$ = b$
    start_block = 1

    if opeInvHdr.shipto_type$ <> "B" then 
        needAddress=1
        read record (ope31_dev, key=firm_id$+opeInvHdr.customer_id$+opeInvHdr.order_no$+opeInvHdr.ar_inv_no$+"S", dom=*next) ope31!; needAddress=0
        if !needAddress or opeInvHdr.shipto_type$="M" then
            c$ = func.formatAddress(table_chans$[all], ope31!, bill_addrLine_len, max_billAddr_lines-1)
        else
            rem --- Need non-manual ship-to address
            find record (arm03_dev,key=firm_id$+opeInvHdr.customer_id$+opeInvHdr.shipto_no$, dom=*next) arm03!
            c$ = func.formatAddress(table_chans$[all], arm03!, cust_addrLine_len, max_custAddr_lines)
        endif

        if cvs(c$((max_billAddr_lines-1)*bill_addrLine_len),2)="" then
                c$ = pad(func.alphaMask(arm01!.getFieldAsString("CUSTOMER_ID"), cust_mask$), bill_addrLine_len) + c$
        endif
    endif

rem --- Terms
    dim arm10a$:fattr(arm10a$)
    arm10a.code_desc$ = "Not Found"
    find record (arm10a_dev,key=firm_id$+"A"+opeInvHdr.terms_code$,dom=*next) arm10a$

    terms_code$ = opeInvHdr.terms_code$
    terms_desc$ = arm10a.code_desc$
    
rem --- Salesperson
    arm10f.code_desc$ = "Not Found"
    find record (arm10f_dev,key=firm_id$+"F"+opeInvHdr.slspsn_code$,dom=*next) arm10f$

    slspsn_code$ = opeInvHdr.slspsn_code$
    slspsn_desc$ = arm10f.code_desc$

rem --- Job Name
    dim opm09a$:fattr(opm09a$)
    opm09a.customer_name$ = "Not Found"

    if opm09_dev then 
        find record (opm09_dev, key=firm_id$+opeInvHdr.customer_id$+opeInvHdr.job_no$, dom=*next) opm09a$
    else
        opm09a.customer_name$ = opeInvHdr.job_no$
    endif

rem --- Standard Message
    gosub get_stdMessage
        
all_done:    rem --- End of pick list -- Send data out

rem --- Format addresses to be bottom justified
	address$=b$
	line_len=bill_addrLine_len
	gosub format_address
	b$=address$
	
	address$=c$
	line_len=cust_addrLine_len
	gosub format_address
	c$=address$

    data! = rs!.getEmptyRecordData()
    data!.setFieldValue("ORDER_NO", order_no$+" "+opeInvHdr.backord_flag$)
    data!.setFieldValue("ORDER_DATE", order_date$)

    data!.setFieldValue("BILL_ADDR_LINE1", b$((bill_addrLine_len*0)+1,bill_addrLine_len))
    data!.setFieldValue("BILL_ADDR_LINE2", b$((bill_addrLine_len*1)+1,bill_addrLine_len))
    data!.setFieldValue("BILL_ADDR_LINE3", b$((bill_addrLine_len*2)+1,bill_addrLine_len))
    data!.setFieldValue("BILL_ADDR_LINE4", b$((bill_addrLine_len*3)+1,bill_addrLine_len))
    data!.setFieldValue("BILL_ADDR_LINE5", b$((bill_addrLine_len*4)+1,bill_addrLine_len))
    data!.setFieldValue("BILL_ADDR_LINE6", b$((bill_addrLine_len*5)+1,bill_addrLine_len))

    data!.setFieldValue("SHIP_ADDR_LINE1", c$((cust_addrLine_len*0)+1,cust_addrLine_len))
    data!.setFieldValue("SHIP_ADDR_LINE2", c$((cust_addrLine_len*1)+1,cust_addrLine_len))
    data!.setFieldValue("SHIP_ADDR_LINE3", c$((cust_addrLine_len*2)+1,cust_addrLine_len))
    data!.setFieldValue("SHIP_ADDR_LINE4", c$((cust_addrLine_len*3)+1,cust_addrLine_len))
    data!.setFieldValue("SHIP_ADDR_LINE5", c$((cust_addrLine_len*4)+1,cust_addrLine_len))
    data!.setFieldValue("SHIP_ADDR_LINE6", c$((cust_addrLine_len*5)+1,cust_addrLine_len))

    data!.setFieldValue("SALESREP_CODE", slspsn_code$)
    data!.setFieldValue("SALESREP_DESC", slspsn_desc$)
    data!.setFieldValue("CUST_PO_NUM", cust_po_no$)
    data!.setFieldValue("SHIP_VIA", ship_via$)
    data!.setFieldValue("SHIPPING_ID", shipping_id$)
    data!.setFieldValue("FOB", fob$)
    data!.setFieldValue("SHIP_DATE", ship_date$)
    data!.setFieldValue("TERMS_CODE", terms_code$)
    data!.setFieldValue("TERMS_DESC", terms_desc$)

    memo_1024$=opcMessage.memo_1024$
    if len(memo_1024$) and memo_1024$(len(memo_1024$))=$0A$ then memo_1024$=memo_1024$(1,len(memo_1024$)-1); rem --- trim trailing newline
    data!.setFieldValue("INV_STD_MESSAGE", memo_1024$)

    rs!.insert(data!)

	sp!.setRecordSet(rs!)
    
	goto std_exit

format_address: rem --- Reformat address to bottom justify
	dim tmp_address$(6*line_len)
	y=5*line_len+1
	for x=y to 1 step -line_len
		if cvs(address$(x,line_len),2)<>""
			tmp_address$(y,line_len)=address$(x,line_len)
			y=y-line_len
		endif
	next x
	address$=tmp_address$
	return

get_stdMessage: rem --- Get Standard Message lines
    find record (opcMessage_dev, key=firm_id$+opeInvHdr.message_code$, dom=*next)opcMessage$
		
    return

rem --- Functions
    def fnline2y%(tmp0)=(tmp0*12)+12+top_of_detail+2


rem #include std_end.src

sproc_error:rem --- SPROC error trap/handler
    rd_err_text$="", err_num=err
    if tcb(2)=0 and tcb(5) then rd_err_text$=pgm(tcb(5),tcb(13),err=*next)
    x$=stbl("+THROWN_ERR","TRUE")   
    throw "["+pgm(-2)+"] "+str(tcb(5))+": "+rd_err_text$,err_num
	
std_exit:
	rem --- Close files
		x = files_opened
		while x>=1
			close (channels[x],err=*next)
			x=x-1
		wend

    end
