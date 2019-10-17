# an09-ip-watchdog-1-of-2
PING based failure detection for 1 or 2 devices (Lua script)

source: https://www.netio-products.com/en/application-notes/an09-ip-watchdog-1-of-2-ping-based-failure-detection-for-1-or-2-devices-lua-script

AN09 demonstrates a Lua script that detects a dropped Internet connection and automatically restarts e.g. a microwave link. The script periodically sends PING (icmp) requests to the 1 or 2 configured IP addresses. When none of these two addresses respond for e.g. 60 seconds, one of the 230V sockets is turned off for 20 seconds (short off – restart).

Supported devices: NETIO 4All, NETIO PowerPDU 4C, NETIO 4

 

AN09 Ping to 1 of 2 IP addresses is a Lua script to detect lost connectivity to a specific device, or to the Internet in general (8.8.8.8 – Google’s publicly available DNS server).

 

Typical uses of NETIO AN09

 Detection of lost internet connectivity from a LAN (to restart a router / modem / link)
 Detection of a central IP printer going offline – to turn off power to certain desks in order to save energy
 Detection of an IP link failure – to autonomously activate a back-up network connection
 Restarting an unstable link without the customers experiencing any prolonged downtime or without having to physically travel to the remote site
 

How does it work?

The header of the Lua script specifies the primary and secondary IP address where the NETIO device sends the PING requests. When a reply is received from the primary or from the secondary IP address, everything is considered OK. If no reply is received for a given number of tries (missingPingAnswers, default is 10), an action is performed – typically an output is turned off for a specified time in order to restart the device connected to that output.

 

In case the reboot takes a longer time, or the problem is not in the terminal device, the firstLivingPulse = 1 parameter makes sure that the link is not restarted over and over again.

Continuous mode

To detect an unstable link (e.g. an infrared / laser link in foggy weather), set continuous = 1. In this mode, the number of failed attempts is added over a longer period, e.g. 24 hours, and the link is restarted in order to trigger its automatic calibration.

 

Creating the rule
To create and run the Lua script, do the following:

1) In the Actions section of NETIO 4 web administration, click Create Rule to add a rule.

2) Fill in the following parameters:

 Enabled: checked
 Name: Watchdog (user-defined)
 Description: Watchdog for IP device (user-defined)
 Trigger: System started up
 Schedule: Always
 
 3) copy code from this repository into the field Lua script
 
 4) To finish creating the rule, click Create Rule at the bottom of the screen.
 
 Method of operation
Using ping requests, the script monitors the accessibility of the specified IP address (primaryIP) or of the back-up IP address (secondaryIP) with the given periodicity (pingPeriod).

If the primary IP does not respond, the accessibility of secondary IP is checked (again with a ping request).

When none of the IP addresses are accessible, the counter is incremented.

As soon as the counter exceeds the specified threshold (missingPingAnswers), the specified action is performed with the selected output (controlOutput). The shortest reaction time to a dropped connection is therefore equal to missingPingAnswers * (pingPeriod + 5) seconds. (Default timeout for ping command is 5 seconds).

The action numbers correspond to those for M2M protocols:

 0 = Output switched off (Off)
 1 = Output switched on (On)
 2 = Output switched off for a short time (short Off)
 3 = Output switched on for a short time (short On)
 4 = Output switched from one state to the other (toggle)
After performing the action, the script waits for the specified time (timeoutAfterWatchdogAction) and then, according to the value of firstLivingPulse, it either activates again (firstLivingPulse = 0) or waits until a reply to a ping request is received from at least one of the IP addresses (firstLivingPulse = 1).

The continuous variable specifies whether the Watchdog looks for a total outage lasting a certain time (continuous = 1). In this case, the counter is reset after every reply received from at least one of the IP addresses. When continuous = 0, the counter is not reset and the Watchdog monitors the overall number of failures from both IP addresses (that is, for a stable link, the action can be performed e.g. after several months).

 

Setting the variables
 primaryIP
 A string containing the primary IP address.
 The address needs to be specified in the IPv4 format. To find the IP address for a given DNS name, use e.g. https://www.whatismyip.com/dns-lookup/.
 Example – for IP 192.168.101.128: primaryIP="192.168.101.128"
 secondaryIP
 A string containing the secondary IP address.
 This variable is optional. To monitor one IP address only, specify an empty string or 0.0.0.0.
 Example – for IP 192.168.101.192: secondaryIP="192.168.101.192"
 Example for monitoring the primary IP address only: secondaryIP="" or secondaryIP="0.0.0.0"
 pingPeriod
 Specifies the period (in seconds) for requesting responses.
 The time is counted from the moment of receiving a reply, not from the previous request.
 The minimum value is 1 second.
 Example – to check every 10 seconds: pingPeriod = 10
 missingPingAnswers
 Number of missing replies before the respective action is performed.
 The minimum value is 1.
 Example – for 5 missing replies: missingPingAnswers = 5
 controlOutput 
  Specifies the output to control.
  Example – to control socket 1: controlOutput= 1
 action
 Specifies the action to perform with the output.
 Actions:
  0 – output switched off
  1 – output switched on
  2 – “short off”: output is set to 0, and after a delay specified in the shortTimeMs variable, the output is set to 1
  3 – “short on”: output is set to 1, and after a delay specified in the shortTimeMs variable, the output is set to 0
  4 – “toggle”, if the output was on, it is turned off, and vice versa
  5 – the output is unchanged
 timeoutAfterWatchdogAction
 Specifies the delay in seconds after performing the action. After this delay, the Watchdog is either activated again, or starts actively waiting for a ping (see the firstLivingPulse variable).
 Example – for a 30 second delay: timeoutAfterWatchdogAction = 30
 firstLivingPulse
 Specifies whether the Watchdog is activated immediately after performing the action, or only after receiving a positive response from one of the IP addresses.
 To wait for a positive reply: firstLivingPulse = 1
 To activate immediately: firstLivingPulse = 0
 continuous
 Specifies whether to monitor outages that last at least a certain time (continuous mode), or the number of missing replies (absolute mode).
 Continuous mode: continuous = 1
 Absolute mode: continuous = 0
 shortTimeMs
  Specifies (in milliseconds) for how long is the output on or off for actions 2 or 3 respectively.
  The minimum value is 100 ms.
  Example – for 2 seconds between state changes: shortTimeMs = 2000
 

Starting the script
After configuring all the parameters and saving the script, the NETIO smart sockets device needs to be restarted. After the device reboots, the script is started and begins to periodically check the accessibility of the IP address(es) in the network.

 
