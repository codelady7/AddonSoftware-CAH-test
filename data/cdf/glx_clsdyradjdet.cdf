[[GLX_CLSDYRADJDET.ACCOUNT.AVAL]]
rem --- GL account is active
	glacctinput$=callpoint!.getUserInput()
	glmAcct_dev=fnget_dev("GLM_ACCT")
	dim glmAcct$:fnget_tpl$("GLM_ACCT")
	glmAcct_key$=firm_id$+glacctinput$
	findrecord(glm01_dev,key=glm01a_key$,err=*next) glmAcct$
	if glmAcct.acct_inactive$="Y" then
		call stbl("+DIR_PGM")+"adc_getmask.aon","GL_ACCOUNT","","","",m0$,0,gl_size
		msg_id$="GL_ACCT_INACTIVE"
		dim msg_tokens$[2]
		msg_tokens$[1]=fnmask$(glm01a.gl_account$(1,gl_size),m0$)
		msg_tokens$[2]=cvs(glm01a.gl_acct_desc$,2)
		gosub disp_message
		callpoint!.setStatus("ACTIVATE-ABORT")
		break
	endif

[[GLX_CLSDYRADJDET.ADEL]]
rem --- Recal/display tots after deleting a grid row
	gosub update_grid_tots

[[GLX_CLSDYRADJDET.ADGE]]
rem --- Set default value for memo lines to the description entered in the header
	description$=callpoint!.getHeaderColumnData("GLX_CLSDYRADJHDR.DESCRIPTION")
	callpoint!.setTableColumnAttribute("GLX_CLSDYRADJDET.POST_MEMO","DFLT",description$)
	callpoint!.setTableColumnAttribute("GLX_CLSDYRADJDET.MEMO_1024","DFLT",description$)

rem --- Need to disable units column in grid if gls01a.units_flag$ isn't "Y"
	if callpoint!.getDevObject("units_flag")="Y" then
		callpoint!.setColumnEnabled(-1,"GLX_CLSDYRADJDET.UNITS",1)
	else
		callpoint!.setColumnEnabled(-1,"GLX_CLSDYRADJDET.UNITS",0)
	endif

[[GLX_CLSDYRADJDET.AGCL]]
rem --- Set column size for memo_1024 field very small so it doesn't take up room, but still available for hover-over of memo contents
	use ::ado_util.src::util

	grid! = util.getGrid(Form!)
	col_hdr$=callpoint!.getTableColumnAttribute("GLX_CLSDYRADJDET.MEMO_1024","LABS")
	memo_1024_col=util.getGridColumnNumber(grid!, col_hdr$)
	grid!.setColumnWidth(memo_1024_col,15)

[[GLX_CLSDYRADJDET.AGRE]]
rem --- Recal/display tots when leaving a grid row
	gosub update_grid_tots

[[GLX_CLSDYRADJDET.AGRN]]
rem --- Recal/display tots when entering a grid row
	gosub update_grid_tots

rem --- Enable comments
	if callpoint!.isEditMode() then
		callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"GLX_CLSDYRADJDET.MEMO_1024",1)
		callpoint!.setOptionEnabled("COMM",1)
	else
		callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"GLX_CLSDYRADJDET.MEMO_1024",0)
		callpoint!.setOptionEnabled("COMM",0)
	endif

rem --- Always launch Comments dialog for existing rows
	if callpoint!.getGridRowNewStatus(callpoint!.getValidationRow())<>"Y" then
		callpoint!.setDevObject("skip_memo","N")
	endif

[[GLX_CLSDYRADJDET.AOPT-COMM]]
rem --- Launch Comments dialog
	gosub comment_entry
	callpoint!.setStatus("ABORT")

[[GLX_CLSDYRADJDET.AREC]]
rem --- Skip launching Comments dialog for new rows
	callpoint!.setDevObject("skip_memo","Y")

rem --- Need to disable units column in grid if gls01a.units_flag$ isn't "Y"
	if callpoint!.getDevObject("units_flag")="Y" then
		callpoint!.setColumnEnabled(-1,"GLX_CLSDYRADJDET.UNITS",1)
	else
		callpoint!.setColumnEnabled(-1,"GLX_CLSDYRADJDET.UNITS",0)
	endif

[[GLX_CLSDYRADJDET.AUDE]]
rem --- Recal/display tots after deleting a grid row
	gosub update_grid_tots

rem --- Need to disable units column in grid if gls01a.units_flag$ isn't "Y"
	if callpoint!.getDevObject("units_flag")="Y" then
		callpoint!.setColumnEnabled(-1,"GLX_CLSDYRADJDET.UNITS",1)
	else
		callpoint!.setColumnEnabled(-1,"GLX_CLSDYRADJDET.UNITS",0)
	endif

[[GLX_CLSDYRADJDET.BDGX]]
rem --- Disable comments
	callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"GLX_CLSDYRADJDET.MEMO_1024",0)
	callpoint!.setOptionEnabled("COMM",0)

[[GLX_CLSDYRADJDET.CREDIT_AMT.AVAL]]
rem --- set debit amt to zero (since entering credit), then recalc/display hdr disp columns
	if num(callpoint!.getUserInput())<>0 callpoint!.setColumnData("GLX_CLSDYRADJDET.DEBIT_AMT",str(0),1)

[[GLX_CLSDYRADJDET.CREDIT_AMT.AVEC]]
rem --- Recalc/display hdr disp columns
	gosub update_grid_tots

[[GLX_CLSDYRADJDET.DEBIT_AMT.AVAL]]
rem --- Set credit amt to zero (since entering debit), then recalc/display hdr disp columns
	if num(callpoint!.getUserInput())<>0 callpoint!.setColumnData("GLX_CLSDYRADJDET.CREDIT_AMT",str(0),1)

[[GLX_CLSDYRADJDET.DEBIT_AMT.AVEC]]
rem --- Recalc/display hdr disp columns
	gosub update_grid_tots

[[GLX_CLSDYRADJDET.MEMO_1024.AVAL]]
rem --- Store first part of memo_1024 in post_memo.
rem --- This AVAL is hit if user navigates via arrows or clicks on the memo_1024 field, and double-clicks or ctrl-F to bring up editor.
rem --- If on a memo line or using ctrl-C or Comments button, code in the comment_entry: subroutine is hit instead.

	disp_text$=callpoint!.getUserInput()
	if disp_text$<>callpoint!.getColumnUndoData("GLX_CLSDYRADJDET.MEMO_1024")
		memo_len=len(callpoint!.getColumnData("GLX_CLSDYRADJDET.POST_MEMO"))
		memo$=disp_text$
		memo$=memo$(1,min(memo_len,(pos($0A$=memo$+$0A$)-1)))

		callpoint!.setColumnData("GLX_CLSDYRADJDET.MEMO_1024",disp_text$)
		callpoint!.setColumnData("GLX_CLSDYRADJDET.POST_MEMO",memo$,1)

		callpoint!.setStatus("MODIFIED")
	endif

[[GLX_CLSDYRADJDET.POST_MEMO.BINP]]
rem --- Skip launching Comments dialog the first time
	if callpoint!.getDevObject("skip_memo")="Y" then
		callpoint!.setFocus(callpoint!.getValidationRow(),"GLX_CLSDYRADJDET.DEBIT_AMT",1)
		callpoint!.setDevObject("skip_memo","N"); rem --- Launch Comments dialog the next time
	else
		gosub comment_entry
		callpoint!.setStatus("ABORT")
		break
	endif

[[GLX_CLSDYRADJDET.UNITS.AVEC]]
rem --- Recalc/display hdr disp columns
	gosub update_grid_tots

[[GLX_CLSDYRADJDET.<CUSTOM>]]
update_grid_tots: rem --- Calculate total debits/credits/units and display in form header

	recVect!=GridVect!.getItem(0)
	dim gridrec$:dtlg_param$[1,3]
	numrecs=recVect!.size()
	if numrecs>0
		for reccnt=0 to numrecs-1
			gridrec$=recVect!.getItem(reccnt)
			if cvs(gridrec$,3) <> "" and callpoint!.getGridRowDeleteStatus(reccnt)<>"Y"
				tdb=tdb+num(gridrec.debit_amt$)
				tcr=tcr+num(gridrec.credit_amt$)
				tunits=tunits+num(gridrec.units$)
			endif
		next reccnt
		tbal=tdb-tcr

		debitCtrl!=callpoint!.getDevObject("debitCtrl")
		debitCtrl!.setValue(tdb)
		creditCtrl!=callpoint!.getDevObject("creditCtrl")
		creditCtrl!.setValue(tcr)
		totalCtrl!=callpoint!.getDevObject("totalCtrl")
		totalCtrl!.setValue(tbal)
		unitsCtrl!=callpoint!.getDevObject("unitsCtrl")
		unitsCtrl!.setValue(tunits)
	endif

	return

rem ==========================================================================
comment_entry:
rem --- pop the new memo_1024 editor instead entering the post_memo cell
rem --- the editor can be popped on demand for any line using the Comments button (alt-C)
rem ==========================================================================

	disp_text$=callpoint!.getColumnData("GLX_CLSDYRADJDET.MEMO_1024")
	sv_disp_text$=disp_text$

	editable$="YES"
	force_loc$="NO"
	baseWin!=null()
	startx=0
	starty=0
	shrinkwrap$="NO"
	html$="NO"
	dialog_result$=""

	call stbl("+DIR_SYP")+ "bax_display_text.bbj",
:		"Comments/Message Line",
:		disp_text$, 
:		table_chans$[all], 
:		editable$, 
:		force_loc$, 
:		baseWin!, 
:		startx, 
:		starty, 
:		shrinkwrap$, 
:		html$, 
:		dialog_result$

	if disp_text$<>sv_disp_text$
		post_memo$=disp_text$(1,pos($0A$=disp_text$+$0A$)-1)
		callpoint!.setColumnData("GLX_CLSDYRADJDET.MEMO_1024",disp_text$,1)
		callpoint!.setColumnData("GLX_CLSDYRADJDET.POST_MEMO",post_memo$,1)
		callpoint!.setStatus("MODIFIED")
	endif

	callpoint!.setStatus("ACTIVATE")

	return

rem ==========================================================================
#include [+ADDON_LIB]std_missing_params.aon
#include [+ADDON_LIB]std_functions.aon
rem ==========================================================================



