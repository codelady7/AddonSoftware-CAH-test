[[APX_MICRCODE.BSHO]]
myGrid!=Form!.getControl(num(stbl("+GRID_CTL")))
myFont!=SysGUI!.makeFont("MICR Encoding",14,SysGUI!.PLAIN)
myGrid!.setColumnFont(2,myFont!)
myGrid!.setEnabled(0)

rem -- build table first run
num_files=1
dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
open_tables$[1]="APX_MICRCODE",open_opts$[1]="OTA"
gosub open_tables

apm_micr_dev=num(open_chans$[1])
dim apm_micr$:open_tpls$[1]

recs=dec(fin(apm_micr_dev)(77,4))
if !recs
	character_list$="0123456789ABCD"
	descList!=BBjAPI().makeVector()
	descList!.add("Zero")
	descList!.add("One")
	descList!.add("Two")
	descList!.add("Three")
	descList!.add("Four")
	descList!.add("Five")
	descList!.add("Six")
	descList!.add("Seven")
	descList!.add("Eight")
	descList!.add("Nine")
	descList!.add("Transit Symbol")
	descList!.add("Amount Symbol")
	descList!.add("On-Us Symbol")
	descList!.add("Dash")

	for x=1 to len(character_list$)
		apm_micr.micr_char$=character_list$(x,1)
		apm_micr.micr_symbol$=character_list$(x,1)
		apm_micr.code_desc$=descList!.get(x-1)
		write record(apm_micr_dev)apm_micr$
	next x
endif



