[[GLU_CREATEBUDGET.AMT_OR_UNITS.AVAL]]
rem --- Verify the budget revision (BUDGET_CODE+AMT_OR_UNITS) exists
	amt_or_units$=callpoint!.getUserInput()
	budgetCode$=callpoint!.getColumnData("GLU_CREATEBUDGET.BUDGET_CODE")
	glmBudgetMaster_dev=fnget_dev("GLM_BUDGETMASTER")
	dim glmBudgetMaster$:fnget_tpl$("GLM_BUDGETMASTER")
	readrecord(glmBudgetMaster_dev,key=firm_id$+budgetCode$+amt_or_units$,dom=*next)glmBudgetMaster$
	if cvs(glmBudgetMaster.budget_code$+glmBudgetMaster.amt_or_units$,2)="" then
		rem --- budget revision
		msg_id$="GL_BAD_BUDGET_REV"
		dim msg_tokens$[2]
		msg_tokens$[1]=budgetCode$
		msg_tokens$[2]=amt_or_units$
		gosub disp_message

		callpoint!.setStatus("ABORT")
		break
	endif

rem --- Load selected GLM_BUDGEMASTER data into the form
	budget_code$=callpoint!.getColumnData("GLU_CREATEBUDGET.BUDGET_CODE")
	gosub loadFormData

[[GLU_CREATEBUDGET.BFMC]]
rem --- Initialize displayColumns! object
	use ::glo_DisplayColumns.aon::DisplayColumns
	displayColumns!=new DisplayColumns(firm_id$)

rem --- Initialize revision_src ListButton
	ldat_list$=displayColumns!.getStringButtonList()
	callpoint!.setTableColumnAttribute("GLU_CREATEBUDGET.REVISION_SRC","LDAT",ldat_list$)

[[GLU_CREATEBUDGET.BSHO]]
rem --- Open/Lock files
	num_files=2
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="GLS_PARAMS",open_opts$[1]="OTA"
	open_tables$[2]="GLM_BUDGETMASTER",open_opts$[2]="OTA"

	gosub open_tables

	gls01_dev=num(open_chans$[1])
	dim gls01a$:open_tpls$[1]

rem --- Verify GL is using budgets
	readrecord(gls01_dev,key=firm_id$+"GL00",err=std_missing_params)gls01a$
	if gls01a.budget_flag$<>"Y"
		msg_id$="GL_NO_BUDG"
		gosub disp_message
		rem --- remove process bar:
		bbjAPI!=bbjAPI()
		rdFuncSpace!=bbjAPI!.getGroupNamespace()
		rdFuncSpace!.setValue("+build_task","OFF")
		release
	endif

[[GLU_CREATEBUDGET.BUDGET_CODE.AVAL]]
rem --- Validate entered Budget Code
	budgetCode$=callpoint!.getUserInput()
	glmBudgetMaster_dev=fnget_dev("GLM_BUDGETMASTER")
	dim glmBudgetMaster$:fnget_tpl$("GLM_BUDGETMASTER")
	read(glmBudgetMaster_dev,key=firm_id$+budgetCode$,dom=*next)
	glmBudgetMaster_key$=key(glmBudgetMaster_dev,end=*next)
	if pos(firm_id$+budgetCode$=glmBudgetMaster_key$)<>1 then
		rem --- Invalid Budget Code
		msg_id$="GL_BAD_BUDGET_CODE"
		dim msg_tokens$[1]
		msg_tokens$[1]=budgetCode$
		gosub disp_message

		callpoint!.setStatus("ABORT")
		break
	endif

[[GLU_CREATEBUDGET.BUDGET_CODE.BINP]]
rem --- Clear form data
	budget_code$=""
	amt_or_units$=""
	gosub loadFormData

[[GLU_CREATEBUDGET.BUDGET_CODE.BINQ]]
rem --- Budget Code lookup
	call stbl("+DIR_SYP")+"bac_key_template.bbj","GLM_BUDGETMASTER","PRIMARY",key_tpl$,rd_table_chans$[all],status$
	dim glmBudgetMaster_key$:key_tpl$
	dim filter_defs$[1,2]
	filter_defs$[1,0]="GLM_BUDGETMASTER.FIRM_ID"
	filter_defs$[1,1]="='"+firm_id$+"'"
	filter_defs$[1,2]="LOCK"
	
	call stbl("+DIR_SYP")+"bax_query.bbj",gui_dev,form!,"GLM_BUDGETMASTER","BUILD",table_chans$[all],glmBudgetMaster_key$,filter_defs$[all]

	rem --- Load selected GLM_BUDGEMASTER data into the form
	if cvs(glmBudgetMaster_key$,2)<>"" then
		budget_code$=glmBudgetMaster_key.budget_code$
		amt_or_units$=glmBudgetMaster_key.amt_or_units$
		gosub loadFormData
	endif

	callpoint!.setStatus("ACTIVATE-ABORT")

[[GLU_CREATEBUDGET.<CUSTOM>]]
#include [+ADDON_LIB]std_missing_params.aon

rem ==========================================================================
loadFormData: rem --- Load selected GLM_BUDGEMASTER data into the form
               rem      IN: budget_code$
               rem      IN: amt_or_units$
rem ==========================================================================

	glmBudgetMaster_dev=fnget_dev("GLM_BUDGETMASTER")
	dim glmBudgetMaster$:fnget_tpl$("GLM_BUDGETMASTER")
	readrecord(glmBudgetMaster_dev,key=firm_id$+budget_code$+amt_or_units$,dom=*next)glmBudgetMaster$
	callpoint!.setColumnData("GLU_CREATEBUDGET.BUDGET_CODE",glmBudgetMaster.budget_code$,1)
	callpoint!.setColumnData("GLU_CREATEBUDGET.AMT_OR_UNITS",glmBudgetMaster.amt_or_units$,1)
	callpoint!.setColumnData("GLU_CREATEBUDGET.DESCRIPTION",glmBudgetMaster.description$,1)
	callpoint!.setColumnData("GLU_CREATEBUDGET.REV_TITLE",glmBudgetMaster.rev_title$,1)

	revision_src$=glmBudgetMaster.revision_src$
	for i=1 to len(revision_src$)
		if revision_src$(i,1)<>" " then temp$=temp$+revision_src$(i,1)
	next i
	revision_src$=temp$
	callpoint!.setColumnData("GLU_CREATEBUDGET.REVISION_SRC",revision_src$,1)

	callpoint!.setColumnData("GLU_CREATEBUDGET.AMT_OR_PCT",glmBudgetMaster.amt_or_pct$,1)
	callpoint!.setColumnData("GLU_CREATEBUDGET.OVERWRITE",glmBudgetMaster.overwrite$,1)
	callpoint!.setColumnData("GLU_CREATEBUDGET.ROUNDING",glmBudgetMaster.rounding$,1)
	callpoint!.setColumnData("GLU_CREATEBUDGET.CREATED_DATE",glmBudgetMaster.created_date$,1)
	callpoint!.setColumnData("GLU_CREATEBUDGET.LSTREV_DATE",glmBudgetMaster.lstrev_date$,1)
	callpoint!.setColumnData("GLU_CREATEBUDGET.GL_ACCOUNT_1",glmBudgetMaster.gl_account_01$,1)
	callpoint!.setColumnData("GLU_CREATEBUDGET.GL_ACCOUNT_2",glmBudgetMaster.gl_account_02$,1)
	callpoint!.setColumnData("GLU_CREATEBUDGET.GL_WILDCARD",glmBudgetMaster.gl_wildcard$,1)
	callpoint!.setColumnData("GLU_CREATEBUDGET.AMTPCT_VAL",glmBudgetMaster.amtpct_val$,1)
	callpoint!.setStatus("MODIFIED")

	return



