# Getting Started
The **Log4PowerShell** logging module provides a framework for creating log statements within PowerShell scripts, modules, and classes.  It is configured at runtime via a JSON configuration file that allows a user to tailor the logging system to send log messages to a number of different types of message endpoints.  Currently, the following types of endpoints are supported:

* Text files.
* CSV files.
* Google Chat channels.

The configuration supports the creation of any number of endpoints, as well as customizing the log message output and format to each endpoint.  The following section describes the configuration file in more detail

## JSON Configuration File
As already mentioned, the Log4PowerShell logging framework is configured by a JSON file passed into the logging framework when it's started.  The configuration file has two main sections: one for the configuration of console output, and the other for the definition of all the message endpoints (referred to as appenders) that will be used when the framework is started.  The following is an example of a valid configuration JSON file:

```json
{
	"console" : {
		"enabled"     : true,
		"datePattern" : "yyyy-MM-dd HH:mm:ss.fff",
		"logLevel"       : "DEBUG"
	},
	"appenders" : [ {
			"type"              : "CSV",
			"name"              : "csv1",
			"datePattern"       : "yyyy-MM-dd HH:mm:ss.fff",
			"headers"	        : "vCenter,Datacenter,Cluster,ResourcePool",
			"valuesMandatory"   : false,
			"path"              : "C:/logs",
			"fileName"          : "csv-log.csv",
			"append"            : true,
			"rollingPolicy"     : "none",
			"logLevel"          : "DEBUG"
		}, {
			"type"              : "File",
			"name"              : "fileLogger1",
			"path"              : "C:/Users/EdwardBlackwell/Documents/logs",
			"fileName"          : "file-%d{MM-dd-yyyy-HH-mm-ss}.log",
			"append"            : true,
			"rollingPolicy"     : "size",
			"rollingFileSize"   : "10Mb",
			"rollingFileNumber" : 5,
			"datePattern"       : "yyyy-MM-dd HH:mm:ss.fff",
			"logLevel"          : "DEBUG"
		}, {
			"type"              : "GoogleChat",
			"name"              : "googleChat1",
			"webhookUrl"        : "https://chat.googleapis.com/v1/spaces/AAQA_2ChzVa/messages?key=AIzaSyDdI0E9vHpvySjMm-WEfRq3CPzqKqqsHI&token=B4hawzNnqxiS_E5vpvFgU3cdMXFND6KGvTv5BEV2PQ",
			"datePattern"       : "yyyy-MM-dd HH:mm:ss.fff",
			"logLevel"          : "DEBUG",
			"maxRetryAttempts"  : 10,
			"retryInterval"     : 10,
			"batchConfig"       : {
				"batchInterval"    : 5,
				"maxBatchSize"     : 50,
				"maxMessageLength" : 500
			}
		}
	]
}
```

### The `console` section
The `console` section of the JSON file configures the console output for logging statements passed into the logging framework from applications utilizing the logging framework.  The following parameters are available:

| Name          | Description |
| ------------- | ----------- |
| `enable`      | A boolean flag indicating whether or not logging statements will be echoes to the current console. |
| `datePattern` | The date format string to use when formatting the timestamp for each log message echoed to the current console. |
| `logLevel`    | The logging level to compare log statements to when determining if the log statements are echoed to the current console or not. |

### The `appenders` section
The `appenders` section of the JSON file configures the log message endpoints for logging statements handled by the logging framework.  There are three current types of appenders that can be configured within the JSON file.  They are:

| Name         | Description |
| ------------ | ----------- |
| `File`       | Configures and sends log messages to a text file. |
| `CSV`        | Configures and sends log messages to a CSV file. |
| `GoogleChat` | Configures and sends log messages to a Google Chat channel. |

### The File Appender
The `file` appender sends log messages to a specific text file.  The following parameters are available:

| Name         | Description |
| ------------ | ----------- |
| `type` | Must be set to `File` |
| `name` | A unique name to give the appender. |
| `path` | The directory path where the generated log file(s) will be created. |
| `fileName` | The name of the log file to send log messages to.  The name string can have a date pattern in it bounded by the characters `d{<date pattern>}`.  This allows for the generation of unique names.  For example, the string `"file-%d{MM-dd-yyyy-HH-mm-ss}.log"` is a valid log file name pattern. |
| `append` | A boolean value that tells the appender to either append or not append the log messages to the current version of the log file specified by the `fileName` parameter. |
| `datePattern` | The date string pattern to use when formatting the timestamp portion of a generated log message. |
| `logLevel` | The logging level to use when determining whether or not log messages are added to the log file. |
| `rollingPolicy` | Specifies the type of rolling file policy to apply to the log file.  If this parameter is not specified or set to `none`, then the rolling file functionality will not be triggered.  Current values for the policy are:  `none`, `minute`, `hourly`, `daily`, `weekly`, and `size`. |
| `rollingFileSize` | If the `rollingPolicy` parameter is set to `size`, and the current log file's size reaches the size set for this parameter, then a new log file is started.  Specific byte numbers can be specified, or terms such as `10Mb` or `5Gb` can be listed as well. |
| `rollingFileNumber` | The number of rolling files to maintain should a rolling policy be specified. |

### The CSV Appender
The `csv` appender sends log messages to a specific CSV file.  The following parameters are available:

| Name         | Description |
| ------------ | ----------- |
| `type` | Must be set to `CSV` |
| `name` | A unique name to give the appender. |
| `path` | The directory path where the generated log file(s) will be created. |
| `fileName` | The name of the log file to send log messages to.  The name string can have a date pattern in it bounded by the characters `d{<date pattern>}`.  This allows for the generation of unique names.  For example, the string `"file-%d{MM-dd-yyyy-HH-mm-ss}.log"` is a valid log file name pattern. |
| `append` | A boolean value that tells the appender to either append or not append the log messages to the current version of the log file specified by the `fileName` parameter. |
| `datePattern` | The date string pattern to use when formatting the timestamp portion of a generated log message. |
| `logLevel` | The logging level to use when determining whether or not log messages are added to the log file. |
| `headers` | A comma-separated list of strings that are parsed into the headers for the columns within the CSV file.  The order of the headers are in the order added to the CSV file. |
| `valuesMandatory` | If this boolean parameters is set to `true`, then log messages sent to this appender must have ALL the parameters listed in the headers list in order to be added to the CSV file. |
| `rollingPolicy` | Specifies the type of rolling file policy to apply to the log file.  If this parameter is not specified or set to `none`, then the rolling file functionality will not be triggered.  Current values for the policy are:  `none`, `minute`, `hourly`, `daily`, `weekly`, and `size`. |
| `rollingFileSize` | If the `rollingPolicy` parameter is set to `size`, and the current log file's size reaches the size set for this parameter, then a new log file is started.  Specific byte numbers can be specified, or terms such as `10Mb` or `5Gb` can be listed as well. |
| `rollingFileNumber` | The number of rolling files to maintain should a rolling policy be specified. |

### The Google Chat Appender
The `googleChat` appender sends log messages to a specific Google Chat channel.  The following parameters are available:

| Name         | Description |
| ------------ | ----------- |
| `type` | Must be set to `GoogleChat` |
| `name` | A unique name to give the appender. |
| `path` | The directory path where the generated log file(s) will be created. |
| `datePattern` | The date string pattern to use when formatting the timestamp portion of a generated log message. |
| `logLevel` | The logging level to use when determining whether or not log messages are added to the log file. |
| `webhookUrl` | The webhook URL for the Google Chat channel that log messages will be sent to. |
| `maxRetryAttempts` | The number of attempts to make when previous attempts to send the log message to the Google Chat channel fails. |
| `retryInterval` | The amount of time to wait between attempts to send the log message. |

### Log Message Batching
If an appender might take a while to process or send a message to whatever endpoint is configured for it, then it might be necessary to batch together log messages and send them all at once, which can cut down on the number of times an appender receives individual messages.  A good example of an appender where this might be necessary is the Google Chat appender as it makes a REST call to the Google Chat channel when sending a log message, but all appenders can receive batching configuration.  In order to configure an appender to batch log messages add a `batchConfig` section to the appender configuration.  The following JSON configuration is an example using batching:

```json
{
	"type"              : "GoogleChat",
	"name"              : "googleChat1",
	"webhookUrl"        : "https://chat.googleapis.com/v1/spaces/AAQA_2CyzVs/messages?key=AIzaSyDdI0hCZtE6vySjMm-WEfRq3CPzqKqqsHI&token=B4hawzNnqxiS_E5vpvFgZ0l5TlXFND6KGvTv5BEV2PQ",
	"datePattern"       : "yyyy-MM-dd HH:mm:ss.fff",
	"logLevel"          : "DEBUG",
	"maxRetryAttempts"  : 10,
	"retryInterval"     : 10,
	"batchConfig"       : {
		"batchInterval"    : 5,
		"maxBatchSize"     : 50,
		"maxMessageLength" : 500
	}
}
```

<add table explaining batch parameters>

## Start-Logging.ps1
The Start-Logging.ps1 script is the script used to start the logging system.  It creates an instance of the **Logger** class, and stores it into the global scope.  The following sequence digram outlines the actual steps involved when the script is executed.

```mermaid
sequenceDiagram
    actor SU as Script User
    participant LOG as Logger
    participant LC as loggingConfig
    participant LT as LoggingThread

    SU->>+LOG: Logger(ConfigFile)
        alt Console enabled
            LOG->>+LOG: ConsoleEnabled = true
            LOG-->>-LOG: return
            LOG->>+LC: Get the console log level
            LC-->>-LOG: return
            LOG->>+LC: Get the console date pattern
            LC-->>-LOG: return
        end
        LOG->>+LT: LoggingThread(AppenderConfig)
        LT-->>-LOG: return
    LOG-->>-SU: return
```

# Architecture

The **Log4PowerShell** logging framework places each endpoint processing object into its own PowerShell JobThread object, and uses a ConcurrentQueue within each thread object to send log messages to the endpoint processing object for processing.  The following class diagram outlines the objects used within the framework:

![Class Diagram](./doc/Class_Diagram_1.jpeg "Class Diagram")

In addition to the core classes, there are a number of supporting, stand-alone cmdlets used to simplify the configuration, initialization, and use of the logging framework.  Each cmdlet is stored within its own .ps1 script file located within the **public** directory of this project.

## Classes
As already mentioned, the **Log4PowerShell** logging framework is implemented using object-oriented design principles.  This section documents each class.

### LogMessage

The LogMessage class is the class that represents a logging message created and sent by a calling class into the **Log4PowerShell** logging framework.  

<img src="./doc/LogMessage_Class_Diagram.jpeg" width="35%" alt="LogMessage Class Diagram">

Each message contains the following pieces of information:

| Name          | Type     | Description |
| ------------- | -------- | ----------- |
| Timestamp     | datetime | The time at which the log message was created. |
| MessageHash   | object   | A map object that either contains the various name/value pairs that comprise the log message, or the single message represents the log message.
| LogLevel      | LogLevel | The configured loging level for the log message.  This is one of the values within the LogLevel enumeration. |
| MessageLength | int      | The number of bytes that make up the log message.  This number is derived in one of two ways.  First, if the message only contains a single message string, then the length of that string becomes the message length.  Second, if the message contains multiple name/value pairs within the message hash object, then the lengths of all names and values are combined together to arrive at the message length.  This value is used primarily for message batching functionality. |

### Logger

The Logger class is the class that is used by all external applications to perform logging.  Although an instance of this class can be created by a calling application, it is recommended to use the **Start-Logging.ps1** script located within the root directory of this application.  This script creates an instance of the Logger class, and places it within the global scope of the current PowerShell session.

<img src="./doc/Logger_Class_Diagram.jpeg" width="25%" alt="Logger Class Diagram">

The **Logger** class contains the following attributes:

| Name            | Type            | Description |
| --------------- | --------------- | ----------- |
| LoggingThreads  | LoggingThread[] | A list of the ThreadJob objects that process logging messages sent to the Logger object. |
| ConsoleLogLevel | LogLevel        | The logging level for the console output from an application utilizing the logging framework. |
| ConsolePattern  | string          | The timestamp date pattern used for log messages sent to the console. |
| ConsoleEnabled  | bool            | A flag indicating whether or not to send log messages to the console. |


### LoggingThread

[Description]

### Appender

[Description]

### FileAppender

In order to use the logging framework after the configuration has been determined and entered into the JSON file, simply run the **Start-Logging.ps1** script in the root directory of the module in order to create the main logger object from the JSON file, and load it into the global scope for the current PowerShell session.  The logger object can then be used directly from the global scope to send log messages, but it is recommended to use the utility functions in the public directory to perform logging tasks as they simplify use greatly.

## Appenders
Appenders are the class objects that are dedicated to sending log messages to a specific type of endpoint, such as a text file.  The current Appenders implemented for the logging framework are:

* CSVAppender
* FileAppender
* GoogleChatAppender

Each appender has its own specific configuration parameters defined within the JSON configuration file, and can log single log messages, or a list of log messages, which can occur when batching is configured for the Appender.

## The Configuration JSON File
By default, the logging framework looks for the JSON configuration file under the project **config** directory.  To be more specific, the logging framework looks for a file called logging.json by default.

## Starting the Logging System
To start the logging system, simply execute the **Start-Logging.ps1** script located in the root directory of this project.  This script simply creates an instance of the **Logger** class, and places it into the global scope of the current PowerShell session.

## Coding Standards
The following coding standards are adhered to for this implementation.

### Classes
Each class implemented for this framework is definied within its own module file under the **classes** directory of this project.  

#### Naming Conventions
Class names, property names, and method names follow PascalCase (e.g., MyClass, MyProperty, MyMethod).

