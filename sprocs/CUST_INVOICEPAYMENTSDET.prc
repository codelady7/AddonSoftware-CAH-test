rem ----------------------------------------------------------------------------
rem Program: CUST_PRINTPAYMENTSDET.prc
rem Description: Stored Procedure to create a jasper-based payment history detail
rem              for Historical Invoices
rem AddonSoftware
rem Copyright BASIS International Ltd.
rem ----------------------------------------------------------------------------

    seterr sproc_error
    
    declare BBjStoredProcedureData sp!
    declare BBjRecordSet rs!
    declare BBjRecordData data!
    
    sp! = BBjAPI().getFileSystem().getStoredProcedureData()

rem --- get SPROC parameters

    firm_id$ = sp!.getParameter("FIRM_ID")
    customer$ = sp!.getParameter("CUSTOMER_ID")
    ar_inv_no$ = sp!.getParameter("AR_INV_NO")
    amt_mask$ = sp!.getParameter("AMT_MASK")
    barista_wd$ = sp!.getParameter("BARISTA_WD")
    
    chdir barista_wd$

rem --- create the in memory recordset for return

    dataTemplate$ = "receipt_date:C(1*),trans_type:C(1*),check_no:C(1*),amount:C(1*)"
    
    rs! = BBJAPI().createMemoryRecordSet(dataTemplate$)

rem --- Retrieve the program path

    pgmdir$=""
    pgmdir$=stbl("+DIR_PGM",err=*next)

rem --- open files

    files=2,begfile=1,endfile=files
    dim files$[files],options$[files],ids$[files],templates$[files],channels[files]
    files$[1]="art-16",      ids$[1]="ART_CASHDET"
    files$[2]="arc_cashcode",ids$[2]="ARC_CASHCODE"

    call pgmdir$+"adc_fileopen.aon",action,begfile,endfile,files$[all],options$[all],ids$[all],templates$[all],channels[all],batch,status
    if status then
        seterr 0
        x$=stbl("+THROWN_ERR","TRUE")   
        throw "File open error.",1001
    endif

    artCashDet_dev=channels[1]
    arcCashCode_dev=channels[2]
	dim artCashDet$:templates$[1]
    dim arcCashCode$:templates$[2]

rem --- main loop
    artCashDet_trip$=firm_id$+"  "+customer$+ar_inv_no$
    readrecord(artCashDet_dev,key=artCashDet_trip$,knum="AO_CUST_INV",dom=*next)
    while 1
        artCashDet_key$=key(artCashDet_dev,end=*break)
        if pos(artCashDet_trip$=artCashDet_key$)<>1 then break
    	readrecord(artCashDet_dev,end=*break)artCashDet$
    	
        rem --- get type of transaction
        redim arcCashCode$
        readrecord(arcCashCode_dev,key=firm_id$+"C"+artCashDet.cash_rec_cd$,dom=*next)arcCashCode$
    
    dataTemplate$ = "receipt_date:C(1*),trans_type:C(1*),check_no:C(1*),amount:C(1*)"
    	rem --- put data into recordset
     	data! = rs!.getEmptyRecordData()
        data!.setFieldValue("RECEIPT_DATE",fndate$(artCashDet.receipt_date$))
        data!.setFieldValue("TRANS_TYPE",arcCashCode.code_desc$)
        data!.setFieldValue("CHECK_NO",artCashDet.ar_check_no$)
        data!.setFieldValue("AMOUNT",str(artCashDet.apply_amt:amt_mask$))
    	rs!.insert(data!)
    wend

rem --- close files

    close(artCashDet_dev)
    close(arcCashCode_dev)
    
    sp!.setRecordSet(rs!)
    end

rem --- Date/time handling functions

    def fndate$(q$)
        q1$=""
        q1$=date(jul(num(q$(1,4)),num(q$(5,2)),num(q$(7,2)),err=*next),err=*next)
        if q1$="" q1$=q$
        return q1$
    fnend

    def fnyy$(q$)=q$(3,2)
    def fnclock$(q$)=date(0:"%hz:%mz %p")
    def fntime$(q$)=date(0:"%Hz%mz")

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
    end
