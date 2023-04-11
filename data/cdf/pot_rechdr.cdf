[[POT_RECHDR.BSHO]]
rem --- Open Files
	num_files=11
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="IVM_ITEMMAST",open_opts$[1]="OTA"

	gosub open_tables

rem --- store control for header total
	callpoint!.setDevObject("totReceived",callpoint!.getControl("<<DISPLAY>>.ORDER_TOTAL"))



