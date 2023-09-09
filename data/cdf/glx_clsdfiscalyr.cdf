[[GLX_CLSDFISCALYR.AFMC]]
rem --- Inits
	use java.io.File

	use ::ado_util.src::util

rem --- Add static label to display fiscal period description
	period!=fnget_control!("GLX_CLSDFISCALYR.PERIOD")
	period_x=period!.getX()
	period_y=period!.getY()
	period_height=period!.getHeight()
	period_width=period!.getWidth()
	desc_width=105
	nxt_ctlID=util.getNextControlID()
	period_desc!=Form!.addStaticText(nxt_ctlID,period_x+period_width+6,period_y+3,desc_width,period_height-6,"")
	RGB$=stbl("+HYPERLINK_COLOR")
	gosub get_RGB
	labelColor! = BBjAPI().makeColor(R,G,B); rem --- Blue color only. This is NOT a hyperlink.
	period_desc!.setForeColor(labelColor!)
	callpoint!.setDevObject("period_desc",period_desc!)

[[GLX_CLSDFISCALYR.AREC]]
rem --- Initialize amount and units display only fields
	callpoint!.setColumnData("GLX_CLSDFISCALYR.DEBIT_AMT",str(0))
	callpoint!.setColumnData("GLX_CLSDFISCALYR.CREDIT_AMT",str(0))
	callpoint!.setColumnData("GLX_CLSDFISCALYR.TOTAL_AMOUNT",str(0))
	callpoint!.setColumnData("GLX_CLSDFISCALYR.UNITS",str(0))

rem --- Clear static label for fiscal period description
	period_desc!=callpoint!.getDevObject("period_desc")
	period_desc!.setText("")

[[GLX_CLSDFISCALYR.BSHO]]
rem --- Open files
	num_files=2
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="GLS_PARAMS",open_opts$[1]="OTA"
	open_tables$[2]="GLS_CALENDAR",open_opts$[2]="OTA"

	gosub open_tables

rem --- Files to be backed up
	backupFiles! = BBjAPI().makeVector()
	backupFiles!.addItem("glm-01")
	backupFiles!.addItem("glm-02")
	backupFiles!.addItem("glt-04")
	backupFiles!.addItem("glt-06")
	backupFiles!.addItem("glt-15")
	callpoint!.setDevObject("backupFiles",backupFiles!)

[[GLX_CLSDFISCALYR.DIR_BROWSE.AVAL]]
rem --- Backup directory must already exists
	backupDir$=callpoint!.getUserInput()
	backupDir!=new File(backupDir$)
	if !backupDir!.exists() or !backupDir!.isDirectory() then
		msg_id$="AD_DIR_MISSING"
		dim msg_tokens$[1]
		msg_tokens$[1]=backupDir$
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif

	rem --- Remove trailing slashes (/ and \) from backup dirctory
	backupDir$=backupDir!.getCanonicalPath()
	while len(backupDir$) and pos(backupDir$(len(backupDir$),1)="/\")
		backupDir$ = backupDir$(1, len(backupDir$)-1)
	wend

rem --- Backup directory can NOT already contain GL data files that will be updated.
	fileExists!=null()
	backupFiles!=callpoint!.getDevObject("backupFiles")
	for i=0 to backupFiles!.size()-1
		thisFile!=new File(backupDir$+"/"+backupFiles!.getItem(i))
		if thisFile!.exists() then
			fileExists!=thisFile!
			break
		endif
	next i
	if fileExists!<>null() then
		msg_id$="GL_BCKUP_FILE_EXISTS"
		dim msg_tokens$[1]
		msg_tokens$[1]=fileExists!.getCanonicalPath()
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- Use the backup directory's canonical path
	callpoint!.setUserInput(backupDir$)

[[GLX_CLSDFISCALYR.TRANS_DATE.AVAL]]
rem --- Must be in an existing fiscal year.
	trans_date$=callpoint!.getUserInput()
	call pgmdir$+"adc_fiscalperyr.aon",firm_id$,trans_date$,period$,year$,table_chans$[all],status
	if status then
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- Must be in the prior fiscal year.
	glsParams_dev=fnget_dev("GLS_PARAMS")
	dim glsParams$:fnget_tpl$("GLS_PARAMS")
	readrecord(glsParams_dev,key=firm_id$+"GL00")glsParams$
	if num(year$)<>num(glsParams.current_year$)-1 then
		msg_id$="GL_NOT_PRIOR_YR"
		dim msg_tokens$[1]
		msg_tokens$[1]=str(num(glsParams.current_year$)-1)
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif
	

rem --- Prior fiscal year must be closed fiscal.
	if glsParams.gl_yr_closed$<>"Y" then
		msg_id$="GL_PRI_YR_NOT_CLOSED"
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- Show the fiscal year and period
	callpoint!.setColumnData("GLX_CLSDFISCALYR.YEAR",year$,1)
	callpoint!.setColumnData("GLX_CLSDFISCALYR.PERIOD",period$,1)

rem --- Show description for fiscal period
	glsCalendar_dev=fnget_dev("GLS_CALENDAR")
	dim glsCalendar$:fnget_tpl$("GLS_CALENDAR")
	readrecord(glsCalendar_dev,key=firm_id$+year$,dom=*next)glsCalendar$
	periodName$=field(glsCalendar$,"period_name_"+period$)
	period_desc!=callpoint!.getDevObject("period_desc")
	period_desc!.setText(periodName$)

[[GLX_CLSDFISCALYR.<CUSTOM>]]
rem ==========================================================================
get_RGB: rem --- Parse Red, Green and Blue segments from RGB$ string
	rem --- input: RGB$
	rem --- output: R
	rem --- output: G
	rem --- output: B
rem ==========================================================================
	comma1=pos(","=RGB$,1,1)
	comma2=pos(","=RGB$,1,2)
	R=num(RGB$(1,comma1-1))
	G=num(RGB$(comma1+1,comma2-comma1-1))
	B=num(RGB$(comma2+1))

	return

#include [+ADDON_LIB]std_functions.aon

rem #include fnget_control.src
	def fnget_control!(ctl_name$)
	ctlContext=num(callpoint!.getTableColumnAttribute(ctl_name$,"CTLC"))
	ctlID=num(callpoint!.getTableColumnAttribute(ctl_name$,"CTLI"))
	get_control!=SysGUI!.getWindow(ctlContext).getControl(ctlID)
	return get_control!
	fnend
rem #endinclude fnget_control.src



