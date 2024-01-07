-- state that lists hosts on network

-- local Camera = require("camera")
local StateHostList = {}

local hosts = {}
local host_timer
local host_handle
local current_selection = 1

-- this is a plain array of mac's to track what I have seen
local host_macs = {}

-- local camera = Camera(320, 0)

local displayStartIndex = 1
local maxDisplayCount = 6

-- local useDatabase = false
local useActive = true
local messageWindow ={}
local messageWindowTimer = 0

local connectionsUpdateInterval = 5  -- Time in seconds between updates
local connectionsTimer = 0

   -- Load the sprite/background
local planetSprite = love.graphics.newImage("assets/planet.png")
local background = love.graphics.newImage("assets/background.png")
   -- Define the sun's position
local sunX, sunY = love.graphics.getWidth() / 2, love.graphics.getHeight() / 2
   
   -- Adjust sun placement because i'm lazy and suck at maths
local sunX = sunX + 240
local sunY = sunY - 140
local commandResponseText = ""


   -- Initialize variables for cycling display
local displayStartIndex = 1
local maxDisplayCount = 6
   
   -- planets orbit if true
local isOrbiting = true

   -- Initialize selected planet index
local selectedPlanetIndex = 1

local planetInfo = false

planets = {}
local messageWindow = {
  x = 0,
  y = 0,
  width = 400,
  height = 200,
  message = "Welcome to the Message Window!",
}
messageWindow.x = (love.graphics.getWidth() - messageWindow.width) / 2
messageWindow.y = (love.graphics.getHeight() - messageWindow.height) / 2


local function base64_encode(data)
  local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
  return ((data:gsub('.', function(x) 
      local r, b = '', x:byte()
      for i = 8, 1, -1 do r = r .. (b % 2^i - b % 2^(i-1) > 0 and '1' or '0') end
      return r;
  end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
      if (#x < 6) then return '' end
      local c = 0
      for i = 1, 6 do c = c + (x:sub(i,i) == '1' and 2^(6-i) or 0) end
      return b:sub(c+1,c+1)
  end)..({ '', '==', '=' })[#data%3+1])
end



local function printTable(t, indent, result)
  indent = indent or ""
  result = result or ""

for k, v in pairs(t) do
  if type(v) == "table" then
      result = result .. indent .. k .. ":\n"
      result = result .. printTable(v, indent .. "  ", "")
  else
      result = result .. indent .. k .. ": " .. tostring(v) .. "\n"
  end
end

return result
end


-- function that defines orbit
function calculateEllipticalOrbit(semiMajorAxis, eccentricity, angle, tiltAngle)
  local semiMinorAxis = semiMajorAxis * math.sqrt(1 - eccentricity^2)
  local r = semiMajorAxis * (1 - eccentricity^2) / (1 + eccentricity * math.cos(angle))
  local x = r * math.cos(angle)
  local y = r * math.sin(angle) * (semiMinorAxis / semiMajorAxis)

  -- Apply rotation for the tilt
  local tiltRadian = math.rad(tiltAngle)
  local rotatedX = x * math.cos(tiltRadian) - y * math.sin(tiltRadian)
  local rotatedY = x * math.sin(tiltRadian) + y * math.cos(tiltRadian)

  return rotatedX, rotatedY -- x and y coods 
end


function updateSelectedPlanet()
  if planets and selectedPlanetIndex then
      selectedPlanet = planets[selectedPlanetIndex]
  else
      selectedPlanet = nil
  end
end

function updateMessage(newMessage)
  messageWindow.message = newMessage
  messageWindowTimer = 6 
end

local function runActive(dataTable)
  local function mergePlanetAlignment(dataTable)
      local hostTable = {}
      local semiMajorAxis = 50 -- Starting value
      local angle = 0
      local speed = .8
      local eccentricity = .5


for _, hostData in ipairs(dataTable) do
      
    local host = {}
          -- Create a new table for each host, copying the values from the row
          local host = {}
          for key, value in pairs(hostData) do
              host[key] = value
          end

          host.satellites = {}
          if hostData.meta and hostData.meta.values and hostData.meta.values.ports then
              for portNumber, portData in pairs(hostData.meta.values.ports) do
                  table.insert(host.satellites, {
                      name = tostring(portNumber),  -- Using port number as satellite name
                      angle = math.random() * 360,
                      distance = 25,
                      speed = 1
                  })
              end
          end

          print("Host:", host.hostname, "Ports:", host.ports)  -- Debug print ports

    -- Add additional properties
          host.semiMajorAxis = semiMajorAxis
          host.angle = angle
          host.speed = speed
          host.eccentricity = eccentricity

          -- Insert the host into the hostTable
          table.insert(hostTable, host)

          -- Update properties for the next host
          angle = math.random() * 360
          semiMajorAxis = semiMajorAxis + math.random(10,35)
          if semiMajorAxis > 400 then semiMajorAxis = math.ceil(math.random(400,500)) end
          eccentricity = math.random(0.09,0.65)
      end
      return hostTable
  end

  return mergePlanetAlignment(dataTable)
end

-- called when this scene is entered
function StateHostList:enter()
  print("enabling recon")
  bettercap:run("net.probe on; net.recon on")
  host_handle = bettercap:lan()
  host_timer = cron.every(10, function() host_handle = bettercap:lan() end)
end

-- called when this scene is left
function StateHostList:leave()
  print("disabling recon")
  bettercap:run("net.probe off; net.recon off")
end

-- called often to update state 
function StateHostList:update(dt)
  -- stuff gets unset on lurker-reload, so this will recreate it
  if not host_timer then
    StateHostList:enter()
  end
  host_timer:update(dt)

  
  local data, error = host_handle()
  if data and not error and not data._processed then
    data._processed = true
    
    for k,v in ipairs(planets) do print(k,v) end -- DEPRINT
    for _, host in pairs(data["hosts"]) do
      table.insert(planets, data.hosts)
    end
    planets = runActive(planets)

  end
  if current_selection > #hosts and #hosts ~= 0 then
    current_selection = #hosts
  end

      -- main start of update func	
    if messageWindowTimer > 0 then
        messageWindowTimer = messageWindowTimer - dt
        if messageWindowTimer <= 0 then
            messageWindow.message = ""  -- Clear the message when timer runs out
        end
    end

    if isOrbiting then
    -- Update the planets' angles
       for i, planet in ipairs(planets) do
         planet.angle = planet.angle + planet.speed * dt
       end

       for _, planet in ipairs(planets) do
           for _, satellite in ipairs(planet.satellites) do
                satellite.angle = satellite.angle + satellite.speed * dt
           end
        end
    end


end

-- called when a mapped button is pressed
function StateHostList:pressed(button)
  if button == "up" then
    current_selection = current_selection - 1
  end
  if button == "down" then
    current_selection = current_selection + 1
  end
  if current_selection > #host_macs then
    current_selection = 1
  end
  if current_selection < 1 then
    current_selection = #host_macs
  end
end

--
-- add functions:
--


function getPlanetCoordinates(ipAddress)
  for _, planet in ipairs(planets) do
      if planet.ipv4 == ipAddress then
          local x, y = calculateEllipticalOrbit(planet.semiMajorAxis, planet.eccentricity, planet.angle, 335)
          return sunX + x, sunY + y
      end
  end
  return nil, nil  -- IP address not found among planets
end


local function printTable(t, indent)
  indent = indent or ""
  local result = ""

  for k, v in pairs(t) do
      if type(v) == "table" then
          result = result .. indent .. k .. ":\n"
          result = result .. printTable(v, indent .. "  ")
      else
          result = result .. indent .. k .. ": " .. tostring(v) .. "\n"
      end
  end

  return result
end


function drawDetailsBox(selectedPlanet)
  if planetInfo and nestedTables[currentTableIndex] and selectedPlanet and selectedPlanet.meta and selectedPlanet.meta.values then
      local currentTable = selectedPlanet.meta.values[nestedTables[currentTableIndex]]

      if currentTable and #currentTable > 0 then
          local screenWidth, screenHeight = love.graphics.getWidth(), love.graphics.getHeight()
          local boxWidth, boxHeight = 300, 100
          local startX, startY = (screenWidth - boxWidth) / 2, screenHeight - boxHeight - 10

          if startX and startY then
              love.graphics.setColor(0, 0, 0, 0.7)  -- Semi-transparent black
              love.graphics.rectangle("fill", startX, startY, boxWidth, boxHeight)

              love.graphics.setColor(1, 1, 1)  -- White for text
              if currentItemIndex <= #currentTable then
                  local currentItem = currentTable[currentItemIndex]
                  local text = nestedTables[currentTableIndex] .. ": " .. tostring(currentItem)
                  love.graphics.print(text, startX + 10, startY + 10)
              else
                  love.graphics.print("No item at index: " .. currentItemIndex, startX + 10, startY + 10)
              end
          else
              print("Error: startX or startY is nil")
          end
      else
          love.graphics.print("Table is empty or nil", 300, 100) -- Default position if startX or startY is nil
      end
  else
   --   print("Details not displayed or data missing")
  end
end

local function printTable(t, indent, result)
      indent = indent or ""
      result = result or ""

  for k, v in pairs(t) do
      if type(v) == "table" then
          result = result .. indent .. k .. ":\n"
          result = result .. printTable(v, indent .. "  ", "")
      else
          result = result .. indent .. k .. ": " .. tostring(v) .. "\n"
      end
  end

  return result
end

local function printNestedTable(t, startX, startY, width, indent)
  love.graphics.setColor(0, 255, 255, 0.7)
  love.graphics.rectangle("fill", startX, startY, width, 200)  -- Adjust size as needed
  love.graphics.setColor(0, 255, 255)

  local nestedText = ""
  indent = indent or ""

  for k, v in pairs(t) do
      if type(v) == "table" then
          nestedText = nestedText .. indent .. k .. ":\n"
          for subK, subV in pairs(v) do
              nestedText = nestedText .. indent .. "  " .. subK .. ": " .. tostring(subV) .. "\n"
          end
      else
          nestedText = nestedText .. indent .. k .. ": " .. tostring(v) .. "\n"
      end
  end

  love.graphics.printf(nestedText, startX + 10, startY + 10, width - 20, "left")
end

-- called often to draw current state
function StateHostList:draw()
  if #host_macs == 0 then
    love.graphics.setColor(0, 0, 0.5, 1)
    love.graphics.rectangle("fill", 100, 212, 420, 50, 10, 10)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("line", 100, 212, 420, 50, 10, 10)
    local el = ""
    for i=0,(math.floor(time) % 4) do el = el .. "." end
    love.graphics.printf("Searching for hosts" .. el, 0, 230, 640, "center")
  end
  -- camera:attach()

  love.graphics.draw(background)
  -- Set color for orbit lines
  love.graphics.setColor(0, 255, 255)
  local endIndex = math.min(displayStartIndex + maxDisplayCount - 1, #planets)

  -- Draw orbit lines for the planets within the specified range
  for i = displayStartIndex, endIndex do
      local planet = planets[i]
      local x, y = calculateEllipticalOrbit(planet.semiMajorAxis, planet.eccentricity, 0, 335)
      love.graphics.ellipse("line", sunX, sunY, x, y)
  end

  -- Reset color to white for drawing planets and text
  love.graphics.setColor(1, 1, 1)

  -- Draw the sun
  love.graphics.circle("fill", sunX, sunY, 20)

  -- Draw planets and satellites
  for i = displayStartIndex, endIndex do
      local planet = planets[i]
      local planetX, planetY = calculateEllipticalOrbit(planet.semiMajorAxis, planet.eccentricity, planet.angle, 335)
      love.graphics.draw(planetSprite, sunX + planetX, sunY + planetY, 0, 0.1, 0.1, planetSprite:getWidth() / 2, planetSprite:getHeight() / 2)
      local textX = sunX + planetX - planetSprite:getWidth() / 4
      local textY = sunY + planetY - planetSprite:getHeight() / 4 - 15
      --love.graphics.print(planet.hostname, textX, textY)

      for _, satellite in ipairs(planet.satellites) do
          local satelliteX, satelliteY = calculateEllipticalOrbit(satellite.distance, 0, satellite.angle, 0)
          satelliteX, satelliteY = satelliteX + planetX, satelliteY + planetY
          love.graphics.setColor(0, 255, 255)
          love.graphics.circle("fill", sunX + satelliteX, sunY + satelliteY, 5)
          love.graphics.setColor(1, 1, 1)
      end
  end

  -- Message window
  if messageWindowTimer > 0 then
      love.graphics.setColor(0, 255, 255, 0.65)  -- semi-transparent cyan
      love.graphics.rectangle("fill", messageWindow.x, messageWindow.y, messageWindow.width, messageWindow.height)
      love.graphics.setColor(0, 0, 0)  -- red color for the text
      love.graphics.printf(messageWindow.message, messageWindow.x, messageWindow.y + 20, messageWindow.width, "center")
  end

  -- Display details of the selected planet
  if planetInfo and planets and selectedPlanetIndex and planets[selectedPlanetIndex] then
      local selectedPlanet = planets[selectedPlanetIndex]
      local x, y = calculateEllipticalOrbit(selectedPlanet.semiMajorAxis, selectedPlanet.eccentricity, selectedPlanet.angle, 335)
      
      -- Draw details box
      drawDetailsBox(selectedPlanet)

      -- Draw line from selected planet to planetInfo
      love.graphics.setColor(0, 255, 255)
      love.graphics.line(sunX + x, sunY + y, 10, 210)

      -- Draw planetInfo for main properties
      love.graphics.setColor(0, 255, 255, 0.7)
      love.graphics.rectangle("fill", 10, 10, 150, 200)
      love.graphics.setColor(0, 255, 255)
      local displayText = "Name: " .. selectedPlanet.hostname .. "\n"
      for k, v in pairs(selectedPlanet) do
          if k ~= "hostname" and type(v) ~= "table" then
              displayText = displayText .. k .. ": " .. tostring(v) .. "\n"
          end
      end
      love.graphics.printf(displayText, 20, 20, 130, "left")

      -- Separate drawing for nested tables
      if selectedPlanet.meta and selectedPlanet.meta.values and selectedPlanet.meta.values.ports then
          printNestedTable(selectedPlanet.meta.values.ports, 200, 10, 150)
      end
      love.graphics.setColor(1, 1, 1)
  end

  -- Context menu
  if isContextMenuOpen then
  local menuWidth, menuHeight = 300, 100
  local startX, startY = (love.graphics.getWidth() - menuWidth) / 2, love.graphics.getHeight() - menuHeight - 10

  -- Draw the menu background
  love.graphics.setColor(0, 255, 255, 0.7)
  love.graphics.rectangle("fill", startX, startY, menuWidth, menuHeight)

  -- Draw the options
  for i, option in ipairs(contextMenuOptions) do
      if i == selectedOptionIndex then
          love.graphics.setColor(1, 0, 0)  -- Highlight selected option
      else
          love.graphics.setColor(1, 1, 1)  -- White for non-selected options
      end
      love.graphics.print(option, startX + 10, startY + i * 20)
  end
end


--  camera:detach()
end

return StateHostList