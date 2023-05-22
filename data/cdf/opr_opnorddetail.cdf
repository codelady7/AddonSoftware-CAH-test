[[OPR_OPNORDDETAIL.AREC]]
rem --- Disable Shipped Orders
	callpoint!.setColumnEnabled("OPR_OPNORDDETAIL.OPEN_SHIPPED",0)

[[OPR_OPNORDDETAIL.ARER]]
rem --- Enable Open Orders' Non-Stock Options ListButton
	callpoint!.setColumnEnabled("OPR_OPNORDDETAIL.NON_STOCK_OPTION",1)

[[OPR_OPNORDDETAIL.OPEN.AVAL]]
rem --- Skip if not changed
open$=callpoint!.getUserInput()
if open$=callpoint!.getColumnData("OPR_OPNORDDETAIL.OPEN") then break

rem --- Enable/disable Open Orders sub-options
if open$="Y" then
	rem --- Enable and check sub-options
	callpoint!.setColumnEnabled("OPR_OPNORDDETAIL.OPEN_BACK",1)
	callpoint!.setColumnEnabled("OPR_OPNORDDETAIL.OPEN_HOLD",1)
	callpoint!.setColumnEnabled("OPR_OPNORDDETAIL.OPEN_NEW",1)
	callpoint!.setColumnEnabled("OPR_OPNORDDETAIL.OPEN_SHIPPED",0); rem --- Disable Shipped Orders
	callpoint!.setColumnEnabled("OPR_OPNORDDETAIL.NON_STOCK_OPTION",1)
	callpoint!.setColumnData("OPR_OPNORDDETAIL.OPEN_BACK","Y",1)
	callpoint!.setColumnData("OPR_OPNORDDETAIL.OPEN_HOLD","Y",1)
	callpoint!.setColumnData("OPR_OPNORDDETAIL.OPEN_NEW","Y",1)
	callpoint!.setColumnData("OPR_OPNORDDETAIL.OPEN_SHIPPED","Y",1)
	callpoint!.setColumnData("OPR_OPNORDDETAIL.NON_STOCK_OPTION","A",1)
else
	rem --- Disable and uncheck sub-options
	callpoint!.setColumnEnabled("OPR_OPNORDDETAIL.OPEN_BACK",0)
	callpoint!.setColumnEnabled("OPR_OPNORDDETAIL.OPEN_HOLD",0)
	callpoint!.setColumnEnabled("OPR_OPNORDDETAIL.OPEN_NEW",0)
	callpoint!.setColumnEnabled("OPR_OPNORDDETAIL.OPEN_SHIPPED",1); rem --- Enable Shipped Orders
	callpoint!.setColumnEnabled("OPR_OPNORDDETAIL.NON_STOCK_OPTION",0)
	callpoint!.setColumnData("OPR_OPNORDDETAIL.OPEN_BACK","N",1)
	callpoint!.setColumnData("OPR_OPNORDDETAIL.OPEN_HOLD","N",1)
	callpoint!.setColumnData("OPR_OPNORDDETAIL.OPEN_NEW","N",1)
	callpoint!.setColumnData("OPR_OPNORDDETAIL.OPEN_SHIPPED","N",1)
	callpoint!.setColumnData("OPR_OPNORDDETAIL.NON_STOCK_OPTION","X",1)
endif

[[OPR_OPNORDDETAIL.OPEN_BACK.AVAL]]
rem --- Skip if not changed
open_back$=callpoint!.getUserInput()
if open$=callpoint!.getColumnData("OPR_OPNORDDETAIL.OPEN_BACK") then break

rem --- Enable/disable Open Orders' Non-Stock Options ListButton
open_hold$=callpoint!.getColumnData("OPR_OPNORDDETAIL.OPEN_HOLD")
open_new$=callpoint!.getColumnData("OPR_OPNORDDETAIL.OPEN_NEW")
if open_back$="Y" or open_hold$="Y" or open_new$="Y" then
	rem --- Enable Non-Stock Options ListButton, but don't set
	callpoint!.setColumnEnabled("OPR_OPNORDDETAIL.NON_STOCK_OPTION",1)
else
	rem --- Disable and set Non-Stock Options ListButton
	callpoint!.setColumnEnabled("OPR_OPNORDDETAIL.NON_STOCK_OPTION",0)
	callpoint!.setColumnData("OPR_OPNORDDETAIL.NON_STOCK_OPTION","X",1)
endif

[[OPR_OPNORDDETAIL.OPEN_HOLD.AVAL]]
rem --- Skip if not changed
open_hold$=callpoint!.getUserInput()
if open_hold$=callpoint!.getColumnData("OPR_OPNORDDETAIL.OPEN_HOLD") then break

rem --- Enable/disable Open Orders' Non-Stock Options ListButton
open_back$=callpoint!.getColumnData("OPR_OPNORDDETAIL.OPEN_BACK")
open_new$=callpoint!.getColumnData("OPR_OPNORDDETAIL.OPEN_NEW")
if open_back$="Y" or open_hold$="Y" or open_new$="Y" then
	rem --- Enable Non-Stock Options ListButton, but don't set
	callpoint!.setColumnEnabled("OPR_OPNORDDETAIL.NON_STOCK_OPTION",1)
else
	rem --- Disable and set Non-Stock Options ListButton
	callpoint!.setColumnEnabled("OPR_OPNORDDETAIL.NON_STOCK_OPTION",0)
	callpoint!.setColumnData("OPR_OPNORDDETAIL.NON_STOCK_OPTION","X",1)
endif

[[OPR_OPNORDDETAIL.OPEN_NEW.AVAL]]
rem --- Skip if not changed
open_new$=callpoint!.getUserInput()
if open_new$=callpoint!.getColumnData("OPR_OPNORDDETAIL.OPEN_new") then break

rem --- Enable/disable Shipped Orders checkbox
if open_new$="Y" then
	rem --- Check and disable Shipped Orders when New Orders is checked
	callpoint!.setColumnEnabled("OPR_OPNORDDETAIL.OPEN_SHIPPED",0)
	callpoint!.setColumnData("OPR_OPNORDDETAIL.OPEN_SHIPPED","Y",1)
else
	rem --- Unheck and enable Shipped Orders when New Orders is NOT checked
	callpoint!.setColumnEnabled("OPR_OPNORDDETAIL.OPEN_SHIPPED",1)
	callpoint!.setColumnData("OPR_OPNORDDETAIL.OPEN_SHIPPED","N",1)
endif

rem --- Enable/disable Open Orders' Non-Stock Options ListButton
open_back$=callpoint!.getColumnData("OPR_OPNORDDETAIL.OPEN_BACK")
open_hold$=callpoint!.getColumnData("OPR_OPNORDDETAIL.OPEN_HOLD")
if open_back$="Y" or open_hold$="Y" or open_new$="Y" then
	rem --- Enable Non-Stock Options ListButton, but don't set
	callpoint!.setColumnEnabled("OPR_OPNORDDETAIL.NON_STOCK_OPTION",1)
else
	rem --- Disable and set Non-Stock Options ListButton
	callpoint!.setColumnEnabled("OPR_OPNORDDETAIL.NON_STOCK_OPTION",0)
	callpoint!.setColumnData("OPR_OPNORDDETAIL.NON_STOCK_OPTION","X",1)
endif

[[OPR_OPNORDDETAIL.QUOTED.AVAL]]
rem --- Skip if not changed
quoted$=callpoint!.getUserInput()
if quoted$=callpoint!.getColumnData("OPR_OPNORDDETAIL.QUOTED") then break

rem --- Enable/disable Quotes sub-options
if quoted$="Y" then
	rem --- Enable and check sub-options
	callpoint!.setColumnEnabled("OPR_OPNORDDETAIL.QUOTE_HOLD",1)
	callpoint!.setColumnEnabled("OPR_OPNORDDETAIL.QUOTE_NEW",1)
	callpoint!.setColumnEnabled("OPR_OPNORDDETAIL.NON_STOCK",1)
	callpoint!.setColumnEnabled("OPR_OPNORDDETAIL.QUOTE_EXPIRED",1)
	callpoint!.setColumnData("OPR_OPNORDDETAIL.QUOTE_EXPIRED","Y",1)
	callpoint!.setColumnData("OPR_OPNORDDETAIL.QUOTE_HOLD","Y",1)
	callpoint!.setColumnData("OPR_OPNORDDETAIL.QUOTE_NEW","Y",1)
	callpoint!.setColumnData("OPR_OPNORDDETAIL.NON_STOCK","Y",1)
else
	rem --- Disable and uncheck sub-options
	callpoint!.setColumnEnabled("OPR_OPNORDDETAIL.QUOTE_HOLD",0)
	callpoint!.setColumnEnabled("OPR_OPNORDDETAIL.QUOTE_NEW",0)
	callpoint!.setColumnEnabled("OPR_OPNORDDETAIL.NON_STOCK",0)
	callpoint!.setColumnEnabled("OPR_OPNORDDETAIL.QUOTE_EXPIRED",0)
	callpoint!.setColumnData("OPR_OPNORDDETAIL.QUOTE_EXPIRED","N",1)
	callpoint!.setColumnData("OPR_OPNORDDETAIL.QUOTE_HOLD","N",1)
	callpoint!.setColumnData("OPR_OPNORDDETAIL.QUOTE_NEW","N",1)
	callpoint!.setColumnData("OPR_OPNORDDETAIL.NON_STOCK","N",1)
endif

[[OPR_OPNORDDETAIL.QUOTE_HOLD.AVAL]]
rem --- Skip if not changed
quote_hold$=callpoint!.getUserInput()
if quote_hold$=callpoint!.getColumnData("OPR_OPNORDDETAIL.QUOTE_HOLD") then break

rem --- Enable/disable Quotes Non-Stock CheckBox
quote_new$=callpoint!.getColumnData("OPR_OPNORDDETAIL.QUOTE_NEW")
if quote_hold$="Y" or quote_new$="Y" then
	rem --- Enable Non-Stock CheckBox, but don't set
	callpoint!.setColumnEnabled("OPR_OPNORDDETAIL.NON_STOCK",1)
else
	rem --- Disable and set Non-Stock CheckBox
	callpoint!.setColumnEnabled("OPR_OPNORDDETAIL.NON_STOCK",0)
	callpoint!.setColumnData("OPR_OPNORDDETAIL.NON_STOCK","N",1)
endif

[[OPR_OPNORDDETAIL.QUOTE_NEW.AVAL]]
rem --- Skip if not changed
quote_new$=callpoint!.getUserInput()
if quote_new$=callpoint!.getColumnData("OPR_OPNORDDETAIL.QUOTE_NEW") then break

rem --- Enable/disable Quotes Non-Stock CheckBox
quote_hold$=callpoint!.getColumnData("OPR_OPNORDDETAIL.QUOTE_HOLD")
if quote_hold$="Y" or quote_new$="Y" then
	rem --- Enable Non-Stock CheckBox, but don't set
	callpoint!.setColumnEnabled("OPR_OPNORDDETAIL.NON_STOCK",1)
else
	rem --- Disable and set Non-Stock CheckBox
	callpoint!.setColumnEnabled("OPR_OPNORDDETAIL.NON_STOCK",0)
	callpoint!.setColumnData("OPR_OPNORDDETAIL.NON_STOCK","N",1)
endif



