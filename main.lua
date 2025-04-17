
-- Check if we're in a Roblox environment
local isRoblox = (type(game) == "userdata" and game:GetService("Players") ~= nil)

if not isRoblox then
    print("Este script está diseñado para ejecutarse en Roblox.")
    print("Por favor, copia y pega el código en un ejecutor de Roblox.")
    return
end

-- Anti Caída: Esta función automáticamente usa el primer item del inventario cuando estás por caer
local function setupAntiCaida()
    local Players = game:GetService("Players")
    local Player = Players.LocalPlayer
    local Character = Player.Character or Player.CharacterAdded:Wait()
    local Humanoid = Character:WaitForChild("Humanoid")
    local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
    local UserInputService = game:GetService("UserInputService")
    local isMobile = UserInputService.TouchEnabled
    
    -- Variables para detectar caída
    local isJumping = false
    local jumpHeight = 0
    local minHeightTrigger = 15 -- Altura mínima para activar (reducida para más sensibilidad)
    local triggerDistance = 8 -- Distancia al suelo aumentada para activación temprana
    local cooldown = false
    local cooldownTime = 0.5 -- Segundos de espera entre activaciones (reducido)
    
    -- Crear interfaz de estado
    local function createStatusUI()
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "AntiCaidaGUI"
        screenGui.ResetOnSpawn = false
        pcall(function() screenGui.IgnoreGuiInset = true end)
        
        -- Asignar parent
        pcall(function() screenGui.Parent = Player:WaitForChild("PlayerGui") end)
        if not screenGui.Parent then
            pcall(function() screenGui.Parent = game:GetService("CoreGui") end)
        end
        
        -- Panel de estado
        local statusFrame = Instance.new("Frame")
        statusFrame.Name = "StatusFrame"
        statusFrame.Size = UDim2.new(0, 180, 0, 40)
        statusFrame.Position = UDim2.new(0, 10, 0, 200) -- Debajo del recolector de drops
        statusFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
        statusFrame.BackgroundTransparency = 0.3
        statusFrame.BorderSizePixel = 0
        statusFrame.Parent = screenGui
        
        -- Esquinas redondeadas
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = statusFrame
        
        -- Título
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Name = "TitleLabel"
        titleLabel.Size = UDim2.new(1, 0, 0, 20)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Font = Enum.Font.SourceSansBold
        titleLabel.TextSize = 14
        titleLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
        titleLabel.Text = "ANTI-CAÍDA ACTIVADO"
        titleLabel.Parent = statusFrame
        
        -- Indicador de estado
        local statusLabel = Instance.new("TextLabel")
        statusLabel.Name = "StatusLabel"
        statusLabel.Size = UDim2.new(1, 0, 0, 20)
        statusLabel.Position = UDim2.new(0, 0, 0.5, 0)
        statusLabel.BackgroundTransparency = 1
        statusLabel.Font = Enum.Font.SourceSans
        statusLabel.TextSize = 13
        statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        statusLabel.Text = "Esperando salto..."
        statusLabel.Parent = statusFrame
        
        -- Indicador visual (círculo)
        local statusIndicator = Instance.new("Frame")
        statusIndicator.Name = "StatusIndicator"
        statusIndicator.Size = UDim2.new(0, 10, 0, 10)
        statusIndicator.Position = UDim2.new(0, 8, 0, 5)
        statusIndicator.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
        statusIndicator.BorderSizePixel = 0
        statusIndicator.Parent = statusFrame
        
        -- Hacer el círculo redondo
        local indicatorCorner = Instance.new("UICorner")
        indicatorCorner.CornerRadius = UDim.new(1, 0)
        indicatorCorner.Parent = statusIndicator
        
        return {
            frame = statusFrame,
            status = statusLabel,
            indicator = statusIndicator
        }
    end
    
    local statusUI = createStatusUI()
    
    -- Función para usar el item Glider específicamente
    local function useFirstItem()
        -- Si está en cooldown, no hacer nada
        if cooldown then return end
        
        cooldown = true
        statusUI.status.Text = "¡ACTIVADO! Usando Glider"
        statusUI.indicator.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
        
        -- Buscar y usar específicamente el Glider
        pcall(function()
            -- Primero buscar en el personaje
            local glider = nil
            
            -- Buscar en el personaje primero
            for _, item in pairs(Character:GetChildren()) do
                if item:IsA("Tool") and item.Name == "Glider" then
                    glider = item
                    break
                end
            end
            
            -- Si no está equipado, buscar en la mochila
            if not glider then
                local backpack = Player:FindFirstChild("Backpack")
                if backpack then
                    for _, item in pairs(backpack:GetChildren()) do
                        if item:IsA("Tool") and item.Name == "Glider" then
                            -- Equipar el Glider
                            item.Parent = Character
                            glider = item
                            wait(0.1) -- Esperar a que se equipe
                            break
                        end
                    end
                end
            end
            
            -- Activar el Glider si se encontró
            if glider then
                if glider.Activate then
                    glider:Activate()
                end
                
                -- Intentar activar mediante eventos remotos también
                if glider:FindFirstChild("RemoteEvent") then
                    glider.RemoteEvent:FireServer()
                end
                
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title = "Anti-Caída",
                    Text = "Glider activado con éxito",
                    Duration = 2
                })
            else
                -- Notificar si no se encontró el Glider
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title = "Anti-Caída",
                    Text = "¡Error! No se encontró el Glider",
                    Duration = 2
                })
            end
        end)
        
        -- Método 3: Para móviles - buscar y tocar todos los botones posibles de ítem/slot
        if isMobile then
            pcall(function()
                -- Buscar botones en la interfaz de usuario
                for _, gui in pairs(Player.PlayerGui:GetDescendants()) do
                    if (gui:IsA("ImageButton") or gui:IsA("TextButton")) and gui.Visible then
                        local nameCheck = string.lower(gui.Name)
                        local success = false
                        
                        -- Comprobar por nombre o posición (primer botón en una barra)
                        if string.find(nameCheck, "slot") or 
                           string.find(nameCheck, "item") or 
                           string.find(nameCheck, "1") or 
                           string.find(nameCheck, "one") or
                           string.find(nameCheck, "hotbar") then
                            
                            -- Simular toque en ese botón
                            local position = gui.AbsolutePosition + gui.AbsoluteSize/2
                            game:GetService("VirtualInputManager"):SendTouchEvent(Enum.UserInputState.Begin, position, true)
                            wait(0.05)
                            game:GetService("VirtualInputManager"):SendTouchEvent(Enum.UserInputState.End, position, true)
                            
                            success = true
                            wait(0.1) -- Pequeña espera entre clics
                        end
                        
                        -- Si hemos tenido éxito con un botón, esperar un poco más
                        if success then
                            wait(0.1)
                        end
                    end
                end
            end)
            
            -- Método adicional: tocar la esquina inferior izquierda (donde suele estar el botón 1)
            pcall(function()
                local viewportSize = workspace.CurrentCamera.ViewportSize
                local positions = {
                    Vector2.new(viewportSize.X * 0.1, viewportSize.Y * 0.9),  -- Esquina inferior izquierda
                    Vector2.new(viewportSize.X * 0.2, viewportSize.Y * 0.9),  -- Un poco a la derecha
                    Vector2.new(viewportSize.X * 0.15, viewportSize.Y * 0.85) -- Un poco arriba
                }
                
                for _, pos in ipairs(positions) do
                    game:GetService("VirtualInputManager"):SendTouchEvent(Enum.UserInputState.Begin, pos, true)
                    wait(0.05)
                    game:GetService("VirtualInputManager"):SendTouchEvent(Enum.UserInputState.End, pos, true)
                    wait(0.1)
                end
            end)
        end
        
        -- Restablecer después del cooldown
        spawn(function()
            wait(cooldownTime)
            cooldown = false
            statusUI.status.Text = "Esperando salto..."
            statusUI.indicator.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
        end)
    end
    
    -- Detectar cuando el jugador comienza a saltar
    Humanoid.StateChanged:Connect(function(oldState, newState)
        if newState == Enum.HumanoidStateType.Jumping then
            isJumping = true
            jumpHeight = HumanoidRootPart.Position.Y
            statusUI.status.Text = "¡Saltando! Altura: " .. math.floor(jumpHeight)
        elseif oldState == Enum.HumanoidStateType.Jumping or oldState == Enum.HumanoidStateType.Freefall then
            if newState == Enum.HumanoidStateType.Landed then
                isJumping = false
                statusUI.status.Text = "Esperando salto..."
            end
        end
    end)
    
    -- Verificar constantemente la altura y distancia al suelo
    game:GetService("RunService").Heartbeat:Connect(function()
        if not isJumping or cooldown then return end
        
        local currentY = HumanoidRootPart.Position.Y
        local heightDiff = jumpHeight - currentY
        
        -- Solo activar si la caída es significativa
        if heightDiff > minHeightTrigger then
            -- Raycast para detectar distancia al suelo
            local rayParams = RaycastParams.new()
            rayParams.FilterType = Enum.RaycastFilterType.Blacklist
            rayParams.FilterDescendantsInstances = {Character}
            
            local rayOrigin = HumanoidRootPart.Position
            local rayDirection = Vector3.new(0, -50, 0) -- Rayo hacia abajo
            
            local rayResult = workspace:Raycast(rayOrigin, rayDirection, rayParams)
            
            if rayResult then
                local distanceToGround = (rayOrigin - rayResult.Position).Magnitude
                
                -- Actualizar texto de estado
                statusUI.status.Text = "Altura: " .. math.floor(heightDiff) .. " | Suelo: " .. math.floor(distanceToGround)
                
                -- Mejorar la detección del momento crítico para usar el ítem
                -- Si la distancia al suelo es corta o la velocidad de caída es alta
                local velocity = HumanoidRootPart.Velocity.Y
                if (distanceToGround <= triggerDistance) or 
                   (distanceToGround <= triggerDistance * 2 and velocity < -50) then
                    -- Usar el ítem y notificar
                    useFirstItem()
                    -- Notificar al usuario
                    game:GetService("StarterGui"):SetCore("SendNotification", {
                        Title = "Anti-Caída Activado",
                        Text = "Usando ítem 1 para evitar daño",
                        Duration = 2
                    })
                end
            end
        end
    end)
    
    -- Reiniciar al cambiar de personaje
    Player.CharacterAdded:Connect(function(newChar)
        Character = newChar
        Humanoid = newChar:WaitForChild("Humanoid")
        HumanoidRootPart = newChar:WaitForChild("HumanoidRootPart")
        isJumping = false
        cooldown = false
        statusUI.status.Text = "Esperando salto..."
        statusUI.indicator.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
    end)
    
    -- Notificar que el anti-caída se ha activado
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Anti-Caída Activado",
        Text = "Se usará automáticamente el Glider al caer",
        Duration = 5
    })
end

-- Iniciar el anti-caída
spawn(setupAntiCaida)

-- Roblox Infinite Script Executor v2.0
-- Compatible con ejecutores como Synapse X, KRNL, etc.

-- Variables globales
local executing = false
local scriptSelected = nil
local delayTime = 1 -- Delay en segundos (valor predeterminado)
local savedScripts = {}

-- Crear la interfaz gráfica
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local ScriptBox = Instance.new("TextBox")
local DelayLabel = Instance.new("TextLabel")
local DelayInput = Instance.new("TextBox")
local ExecuteButton = Instance.new("TextButton")
local StopButton = Instance.new("TextButton")
local StatusLabel = Instance.new("TextLabel")
local ScriptsFrame = Instance.new("Frame")
local ScriptsTitle = Instance.new("TextLabel")
local ScriptsList = Instance.new("ScrollingFrame")
local ScriptTemplate = Instance.new("Frame")
local SaveButton = Instance.new("TextButton")
local ScriptNameInput = Instance.new("TextBox")

-- Propiedades de la interfaz principal
ScreenGui.Name = "InfiniteExecutor"
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false

MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
MainFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.BorderSizePixel = 2
MainFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
MainFrame.Size = UDim2.new(0, 500, 0, 400)
MainFrame.Active = true
MainFrame.Draggable = true

Title.Name = "Title"
Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Title.BorderSizePixel = 0
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Font = Enum.Font.SourceSansBold
Title.Text = "Fortline Script Executor v2.0"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18.0

-- Editor de scripts
-- Editor de scripts con scroll
local ScriptBoxContainer = Instance.new("Frame")
ScriptBoxContainer.Name = "ScriptBoxContainer"
ScriptBoxContainer.Parent = MainFrame
ScriptBoxContainer.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
ScriptBoxContainer.BorderColor3 = Color3.fromRGB(80, 80, 90)
ScriptBoxContainer.Position = UDim2.new(0.03, 0, 0.12, 0)
ScriptBoxContainer.Size = UDim2.new(0.57, 0, 0.58, 0)
ScriptBoxContainer.ClipsDescendants = true

ScriptBox.Name = "ScriptBox"
ScriptBox.Parent = ScriptBoxContainer
ScriptBox.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
ScriptBox.BorderSizePixel = 0
ScriptBox.Position = UDim2.new(0, 0, 0, 0)
ScriptBox.Size = UDim2.new(1, -10, 1, 0)
ScriptBox.Font = Enum.Font.SourceSans
ScriptBox.PlaceholderText = "Coloca tu script aquí..."
ScriptBox.Text = ""
ScriptBox.TextColor3 = Color3.fromRGB(255, 255, 255)
ScriptBox.TextSize = 14.0
ScriptBox.TextXAlignment = Enum.TextXAlignment.Left
ScriptBox.TextYAlignment = Enum.TextYAlignment.Top
ScriptBox.ClearTextOnFocus = false
ScriptBox.MultiLine = true
ScriptBox.TextWrapped = true
ScriptBox.ClearTextOnFocus = false

-- Añadir scrollbar
local ScriptBoxScrollBar = Instance.new("ScrollingFrame")
ScriptBoxScrollBar.Name = "ScriptBoxScrollBar"
ScriptBoxScrollBar.Parent = ScriptBoxContainer
ScriptBoxScrollBar.BackgroundTransparency = 1
ScriptBoxScrollBar.BorderSizePixel = 0
ScriptBoxScrollBar.Position = UDim2.new(0, 0, 0, 0)
ScriptBoxScrollBar.Size = UDim2.new(1, 0, 1, 0)
ScriptBoxScrollBar.ScrollBarThickness = 6
ScriptBoxScrollBar.ScrollingDirection = Enum.ScrollingDirection.Y
ScriptBoxScrollBar.CanvasSize = UDim2.new(0, 0, 4, 0) -- Permite 4 veces la altura para scripts largos
ScriptBoxScrollBar.AutomaticCanvasSize = Enum.AutomaticSize.Y

-- Sincronizar ScriptBox con ScrollingFrame
ScriptBox.Parent = ScriptBoxScrollBar

-- Input para nombre del script
ScriptNameInput.Name = "ScriptNameInput"
ScriptNameInput.Parent = MainFrame
ScriptNameInput.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
ScriptNameInput.BorderColor3 = Color3.fromRGB(80, 80, 90)
ScriptNameInput.Position = UDim2.new(0.03, 0, 0.72, 0)
ScriptNameInput.Size = UDim2.new(0.4, 0, 0, 25)
ScriptNameInput.Font = Enum.Font.SourceSans
ScriptNameInput.PlaceholderText = "Nombre del script..."
ScriptNameInput.Text = ""
ScriptNameInput.TextColor3 = Color3.fromRGB(255, 255, 255)
ScriptNameInput.TextSize = 14.0

-- Botón guardar script
SaveButton.Name = "SaveButton"
SaveButton.Parent = MainFrame
SaveButton.BackgroundColor3 = Color3.fromRGB(0, 100, 180)
SaveButton.BorderColor3 = Color3.fromRGB(0, 70, 150)
SaveButton.Position = UDim2.new(0.45, 0, 0.72, 0)
SaveButton.Size = UDim2.new(0.15, 0, 0, 25)
SaveButton.Font = Enum.Font.SourceSansBold
SaveButton.Text = "GUARDAR"
SaveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SaveButton.TextSize = 14.0

DelayLabel.Name = "DelayLabel"
DelayLabel.Parent = MainFrame
DelayLabel.BackgroundTransparency = 1
DelayLabel.Position = UDim2.new(0.03, 0, 0.8, 0)
DelayLabel.Size = UDim2.new(0.2, 0, 0, 25)
DelayLabel.Font = Enum.Font.SourceSans
DelayLabel.Text = "Delay (seg):"
DelayLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
DelayLabel.TextSize = 14.0
DelayLabel.TextXAlignment = Enum.TextXAlignment.Left

DelayInput.Name = "DelayInput"
DelayInput.Parent = MainFrame
DelayInput.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
DelayInput.BorderColor3 = Color3.fromRGB(80, 80, 90)
DelayInput.Position = UDim2.new(0.23, 0, 0.8, 0)
DelayInput.Size = UDim2.new(0.1, 0, 0, 25)
DelayInput.Font = Enum.Font.SourceSans
DelayInput.Text = "1"
DelayInput.TextColor3 = Color3.fromRGB(255, 255, 255)
DelayInput.TextSize = 14.0

ExecuteButton.Name = "ExecuteButton"
ExecuteButton.Parent = MainFrame
ExecuteButton.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
ExecuteButton.BorderColor3 = Color3.fromRGB(0, 80, 0)
ExecuteButton.Position = UDim2.new(0.03, 0, 0.88, 0)
ExecuteButton.Size = UDim2.new(0.28, 0, 0, 30)
ExecuteButton.Font = Enum.Font.SourceSansBold
ExecuteButton.Text = "EJECUTAR INFINITO"
ExecuteButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ExecuteButton.TextSize = 14.0

StopButton.Name = "StopButton"
StopButton.Parent = MainFrame
StopButton.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
StopButton.BorderColor3 = Color3.fromRGB(120, 0, 0)
StopButton.Position = UDim2.new(0.33, 0, 0.88, 0)
StopButton.Size = UDim2.new(0.27, 0, 0, 30)
StopButton.Font = Enum.Font.SourceSansBold
StopButton.Text = "DETENER"
StopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
StopButton.TextSize = 14.0

StatusLabel.Name = "StatusLabel"
StatusLabel.Parent = MainFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0.03, 0, 0.965, 0)
StatusLabel.Size = UDim2.new(0.57, 0, 0, 20)
StatusLabel.Font = Enum.Font.SourceSans
StatusLabel.Text = "Estado: Esperando"
StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusLabel.TextSize = 14.0

-- Panel de scripts guardados
ScriptsFrame.Name = "ScriptsFrame"
ScriptsFrame.Parent = MainFrame
ScriptsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
ScriptsFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
ScriptsFrame.BorderSizePixel = 1
ScriptsFrame.Position = UDim2.new(0.63, 0, 0.12, 0)
ScriptsFrame.Size = UDim2.new(0.34, 0, 0.83, 0)

ScriptsTitle.Name = "ScriptsTitle"
ScriptsTitle.Parent = ScriptsFrame
ScriptsTitle.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
ScriptsTitle.BorderSizePixel = 0
ScriptsTitle.Size = UDim2.new(1, 0, 0, 25)
ScriptsTitle.Font = Enum.Font.SourceSansBold
ScriptsTitle.Text = "Scripts Guardados"
ScriptsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
ScriptsTitle.TextSize = 14.0

ScriptsList.Name = "ScriptsList"
ScriptsList.Parent = ScriptsFrame
ScriptsList.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
ScriptsList.BorderSizePixel = 0
ScriptsList.Position = UDim2.new(0, 0, 0, 25)
ScriptsList.Size = UDim2.new(1, 0, 1, -25)
ScriptsList.CanvasSize = UDim2.new(0, 0, 0, 0)
ScriptsList.ScrollBarThickness = 6
ScriptsList.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScriptsList.ScrollingDirection = Enum.ScrollingDirection.Y

-- Template para un script guardado (no se añade directamente)
ScriptTemplate.Name = "ScriptTemplate"
ScriptTemplate.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
ScriptTemplate.BorderColor3 = Color3.fromRGB(60, 60, 65)
ScriptTemplate.Size = UDim2.new(1, -10, 0, 40)
ScriptTemplate.Visible = false

-- Funciones
local function updateStatus(status, color)
    StatusLabel.Text = "Estado: " .. status
    StatusLabel.TextColor3 = color or Color3.fromRGB(255, 255, 255)
end

local function createScriptItem(name, scriptText, index)
    local scriptItem = ScriptTemplate:Clone()
    scriptItem.Name = "Script_" .. index
    scriptItem.Position = UDim2.new(0, 5, 0, (index - 1) * 45 + 5)
    scriptItem.Visible = true
    scriptItem.Parent = ScriptsList
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.BackgroundTransparency = 1
    nameLabel.Position = UDim2.new(0, 5, 0, 0)
    nameLabel.Size = UDim2.new(1, -10, 0.5, 0)
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.Text = name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextSize = 14.0
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Parent = scriptItem
    
    local selectButton = Instance.new("TextButton")
    selectButton.Name = "SelectButton"
    selectButton.BackgroundColor3 = Color3.fromRGB(60, 120, 180)
    selectButton.BorderColor3 = Color3.fromRGB(40, 90, 150)
    selectButton.Position = UDim2.new(0, 5, 0.5, 2)
    selectButton.Size = UDim2.new(0.48, 0, 0.4, 0)
    selectButton.Font = Enum.Font.SourceSansSemibold
    
    -- Cambiar el texto del botón según si es un script predeterminado
    local isDefaultScript = index <= 4  -- Ahora son 4 scripts predeterminados
    selectButton.Text = "EJECUTAR"
    
    selectButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    selectButton.TextSize = 12.0
    selectButton.Parent = scriptItem
    
    local deleteButton = Instance.new("TextButton")
    deleteButton.Name = "DeleteButton"
    deleteButton.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
    deleteButton.BorderColor3 = Color3.fromRGB(150, 40, 40)
    deleteButton.Position = UDim2.new(0.52, 0, 0.5, 2)
    deleteButton.Size = UDim2.new(0.48, 0, 0.4, 0)
    deleteButton.Font = Enum.Font.SourceSansSemibold
    deleteButton.Text = "ELIMINAR"
    deleteButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    deleteButton.TextSize = 12.0
    deleteButton.Parent = scriptItem
    
    -- Funcionalidad del botón principal (ejecutar)
    selectButton.MouseButton1Click:Connect(function()
        pcall(function()
            loadstring(scriptText)()
        end)
        updateStatus("Ejecutando '" .. name .. "'", Color3.fromRGB(0, 255, 150))
    end)
    
    -- Funcionalidad de eliminar script
    deleteButton.MouseButton1Click:Connect(function()
        table.remove(savedScripts, index)
        updateScriptsList()
        if scriptSelected == index then
            scriptSelected = nil
        end
        updateStatus("Script '" .. name .. "' eliminado", Color3.fromRGB(255, 150, 0))
    end)
    
    return scriptItem
end

local function updateScriptsList()
    -- Limpiar lista actual
    for _, child in pairs(ScriptsList:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Recrear lista con scripts guardados
    for i, scriptData in ipairs(savedScripts) do
        createScriptItem(scriptData.name, scriptData.code, i)
    end
    
    -- Actualizar tamaño del canvas (ahora automático con AutomaticCanvasSize)
end

local function saveCurrentScript()
    local scriptName = ScriptNameInput.Text
    local scriptCode = ScriptBox.Text
    
    if scriptName == "" then
        updateStatus("Error: Debes dar un nombre al script", Color3.fromRGB(255, 50, 50))
        return
    end
    
    if scriptCode == "" then
        updateStatus("Error: El script está vacío", Color3.fromRGB(255, 50, 50))
        return
    end
    
    -- Añadir a la lista de scripts
    table.insert(savedScripts, {name = scriptName, code = scriptCode})
    updateScriptsList()
    
    -- Limpiar campo de nombre
    ScriptNameInput.Text = ""
    updateStatus("Script '" .. scriptName .. "' guardado", Color3.fromRGB(0, 255, 150))
end

local function startExecution()
    if executing then return end
    
    -- Obtener el script y el delay
    local scriptToExecute = ScriptBox.Text
    local delayValue = tonumber(DelayInput.Text)
    
    -- Validaciones
    if scriptToExecute == "" then
        updateStatus("Error: Script vacío", Color3.fromRGB(255, 50, 50))
        return
    end
    
    if not delayValue or delayValue < 0.1 then
        updateStatus("Error: Delay inválido (mín. a.1s)", Color3.fromRGB(255, 50, 50))
        return
    end
    
    delayTime = delayValue
    executing = true
    updateStatus("Ejecutando infinitamente...", Color3.fromRGB(0, 255, 0))
    
    -- Bucle de ejecución
    spawn(function()
        while executing do
            pcall(function()
                loadstring(scriptToExecute)()
            end)
            wait(delayTime)
        end
    end)
end

local function stopExecution()
    executing = false
    updateStatus("Ejecución detenida", Color3.fromRGB(255, 150, 0))
end

-- Añadir scripts preconfigurados para Fortline
local function addDefaultScripts()
    local defaultScripts = {
        {
            name = "Anti-Daño de Caída",
            code = [[
                local Players = game:GetService("Players")
                local Player = Players.LocalPlayer
                local Character = Player.Character or Player.CharacterAdded:Wait()
                local Humanoid = Character:WaitForChild("Humanoid")
                local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
                local UserInputService = game:GetService("UserInputService")
                local isMobile = UserInputService.TouchEnabled
                
                -- Variables para detectar caída
                local isJumping = false
                local jumpHeight = 0
                local minHeightTrigger = 20 -- Altura mínima para activar
                local triggerDistance = 5 -- Distancia al suelo en la que se activará
                local cooldown = false
                local cooldownTime = 1 -- Segundos de espera entre activaciones
                
                -- Crear interfaz de estado
                local screenGui = Instance.new("ScreenGui")
                screenGui.Name = "AntiCaidaGUI"
                screenGui.ResetOnSpawn = false
                pcall(function() screenGui.IgnoreGuiInset = true end)
                pcall(function() screenGui.Parent = Player:WaitForChild("PlayerGui") end)
                if not screenGui.Parent then
                    pcall(function() screenGui.Parent = game:GetService("CoreGui") end)
                end
                
                -- Panel de estado
                local statusFrame = Instance.new("Frame")
                statusFrame.Name = "StatusFrame"
                statusFrame.Size = UDim2.new(0, 180, 0, 40)
                statusFrame.Position = UDim2.new(0, 10, 0, 200)
                statusFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
                statusFrame.BackgroundTransparency = 0.3
                statusFrame.BorderSizePixel = 0
                statusFrame.Parent = screenGui
                
                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(0, 6)
                corner.Parent = statusFrame
                
                local titleLabel = Instance.new("TextLabel")
                titleLabel.Name = "TitleLabel"
                titleLabel.Size = UDim2.new(1, 0, 0, 20)
                titleLabel.BackgroundTransparency = 1
                titleLabel.Font = Enum.Font.SourceSansBold
                titleLabel.TextSize = 14
                titleLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
                titleLabel.Text = "ANTI-CAÍDA ACTIVADO"
                titleLabel.Parent = statusFrame
                
                local statusLabel = Instance.new("TextLabel")
                statusLabel.Name = "StatusLabel"
                statusLabel.Size = UDim2.new(1, 0, 0, 20)
                statusLabel.Position = UDim2.new(0, 0, 0.5, 0)
                statusLabel.BackgroundTransparency = 1
                statusLabel.Font = Enum.Font.SourceSans
                statusLabel.TextSize = 13
                statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
                statusLabel.Text = "Esperando salto..."
                statusLabel.Parent = statusFrame
                
                local statusIndicator = Instance.new("Frame")
                statusIndicator.Name = "StatusIndicator"
                statusIndicator.Size = UDim2.new(0, 10, 0, 10)
                statusIndicator.Position = UDim2.new(0, 8, 0, 5)
                statusIndicator.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
                statusIndicator.BorderSizePixel = 0
                statusIndicator.Parent = statusFrame
                
                local indicatorCorner = Instance.new("UICorner")
                indicatorCorner.CornerRadius = UDim.new(1, 0)
                indicatorCorner.Parent = statusIndicator
                
                -- Función para usar el primer item
                local function useFirstItem()
                    if cooldown then return end
                    
                    cooldown = true
                    statusLabel.Text = "¡ACTIVADO! Usando item 1"
                    statusIndicator.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
                    
                    -- Método para PC
                    if not isMobile then
                        game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.One, false, game)
                        wait(0.05)
                        game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.One, false, game)
                    else
                        -- Método para móvil
                        pcall(function()
                            for _, gui in pairs(Player.PlayerGui:GetDescendants()) do
                                if gui:IsA("ImageButton") or gui:IsA("TextButton") then
                                    local nameCheck = string.lower(gui.Name)
                                    if string.find(nameCheck, "slot") or string.find(nameCheck, "item") or string.find(nameCheck, "1") or string.find(nameCheck, "one") then
                                        local position = gui.AbsolutePosition + gui.AbsoluteSize/2
                                        game:GetService("VirtualInputManager"):SendTouchEvent(Enum.UserInputState.Begin, position, true)
                                        wait(0.05)
                                        game:GetService("VirtualInputManager"):SendTouchEvent(Enum.UserInputState.End, position, true)
                                        break
                                    end
                                end
                            end
                        end)
                    end
                    
                    -- Intentar equipar y usar directamente
                    pcall(function()
                        local backpack = Player:FindFirstChild("Backpack")
                        if backpack then
                            local tools = backpack:GetChildren()
                            if #tools > 0 then
                                tools[1].Parent = Character
                                if tools[1]:IsA("Tool") then
                                    tools[1]:Activate()
                                end
                            end
                        end
                    end)
                    
                    -- Restablecer cooldown
                    spawn(function()
                        wait(cooldownTime)
                        cooldown = false
                        statusLabel.Text = "Esperando salto..."
                        statusIndicator.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
                    end)
                end
                
                -- Detectar cuando el jugador comienza a saltar
                Humanoid.StateChanged:Connect(function(oldState, newState)
                    if newState == Enum.HumanoidStateType.Jumping then
                        isJumping = true
                        jumpHeight = HumanoidRootPart.Position.Y
                        statusLabel.Text = "¡Saltando! Altura: " .. math.floor(jumpHeight)
                    elseif oldState == Enum.HumanoidStateType.Jumping or oldState == Enum.HumanoidStateType.Freefall then
                        if newState == Enum.HumanoidStateType.Landed then
                            isJumping = false
                            statusLabel.Text = "Esperando salto..."
                        end
                    end
                end)
                
                -- Verificar constantemente la altura y distancia al suelo
                game:GetService("RunService").Heartbeat:Connect(function()
                    if not isJumping or cooldown then return end
                    
                    local currentY = HumanoidRootPart.Position.Y
                    local heightDiff = jumpHeight - currentY
                    
                    if heightDiff > minHeightTrigger then
                        local rayParams = RaycastParams.new()
                        rayParams.FilterType = Enum.RaycastFilterType.Blacklist
                        rayParams.FilterDescendantsInstances = {Character}
                        
                        local rayOrigin = HumanoidRootPart.Position
                        local rayDirection = Vector3.new(0, -50, 0)
                        
                        local rayResult = workspace:Raycast(rayOrigin, rayDirection, rayParams)
                        
                        if rayResult then
                            local distanceToGround = (rayOrigin - rayResult.Position).Magnitude
                            statusLabel.Text = "Altura: " .. math.floor(heightDiff) .. " | Suelo: " .. math.floor(distanceToGround)
                            
                            if distanceToGround <= triggerDistance then
                                useFirstItem()
                            end
                        end
                    end
                end)
                
                -- Reiniciar al cambiar de personaje
                Player.CharacterAdded:Connect(function(newChar)
                    Character = newChar
                    Humanoid = newChar:WaitForChild("Humanoid")
                    HumanoidRootPart = newChar:WaitForChild("HumanoidRootPart")
                    isJumping = false
                    cooldown = false
                end)
                
                -- Notificar inicio
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title = "Anti-Caída Activado",
                    Text = "Se usará automáticamente el item 1 al caer",
                    Duration = 5
                })
            ]]
        },
        {
            name = "Auto Disparo",
            code = [[
                local args = {
                    [1] = game:GetService("Players").LocalPlayer.Character.Sniper,
                    [2] = {
                        ["id"] = 16,
                        ["charge"] = 0,
                        ["origin"] = Vector3.new(3386.06201171875, 115.289794921875, 2648.832763671875),
                        ["dir"] = Vector3.new(-0.7572656869888306, 0.6518105864524841, 0.041128527373075485)
                    }
                }

                game:GetService("ReplicatedStorage"):WaitForChild("WeaponsSystem"):WaitForChild("Network"):WaitForChild("WeaponFired"):FireServer(unpack(args))
            ]]
        },
        {
            name = "ESP Avanzado + FPS & Crosshair",
            code = [[
                local Players = game:GetService("Players")
                local RunService = game:GetService("RunService")
                local ReplicatedStorage = game:GetService("ReplicatedStorage")
                local Player = Players.LocalPlayer
                local PlayerGui = Player:WaitForChild("PlayerGui")

                -- Variables
                local fps = 0
                local fpsLabel = nil
                
                -- Función para crear contador de FPS
                local function createFPSCounter()
                    -- Remover contador existente si hay uno
                    if fpsLabel and fpsLabel.Parent then
                        fpsLabel:Destroy()
                    end

                    local screenGui = Instance.new("ScreenGui")
                    screenGui.Name = "FPSCounterGui"
                    screenGui.DisplayOrder = 999
                    screenGui.ResetOnSpawn = false
                    
                    -- Intentar configurar IgnoreGuiInset para que no afecte la barra superior
                    pcall(function() screenGui.IgnoreGuiInset = true end)
                    
                    -- Asignar el parent con manejo de errores
                    pcall(function() screenGui.Parent = PlayerGui end)
                    
                    -- También intentar CoreGui como alternativa
                    if not screenGui.Parent then
                        pcall(function() screenGui.Parent = game:GetService("CoreGui") end)
                    end

                    -- Crear un panel más elegante en la esquina
                    local panel = Instance.new("Frame")
                    panel.Parent = screenGui
                    panel.Size = UDim2.new(0, 80, 0, 24)
                    panel.Position = UDim2.new(0, 10, 0, 10) -- Colocado en la esquina superior izquierda
                    panel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
                    panel.BackgroundTransparency = 0.3
                    panel.BorderSizePixel = 0
                    
                    -- Esquinas redondeadas
                    local panelCorner = Instance.new("UICorner")
                    panelCorner.CornerRadius = UDim.new(0, 4)
                    panelCorner.Parent = panel
                    
                    -- Borde sutil
                    local stroke = Instance.new("UIStroke")
                    stroke.Color = Color3.fromRGB(50, 200, 255)
                    stroke.Thickness = 1
                    stroke.Transparency = 0.7
                    stroke.Parent = panel
                    
                    -- Icono/prefijo
                    local prefixLabel = Instance.new("TextLabel")
                    prefixLabel.Parent = panel
                    prefixLabel.Size = UDim2.new(0, 24, 1, 0)
                    prefixLabel.Position = UDim2.new(0, 0, 0, 0)
                    prefixLabel.BackgroundTransparency = 1
                    prefixLabel.TextSize = 14
                    prefixLabel.TextColor3 = Color3.fromRGB(50, 200, 255)
                    prefixLabel.Font = Enum.Font.SourceSansBold
                    prefixLabel.Text = "FPS"
                    prefixLabel.TextXAlignment = Enum.TextXAlignment.Center

                    local textLabel = Instance.new("TextLabel")
                    textLabel.Parent = panel
                    textLabel.Size = UDim2.new(0, 56, 1, 0)
                    textLabel.Position = UDim2.new(0, 24, 0, 0)
                    textLabel.BackgroundTransparency = 1
                    textLabel.TextSize = 14
                    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                    textLabel.Font = Enum.Font.SourceSansBold
                    textLabel.Text = "0"
                    textLabel.TextXAlignment = Enum.TextXAlignment.Center

                    fpsLabel = textLabel
                    return textLabel
                end

                -- Cálculo de FPS
                RunService.RenderStepped:Connect(function()
                    fps = fps + 1
                end)

                -- Actualizar FPS cada segundo
                spawn(function()
                    while wait(1) do
                        if fpsLabel then
                            fpsLabel.Text = tostring(fps)
                            
                            -- Cambiar color según los FPS (rojo si es bajo, verde si es alto)
                            if fps < 30 then
                                fpsLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
                            elseif fps < 60 then
                                fpsLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
                            else
                                fpsLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
                            end
                            
                            -- Efecto de animación para el color (pulsante suave)
                            spawn(function()
                                local originalColor = fpsLabel.TextColor3
                                local brightColor = Color3.new(
                                    math.min(1, originalColor.R * 1.3),
                                    math.min(1, originalColor.G * 1.3),
                                    math.min(1, originalColor.B * 1.3)
                                )
                                
                                for i = 0, 1, 0.1 do
                                    if fpsLabel then
                                        fpsLabel.TextColor3 = originalColor:Lerp(brightColor, i)
                                        wait(0.01)
                                    else
                                        break
                                    end
                                end
                                
                                for i = 1, 0, -0.1 do
                                    if fpsLabel then
                                        fpsLabel.TextColor3 = originalColor:Lerp(brightColor, i)
                                        wait(0.01)
                                    else
                                        break
                                    end
                                end
                            end)
                        end
                        fps = 0
                    end
                end)

                -- Función para crear BillboardGui para mostrar info de jugadores
                local function createBillboard(character, player)
                    if not character or character:FindFirstChild("BillboardGui") then return end
                    
                    -- No aplicar al jugador local
                    if player == Player then return end
                    
                    -- Con manejo de errores para mayor estabilidad
                    local success, billboard = pcall(function()
                        local bill = Instance.new("BillboardGui")
                        bill.Name = "BillboardGui"
                        bill.Parent = character
                        bill.Adornee = character:FindFirstChild("Head") or character.PrimaryPart
                        bill.Size = UDim2.new(0, 150, 0, 35) -- Tamaño reducido
                        bill.AlwaysOnTop = true
                        bill.StudsOffset = Vector3.new(0, 2.5, 0) -- Movido más abajo, cerca de la cabeza
                        bill.MaxDistance = 150 -- Limitar distancia de visibilidad
                        return bill
                    end)
                    
                    if not success or not billboard then return end

                    -- Fondo semitransparente para mejor lectura
                    local background = Instance.new("Frame")
                    background.Parent = billboard
                    background.Size = UDim2.new(1, 0, 1, 0)
                    background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                    background.BackgroundTransparency = 0.6
                    background.BorderSizePixel = 0
                    
                    -- Esquinas redondeadas
                    local uiCorner = Instance.new("UICorner")
                    uiCorner.CornerRadius = UDim.new(0, 4)
                    uiCorner.Parent = background

                    local textLabel = Instance.new("TextLabel")
                    textLabel.Parent = billboard
                    textLabel.Size = UDim2.new(1, 0, 1, 0)
                    textLabel.BackgroundTransparency = 1
                    textLabel.TextSize = 11 -- Tamaño de texto más pequeño
                    textLabel.TextStrokeTransparency = 0.3 -- Más contorno para mejor lectura
                    textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
                    textLabel.Font = Enum.Font.SourceSansSemibold -- Fuente más clara

                    -- Función para actualizar info del jugador
                    local function updateInfo()
                        pcall(function()
                            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and 
                               Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
                                
                                local distance = (player.Character.HumanoidRootPart.Position - Player.Character.HumanoidRootPart.Position).Magnitude
                                local health = player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health or 0
                                local maxHealth = player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.MaxHealth or 100
                                local healthPercent = math.floor((health/maxHealth) * 100)
                                
                                -- Cambiar color según estado de amistad
                                if Player:IsFriendsWith(player.UserId) then
                                    textLabel.TextColor3 = Color3.new(0, 1, 0) -- Verde para amigos
                                else
                                    -- Color según la salud (rojo a verde)
                                    local r = math.min(255, math.floor(255 * (1 - healthPercent/100)))
                                    local g = math.min(255, math.floor(255 * (healthPercent/100)))
                                    textLabel.TextColor3 = Color3.fromRGB(r, g, 0)
                                end
                                
                                -- Mostrar información de manera más compacta
                                local displayName = player.DisplayName ~= player.Name and " [" .. player.DisplayName .. "]" or ""
                                textLabel.Text = player.Name .. displayName .. 
                                                "\n❤️ " .. math.floor(health) .. " (" .. healthPercent .. "%)" ..
                                                "\n📏 " .. math.floor(distance)
                            end
                        end)
                    end

                    -- Actualizar constantemente
                    spawn(function()
                        while billboard and billboard.Parent do
                            updateInfo()
                            wait(0.1)
                        end
                    end)
                end

                -- Función para resaltar personaje
                local function highlightCharacter(character, player)
                    if not character or character:FindFirstChild("Highlight") then return end
                    
                    -- No aplicar al jugador local
                    if player == Player then return end
                    
                    local esp = Instance.new("Highlight")
                    esp.Name = "Highlight"
                    esp.FillTransparency = 0.85 -- Ligero relleno para mejor visibilidad
                    esp.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- Siempre visible a través de paredes
                    esp.OutlineTransparency = 0.2 -- Línea más visible

                    -- Configurar color según el tipo de jugador
                    if player and Player:IsFriendsWith(player.UserId) then
                        esp.OutlineColor = Color3.new(0, 1, 0) -- Verde para amigos
                        esp.FillColor = Color3.new(0, 0.7, 0) -- Ligero relleno verde
                    else
                        -- Equipos
                        if player and player.Team then
                            esp.OutlineColor = player.Team.TeamColor.Color
                            esp.FillColor = player.Team.TeamColor.Color
                        else
                            esp.OutlineColor = Color3.new(1, 0, 0) -- Rojo para enemigos
                            esp.FillColor = Color3.new(0.7, 0, 0) -- Ligero relleno rojo
                        end
                    end
                    
                    -- Intentar aumentar el grosor para mejor visibilidad
                    pcall(function()
                        esp.OutlineSize = 2
                    end)

                    esp.Parent = character
                end

                -- Función para detectar y corregir invisibilidad
                local function fixInvisibility(character)
                    if not character or player == Player then return end
                    
                    pcall(function()
                        for _, part in ipairs(character:GetChildren()) do
                            if part:IsA("BasePart") and part.Transparency == 1 then
                                part.Transparency = 0.4
                            end
                            if part.Name == "HumanoidRootPart" then
                                part.Transparency = 0.95
                            end
                        end
                    end)
                end

                -- Función cuando un jugador se une
                local function onPlayerAdded(player)
                    local function applyESP(character)
                        pcall(function()
                            -- Solo aplicar ESP si no es el jugador local
                            if player ~= Player then
                                highlightCharacter(character, player)
                                createBillboard(character, player)
                                fixInvisibility(character)
                            end
                        end)
                    end

                    if player.Character then
                        applyESP(player.Character)
                    end

                    player.CharacterAdded:Connect(applyESP)
                end

                -- Aplicar a jugadores existentes
                for _, player in pairs(Players:GetPlayers()) do
                    onPlayerAdded(player)
                end

                -- Observar nuevos jugadores
                Players.PlayerAdded:Connect(onPlayerAdded)

                -- Reaplicar ESP y corregir invisibilidad en un bucle
                spawn(function()
                    while wait(0.5) do
                        pcall(function()
                            for _, player in pairs(Players:GetPlayers()) do
                                if player ~= Player and player.Character then
                                    if not player.Character:FindFirstChild("Highlight") then
                                        highlightCharacter(player.Character, player)
                                    end
                                    if not player.Character:FindFirstChild("BillboardGui") then
                                        createBillboard(player.Character, player)
                                    end
                                    fixInvisibility(player.Character)
                                end
                            end
                        end)
                    end
                end)

                -- Función de crosshair removida

                Player.CharacterAdded:Connect(function()
                    pcall(function()
                        createFPSCounter()
                        -- createCrosshair() -- Removido para evitar crear cursor
                    end)
                end)

                -- Configuración inicial
                createFPSCounter()
                -- createCrosshair() -- Removido para evitar crear cursor
                
                -- Indicador de inicio exitoso
                if fpsLabel then
                    fpsLabel.Text = "ESP Activado!"
                    wait(1)
                end
            ]]
        },
        {
            name = "Velocidad Extra",
            code = [[
                local player = game.Players.LocalPlayer
                local character = player.Character or player.CharacterAdded:Wait()
                local humanoid = character:WaitForChild("Humanoid")
                
                -- Cambiar velocidad
                humanoid.WalkSpeed = 32  -- Normal es 16
                
                -- Restaurar al morir
                player.CharacterAdded:Connect(function(newCharacter)
                    local newHumanoid = newCharacter:WaitForChild("Humanoid")
                    newHumanoid.WalkSpeed = 32
                end)
            ]]
        },
        {
            name = "Auto-Disparo Avanzado",
            code = [[
                local Players = game:GetService("Players")
                local RunService = game:GetService("RunService")
                local ReplicatedStorage = game:GetService("ReplicatedStorage")
                local UserInputService = game:GetService("UserInputService")
                local Camera = game.Workspace.CurrentCamera
                local Player = Players.LocalPlayer
                
                -- Configuración
                local autoShootEnabled = true
                local targetDetectionRange = 500 -- Distancia máxima para detectar objetivos
                local shootDelay = 0.1 -- Tiempo entre disparos en segundos
                local lastShootTime = 0
                local maxObstacleThickness = 5 -- Grosor máximo de obstáculo que se considera
                local showInfoGui = true -- Mostrar información sobre el objetivo actual
                
                -- Crear cursor invisible en el centro de la pantalla
                local function createInvisibleCursor()
                    local screenGui = Instance.new("ScreenGui")
                    screenGui.Name = "InvisibleCursorGui"
                    screenGui.ResetOnSpawn = false
                    pcall(function() screenGui.IgnoreGuiInset = true end)
                    
                    -- Asignar parent con manejo de errores
                    pcall(function() screenGui.Parent = Player:WaitForChild("PlayerGui") end)
                    if not screenGui.Parent then
                        pcall(function() screenGui.Parent = game:GetService("CoreGui") end)
                    end
                    
                    -- Crear un punto central invisible
                    local cursorPoint = Instance.new("Frame")
                    cursorPoint.Size = UDim2.new(0, 4, 0, 4)
                    cursorPoint.Position = UDim2.new(0.5, -2, 0.5, -2)
                    cursorPoint.BackgroundTransparency = 1 -- Invisible
                    cursorPoint.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                    cursorPoint.BorderSizePixel = 0
                    cursorPoint.Name = "CursorPoint"
                    cursorPoint.Parent = screenGui
                    
                    return cursorPoint
                end
                
                -- Crear HUD de información
                local function createInfoGui()
                    local screenGui = Instance.new("ScreenGui")
                    screenGui.Name = "TargetInfoGui"
                    screenGui.ResetOnSpawn = false
                    pcall(function() screenGui.IgnoreGuiInset = true end)
                    
                    -- Asignar parent con manejo de errores
                    pcall(function() screenGui.Parent = Player:WaitForChild("PlayerGui") end)
                    if not screenGui.Parent then
                        pcall(function() screenGui.Parent = game:GetService("CoreGui") end)
                    end
                    
                    -- Crear panel de información
                    local panel = Instance.new("Frame")
                    panel.Size = UDim2.new(0, 200, 0, 80)
                    panel.Position = UDim2.new(1, -210, 1, -90) -- Esquina inferior derecha
                    panel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                    panel.BackgroundTransparency = 0.5
                    panel.BorderSizePixel = 0
                    panel.Parent = screenGui
                    
                    -- Esquinas redondeadas
                    local corner = Instance.new("UICorner")
                    corner.CornerRadius = UDim.new(0, 6)
                    corner.Parent = panel
                    
                    -- Título
                    local titleLabel = Instance.new("TextLabel")
                    titleLabel.Size = UDim2.new(1, 0, 0, 20)
                    titleLabel.Position = UDim2.new(0, 0, 0, 0)
                    titleLabel.BackgroundTransparency = 1
                    titleLabel.Font = Enum.Font.SourceSansBold
                    titleLabel.TextSize = 14
                    titleLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
                    titleLabel.Text = "AUTO-DISPARO ACTIVADO"
                    titleLabel.Parent = panel
                    
                    -- Información del objetivo
                    local infoLabel = Instance.new("TextLabel")
                    infoLabel.Size = UDim2.new(1, 0, 0, 40)
                    infoLabel.Position = UDim2.new(0, 0, 0, 20)
                    infoLabel.BackgroundTransparency = 1
                    infoLabel.Font = Enum.Font.SourceSans
                    infoLabel.TextSize = 14
                    infoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                    infoLabel.Text = "Buscando objetivo..."
                    infoLabel.TextXAlignment = Enum.TextXAlignment.Center
                    infoLabel.TextYAlignment = Enum.TextYAlignment.Top
                    infoLabel.Parent = panel
                    
                    -- Indicador de estado (círculo)
                    local statusIndicator = Instance.new("Frame")
                    statusIndicator.Size = UDim2.new(0, 12, 0, 12)
                    statusIndicator.Position = UDim2.new(0, 10, 0, 4)
                    statusIndicator.BackgroundColor3 = Color3.fromRGB(255, 100, 100) -- Rojo por defecto
                    statusIndicator.BorderSizePixel = 0
                    statusIndicator.Parent = panel
                    
                    -- Hacer el círculo redondo
                    local statusCorner = Instance.new("UICorner")
                    statusCorner.CornerRadius = UDim.new(1, 0)
                    statusCorner.Parent = statusIndicator
                    
                    -- Botón para activar/desactivar
                    local toggleButton = Instance.new("TextButton")
                    toggleButton.Size = UDim2.new(1, -20, 0, 20)
                    toggleButton.Position = UDim2.new(0, 10, 0, 60)
                    toggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                    toggleButton.BorderColor3 = Color3.fromRGB(100, 100, 100)
                    toggleButton.Text = "ACTIVADO [Alt para Toggle]"
                    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                    toggleButton.Font = Enum.Font.SourceSansSemibold
                    toggleButton.TextSize = 12
                    toggleButton.Parent = panel
                    
                    local buttonCorner = Instance.new("UICorner")
                    buttonCorner.CornerRadius = UDim.new(0, 4)
                    buttonCorner.Parent = toggleButton
                    
                    return {
                        infoLabel = infoLabel,
                        statusIndicator = statusIndicator,
                        toggleButton = toggleButton,
                        gui = screenGui
                    }
                end
                
                -- Verificar si hay un objetivo válido en el cursor
                local function getTargetInCrosshair()
                    -- Crear un rayo desde el centro de la pantalla
                    local viewportSize = Camera.ViewportSize
                    local screenCenter = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
                    local unitRay = Camera:ScreenPointToRay(screenCenter.X, screenCenter.Y)
                    
                    -- Configurar parámetros del rayo
                    local raycastParams = RaycastParams.new()
                    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
                    raycastParams.FilterDescendantsInstances = {Player.Character}
                    
                    -- Lanzar el rayo para detectar objetivos
                    local rayResult = workspace:Raycast(unitRay.Origin, unitRay.Direction * targetDetectionRange, raycastParams)
                    
                    if rayResult then
                        -- Buscar el modelo del personaje asociado con la parte golpeada
                        local hitPart = rayResult.Instance
                        local hitModel = hitPart:FindFirstAncestorOfClass("Model")
                        
                        if hitModel then
                            local humanoid = hitModel:FindFirstChildOfClass("Humanoid")
                            local hitPlayer = Players:GetPlayerFromCharacter(hitModel)
                            
                            -- Verificar si es un jugador válido y no está muerto
                            if humanoid and hitPlayer and hitPlayer ~= Player and humanoid.Health > 0 then
                                -- Verificar si hay un obstáculo entre el jugador y el objetivo
                                local characterHead = Player.Character and Player.Character:FindFirstChild("Head")
                                if characterHead then
                                    local obstacleParams = RaycastParams.new()
                                    obstacleParams.FilterType = Enum.RaycastFilterType.Blacklist
                                    obstacleParams.FilterDescendantsInstances = {Player.Character, hitModel}
                                    
                                    -- Calcular dirección hacia la cabeza del objetivo
                                    local targetHead = hitModel:FindFirstChild("Head") or hitPart
                                    local targetPos = targetHead.Position
                                    
                                    local toTarget = (targetPos - characterHead.Position)
                                    local distance = toTarget.Magnitude
                                    local direction = toTarget.Unit
                                    
                                    -- Comprobar obstáculos
                                    local obstacleResult = workspace:Raycast(characterHead.Position, direction * distance, obstacleParams)
                                    
                                    if not obstacleResult or (obstacleResult.Distance > distance - maxObstacleThickness) then
                                        -- No hay obstáculo o es muy delgado, podemos disparar
                                        return {
                                            player = hitPlayer,
                                            character = hitModel,
                                            humanoid = humanoid,
                                            hitPart = hitPart,
                                            position = targetPos,
                                            distance = distance,
                                            direction = direction
                                        }
                                    end
                                end
                            end
                        end
                    end
                    
                    return nil
                end
                
                -- Función para disparar al objetivo
                local function shootAtTarget(target)
                    if not target then return end
                    
                    local currentTime = tick()
                    if currentTime - lastShootTime < shootDelay then
                        return
                    end
                    
                    lastShootTime = currentTime
                    
                    -- Obtener el arma del jugador
                    local character = Player.Character
                    if not character then return end
                    
                    -- Buscar el arma - primero intentamos con "Sniper" y luego con cualquier herramienta
                    local weapon = character:FindFirstChild("Sniper")
                    if not weapon then
                        weapon = character:FindFirstChildOfClass("Tool")
                    end
                    
                    if not weapon then return end
                    
                    -- Preparar el disparo
                    local playerHead = character:FindFirstChild("Head")
                    if not playerHead then return end
                    
                    -- Calcular el origen y dirección para el disparo
                    local origin = playerHead.Position
                    local dir = (target.position - origin).Unit
                    
                    -- Crear los argumentos para el disparo
                    local args = {
                        [1] = weapon,
                        [2] = {
                            ["id"] = 16,
                            ["charge"] = 0,
                            ["origin"] = origin,
                            ["dir"] = dir
                        }
                    }
                    
                    -- Disparar usando el sistema de armas del juego
                    pcall(function()
                        ReplicatedStorage:WaitForChild("WeaponsSystem"):WaitForChild("Network"):WaitForChild("WeaponFired"):FireServer(unpack(args))
                    end)
                end
                
                -- Iniciar el auto disparo
                local function startAutoShoot()
                    -- Crear elementos visuales
                    local cursorPoint = createInvisibleCursor()
                    local infoGui = createInfoGui()
                    
                    -- Bucle principal de detección y disparo
                    local connection = RunService.RenderStepped:Connect(function()
                        if not autoShootEnabled then
                            infoGui.infoLabel.Text = "Auto-Disparo DESACTIVADO"
                            infoGui.statusIndicator.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
                            infoGui.toggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                            infoGui.toggleButton.Text = "DESACTIVADO [Alt para Toggle]"
                            return
                        end
                        
                        infoGui.statusIndicator.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
                        infoGui.toggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
                        infoGui.toggleButton.Text = "ACTIVADO [Alt para Toggle]"
                        
                        -- Buscar objetivo en el cursor
                        local target = getTargetInCrosshair()
                        
                        if target then
                            -- Actualizar información en GUI
                            infoGui.infoLabel.Text = string.format("Objetivo: %s\nDistancia: %d studs\nSalud: %d%%", 
                                target.player.Name,
                                math.floor(target.distance), 
                                math.floor(target.humanoid.Health / target.humanoid.MaxHealth * 100))
                            
                            -- Disparar al objetivo
                            shootAtTarget(target)
                        else
                            infoGui.infoLabel.Text = "Buscando objetivo..."
                        end
                    end)
                    
                    -- Detectar tecla para activar/desactivar
                    UserInputService.InputBegan:Connect(function(input, gameProcessed)
                        if not gameProcessed and input.KeyCode == Enum.KeyCode.LeftAlt then
                            autoShootEnabled = not autoShootEnabled
                            
                            -- Notificar cambio de estado
                            game:GetService("StarterGui"):SetCore("SendNotification", {
                                Title = autoShootEnabled and "Auto-Disparo ACTIVADO" or "Auto-Disparo DESACTIVADO",
                                Text = autoShootEnabled and "Disparando automáticamente en el cursor" or "Disparo automático pausado",
                                Duration = 2
                            })
                        end
                    end)
                    
                    -- Opción para alternar con botón GUI
                    infoGui.toggleButton.MouseButton1Click:Connect(function()
                        autoShootEnabled = not autoShootEnabled
                    end)
                    
                    -- Limpiar al desconectar
                    Player.CharacterRemoving:Connect(function()
                        connection:Disconnect()
                    end)
                    
                    -- Notificar inicialización
                    game:GetService("StarterGui"):SetCore("SendNotification", {
                        Title = "Auto-Disparo Inicializado",
                        Text = "Presiona ALT para activar/desactivar",
                        Duration = 5
                    })
                end
                
                -- Iniciar cuando el personaje esté listo
                if Player.Character then
                    startAutoShoot()
                else
                    Player.CharacterAdded:Wait()
                    startAutoShoot()
                end
            ]]
        },
        {
            name = "Auto Drops Recolector (Móvil)",
            code = [[
                local Players = game:GetService("Players")
                local RunService = game:GetService("RunService")
                local VirtualInputManager = game:GetService("VirtualInputManager")
                local TweenService = game:GetService("TweenService")
                local UserInputService = game:GetService("UserInputService")
                local ContextActionService = game:GetService("ContextActionService")
                local Player = Players.LocalPlayer
                local Character = Player.Character or Player.CharacterAdded:Wait()
                local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
                local Humanoid = Character:WaitForChild("Humanoid")
                
                -- Configuración
                local running = true
                local collectionDelay = 1.5 -- Tiempo entre recolecciones
                local teleportHeight = 5 -- Altura extra al teleportar para evitar obstáculos
                local auraRadius = 15 -- Radio del aura de recolección en studs
                local collectAgainDelay = 120 -- Tiempo para volver a recolectar todos los drops (2 minutos)
                local isMobile = UserInputService.TouchEnabled
                local useAuraMode = true -- Activar modo aura (mejor para móviles)
                
                -- Crear interfaz
                local function createProgressInterface()
                    local screenGui = Instance.new("ScreenGui")
                    screenGui.Name = "DropCollectorGui"
                    screenGui.ResetOnSpawn = false
                    pcall(function() screenGui.IgnoreGuiInset = true end)
                    
                    -- Asignar parent
                    pcall(function() screenGui.Parent = Player:WaitForChild("PlayerGui") end)
                    if not screenGui.Parent then
                        pcall(function() screenGui.Parent = game:GetService("CoreGui") end)
                    end
                    
                    -- Panel principal - Adaptado para móviles con botones más grandes
                    local mainPanel = Instance.new("Frame")
                    mainPanel.Name = "MainPanel"
                    
                    -- Ajustar tamaño para móviles
                    if isMobile then
                        mainPanel.Size = UDim2.new(0, 280, 0, 180)
                        mainPanel.Position = UDim2.new(0, 10, 0, 10)
                    else
                        mainPanel.Size = UDim2.new(0, 250, 0, 150)
                        mainPanel.Position = UDim2.new(0, 10, 0, 10)
                    end
                    
                    mainPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
                    mainPanel.BackgroundTransparency = 0.2
                    mainPanel.BorderSizePixel = 0
                    mainPanel.Parent = screenGui
                    
                    -- Esquinas redondeadas
                    local uiCorner = Instance.new("UICorner")
                    uiCorner.CornerRadius = UDim.new(0, 8)
                    uiCorner.Parent = mainPanel
                    
                    -- Título
                    local titleLabel = Instance.new("TextLabel")
                    titleLabel.Name = "TitleLabel"
                    titleLabel.Size = UDim2.new(1, 0, 0, 30)
                    titleLabel.Position = UDim2.new(0, 0, 0, 0)
                    titleLabel.BackgroundTransparency = 1
                    titleLabel.Font = Enum.Font.SourceSansBold
                    titleLabel.TextSize = isMobile and 20 or 18
                    titleLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
                    titleLabel.Text = "RECOLECTOR DE DROPS MÓVIL"
                    titleLabel.Parent = mainPanel
                    
                    -- Status
                    local statusLabel = Instance.new("TextLabel")
                    statusLabel.Name = "StatusLabel"
                    statusLabel.Size = UDim2.new(1, -20, 0, 20)
                    statusLabel.Position = UDim2.new(0, 10, 0, 35)
                    statusLabel.BackgroundTransparency = 1
                    statusLabel.Font = Enum.Font.SourceSans
                    statusLabel.TextSize = isMobile and 18 or 16
                    statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
                    statusLabel.Text = "Estado: Buscando drops..."
                    statusLabel.Parent = mainPanel
                    
                    -- Modo
                    local modeLabel = Instance.new("TextLabel")
                    modeLabel.Name = "ModeLabel"
                    modeLabel.Size = UDim2.new(1, -20, 0, 20)
                    modeLabel.Position = UDim2.new(0, 10, 0, 55)
                    modeLabel.BackgroundTransparency = 1
                    modeLabel.Font = Enum.Font.SourceSans
                    modeLabel.TextSize = isMobile and 18 or 16
                    modeLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
                    modeLabel.TextXAlignment = Enum.TextXAlignment.Left
                    modeLabel.Text = "Modo: " .. (useAuraMode and "Aura de recolección" or "Teleport")
                    modeLabel.Parent = mainPanel
                    
                    -- Counter
                    local counterLabel = Instance.new("TextLabel")
                    counterLabel.Name = "CounterLabel"
                    counterLabel.Size = UDim2.new(1, -20, 0, 20)
                    counterLabel.Position = UDim2.new(0, 10, 0, 75)
                    counterLabel.BackgroundTransparency = 1
                    counterLabel.Font = Enum.Font.SourceSans
                    counterLabel.TextSize = isMobile and 18 or 16
                    counterLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
                    counterLabel.TextXAlignment = Enum.TextXAlignment.Left
                    counterLabel.Text = "Drops recogidos: 0"
                    counterLabel.Parent = mainPanel
                    
                    -- Fila de botones
                    local buttonsY = isMobile and 100 or 95
                    local buttonHeight = isMobile and 35 or 30
                    
                    -- Botón parar
                    local stopButton = Instance.new("TextButton")
                    stopButton.Name = "StopButton"
                    stopButton.Size = UDim2.new(0.3, 0, 0, buttonHeight)
                    stopButton.Position = UDim2.new(0.025, 0, 0, buttonsY)
                    stopButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
                    stopButton.BorderSizePixel = 0
                    stopButton.Font = Enum.Font.SourceSansBold
                    stopButton.TextSize = isMobile and 18 or 16
                    stopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                    stopButton.Text = "PARAR"
                    stopButton.Parent = mainPanel
                    
                    -- Botón modo
                    local modeButton = Instance.new("TextButton")
                    modeButton.Name = "ModeButton"
                    modeButton.Size = UDim2.new(0.3, 0, 0, buttonHeight)
                    modeButton.Position = UDim2.new(0.35, 0, 0, buttonsY)
                    modeButton.BackgroundColor3 = Color3.fromRGB(50, 150, 200)
                    modeButton.BorderSizePixel = 0
                    modeButton.Font = Enum.Font.SourceSansBold
                    modeButton.TextSize = isMobile and 18 or 16
                    modeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                    modeButton.Text = "MODO"
                    modeButton.Parent = mainPanel
                    
                    -- Botón reanudar
                    local resumeButton = Instance.new("TextButton")
                    resumeButton.Name = "ResumeButton"
                    resumeButton.Size = UDim2.new(0.3, 0, 0, buttonHeight)
                    resumeButton.Position = UDim2.new(0.675, 0, 0, buttonsY)
                    resumeButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
                    resumeButton.BorderSizePixel = 0
                    resumeButton.Font = Enum.Font.SourceSansBold
                    resumeButton.TextSize = isMobile and 18 or 16
                    resumeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                    resumeButton.Text = "INICIAR"
                    resumeButton.Parent = mainPanel
                    
                    -- Esquinas para botones
                    local function addCorner(button)
                        local corner = Instance.new("UICorner")
                        corner.CornerRadius = UDim.new(0, 6)
                        corner.Parent = button
                        return corner
                    end
                    
                    addCorner(stopButton)
                    addCorner(modeButton)
                    addCorner(resumeButton)
                    
                    -- Visualizador de aura (solo en modo aura)
                    local auraFrame = Instance.new("Frame")
                    auraFrame.Name = "AuraVisualizer"
                    auraFrame.Size = UDim2.new(1, -20, 0, buttonHeight)
                    auraFrame.Position = UDim2.new(0, 10, 0, buttonsY + buttonHeight + 10)
                    auraFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
                    auraFrame.BorderSizePixel = 0
                    auraFrame.Parent = mainPanel
                    addCorner(auraFrame)
                    
                    local auraBar = Instance.new("Frame")
                    auraBar.Name = "AuraBar"
                    auraBar.Size = UDim2.new(0, 0, 1, 0)
                    auraBar.BackgroundColor3 = Color3.fromRGB(50, 220, 100)
                    auraBar.BorderSizePixel = 0
                    auraBar.Parent = auraFrame
                    addCorner(auraBar)
                    
                    local auraText = Instance.new("TextLabel")
                    auraText.Name = "AuraText"
                    auraText.Size = UDim2.new(1, 0, 1, 0)
                    auraText.BackgroundTransparency = 1
                    auraText.Font = Enum.Font.SourceSansSemibold
                    auraText.TextSize = isMobile and 16 or 14
                    auraText.TextColor3 = Color3.fromRGB(255, 255, 255)
                    auraText.Text = "Radio: " .. auraRadius .. " studs"
                    auraText.Parent = auraFrame
                    
                    -- Eventos de botones
                    stopButton.MouseButton1Click:Connect(function()
                        running = false
                        statusLabel.Text = "Estado: Detenido"
                        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
                    end)
                    
                    resumeButton.MouseButton1Click:Connect(function()
                        running = true
                        statusLabel.Text = "Estado: Buscando drops..."
                        statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                    end)
                    
                    modeButton.MouseButton1Click:Connect(function()
                        useAuraMode = not useAuraMode
                        modeLabel.Text = "Modo: " .. (useAuraMode and "Aura de recolección" or "Teleport")
                        
                        -- Actualizar interfaz según el modo
                        if useAuraMode then
                            auraFrame.Visible = true
                            modeButton.BackgroundColor3 = Color3.fromRGB(50, 150, 200)
                        else
                            auraFrame.Visible = false
                            modeButton.BackgroundColor3 = Color3.fromRGB(150, 100, 200)
                        end
                    end)
                    
                    return {
                        statusLabel = statusLabel,
                        modeLabel = modeLabel,
                        counterLabel = counterLabel,
                        auraBar = auraBar,
                        auraText = auraText,
                        gui = screenGui
                    }
                end
                
                -- Crear visualización del aura
                local function createAuraVisualization()
                    if workspace:FindFirstChild("DropCollectorAura") then
                        workspace.DropCollectorAura:Destroy()
                    end
                    
                    local aura = Instance.new("Part")
                    aura.Name = "DropCollectorAura"
                    aura.Anchored = true
                    aura.CanCollide = false
                    aura.Size = Vector3.new(auraRadius * 2, 0.2, auraRadius * 2)
                    aura.Shape = Enum.PartType.Cylinder
                    aura.Orientation = Vector3.new(0, 0, 90)
                    aura.Material = Enum.Material.Neon
                    aura.Transparency = 0.7
                    aura.Color = Color3.fromRGB(50, 220, 100)
                    
                    -- Solo visible para el jugador local
                    local noTouch = Instance.new("IntValue")
                    noTouch.Name = "NoTouch"
                    noTouch.Parent = aura
                    
                    aura.Parent = workspace
                    return aura
                end
                
                -- Función para simular input tactil (tap y hold)
                local function simulateTapAndHold()
                    -- Múltiples métodos para asegurar que funcione en móviles
                    local holdDuration = 2 -- Duración en segundos
                    
                    -- Método 1: Virtual Input Manager (móvil)
                    pcall(function()
                        if isMobile then
                            -- Simular presión prolongada en el centro de la pantalla
                            local viewportSize = workspace.CurrentCamera.ViewportSize
                            local centerX = viewportSize.X / 2
                            local centerY = viewportSize.Y / 2
                            
                            -- Simular presionar
                            VirtualInputManager:SendTouchEvent(
                                Enum.UserInputState.Begin, 
                                Vector2.new(centerX, centerY), 
                                true
                            )
                            
                            -- Mantener presionado
                            wait(holdDuration)
                            
                            -- Simular soltar
                            VirtualInputManager:SendTouchEvent(
                                Enum.UserInputState.End, 
                                Vector2.new(centerX, centerY), 
                                true
                            )
                        else
                            -- En PC, usar la tecla E
                            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                            wait(holdDuration)
                            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                        end
                    end)
                    
                    -- Método 2: Simular toques rápidos (spam tap para móviles)
                    pcall(function()
                        if isMobile then
                            local viewportSize = workspace.CurrentCamera.ViewportSize
                            local centerX = viewportSize.X / 2
                            local centerY = viewportSize.Y / 2
                            
                            -- Enviar múltiples toques rápidos (spam tap)
                            for i = 1, 10 do
                                VirtualInputManager:SendTouchEvent(
                                    Enum.UserInputState.Begin, 
                                    Vector2.new(centerX, centerY), 
                                    true
                                )
                                wait(0.05)
                                VirtualInputManager:SendTouchEvent(
                                    Enum.UserInputState.End, 
                                    Vector2.new(centerX, centerY), 
                                    true
                                )
                                wait(0.1)
                            end
                        end
                    end)
                    
                    -- Método 3: Activar manualmente cualquier prompt visible
                    pcall(function()
                        for _, prompt in pairs(workspace:GetDescendants()) do
                            if prompt:IsA("ProximityPrompt") and prompt.Enabled then
                                fireproximityprompt(prompt)
                            end
                        end
                    end)
                    
                    -- Método 4: Disparar eventos de interacción comunes
                    pcall(function()
                        -- Intentar activar eventos de interacción comunes en Roblox
                        for _, obj in pairs(workspace:GetDescendants()) do
                            if obj:IsA("ClickDetector") then
                                obj.MouseClick:Fire()
                            end
                        end
                    end)
                    
                    -- Método 5: Invocar directamente funciones UI de recogida
                    pcall(function()
                        for _, ui in pairs(Player.PlayerGui:GetDescendants()) do
                            if ui:IsA("TextButton") and 
                               (string.find(string.lower(ui.Text), "recoger") or 
                                string.find(string.lower(ui.Text), "collect") or
                                string.find(string.lower(ui.Text), "pick")) then
                                -- Simular click en botones de recolección
                                ui.MouseButton1Click:Fire()
                            end
                        end
                    end)
                    
                    -- Método 6: Activar acción principal de cualquier herramienta equipada
                    pcall(function()
                        local tool = Character:FindFirstChildOfClass("Tool")
                        if tool and tool:FindFirstChild("RemoteEvent") then
                            -- Intentar activar múltiples veces
                            for i = 1, 5 do
                                tool.RemoteEvent:FireServer()
                                wait(holdDuration/5)
                            end
                        end
                    end)
                end
                
                -- Función para teleportarse a una posición
                local function teleportTo(position)
                    if not Character or not HumanoidRootPart then return end
                    
                    -- Posición segura elevada para evitar colisiones
                    local targetPosition = Vector3.new(
                        position.X,
                        position.Y + teleportHeight,
                        position.Z
                    )
                    
                    -- Teletransportar
                    HumanoidRootPart.CFrame = CFrame.new(targetPosition)
                    
                    -- Bajar suavemente hasta la posición final
                    local finalPosition = Vector3.new(position.X, position.Y + 2, position.Z)
                    local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                    local tween = TweenService:Create(
                        HumanoidRootPart,
                        tweenInfo,
                        {CFrame = CFrame.new(finalPosition)}
                    )
                    tween:Play()
                    
                    -- Esperar a que termine
                    tween.Completed:Wait()
                end
                
                -- Función para encontrar drops cercanos (para modo aura)
                local function findNearbyDrops(maxDistance)
                    if not Character or not HumanoidRootPart then return {} end
                    
                    local nearbyDrops = {}
                    local playerPos = HumanoidRootPart.Position
                    
                    -- Buscar en la carpeta Drop primero
                    local dropsFolder = workspace:FindFirstChild("Drop")
                    if dropsFolder then
                        for _, drop in pairs(dropsFolder:GetChildren()) do
                            if drop:IsA("Model") or drop:IsA("Part") then
                                local primaryPart = drop:IsA("Model") and 
                                                    (drop.PrimaryPart or drop:FindFirstChildWhichIsA("BasePart")) or 
                                                    drop
                                
                                if primaryPart then
                                    local distance = (primaryPart.Position - playerPos).Magnitude
                                    if distance <= maxDistance then
                                        table.insert(nearbyDrops, {
                                            drop = drop,
                                            part = primaryPart,
                                            distance = distance
                                        })
                                    end
                                end
                            end
                        end
                    else
                        -- Si no existe la carpeta Drop, buscar en todo el workspace
                        for _, obj in pairs(workspace:GetChildren()) do
                            if obj.Name == "Drop" and (obj:IsA("Model") or obj:IsA("Part")) then
                                local primaryPart = obj:IsA("Model") and 
                                                    (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")) or 
                                                    obj
                                
                                if primaryPart then
                                    local distance = (primaryPart.Position - playerPos).Magnitude
                                    if distance <= maxDistance then
                                        table.insert(nearbyDrops, {
                                            drop = obj,
                                            part = primaryPart,
                                            distance = distance
                                        })
                                    end
                                end
                            end
                        end
                    end
                    
                    -- Ordenar por distancia (más cercanos primero)
                    table.sort(nearbyDrops, function(a, b)
                        return a.distance < b.distance
                    end)
                    
                    return nearbyDrops
                end
                
                -- Función principal para recolectar drops
                local function collectDrops()
                    -- Crear interfaz
                    local ui = createProgressInterface()
                    local collectedCount = 0
                    
                    -- Almacenar drops ya recogidos
                    local collectedDrops = {}
                    
                    -- Crear visualización de aura
                    local auraVisualization = createAuraVisualization()
                    
                    -- Actualizar posición del aura
                    RunService.Heartbeat:Connect(function()
                        if running and useAuraMode and Character and Character:FindFirstChild("HumanoidRootPart") then
                            auraVisualization.CFrame = CFrame.new(HumanoidRootPart.Position) * CFrame.Angles(0, 0, math.rad(90))
                            auraVisualization.Transparency = 0.7
                            auraVisualization.Size = Vector3.new(auraRadius * 2, 0.2, auraRadius * 2)
                        else
                            auraVisualization.Transparency = 1
                        end
                    end)
                    
                    -- Bucle principal de recolección
                    while wait(0.5) do
                        -- Respetar el toggle
                        if not running then
                            wait(1)
                            continue
                        end
                        
                        -- Comprobar si el personaje está disponible
                        if not Player.Character or not Player.Character:FindFirstChild("HumanoidRootPart") then
                            Character = Player.Character or Player.CharacterAdded:Wait()
                            HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
                            Humanoid = Character:WaitForChild("Humanoid")
                            ui.statusLabel.Text = "Estado: Esperando personaje..."
                            wait(1)
                            continue
                        end
                        
                        -- Actualizar el texto del aura
                        ui.auraText.Text = "Radio: " .. auraRadius .. " studs"
                        
                        -- MODO AURA: Recolectar todo lo que esté dentro del radio sin teleport
                        if useAuraMode then
                            local nearbyDrops = findNearbyDrops(auraRadius)
                            
                            if #nearbyDrops > 0 then
                                -- Actualizar barra de progreso
                                for i, dropInfo in ipairs(nearbyDrops) do
                                    -- Solo procesar si no está ya recogido
                                    if not collectedDrops[dropInfo.drop] then
                                        local dropName = dropInfo.drop.Name or "Drop"
                                        local progress = i / #nearbyDrops
                                        
                                        -- Actualizar UI
                                        ui.statusLabel.Text = "Estado: Recogiendo " .. dropName .. " (" .. i .. "/" .. #nearbyDrops .. ")"
                                        ui.auraBar.Size = UDim2.new(progress, 0, 1, 0)
                                        
                                        -- No teletransportar, solo activar recogida
                                        simulateTapAndHold()
                                        
                                        -- Marcar como recogido
                                        collectedDrops[dropInfo.drop] = true
                                        collectedCount = collectedCount + 1
                                        ui.counterLabel.Text = "Drops recogidos: " .. collectedCount
                                        
                                        -- Notificar
                                        game:GetService("StarterGui"):SetCore("SendNotification", {
                                            Title = "Drop Recogido",
                                            Text = "Se ha recogido: " .. dropName,
                                            Duration = 2
                                        })
                                        
                                        -- Pequeña pausa entre recogidas
                                        wait(0.5)
                                    end
                                end
                                
                                -- Resetear barra
                                ui.auraBar.Size = UDim2.new(1, 0, 1, 0)
                                wait(collectionDelay)
                            else
                                ui.statusLabel.Text = "Estado: No hay drops cercanos, buscando..."
                                ui.auraBar.Size = UDim2.new(0, 0, 1, 0)
                                wait(1)
                            end
                        else
                            -- MODO TELEPORT: Buscar drops en el juego
                            local dropsFolder = workspace:FindFirstChild("Drop")
                            local drops = {}
                            
                            -- Buscar drops en la carpeta Drop
                            if dropsFolder then
                                for _, drop in pairs(dropsFolder:GetChildren()) do
                                    if drop:IsA("Model") or drop:IsA("Part") then
                                        table.insert(drops, drop)
                                    end
                                end
                            else
                                -- Si no existe la carpeta, buscar en el workspace
                                for _, obj in pairs(workspace:GetChildren()) do
                                    if obj.Name == "Drop" and (obj:IsA("Model") or obj:IsA("Part")) then
                                        table.insert(drops, obj)
                                    end
                                end
                            end
                            
                            -- Si no se encontraron drops, reintentar
                            if #drops == 0 then
                                ui.statusLabel.Text = "Estado: No se encontraron drops, buscando..."
                                wait(3)
                                
                                -- Reiniciar lista cada cierto tiempo
                                if os.time() % collectAgainDelay < 1 then
                                    ui.statusLabel.Text = "Estado: Reiniciando ciclo de recolección..."
                                    collectedDrops = {}
                                    wait(1)
                                end
                                
                                continue
                            end
                            
                            local foundNewDrop = false
                            
                            -- Procesar cada drop
                            for _, drop in pairs(drops) do
                                -- Verificar si ya se recogió este drop
                                if collectedDrops[drop] then
                                    continue
                                end
                                
                                foundNewDrop = true
                                local primaryPart = drop:IsA("Model") and 
                                                    (drop.PrimaryPart or drop:FindFirstChildWhichIsA("BasePart")) or 
                                                    drop
                                
                                if primaryPart then
                                    ui.statusLabel.Text = "Estado: Teletransportando a drop " .. drop.Name
                                    
                                    -- Teleport al drop
                                    teleportTo(primaryPart.Position)
                                    wait(0.5)
                                    
                                    -- Intentar activar el drop con múltiples métodos
                                    ui.statusLabel.Text = "Estado: Recogiendo drop..."
                                    simulateTapAndHold()
                                    
                                    -- Marcar como recogido
                                    collectedDrops[drop] = true
                                    collectedCount = collectedCount + 1
                                    ui.counterLabel.Text = "Drops recogidos: " .. collectedCount
                                    
                                    -- Notificar
                                    game:GetService("StarterGui"):SetCore("SendNotification", {
                                        Title = "Drop Recogido",
                                        Text = "Se ha recogido: " .. drop.Name,
                                        Duration = 2
                                    })
                                    
                                    -- Esperar entre drops
                                    wait(collectionDelay)
                                    break
                                end
                            end
                            
                            -- Si no se encontraron nuevos drops
                            if not foundNewDrop then
                                ui.statusLabel.Text = "Estado: Todos los drops recogidos, esperando..."
                                wait(5)
                                
                                -- Reiniciar lista cada cierto tiempo
                                if os.time() % collectAgainDelay < 1 then
                                    ui.statusLabel.Text = "Estado: Reiniciando ciclo de recolección..."
                                    collectedDrops = {}
                                    wait(1)
                                end
                            end
                        end
                    end
                end
                
                -- Detectar si es dispositivo móvil y mostrar mensaje apropiado
                local startMessage = isMobile and 
                    "Iniciando recolector con soporte para móviles..." or
                    "Iniciando recolección automática..."
                
                -- Notificar inicio
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title = "Auto Recolector de Drops",
                    Text = startMessage,
                    Duration = 5
                })
                
                -- Iniciar cuando el personaje esté listo
                if Player.Character then
                    collectDrops()
                else
                    Player.CharacterAdded:Wait()
                    collectDrops()
                end
            ]]
        }
    }
    
    -- Añadir scripts predeterminados
    for _, scriptData in ipairs(defaultScripts) do
        table.insert(savedScripts, scriptData)
    end
    
    updateScriptsList()
    
    -- Auto-ejecución del Auto-Disparo desactivada
    -- if savedScripts[4] and savedScripts[4].code then
    --     pcall(function()
    --         loadstring(savedScripts[4].code)()
    --         updateStatus("Auto-Disparo Avanzado activado automáticamente", Color3.fromRGB(0, 255, 150))
    --     end)
    -- end
end

-- Conectar eventos a los botones
ExecuteButton.MouseButton1Click:Connect(startExecution)
StopButton.MouseButton1Click:Connect(stopExecution)
SaveButton.MouseButton1Click:Connect(saveCurrentScript)

-- Mejorar manejo del textbox para scripts largos
ScriptBox:GetPropertyChangedSignal("TextBounds"):Connect(function()
    -- Ajustar automáticamente el tamaño del canvas según el contenido
    local textBounds = ScriptBox.TextBounds
    ScriptBoxScrollBar.CanvasSize = UDim2.new(0, 0, 0, math.max(textBounds.Y + 20, ScriptBoxScrollBar.AbsoluteSize.Y))
end)

-- Prevenir que se cierre al recargar la GUI
local function onRemoval()
    if executing then
        local newGui = game:GetService("CoreGui"):FindFirstChild("InfiniteExecutor")
        if not newGui then
            executing = false
        end
    end
end

ScreenGui.AncestryChanged:Connect(onRemoval)

-- Inicializar la aplicación
addDefaultScripts()
updateStatus("Listo para ejecutar", Color3.fromRGB(0, 200, 255))

-- Mostrar mensaje de bienvenida
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Fortline Script Ejecutor v2.0",
    Text = "Selecciona y ejecuta scripts manualmente",
    Duration = 5
})
