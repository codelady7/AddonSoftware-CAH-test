[[GLS_CALENDAR.AABO]]
rem --- Undo date auto-adjustment
	oldEndDate$=callpoint!.getDevObject("priorYearEndDate")
	if oldEndDate$<>"" then
		glsCalendar_dev=callpoint!.getDevObject("gls_calendar_dev")
		dim glsCalendar$:fnget_tpl$("GLS_CALENDAR")
		prior_year$=str(num(callpoint!.getColumnData("GLS_CALENDAR.YEAR"))-1)
		readrecord(glsCalendar_dev,key=firm_id$+prior_year$)glsCalendar$
		field glsCalendar$,"PERIOD_END_"+glsCalendar.total_pers$=oldEndDate$(5,4)
		writerecord(glsCalendar_dev)glsCalendar$
	endif

	oldStartDate$=callpoint!.getDevObject("nextYearStartDate")
	if oldStartDate$<>"" then
		glsCalendar_dev=callpoint!.getDevObject("gls_calendar_dev")
		dim glsCalendar$:fnget_tpl$("GLS_CALENDAR")
		next_year$=str(num(callpoint!.getColumnData("GLS_CALENDAR.YEAR"))+1)
		readrecord(glsCalendar_dev,key=firm_id$+next_year$)glsCalendar$
		field glsCalendar$,"START_DATE"=oldStartDate$
		writerecord(glsCalendar_dev)glsCalendar$
	endif

[[GLS_CALENDAR.ADIS]]
rem --- Show current fiscal year and period
	gosub show_current_fiscal_yr

rem --- Disable and clear un-used periods
	total_pers=num(callpoint!.getColumnData("GLS_CALENDAR.TOTAL_PERS"))
	gosub disable_periods

rem --- Get the earliest and latest trns_date in GLT_TRANSDETAIL (glt-06) for each period in "this" fiscal year.
	year$=callpoint!.getColumnData("GLS_CALENDAR.YEAR")
	gosub get_transdetail_period_dates

rem --- Need to know if prior fiscal year end date, or next fiscal year start date were auto-adjusted
	callpoint!.setDevObject("priorYearEndDate","")
	callpoint!.setDevObject("nextYearStartDate","")

[[GLS_CALENDAR.AREC]]
rem --- Show current fiscal year and period
	gosub show_current_fiscal_yr

rem --- Disable and clear un-used periods
	total_pers=num(callpoint!.getColumnData("GLS_CALENDAR.TOTAL_PERS"))
	gosub disable_periods

rem --- On launch initialize form with calendar for current fiscal year
	if num(callpoint!.getDevObject("justLaunched")) then
		callpoint!.setDevObject("justLaunched","0")
		gls_calendar_dev=callpoint!.getDevObject("gls_calendar_dev")
		dim gls_calendar$:fnget_tpl$("GLS_CALENDAR")

		dim gls_params$:fnget_tpl$("GLS_PARAMS")
		gls_params$=callpoint!.getDevObject("gls_params")
		readrecord(gls_calendar_dev,key=firm_id$+gls_params.current_year$,dom=*next)gls_calendar$
		if cvs(gls_calendar.year$,2)<>"" then
			callpoint!.setStatus("RECORD:["+firm_id$+gls_calendar.year$+"]")
		else
			rem --- Default to a calendar year for the very first calendar entered, which is for the current fiscal year.
			callpoint!.setColumnData("GLS_CALENDAR.YEAR",gls_params.current_year$)
			callpoint!.setColumnData("GLS_CALENDAR.START_DATE",gls_params.current_year$+"0101")
			callpoint!.setColumnData("GLS_CALENDAR.TOTAL_PERS","12")
			callpoint!.setColumnData("GLS_CALENDAR.PERIOD_END_01",gls_params.current_year$+"0131")
			Calendar! = new java.util.GregorianCalendar()
			if Calendar!.isLeapYear(num(gls_params.current_year$)) then
				callpoint!.setColumnData("GLS_CALENDAR.PERIOD_END_02",gls_params.current_year$+"0229")
			else
				callpoint!.setColumnData("GLS_CALENDAR.PERIOD_END_02",gls_params.current_year$+"0228")
			endif
			callpoint!.setColumnData("GLS_CALENDAR.PERIOD_END_03",gls_params.current_year$+"0331")
			callpoint!.setColumnData("GLS_CALENDAR.PERIOD_END_04",gls_params.current_year$+"0430")
			callpoint!.setColumnData("GLS_CALENDAR.PERIOD_END_05",gls_params.current_year$+"0531")
			callpoint!.setColumnData("GLS_CALENDAR.PERIOD_END_06",gls_params.current_year$+"0630")
			callpoint!.setColumnData("GLS_CALENDAR.PERIOD_END_07",gls_params.current_year$+"0731")
			callpoint!.setColumnData("GLS_CALENDAR.PERIOD_END_08",gls_params.current_year$+"0831")
			callpoint!.setColumnData("GLS_CALENDAR.PERIOD_END_09",gls_params.current_year$+"0930")
			callpoint!.setColumnData("GLS_CALENDAR.PERIOD_END_10",gls_params.current_year$+"1031")
			callpoint!.setColumnData("GLS_CALENDAR.PERIOD_END_11",gls_params.current_year$+"1130")
			callpoint!.setColumnData("GLS_CALENDAR.PERIOD_END_12",gls_params.current_year$+"1231")
			callpoint!.setColumnData("GLS_CALENDAR.PERIOD_NAME_01",Translate!.getTranslation("AON_JANUARY"))
			callpoint!.setColumnData("GLS_CALENDAR.PERIOD_NAME_02",Translate!.getTranslation("AON_FEBRUARY"))
			callpoint!.setColumnData("GLS_CALENDAR.PERIOD_NAME_03",Translate!.getTranslation("AON_MARCH"))
			callpoint!.setColumnData("GLS_CALENDAR.PERIOD_NAME_04",Translate!.getTranslation("AON_APRIL"))
			callpoint!.setColumnData("GLS_CALENDAR.PERIOD_NAME_05",Translate!.getTranslation("AON_MAY"))
			callpoint!.setColumnData("GLS_CALENDAR.PERIOD_NAME_06",Translate!.getTranslation("AON_JUNE"))
			callpoint!.setColumnData("GLS_CALENDAR.PERIOD_NAME_07",Translate!.getTranslation("AON_JULY"))
			callpoint!.setColumnData("GLS_CALENDAR.PERIOD_NAME_08",Translate!.getTranslation("AON_AUGUST"))
			callpoint!.setColumnData("GLS_CALENDAR.PERIOD_NAME_09",Translate!.getTranslation("AON_SEPTEMBER"))
			callpoint!.setColumnData("GLS_CALENDAR.PERIOD_NAME_10",Translate!.getTranslation("AON_OCTOBER"))
			callpoint!.setColumnData("GLS_CALENDAR.PERIOD_NAME_11",Translate!.getTranslation("AON_NOVEMBER"))
			callpoint!.setColumnData("GLS_CALENDAR.PERIOD_NAME_12",Translate!.getTranslation("AON_DECEMBER"))
			callpoint!.setColumnData("GLS_CALENDAR.ABBR_NAME_01","Jan")
			callpoint!.setColumnData("GLS_CALENDAR.ABBR_NAME_02","Feb")
			callpoint!.setColumnData("GLS_CALENDAR.ABBR_NAME_03","Mar")
			callpoint!.setColumnData("GLS_CALENDAR.ABBR_NAME_04","Apr")
			callpoint!.setColumnData("GLS_CALENDAR.ABBR_NAME_05","May")
			callpoint!.setColumnData("GLS_CALENDAR.ABBR_NAME_06","Jun")
			callpoint!.setColumnData("GLS_CALENDAR.ABBR_NAME_07","Jul")
			callpoint!.setColumnData("GLS_CALENDAR.ABBR_NAME_08","Aug")
			callpoint!.setColumnData("GLS_CALENDAR.ABBR_NAME_09","Sep")
			callpoint!.setColumnData("GLS_CALENDAR.ABBR_NAME_10","Oct")
			callpoint!.setColumnData("GLS_CALENDAR.ABBR_NAME_11","Nov")
			callpoint!.setColumnData("GLS_CALENDAR.ABBR_NAME_12","Dec")
			callpoint!.setColumnData("GLS_CALENDAR.LOCKED_FLAG_01","N")
			callpoint!.setColumnData("GLS_CALENDAR.LOCKED_FLAG_02","N")
			callpoint!.setColumnData("GLS_CALENDAR.LOCKED_FLAG_03","N")
			callpoint!.setColumnData("GLS_CALENDAR.LOCKED_FLAG_04","N")
			callpoint!.setColumnData("GLS_CALENDAR.LOCKED_FLAG_05","N")
			callpoint!.setColumnData("GLS_CALENDAR.LOCKED_FLAG_06","N")
			callpoint!.setColumnData("GLS_CALENDAR.LOCKED_FLAG_07","N")
			callpoint!.setColumnData("GLS_CALENDAR.LOCKED_FLAG_08","N")
			callpoint!.setColumnData("GLS_CALENDAR.LOCKED_FLAG_09","N")
			callpoint!.setColumnData("GLS_CALENDAR.LOCKED_FLAG_10","N")
			callpoint!.setColumnData("GLS_CALENDAR.LOCKED_FLAG_11","N")
			callpoint!.setColumnData("GLS_CALENDAR.LOCKED_FLAG_12","N")

			total_pers=12
			gosub disable_periods
			callpoint!.setStatus("REFRESH-MODIFIED")
		endif
	endif

rem --- Need to know if prior fiscal year end date, or next fiscal year start date were auto-adjusted
	callpoint!.setDevObject("priorYearEndDate","")
	callpoint!.setDevObject("nextYearStartDate","")

[[GLS_CALENDAR.AWRI]]
rem --- When fiscal calendar for the initial fiscal year is saved, create duplicate fiscal calendars for the prior and next fiscal years.
	year$=callpoint!.getDevObject("copy_calendar")
	if year$<>"" then
		dim gls_params$:fnget_tpl$("GLS_PARAMS")
		gls_params$=callpoint!.getDevObject("gls_params")
		gls_calendar_dev=callpoint!.getDevObject("gls_calendar_dev")
		dim gls_calendar$:fnget_tpl$("GLS_CALENDAR")
		readrecord(gls_calendar_dev,key=firm_id$+year$,dom=*endif)gls_calendar$

		rem --- Create prior fiscal year's calendar
		dim prior_cal$:fnget_tpl$("GLS_CALENDAR")
		prior_cal$=gls_calendar$
		prior_cal.year$=str(num(prior_cal.year$)-1)
		prior_cal.start_date$(1,4)=str(num(prior_cal.start_date$(1,4))-1)
		for per=1 to num(prior_cal.total_pers$)
			field prior_cal$,"LOCKED_FLAG_"+str(per:"00")="Y"
			field prior_cal$,"LOCKED_DATE_"+str(per:"00")=date(0:"%Yd%Mz%Dz")
			period_end$=field(prior_cal$,"PERIOD_END_"+str(per:"00"))
			period_end$(1,4)=str(num(period_end$(1,4))-1)
			field prior_cal$,"PERIOD_END_"+str(per:"00")=period_end$
			if (gls_params.adjust_february and period_end$(5)="0228") or period_end$(5)="0229" then
				rem --- Adjust last day of February for leap year
				Calendar! = new java.util.GregorianCalendar()
				if period_end$(5)="0229" and !Calendar!.isLeapYear(num(period_end$(1,4))) then field prior_cal$,"PERIOD_END_"+str(per:"00")=period_end$(1,4)+"0228"
				if period_end$(5)="0228" and Calendar!.isLeapYear(num(period_end$(1,4))) then field prior_cal$,"PERIOD_END_"+str(per:"00")=period_end$(1,4)+"0229"
			endif
		next per

		prior_cal$=field(prior_cal$)
		writerecord(gls_calendar_dev)prior_cal$

		rem --- Create next fiscal year's calendar only if GL parameter create_next_cal is checked/true
		dim gls_params$:fnget_tpl$("GLS_PARAMS")
		gls_params$=callpoint!.getDevObject("gls_params")
		if gls_params.create_next_cal then
			rem --- Next fiscal year
			dim next_cal$:fnget_tpl$("GLS_CALENDAR")
			next_cal$=gls_calendar$
			next_cal.year$=str(num(next_cal.year$)+1)
			next_cal.start_date$(1,4)=str(num(next_cal.start_date$(1,4))+1)
			for per=1 to num(next_cal.total_pers$)
				field next_cal$,"LOCKED_FLAG_"+str(per:"00")="N"
				field next_cal$,"LOCKED_DATE_"+str(per:"00")=""
				period_end$=field(next_cal$,"PERIOD_END_"+str(per:"00"))
				period_end$(1,4)=str(num(period_end$(1,4))+1)
				field next_cal$,"PERIOD_END_"+str(per:"00")=period_end$	
				if (gls_params.adjust_february and period_end$(5)="0228") or period_end$(5)="0229" then
					rem --- Adjust last day of February for leap year
					Calendar! = new java.util.GregorianCalendar()
					if period_end$(5)="0229" and !Calendar!.isLeapYear(num(period_end$(1,4))) then field next_cal$,"PERIOD_END_"+str(per:"00")=period_end$(1,4)+"0228"
					if period_end$(5)="0228" and Calendar!.isLeapYear(num(period_end$(1,4))) then field next_cal$,"PERIOD_END_"+str(per:"00")=period_end$(1,4)+"0229"
				endif
			next per

			next_cal$=field(next_cal$)
			writerecord(gls_calendar_dev)next_cal$
		endif

		rem --- Reset file pointer for saved record
		read(gls_calendar_dev,key=firm_id$+year$,dom=*next)
	endif

rem --- Remove glw_acctsummary records if the fiscal calendar was changed.
	if callpoint!.getDevObject("calendar_changed") then
		dim gls_params$:fnget_tpl$("GLS_PARAMS")
		gls_params$=callpoint!.getDevObject("gls_params")
		if callpoint!.getColumnData("GLS_CALENDAR.YEAR")=gls_params.current_year$ then
			rem --- Remove all glw_acctsummary records for the FIRM if the fiscal calendar (total_pers, start_date, or period_end_nn)
			rem --- for the CURRENT FISCAL YEAR changes.
			call stbl("+DIR_PGM")+"adc_clearpartial.aon","",fnget_dev("GLW_ACCTSUMMARY"),firm_id$,status
		else
			rem --- Remove all glw_acctsummary records for a YEAR if the fiscal calendar (total_pers, start_date, or period_end_nn)
			rem --- changes for THAT FISCAL YEAR.
			call stbl("+DIR_PGM")+"adc_clearpartial.aon","",fnget_dev("GLW_ACCTSUMMARY"),firm_id$+callpoint!.getColumnData("GLS_CALENDAR.YEAR"),status
		endif
		if status then
			callpoint!.setStatus("ABORT")
			break
		endif
	endif

[[GLS_CALENDAR.BDEL]]
rem --- Never allow deleting the calendar for the prior/current/next fiscal year.
	dim gls_params$:fnget_tpl$("GLS_PARAMS")
	gls_params$=callpoint!.getDevObject("gls_params")
	current_year=num(gls_params.current_year$)
	year=num(callpoint!.getColumnData("GLS_CALENDAR.YEAR"))
	if year=current_year-1 or year=current_year or year=current_year+1 then
		msg_id$="GL_NOT_DEL_PCN_CAL"
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- Can only delete fiscal calendars where there is no corresponding data in 
rem --- GLM_ACCTSUMMARY (glm-02) or GLM_ACCTBUDGET.
	cal_in_use=0
	year$=callpoint!.getColumnData("GLS_CALENDAR.YEAR")

	glm_acctsummary_dev=fnget_dev("GLM_ACCTSUMMARY")
	dim glm_acctsummary$:fnget_tpl$("GLM_ACCTSUMMARY")
	read(glm_acctsummary_dev,key=firm_id$+year$,knum="BY_YEAR_ACCT",dom=*next)
	readrecord(glm_acctsummary_dev,end=*next)glm_acctsummary$
	if glm_acctsummary.year$=year$ then cal_in_use=1

	if !cal_in_use then
		glm_acctbudget_dev=fnget_dev("GLM_ACCTBUDGET")
		dim glm_acctbudget$:fnget_tpl$("GLM_ACCTBUDGET")
		read(glm_acctbudget_dev,key=firm_id$+year$,knum="BY_YEAR_ACCT",dom=*next)
		readrecord(glm_acctbudget_dev,end=*next)glm_acctbudget$
		if glm_acctbudget.year$=year$ then cal_in_use=1
	endif

	if cal_in_use then
		msg_id$="GL_CANNOT_DEL_CAL"
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif

[[GLS_CALENDAR.BSHO]]
rem -- Get GL parameters
	num_files=7
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="GLS_PARAMS",open_opts$[1]="OTA"
	open_tables$[2]="GLT_TRANSDETAIL",open_opts$[2]="OTA"
	open_tables$[3]="GLM_ACCTSUMMARY",open_opts$[3]="OTA"
	open_tables$[4]="ADS_COMPINFO",open_opts$[4]="OTA"
	open_tables$[5]="GLW_ACCTSUMMARY",open_opts$[5]="OTA"
	open_tables$[6]="GLM_ACCTBUDGET",open_opts$[6]="OTA"
	open_tables$[7]="GLS_CALENDAR",open_opts$[7]="OTA[1]"
	gosub open_tables

	gls_params_dev=num(open_chans$[1])
	dim gls_params$:open_tpls$[1]

	find record(gls_params_dev,key=firm_id$+"GL00",err=std_missing_params)gls_params$
	callpoint!.setDevObject("gls_params",gls_params$)

rem --- Hold on to 2nd channel to GLS_CALENDAR
	callpoint!.setDevObject("gls_calendar_dev",num(open_chans$[7]))

rem --- Need to know later if form was just launched
	callpoint!.setDevObject("justLaunched","1")

rem --- Need to know if prior fiscal year end date, or next fiscal year start date were auto-adjusted
	callpoint!.setDevObject("priorYearEndDate","")
	callpoint!.setDevObject("nextYearStartDate","")

[[GLS_CALENDAR.BWRI]]
rem --- TOTAL_PERS must be >= last period in glt_transdetail (glt-06) for this fiscal year
	total_pers=num(callpoint!.getColumnData("GLS_CALENDAR.TOTAL_PERS"))
	gosub check_total_pers
	if abort then break

rem --- START_DATE must be <= first trns_date in glt_transdetail (glt-06) for this fiscal year
	start_date$=callpoint!.getColumnData("GLS_CALENDAR.START_DATE")
	gosub check_start_date
	if abort then break

rem --- Check PERIOD_END_nn date against GLT_TRANSDETAIL (glt-06) period dates
	for per=1 to 13
		period$=str(per:"00")
		period_end$=callpoint!.getColumnData("GLS_CALENDAR.PERIOD_END_"+period$)
		gosub check_transdetail_period_dates
		if abort then break
	next per
	if abort then break

rem --- Check United States (US) specific requirements for fiscal calendars
	ads_compinfo_dev=fnget_dev("ADS_COMPINFO")
	dim ads_compinfo$:fnget_tpl$("ADS_COMPINFO")
	readrecord(ads_compinfo_dev,key=firm_id$,dom=*next)ads_compinfo$
	if ads_compinfo.country_id$="US" then gosub validate_us_requirements

rem --- When fiscal calendar for the initial fiscal year is saved, create duplicate fiscal calendars for the prior and next fiscal years.
	gls_calendar_dev=callpoint!.getDevObject("gls_calendar_dev")
	dim gls_calendar$:fnget_tpl$("GLS_CALENDAR")

	read(gls_calendar_dev,key=firm_id$,dom=*next)
	gls_calendar_key$=key(gls_calendar_dev,end=*next)
	if pos(firm_id$=gls_calendar_key$)<>1 then
		callpoint!.setDevObject("copy_calendar",callpoint!.getColumnData("GLS_CALENDAR.YEAR"))
	else
		callpoint!.setDevObject("copy_calendar","")
	endif

rem --- Was this fiscal calendar changed (total_pers, start_date, or period_end_nn)?
	callpoint!.setDevObject("calendar_changed",0)
	if callpoint!.getColumnData("GLS_CALENDAR.TOTAL_PERS")<>callpoint!.getColumnUndoData("GLS_CALENDAR.TOTAL_PERS") then
		callpoint!.setDevObject("calendar_changed",1)
	else
		if callpoint!.getColumnData("GLS_CALENDAR.START_DATE")<>callpoint!.getColumnUndoData("GLS_CALENDAR.START_DATE") then
			callpoint!.setDevObject("calendar_changed",1)
		else
			for per=1 to num(callpoint!.getColumnData("GLS_CALENDAR.TOTAL_PERS"))
				if callpoint!.getColumnData("GLS_CALENDAR.PERIOD_END_"+str(per:"00"))<>callpoint!.getColumnUndoData("GLS_CALENDAR.PERIOD_END_"+str(per:"00")) then
					callpoint!.setDevObject("calendar_changed",1)
                            		break
				endif
			next per
		endif
	endif

[[GLS_CALENDAR.PERIOD_END_01.AVAL]]
rem --- Nothing to do if PERIOD_END_01 wasn't changed
	if callpoint!.getUserInput()=callpoint!.getColumnData("GLS_CALENDAR.PERIOD_END_01") then break

rem --- Validate period ending date
	period$="01"
	period_end$=callpoint!.getUserInput()
	gosub validate_mo_day
	if abort then break

rem --- For new entries, Adjust last day of February for leap year
	if cvs(callpoint!.getColumnData("GLS_CALENDAR.PERIOD_END_01"),2)="" then
		period_end$=callpoint!.getUserInput()
		gosub leap_year_adjustment
		if yyyymmdd$<>period_end$ then callpoint!.setUserInput(yymmdd$)
	endif

rem --- Check PERIOD_END_01 date against GLT_TRANSDETAIL (glt-06) period dates
	period$="01"
	period_end$=callpoint!.getUserInput()
	gosub check_transdetail_period_dates
	if abort then break

rem --- The last period must end on the day before the calendar start date of the next year.
	if callpoint!.getColumnData("GLS_CALENDAR.TOTAL_PERS")="01" then
		period_end$=callpoint!.getUserInput()
		gosub validate_cal_end
		if abort then break
	endif

[[GLS_CALENDAR.PERIOD_END_02.AVAL]]
rem --- Nothing to do if PERIOD_END_02 wasn't changed
	if callpoint!.getUserInput()=callpoint!.getColumnData("GLS_CALENDAR.PERIOD_END_02") then break

rem --- Validate period ending date
	period$="02"
	period_end$=callpoint!.getUserInput()
	gosub validate_mo_day
	if abort then break

rem --- For new entries, Adjust last day of February for leap year
	if cvs(callpoint!.getColumnData("GLS_CALENDAR.PERIOD_END_02"),2)="" then
		period_end$=callpoint!.getUserInput()
		gosub leap_year_adjustment
		if yyyymmdd$<>period_end$ then callpoint!.setUserInput(yyyymmdd$)
	endif

rem --- Check PERIOD_END_02 date against GLT_TRANSDETAIL (glt-06) period dates
	period$="02"
	period_end$=callpoint!.getUserInput()
	gosub check_transdetail_period_dates
	if abort then break

rem --- The last period must end on the day before the calendar start date of the next year.
	if callpoint!.getColumnData("GLS_CALENDAR.TOTAL_PERS")="02" then
		period_end$=callpoint!.getUserInput()
		gosub validate_cal_end
		if abort then break
	endif

[[GLS_CALENDAR.PERIOD_END_03.AVAL]]
rem --- Nothing to do if PERIOD_END_03 wasn't changed
	if callpoint!.getUserInput()=callpoint!.getColumnData("GLS_CALENDAR.PERIOD_END_03") then break

rem --- Validate period ending date
	period$="03"
	period_end$=callpoint!.getUserInput()
	gosub validate_mo_day
	if abort then break

rem --- For new entries, Adjust last day of February for leap year
	if cvs(callpoint!.getColumnData("GLS_CALENDAR.PERIOD_END_03"),2)="" then
		period_end$=callpoint!.getUserInput()
		gosub leap_year_adjustment
		if yyyymmdd$<>period_end$ then callpoint!.setUserInput(yyyymmdd$)
	endif

rem --- Check PERIOD_END_03 date against GLT_TRANSDETAIL (glt-06) period dates
	period$="03"
	period_end$=callpoint!.getUserInput()
	gosub check_transdetail_period_dates
	if abort then break

rem --- The last period must end on the day before the calendar start date of the next year.
	if callpoint!.getColumnData("GLS_CALENDAR.TOTAL_PERS")="03" then
		period_end$=callpoint!.getUserInput()
		gosub validate_cal_end
		if abort then break
	endif

[[GLS_CALENDAR.PERIOD_END_04.AVAL]]
rem --- Nothing to do if PERIOD_END_04 wasn't changed
	if callpoint!.getUserInput()=callpoint!.getColumnData("GLS_CALENDAR.PERIOD_END_04") then break

rem --- Validate period ending date
	period$="04"
	period_end$=callpoint!.getUserInput()
	gosub validate_mo_day
	if abort then break

rem --- For new entries, Adjust last day of February for leap year
	if cvs(callpoint!.getColumnData("GLS_CALENDAR.PERIOD_END_04"),2)="" then
		period_end$=callpoint!.getUserInput()
		gosub leap_year_adjustment
		if yyyymmdd$<>period_end$ then callpoint!.setUserInput(yyyymmdd$)
	endif

rem --- Check PERIOD_END_04 date against GLT_TRANSDETAIL (glt-06) period dates
	period$="04"
	period_end$=callpoint!.getUserInput()
	gosub check_transdetail_period_dates
	if abort then break

rem --- The last period must end on the day before the calendar start date of the next year.
	if callpoint!.getColumnData("GLS_CALENDAR.TOTAL_PERS")="04" then
		period_end$=callpoint!.getUserInput()
		gosub validate_cal_end
		if abort then break
	endif

[[GLS_CALENDAR.PERIOD_END_05.AVAL]]
rem --- Nothing to do if PERIOD_END_05 wasn't changed
	if callpoint!.getUserInput()=callpoint!.getColumnData("GLS_CALENDAR.PERIOD_END_05") then break

rem --- Validate period ending date
	period$="05"
	period_end$=callpoint!.getUserInput()
	gosub validate_mo_day
	if abort then break

rem --- For new entries, Adjust last day of February for leap year
	if cvs(callpoint!.getColumnData("GLS_CALENDAR.PERIOD_END_05"),2)="" then
		period_end$=callpoint!.getUserInput()
		gosub leap_year_adjustment
		if yyyymmdd$<>period_end$ then callpoint!.setUserInput(yyyymmdd$)
	endif

rem --- Check PERIOD_END_05 date against GLT_TRANSDETAIL (glt-06) period dates
	period$="05"
	period_end$=callpoint!.getUserInput()
	gosub check_transdetail_period_dates
	if abort then break

rem --- The last period must end on the day before the calendar start date of the next year.
	if callpoint!.getColumnData("GLS_CALENDAR.TOTAL_PERS")="05" then
		period_end$=callpoint!.getUserInput()
		gosub validate_cal_end
		if abort then break
	endif

[[GLS_CALENDAR.PERIOD_END_06.AVAL]]
rem --- Nothing to do if PERIOD_END_06 wasn't changed
	if callpoint!.getUserInput()=callpoint!.getColumnData("GLS_CALENDAR.PERIOD_END_06") then break

rem --- Validate period ending date
	period$="06"
	period_end$=callpoint!.getUserInput()
	gosub validate_mo_day
	if abort then break

rem --- For new entries, Adjust last day of February for leap year
	if cvs(callpoint!.getColumnData("GLS_CALENDAR.PERIOD_END_06"),2)="" then
		period_end$=callpoint!.getUserInput()
		gosub leap_year_adjustment
		if yyyymmdd$<>period_end$ then callpoint!.setUserInput(yyyymmdd$)
	endif

rem --- Check PERIOD_END_06 date against GLT_TRANSDETAIL (glt-06) period dates
	period$="06"
	period_end$=callpoint!.getUserInput()
	gosub check_transdetail_period_dates
	if abort then break

rem --- The last period must end on the day before the calendar start date of the next year.
	if callpoint!.getColumnData("GLS_CALENDAR.TOTAL_PERS")="06" then
		period_end$=callpoint!.getUserInput()
		gosub validate_cal_end
		if abort then break
	endif

[[GLS_CALENDAR.PERIOD_END_07.AVAL]]
rem --- Nothing to do if PERIOD_END_07 wasn't changed
	if callpoint!.getUserInput()=callpoint!.getColumnData("GLS_CALENDAR.PERIOD_END_07") then break

rem --- Validate period ending date
	period$="07"
	period_end$=callpoint!.getUserInput()
	gosub validate_mo_day
	if abort then break

rem --- For new entries, Adjust last day of February for leap year
	if cvs(callpoint!.getColumnData("GLS_CALENDAR.PERIOD_END_07"),2)="" then
		period_end$=callpoint!.getUserInput()
		gosub leap_year_adjustment
		if yyyymmdd$<>period_end$ then callpoint!.setUserInput(yyyymmdd$)
	endif

rem --- Check PERIOD_END_07 date against GLT_TRANSDETAIL (glt-06) period dates
	period$="07"
	period_end$=callpoint!.getUserInput()
	gosub check_transdetail_period_dates
	if abort then break

rem --- The last period must end on the day before the calendar start date of the next year.
	if callpoint!.getColumnData("GLS_CALENDAR.TOTAL_PERS")="07" then
		period_end$=callpoint!.getUserInput()
		gosub validate_cal_end
		if abort then break
	endif

[[GLS_CALENDAR.PERIOD_END_08.AVAL]]
rem --- Nothing to do if PERIOD_END_08 wasn't changed
	if callpoint!.getUserInput()=callpoint!.getColumnData("GLS_CALENDAR.PERIOD_END_08") then break

rem --- Validate period ending date
	period$="08"
	period_end$=callpoint!.getUserInput()
	gosub validate_mo_day
	if abort then break

rem --- For new entries, Adjust last day of February for leap year
	if cvs(callpoint!.getColumnData("GLS_CALENDAR.PERIOD_END_08"),2)="" then
		period_end$=callpoint!.getUserInput()
		gosub leap_year_adjustment
		if yyyymmdd$<>period_end$ then callpoint!.setUserInput(yyyymmdd$)
	endif

rem --- Check PERIOD_END_08 date against GLT_TRANSDETAIL (glt-06) period dates
	period$="08"
	period_end$=callpoint!.getUserInput()
	gosub check_transdetail_period_dates
	if abort then break

rem --- The last period must end on the day before the calendar start date of the next year.
	if callpoint!.getColumnData("GLS_CALENDAR.TOTAL_PERS")="08" then
		period_end$=callpoint!.getUserInput()
		gosub validate_cal_end
		if abort then break
	endif

[[GLS_CALENDAR.PERIOD_END_09.AVAL]]
rem --- Nothing to do if PERIOD_END_09 wasn't changed
	if callpoint!.getUserInput()=callpoint!.getColumnData("GLS_CALENDAR.PERIOD_END_09") then break

rem --- Validate period ending date
	period$="09"
	period_end$=callpoint!.getUserInput()
	gosub validate_mo_day
	if abort then break

rem --- For new entries, Adjust last day of February for leap year
	if cvs(callpoint!.getColumnData("GLS_CALENDAR.PERIOD_END_09"),2)="" then
		period_end$=callpoint!.getUserInput()
		gosub leap_year_adjustment
		if yyyymmdd$<>period_end$ then callpoint!.setUserInput(yyyymmdd$)
	endif

rem --- Check PERIOD_END_09 date against GLT_TRANSDETAIL (glt-06) period dates
	period$="09"
	period_end$=callpoint!.getUserInput()
	gosub check_transdetail_period_dates
	if abort then break

rem --- The last period must end on the day before the calendar start date of the next year.
	if callpoint!.getColumnData("GLS_CALENDAR.TOTAL_PERS")="09" then
		period_end$=callpoint!.getUserInput()
		gosub validate_cal_end
		if abort then break
	endif

[[GLS_CALENDAR.PERIOD_END_10.AVAL]]
rem --- Nothing to do if PERIOD_END_10 wasn't changed
	if callpoint!.getUserInput()=callpoint!.getColumnData("GLS_CALENDAR.PERIOD_END_10") then break

rem --- Validate period ending date
	period$="10"
	period_end$=callpoint!.getUserInput()
	gosub validate_mo_day
	if abort then break

rem --- For new entries, Adjust last day of February for leap year
	if cvs(callpoint!.getColumnData("GLS_CALENDAR.PERIOD_END_10"),2)="" then
		period_end$=callpoint!.getUserInput()
		gosub leap_year_adjustment
		if yyyymmdd$<>period_end$ then callpoint!.setUserInput(yyyymmdd$)
	endif

rem --- Check PERIOD_END_10 date against GLT_TRANSDETAIL (glt-06) period dates
	period$="10"
	period_end$=callpoint!.getUserInput()
	gosub check_transdetail_period_dates
	if abort then break

rem --- The last period must end on the day before the calendar start date of the next year.
	if callpoint!.getColumnData("GLS_CALENDAR.TOTAL_PERS")="10" then
		period_end$=callpoint!.getUserInput()
		gosub validate_cal_end
		if abort then break
	endif

[[GLS_CALENDAR.PERIOD_END_11.AVAL]]
rem --- Nothing to do if PERIOD_END_11 wasn't changed
	if callpoint!.getUserInput()=callpoint!.getColumnData("GLS_CALENDAR.PERIOD_END_11") then break

rem --- Validate period ending date
	period$="11"
	period_end$=callpoint!.getUserInput()
	gosub validate_mo_day
	if abort then break

rem --- For new entries, Adjust last day of February for leap year
	if cvs(callpoint!.getColumnData("GLS_CALENDAR.PERIOD_END_11"),2)="" then
		period_end$=callpoint!.getUserInput()
		gosub leap_year_adjustment
		if yyyymmdd$<>period_end$ then callpoint!.setUserInput(yyyymmdd$)
	endif

rem --- Check PERIOD_END_11 date against GLT_TRANSDETAIL (glt-06) period dates
	period$="11"
	period_end$=callpoint!.getUserInput()
	gosub check_transdetail_period_dates
	if abort then break

rem --- The last period must end on the day before the calendar start date of the next year.
	if callpoint!.getColumnData("GLS_CALENDAR.TOTAL_PERS")="11" then
		period_end$=callpoint!.getUserInput()
		gosub validate_cal_end
		if abort then break
	endif

[[GLS_CALENDAR.PERIOD_END_12.AVAL]]
rem --- Nothing to do if PERIOD_END_12 wasn't changed
	if callpoint!.getUserInput()=callpoint!.getColumnData("GLS_CALENDAR.PERIOD_END_12") then break

rem --- Validate period ending date
	period$="12"
	period_end$=callpoint!.getUserInput()
	gosub validate_mo_day
	if abort then break

rem --- For new entries, Adjust last day of February for leap year
	if cvs(callpoint!.getColumnData("GLS_CALENDAR.PERIOD_END_12"),2)="" then
		period_end$=callpoint!.getUserInput()
		gosub leap_year_adjustment
		if yyyymmdd$<>period_end$ then callpoint!.setUserInput(yyyymmdd$)
	endif

rem --- Check PERIOD_END_12 date against GLT_TRANSDETAIL (glt-06) period dates
	period$="12"
	period_end$=callpoint!.getUserInput()
	gosub check_transdetail_period_dates
	if abort then break

rem --- The last period must end on the day before the calendar start date of the next year.
	if callpoint!.getColumnData("GLS_CALENDAR.TOTAL_PERS")="12" then
		period_end$=callpoint!.getUserInput()
		gosub validate_cal_end
		if abort then break
	endif

[[GLS_CALENDAR.PERIOD_END_13.AVAL]]
rem --- Nothing to do if PERIOD_END_13 wasn't changed
	if callpoint!.getUserInput()=callpoint!.getColumnData("GLS_CALENDAR.PERIOD_END_13") then break

rem --- Validate period ending date
	period$="13"
	period_end$=callpoint!.getUserInput()
	gosub validate_mo_day
	if abort then break

rem --- For new entries, Adjust last day of February for leap year
	if cvs(callpoint!.getColumnData("GLS_CALENDAR.PERIOD_END_13"),2)="" then
		period_end$=callpoint!.getUserInput()
		gosub leap_year_adjustment
		if yyyymmdd$<>period_end$ then callpoint!.setUserInput(yyyymmdd$)
	endif

rem --- Check PERIOD_END_13 date against GLT_TRANSDETAIL (glt-06) period dates
	period$="13"
	period_end$=callpoint!.getUserInput()
	gosub check_transdetail_period_dates
	if abort then break

rem --- The last period must end on the day before the calendar start date of the next year.
	if callpoint!.getColumnData("GLS_CALENDAR.TOTAL_PERS")="13" then
		period_end$=callpoint!.getUserInput()
		gosub validate_cal_end
		if abort then break
	endif

[[GLS_CALENDAR.START_DATE.AVAL]]
rem --- Nothing to do if START_DATE wasn't changed
	if callpoint!.getUserInput()=callpoint!.getColumnData("GLS_CALENDAR.START_DATE") then break

rem --- START_DATE must be <= first trns_date in glt_transdetail (glt-06) for this fiscal year
	start_date$=callpoint!.getUserInput()
	gosub check_start_date
	if abort then break

rem --- Must be the day after the ending period of the prior year when there is a calendar for the prior year.
	gls_calendar_dev=callpoint!.getDevObject("gls_calendar_dev")
	dim gls_calendar$:fnget_tpl$("GLS_CALENDAR")
	prior_year$=str(num(callpoint!.getColumnData("GLS_CALENDAR.YEAR"))-1)
	readrecord(gls_calendar_dev,key=firm_id$+prior_year$,dom=*next)gls_calendar$
	if cvs(gls_calendar.year$,2)<>"" then
		julian=jul(num(start_date$(1,4)),num(start_date$(5,2)),num(start_date$(7)),err=*next)
		newEndDate$=date(julian-1:"%Yl%Mz%Dz")
		call stbl("+DIR_PGM")+"adc_perioddates.aon",num(gls_calendar.total_pers$),num(prior_year$),priorPerBegDate$,oldEndDate$,table_chans$[all],status
		if newEndDate$<>oldEndDate$ then
			msg_id$="GL_BAD_START_DATE"
			gosub disp_message
			if msg_opt$="N" then
				callpoint!.setStatus("ABORT")
				break
			else
				rem --- Check for existing transactions between prior year's old end date and new end date
				rem --- Transactions on the gapStartDate$ are okay
				rem --- Transactions on or before the gapEndDate$ are NOT okay
				glt_transdetail_dev=fnget_dev("GLT_TRANSDETAIL")
				dim glt_transdetail$:fnget_tpl$("GLT_TRANSDETAIL")
				if newEndDate$>oldEndDate$ then
					lastJulian=jul(num(oldEndDate$(1,4)),num(oldEndDate$(5,2)),num(oldEndDate$(7,2)))
					gapStartDate$=date(lastJulian+1:"%Yl%Mz%Dz")
					gapEndDate$=newEndDate$
				else
					lastJulian=jul(num(newEndDate$(1,4)),num(newEndDate$(5,2)),num(newEndDate$(7,2)))
					gapStartDate$=date(lastJulian+1:"%Yl%Mz%Dz")
					gapEndDate$=oldEndDate$
				endif
				read(glt_transdetail_dev,key=firm_id$+gapStartDate$,knum="BY_TRANS_DATE",dom=*next)
				readrecord(glt_transdetail_dev,end=*next)glt_transdetail$
				if glt_transdetail.firm_id$=firm_id$ and glt_transdetail.trns_date$<=gapEndDate$ then
					rem --- Don't allow changing START_DATE if there are transactions in the gap
					msg_id$="GL_EXISTING_TRANS"
					dim msg_tokens$[2]
					msg_tokens$[1]=gapStartDate$(1,4)+"-"+gapStartDate$(5,2)+"-"+gapStartDate$(7,2)
					msg_tokens$[2]=gapEndDate$(1,4)+"-"+gapEndDate$(5,2)+"-"+gapEndDate$(7,2)
					gosub disp_message
					callpoint!.setStatus("ABORT")
					break
				else
					rem --- Auto-adjust prior year end date when there are no transactions in the gap
					readrecord(gls_calendar_dev,key=firm_id$+prior_year$)gls_calendar$
					field gls_calendar$,"PERIOD_END_"+gls_calendar.total_pers$=newEndDate$
					writerecord(gls_calendar_dev)gls_calendar$

					rem --- Hold on to prior fiscal year end date in case START_DATE is not saved
					callpoint!.setDevObject("priorYearEndDate",oldEndDate$)
				endif
			endif
		endif
	endif

[[GLS_CALENDAR.TOTAL_PERS.AVAL]]
rem --- Disable and clear un-used periods
	total_pers=num(callpoint!.getUserInput())
	gosub disable_periods

rem --- TOTAL_PERS must be >= last period in glt_transdetail (glt-06) for this fiscal year
	total_pers=num(callpoint!.getUserInput())
	gosub check_total_pers
	if abort then break

rem --- Set focus of first period end date
	callpoint!.setFocus("GLS_CALENDAR.PERIOD_END_01")

[[GLS_CALENDAR.YEAR.AVAL]]
rem --- Unless it's the current fiscal year, a new year must have an existing prior year, or next year.
	gls_calendar_dev=callpoint!.getDevObject("gls_calendar_dev")
	dim gls_calendar$:fnget_tpl$("GLS_CALENDAR")
	dim gls_params$:fnget_tpl$("GLS_PARAMS")
	gls_params$=callpoint!.getDevObject("gls_params")

	year$=callpoint!.getUserInput()
	if year$<>gls_params.current_year$ then
		prior_year$=str(num(year$)-1)
		readrecord(gls_calendar_dev,key=firm_id$+prior_year$,dom=*next)gls_calendar$
		if cvs(gls_calendar.year$,2)="" then
			next_year$=str(num(year$)+1)
			readrecord(gls_calendar_dev,key=firm_id$+next_year$,dom=*next)gls_calendar$
			if cvs(gls_calendar.year$,2)="" then
				msg_id$="GL_CALENDAR_MISSING"
				gosub disp_message
				callpoint!.setStatus("ABORT")
				break
			endif

			rem --- Is this a new record?
			newRecord=1
			readrecord(gls_calendar_dev,key=firm_id$+year$,dom=*next); newRecord=0
			if newRecord then
				msg_id$="GL_COPY_CALENDAR"
				gosub disp_message
				if msg_opt$="Y" then
					rem --- Copy calendar from current fiscal year.
					gosub copy_fiscal_calendar
				else
					rem --- Do NOT copy calendar from current fiscal year.
					callpoint!.setColumnData("GLS_CALENDAR.START_DATE","",1)
					callpoint!.setColumnEnabled("GLS_CALENDAR.START_DATE",1)
				endif
			endif
		else
			rem --- Is this a new record?
			newRecord=1
			readrecord(gls_calendar_dev,key=firm_id$+year$,dom=*next); newRecord=0
			if newRecord then
				msg_id$="GL_COPY_CALENDAR"
				gosub disp_message
				if msg_opt$="Y" then
					rem --- Copy calendar from current fiscal year.
					gosub copy_fiscal_calendar
				else
					rem --- Do NOT copy calendar from current fiscal year.
					rem --- Initialize START_DATE to the day after the ending period of the prior year.
					begdate$=field(gls_calendar$,"PERIOD_END_"+gls_calendar.total_pers$)
					rem --- Adjust last day of February for leap year
					if begdate$(5,2)="02" then
						Calendar! = new java.util.GregorianCalendar()
						if begdate$(7)="29" and !Calendar!.isLeapYear(num(begdate$(1,4))) then begdate$(7)="28"
						if begdate$(7)="28" and Calendar!.isLeapYear(num(begdate$(1,4))) then begdate$(7)="29"
					endif
					julian=jul(num(begdate$(1,4)),num(begdate$(5,2)),num(begdate$(7)))+1
					begdate$=date(julian:"%Yl%Mz%Dz")
					callpoint!.setColumnData("GLS_CALENDAR.START_DATE",begdate$,1)
					callpoint!.setColumnEnabled("GLS_CALENDAR.START_DATE",0)
				endif
			endif
		endif
	endif

rem --- Get the earliest and latest trns_date in GLT_TRANSDETAIL (glt-06) for each period in "this" fiscal year.
	year$=callpoint!.getUserInput()
	gosub get_transdetail_period_dates

[[GLS_CALENDAR.<CUSTOM>]]
#include [+ADDON_LIB]std_missing_params.aon

show_current_fiscal_yr: rem --- Show current fiscal year and period
	dim gls_params$:fnget_tpl$("GLS_PARAMS")
	gls_params$=callpoint!.getDevObject("gls_params")
	callpoint!.setColumnData("<<DISPLAY>>.CURRENT_YEAR",gls_params.current_year$,1)
	callpoint!.setColumnData("<<DISPLAY>>.CURRENT_PER",gls_params.current_per$,1)
	callpoint!.setColumnData("<<DISPLAY>>.GL_YR_CLOSED",gls_params.gl_yr_closed$,1)
	callpoint!.setColumnData("<<DISPLAY>>.ADJUST_FEBRUARY",str(gls_params.adjust_february),1)
	callpoint!.setColumnData("<<DISPLAY>>.CREATE_NEXT_CAL",str(gls_params.create_next_cal),1)
return

disable_periods: rem --- Disable and clear periods based on total number of fiscal periods
                            rem --- Input: total_pers = total number of periods in this fiscal year
	for per=1 to 13
		able=iff(per<=total_pers,1,0)
		callpoint!.setColumnEnabled("GLS_CALENDAR.PERIOD_END_"+str(per:"00"),able)
		callpoint!.setColumnEnabled("GLS_CALENDAR.PERIOD_NAME_"+str(per:"00"),able)
		callpoint!.setColumnEnabled("GLS_CALENDAR.ABBR_NAME_"+str(per:"00"),able)
		callpoint!.setColumnEnabled("GLS_CALENDAR.LOCKED_FLAG_"+str(per:"00"),able)
		callpoint!.setColumnEnabled("GLS_CALENDAR.LOCKED_DATE_"+str(per:"00"),able)
		if !able then
			callpoint!.setColumnData("GLS_CALENDAR.PERIOD_END_"+str(per:"00"),"")
			callpoint!.setColumnData("GLS_CALENDAR.PERIOD_NAME_"+str(per:"00"),"")
			callpoint!.setColumnData("GLS_CALENDAR.ABBR_NAME_"+str(per:"00"),"")
			callpoint!.setColumnData("GLS_CALENDAR.LOCKED_FLAG_"+str(per:"00"),"")
			callpoint!.setColumnData("GLS_CALENDAR.LOCKED_DATE_"+str(per:"00"),"")
		endif
	next per
	callpoint!.setStatus("REFRESH")
return

validate_cal_end: rem --- The ending day of the last period must be the day before the start of
                              rem --- the next year when a fiscal calendar exists for the next year.
                              rem --- Input: period_end$ = yyyymmdd period ending date
                              rem --- Output: abort = 1 (true) or 0 (false) for callpoint!.setStatus("ABORT")
	gls_calendar_dev=callpoint!.getDevObject("gls_calendar_dev")
	dim gls_calendar$:fnget_tpl$("GLS_CALENDAR")
	abort=0

	year$=callpoint!.getColumnData("GLS_CALENDAR.YEAR")
	next_year$=str(num(year$)+1)
	readrecord(gls_calendar_dev,key=firm_id$+next_year$,dom=*next)gls_calendar$
	if cvs(gls_calendar.year$,2)<>"" then
		oldStartDate$=gls_calendar.start_date$
		julian=jul(num(period_end$(1,4)),num(period_end$(5,2)),num(period_end$(7)))
		newStartDate$=date(julian+1:"%Yl%Mz%Dz")
		if newStartDate$<>oldStartDate$ then
			msg_id$="GL_BAD_END_DATE"
			gosub disp_message
			if msg_opt$="N" then
				callpoint!.setStatus("ABORT")
				abort=1
			else
				rem --- Check for existing transactions between prior year's old end date and new end date
				rem --- Transactions on the gapStartDate$ are okay
				rem --- Transactions on or before the gapEndDate$ are NOT okay
				glt_transdetail_dev=fnget_dev("GLT_TRANSDETAIL")
				dim glt_transdetail$:fnget_tpl$("GLT_TRANSDETAIL")
				if newStartDate$>oldStartDate$ then
					gapStartDate$=oldStartDate$
					newStartJulian=jul(num(newStartDate$(1,4)),num(newStartDate$(5,2)),num(newStartDate$(7,2)))
					gapEndDate$=date(newStartJulian-1:"%Yl%Mz%Dz")
				else
					gapStartDate$=newStartDate$
					oldStartJulian=jul(num(oldStartDate$(1,4)),num(oldStartDate$(5,2)),num(oldStartDate$(7,2)))
					gapEndDate$=date(oldStartJulian-1:"%Yl%Mz%Dz")
				endif
				read(glt_transdetail_dev,key=firm_id$+gapStartDate$,knum="BY_TRANS_DATE",dom=*next)
				readrecord(glt_transdetail_dev,end=*next)glt_transdetail$
				if glt_transdetail.firm_id$=firm_id$ and glt_transdetail.trns_date$<=gapEndDate$ then
					rem --- Don't allow changing fiscal calendar end date if there are transactions in the gap
					msg_id$="GL_EXISTING_TRANS"
					dim msg_tokens$[2]
					msg_tokens$[1]=gapStartDate$(1,4)+"-"+gapStartDate$(5,2)+"-"+gapStartDate$(7,2)
					msg_tokens$[2]=gapEndDate$(1,4)+"-"+gapEndDate$(5,2)+"-"+gapEndDate$(7,2)
					gosub disp_message
					callpoint!.setStatus("ABORT")
				else
					rem --- Auto-adjust next year start date when there are no transactions in the gap
					readrecord(gls_calendar_dev,key=firm_id$+next_year$)gls_calendar$
					field gls_calendar$,"START_DATE"=newStartDate$
					writerecord(gls_calendar_dev)gls_calendar$

					rem --- Hold on to next fiscal year start date in case last PERIOD_END_nn is not saved
					callpoint!.setDevObject("nextYearStartDate",oldStartDate$)
				endif
			endif
		endif
	endif
return

leap_year_adjustment: rem --- Adjust last day of February for leap year
                              rem --- Input: period_end$ = yyyymmdd period ending date
                              rem --- Output: yyyymmdd$ = adjusted date
	yyyymmdd$=period_end$
	dim gls_params$:fnget_tpl$("GLS_PARAMS")
	gls_params$=callpoint!.getDevObject("gls_params")
	if (gls_params.adjust_february and period_end$(5)="0228") or period_end$(5)="0229" then
		Calendar! = new java.util.GregorianCalendar()
		if period_end$(5)="0229" and !Calendar!.isLeapYear(num(period_end$(1,4))) then yyyymmdd$(5)="0228"
		if period_end$(5)="0228" and Calendar!.isLeapYear(num(period_end$(1,4))) then yyyymmdd$(5)="0229"
	endif
return

copy_fiscal_calendar: rem --- Copy calendar from current fiscal year
	current_fiscal_yr$=gls_params.current_year$
	delta_years=num(year$)-num(current_fiscal_yr$)
	readrecord(gls_calendar_dev,key=firm_id$+current_fiscal_yr$,dom=*endif)gls_calendar$
	start_date$=gls_calendar.start_date$
	start_year$=str(num(start_date$(1,4))+delta_years)
	callpoint!.setColumnData("GLS_CALENDAR.START_DATE",start_year$+start_date$(5))
	total_pers$=gls_calendar.total_pers$
	callpoint!.setColumnData("GLS_CALENDAR.TOTAL_PERS",total_pers$)
	for per=1 to num(total_pers$)
		period_end$=field(gls_calendar$,"PERIOD_END_"+str(per:"00"))
		period_year$=str(num(period_end$(1,4))+delta_years)
		period_end$=period_year$+period_end$(5)
		if (gls_params.adjust_february and period_end$(5)="0228") or period_end$(5)="0229" then
			rem --- Adjust last day of February for leap year
			Calendar! = new java.util.GregorianCalendar()
			if period_end$(5)="0229" and !Calendar!.isLeapYear(num(period_end$(1,4))) then period_end$(5)="0228"
			if period_end$(5)="0228" and Calendar!.isLeapYear(num(period_end$(1,4))) then period_end$(5)="0229"
		endif
		callpoint!.setColumnData("GLS_CALENDAR.PERIOD_END_"+str(per:"00"),period_end$)
		period_name$=field(gls_calendar$,"PERIOD_NAME_"+str(per:"00"))
		callpoint!.setColumnData("GLS_CALENDAR.PERIOD_NAME_"+str(per:"00"),period_name$)
		abbr_name$=field(gls_calendar$,"ABBR_NAME_"+str(per:"00"))
		callpoint!.setColumnData("GLS_CALENDAR.ABBR_NAME_"+str(per:"00"),abbr_name$)
		if year$<current_fiscal_yr$ then
			callpoint!.setColumnData("GLS_CALENDAR.LOCKED_FLAG_"+str(per:"00"),"Y")
			callpoint!.setColumnData("GLS_CALENDAR.LOCKED_DATE_"+str(per:"00"),date(0:"%Yd%Mz%Dz"))
		else
			callpoint!.setColumnData("GLS_CALENDAR.LOCKED_FLAG_"+str(per:"00"),"N")
			callpoint!.setColumnData("GLS_CALENDAR.LOCKED_DATE_"+str(per:"00"),"")
		endif
	next per

	total_pers=num(total_pers$)
	gosub disable_periods
	callpoint!.setStatus("REFRESH-MODIFIED")
return

get_transdetail_period_dates: rem --- Get the earliest and latest trns_date in GLT_TRANSDETAIL (glt-06) for each period in given fiscal year.
                                                   rem --- Input: year$ = fiscal year of interest
	glt_transdetail_dev=fnget_dev("GLT_TRANSDETAIL")
	dim glt_transdetail$:fnget_tpl$("GLT_TRANSDETAIL")

	rem --- Get the earliest trns_date for each period
	earliestTransDate!=new java.util.HashMap()
	for per=1 to 13
		period$=str(per:"00")
		read(glt_transdetail_dev,key=firm_id$+year$+period$,knum="BY_YEAR_PERIOD",dom=*next)
		redim glt_transdetail$
		readrecord(glt_transdetail_dev,end=*next)glt_transdetail$
		if firm_id$+year$+period$=glt_transdetail.firm_id$+glt_transdetail.posting_year$+glt_transdetail.posting_per$ then
			earliestTransDate!.put(period$,glt_transdetail.trns_date$)
		else
			earliestTransDate!.put(period$,"")
		endif
	next per

	rem --- Get the latest trns_date for each period
	latestTransDate!=new java.util.HashMap()
	for per=1 to 13
		period$=str(per:"00")
		read(glt_transdetail_dev,key=firm_id$+year$+period$+$FF$,knum="BY_YEAR_PERIOD",dom=*next)
		readrecord(glt_transdetail_dev,dir=-1,end=*next)
		redim glt_transdetail$
		readrecord(glt_transdetail_dev,end=*next)glt_transdetail$
		if firm_id$+year$+period$=glt_transdetail.firm_id$+glt_transdetail.posting_year$+glt_transdetail.posting_per$ then
			latestTransDate!.put(period$,glt_transdetail.trns_date$)
		else
			latestTransDate!.put(period$,"")
		endif
	next per

	callpoint!.setDevObject("earliestTransDate",earliestTransDate!)
	callpoint!.setDevObject("latestTransDate",latestTransDate!)
return

check_total_pers: rem --- TOTAL_PERS must be >= last period in glt_transdetail (glt-06) for this fiscal year
                                                       rem --- Input: total_per = total number of periods in the fiscal year
                                                       rem --- Output: abort = 1 (true) or 0 (false) for callpoint!.setStatus("ABORT")
	latestTransDate!=callpoint!.getDevObject("latestTransDate")
	last_period=-1
	for per=13 to 1 step -1
		if latestTransDate!.get(str(per:"00"))<>"" then
			last_period=per
			break
		endif
	next per
	if total_pers<last_period then
		msg_id$="GL_BAD_TOTAL_PERS"
		dim msg_tokens$[2]
		msg_tokens$[1]=str(last_period)
		msg_tokens$[2]=str(last_period)
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif
return


check_start_date: rem --- START_DATE must be <= first trns_date in glt_transdetail (glt-06) for this fiscal year
                                                       rem --- Input: start_date$ = the calendar start date to be checked
                                                       rem --- Output: abort = 1 (true) or 0 (false) for callpoint!.setStatus("ABORT")

	abort=0
	earliestTransDate!=callpoint!.getDevObject("earliestTransDate")
	first_yyyymmdd$="99999999"
	for per=1 to 13
		trans_date$=earliestTransDate!.get(str(per:"00"))
		if trans_date$<>"" then
			first_yyyymmdd$=trans_date$
			break
		endif
	next per
	if start_date$>first_yyyymmdd$ then
		msg_id$="GL_BAD_CAL_START"
		dim msg_tokens$[2]
		msg_tokens$[1]=first_yyyymmdd$(5,2)+"-"+first_yyyymmdd$(7)+"-"+first_yyyymmdd$(1,4)
		msg_tokens$[2]=first_yyyymmdd$(5,2)+"-"+first_yyyymmdd$(7)+"-"+first_yyyymmdd$(1,4)
		gosub disp_message
		callpoint!.setStatus("ABORT")
		abort=1
	endif
return

check_transdetail_period_dates: rem --- Check PERIOD_END_nn date against GLT_TRANSDETAIL (glt-06) period dates
                                                       rem --- Input: period$ = period the period_end$ date is for
                                                       rem --- Input: period_end$ = yyyymmdd period ending date
                                                       rem --- Output: abort = 1 (true) or 0 (false) for callpoint!.setStatus("ABORT")

	rem --- Period cannot end before this date
	abort=0
	latestTransDate!=callpoint!.getDevObject("latestTransDate")
	before_date$=latestTransDate!.get(period$)
	if before_date$<>"" and period_end$<before_date$ then
		msg_id$="GL_PER_END_BEFORE"
		dim msg_tokens$[4]
		msg_tokens$[1]=before_date$(1,4)+"-"+before_date$(5,2)+"-"+before_date$(7)
		msg_tokens$[2]=period$
		msg_tokens$[3]=period$
		msg_tokens$[4]=before_date$(1,4)+"-"+before_date$(5,2)+"-"+before_date$(7)
		gosub disp_message
		callpoint!.setStatus("ABORT")
		abort=1
	endif

	rem --- Period cannot end on or after this date
	next_period$=str(num(period$)+1:"00")
	if !abort and next_period$<="13" then
		earliestTransDate!=callpoint!.getDevObject("earliestTransDate")
		after_date$=earliestTransDate!.get(next_period$)
		if after_date$<>"" then
			if period_end$>=after_date$ then
				msg_id$="GL_PER_END_AFTER"
				dim msg_tokens$[4]
				msg_tokens$[1]=after_date$(1,4)+"-"+after_date$(5,2)+"-"+after_date$(7)
				msg_tokens$[2]=next_period$
				msg_tokens$[3]=period$
				msg_tokens$[4]=after_date$(1,4)+"-"+after_date$(5,2)+"-"+after_date$(7)
				gosub disp_message
				callpoint!.setStatus("ABORT")
				abort=1
			endif
		endif
	endif
return

rem --- Validate period ending date
validate_mo_day: rem --- validate period ending date (yyyymmdd - doesn't check for Feb 28 vs 29)
                              rem --- Input: period$
                              rem --- Input: period_end$ = yyyymmdd period ending date
                              rem --- Output: abort = 1 (true) or 0 (false) for callpoint!.setStatus("ABORT")

	rem --- Valid month and day?
	abort=1
	switch num(period_end$(5,2))
		case 1
		case 3
		case 5
		case 7
		case 8
		case 10
		case 12
			if num(period_end$(7))>=1 and num(period_end$(7))<=31 then abort=0	
			break
		case 2
			if num(period_end$(7))>=1 and num(period_end$(7))<=29 then abort=0
			break
		case 4
		case 6
		case 9
		case 11
			if num(period_end$(7))>=1 and num(period_end$(7))<=30 then abort=0
			break
		case default
			break
	swend
	if abort then
		msg_id$="GL_INVAL_PER"
		gosub disp_message
		callpoint!.setStatus("ABORT")
		return
	endif

	rem --- Period ending date cannot be before period start date
	if period$<>"01" then
		rem --- Period start date is prior period end date +1
		prior_end$=callpoint!.getColumnData("GLS_CALENDAR.PERIOD_END_"+str(num(period$)-1:"00"))
		start_julian=0
		start_julian=jul(num(prior_end$(1,4)),num(prior_end$(5,2)),num(prior_end$(7)),err=*next)+1
	else
		rem --- Period start date is calendar start date
		start_date$=callpoint!.getColumnData("GLS_CALENDAR.START_DATE")
		start_julian=0
		start_julian=jul(num(start_date$(1,4)),num(start_date$(5,2)),num(start_date$(7)),err=*next)
	endif
	end_julian=jul(num(period_end$(1,4)),num(period_end$(5,2)),num(period_end$(7)))
	if start_julian>0 and end_julian<start_julian then
		startDate$=date(start_julian:"%Yl%Mz%Dz")
		msg_id$="GL_PER_END_EARLY"
		dim msg_tokens$[1]
		msg_tokens$[1]=startDate$(1,4)+"-"+startDate$(5,2)+"-"+startDate$(7,2)
		gosub disp_message
		callpoint!.setStatus("ABORT")
		return
	endif

	rem --- Period ending date must be before next periods end date
	if period$<>callpoint!.getColumnData("GLS_CALENDAR.TOTAL_PERS") then
		rem --- Period end date must be before next periods end date
		next_end$=callpoint!.getColumnData("GLS_CALENDAR.PERIOD_END_"+str(num(period$)+1:"00"))
		nextEnd_julian=0
		nextEnd_julian=jul(num(next_end$(1,4)),num(next_end$(5,2)),num(next_end$(7)),err=*next)
	else
		rem --- Period end date must be before next fiscal year's start date
		rem --- Handled via validate_cal_end subroutine for each PERIOD_END
	endif
	end_julian=jul(num(period_end$(1,4)),num(period_end$(5,2)),num(period_end$(7)))
	if nextEnd_julian>0 and end_julian>=nextEnd_julian then
		nextEndtDate$=date(nextEnd_julian:"%Yl%Mz%Dz")
		msg_id$="GL_PER_END_LATE"
		dim msg_tokens$[1]
		msg_tokens$[1]=nextEndtDate$(1,4)+"-"+nextEndtDate$(5,2)+"-"+nextEndtDate$(7,2)
		gosub disp_message
		callpoint!.setStatus("ABORT")
		return
	endif
return

validate_us_requirements: rem --- Check United States (US) specific requirements for fiscal calendars

	rem --- Per US Tax Code, fiscal calendar must include at least a minimum of 359 days ( 13 periods * 4 weeks – less 5 days),
        rem --- but not more than a maximum of 371 days (53 weeks * 7 days).
	start_date$=callpoint!.getColumnData("GLS_CALENDAR.START_DATE")
	start_julian=jul(num(start_date$(1,4)),num(start_date$(5,2)),num(start_date$(7)))

	total_pers$=callpoint!.getColumnData("GLS_CALENDAR.TOTAL_PERS")
	ending_yyyymmdd$=callpoint!.getColumnData("GLS_CALENDAR.PERIOD_END_"+total_pers$)
	end_julian=jul(num(ending_yyyymmdd$(1,4)),num(ending_yyyymmdd$(5,2)),num(ending_yyyymmdd$(7)))

	minimum_julian=start_julian+359
	maximum_julian=start_julian+371
	if end_julian<minimum_julian and end_julian>maximum_julian then
		msg_id$="GL_US_CAL_REQ_1"
		gosub disp_message
	endif
return



