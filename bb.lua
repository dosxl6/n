
spawn(function()
    function anticrashSkid(player)
        function anticrashChar(char)
            local hum = char:WaitForChild("Humanoid", 5)
            local anim = hum:WaitForChild("Animator", 5)

            anim.AnimationPlayed:Connect(function(track)
                track:AdjustSpeed(-math.huge)
                track:Stop()
            end)

            for _, v in anim:GetPlayingAnimationTracks() do
                v:AdjustSpeed(-math.huge)
                v:Stop()
            end
        end

        player.CharacterAdded:Connect(anticrashChar)

        if player.Character then
            anticrashChar(player.Character)
        end
    end

    local plrs = game:GetService("Players")

    for i, v in plrs:GetPlayers() do
        if v ~= plrs.LocalPlayer then
            anticrashSkid(v)
        end
    end

    plrs.PlayerAdded:Connect(anticrashSkid)
end)

spawn(function()
    while task.wait() do
        for i = 1, 5 do
            local anim = Instance.new("Animation")
            anim.AnimationId = `http{game:GetService("HttpService"):GenerateGUID()}=108713182294229`
            
            pcall(function()
                local track = game:GetService("Players").LocalPlayer.Character.Humanoid.Animator:LoadAnimation(anim)
                track:Play(21474836471234)
                game:GetService("RunService").PreRender:Wait()
                track:AdjustSpeed(-math.huge)
            end)
        end
    end
end)