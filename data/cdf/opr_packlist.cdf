[[OPR_PACKLIST.AFMC]]
rem --- Inits
	use ::ado_util.src::util

rem --- Add static label to show when it's a reprint of the Packing List
	order_no!=fnget_control!("OPR_PACKLIST.ORDER_NO")
	order_no_x=order_no!.getX()
	order_no_y=order_no!.getY()
	order_no_height=order_no!.getHeight()
	order_no_width=order_no!.getWidth()
	label_width=75
	nxt_ctlID=util.getNextControlID()
	reprintMsg!=Form!.addStaticText(nxt_ctlID,order_no_x,order_no_y+order_no_height+5,label_width,order_no_height-6,"")
	reprintMsg!.setText("*** "+Translate!.getTranslation("AON_REPRINT")+" ***")
	reprintMsg!.setForeColor(BBjColor.RED)
	tabCtrl!=Form!.getControl(num(stbl("+NAVBAR_CTL")))
	reprintMsg!.setBackColor(tabCtrl!.getBackColor())
	reprintMsg!.setVisible(0)
	callpoint!.setDevObject("reprintMsg",reprintMsg!)

[[OPR_PACKLIST.AREC]]
rem --- Show Reprint label
if callpoint!.getDevObject("reprint_flag")="Y" then
	reprintMsg!=callpoint!.getDevObject("reprintMsg")
	reprintMsg!.setVisible(1)
endif

[[OPR_PACKLIST.<CUSTOM>]]
rem #include fnget_control.src
	def fnget_control!(ctl_name$)
	ctlContext=num(callpoint!.getTableColumnAttribute(ctl_name$,"CTLC"))
	ctlID=num(callpoint!.getTableColumnAttribute(ctl_name$,"CTLI"))
	get_control!=SysGUI!.getWindow(ctlContext).getControl(ctlID)
	return get_control!
	fnend
rem #endinclude fnget_control.src



