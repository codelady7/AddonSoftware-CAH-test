[[ADE_FILENAMEPATH.AFMC]]
rem --- Add static label for warning message
	file_name!=fnget_control!("ADE_FILENAMEPATH.FILE_NAME")
	file_name_x=file_name!.getX()
	file_name_y=file_name!.getY()
	file_name_height=file_name!.getHeight()
	file_name_width=file_name!.getWidth()
	label_width=file_name_width+50
	nxt_ctlID=util.getNextControlID()
	warning!=Form!.addStaticText(nxt_ctlID,file_name_x-30,file_name_y-50,label_width,file_name_height*2,"")
	warning!.setText("")
	warning!.setForeColor(BBjColor.RED)
	warning!.setBackColor(Form!.getBackColor())
	warning!.setVisible(1)
	callpoint!.setDevObject("warning",warning!)

[[ADE_FILENAMEPATH.AREC]]
rem --- Enable/disable client directory
	if bbjapi().getCurrentSessionInfo().getIPAddress()="127.0.0.1" then
		rem --- Running locally on the server, so disable client directory
		callpoint!.setColumnEnabled("ADE_FILENAMEPATH.CLIENT_DIR",0)
	else
		rem --- Running remote, so enable client directory
		callpoint!.setColumnEnabled("ADE_FILENAMEPATH.CLIENT_DIR",1)
	endif

rem --- Show security warning
	warning$=callpoint!.getColumnData("ADE_FILENAMEPATH.WARNING")
	warning!=callpoint!.getDevObject("warning")
	warning!.setText(warning$)


rem --- Initialize Group Name Space values used for Positive Pay filename and directories
	groupNS!=BBjAPI().getGroupNamespace()
	groupNS!.setValue("ADE_FILENAMEPATH.FILE_NAME",cvs(callpoint!.getColumnData("ADE_FILENAMEPATH.FILE_NAME"),3))
	groupNS!.setValue("ADE_FILENAMEPATH.EXPORT_LOC",cvs(callpoint!.getColumnData("ADE_FILENAMEPATH.EXPORT_LOC"),3))
	groupNS!.setValue("ADE_FILENAMEPATH.CLIENT_DIR",cvs(callpoint!.getColumnData("ADE_FILENAMEPATH.CLIENT_DIR"),3))

[[ADE_FILENAMEPATH.ASVA]]
rem --- Validate server export directory (create if needed), and confirm write access
	export_loc$=cvs(callpoint!.getColumnData("ADE_FILENAMEPATH.EXPORT_LOC"),3)
	abort=0

	if export_loc$=""
		abort=1
	else
		export_loc!=new File(export_loc$)
		export_loc$=export_loc!.getCanonicalPath()

		rem --- Fix path for this OS
		current_dir$=dir("")
		current_drive$=dsk("",err=*next)
		success=0
	    	FileObject.makeDirs(new File(export_loc$),err=*next);success=1
		if success
			success=0
			chdir(export_loc$),err=*next;success=1
			if success
				export_loc$=current_drive$+dir("")
				chdir(current_dir$)

				rem --- Write directory permissions are required
				if !FileObject.isDirWritable(export_loc$)
					msg_id$="AD_DIR_NOT_WRITABLE"
					dim msg_tokens$[1]
					msg_tokens$[1]=export_loc$
					gosub disp_message
					abort=1
				endif
			else
				abort=1
			endif
		else
			abort=1	
		endif
	endif

	if abort
		callpoint!.setColumnData("ADE_FILENAMEPATH.EXPORT_LOC", export_loc$,1)
		callpoint!.setFocus("ADE_FILENAMEPATH.EXPORT_LOC")
		callpoint!.setStatus("ABORT")
	endif

rem --- Verify file does not exist in server export directory
	if !abort
		file_name$=cvs(callpoint!.getColumnData("ADE_FILENAMEPATH.FILE_NAME"),3)
		if pos(export_loc$(len(export_loc$),1)="/\") then export_loc$=export_loc$(1, len(export_loc$)-1)
		serverFile! = new File(export_loc$+"/"+file_name$).getCanonicalFile()
		if serverFile!.exists() then
			msg_id$="AD_FILE_EXISTS"
			dim msg_tokens$[1]
			msg_tokens$[1]=export_loc$+"/"+file_name$
			gosub disp_message
			callpoint!.setFocus("ADE_FILENAMEPATH.FILE_NAME",1)
			callpoint!.setStatus("ABORT")
		endif
	endif

rem --- Validate client export directory (create if needed), and confirm write access
	client_dir$=cvs(callpoint!.getColumnData("ADE_FILENAMEPATH.CLIENT_DIR"),3)
	abort=0

	rem --- Client export directory is NOT required
	if client_dir$<>"" then
		rem --- Path must include drive for Windows
		if pos(":"=client_dir$)<>2 then
			current_drive$=dsk("",err=*next)
			client_dir$=current_drive$+client_dir$
		endif
		client_dir!=client_dir$
		client_dir$=client_dir!.replace("\","/")

		rem --- Make sure backend program get the updated path
		callpoint!.setColumnData("ADE_FILENAMEPATH.CLIENT_DIR", client_dir$,1)

		rem --- Does client directory exist?
		cfs! = BBjAPI().getThinClient().getClientFileSystem()
		cf!=cfs!.getClientFile(client_dir$)
		if cf!.exists() then
			rem --- Make sure client directory is a directory
			if !cf!.isDirectory()
				msg_id$="AD_BAD_DIR"
				dim msg_tokens$[1]
				msg_tokens$[1]=client_dir$
				gosub disp_message
				abort=1
			endif
		else
			rem --- Need to create client directory
			success=cf!.mkdir()
			if !success then
				msg_id$="AD_DIR_NOT_WRITABLE"
				dim msg_tokens$[1]
				msg_tokens$[1]=client_dir$
				gosub disp_message
				abort=1
			endif
		endif

		rem --- Make sure client directory is writable
		if !abort then
			cf!.setWritable(1)
			success=cf!.canWrite()
			if !success then
				msg_id$="AD_DIR_NOT_WRITABLE"
				dim msg_tokens$[1]
				msg_tokens$[1]=client_dir$
				gosub disp_message
				abort=1
			endif
		endif

		if abort
			callpoint!.setColumnData("ADE_FILENAMEPATH.CLIENT_DIR", client_dir$,1)
			callpoint!.setFocus("ADE_FILENAMEPATH.CLIENT_DIR")
			callpoint!.setStatus("ABORT")
		endif

		rem --- Verify file does not exist in client export directory
		if !abort
			file_name$=cvs(callpoint!.getColumnData("ADE_FILENAMEPATH.FILE_NAME"),3)
			sep$ = File.separator
			if pos(client_dir$(len(client_dir$),1)="/\") then client_dir$=client_dir$(1,len(client_dir$)-1)
			cfs! = BBjAPI().getThinClient().getClientFileSystem()
			clientFile!=cfs!.getClientFile(client_dir$+sep$+file_name$)
			if clientFile!.exists() then
				msg_id$="AD_FILE_EXISTS"
				dim msg_tokens$[1]
				msg_tokens$[1]=client_dir$+sep$+file_name$
				gosub disp_message
				callpoint!.setFocus("ADE_FILENAMEPATH.FILE_NAME",1)
				callpoint!.setStatus("ABORT")
			endif
		endif
	endif

rem --- Set/return Positive Pay filename and directories
	if !abort
		groupNS!=BBjAPI().getGroupNamespace()
		groupNS!.setValue("ADE_FILENAMEPATH.FILE_NAME",cvs(callpoint!.getColumnData("ADE_FILENAMEPATH.FILE_NAME"),3))
		groupNS!.setValue("ADE_FILENAMEPATH.EXPORT_LOC",cvs(callpoint!.getColumnData("ADE_FILENAMEPATH.EXPORT_LOC"),3))
		groupNS!.setValue("ADE_FILENAMEPATH.CLIENT_DIR",cvs(callpoint!.getColumnData("ADE_FILENAMEPATH.CLIENT_DIR"),3))
	endif

[[ADE_FILENAMEPATH.BSHO]]
rem --- Inits
	use java.io.File
	use ::ado_file.src::FileObject
	use ::ado_util.src::util

rem --- Get starting +USE_CLIENT_FILESYSTEM
	starting_UseClientFilesystem$=stbl("+USE_CLIENT_FILESYSTEM",err=*next)
	callpoint!.setDevObject("starting_UseClientFilesystem$",starting_UseClientFilesystem$)

[[ADE_FILENAMEPATH.CLIENT_DIR.AINQ]]
rem --- Set +USE_CLIENT_FILESYSTEM to starting value
	starting_UseClientFilesystem$=callpoint!.getDevObject("starting_UseClientFilesystem$")
	x$=stbl("+USE_CLIENT_FILESYSTEM",starting_UseClientFilesystem$)

[[ADE_FILENAMEPATH.CLIENT_DIR.BINQ]]
rem --- Set +USE_CLIENT_FILESYSTEM for client
	x$=stbl("+USE_CLIENT_FILESYSTEM","YES")

[[ADE_FILENAMEPATH.EXPORT_LOC.AINQ]]
rem --- Set +USE_CLIENT_FILESYSTEM to starting value
	starting_UseClientFilesystem$=callpoint!.getDevObject("starting_UseClientFilesystem$")
	x$=stbl("+USE_CLIENT_FILESYSTEM",starting_UseClientFilesystem$)

[[ADE_FILENAMEPATH.EXPORT_LOC.BINQ]]
rem --- Set +USE_CLIENT_FILESYSTEM for server
	x$=stbl("+USE_CLIENT_FILESYSTEM","")

[[ADE_FILENAMEPATH.<CUSTOM>]]
#include [+ADDON_LIB]std_functions.aon

rem #include fnget_control.src
	def fnget_control!(ctl_name$)
	ctlContext=num(callpoint!.getTableColumnAttribute(ctl_name$,"CTLC"))
	ctlID=num(callpoint!.getTableColumnAttribute(ctl_name$,"CTLI"))
	get_control!=SysGUI!.getWindow(ctlContext).getControl(ctlID)
	return get_control!
	fnend
rem #endinclude fnget_control.src



