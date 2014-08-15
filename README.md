AfterShip Queue Challange Solution
----------------------------------

## Interface

Queue accepts tracking requests via Beanstalkd jobs and saves results to MongoDB.
To add a job to queue submit a job to *requests_flow* tube the following payload:

    {"type": "requests_flow",
     "payload": {"slug":   "<slug name>",
                 "number": "<tracking number>"}}

To get result reference to MongoDB *bucket* database, *tracking* collection.

## How it works
### Overview

Queue instance is called worker and can be run on different machines at the same time. In order for workers to work together they need to share common **MongoDB, Redis and Beanstalkd servers.**

 - Reach the worker code directory at lib/worker
 - Run worker by **$: ./worker.js**

### Beanstalkd Tubes

Each worker serves 2 Beanstalkd tubes:

 - requests_flow
 - wait_list

**requests_flow** tube receives user tracking requests (see Interface section above). If user request fits in workers limitations (max. 20 simultaneous calls to couriers and 2 calls per. second) it calls logic to get tracking info

    Courier[slug](tracking_number, courier_callback...)

if request falls beyond limits its tracking number is pushed to Redis *wait_list:slug_name* list and adds a job to *wait_list* tube.

**wait_list** tube aims to empty the Redis *wait_list:...* within worker limits. After being initiated it performs the following steps:

 - Check *wait_list_activated:...* flag from Redis. Sets it up if not already. Only one worker can work on specific *wait_list:...* at the same time.
 - Checks *wait_list:...* length and sets appropriate numbers of attempts to get the first element of the list *e.g.: 2 calls at 1st sec, 2 calls at 2nd sec, etc.*

The code that schedules requests:

    for sec in [1..seconds]
		for call in [1..calls_per_sec]
			setTimeout get_wait_request(slug), sec*1000


 - Schedules *wait_list* tube job (recursive call) after scheduled jobs. The tube logic would be repeated until *wait_list:...* is not empty.
 - **get_wait_request** callback calls logic to get tracking info if number of calls < 20

**Notes:**

Both *requests_flow* and *wait_list* tube handlers relies on Redis to ensure limits requirements and avoid race conditions. The following Redis keys are used:

| Redis key                | Description                                                                  |
| ------------------------ | ---------------------------------------------------------------------------- |
| wait_list:slug           | list of slug tracking numbers in chronological order                         |
| calls_number:slug        | total calls number that happens now for specific slug                        |
| sec_calls:slug           | calls number performed during 1 second period                                |
| wait_list_activated:slug | a flag to ensure that only one slug worker served waiting requests at a time |

To ensure that workers executions would not be blocked in case of previous workers failure the following expiration periods are set to each Redis keys:

| Redis key                | Expication period                                                              |
| ------------------------ | ------------------------------------------------------------------------------ |
| wait_list:slug           | no expire                                                                      |
| calls_number:slug        | 60 seconds after each new tracking number was added                            |
| sec_calls:slug           | 1 second                                                                       |
| wait_list_activated:slug | a number of seconds equals to delay of last scheduled call of *wait_list* tube |

 
