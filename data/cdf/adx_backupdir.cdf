[[ADX_BACKUPDIR.AFMC]]
rem --- Inits
	use java.io.File

	ignore$ = stbl("ADX_BACKUP_DIR","")

[[ADX_BACKUPDIR.ASVA]]
rem --- Set STBL for the entered backup directory
	ignore$ = stbl("ADX_BACKUP_DIR",callpoint!.getColumnData("ADX_BACKUPDIR.DIR_BROWSE"),err=*next)

[[ADX_BACKUPDIR.DIR_BROWSE.AINV]]
rem --- Return focus to this field
	callpoint!.setFocus("ADX_BACKUPDIR.DIR_BROWSE",1)

[[ADX_BACKUPDIR.DIR_BROWSE.AVAL]]
rem --- Backup directory must already exists
	backupDir$=callpoint!.getUserInput()
	backupDir!=new File(backupDir$)
	if !backupDir!.exists() or !backupDir!.isDirectory() then
		msg_id$="AD_DIR_MISSING"
		dim msg_tokens$[1]
		msg_tokens$[1]=backupDir$
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- Remove trailing slashes (/ and \) from backup dirctory
	backupDir$=backupDir!.getCanonicalPath()
	while len(backupDir$) and pos(backupDir$(len(backupDir$),1)="/\")
		backupDir$ = backupDir$(1, len(backupDir$)-1)
	wend

rem --- Backup directory can NOT already contain data files that will be updated.
	fileExists$=""
	backupFiles$=stbl("adx_backup_files",err=*next)
	while len(backupFiles$)>0
		nextFile$=backupFiles$(1,pos(";"=backupFiles$)-1)

		thisFile!=new File(backupDir$+"/"+backupFiles$(1,pos(";"=backupFiles$)-1))
		if thisFile!.exists() then
			fileExists!=thisFile!
			break
		endif
		backupFiles$=backupFiles$(pos(";"=backupFiles$)+1)
	wend
	if fileExists!<>null() then
		msg_id$="GL_BCKUP_FILE_EXISTS"
		dim msg_tokens$[1]
		msg_tokens$[1]=fileExists!.getCanonicalPath()
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- Use canonical path
	callpoint!.setUserInput(backupDir$)

[[ADX_BACKUPDIR.DIR_BROWSE.BINP]]
rem --- Re-initialize to clear previous entry.
	callpoint!.setColumnData("ADX_BACKUPDIR.DIR_BROWSE","")
	ignore$ = stbl("ADX_BACKUP_DIR","")



