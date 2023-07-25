[[ARC_CC_USERS.AOPT-DACT]]
use java.time.format.DateTimeFormatter
use java.time.LocalDate

REM Toggle the Deactivated Field
declare BBjString currentValue!
declare BBjString customer_id$
declare BBjString username$

customer_id$=callpoint!.getColumnData("ARC_CC_USERS.CUSTOMER_ID")
username$=callpoint!.getColumnData("ARC_CC_USERS.CC_USERNAME")

arc_cc_users=fnget_dev("1ARC_CC_USERS")
dim arc_cc_users$:fnget_tpl$("1ARC_CC_USERS")

key$=firm_id$+customer_id$+username$
read record (arc_cc_users,key=key$) arc_cc_users$

if (cvs(arc_cc_users.deactivated_date$,3)="") then
	msg_id$="GENERIC_YN"
        dim msg_tokens$[1]
	rem dim table_chans$[10,10]
        msg_tokens$[1]="Are you sure you want to deactivate this user?"
        call stbl("+DIR_SYP")+"bac_message.bbj",msg_id$,msg_tokens$[all],msg_opt$,table_chans$[all]
	if (pos("Y"=msg_opt$)>-1) then 
        		deactivatedDate!=DateTimeFormatter.BASIC_ISO_DATE.format(LocalDate.now())
		arc_cc_users.deactivated_date$=deactivatedDate!
		write record (arc_cc_users) arc_cc_users$
		callpoint!.setStatus("RECORD:["+key$+"]")
	endif
else 
	arc_cc_users.deactivated_date$=""
	write record (arc_cc_users) arc_cc_users$
	callpoint!.setStatus("RECORD:["+key$+"]")
endif 


 

[[ARC_CC_USERS.BDEL]]
rem --- Remove deleted user from Enterprise Manager
	admin!=callpoint!.getDevObject("admin")
	cc_username$=cvs(callpoint!.getColumnData("ARC_CC_USERS.CC_USERNAME"),2)
	thisUser!=new CCUserModel()
	admin!.dropUser(thisUser!.getEMUserName(cc_username$),err=*next)
	admin!.commit(err=*next)

[[ARC_CC_USERS.BSHO]]
rem --- Get needed classes
	use ::ado_util.src::util
	use ::aro_CCUtil.aon::CCUtil
	use ::aro_CCUserModel.aon::CCUserModel

rem --- Get BBjAdmin object
	admin!=CCUtil.getAdmin()
	callpoint!.setDevObject("admin",admin!)

num_files=1
dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
open_tables$[1]="ARC_CC_USERS",open_opts$[1]="OTA[1]"
gosub open_tables

[[ARC_CC_USERS.CC_USERNAME.AVAL]]
rem --- Validate email address
	email$=callpoint!.getUserInput()
	if !util.validEmailAddress(email$) then
		callpoint!.setStatus("ABORT")
		break
	endif



