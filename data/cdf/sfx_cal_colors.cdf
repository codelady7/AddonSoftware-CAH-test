[[SFX_CAL_COLORS.ACUS]]
rem --- Handle events (ColorChooserCancelEvent, ColorChooserApproveEvent)

	event! = sysGui!.getLastEvent()
	if pos("BBjColorChooserCancelEvent"=event!.getEventName())

		callpoint!.setStatus("EXIT")
		callpoint!.setDevObject("colorChooser",null())
	else
		if pos("BBjColorChooserChangeEvent"=event!.getEventName())

			colorChooser!=callpoint!.getDevObject("colorChooser")
			opCodeNewColor!=callpoint!.getDevObject("opCodeNewColor")
			opCodesCtl!=callpoint!.getControl("SFX_CAL_COLORS.OPERATIONS")
			op_index=opCodesCtl!.getSelectedIndex()
	 		newColor!=colorChooser!.getColor()
			new_color$=fncolor_to_string$(newColor!)
			opCodeNewColor!.remove(op_index)
			opCodeNewColor!.insertItem(op_index,new_color$)
			gosub show_new_color
		else
			rem --- BBjColorChooserApproveEvent (user clicked OK)
			rem --- update sfw_cal_colors and the opCodeColor! vector for all ops

			sfw_cal_colors=fnget_dev("SFW_CAL_COLORS")
			dim sfw_cal_colors$:fnget_tpl$("SFW_CAL_COLORS")

			opCode!=callpoint!.getDevObject("opCode")			
			opCodeColor!=callpoint!.getDevObject("opCodeColor")
			opCodeNewColor!=callpoint!.getDevObject("opCodeNewColor")
			opCodeTextColor!=callpoint!.getDevObject("opCodeTextColor")
			colorChooser!=callpoint!.getDevObject("colorChooser")

			if opCode!.size()
				for op_code=0 to opCode!.size()-1
					op_code$=opCode!.get(op_code)
					new_color$=opCodeNewColor!.get(op_code)
					text_color$=fntext_char$(opCodeTextColor!.get(op_code))
					sfw_cal_colors.firm_id$=firm_id$
					sfw_cal_colors.user_id$=stbl("+USER_ID")
					sfw_cal_colors.op_code$=op_code$

					extract record(sfw_cal_colors,key=sfw_cal_colors.firm_id$+sfw_cal_colors.user_id$+sfw_cal_colors.op_code$,dom=*next)sfw_cal_colors$
					sfw_cal_colors.op_color$=new_color$
					sfw_cal_colors.text_color$=text_color$
					writerecord(sfw_cal_colors)sfw_cal_colors$
			
					opCodeColor!.remove(op_code)
					opCodeColor!.insertItem(op_code,new_color$)

					callpoint!.setDevObject("opCodeColor",opCodeColor!)
					callpoint!.setDevObject("opCodeTextColor",opCodeTextColor!)

					callpoint!.setStatus("EXIT")
					callpoint!.setDevObject("colorChooser",null())
				next op_code
			endif
		endif
	endif

[[SFX_CAL_COLORS.ARER]]
rem --- load operations into listbox

	opCodeDesc!=callpoint!.getDevObject("opCodeDesc")
	opCode!=callpoint!.getDevObject("opCode")
	opCodeColor!=callpoint!.getDevObject("opCodeColor")
	opCodeTextColor!=callpoint!.getDevObject("opCodeTextColor")
	opCodeNewColor!=callpoint!.getDevObject("opCodeNewColor")

	opCodesCtl!=callpoint!.getControl("SFX_CAL_COLORS.OPERATIONS")
	opCodesCtl!.setMultipleSelection(0)
	opCodesCtl!.removeAllItems()

	if opCodeDesc!.size()
		opCodesCtl!.insertItems(0,opCodeDesc!)
		ldat$=func.buildListButtonList(opCodeDesc!,opCode!)
		callpoint!.setTableColumnAttribute("SFX_CAL_COLORS.OPERATIONS","LDAT",ldat$)
	else
		opCodesCtl!.addItem(Translate!.getTranslation("AON_NONE"))
	endif
	op_index=0
	opCodesCtl!.selectIndex(op_index)
	callpoint!.setColumnData("SFX_CAL_COLORS.OPERATIONS",opCode!.get(op_index),1)

	gosub show_orig_color
	gosub show_new_color
	gosub show_text_color

	

[[SFX_CAL_COLORS.ASIZ]]
rem --- resize

	colorChooser!=callpoint!.getDevObject("colorChooser")
	if colorChooser!<>null() then colorChooser!.setSize(Form!.getWidth()-(colorChooser!.getX()*2),Form!.getHeight()-(colorChooser!.getY()+10))

[[SFX_CAL_COLORS.BEND]]
rem --- clear colorChooser from dev object so 2nd/subsequent launches don't try to use the old/destroyed object

	callpoint!.setDevObject("colorChooser",null())

[[SFX_CAL_COLORS.BSHO]]
rem --- init

    	use ::ado_util.src::util
	use ::ado_func.src::func

rem --- get current vectors of op codes, colors/text colors

	opCodeDesc!=callpoint!.getDevObject("opCodeDesc")
	opCode!=callpoint!.getDevObject("opCode")
	opCodeColor!=callpoint!.getDevObject("opCodeColor")
	opCodeTextColor!=callpoint!.getDevObject("opCodeTextColor")
	dim old_color$:callpoint!.getDevObject("color_tmpl")
	opCodeNewColor!=BBjAPI().makeVector()
    
rem --- add BBjColorChooser to the form

	nxt_ctlID=util.getNextControlID()
	colorChooser!=form!.addColorChooser(nxt_ctlID,10,95,700,300)
	colorChooser!.setPreviewPanelVisible(0)
	callpoint!.setDevObject("colorChooser",colorChooser!)
	util.resizeWindow(Form!, SysGui!)

rem --- set callback for when user chooses a color, or clicks OK/Cancel

	colorChooser!.setCallback(colorChooser!.ON_COLORCHOOSER_APPROVE,"custom_event")
	colorChooser!.setCallback(colorChooser!.ON_COLORCHOOSER_CANCEL,"custom_event")
	colorChooser!.setCallback(colorChooser!.ON_COLORCHOOSER_CHANGE,"custom_event")

rem --- init opCodeNewColor! to opCodeColor!
	for x=0 to opCodeColor!.size()-1
		opCodeNewColor!.add(opCodeColor!.get(x))
	next x
	callpoint!.setDevObject("opCodeNewColor",opCodeNewColor!)

[[SFX_CAL_COLORS.OPERATIONS.AVAL]]
rem --- set color for selected operation

	if cvs(callpoint!.getUserInput(),2)<>cvs(callpoint!.getColumnData("SFX_CAL_COLORS.OPERATIONS"),2)

		opCodeColor!=callpoint!.getDevObject("opCodeColor")
		opCodeTextColor!=callpoint!.getDevObject("opCodeTextColor")
		opCodeNewColor!=callpoint!.getDevObject("opCodeNewColor")
		colorChooser!=callpoint!.getDevObject("colorChooser")

		opCodesCtl!=callpoint!.getControl("SFX_CAL_COLORS.OPERATIONS")
		op_index=opCodesCtl!.getSelectedIndex()

		gosub show_orig_color
		gosub show_new_color
		gosub show_text_color

	endif

[[SFX_CAL_COLORS.TEXT_COLOR.AVAL]]
rem --- update text color vector if changed

	text_color$=callpoint!.getUserInput()
	if text_color$<>callpoint!.getColumnData("SFX_CAL_COLORS.TEXT_COLOR")
		opCodesCtl!=callpoint!.getControl("SFX_CAL_COLORS.OPERATIONS")
		op_index=opCodesCtl!.getSelectedIndex()
		opCodeTextColor!=callpoint!.getDevObject("opCodeTextColor")
		opCodeTextColor!.remove(op_index)
		new_text_color$=fntext_color$(text_color$)
		opCodeTextColor!.insertItem(op_index,new_text_color$)
	endif

[[SFX_CAL_COLORS.<CUSTOM>]]
show_orig_color: rem ========================================================
rem in: op_index (selected index of ops listbox), opCodeColor! (vector of orig color strings per op code)

	dispOrigColor!=callpoint!.getControl("<<DISPLAY>>.ORIG_COLOR")
	dim orig_color$:callpoint!.getDevObject("color_tmpl")
	orig_color$=opCodeColor!.get(op_index)
	origColor!=fnmake_color!(orig_color$)
	dispOrigColor!.setBackColor(origColor!)

	return

show_new_color: rem ========================================================
rem in: op_index (selected index of ops listbox), opCodeNewColor! (vector of new color strings per op code)

	colorChooser!=callpoint!.getDevObject("colorChooser")
	dispNewColor!=callpoint!.getControl("<<DISPLAY>>.NEW_COLOR")
	dim new_color$:callpoint!.getDevObject("color_tmpl")
	new_color$=opCodeNewColor!.get(op_index)
	newColor!=fnmake_color!(new_color$)
	dispNewColor!.setBackColor(newColor!)
	colorChooser!.setColor(newColor!)
	callpoint!.setDevObject("colorChooser",colorChooser!)

	return

show_text_color: rem ========================================================
rem in: op_index (selected index of ops listbox), opCodeTextColor! (vector of text colors [black/white] per op code)

	dim text_color$:callpoint!.getDevObject("color_tmpl")
	text_color$=opCodeTextColor!.get(op_index)
	text_color$=fntext_char$(text_color$);rem translate from rgb color string to B or W
	callpoint!.setColumnData("SFX_CAL_COLORS.TEXT_COLOR",text_color$,1)

	return

rem --- Functions ==============================================================

	def fntext_color$(q$)
		q1$=""
		q1$=iff(q$="B","rgba(0,0,0,1)","rgba(255,255,255,1)")
		return q1$
	fnend

	def fntext_char$(q$)
		q1$=""
		q1$=iff(q$="rgba(0,0,0,1)","B","W")
		return q1$
	fnend

	def fnmake_color!(q$)
		dim q1$:callpoint!.getDevObject("color_tmpl")
		q1$=q$
		q2!=SysGui!.makeColor(num(q1.r$),num(q1.g$),num(q1.b$),num(q1.a$))
		return q2!
	fnend

	def fncolor_to_string$(q!)
		dim q1$:callpoint!.getDevObject("color_tmpl")
		q1.desc$="rgba"
		q1.r$=str(q!.getRed())
		q1.g$=str(q!.getGreen())
		q1.b$=str(q!.getBlue())
		q1.a$=str(q!.getAlpha())
		return q1$
	fnend
		



