[[ART_INVHDR_ARC.ADIS]]
rem --- Display customer address
	cust_key$=callpoint!.getColumnData("ART_INVHDR_ARC.FIRM_ID")+callpoint!.getColumnData("ART_INVHDR_ARC.CUSTOMER_ID")
	gosub disp_cust_addr
	gosub calc_grid_tots
	callpoint!.setColumnData("<<DISPLAY>>.TOT_QTY",str(callpoint!.getDevObject("tqty")),1)
	callpoint!.setColumnData("<<DISPLAY>>.TOT_AMT",str(callpoint!.getDevObject("tamt")),1)

rem --- Display Comments
	cust_id$=callpoint!.getColumnData("ART_INVHDR_ARC.CUSTOMER_ID")
	gosub disp_cust_comments

rem --- Disable Print for Voided invoices
	if callpoint!.getColumnData("ART_INVHDR_ARC.SIM_INV_TYPE")="V"
		callpoint!.setOptionEnabled("PRNT",0)
	else
		callpoint!.setOptionEnabled("PRNT",1)
	endif

[[ART_INVHDR_ARC.AOPT-PRNT]]
rem Print Archive Invoice

ar_inv_no$=callpoint!.getColumnData("ART_INVHDR_ARC.AR_INV_NO")
cust_id$=callpoint!.getColumnData("ART_INVHDR_ARC.CUSTOMER_ID")
user_id$=stbl("+USER_ID")

dim dflt_data$[2,1]
dflt_data$[1,0]="AR_INV_NO"
dflt_data$[1,1]=ar_inv_no$
dflt_data$[2,0]="CUSTOMER_ID"
dflt_data$[2,1]=cust_id$
call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:                       "ARR_INVOICES_ARC",
:                       user_id$,
:                   	"",
:                       "",
:                       table_chans$[all],
:                       "",
:                       dflt_data$[all]

[[ART_INVHDR_ARC.BSHO]]
rem --- Use statements

	use ::ado_func.src::func

	callpoint!.setDevObject("tamt","0")
	callpoint!.setDevObject("tqty","0")

[[ART_INVHDR_ARC.<CUSTOM>]]
#include [+ADDON_LIB]std_functions.aon
calc_grid_tots:
        recVect!=GridVect!.getItem(0)
        dim gridrec$:dtlg_param$[1,3]
        numrecs=recVect!.size()
        if numrecs>0
            for reccnt=0 to numrecs-1
                gridrec$=recVect!.getItem(reccnt)
                tqty=tqty+num(gridrec.units$)
                tamt=tamt+num(gridrec.ext_price$)
            next reccnt
	    callpoint!.setDevObject("tqty",str(tqty))
	    callpoint!.setDevObject("tamt",str(tamt))
        endif
    return

disp_cust_addr:

	declare BBjTemplatedString addr!

	arm_custmast_dev = fnget_dev("ARM_CUSTMAST")
	dim arm01a$:fnget_tpl$("ARM_CUSTMAST")
	read record (arm_custmast_dev, key=cust_key$, err=std_error) arm01a$
	addr! = BBjAPI().makeTemplatedString( fnget_tpl$("ARM_CUSTMAST") )
	addr!.setString(arm01a$)
	addr$ = func.formatAddress(table_chans$[all], addr!, 30, 7)

	callpoint!.setColumnData("<<DISPLAY>>.CUST_ADDR1",addr$(31,30),1)
	callpoint!.setColumnData("<<DISPLAY>>.CUST_ADDR2",addr$(61,30),1)
	callpoint!.setColumnData("<<DISPLAY>>.CUST_ADDR3",addr$(91,30),1)
	callpoint!.setColumnData("<<DISPLAY>>.CUST_ADDR4",addr$(121,30),1)
	callpoint!.setColumnData("<<DISPLAY>>.CUST_CTST",addr$(151,30),1)
	callpoint!.setColumnData("<<DISPLAY>>.CUST_ZIP",addr$(181,30),1)

disp_cust_comments: rem --- You must pass in cust_id$ because we don't know whether it's verified or not
	arm01_dev=fnget_dev("ARM_CUSTMAST")
	dim arm01a$:fnget_tpl$("ARM_CUSTMAST")
	readrecord(arm01_dev,key=firm_id$+cust_id$,dom=*next)arm01a$
	callpoint!.setColumnData("<<DISPLAY>>.comments",arm01a.memo_1024$,1)
	return



