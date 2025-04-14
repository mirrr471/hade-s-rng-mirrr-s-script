
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")


local isTeleportActive = false


local function teleportTo(targetPos)
    if rootPart then
        local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Linear)
        local tween = TweenService:Create(rootPart, tweenInfo, {CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))})
        tween:Play()
        tween.Completed:Wait()
        print("Teleport: ", targetPos)
    else
        warn("The character is not ready")
    end
end

local function triggerPrompt(prompt)
    if prompt:IsA("ProximityPrompt") then
        fireproximityprompt(prompt)
        print("item: ", prompt:GetFullName())
    end
end

-- 가장 가까운 아이템 찾기 ("gwa gwa" 제외)
local function findClosestItem()
    local items = {}
    local itemsFolder = workspace:FindFirstChild("Items")
    if itemsFolder then
        for _, item in pairs(itemsFolder:GetChildren()) do
            if not (item.Name:lower():match("gwa") or item.Name:lower():match("gwa gwa")) then
                for _, obj in pairs(item:GetDescendants()) do
                    if obj:IsA("ProximityPrompt") then
                        table.insert(items, obj)
                    end
                end
            end
        end
    end

    local closestItem = nil
    local minDistance = 500
    for _, item in pairs(items) do
        local targetPos
        if item.Parent and item.Parent:IsA("BasePart") then
            targetPos = item.Parent.Position
        elseif item.Parent.Parent and item.Parent.Parent:IsA("BasePart") then
            targetPos = item.Parent.Parent.Position
        else
            continue
        end

        local distance = (targetPos - rootPart.Position).Magnitude
        if distance < minDistance then
            minDistance = distance
            closestItem = item
        end
    end
    return closestItem, minDistance
end

local function createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TeleportGUI"
    screenGui.Parent = player.PlayerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 250, 0, 200)
    frame.Position = UDim2.new(0.5, -125, 0.5, -100)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BackgroundTransparency = 0.1
    frame.Parent = screenGui

    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 15)
    frameCorner.Parent = frame

    local frameGradient = Instance.new("UIGradient")
    frameGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 50, 50)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 20))
    }
    frameGradient.Rotation = 45
    frameGradient.Parent = frame

    local frameStroke = Instance.new("UIStroke")
    frameStroke.Thickness = 2
    frameStroke.Color = Color3.fromRGB(0, 170, 255)
    frameStroke.Parent = frame


    frame.Active = true
    frame.Draggable = true


    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(0, 230, 0, 40)
    titleLabel.Position = UDim2.new(0.5, -115, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "made by 어무니"
    titleLabel.TextColor3 = Color3.fromRGB(0, 170, 255)
    titleLabel.TextScaled = true
    titleLabel.Parent = frame

    -- 닫기 버튼
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -40, 0, 10)
    closeButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.TextScaled = true
    closeButton.Parent = frame

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 5)
    closeCorner.Parent = closeButton

    -- 상태 라벨
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(0, 230, 0, 30)
    statusLabel.Position = UDim2.new(0.5, -115, 0, 60)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Condition : Waiting"
    statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    statusLabel.TextScaled = true
    statusLabel.Parent = frame

    -- Auto Get Item 체크박스
    local autoGetButton = Instance.new("TextButton")
    autoGetButton.Size = UDim2.new(0, 210, 0, 50)
    autoGetButton.Position = UDim2.new(0.5, -105, 0, 100)
    autoGetButton.Text = "Auto Get Item OFF"
    autoGetButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    autoGetButton.TextColor3 = Color3.new(1, 1, 1)
    autoGetButton.TextScaled = true
    autoGetButton.Parent = frame

    local autoGetCorner = Instance.new("UICorner")
    autoGetCorner.CornerRadius = UDim.new(0, 10)
    autoGetCorner.Parent = autoGetButton

    local autoGetStroke = Instance.new("UIStroke")
    autoGetStroke.Thickness = 1
    autoGetStroke.Color = Color3.new(1, 1, 1)
    autoGetStroke.Parent = autoGetButton

    -- 호버 효과 (Auto Get Item 버튼)
    autoGetButton.MouseEnter:Connect(function()
        local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Sine)
        TweenService:Create(autoGetButton, tweenInfo, {BackgroundColor3 = Color3.fromRGB(255, 50, 50)}):Play()
    end)
    autoGetButton.MouseLeave:Connect(function()
        local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Sine)
        TweenService:Create(autoGetButton, tweenInfo, {BackgroundColor3 = isTeleportActive and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)}):Play()
    end)

    -- 닫기 버튼 동작 (완전히 닫기)
    closeButton.MouseButton1Click:Connect(function()
        screenGui:Destroy() -- UI와 스크립트 완전히 종료
    end)

    -- Auto Get Item 버튼 동작
    autoGetButton.MouseButton1Click:Connect(function()
        isTeleportActive = not isTeleportActive
        autoGetButton.Text = isTeleportActive and "Auto Get Item ON" or "Auto Get Item OFF"
        autoGetButton.BackgroundColor3 = isTeleportActive and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
        statusLabel.Text = isTeleportActive and "Status: On the move" or "Condition : Waiting"

        if isTeleportActive then
            -- 텔레포트 및 아이템 수집 루프
            spawn(function()
                while true do
                    if not isTeleportActive then break end -- 상태 체크로 루프 종료
                    local closestItem, distance = findClosestItem()
                    if closestItem then
                        print("Nearest item: ", closestItem:GetFullName(), " Distance: ", distance)
                        local targetPos
                        if closestItem.Parent and closestItem.Parent:IsA("BasePart") then
                            targetPos = closestItem.Parent.Position
                        elseif closestItem.Parent.Parent and closestItem.Parent.Parent:IsA("BasePart") then
                            targetPos = closestItem.Parent.Parent.Position
                        else
                            warn("Item location not found: ", closestItem:GetFullName())
                            break
                        end
                        teleportTo(targetPos)
                        wait(0.1)
                        triggerPrompt(closestItem)
                    else
                        print("There are no items close to you")
						wait(1)
                    end
                    wait(0.5)
                end
                isTeleportActive = false
                autoGetButton.Text = "Auto Get Item OFF"
                autoGetButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                statusLabel.Text = "Status: Waiting"
            end)
        end
    end)

    return screenGui, frame
end

-- 초기 UI 생성
local gui, mainFrame = createUI()

-- 캐릭터 리스폰 시 재설정
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    rootPart = newCharacter:WaitForChild("HumanoidRootPart")
    if gui then
        gui:Destroy()
    end
    gui, mainFrame = createUI()
end)
