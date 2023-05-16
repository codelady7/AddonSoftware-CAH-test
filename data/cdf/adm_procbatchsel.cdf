[[ADM_PROCBATCHSEL.AGRN]]
rem --- Disable the Edit button
	navWin!=Form!.getChildWindow(num(stbl("+NAVBAR_CTL")))
	ctrlVec!=navWin!.getAllControls()
	for i=0 to ctrlVec!.size()-1
		ctrl!=ctrlVec!.get(i)
		if ctrl!.getToolTipText()="Edit" then
			ctrl!.setEnabled(0)
			break
		endif
	next i

[[ADM_PROCBATCHSEL.AOPT-CHKO]]
rem --- Check for orphan batches
	admProcBatchSel_dev=fnget_dev("ADM_PROCBATCHSEL")
	admProcDetail_dev=fnget_dev("ADM_PROCDETAIL")
	dim admProcDetail$:fnget_tpl$("ADM_PROCDETAIL")
	process_id$=stbl("+PROCESS_ID")
	table_alias$=""

	trip_key$=firm_id$+process_id$
	read(admProcDetail_dev,key=trip_key$,knum="PRIMARY",dom=*next)
	while 1
		admProcDetail_key$=key(admProcDetail_dev,end=*break)
		if pos(trip_key$=admProcDetail_key$)<>1 break
		readrecord(admProcDetail_dev)admProcDetail$
		table_alias$=cvs(admProcDetail.dd_table_alias$,2)
		break
	wend
	if table_alias$="" then break

	rem --- For tables with a trans_status column, skip records where trans_status$<>"E".
	sqlprep$="SELECT COUNT(*) FROM DDM_TABLE_COLS WHERE DD_TABLE_ALIAS='"+table_alias$+"' AND DD_DATA_NAME='TRANS_STATUS'"
	sql_chan=sqlunt
	sqlopen(sql_chan,err=*next)stbl("+DBNAME")
	sqlprep(sql_chan)sqlprep$
	dim read_tpl$:sqltmpl(sql_chan)
	sqlexec(sql_chan)

	read_tpl$=sqlfetch(sql_chan,err=*break)
	if num(read_tpl$)=0 then
		where_transStatus$=""
	else
		where_transStatus$=" AND TRANS_STATUS='E'"
	endif

	sqlprep$="SELECT DISTINCT BATCH_NO FROM "+table_alias$+" WHERE FIRM_ID='"+firm_id$+"'"+where_transStatus$
	sql_chan=sqlunt
	sqlopen(sql_chan,err=*next)stbl("+DBNAME")
	sqlprep(sql_chan)sqlprep$
	dim read_tpl$:sqltmpl(sql_chan)
	sqlexec(sql_chan)

	orph_batches! = BBjAPI().makeVector()
	orph_grid_batches!=BBjAPI().makeVector()
	while 1
		read_tpl$=sqlfetch(sql_chan,err=*break) 
		batch_no$=read_tpl.batch_no$

		rem --- Is this an orphan batch?
		found=0
		read(admProcBatchSel_dev,key=firm_id$+process_id$+batch_no$,dom=*next); found=1
		if !found then
			rem --- Add this orphan batch to the grid
			 orph_batches!.addItem(batch_no$)

			orph_grid_batches!.addItem(batch_no$)
			orph_grid_batches!.addItem("Unknown")
			orph_grid_batches!.addItem("")
			orph_grid_batches!.addItem("")
			orph_grid_batches!.addItem("")
			orph_grid_batches!.addItem("")
			orph_grid_batches!.addItem("Not on File")
		endif
	wend

	if orph_batches!.size() then
		msg_id$="AD_BATCH_ORPH"
		dim msg_tokens$[2]
		batches$=""
		msg_tokens$[1]=table_alias$
		for i=0 to orph_batches!.size()-1
			batches$=batches$+orph_batches!.getItem(i)+$0A$
		next i
		msg_tokens$[2]=batches$
		gosub disp_message

		rem --- Add orphan batches to the grid
		maintGrid!=Form!.getControl(num(stbl("+GRID_CTL")))
		maintGrid!.setNumRows(maintGrid!.getNumRows()+orph_batches!.size()-1)
		maintGrid!.setCellText(GridVect!.size(),0,orph_grid_batches!)
	else
		msg_id$="AD_BATCH_NO_ORPH"
		gosub disp_message
	endif

[[ADM_PROCBATCHSEL.AOPT-SELB]]
rem --- Set +BATCH_NO stbl, lock batch and Exit
	process_id$=callpoint!.getColumnData("ADM_PROCBATCHSEL.PROCESS_ID")

	maintGrid!=Form!.getControl(num(stbl("+GRID_CTL")))
	batch_no$=maintGrid!.getCellText(maintGrid!.getSelectedRow(),0)
	if cvs(batch_no$,2)="" then break

	lock_record$=firm_id$+process_id$+batch_no$
	lock_record$=lock_record$+"S"; rem --- Must add "S" at end of lock_record$ when checking for supplemental lock
	lock_type$="C"; rem --- check for lock
	lock_status$=""
	lock_disp$="M"
	call stbl("+DIR_SYP")+"bac_lock_record.bbj","ADM_PROCBATCHES",lock_record$,lock_type$,lock_disp$,rd_table_chan,table_chans$[all],lock_status$

	if lock_status$="" then
		lock_record$=firm_id$+process_id$+batch_no$
		lock_type$="S"
		lock_status$=""
		lock_disp$="M"
		call stbl("+DIR_SYP")+"bac_lock_record.bbj","ADM_PROCBATCHSEL",lock_record$,lock_type$,lock_disp$,rd_table_chan,table_chans$[all],lock_status$

		if lock_status$="" then
			x$=stbl("+BATCH_NO",batch_no$)
			callpoint!.setDevObject("batchSelected",1)
			callpoint!.setStatus("EXIT")
		else
			x$=stbl("+BATCH_NO","")
			callpoint!.setDevObject("batchSelected",0)
		endif
	else
		x$=stbl("+BATCH_NO","")
		callpoint!.setDevObject("batchSelected",0)
	endif

[[ADM_PROCBATCHSEL.BEND]]
rem --- Notify user of the process aborting and release
	if callpoint!.getDevObject("batchSelected")=0 then
		msg_id$="PROCESS_ABORT"
		gosub disp_message
		release
	endif

[[ADM_PROCBATCHSEL.BSHO]]
rem --- Initializations
	callpoint!.setDevObject("batchSelected",0)

rem --- Open/Lock files
	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="ADM_PROCDETAIL",open_opts$[1]="OTA"

	gosub open_tables

[[ADM_PROCBATCHSEL.BTBL]]
rem --- Only show batches for the current process
	callpoint!.setTableColumnAttribute("ADM_PROCBATCHSEL.PROCESS_ID","PVAL",$22$+stbl("+PROCESS_ID")+$22$)



