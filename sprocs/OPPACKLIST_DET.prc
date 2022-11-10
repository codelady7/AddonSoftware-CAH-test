rem ----------------------------------------------------------------------------
rem --- OP Pack List Detail Printing
rem --- Program: OPPACKLIST_DET.prc 

rem --- Copyright BASIS International Ltd.
rem --- All Rights Reserved

rem --- This SPROC is called from the OPPackListDet Jasper report as the detail/subreport from OPPackListHdr

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
	firm_id$ =       sp!.getParameter("FIRM_ID")
	ar_type$ =       sp!.getParameter("AR_TYPE")
	customer_id$ =   sp!.getParameter("CUSTOMER_ID")
	order_no$ =      sp!.getParameter("ORDER_NO")
    ar_inv_no$ =     sp!.getParameter("AR_INV_NO")
	qty_mask$ =      sp!.getParameter("QTY_MASK")
    ivIMask$ =       sp!.getParameter("ITEM_MASK")
	barista_wd$ =    sp!.getParameter("BARISTA_WD")

	chdir barista_wd$

rem --- create the in memory recordset for return
	dataTemplate$ = ""
	dataTemplate$ = dataTemplate$ + "item_id:c(1*), item_desc:c(1*), um_sold:c(6*),ship_qty:c(1*), pack_qty:c(1*), "
	dataTemplate$ = dataTemplate$ + "carton_no:c(1*), orddet_seq_ref:c(1*), item_is_ls:c(1)"

	rs! = BBJAPI().createMemoryRecordSet(dataTemplate$)

rem --- Retrieve the program path
    pgmdir$=""
    pgmdir$=stbl("+DIR_PGM",err=*next)
    sypdir$=""
    sypdir$=stbl("+DIR_SYP",err=*next)
	
rem --- Open Files    
rem --- Note 'files' and 'channels[]' are used in close loop, so don't re-use
    files=4,begfile=1,endfile=files
    dim files$[files],options$[files],ids$[files],templates$[files],channels[files]    

    files$[1]="ivs_params",     ids$[1]="IVS_PARAMS"
    files$[2]="opt_cartdet",    ids$[2]="OPT_CARTDET"
    files$[3]="opt_fillmntdet", ids$[3]="OPT_FILLMNTDET"
    files$[4]="ivm-01",         ids$[4]="IVM_ITEMMAST"

	call pgmdir$+"adc_fileopen.aon",action,begfile,endfile,files$[all],options$[all],ids$[all],templates$[all],channels[all],batch,status

    if status then
        seterr 0
        x$=stbl("+THROWN_ERR","TRUE")   
        throw "File open error.",1001
    endif
    
	files_opened = files; rem used in loop to close files

    ivsParams_dev     = channels[1]
    optCartDet_dev    = channels[2]
    optFillmntDet_dev = channels[3]
    ivm01_dev         = channels[4]
    
    dim ivsParams$:templates$[1]
    dim optCartDet$:templates$[2]
    dim optFillmntDet$:templates$[3]
    dim ivm01a$:templates$[4]

rem --- Get IV parameters
    findrecord(ivsParams_dev,key=firm_id$+"IV00",dom=*next)ivsParams$
    
rem --- Main
	optCartDet_trip$=firm_id$+"E"+ar_type$+customer_id$+order_no$+ar_inv_no$
    read(optCartDet_dev, key=optCartDet_trip$, knum="AO_STATUS", dom=*next)

rem --- Detail lines
    while 1
		optCartDet_key$=key(optCartDet_dev,end=*break)
		if pos(optCartDet_trip$=optCartDet_key$)<>1 then break
        readrecord(optCartDet_dev,end=*break)optCartDet$

		foundFillmntDet=0
		read(optFillmntDet_dev,key=optCartDet_trip$,knum="AO_STATUS",dom=*next)
		while 1
			optFillmntDet_key$=key(optFillmntDet_dev,end=*break)
			if pos(optCartDet_trip$=optFillmntDet_key$)<>1 then break
			readrecord(optFillmntDet_dev)optFillmntDet$
			if optFillmntDet.orddet_seq_ref$<>optCartDet.orddet_seq_ref$ then continue
			foundFillmntDet=1
			break
		wend
		if !foundFillmntDet then continue

		item_id$ = ""
		item_desc$ = ""
        um_sold$ = optCartDet.um_sold$
        ship_qty$ = str(optFillmntDet.qty_picked:qty_mask$)
        pack_qty$ = str(optCartDet.qty_packed:qty_mask$)
        carton_no$ = optCartDet.carton_no$
        orddet_seq_ref$ = optCartDet.orddet_seq_ref$
		item_is_ls$ = "N"
	
        redim ivm01a$
        ivm01a.conv_factor=1
        findrecord(ivm01_dev,key=firm_id$+optCartDet.item_id$,dom=*next)ivm01a$
		if pos(ivsParams.lotser_flag$="LS") then item_is_ls$=ivm01a.lotser_item$
        if cvs(ivm01a.item_id$,2)<>"" then
            item_id$=cvs(fnmask$(optCartDet.item_id$,ivIMask$),3)
        	item_description$=func.displayDesc(ivm01a.item_desc$)
            item_desc$=item_id$+" "+cvs(item_description$,3)+iff(cvs(optFillmntDet.memo_1024$,3)="",""," - "+cvs(optFillmntDet.memo_1024$,3))
		else
			item_desc$=cvs(optFillmntDet.memo_1024$,3)
		endif
        if len(item_desc$) and item_desc$(len(item_desc$),1)=$0A$ then item_desc$=item_desc$(1,len(item_desc$)-1)

        data! = rs!.getEmptyRecordData()
		data!.setFieldValue("ITEM_ID", item_id$)
		data!.setFieldValue("ITEM_DESC", item_desc$)
        data!.setFieldValue("UM_SOLD",cvs(um_sold$,3))			
		data!.setFieldValue("SHIP_QTY",cvs(ship_qty$,3))
		data!.setFieldValue("PACK_QTY",cvs(pack_qty$,3))
        data!.setFieldValue("CARTON_NO",carton_no$)
        data!.setFieldValue("ORDDET_SEQ_REF",orddet_seq_ref$)
		data!.setFieldValue("ITEM_IS_LS",item_is_ls$)

		rs!.insert(data!)
    wend

rem --- Tell the stored procedure to return the result set.
	sp!.setRecordSet(rs!)

	goto std_exit

rem --- Functions
    def fndate$(q$)
        q1$=""
        q1$=date(jul(num(q$(1,4)),num(q$(5,2)),num(q$(7,2)),err=*next),err=*next)
        if q1$="" q1$=q$
        return q1$
    fnend

rem --- fnmask$: Alphanumeric Masking Function (formerly fnf$)
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
