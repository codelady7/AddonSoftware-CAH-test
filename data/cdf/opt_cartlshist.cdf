[[OPT_CARTLSHIST.BGDR]]
rem --- Get item_id for this lot/serial number
	optCartDet_dev=fnget_dev("OPT_CARTDET")
	dim optCartDet$:fnget_tpl$("OPT_CARTDET")
	ar_type$=callpoint!.getColumnData("OPT_CARTLSHIST.AR_TYPE")
	customer_id$=callpoint!.getColumnData("OPT_CARTLSHIST.CUSTOMER_ID")
	order_no$=callpoint!.getColumnData("OPT_CARTLSHIST.ORDER_NO")
	ar_inv_no$=callpoint!.getColumnData("OPT_CARTLSHIST.AR_INV_NO")
	carton_no$=callpoint!.getColumnData("OPT_CARTLSHIST.CARTON_NO")
	orddet_seq_ref$=callpoint!.getColumnData("OPT_CARTLSHIST.ORDDET_SEQ_REF")

	optCartDet_key$=firm_id$+ar_type$+customer_id$+order_no$+ar_inv_no$+carton_no$+orddet_seq_ref$
	findrecord(optCartDet_dev,key=optCartDet_key$,dom=*next)optCartDet$
	callpoint!.setColumnData("<<DISPLAY>>.ITEM_ID",optCartDet.item_id$)

[[OPT_CARTLSHIST.BSHO]]
rem --- Open files
	num_files = 1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]

	open_tables$[1]="OPT_CARTDET", open_opts$[1]="OTA"

	gosub open_tables



