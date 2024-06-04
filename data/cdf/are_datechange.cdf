[[ARE_DATECHANGE.AR_DIST_CODE.AVAL]]
rem --- Don't allow inactive code
	arcDistCode_dev=fnget_dev("ARC_DISTCODE")
	dim arcDistCode$:fnget_tpl$("ARC_DISTCODE")
	ar_dist_code$=callpoint!.getUserInput()
	read record(arcDistCode_dev,key=firm_id$+"D"+ar_dist_code$,dom=*next)arcDistCode$
	if arcDistCode.code_inactive$ = "Y"
		msg_id$="AD_CODE_INACTIVE"
		dim msg_tokens$[2]
		msg_tokens$[1]=cvs(arcDistCode.ar_dist_code$,3)
		msg_tokens$[2]=cvs(arcDistCode.code_desc$,3)
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif

[[ARE_DATECHANGE.AR_INV_NO_VER.AVAL]]
	msg_id$="AR_INV_NO"
	dim msg_tokens$[1]
	msg_opt$=""
	dim art_invhdr$:user_tpl.art_invhdr_tpl$
	firm_id$=callpoint!.getColumnData("ARE_DATECHANGE.FIRM_ID")
	ar_type$=callpoint!.getColumnData("ARE_DATECHANGE.AR_TYPE")
	cust_id$=callpoint!.getColumnData("ARE_DATECHANGE.CUSTOMER_ID")
	inv_no$=callpoint!.getUserInput()
	readrecord(user_tpl.art_invhdr_chn,key=firm_id$+ar_type$+cust_id$+inv_no$+"00",dom=invalid_inv)art_invhdr$
	msg_id$=""
	callpoint!.setColumnData("ARE_DATECHANGE.AR_TERMS_CODE",art_invhdr.ar_terms_code$)
	callpoint!.setColumnData("ARE_DATECHANGE.DISCOUNT_AMT",str(art_invhdr.disc_allowed))
	callpoint!.setColumnData("ARE_DATECHANGE.DISC_DATE",art_invhdr.disc_date$)
	callpoint!.setColumnData("ARE_DATECHANGE.INVOICE_AMT",str(art_invhdr.invoice_amt))
	callpoint!.setColumnData("ARE_DATECHANGE.INVOICE_DATE",art_invhdr.invoice_date$)
	callpoint!.setColumnData("ARE_DATECHANGE.INVOICE_TYPE",art_invhdr.invoice_type$)
	callpoint!.setColumnData("ARE_DATECHANGE.INV_DUE_DATE",art_invhdr.inv_due_date$)
	callpoint!.setStatus("ABLEMAP-REFRESH")

invalid_inv:
	if msg_id$<>"" then
		gosub disp_message
	endif

[[ARE_DATECHANGE.AR_TERMS_CODE.AVAL]]
rem --- Don't allow inactive code
	arc_termcode_dev=fnget_dev("ARC_TERMCODE")
	dim arm10a$:fnget_tpl$("ARC_TERMCODE")
	ar_terms_code$=callpoint!.getUserInput()
	read record(arc_termcode_dev,key=firm_id$+"A"+ar_terms_code$,dom=*next)arm10a$
	if arm10a.code_inactive$ = "Y"
		msg_id$="AD_CODE_INACTIVE"
		dim msg_tokens$[2]
		msg_tokens$[1]=cvs(arm10a.ar_terms_code$,3)
		msg_tokens$[2]=cvs(arm10a.code_desc$,3)
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- recalculate due and discount dates
	tmp_inv_date$=callpoint!.getColumnData("ARE_DATECHANGE.INVOICE_DATE")
	tmp_term_code$=callpoint!.getUserInput()
	gosub recalc_dates

[[ARE_DATECHANGE.AWIN]]
rem --- Open/Lock files
files=1,begfile=1,endfile=1
dim files$[files],options$[files],chans$[files],templates$[files]
files$[1]="ARE_DATECHANGE";rem --- "are-06"
for wkx=begfile to endfile
	options$[wkx]="OTA"
next wkx
call dir_pgm$+"bac_open_tables.bbj",begfile,endfile,files$[all],options$[all],
:                                   chans$[all],templates$[all],table_chans$[all],batch,status$
if status$<>"" then
	remove_process_bar:
	bbjAPI!=bbjAPI()
	rdFuncSpace!=bbjAPI!.getGroupNamespace()
	rdFuncSpace!.setValue("+build_task","OFF")
	release
endif
are_datechange_dev=num(chans$[1])

[[ARE_DATECHANGE.BSHO]]
num_files=3
dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
open_tables$[1]="ART_INVHDR",open_opts$[1]="OTA"
open_tables$[2]="ARC_TERMCODE",open_opts$[2]="OTA"
open_tables$[3]="ARC_DISTCODE",open_opts$[3]="OTA"
gosub open_tables
dim user_tpl$:"art_invhdr_tpl:c("+str(len(open_tpls$[1]))+"*),art_invhdr_chn:n(3*)"
user_tpl.art_invhdr_chn=num(open_chans$[1])
user_tpl.art_invhdr_tpl$=open_tpls$[1]

[[ARE_DATECHANGE.BWRI]]
rem --- Abort if record not a valid invoice
	art_invhdr_dev=fnget_dev("ART_INVHDR")
	find record (art_invhdr_dev,key=firm_id$+
:		callpoint!.getColumnData("ARE_DATECHANGE.AR_TYPE")+
:		callpoint!.getColumnData("ARE_DATECHANGE.CUSTOMER_ID")+
:		callpoint!.getColumnData("ARE_DATECHANGE.AR_INV_NO_VER")+"00",dom=*next);goto valid_inv
	callpoint!.setMessage("AR_INV_NO")
	callpoint!.setStatus("ABORT")
valid_inv:
	arc_temcode_dev=fnget_dev("ARC_TERMCODE")
	find record (arc_temcode_dev,key=firm_id$+"A"+
:		pad(callpoint!.getColumnData("ARE_DATECHANGE.AR_TERMS_CODE"),2),dom=*next);goto valid_terms
	callpoint!.setMessage("INVALID_TERMS")
	callpoint!.setStatus("ABORT")
valid_terms:	

[[ARE_DATECHANGE.CUSTOMER_ID.AVAL]]
rem "Customer Inactive Feature"
customer_id$=callpoint!.getUserInput()
arm01_dev=fnget_dev("ARM_CUSTMAST")
arm01_tpl$=fnget_tpl$("ARM_CUSTMAST")
dim arm01a$:arm01_tpl$
arm01a_key$=firm_id$+customer_id$
find record (arm01_dev,key=arm01a_key$,err=*break) arm01a$
if arm01a.cust_inactive$="Y" then
   call stbl("+DIR_PGM")+"adc_getmask.aon","CUSTOMER_ID","","","",m0$,0,customer_size
   msg_id$="AR_CUST_INACTIVE"
   dim msg_tokens$[2]
   msg_tokens$[1]=fnmask$(arm01a.customer_id$(1,customer_size),m0$)
   msg_tokens$[2]=cvs(arm01a.customer_name$,2)
   gosub disp_message
   callpoint!.setStatus("ACTIVATE-ABORT")
endif

[[ARE_DATECHANGE.INVOICE_DATE.AVAL]]
rem --- recalculate due and discount dates
	tmp_inv_date$=callpoint!.getUserInput()
	tmp_term_code$=callpoint!.getColumnData("ARE_DATECHANGE.AR_TERMS_CODE")
	gosub recalc_dates

[[ARE_DATECHANGE.<CUSTOM>]]
#include [+ADDON_LIB]std_functions.aon
recalc_dates:
	rem --- tmp_term_code$ and tmp_inv_date$ set prior to gosub
	arc_termcode_dev=fnget_dev("ARC_TERMCODE")
	dim arc_termcode$:fnget_tpl$("ARC_TERMCODE")
	while 1
		readrecord (arc_termcode_dev,key=firm_id$+"A"+tmp_term_code$,dom=*break)arc_termcode$
		call stbl("+DIR_PGM")+"adc_duedate.aon",arc_termcode.prox_or_days$,tmp_inv_date$,
:			arc_termcode.inv_days_due,due$,status
		callpoint!.setColumnData("ARE_DATECHANGE.INV_DUE_DATE",due$)
		readrecord (arc_termcode_dev,key=firm_id$+"A"+tmp_term_code$,dom=*break)arc_termcode$
		call stbl("+DIR_PGM")+"adc_duedate.aon",arc_termcode.prox_or_days$,tmp_inv_date$,
:			arc_termcode.disc_days,due$,status
		callpoint!.setColumnData("ARE_DATECHANGE.DISC_DATE",due$)
		callpoint!.setStatus("REFRESH")
		break
	wend
	return



