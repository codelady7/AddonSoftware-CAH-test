[[IVR_BACKORDERS.ARER]]
rem --- Load Warehouses ListBox
	whseID!=callpoint!.getDevObject("whseID")
	whseName!=callpoint!.getDevObject("whseName")

	whseCtl!=callpoint!.getControl("IVR_BACKORDERS.WAREHOUSES")
	whseCtl!.setMultipleSelection(1)
	whseCtl!.removeAllItems()
	height=whseCtl!.getHeight()
	width=whseCtl!.getWidth()
	if whseID!.size()<4 then
		whseCtl!.setSize(width,height*whseID!.size())
	else
		whseCtl!.setSize(width,height*4)
	endif

	whseCtl!.insertItems(0,whseName!)
	ldat$=func.buildListButtonList(whseName!,whseID!)
	callpoint!.setTableColumnAttribute("IVR_BACKORDERS.WAREHOUSES","LDAT",ldat$)
	indexVect!=bbjAPI().makeVector()
	for i=0 to whseID!.size()-1
		indexVect!.addItem(i)
	next i
	whseCtl!.setSelectedIndices(indexVect!)

[[IVR_BACKORDERS.ASVA]]
rem --- Pass selected Warehouses to the program
	whseCtl!=callpoint!.getControl("IVR_BACKORDERS.WAREHOUSES")
	selectedItems!=whseCtl!.getSelectedItems()
	whseID!=callpoint!.getDevObject("whseID")
	if selectedItems!.size()=whseID!.size()  then
		warehouses$="All"
	else
		for i=0 to selectedItems!.size()-1
			whse$=selectedItems!.getItem(i)
			warehouses$=warehouses$+"'"+whse$(1,pos(" "=whse$)-1)+"', "
		next i
	endif
	callpoint!.setDevObject("warehouses",warehouses$)

[[IVR_BACKORDERS.BSHO]]
rem --- Inits
	use ::ado_func.src::func

rem --- Open File(s)
	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]

	open_tables$[1]="IVC_WHSECODE",open_opts$[1]="OTA"

	gosub open_tables

	ivcWhseCode_dev=num(open_chans$[1]);dim ivcWhseCode$:open_tpls$[1]

rem --- Build vectors of Warehouse IDs and Name
	whseID!=bbjAPI().makeVector()
	whseName!=bbjAPI().makeVector()
	read(ivcWhseCode_dev,key=firm_id$+"C",dom=*next)
	while 1
		ivcWhseCode_key$=key(ivcWhseCode_dev,end=*break)
		if pos(firm_id$+"C"=ivcWhseCode_key$)<>1 then break
		readrecord(ivcWhseCode_dev)ivcWhseCode$
		whseID!.addItem(ivcWhseCode.warehouse_id$)
		whseName!.addItem(ivcWhseCode.warehouse_id$+" "+ivcWhseCode.short_name$)
	wend

	callpoint!.setDevObject("whseID",whseID!)
	callpoint!.setDevObject("whseName",whseName!)



