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

### Request Properties

| Property | DataType | Description |
| --- | --- | --- |
| URL | string | The URL for the service you wish to request |
| Method | string | The request method, must be "GET", "POST" or "PUT". |
| Content | string | Any data to post |
| ContentType | string | Mime type for data to be posted, fopr example "application/x-www-form-urlencoded", "text/xml; encoding='utf-8'" |
| UserName | string | If authentification is required, the UserName |
| Password | string | If authentification is required, the Password |
| ExpectedFormat | string | The response can be returned as a string or binary (btye[]), see below for options |
| MaxBinarySize | int | If the response is Binary, this is the maximum allowable size |
| UseProxy | bool | If false, the request will be made using a httpWebRequest object, if True the request will be made via the mdzWebRequest_Proxy.php |
| ProxyURL | string | URL to access to proxy. |
| ProxyUserName | string | If authentification is required to access the proxy, the UserName |
| ProxyPassword | string | If authentification is required to access the proxy, the Password |

#### Expectedformat

The ExpectedFormat property may be set to one of the following:

| Value | Description |
| --- | --- |
| Text | The response is expected to be Text and will be returned in the Response property as a string, only use when safe to do so |
| Binary | The response is expected to be Binary and will be returned in the ResponseBinary property as a byte[] |
| Detect (Default) | When ResponseType is "text/*", "application/xhtml+xml", "application/xml" or "application/json" it will be processed as Text, otherwise it will be processed as Binary |

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
