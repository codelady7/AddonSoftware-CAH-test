[[APX_EXPORT1099.AREC]]
rem --- Set default server directory
	default_dir$=util.resolvePathStbls(stbl("+DOC_DIR_DEFAULT",err=*next))
	if default_dir$<>"" then callpoint!.setColumnData("APX_EXPORT1099.EXPORT_LOC",default_dir$)

rem --- Enable/disable client directory

	if bbjapi().getCurrentSessionInfo().getIPAddress()="127.0.0.1" then
		rem --- Running locally on the server, so disable client directory
		callpoint!.setColumnEnabled("APX_EXPORT1099.CLIENT_DIR",0)
	else
		rem --- Running remote, so enable client directory
		callpoint!.setColumnEnabled("APX_EXPORT1099.CLIENT_DIR",1)
	endif

[[APX_EXPORT1099.ASVA]]
rem --- Validate server export directory (create if needed), and confirm write access
	export_loc$=cvs(callpoint!.getColumnData("APX_EXPORT1099.EXPORT_LOC"),3)
	abort=0

	if export_loc$=""
		abort=1
	else
		export_loc!=export_loc$
		export_loc$=export_loc!.replace("\","/")

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
		callpoint!.setColumnData("APX_EXPORT1099.EXPORT_LOC", export_loc$,1)
		callpoint!.setFocus("APX_EXPORT1099.EXPORT_LOC")
		callpoint!.setStatus("ABORT")
	endif

rem --- Validate client export directory (create if needed), and confirm write access
	client_dir$=cvs(callpoint!.getColumnData("APX_EXPORT1099.CLIENT_DIR"),3)
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
		callpoint!.setColumnData("APX_EXPORT1099.CLIENT_DIR", client_dir$,1)

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
	endif

	if abort
		callpoint!.setColumnData("APX_EXPORT1099.CLIENT_DIR", client_dir$,1)
		callpoint!.setFocus("APX_EXPORT1099.CLIENT_DIR")
		callpoint!.setStatus("ABORT")
	endif

[[APX_EXPORT1099.BSHO]]
rem --- Declare Java classes used

	use java.io.File
	use ::ado_file.src::FileObject
	use ::ado_util.src::util

rem --- Get starting +USE_CLIENT_FILESYSTEM
	starting_UseClientFilesystem$=stbl("+USE_CLIENT_FILESYSTEM",err=*next)
	callpoint!.setDevObject("starting_UseClientFilesystem$",starting_UseClientFilesystem$)

[[APX_EXPORT1099.CLIENT_DIR.AINQ]]
rem --- Set +USE_CLIENT_FILESYSTEM to starting value
	starting_UseClientFilesystem$=callpoint!.getDevObject("starting_UseClientFilesystem$")
	x$=stbl("+USE_CLIENT_FILESYSTEM",starting_UseClientFilesystem$)

[[APX_EXPORT1099.CLIENT_DIR.BINQ]]
rem --- Set +USE_CLIENT_FILESYSTEM for client
	x$=stbl("+USE_CLIENT_FILESYSTEM","YES")

[[APX_EXPORT1099.EXPORT_LOC.AINQ]]
rem --- Set +USE_CLIENT_FILESYSTEM to starting value
	starting_UseClientFilesystem$=callpoint!.getDevObject("starting_UseClientFilesystem$")
	x$=stbl("+USE_CLIENT_FILESYSTEM",starting_UseClientFilesystem$)

[[APX_EXPORT1099.EXPORT_LOC.BINQ]]
rem --- Set +USE_CLIENT_FILESYSTEM for server
	x$=stbl("+USE_CLIENT_FILESYSTEM","")



