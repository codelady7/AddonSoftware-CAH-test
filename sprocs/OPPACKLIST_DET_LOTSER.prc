rem ----------------------------------------------------------------------------
rem --- OP Pack List Lot/Serial Detail Printing
rem --- Program: OPPACKLIST_DET_LOTSER.prc 

rem --- Copyright BASIS International Ltd.
rem --- All Rights Reserved

rem --- This SPROC is called from the OPPackListDet-LotSer Jasper report as the detail/subreport from OPPackListDet

rem ----------------------------------------------------------------------------

	seterr sproc_error

rem --- Use statements and Declares
    use ::ado_func.src::func

	declare BBjStoredProcedureData sp!
	declare BBjRecordSet rs!
	declare BBjRecordData data!

rem --- Get the infomation object for the Stored Procedure
	sp! = BBjAPI().getFileSystem().getStoredProcedureData()

rem --- Get 'IN' SPROC parameters 
	firm_id$ =               sp!.getParameter("FIRM_ID")
	ar_type$ =               sp!.getParameter("AR_TYPE")
	customer_id$ =           sp!.getParameter("CUSTOMER_ID")
	order_no$ =              sp!.getParameter("ORDER_NO")
    ar_inv_no$ =             sp!.getParameter("AR_INV_NO")
    carton_no$ =             sp!.getParameter("CARTON_NO")
	orddet_seq_ref$ =        sp!.getParameter("ORDDET_SEQ_REF")
	qty_mask$ =              sp!.getParameter("QTY_MASK")
	barista_wd$ =            sp!.getParameter("BARISTA_WD")

	chdir barista_wd$

rem --- create the in memory recordset for return
	dataTemplate$ = ""
	dataTemplate$ = dataTemplate$ + "lotser_no:c(1*), pack_qty:c(1*) " 
	
	rs! = BBJAPI().createMemoryRecordSet(dataTemplate$)

rem --- Retrieve the program path
    pgmdir$=""
    pgmdir$=stbl("+DIR_PGM",err=*next)
    sypdir$=""
    sypdir$=stbl("+DIR_SYP",err=*next)

rem --- Open Files    
rem --- Note 'files' and 'channels[]' are used in close loop, so don't re-use
    files=1,begfile=1,endfile=files
    dim files$[files],options$[files],ids$[files],templates$[files],channels[files]    

    files$[1]="opt_cartlsdet",  ids$[1]="OPT_CARTLSDET"
	
	call pgmdir$+"adc_fileopen.aon",action,begfile,endfile,files$[all],options$[all],ids$[all],templates$[all],channels[all],batch,status

    if status then
        seterr 0
        x$=stbl("+THROWN_ERR","TRUE")   
        throw "File open error.",1001
    endif
    
	files_opened = files; rem used in loop to close files

    optCartLsDet_dev = channels[1]
    
    dim optCartLsDet$:templates$[1]

rem --- Get any associated Lots/SerialNumbers
    optCartLsDet_trip$=firm_id$+"E"+ar_type$+customer_id$+order_no$+ar_inv_no$+carton_no$+orddet_seq_ref$
    read(optCartLsDet_dev, key=optCartLsDet_trip$, knum="AO_STATUS", dom=*next)
    while 1
        optCartLsDet_key$=key(optCartLsDet_dev,end=*break)
        if pos(optCartLsDet_trip$=optCartLsDet_key$)<>1 then break
        readrecord(optCartLsDet_dev,end=*break)optCartLsDet$

        data! = rs!.getEmptyRecordData()
		data!.setFieldValue("LOTSER_NO",optCartLsDet.lotser_no$)
		data!.setFieldValue("PACK_QTY","( "+cvs(str(optCartLsDet.qty_packed:qty_mask$),3)+" )")

		rs!.insert(data!)
	wend

	sp!.setRecordSet(rs!)

	goto std_exit

	
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
