------------NETIO AN09------------
 
------------Section 1------------
local primaryIP = "192.168.101.120" -- primary IP address for ping verification
local secondaryIP = "192.168.101.185" -- secondary IP address for ping verification (for watching only one IP use "" or "0.0.0.0"
local pingPeriod = 5 -- period between ping requests [s]
local missingPingAnswers = 5 -- max missing pings (shortest reaction time: pingPeriod * missingPingAnswers = 5 * 10 = 50s
local controlOutput = 1  -- select output (1 - 4)
local action = 2 -- action type (0 - turn off, 1 - turn on, 2 - short Off, 3 - short On,4 - toggle, 5 - do nothing)
local timeoutAfterWatchdogAction = 60 -- time to activate watchdog again after action [s], 0 = no waiting
local firstLivingPulse = 1 -- 1 = Watchdog function is activated after recieved ping answer (0/1)
local continuous = 0 -- absolute/continuous mode (0/1) (more in NETIO AN09)
local shortTimeMs = 2000 -- time used in states 2 and 3 [ms]
 
---------End of Section 1---------
 
local counter = 0
local hasSecondary = true
 
 
-- Setting "output" to state defined in variable "action"
function setOutput_wds1(output,action)
  if action == 0 then -- turn off
    devices.system.SetOut{output = output, value = false}
  elseif action == 1 then -- turn on
    devices.system.SetOut{output = output, value = true}
  elseif action == 2 then -- short off
    devices.system.SetOut{output = output, value = false}
    milliDelay(shortTimeMs,function() short_wds1(output,true) end)
  elseif action == 3 then -- short on
    devices.system.SetOut{output = output, value = true}
    milliDelay(shortTimeMs,function() short_wds1(output,false) end)   
  elseif action == 4 then -- toggle
    if devices.system["output" ..output.. "_state"] == 'on' then
      devices.system.SetOut{output=output,value=false}
    else
      devices.system.SetOut{output=output, value=true}
    end
  elseif action == 5 then
    -- do nothing
  end
end
 
 
function short_wds1(output,state)
  devices.system.SetOut{output=output,value=state}
end
 
 
-- Incrementing counter and if counter exceeds "missingPingAnswers", it is set to 0 and function doAction is called
function incrementCounter_wds1()
  counter = counter + 1
  logf("Both IP addresses do not respond. Incrementing counter. Missing ping %d/%d", counter,missingPingAnswers)
  if counter >= missingPingAnswers then
    counter = 0
    doAction_wds1()
  else
    delay(pingPeriod,function() pingDevice_wds1() end)
  end
end 
 
 
-- Executes action and after delay activates Watchdog again or calls function pingWait
function doAction_wds1()
  logf("Executing action %d with output %d", action, controlOutput)
  setOutput_wds1(controlOutput,action)
  if (toboolean(firstLivingPulse) or (not toboolean(timeoutAfterWatchdogAction))) then
    delay(timeoutAfterWatchdogAction,function() pingWait_wds1() end)  
  else
    delay(timeoutAfterWatchdogAction,function() pingDevice_wds1() end)
    delay(timeoutAfterWatchdogAction,function() log("Turning Watchdog on") end)
  end
end 
 
 
-- Waits for positive ping answer and then activates Watchdog again
function pingWait_wds1()
  ping{address=primaryIP, timeout=5, callback=function(o)
    if o.success then
      logf("Ping on IP %s OK. Turning watchdog on", primaryIP)
      pingDevice_wds1()
    else
      if hasSecondary then
        ping{address=secondaryIP, timeout=5, callback=function(p)
          if p.success then
            logf("Ping on IP %s OK. Turning watchdog on", secondaryIP)
            pingDevice_wds1()
          else
            delay(pingPeriod,function() pingWait_wds1() end)  
          end
        end
        }
      else
        delay(pingPeriod,function() pingWait_wds1() end)
      end
    end 
  end
  }
end
 
 
-- Check if primary IP is responding
function checkPrimary_wds1(o)
  if o.success then
    if toboolean(continuous) then
      counter = 0 
    end
    delay(pingPeriod,function() pingDevice_wds1() end)
  else
    logf("Ping on IP %s failed", primaryIP)
    if hasSecondary then
      ping{address=secondaryIP, timeout=5, callback=checkSecondary_wds1}
    else
      incrementCounter_wds1()
    end
  end
end
 
 
-- Check if secondary IP is responding
function checkSecondary_wds1(o)
  if o.success then
    if toboolean(continuous) then
      counter = 0 
    end
    delay(pingPeriod,function() pingDevice_wds1() end)
  else
    logf("Ping attempt on secondary IP %s failed", secondaryIP)
    incrementCounter_wds1()
  end
end 
 
 
-- Ping on primary IP --> starts Watchdog
function pingDevice_wds1()
  ping{address=primaryIP, timeout=5, callback=checkPrimary_wds1}
end
 
 
-- Detects whether secondary IP is used
function validateSecondaryIP_wds1()
  if secondaryIP == "0.0.0.0" or not toboolean(secondaryIP) then
    hasSecondary = false
  end 
end
 
------------Section delta------------
--[[
local resetTime = 86400 -- counter restart period [s]
function resetCounter_wds1()
  counter = 0
  logf("Counter restarted after %d", resetTime)
  delay(resetTime,function() resetCounter_wds1() end)
end
resetCounter_wds1()
]]--
---------End of Section delta---------
 
log("Watchdog script started")
validateSecondaryIP_wds1()
pingDevice_wds1()
