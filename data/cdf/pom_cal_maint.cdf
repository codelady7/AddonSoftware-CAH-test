[[POM_CAL_MAINT.ACUS]]
rem --- Handle events (Calendar ready, calendar select, calendar dates set, popup menu selection)

	event! = sysGui!.getLastEvent()
	if event!.getEventName()="BBjCustomEvent"
		eventObj! = event!.getObject()
		if pos("CalendarReadyEvent"=str(eventObj!.getClass()))
			myCal!=callpoint!.getDevObject("myCal")
			rem --- inject some css to change the opacity on the font so the status (workday, closed, holiday) stands out more 
			myCal!.injectCss(".fc .fc-bg-event { opacity: 1 !important; } ")

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

		else
			if pos("CalendarSelectEvent"=str(eventObj!.getClass()))
				mySelectEvent! = event!.getObject()
				myCalView! = mySelectEvent!.getCalendarView()

				rem Determine the starting and ending dates for the selected range
				selectedStartDate! = fnYMD$(mySelectEvent!.getStartString())
				selectedEndDate! = fnYMD$(mySelectEvent!.getEndString())
				monthStart! = fnYMD$(myCalView!.getCurrentStart())
				monthEnd! = fnYMD$(myCalView!.getCurrentEnd())

				callpoint!.setDevObject("selectedStartDate",selectedStartDate!)
				callpoint!.setDevObject("selectedEndDate",selectedEndDate!)

				rem If the user selected dates outside of the current month, then don't bother showing the popup
				if (selectedEndDate! > monthEnd!) or (selectedStartDate! < monthStart!) then break

				xPos=mySelectEvent!.getCalendarX()
				yPos=mySelectEvent!.getCalendarY()
				myPopupMenu!=callpoint!.getDevObject("myPopupMenu")
				myPopupMenu!.show(Form!, xPos, yPos)
			else
				if pos("CalendarDatesSetEvent"=str(eventObj!.getClass()))
					myCal!=callpoint!.getDevObject("myCal")
					myDatesSetEvent! = event!.getObject()
					myCalView!=myDatesSetEvent!.getCalendarView()

					rem --- get start/end dates for the selected month/year and load in corresponding pom_calendar entries
					startDate$=fnYMD$(myCalView!.getCurrentStart())
					callpoint!.setDevObject("curr_mo",startDate$(5,2))
					callpoint!.setDevObject("curr_yr",startDate$(1,4))
					gosub AddEntries
				endif
			endif
		endif
	else
		rem --- popup event
		if event!.getEventName()="BBjPopupSelectEvent"
			dim event_str$:tmpl(gui_dev)
			event_str$=sysGui!.getLastEventString()
			pop_item=event_str.y
			switch pop_item
				case 201;rem Closed
					newEntryType$=callpoint!.getDevObject("closedText")
					newEntryColor$=callpoint!.getDevObject("closedColor")
					gosub UpdateCalendarEntries	
				break
				case 202;rem Holiday
					newEntryType$=callpoint!.getDevObject("holidayText")
					newEntryColor$=callpoint!.getDevObject("holidayColor")
					gosub UpdateCalendarEntries
				break
				case 203;rem Workday
					newEntryType$=callpoint!.getDevObject("workdayText")
					newEntryColor$=callpoint!.getDevObject("workdayColor")
					gosub UpdateCalendarEntries
				break
			swend
		endif
	endif

[[POM_CAL_MAINT.AOPT-CCLR]]
rem --- call Barista's color chooser (which uses BBjColorChooser)
	gosub ChooseColors

[[POM_CAL_MAINT.AOPT-HCLR]]
rem --- call Barista's color chooser (which uses BBjColorChooser)
	gosub ChooseColors

[[POM_CAL_MAINT.AOPT-WCLR]]
rem --- call Barista's color chooser (which uses BBjColorChooser)
	gosub ChooseColors

[[POM_CAL_MAINT.ARER]]
rem --- Find gaps in the calendar and populate the Calendar Gaps listbutton
rem --- Find and set the calendar start/end dates

	pom_calendar=fnget_dev("POM_CALENDAR")
	dim pom_calendar$:fnget_tpl$("POM_CALENDAR")

	gosub find_gaps
	gosub get_calendar_boundaries

[[POM_CAL_MAINT.ASIZ]]
rem --- resize the calendar widget

	myCal!=callpoint!.getDevObject("myCal")
	if myCal!<>null() then myCal!.setSize(Form!.getWidth()-(myCal!.getX()*2),Form!.getHeight()-(myCal!.getY()+10))

[[POM_CAL_MAINT.BSHO]]
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

	num_files=3
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]

	open_tables$[1]="POM_CALENDAR",open_opts$[1]="OTA"
	open_tables$[2]="ADM_MODULES",open_opts$[2]="OTA"
	open_tables$[3]="POW_CAL_COLORS",open_opts$[3]="OTA"

	gosub open_tables

	pom_calendar=num(open_chans$[1]);dim pom_calendar$:open_tpls$[1]
	adm_modules=num(open_chans$[2]);dim adm_modules$:open_tpls$[2]
	pow_cal_colors=num(open_chans$[3]);dim pow_cal_colors$:open_tpls$[3]

rem --- Misc init

	curr_mo=num(stbl("+SYSTEM_DATE")(5,2))
	curr_yr=num(stbl("+SYSTEM_DATE")(1,4))
	callpoint!.setDevObject("curr_mo",str(curr_mo:"00"))
	callpoint!.setDevObject("curr_yr",str(curr_yr:"0000"))
	callpoint!.setDevObject("color_tmpl","desc:c(30*=40),r:c(3*=44),g:c(3*=44),b:c(3*=44),a:c(3*=41)")

	callpoint!.setDevObject("closedText",Translate!.getTranslation("AON_CLOSED2"))
	callpoint!.setDevObject("workdayText",Translate!.getTranslation("AON_WORKDAY"))
	callpoint!.setDevObject("holidayText",Translate!.getTranslation("AON_HOLIDAY"))

	read record(pow_cal_colors,key=firm_id$+pad(stbl("+USER_ID"),16),dom=*next)pow_cal_colors$
		if cvs(pow_cal_colors.closed_color$,2)=""
			callpoint!.setDevObject("closedColor","rgba(153, 153, 153, 255)");rem "gray"
		else
			callpoint!.setDevObject("closedColor",pow_cal_colors.closed_color$)
		endif
		if cvs(pow_cal_colors.workday_color$,2)=""
			callpoint!.setDevObject("workdayColor","rgba(0,204,144,255)");rem "teal"
		else
			callpoint!.setDevObject("workdayColor",pow_cal_colors.workday_color$)
		endif
		if cvs(pow_cal_colors.holiday_color$,2)=""
			callpoint!.setDevObject("holidayColor","rgba(229,109,226,255)");rem "pink"
		else
			callpoint!.setDevObject("holidayColor",pow_cal_colors.holiday_color$)
		endif

rem --- If current month doesn't exist, create an empty current month
	day_str$="312831303130313130313031"
	while 1
		try_mo=curr_mo
		try_yr=curr_yr  
		read record(pom_calendar,key=firm_id$+str(try_yr:"0000")+str(try_mo:"00"),dom=*next)pom_calendar$;break
		pom_calendar.firm_id$=firm_id$
		pom_calendar.year$=str(curr_yr:"0000")
		pom_calendar.month$=str(curr_mo:"00")
		pom_calendar.days_in_mth=num(day_str$(curr_mo*2-1,2))
		if mod(curr_yr,4)=0 and curr_mo=2 then pom_calendar.days_in_mth=29
		writerecord(pom_calendar)pom_calendar$
		break
	wend

[[POM_CAL_MAINT.CAL_GAPS.AVAL]]
rem --- get the listbutton control, getSelectedIndex, then getItemAt(index) to get the mm/dd/yyyy
rem --- format that date as yyyy-mm-dd, and use myCal!.navigate() to go to that date

	gap_start$=callpoint!.getUserInput()

	if len(gap_start$)=8 and gap_start$<>callpoint!.getColumnData("POM_CAL_MAINT.CAL_GAPS")
		myCal!=callpoint!.getDevObject("myCal")
		myCal!.navigateDate(gap_start$(1,4)+"-"+gap_start$(5,2)+"-"+gap_start$(7),err=*next)
	endif
	

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

	calBegins!=callpoint!.getControl("POM_CAL_MAINT.CAL_BEGINS")
	ctly=calBegins!.getY()
	ctlh=calBegins!.getHeight()
	cal_ctlID = util.getNextControlID()

	myOpts! = CalendarAPI.createCalendarOptions()
	myOpts!.setEnableSelectable(1)
 	rem --- unrem to enable debug --- if (info(3,6) = "1") then chromium_switches$ = stbl("!CHROMIUM_SWITCHES","--remote-debugging-port=9223")
	myCal! = CalendarAPI.createBBjCalendarWidget(Form!, cal_ctlID,20,ctly+ctlh+10,800,500,myOpts!,null(),1)
	util.resizeWindow(Form!, SysGui!)

rem --- Register callback events for the window and the calendar
	myCal!.setCallback(CalendarAPI.ON_CALENDAR_READY(), "custom_event")
	myCal!.setCallback(CalendarAPI.ON_CALENDAR_SELECT(), "custom_event")
	myCal!.setCallback(CalendarAPI.ON_CALENDAR_ENTRY_CLICK(), "custom_event")
	myCal!.setCallback(CalendarAPI.ON_CALENDAR_DATES_SET(),"custom_event")

	callpoint!.setDevObject("myCal",myCal!)

rem  --- Define a popup menu with options for selected calendar dates
	myPopupMenu! = SysGui!.addPopupMenu()
	myMenuItemClosed! = myPopupMenu!.addMenuItem(-201, callpoint!.getDevObject("closedText"))
	myMenuItemHoliday! = myPopupMenu!.addMenuItem(-202, callpoint!.getDevObject("holidayText"))
	myMenuItemWorkday! = myPopupMenu!.addMenuItem(-203, callpoint!.getDevObject("workdayText"))
	myMenuItemClosed!.setCallback(SysGui!.ON_POPUP_ITEM_SELECT, "custom_event")
	myMenuItemHoliday!.setCallback(SysGui!.ON_POPUP_ITEM_SELECT, "custom_event")
	myMenuItemWorkday!.setCallback(SysGui!.ON_POPUP_ITEM_SELECT, "custom_event")

	callpoint!.setDevObject("myPopupMenu",myPopupMenu!)

	rem --- turn flushEvents off until calendar is ready (otherwise the on_calendar_ready event gets lost)
	callpoint!.setStatus("FLUSHOFF")

[[POM_CAL_MAINT.<CUSTOM>]]
AddEntries: rem ============================================================
rem --- Add entries to the calendar from the pom_calendar file
rem --- in: myCal! calendar object

	pom_calendar=fnget_dev("POM_CALENDAR")
	dim pom_calendar$:fnget_tpl$("POM_CALENDAR")

	myCalendarEntries! = BBjAPI().makeVector()

	curr_yr$=callpoint!.getDevObject("curr_yr")
	curr_mo$=callpoint!.getDevObject("curr_mo")
   
	rem --- Read through pom_calendar for current yr/mo and make a vector of properties for all entries
	readrecord(pom_calendar,key=firm_id$+curr_yr$+curr_mo$,dom=*return)pom_calendar$
	if pom_calendar.firm_id$+pom_calendar.year$+pom_calendar.month$<>firm_id$+curr_yr$+curr_mo$ then break
	for curr_day=1 to pom_calendar.days_in_mth
		start$=pom_calendar.year$+"-"+pom_calendar.month$+"-"+str(curr_day:"00")
		end$=start$
		day_stat$=field(pom_calendar$,"DAY_STATUS_"+str(curr_day:"00"))
		switch pos(day_stat$="CHW");REM C=closed,H=holiday,W=workday
			case 1
				useText$=callpoint!.getDevObject("closedText")
				color$=callpoint!.getDevObject("closedColor")
			break
			case 2
				useText$=callpoint!.getDevObject("holidayText")
				color$=callpoint!.getDevObject("holidayColor")
			break
			case 3
				useText$=callpoint!.getDevObject("workdayText")
				color$=callpoint!.getDevObject("workdayColor")
			break
			case default
				color$=""
			break
		swend
            
		if color$<>""
			myEntry! = CalendarAPI.createCalendarEntry(useText$, start$, end$)
			myEntry!.setId(firm_id$+start$)
			myEntry!.setAllDay(1)
			myEntry!.setDisplay("background");rem --- this makes the event take up the entire square for a given day, rather than appearing as a distinct event within a day
			myEntry!.setBackgroundColor(color$)
			myCalendarEntries!.addItem(myEntry!)
		endif
	next curr_day

	rem --- Now add the entries from the vector to the calendar
	myCal!.addEntries(myCalendarEntries!)
	callpoint!.setDevObject("myCalendarEntries",myCalendarEntries!)

	return

find_gaps: rem =======================================================
rem --- in: channel and templated record for POM_CALENDAR

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

	read(pom_calendar,key=firm_id$,dom=*next)

	while 1

		readrecord(pom_calendar,end=*break)pom_calendar$
		if pom_calendar.firm_id$<>firm_id$ then break
		if last_key$="" then last_key$=pom_calendar.year$+pom_calendar.month$

		for curr_day=1 to pom_calendar.days_in_mth
			day_stat$=field(pom_calendar$,"DAY_STATUS_"+str(curr_day:"00"))
			if cvs(day_stat$,3)=""
				if start_of_gap=1
					if num(pom_calendar.year$+pom_calendar.month$)-num(last_key$)>1
						rem - if at start of new gap, but this yr/mo not contig w/ previous, adjust begin dt for the gap
						rem - then put prev start/stop into gapVect!, and begin tracking gap
						wk_date$=last_key$+day_str$(num(last_key$(5,2))*2-1,2)
						call stbl("+DIR_PGM")+"adc_daydates.aon",wk_date$,nxt_date$,1
						gosub load_GapVect
						gap_start$=nxt_date$
						gap_stop$=gap_start$
						last_key$=pom_calendar.year$+pom_calendar.month$
						start_of_gap=0
					else
						rem - if at start of new gap and this rec is contiguous w/ previous,
						rem - put prev start/stop into gapVect! and begin tracking gap
						gosub load_GapVect
						gap_start$=pom_calendar.year$+pom_calendar.month$+str(curr_day:"00")
						gap_stop$=gap_start$
						start_of_gap=0
					endif
				else
					rem - start_of_gap<>1, meaning we're in the middle of tracking a gap
					rem - just update the gap_stop$
					gap_stop$=pom_calendar.year$+pom_calendar.month$+str(curr_day:"00")
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
						wk_date$=pom_calendar.year$+pom_calendar.month$+str(curr_day:"00")
						call stbl("+DIR_PGM")+"adc_daydates.aon",wk_date$,prev_date$,-1
						last_key$=prev_date$(1,6)
						gap_stop$=prev_date$
						start_of_gap=1
					endif
					rem --- just a regular non-space day
					start_of_gap=1
				endif
			endif
		next curr_day

		last_key$=pom_calendar.year$+pom_calendar.month$

	wend
	gosub load_GapVect

	if GapVect!.size()
		ldat$=func.buildListButtonList(GapVect!,GapStartsVect!)
		callpoint!.setTableColumnAttribute("POM_CAL_MAINT.CAL_GAPS","LDAT",ldat$)
		calGapsCtl!=callpoint!.getControl("POM_CAL_MAINT.CAL_GAPS")
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
rem --- in: channel and templated record for POM_CALENDAR

rem --- show mm/yyyy when calendar starts and ends

	read(pom_calendar,key=firm_id$,dom=*next)

	k$=key(pom_calendar,err=*next)
	readrecord(pom_calendar,key=k$)pom_calendar$
	if pom_calendar.firm_id$<>firm_id$ 
		first_date$=Translate!.getTranslation("AON_NONE")
	else
		first_date$=pom_calendar.year$+pom_calendar.month$
	endif

	redim pom_calendar$

	read(pom_calendar,key=firm_id$+$ff$,dom=*next)
	k$=keyp(pom_calendar,err=*next)
	readrecord(pom_calendar,key=k$)pom_calendar$
	if pom_calendar.firm_id$<>firm_id$
		last_date$=Translate!.getTranslation("AON_NONE")
	else
		last_date$=pom_calendar.year$+pom_calendar.month$
	endif

	callpoint!.setColumnData("POM_CAL_MAINT.CAL_BEGINS",first_date$,1)
	callpoint!.setColumnData("POM_CAL_MAINT.CAL_ENDS",last_date$,1)

	return

UpdateCalendarEntries: rem ========================================================
rem --- in: newEntryType$, newEntryColor$
rem --- Update calendar and pom_calendar table
rem --- Note: to update an entry, we currently have to remove it then add it back to the calendar.

	myCalendarEntries!=callpoint!.getDevObject("myCalendarEntries")
	myCal!=callpoint!.getDevObject("myCal")
	selectedStartDate!=callpoint!.getDevObject("selectedStartDate")
	selectedEndDate!=fnLastDay$(callpoint!.getDevObject("selectedEndDate"))
	curr_mo$=callpoint!.getDevObject("curr_mo")
	curr_yr$=callpoint!.getDevObject("curr_yr")

	pom_calendar=fnget_dev("POM_CALENDAR")
	dim pom_calendar$:fnget_tpl$("POM_CALENDAR")

	pom_calendar.firm_id$=firm_id$
	pom_calendar.year$=curr_yr$
	pom_calendar.month$=curr_mo$
	day_str$="312831303130313130313031"
	pom_calendar.days_in_mth=num(day_str$(num(curr_mo$)*2-1,2))
	if mod(num(curr_yr$),4)=0 and num(curr_mo$)=2 then pom_calendar.days_in_mth=29

	extractrecord(pom_calendar,key=pom_calendar.firm_id$+pom_calendar.year$+pom_calendar.month$,dom=*next)pom_calendar$
	for selected_day = num(selectedStartDate!.substring(6)) to num(selectedEndDate!.substring(6))
		start$=curr_yr$+"-"+curr_mo$+"-"+str(selected_day:"00")
		end$=start$
		i=0
		while myCalendarEntries!.size()
			myEntry! = myCalendarEntries!.getItem(i)
			if num(fnYMD$(myEntry!.getStart())(7,2)) = selected_day
				myCal!.removeEntryById(myEntry!.getId())
				myCalendarEntries!.remove(i)
				break
			else
				i=i+1
				if i=myCalendarEntries!.size() then break
			endif
		wend

		myEntry! = CalendarAPI.createCalendarEntry(newEntryType$, start$, end$)
		myEntry!.setId(firm_id$+start$)
		myEntry!.setAllDay(1)
		myEntry!.setDisplay("background");rem --- this makes the event take up the entire square for a given day, rather than appearing as a distinct event within a day
		myEntry!.setBackgroundColor(newEntryColor$)
		myCalendarEntries!.addItem(myEntry!)
		myCal!.addEntry(myEntry!)
		field pom_calendar$,"DAY_STATUS_"+str(selected_day:"00")=newEntryType$(1,1)
	next selected_day

	rem --- now update pom_calendar table
	writerecord(pom_calendar)pom_calendar$

	callpoint!.setDevObject("myCal",myCal!)
	callpoint!.setDevObject("myCalendarEntries",myCalendarEntries!)

	return

ChooseColors: rem =============================================================
rem --- use color chooser to change colors for workday/closed/holiday
rem --- saved to pow_cal_colors

	pow_cal_colors=fnget_dev("POW_CAL_COLORS")
	dim pow_cal_colors$:fnget_tpl$("POW_CAL_COLORS")

	dim old_color$:callpoint!.getDevObject("color_tmpl")
	dim new_color$:fattr(old_color$)

	which_color$=str(callpoint!.getEvent())(6)
	switch which_color$
		case "CCLR"
			old_color$=callpoint!.getDevObject("closedColor")
		break
		case "HCLR"
			old_color$=callpoint!.getDevObject("holidayColor")
		break
		case "WCLR"
			old_color$=callpoint!.getDevObject("workdayColor")
		break
	swend
	
	if cvs(old_color$,3)<>""
		oldColor!=SysGui!.makeColor(num(old_color.r$),num(old_color.g$),num(old_color.b$),num(old_color.a$))
	endif

	call stbl("+DIR_SYP")+"bac_choose_color.bbj",gui_dev,sysGui!,form!,oldColor!,newColor!
	if newColor!<>null()
		new_color.desc$=old_color.desc$
		new_color.r$=str(newColor!.getRed())
		new_color.g$=str(newColor!.getGreen())
		new_color.b$=str(newColor!.getBlue())
		new_color.a$=str(newColor!.getAlpha())

		pow_cal_colors.firm_id$=firm_id$
		pow_cal_colors.user_id$=stbl("+USER_ID")
		readrecord(pow_cal_colors,key=pow_cal_colors.firm_id$+pow_cal_colors.user_id$,dom=*next)pow_cal_colors$
		switch which_color$
			case "CCLR"
				pow_cal_colors.closed_color$=new_color$
				callpoint!.setDevObject("closedColor",new_color$)
			break
			case "HCLR"
				pow_cal_colors.holiday_color$=new_color$
				callpoint!.setDevObject("holidayColor",new_color$)
			break
			case "WCLR"
				pow_cal_colors.workday_color$=new_color$
				callpoint!.setDevObject("workdayColor",new_color$)
			break
		swend
		writerecord(pow_cal_colors)pow_cal_colors$
		myCal!=callpoint!.getDevObject("myCal")
		myCal!.render();rem --- re-render the calendar to show the new color
	endif

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



