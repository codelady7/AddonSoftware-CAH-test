[[SFM_CAL_MAINT.ACUS]]
rem --- Handle events (Calendar ready, calendar select, calendar dates set)

	event! = sysGui!.getLastEvent()
	if event!.getEventName()="BBjCustomEvent"
		eventObj! = event!.getObject()
		if pos("CalendarReadyEvent"=str(eventObj!.getClass()))
			myCal!=callpoint!.getDevObject("myCal")
			myCal!.injectCss(" .fc-event div { font-size: 12px ;} ")
rem 			myCal!.injectCss(" .fc-event div { font-size: 12px ; font-weight: bold;} ");rem add bold

			rem Add entries to the calendar from the pom_calendar file
			gosub AddEntries

			curr_date$=stbl("+SYSTEM_DATE")
			curr_date$=curr_date$(1,4)+"-"+curr_date$(5,2)+"-"+curr_date$(7,2)
			myCal!.navigateDate(curr_date$)

			rem --- now turn flushEvents back on
			sysGui!.flushEvents()
			callpoint!.setStatus("FLUSHON")

			progWin!=callpoint!.getDevObject("progress_spinner")
			progWin!.destroy()

			callpoint!.setColumnEnabled("<<DISPLAY>>.TEMP_TAB_STOP",0);rem disable so tab/shift-tab won't cycle back and try to re-create widget

		else
			if pos("CalendarEntryClickEvent"=str(eventObj!.getClass()))
				mySelectEvent! = event!.getObject()
				myCalEntry! = mySelectEvent!.getCalendarEntry()

				sfm_opcalndr=fnget_dev("SFM_OPCALNDR")
				dim sfm_opcalndr$:fnget_tpl$("SFM_OPCALNDR")

				hr_mask$=callpoint!.getDevObject("hr_mask")
				op_key$=myCalEntry!.getId()
				op_key$=op_key$(1,len(op_key$)-2);rem strip off day
				op_desc$=myCalEntry!.getTitle()
				op_desc$=op_desc$(pos("("=op_desc$)+1)
				op_desc$=op_desc$(1,len(op_desc$)-1)
				op_date$=fndate$(fnYMD$(myCalEntry!.getStart()))
				readrecord(sfm_opcalndr,key=op_key$)sfm_opcalndr$
				op_hours$=str(nfield(sfm_opcalndr$,"HRS_PER_DAY_"+op_date$(4,2)):hr_mask$)

				callpoint!.setColumnData("SFM_CAL_MAINT.SEL_OP_DATE",op_date$,1)
				callpoint!.setColumnData("SFM_CAL_MAINT.SEL_OP_DESC",op_desc$,1)
				callpoint!.setColumnData("SFM_CAL_MAINT.SEL_HRS_PER_DAY",op_hours$,1)

				callpoint!.setDevObject("selected_key",sfm_opcalndr.firm_id$+sfm_opcalndr.op_code$+sfm_opcalndr.year$+sfm_opcalndr.month$)
				callpoint!.setDevObject("selected_day",op_date$(4,2))
				callpoint!.setDevObject("selectedStartDate","")
				callpoint!.setDevObject("selectedEndDate","")
				callpoint!.setDevObject("myCalEntry",myCalEntry!)

				callpoint!.setColumnEnabled("SFM_CAL_MAINT.SEL_HRS_PER_DAY",1)
				callpoint!.setFocus("SFM_CAL_MAINT.SEL_HRS_PER_DAY")
			else
				if pos("CalendarDatesSetEvent"=str(eventObj!.getClass()))
					myCal!=callpoint!.getDevObject("myCal")
					myDatesSetEvent! = event!.getObject()
					myCalView!=myDatesSetEvent!.getCalendarView()

					curr_mo$=callpoint!.getDevObject("curr_mo")
					curr_yr$=callpoint!.getDevObject("curr_yr")

					rem --- get start/end dates for the selected month/year and load in corresponding pom_calendar entries
					startDate$=fnYMD$(myCalView!.getCurrentStart())
					if pos(curr_yr$+curr_mo$=startDate$)<>1 or callpoint!.getDevObject("adjust_colors")="Y"
						curr_yr=num(startDate$(1,4))
						curr_mo=num(startDate$(5,2))
						gosub create_new_month
						callpoint!.setDevObject("curr_mo",startDate$(5,2))
						callpoint!.setDevObject("curr_yr",startDate$(1,4))
						gosub AddEntries
					endif
				else
					if pos("CalendarSelectEvent"=str(eventObj!.getClass()))
						rem --- selecting multiple days via click/drag, or clicking on a day with or without an entry (but not clicking the actual entry)
						calOps!=callpoint!.getControl("SFM_CAL_MAINT.CAL_OPS")
						opsSelected!=calOps!.getSelectedIndices()
						if opsSelected!.size()<>1 then break; rem --- only allow multiple day change for single op
						opCode!=callpoint!.getDevObject("opCode")
						op_code$=opCode!.get(opsSelected!.get(0))

						mySelectEvent! = event!.getObject()
						myCalView! = mySelectEvent!.getCalendarView()

						rem Determine the starting and ending dates for the selected range
						selectedStartDate$ = fnYMD$(mySelectEvent!.getStartString())
						selectedEndDate$ = fnYMD$(mySelectEvent!.getEndString())
						monthStart$ = fnYMD$(myCalView!.getCurrentStart())
						monthEnd$ = fnYMD$(myCalView!.getCurrentEnd())

						rem --- no action if the user selected dates outside of the currently displayed month
						if (selectedEndDate$ > monthEnd$) or (selectedStartDate$ < monthStart$) then break

						opCodeShortDesc!=callpoint!.getDevObject("opCodeShortDesc")
						op_desc$=opCodeShortDesc!.get(opsSelected!.get(0))

						callpoint!.setDevObject("selectedStartDate",selectedStartDate$)
						callpoint!.setDevObject("selectedEndDate",fnLastDay$(selectedEndDate$))
						callpoint!.setDevObject("selected_key",firm_id$+op_code$+selectedStartDate$(1,6))
						callpoint!.setDevObject("selected_day","")
						callpoint!.setDevObject("this_op_desc",op_desc$)

						if fnLastDay$(selectedEndDate$)>selectedStartDate$
							date_range$=fndate$(selectedStartDate$)+" - "+fndate$(fnLastDay$(selectedEndDate$)) 
						else
							date_range$=fndate$(selectedStartDate$)
						endif

						callpoint!.setColumnData("SFM_CAL_MAINT.SEL_OP_DATE",date_range$,1)
						callpoint!.setColumnData("SFM_CAL_MAINT.SEL_OP_DESC",op_desc$,1)
						callpoint!.setColumnData("SFM_CAL_MAINT.SEL_HRS_PER_DAY","0.00",1)

						callpoint!.setColumnEnabled("SFM_CAL_MAINT.SEL_HRS_PER_DAY",1)
						callpoint!.setFocus("SFM_CAL_MAINT.SEL_HRS_PER_DAY")

					endif
				endif
			endif
		endif
	else
		rem --- ListBox click event - Refresh calendar to show selected op code(s)
		myCal!=callpoint!.getDevObject("myCal")
		gosub AddEntries
	endif

[[SFM_CAL_MAINT.AOPT-CLRS]]
rem --- launch form to choose colors by op code for user

	call stbl("+DIR_SYP")+"bam_run_prog.bbj","SFX_CAL_COLORS",stbl("+USER_ID"),"","",table_chans$[all],"",dflt_data$[all]

	callpoint!.setDevObject("adjust_colors","Y")
	myCal!=callpoint!.getDevObject("myCal")
	myCal!.render();rem --- re-render the calendar to show the new color(s)

[[SFM_CAL_MAINT.AOPT-RFSH]]
rem --- Refresh calendar to show selected op code(s)
	myCal!=callpoint!.getDevObject("myCal")
	gosub AddEntries

[[SFM_CAL_MAINT.ARER]]
rem --- Find gaps in the calendar and populate the Calendar Gaps listbutton
rem --- Find and set the calendar start/end dates
rem --- Initially disable hours field

	sfm_opcalndr=fnget_dev("SFM_OPCALNDR")
	dim sfm_opcalndr$:fnget_tpl$("SFM_OPCALNDR")

	op_code$=callpoint!.getDevObject("first_opcode")

	gosub find_gaps
	gosub get_calendar_boundaries
	gosub load_ops_list

	callpoint!.setColumnEnabled("SFM_CAL_MAINT.SEL_HRS_PER_DAY",0)

[[SFM_CAL_MAINT.ASIZ]]
rem --- resize the calendar widget

	myCal!=callpoint!.getDevObject("myCal")
	if myCal!<>null() then myCal!.setSize(Form!.getWidth()-(myCal!.getX()*2),Form!.getHeight()-(myCal!.getY()+10))

[[SFM_CAL_MAINT.BSHO]]
rem --- BBjCalendarWidget and other USE Statements
	use ::BBjCalendarWidget/CalendarAPI.bbj::CalendarAPI
	use ::BBjCalendarWidget/BBjCalendarWidget.bbj::BBjCalendarWidget
	use ::BBjCalendarWidget/CalendarEntry.bbj::CalendarEntry
	use ::BBjCalendarWidget/CalendarView.bbj::CalendarView
	use ::BBjCalendarWidget/CalendarOptions.bbj::CalendarOptions
	use ::BBjCalendarWidget/CalendarEvents.bbj::CalendarSelectEvent
	use ::BBjCalendarWidget/CalendarEvents.bbj::CalendarEntryClickEvent
	use ::BBjCalendarWidget/CalendarEvents.bbj::CalendarDatesSetEvent

	use java.util.LinkedHashMap
	use com.google.gson.JsonObject
	use ::ado_util.src::util
	use ::ado_func.src::func

rem --- Open File(s)

	num_files=4
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]

	open_tables$[1]="SFM_OPCALNDR",open_opts$[1]="OTA"
	open_tables$[2]="ADM_MODULES",open_opts$[2]="OTA"
	open_tables$[3]="SFS_PARAMS",open_opts$[3]="OTA"
	open_tables$[4]="SFW_CAL_COLORS",open_opts$[4]="OTA"

	gosub open_tables

	sfm_opcalndr=num(open_chans$[1]);dim sfm_opcalndr$:open_tpls$[1]
	adm_modules=num(open_chans$[2]);dim adm_modules$:open_tpls$[2]
	sfs_params=num(open_chans$[3]);dim sfs_params$:open_tpls$[3]
	sfw_cal_colors=num(open_chans$[4]);dim sfw_cal_colors$:open_tpls$[4]

rem --- Open correct Op Code table

	read record (sfs_params,key=firm_id$+"SF00",dom=std_missing_params) sfs_params$
	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	if sfs_params.bm_interface$<>"Y"
		open_tables$[1]="SFC_OPRTNCOD"
	else
		open_tables$[1]="BMC_OPCODES"
	endif
	open_opts$[1]="OTA"
	
	gosub open_tables

	opcode_dev=num(open_chans$[1]);dim opcode$:open_tpls$[1]

rem --- Build vectors of Op Codes, Descriptions, Colors, Text Color

	opCodeDesc!=bbjAPI().makeVector()
	opCodeShortDesc!=bbjAPI().makeVector()
	opCodeColor!=bbjAPI().makeVector()
	opCode!=bbjAPI().makeVector()
	opCodeColor!=bbjAPI().makeVector()
	opCodeTextColor!=bbjAPI().makeVector()

	color_tpl$="desc:c(30*=40),r:c(3*=44),g:c(3*=44),b:c(3*=44),a:c(3*=41)"
	dim dflt_color$:color_tpl$
	dim text_black$:color_tpl$
	dim text_white$:color_tpl$
	dflt_color$="rgba(153, 153, 153, 255)";rem gray
	text_black$="rgba(0,0,0,1)";rem black
	text_white$="rgba(255,255,255,1)";rem white

	read (opcode_dev,key=firm_id$,dom=*next)
	while 1
		read record (opcode_dev,end=*break) opcode$
		if pos(firm_id$=opcode$)<>1 break
		opCodeDesc!.addItem(cvs(opcode.op_code$,2)+" - "+cvs(opcode.code_desc$,2))
		opCodeShortDesc!.addItem(cvs(opcode.op_code$,2)+" "+cvs(opcode.code_desc$,2));rem may have separate short desc field at some point
		opCode!.addItem(opcode.op_code$)
		if first_opcode$="" first_opcode$=opcode.op_code$

		redim sfw_cal_colors$
		read record(sfw_cal_colors,key=firm_id$+pad(stbl("+USER_ID"),16)+opcode.op_code$,dom=*next)sfw_cal_colors$
		if cvs(sfw_cal_colors.op_color$,2)=""
			opCodeColor!.add(dflt_color$)
		else
			dim op_color$:color_tpl$
			op_color$=sfw_cal_colors.op_color$
			opCodeColor!.add(op_color$)
		endif
		if cvs(sfw_cal_colors.text_color$,2)=""
			opCodeTextColor!.add(text_black$)
		else
			dim op_text_color$:color_tpl$
			op_text_color$=iff(sfw_cal_colors.text_color$="B",text_black$,text_white$)
			opCodeTextColor!.add(op_text_color$)
		endif
	wend

	rem --- if no op codes are defined, throw message and exit
	if opCode!.size()=0
		msg_id$="SF_NO_OP_CODES"
		gosub disp_message
		bbjAPI!=bbjAPI()
		gns!=bbjAPI!.getGroupNamespace()
		gns!.setValue("+build_task","OFF")
		release
	endif

	callpoint!.setDevObject("opCodeDesc",opCodeDesc!)
	callpoint!.setDevObject("opCodeShortDesc",opCodeShortDesc!)
	callpoint!.setDevObject("opCode",opCode!)	
	callpoint!.setDevObject("first_opcode",first_opcode$)
	callpoint!.setDevObject("opCodeColor",opCodeColor!)
	callpoint!.setDevObject("opCodeTextColor",opCodeTextColor!)
	callpoint!.setDevObject("this_op_desc","")
	callpoint!.setDevObject("adjust_colors","")

rem --- Misc init

	curr_mo=num(stbl("+SYSTEM_DATE")(5,2))
	curr_yr=num(stbl("+SYSTEM_DATE")(1,4))
	callpoint!.setDevObject("curr_mo",str(curr_mo:"00"))
	callpoint!.setDevObject("curr_yr",str(curr_yr:"0000"))
	callpoint!.setDevObject("day_str","312831303130313130313031")
	callpoint!.setDevObject("color_tmpl",color_tpl$)
	callpoint!.setDevObject("selected_key","")
	callpoint!.setDevObject("selected_day","")
	callpoint!.setDevObject("selectedStartDate","")
	callpoint!.setDevObject("selectedEndDate","")

rem --- get mask for hrs_per_day, and disable control until a calendar entry or selection is made

	call pgmdir$+"adc_getmask.aon","","SF","H","",hr_mask$,0,hr_mask
	callpoint!.setDevObject("hr_mask",hr_mask$)

rem --- If current month doesn't exist, create an empty current month

	gosub create_new_month

[[SFM_CAL_MAINT.CAL_GAPS.AVAL]]
rem --- get the listbutton control, getSelectedIndex, then getItemAt(index) to get the mm/dd/yyyy
rem --- format that date as yyyy-mm-dd, and use myCal!.navigate() to go to that date

	gap_start$=callpoint!.getUserInput()

	if len(gap_start$)=8 and gap_start$<>callpoint!.getColumnData("SFM_CAL_MAINT.CAL_GAPS")
		myCal!=callpoint!.getDevObject("myCal")
		myCal!.navigateDate(gap_start$(1,4)+"-"+gap_start$(5,2)+"-"+gap_start$(7),err=*next)
	endif

[[SFM_CAL_MAINT.SEL_HRS_PER_DAY.AVAL]]
rem --- update sfm_opcalndr record with new hours

	if num(callpoint!.getUserInput())<>num(callpoint!.getColumnData("SFM_CAL_MAINT.SEL_HRS_PER_DAY"))

		sfm_opcalndr=fnget_dev("SFM_OPCALNDR")
		dim sfm_opcalndr$:fnget_tpl$("SFM_OPCALNDR")

		sel_key$=callpoint!.getDevObject("selected_key")
		sel_day$=callpoint!.getDevObject("selected_day")
		hr_mask$=callpoint!.getDevObject("hr_mask")
		start_date$=callpoint!.getDevObject("selectedStartDate")
		end_date$=callpoint!.getDevObject("selectedEndDate")

		if start_date$<>"" and end_date$<>""
			gosub UpdateMultipleEntries
		endif

		if sel_day$<>""
			gosub UpdateSingleEntry
		endif
	endif

	callpoint!.setColumnData("SFM_CAL_MAINT.SEL_OP_DATE","",1)
	callpoint!.setColumnData("SFM_CAL_MAINT.SEL_OP_DESC","",1)
	callpoint!.setColumnData("SFM_CAL_MAINT.SEL_HRS_PER_DAY","",1)
	callpoint!.setColumnEnabled("SFM_CAL_MAINT.SEL_HRS_PER_DAY",0)



	

[[<<DISPLAY>>.TEMP_TAB_STOP.BINP]]
rem --- Create spinner/meter window until calendar is up
	bbjHome$ =  System.getProperty("basis.BBjHome")
	title$=form!.getTitle()
	progtext$=Translate!.getTranslation("AON_LOADING_CALENDAR","Loading calendar",1)+"..."
	progWin! = SysGui!.addWindow(SysGUI!.getAvailableContext(),Form!.getX()+(Form!.getWidth()/2)-150,Form!.getY()+(Form!.getHeight()/2)-50,300,100,title$,$000C0000$)
	nxt_ctlID=util.getNextControlID()
	progWin!.addImageCtrl(nxt_ctlID,15,15,33,33,bbjHome$+"/utils/reporting/bbjasper/images/CreatingReport.gif")
	nxt_ctlID=util.getNextControlID()
	sText!=progWin!.addStaticText(nxt_ctlID,75,20,150,50,progtext$)
	font! = sText!.getFont()
	fontBold! = SysGui!.makeFont(font!.getName(), font!.getSize()+2, SysGui!.BOLD)
	sText!.setFont(fontBold!)
	callpoint!.setDevObject("progress_spinner",progWin!)

rem --- Add the calendar widget to our window, specifying the window and a true value that turns on debug mode

	calGaps!=callpoint!.getControl("SFM_CAL_MAINT.CAL_GAPS")
	calEnds!=callpoint!.getControl("SFM_CAL_MAINT.CAL_ENDS")
	ctly=calGaps!.getY()
	ctlh=calEnds!.getHeight();rem use this for height - using the calGaps listbutton returns height of button + dropdown list
	cal_ctlID = util.getNextControlID()

	myOpts! = CalendarAPI.createCalendarOptions()
	myOpts!.setEnableSelectable(1)
 	rem --- unrem to enable debug --- if (info(3,6) = "1") then chromium_switches$ = stbl("!CHROMIUM_SWITCHES","--remote-debugging-port=9223")
	myCal! = CalendarAPI.createBBjCalendarWidget(Form!, cal_ctlID,20,ctly+ctlh+10,1200,500,myOpts!,null(),1)

	util.resizeWindow(Form!, SysGui!)

rem --- Register callback events for the calendar and ops listbox
	myCal!.setCallback(CalendarAPI.ON_CALENDAR_READY(), "custom_event")
	myCal!.setCallback(CalendarAPI.ON_CALENDAR_SELECT(), "custom_event")
	myCal!.setCallback(CalendarAPI.ON_CALENDAR_ENTRY_CLICK(), "custom_event")
	myCal!.setCallback(CalendarAPI.ON_CALENDAR_DATES_SET(),"custom_event")

	calOps!=callpoint!.getControl("SFM_CAL_MAINT.CAL_OPS")
	calOps!.setCallback(calOps!.ON_LIST_CLICK,"custom_event")

	callpoint!.setDevObject("myCal",myCal!)

	rem --- turn flushEvents off until calendar is ready (otherwise the on_calendar_ready event gets lost)
	callpoint!.setStatus("FLUSHOFF")

[[SFM_CAL_MAINT.<CUSTOM>]]
AddEntries: rem ============================================================

rem --- Add entries to the calendar from the sfm_opcalndr file
rem --- in: myCal! calendar object

	sfm_opcalndr=fnget_dev("SFM_OPCALNDR")
	dim sfm_opcalndr$:fnget_tpl$("SFM_OPCALNDR")

	myCalendarEntries!=BBjAPI().makeVector()
	myCalendarEntries!=myCal!.getEntries()
	if myCalendarEntries!<>null() and myCalendarEntries!.size()
		myCal!.removeEntries(myCalendarEntries!)
		myCal!.render()
	endif

	myCalendarEntries! = BBjAPI().makeVector()
	curr_yr$=callpoint!.getDevObject("curr_yr")
	curr_mo$=callpoint!.getDevObject("curr_mo")
	opCode!=callpoint!.getDevObject("opCode")
	opCodeShortDesc!=callpoint!.getDevObject("opCodeShortDesc")
	opCodeColor!=callpoint!.getDevObject("opCodeColor")
	opCodeTextColor!=callpoint!.getDevObject("opCodeTextColor")
	hr_mask$=callpoint!.getDevObject("hr_mask")
	calOps!=callpoint!.getControl("SFM_CAL_MAINT.CAL_OPS")
	opsSelected!=calOps!.getSelectedIndices()

	rem --- Read through sfm_opcalndr for current op, yr/mo and make a vector of properties for selected month

	if opsSelected!.size()
		for sel_op=0 to opsSelected!.size()-1
			op_code$=opCode!.get(opsSelected!.get(sel_op))
			op_code_short_desc$=opCodeShortDesc!.get(opsSelected!.get(sel_op))
			op_code_color$=opCodeColor!.get(opsSelected!.get(sel_op))
			op_code_text_color$=opCodeTextColor!.get(opsSelected!.get(sel_op))
			redim sfm_opcalndr$
			sfm_opcalndr.op_code$=op_code$
			found=0
			read record(sfm_opcalndr,key=firm_id$+sfm_opcalndr.op_code$+curr_yr$+curr_mo$,dom=*next)sfm_opcalndr$; found=1
			if !found
				curr_yr=num(curr_yr$)
				curr_mo=num(curr_mo$)
				gosub create_new_month
			endif
			for curr_day=1 to sfm_opcalndr.days_in_mth
				start$=sfm_opcalndr.year$+"-"+sfm_opcalndr.month$+"-"+str(curr_day:"00")
				end$=start$
				day_hrs=nfield(sfm_opcalndr$,"HRS_PER_DAY_"+str(curr_day:"00"))
				if day_hrs=-1
					useText$=""
				else
					useText$=op_code_short_desc$+": "+str(day_hrs:hr_mask$)+Translate!.getTranslation("AON__HRS")
				endif
				if useText$<>""
					myCalEntry! = CalendarAPI.createCalendarEntry(useText$, start$, end$)
					myCalEntry!.setId(firm_id$+op_code$+start$(1,4)+start$(6,2)+start$(9,2))
					myCalEntry!.setAllDay(1)
					myCalEntry!.setBackgroundColor(op_code_color$)
					myCalEntry!.setTextColor(op_code_text_color$)
					myCalendarEntries!.addItem(myCalEntry!)
				endif	
			next curr_day
		next sel_op
		myCal!.addEntries(myCalendarEntries!)
		myCal!.render()
		callpoint!.setDevObject("myCal",myCal!)
		callpoint!.setDevObject("adjust_colors","")
	endif

	return

find_gaps: rem =======================================================
rem --- in: channel and templated record for SFM_OPCALNDR

rem --- find gaps (unsched days) between begin/end dates
rem --- this logic is complicated... in v6/7 all day statuses were in a single string
rem --- w/ current version of table, all are separate templated fields.  So we look at each day, mark start of
rem --- gap when we find a space (also set stop=start at that point), then set end of gap 
rem --- each space day thereafter until we hit non-space again.  When we find new start of
rem --- gap, previous start/stop pair are added to gapVect!.  It should process entire
rem --- month gaps correctly as well.
rem --- start_of_gap=1 means we're at the start of a new gap, 0 means we've captured
rem --- the start of gap date, and need set stop dates until we hit a non-space day.

	first_rec=1
	start_of_gap=1
	GapVect!=bbjAPI().makeVector()
	GapStartsVect!=bbjAPI().makeVector()
	gap_start$=""
	gap_stop$=""
	last_key$=""
	dim sfm_opcalndr$:fattr(sfm_opcalndr$)

	read(sfm_opcalndr,key=firm_id$+op_code$,dom=*next)

	while 1

		readrecord(sfm_opcalndr,end=*break)sfm_opcalndr$
		if pos(firm_id$+op_code$=sfm_opcalndr$)<>1 then break
		if last_key$="" then last_key$=sfm_opcalndr.year$+sfm_opcalndr.month$

		for curr_day=1 to sfm_opcalndr.days_in_mth
			day_hrs=nfield(sfm_opcalndr$,"HRS_PER_DAY_"+str(curr_day:"00"))
			if day_hrs=-1
				if start_of_gap=1
					if num(sfm_opcalndr.year$+sfm_opcalndr.month$)-num(last_key$)>1
						rem - if at start of new gap, but this yr/mo not contig w/ previous, adjust begin dt for the gap
						rem - then put prev start/stop into gapVect!, and begin tracking gap
						wk_date$=last_key$+day_str$(num(last_key$(5,2))*2-1,2)
						call stbl("+DIR_PGM")+"adc_daydates.aon",wk_date$,nxt_date$,1
						gosub load_GapVect
						gap_start$=nxt_date$
						gap_stop$=gap_start$
						last_key$=sfm_opcalndr.year$+sfm_opcalndr.month$
						start_of_gap=0
					else
						rem - if at start of new gap and this rec is contiguous w/ previous,
						rem - put prev start/stop into gapVect! and begin tracking gap
						gosub load_GapVect
						gap_start$=sfm_opcalndr.year$+sfm_opcalndr.month$+str(curr_day:"00")
						gap_stop$=gap_start$
						start_of_gap=0
					endif
				else
					rem - start_of_gap<>1, meaning we're in the middle of tracking a gap
					rem - just update the gap_stop$
					gap_stop$=sfm_opcalndr.year$+sfm_opcalndr.month$+str(curr_day:"00")
				endif
			else
				rem --- init gapvect! once we find first non-space day in calendar
				if first_rec=1
					gapVect!.clear()
					start_of_gap=1
					first_rec=0
				else
					rem --- if first day of new month is non-space, and gap isn't closed, get end date for gap
					if curr_day=1 and start_of_gap=0
						wk_date$=sfm_opcalndr.year$+sfm_opcalndr.month$+str(curr_day:"00")
						call stbl("+DIR_PGM")+"adc_daydates.aon",wk_date$,prev_date$,-1
						last_key$=prev_date$(1,6)
						gap_stop$=prev_date$
						start_of_gap=1
					endif
				endif
				rem --- just a regular non-space day
				start_of_gap=1
			endif
		next curr_day

		last_key$=sfm_opcalndr.year$+sfm_opcalndr.month$

	wend

	gosub load_GapVect

	if GapVect!.size()
		ldat$=func.buildListButtonList(GapVect!,GapStartsVect!)
		callpoint!.setTableColumnAttribute("SFM_CAL_MAINT.CAL_GAPS","LDAT",ldat$)
		calGapsCtl!=callpoint!.getControl("SFM_CAL_MAINT.CAL_GAPS")
		calGapsCtl!.removeAllItems()
		calGapsCtl!.insertItems(0,GapVect!)
		calGapsCtl!.selectIndex(0)
	endif

	return

load_GapVect:
	if cvs(gap_start$,3)<>"" and cvs(gap_stop$,3)<>""
		GapVect!.addItem(fndate$(gap_start$)+" - "+fndate$(gap_stop$))
		GapStartsVect!.addItem(gap_start$)
	endif
	gap_start$=""
	gap_stop$=""

	return

get_calendar_boundaries: rem =======================================================
rem --- in: channel and templated record for SFM_OPCALNDR
rem --- show mm/yyyy when calendar starts and ends

	read(sfm_opcalndr,key=firm_id$+op_code$,dom=*next)

	k$=key(sfm_opcalndr,err=*next)
	readrecord(sfm_opcalndr,key=k$)sfm_opcalndr$
	if pos(firm_id$+op_code$=sfm_opcalndr$)<>1
		first_date$=Translate!.getTranslation("AON_NONE")
	else
		first_date$=sfm_opcalndr.year$+sfm_opcalndr.month$
	endif

	redim sfm_opcalndr$

	read(sfm_opcalndr,key=firm_id$+op_code$+$ff$,dom=*next)
	k$=keyp(sfm_opcalndr,err=*next)
	readrecord(sfm_opcalndr,key=k$)sfm_opcalndr$
	if pos(firm_id$+op_code$=sfm_opcalndr$)<>1
		last_date$=Translate!.getTranslation("AON_NONE")
	else
		last_date$=sfm_opcalndr.year$+sfm_opcalndr.month$
	endif

	callpoint!.setColumnData("SFM_CAL_MAINT.CAL_BEGINS",first_date$,1)
	callpoint!.setColumnData("SFM_CAL_MAINT.CAL_ENDS",last_date$,1)

	return

load_ops_list: rem ==========================================================

	opCodesCtl!=callpoint!.getControl("SFM_CAL_MAINT.CAL_OPS")
	opCodesCtl!.setMultipleSelection(1)

	opCodeDesc!=callpoint!.getDevObject("opCodeDesc")
	opCode!=callpoint!.getDevObject("opCode")
	
	opCodesCtl!.removeAllItems()

	if opCodeDesc!.size()
		opCodesCtl!.insertItems(0,opCodeDesc!)
		ldat$=func.buildListButtonList(opCodeDesc!,opCode!)
		callpoint!.setTableColumnAttribute("SFM_CAL_MAINT.CAL_OPS","LDAT",ldat$)
	else
		opCodesCtl!.addItem(Translate!.getTranslation("AON_NONE"))
	endif
	opCodesCtl!.selectIndex(0)

	return

UpdateSingleEntry: rem ========================================================
rem in: sel_key$, sel_day$, hr_mask$, and template/channel for sfm_opcalndr

	extractrecord(sfm_opcalndr,key=sel_key$,err=*return)sfm_opcalndr$
	field sfm_opcalndr$,"HRS_PER_DAY_"+sel_day$=callpoint!.getUserInput()
	write record(sfm_opcalndr)sfm_opcalndr$

	myCal!=callpoint!.getDevObject("myCal")
	myCalEntry!=callpoint!.getDevObject("myCalEntry")

	title$=myCalEntry!.getTitle()
	title$=title$(1,pos(": "=title$)+1)+str(num(callpoint!.getUserInput()):hr_mask$)+Translate!.getTranslation("AON__HRS")
	myCalEntry!.setTitle(title$)

	myCal!.removeEntry(myCalEntry!)
	myCal!.addEntry(myCalEntry!)

	return

UpdateMultipleEntries: rem ========================================================
rem in: start_date$, end_date$, sel_key$, hr_mask$, and template/channel for sfm_opcalndr

	myCal!=callpoint!.getDevObject("myCal")
	this_op_desc$=callpoint!.getDevObject("this_op_desc")
	opCodeColor!=callpoint!.getDevObject("opCodeColor")
	opCodeTextColor!=callpoint!.getDevObject("opCodeTextColor")
	title$=this_op_desc$+": "+str(num(callpoint!.getUserInput()):hr_mask$)+Translate!.getTranslation("AON__HRS")

	redim sfm_opcalndr$
	sfm_opcalndr.firm_id$=firm_id$
	sfm_opcalndr.op_code$=sel_key$(len(firm_id$)+1,len(sfm_opcalndr.op_code$))
	sfm_opcalndr.year$=sel_key$(len(firm_id$)+len(sfm_opcalndr.op_code$)+1,len(sfm_opcalndr.year$))
	sfm_opcalndr.month$=sel_key$(len(firm_id$)+len(sfm_opcalndr.op_code$)+len(sfm_opcalndr.year$)+1,len(sfm_opcalndr.month$))

	extractrecord(sfm_opcalndr,key=sel_key$,err=*next)sfm_opcalndr$

	for entry_dt=num(start_date$(7,2)) to num(end_date$(7,2))
		this_day$=start_date$(1,6)+str(entry_dt:"00")
		myCal!.removeEntryById(sel_key$+str(entry_dt:"00"),err=*next)
		myCalEntry! = CalendarAPI.createCalendarEntry(title$, this_day$,this_day$)
		myCalEntry!.setId(firm_id$+sfm_opcalndr.op_code$+this_day$)
		myCalEntry!.setAllDay(1)
		myCalEntry!.setBackgroundColor(opCodeColor!.get(num(sfm_opcalndr.op_code$)-1))
		myCalEntry!.setTextColor(opCodeTextColor!.get(num(sfm_opcalndr.op_code$)-1))
		myCal!.addEntry(myCalEntry!)
		field sfm_opcalndr$,"HRS_PER_DAY_"+str(entry_dt:"00")=callpoint!.getUserInput()
	next entry_dt

	write record(sfm_opcalndr)sfm_opcalndr$
	callpoint!.setDevObject("myCal",myCal!)

	return

create_new_month: rem =======================================================
rem in: curr_yr, curr_mo

	day_str$=callpoint!.getDevObject("day_str")
	opCode!=callpoint!.getDevObject("opCode")
	sfm_opcalndr=fnget_dev("SFM_OPCALNDR")
	dim sfm_opcalndr$:fnget_tpl$("SFM_OPCALNDR")

	for opcd=0 to opCode!.size()-1
		op_code$=opCode!.get(opcd)	
		found=0

		read record(sfm_opcalndr,key=firm_id$+op_code$+str(curr_yr:"0000")+str(curr_mo:"00"),dom=*next)sfm_opcalndr$; found=1
		
		if !found
			sfm_opcalndr.firm_id$=firm_id$
			sfm_opcalndr.op_code$=op_code$
			sfm_opcalndr.year$=str(curr_yr:"0000")
			sfm_opcalndr.month$=str(curr_mo:"00")
			sfm_opcalndr.days_in_mth=num(day_str$(curr_mo*2-1,2))
			if mod(curr_yr,4)=0 and curr_mo=2 then sfm_opcalndr.days_in_mth=29
			for wk=1 to 31
				field sfm_opcalndr$,"HRS_PER_DAY_"+str(wk:"00")=-1
			next wk
			writerecord(sfm_opcalndr)sfm_opcalndr$
		endif
	next opcd

	return

rem --- Functions ==============================================================


	def fndate$(q$)
		q1$=""
		q1$=date(jul(num(q$(1,4)),num(q$(5,2)),num(q$(7,2)),err=*next):"%Mz/%Dz/%Yd",err=*next)
		if q1$="" q1$=q$
		return q1$
	fnend

	def fnYMD$(x$)
		x1$=""
		x1$=x$(1,pos("T"=x$)-1)
		if len(x1$)=10
			x1$=x1$(1,4)+x1$(6,2)+x1$(9,2)
		else
			x1$=""
		endif
		return x1$
	fnend
    
	def fnLastDay$(x$)
		x2$=""
		if len(x$)=8
			x1=jul(num(x$(1,4)),num(x$(5,2)),num(x$(7,2)))
			x2$=date(x1-1:"%Y%Mz%Dz")
		endif
		return x2$
	fnend

#include std_missing_params.src



