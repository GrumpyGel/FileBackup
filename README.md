# FileBackup
Powershell scripts designed to provide incremental backup of directory structures (Groups) of files.


[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]
[![LinkedIn][linkedin-shield]][linkedin-url]


<!-- PROJECT LOGO -->
<br />
<p align="center">
  <a href="https://github.com/GrumpyGel/FileBackup">
    <img src="source/images/SudokuScreen_2.png" alt="Logo" width="180">
  </a>

  <p align="center">
    <a href="http://www.mydocz.com/mdzWebRequest_Test.aspx">View Demo</a>
    ·
    <a href="https://github.com/GrumpyGel/mdzWebRequest_Test/issues">Report Bug</a>
    ·
    <a href="https://github.com/GrumpyGel/mdzWebRequest_Test/issues">Request Feature</a>
  </p>
</p>



<!-- TABLE OF CONTENTS -->
<details open="open">
  <summary><h2 style="display: inline-block">Table of Contents</h2></summary>
  <ol>
    <li><a href="#about-the-project">About The Project</a></li>
    <li><a href="#installation--usage">Installation &amp; Usage</a></li>
    <li><a href="#documentation">Documentation</a></li>
    <li><a href="#documentation">Security</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgements">Acknowledgements</a></li>
  </ol>
</details>



<!-- ABOUT THE PROJECT -->
## About The Project

The FileBackup routines are Powershell scripts designed to provide incremental backup of directory structures (Groups) of files.

Backup files are created as Compressed (Zipped) folders containing any changed files, a directory Log at the time the backup was taken and a Difference file listing newly created or deleted Directories and newly created, modified or deleted Files.

The backups are created on the same server (unless using mapped drives) but also have an Ftp option to transfer the backups to a remote server.

The directory Log from the most recent Backup is used to determine changes needed to be included in the current Backup. A Log must be manually created to initiate the then incremental BackUp.

The routines also include an Unpack facility that takes Backup files and extracts changes to a duplicate Group directory structure. This provides a complete ready-to-use directory structure ideally on another hard drive/server using mapped drives or Ftp.


<!-- GETTING STARTED -->

## Installation & Usage

Clone the repo
   ```sh
   git clone https://github.com/GrumpyGel/FileBackup.git
   ```


<!-- DOCUMENTATION -->
## Documentation

### Terms

Terms used in this documentation are as follows:

| Term | Description |
| --- | --- |
| Group | The Group of files to be BackedUp. The Group has a Path (directory) that contain the files. |
| Duplicate | A directory FileBackup (Unpack) will replicate the Group's content into. |
| Log file | A Log file containing directory listing of a Group. |
| Differences file | A Differences file listing changes to directories and files between 2 (previous and current) Log files. |
| BackUp | The BackUp file, compressed (zip) archive containing new or modified files plus Log and Differences file for this Backup. BackUp also refers to the process of creating a BackUp. |
| Unpack | The process of taking a BackUp file and extracting its content into the Duplicate. |
| Verify | The process of comparing the Duplicate content against a BackUp Log file. |
| Store | A directory used by FileBackup to Store Backup files. The BackUp files contain the Group and timestamp in the filename and can accumulate in the Store for all Groups. |
| Archive | A directory Unpack will create where deleted directories and deleted or update files from the Duplicate are moved to when Unpacking. This enables a roll back should it be required. |
| ArchiveStore | A directory where Unpack will create Archives. Each Group should have its own ArchiveStore. |

### Backup

The Backup component of the FileBackup routines contains the following scripts..

| Script | Description |
| --- | --- |
| FileLog.ps1 | This reads a directory structure and produces a Log file of all directories and files. The log contains the size and last modified date for files. |
| FileLogCompare.ps1 | This reads 2 Log files and produces a Differences file. |
| FileBackup.ps1 | This can be run manually or on a task scheduler to BackUp a Group. It can optionally upload the Backup to an Ftp server. |
| FileBackupBatch.ps1 | Using a configuration file, this can be run manually or on a task scheduler to BackUp multiple Groups. |

#### FileLog.ps1

The FileLog script captures the Group's directory content producing a Log file of all directories and files. The log contains the size and last modified date for files. FileLog is mainly used from within other scripts, however, it must also be run manually when setting up a Group to be backed up - see "Tutorial" for more information. Parameters:

| Parameter | Description |
| --- | --- |
| -Path | The Group directory to Log. Example "E:\\MyDocz\\FileBackup\\TestGroup\\Live" |
| -LogFile | Name of the Log file to create. If not supplied output is displayed to console. Example "Backup_TestGroup_Initial.log" |
| -Ignore | List of directories to ignore in the backup. The directories should be relative to -Path. directories should be separated by ';'. Example "Temp;Work\\Old;Work\\Temp" |

Ouput is a text file with each line representing a directory or file. Similar to CSV file, the data components are separated by '\*' (as this can not appear in a file name). The first field (always a single character field) shows what type of line it is, as follows:

| Type | Description |
| --- | --- |
| I\* | If included, this will be the first line in the file. The 2nd (and only other) field on the line will contain the Ignore parameter value used when creating the Log. Example "I*Temp;Work\Old;Work\Temp". |
| D\* | Represents a Directory. The 2nd (and only other) field on the line will contain the Directory name. The name is relative to the Group directory. The Group Directory is included, with a blank name, and will be the first line in the file or 2nd if an Ignore record is present. Example "D\*Images". |
| F\* | Represents a File. There are 3 following fields being the Name, Size and Last Write Time. Example "F\*Logo.jpg\*54321\*20210306115426". |

The Directory is listed first, all files in the directory are then listed. Subdirectories are then recursed. Directories and Files within them are listed in alphabetic order.

Main functionality of FileLog is via recursive calls to the CreateLog_Directory function. This add the directory name and all its files to the log, then calls CreateLog_Directory again for all its subdirectories. Log content is buffered into a string and then output once all files are added. This is to improve performance as the cmdlet is used to create the Log file rather than a stream.

#### FileLogCompare.ps1

The FileLogCompare script reads 2 Log files and produces a Differences file. FileLogCompare is used from within the FileBackup script and need not be run manually. Parameters:

| Parameter | Description |
| --- | --- |
| -OldLog | The name of the older/previous Log file. This is the name of the Log file created during the last Backup, or the initial manually created Log for the first time a Backup is created. Example "E:\\MyDocz\\FileBackup\\Store\\Backup_TestGroup_Initial.log". |
| -OldBackup | If the old Log file is contained within a Backup zip file, the OldBaxckup parameter should be used instead of OldLog and should contain the name of the previous Backup file. FileLogCompare will read the old Log file from within the Zip. Example "E:\\MyDocz\\FileBackup\\Store\\Backup_TestGroup_20210306.zip". |
| -NewLog | The name of the newer/current Log file created during this Backup. Example "E:\\MyDocz\\FileBackup\\Store\\Backup_TestGroup_20210306.log". |
| -LogFile | Name of the Difference file to create. If not supplied output is displayed to console. Example "Backup_TestGroup_20210306.dif" |

A file is deemed modified if the size if different or the modified timestamp is more than 3 seconds different. An exact match in timestamps is not required as moving files can truncate the milliseconds of the timestamp which results in seconds being rounded differently.

FileLogCompare does not detect renamed or moved files or directories. If items are renamed or moved, their old name/location will be listed as deleted and current location as new.

Ouput is a text file with each line representing a new or deleted directory or a new, modified or deleted file. Similar to CSV file, the data components are separated by '\*' (as this can not appear in a file name). The fields are change type, object type and name. Change type can be "N"ew, "M"odified (files only) or "D"eleted. The object type can be "D"irectory or "File". The name is the directory or file name relative to the Group path. Examples:

| Example | Meaning |
| --- | --- |
| N\*D\*Images\\Template | New directory named "Images\\Template". |
| D\*D\*Survey | Directory Survey has been deleted. |
| N\*F\*Images\\Template\\Logo.jpg | New file created called Logo.jpg in the Images\\Template directory. |
| M\*F\*Data\\Settings.xml | The file called Settings.xml in the Data directory has been modified. |
| D\*F\*APP_CODE\\clsQuery.cs | The file called clsQuery.cs in the APP_CODE directory has been deleted. |

As FileLogCompare is written to support pre class enabled Powershell. The Old and New Logs are represented internally by Hashtables converted to Objects. Functionality is performed by various Log_* functions that operate on these arrays. They are:

| Function | Description |
| --- | --- |
| Log_Open | Opens the Log as a .Net StreamReader and reads the first line. |
| Log_Clear | Removed record of input Log directory and file. |
| Log_Read | Reads the next line from a Log and populates the array with details of the director or file. |
| Log_Close | Closes a Log. |
| Log_Output | Adds a Difference to the buffered output. |
| Log_ShowOutput | Outputs any buffered content. |
| Log_Compare | Main routine to compare Logs. It is repetetively called from the main script code until both New and Old Logs have been completely read and closed. Once comparisons are made the function will skip necessary lines in the Logs, for example if a folder is deleted that folder (from the Old Log) is recorded as a difference and all files within it skipped. |

#### FileBackup.ps1

FileBackup is a script that uses FileLog and FileLogCompare to package altered files and directories into a compressed zip Backup. Optionaly, the created Backup can be uploaded to an Ftp server. Parameters:

| Parameter | Description |
| --- | --- |
| -Store | Path to the directory used as the Store for Backups. Example "E:\\MyDocz\\FileBackup\\Store". |
| -Name | The name of the Group to be backed up. The only real importance of the name is for use in Backup filenames so that it is identified what the Backup relates to. For example a name of "TestGroup" creates Backup files named "Backup_TestGroup_{timestamp}.zip", Log files named "Backup_TestGroup_{timestamp}.log" and Difference files named "Backup_TestGroup_{timestamp}.dif". |
| -Path | The directory containing the Group's files. Example "E:\\MyDocz\\FileBackup\\TestGroup\\Live". |
| -FtpHost | The host name (or IP Address) of the server to upload the Backup file. This is optional, if no FtpHost is specified, the Backup will not be uploaded to an Ftp server. |
| -FtpUser | If uploading the file, this parameter must be supplied with the login user name. |
| -FtpPassword | If uploading the file, this parameter must be supplied with the login password. |
| -FtpPath | If uploading the file, this parameter may be supplied as the path on the server to upload the Backup to. If not supplied the Backup will be uploaded into the Ftp server's root directory. |
| -Ignore | List of directories to ignore in the Backup. The directories should be relative to -Path. Directories should be separated by ';'. Example "Temp;Work\\Old;Work\\Temp" |
 
The first function of FileBackup is to identify the Log file conmtained within the most recent BackUp. If no previous BackUps are found, FileBackup will use and compare against a Log file named "Backup_{Group}_Initial.log in the Store directory. This Log must be created manually, using the FileLog script, before the first BackUp is performed.

It then calls FileLog to create a Log for this Backup. It then calls FileLogCompare to create a Difference file between the most recent and current Log files.

It then creates the compressed zip Backup file and adds the current Log and Difference files into it. It then reads through the Differences file and the New or Modified files are added to the Backup.

Up until the Backup file has been completed, the Log, Differences and Backup files are created under temporary names. This is performed so that if the process fails, they will not be picked up by subsequent backups which would result in its changes being lost. Only once the Backup has been successfully created is it renamed to its correct name. If the process fails for any reason, the script will try and remove all the temporary named files. Only once the Backup has been successfully created, and uploaded to the FTP server (if specified) will the Backup file name named appropriately. The new Log and Differences files are not retained as individual files, they are only retained within the Backup file.

If the previous Log file used was the Initial file, once the BackUp is complete, this file is renamed to Backup_{Group}_Original.log. This is to ensure it is not inadvertantly picked up subsequently on failed runs.

If the FtpHost is specified, the Backup will then be uploaded to this server.

FileBackup will make 1 of the following console output messages:

```FileBackup: {Group} No changes to files
FileBackup: {Group} Backup complete {BackUpFilename}
FileBackup: {Group} Backup complete and uploaded {BackUpFilename}
```

#### FileBackupBatch.ps1

FileBackupBatch is a script that takes input from a configuration file to repeatedly call FileBackup to BackUp multiple Groups. Parameters:

| Parameter | Description |
| --- | --- |
| -Config | Name of the Config file to use. This is optional and if not specified, the file "FileBackupBatch.cfg" in the directory the scripts are installed will be used. Example "E:\\MyDocz\\FileBackup\\Bin\\FileBackupBatch.cfg". |
 
The Config file is a text file in the format of an '.ini' file. Each line should have an Item and Value pair separated by "=". Possible Items are as follows:

| Item | Description |
| --- | --- |
| Store | Path to the directory used as the Store for Backups. This is passed as the Store parameter to FileBackUp. If different BackUps are to use different Stores, multiple Store lines can appear in the Config, the most recent in order will be used. |
| Ftp | This specifies the Ftp options when calling FileBackup. A value of "None" indicates no Ftp transfer should be made. If an Ftp transfer should be made, the value should be in the format "FtpHost\*FtpUser\*FtpPassword\*FtpPath". Values need to be separated by "\*" characters. This item is optional and if not specified, BackUps created will not be uploaded to an Ftp server. If different BackUps are to use Ftp transfers, multiple Ftp lines can appear in the Config, the most recent in order will be used. |
| Email | (Optional) If specified the summary produced by FileBackupBatch is also emailed to the specified address. The value should be specified as "From\*To\*SmtpServer". Values need to be separated by "\*" characters and represent the From Address, To Address and SMTP Server name. Only 1 Email setting is allowed in the Config file and it must come before the first Group setting. |
| EmailCredentials | (Optional) If the Email setting is used, this may be included to set authentication for SMTP server in the format "User\*Password". If this is not set, the email will be sent unauthenticated. |
| EmailSSLPort | (Optional) If the Email setting is used, if this may be included to specify a SSL connection and the value is the Port Number to use. If this is not set an unencrypted connection to the server will be made on Port 25. Ensure the SMTPServer in the 'Email' setting is the name used in the SSL certificate, this is particularly appropriate if you run your own email server locally which you may address differently in normal use. |
| Group | This specifies a Group to BackUp. The value should be in the format "Name\*Path\*Ignore" specifying the Name, Path and Ignore parameters passed to FileBackup The Ignore value is optional. Multiple Group lines may be included in the Config file. |

The Config file is processed sequentially. Therefore Store, Ftp and Email settings should be included in the Config file before Group lines. A sample Config file is as follows:

```Store=E:\\MyDocz\\FileBackup\\Store
Ftp=backup/mydocz.com\*BackupUser\*BackupPwd\*FileBackupStore
Email=admin@mydocz.com\*admin@mydocz.com\*services.mydocz.com
EmailCredentials = admin@mydocz.com\*AdminPwd
EmailSSLPort = 587
Group=TestGroup\*E:\\MyDocz\\FileBackup\\TestGroup\\Live\*Temp;Work\\Old;Work\\Temp
```

FileBackupBatch passes through the console output from FileBackup and completes output with the line "FileBackupBatch: Process complete". This can also be captured and once processing is complete, emailed to the address specified in the Config file. If a call to FileBackup throws an exception, the message from this exception is displayed as console output but does not terminate the FileBackupBatch process, it will continue to process any subsequent Groups in the Config file.

If an exception occurs within the FileBackupBatch process itself, the summary as at that point will be emailed with the exception's message and the process will terminate at that point throwing the exception.


### Response Properties

| Property | DataType | Description |
| --- | --- | --- |
| ErrNo | int | An error code that may be from mdzWebRequest or culr if using the proxy, see below |
| ErrMsg | string | An error code that may be from mdzWebRequest or culr if using the proxy, see below |
| ResponseCode | HttpStatusCode | The response status code returned by the server - see [https://docs.microsoft.com/en-us/dotnet/api/system.net.httpstatuscode?view](https://docs.microsoft.com/en-us/dotnet/api/system.net.httpstatuscode) |
| ResponseType | string | The response Mine Content Type.  Any parameters following the Content type in the header supplied by the server are stripped, for example "text/html; charset=utf-8" will return just "text/html" |
| ResponseTypeParams | string | Any parameters following the Content Type, for example "text/html; charset=utf-8" will return "charset=utf-8" |
| IsBinary | bool | If True, the response has been treated as Binary and is therefore provided in the ResponseBinary property.  If False the response is treated as Text and is provided in the Response property |
| Response | string | The response data returned by the server, if the IsBinary property is False |
| ResponseBinary | byte[] | The response data returned by the server, if the IsBinary property is True |

### Error Handling

If the ErrNo property has a value of 0 after Submit() has been envoked, the requested was processed successfully.

This does not necessarily mean that the resource requested performed correctly, the ResponseCode property should also be checked for OK/200 and any other logic associated with the request performed on the Response(/Binary) data.

For direct (non-proxy) requests, other than the first 2 errors listed below, ErrNo will always return 0.  If an exception is thrown by the httpWebRequest wrapper, these are thrown back to the calling program.

For proxy requests, exceptions should be less likely as they are trapped and return the 14011 and 14013 codes listed below.  Although this may not give such high detail on the actual error, it highlights what part of the process failed and the exact message is still returned.  If an error was returned by the curl request to the server, this is returned in ErrNo.

| ErrNo | Description |
| --- | --- |
| 14001 | The URL property is blank |
| 14002 | The Method property is not "GET", "POST" or "PUT" |
| 14003 | The UseProxy property is True, but ProxyURL property is blank |
| 14004 | The request was not allowed, client IP or Host blocked , see Configuration below.  This error will also be raised if you have Host exceptionsand the supplied URL property is invalid meaning the Host could not be extracted from it. |
| 14011 | A proxy request was made, but an error was thrown communicating with the proxy, ErrMsg will include a description |
| 14012 | The ResponseCode received from the proxy request was not 200 indicating failure, ErrMsg will include the ResponseCode  |
| 14013 | An error occurred extracting the request response from the proxy response, ErrMsg will include a description |

A list of curl ErrNo codes can be found at https://curl.se/libcurl/c/libcurl-errors.html

When exceptions are raised within the mdzWebRequest class, even if they are not passed on as exception but return 14011 and 14013 error codes, the mdzSys.ErrorLog() function is called.  This can be configured to email details of the error raised and log them to a file.  These are configured within the <smpt> and <errorlog> sections of the mdzSys.config file and documented in the mdzSys.cs source.
  
### Configuration

mdzWebRequest allows for validation of allowable client IP addresses (ie browser or service client IP) and Host server names in the URL property.  The following settings are available:

| Setting | Description |
| --- | --- |
| IP_AutoAllow | A 'True' value means all client IP addresses are by default allowed, a 'False' value means no IP addresses are by default allowed |
| Host_AutoAllow | A 'True' value means all hosts are by default allowed, a 'False' value means no hosts are by default allowed |
| ValidationLog | If a log is required of validation failures, the log filename should be set here.  If the name is prefixed by a '~' character it will be created in the site directory.  If empty, no log is produced. |
| Exception | Exceptions to the IP_AutoAllow and Host_AutoAllow settings can each be made as a separate Exception.  The Exception should have a "Type" attribute of "IP" or "Host" and a "Value" attribute of the IP address/Host name that is the exception.  IP address values can be IPV4 or IPV6 and can optionally include CIDR notation for subnet mask.  IPV6 code has not been tested. |
  
Configuration settings are made in the mdzWebRequest.config file which is in XML format.  The following example only allows client connection from 127.0.0.1 and 192.168.1.* IP addresses, only allows requests to be made to www.mydocz.com and will log validation failures in a file called 'mdzWebRequest.log':
  
```
<mdzWebRequest IP_AutoAllow="False"
               Host_AutoAllow="False"
               ValidationLog="~mdzWebRequest.log">
    <Exception Type="IP"   Value="127.0.0.1"/>
    <Exception Type="IP"   Value="192.168.1.1/24"/>
    <Exception Type="Host" Value="www.mydocz.com"/>
</mdzWebRequest>
```  

Configuration is loaded by a singleton mdzWebRequestConfig class (defined in mdzWebRequest.cs).  This is loaded the first time mdzWebRequest is referenced and therefore improves performance as it does not need to be parsed for each use of mdzWebRequest.  However, once loaded it does not reload the configuration file.  Therefore if the configuration file is edited, the web site should be restarted to reload the mdzWebRequestConfig class.

### Source Files

The files comprising mdzWebRequest are as follows:
  
| Filename | Description |
| --- | --- |
| APP_CODE/mdzWebRequest.cs | The mdzWebRequest class written in c# |
| APP_CODE/mdzSys.cs | A static singleton class with various helper functions used by MyDocz code including mdzWebServices.cs |
| mdzWebRequestProxy.php | The mdzWebRequest proxy PHP program |
| mdzWebRequest_Test.aspx | A program to test mdzWebRequest as used on the MyDocz web site |
| mdzWebRequest_Test.xslt | The mdzWebRequest_Test pages HTML as a XSLT stylesheet |
| mdzWebRequest_Test.css | CSS stylesheet used by mdzWebRequest_Test pages |
| mdzWebRequest_Test.js | Javascript file used by mdzWebRequest_Test pages |
| mdzWebRequest.config | Sample configuration file for mdzWebRequest (see Configuration above) |
| mdzSys.config | Configuration file for mdzSys functions (see Error Handling above) |

<!-- SECURITY -->
## Security

 Although the mdzWebRequest class has configuration to filter IP addresses and hosts being connected to, the proxy component does not.
 
 As mdzWebRequest_Proxy.php will forward all web requests it receives, it opens up 'relay' type security issues.  It currently has no facility to deny usage based on client IP or any other criteria.

It should therefore not be installed on a publicly addressable server.

It can though be hosted on the same server as the public site, but under a different web site.  The MyDocz site hosts mdzWebRequest.php on a separate site under the domain name of mdzwr.mydocz.com.  Normally, this site would be configured so that it only allows connection from trusted IP addresses, for example IP addresses within the local network (or loopback) where mdzWebRequest is running and under the control of the application using it.

On the MyDocz site though the www.mydocz.com/mdzWebRequest_Test.aspx test page operates, which itself could be abused as a relay.  So simply restricting access to mdzwr.mydocz.com from local IPs would be pointless.  Instead the mdzwr.mydocz.com domain is also configured to only allow 2 requests per 10 seconds.  This is fine to stop abuse, and no live applications use this domain, but would not be practical in a normal live environment.


<!-- LICENSE -->
## License

Distributed under the MIT License. See `LICENSE` for more information.



<!-- CONTACT -->
## Contact

Email - [grumpygel@mydocz.com](mailto:grumpygel@mydocz.com)

Project Link: [https://github.com/GrumpyGel/FileBackup](https://github.com/GrumpyGel/FileBackup)



<!-- ACKNOWLEDGEMENTS -->
## Acknowledgements

* [Best-README-Template](https://github.com/othneildrew/Best-README-Template)




<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[contributors-shield]: https://img.shields.io/github/contributors/GrumpyGel/FileBackup.svg?style=for-the-badge
[contributors-url]: https://github.com/GrumpyGel/FileBackup/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/GrumpyGel/FileBackup.svg?style=for-the-badge
[forks-url]: https://github.com/GrumpyGel/FileBackup/network/members
[stars-shield]: https://img.shields.io/github/stars/GrumpyGel/FileBackup.svg?style=for-the-badge
[stars-url]: https://github.com/GrumpyGel/FileBackup/stargazers
[issues-shield]: https://img.shields.io/github/issues/GrumpyGel/FileBackup.svg?style=for-the-badge
[issues-url]: https://github.com/GrumpyGel/FileBackup/issues
[license-shield]: https://img.shields.io/github/license/GrumpyGel/FileBackup.svg?style=for-the-badge
[license-url]: https://github.com/GrumpyGel/FileBackup/blob/master/LICENSE.txt
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://linkedin.com/in/gerald-moull-41b5265
