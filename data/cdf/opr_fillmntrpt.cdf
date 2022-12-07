[[OPR_FILLMNTRPT.ASVA]]
rem --- Get description of report selection
	rptSelection! = callpoint!.getControl("OPR_FILLMNTRPT.RPT_SELECTION")
	bbjRadioGroup! = rptSelection!.getRadioGroup()
	bbjRadioButton! = bbjRadioGroup!.getSelected()
	rptSelectionDesc$=bbjRadioButton!.getText()
	callpoint!.setDevObject("rptSelectionDesc",rptSelectionDesc$)



