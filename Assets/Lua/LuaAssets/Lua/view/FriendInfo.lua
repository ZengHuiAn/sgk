local playerModule = require "module.playerModule"
local PlayerInfoHelper = require "utils.PlayerInfoHelper"
local IconFrameHelper = require "utils.IconFrameHelper"
local npcConfig = require "config.npcConfig"
local View = {};
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self.view.mask[CS.UGUIClickEventListener].onClick = function ( ... )
		UnityEngine.GameObject.Destroy(self.gameObject)
	end
	self.view.desc[UI.Text].text = data.desc
	local PLayerIcon = IconFrameHelper.Hero({},self.view.Group[1])
	PlayerInfoHelper.GetPlayerAddData(data.pid,99,function (addData)
        --获取头像挂件足迹等
        local _PlayerData = data.PlayerData or addData
        self.view.Group[1].name[UI.Text].text = "头像框"--utils.ItemHelper.Get(41,_PlayerData.HeadFrame).name
        if data.isNpc then
            local cfg = npcConfig.GetnpcList()[data.pid]
            IconFrameHelper.UpdateHero({icon = cfg.icon,sex = _PlayerData.Sex,headFrame = _PlayerData.HeadFrame},PLayerIcon)
        else
            IconFrameHelper.UpdateHero({pid = data.pid,sex = _PlayerData.Sex,headFrame = _PlayerData.HeadFrame},PLayerIcon)
        end
		self.view.Group[1][CS.UGUIClickEventListener].onClick = function ( ... )
			DialogStack.Push("mapSceneUI/ChangeIconFrame",{2,(_PlayerData.HeadFrameId or addData.HeadFrameId)})
		end
        if _PlayerData.Bubble == 0 then
            self.view.Group[2].name[UI.Text].text = ""
            self.view.Group[2][UI.Image].enabled = false
        else
            self.view.Group[2].name[UI.Text].text = utils.ItemHelper.Get(41,_PlayerData.Bubble).name
            --DialogStack.Push("mapSceneUI/ChangeIconFrame",)
            self.view.Group[2][CS.UGUIClickEventListener].onClick = function ( ... )
            	DialogStack.Push("mapSceneUI/newPlayerInfoFrame",{2,76,_PlayerData.Bubble})
            end
            IconFrameHelper.Item({id = _PlayerData.Bubble},self.view.Group[2])
        end
       -- self.view.Group[2][UI.Image]:LoadSprite("icon/".._PlayerData.Bubble)
        if (_PlayerData.FootPrint or addData.FootPrint) == 0 then
            self.view.Group[3].name[UI.Text].text = ""
            self.view.Group[3][UI.Image].enabled = false
        else
            self.view.Group[3].name[UI.Text].text = utils.ItemHelper.Get(41,(_PlayerData.FootPrint or addData.FootPrint)).name
            self.view.Group[3][CS.UGUIClickEventListener].onClick = function ( ... )
            	DialogStack.Push("mapSceneUI/newPlayerInfoFrame",{2,99,(_PlayerData.FootPrint or addData.FootPrint)})
            end
            IconFrameHelper.Item({id = (_PlayerData.FootPrint or addData.FootPrint)},self.view.Group[3])
        end
        --self.view.Group[3][UI.Image]:LoadSprite("icon/"..(_PlayerData.FootPrint or addData.FootPrint))
        --self.view.Group[4].name[UI.Text].text = "???"
        --IconFrameHelper.Item({},self.view.Group[4])
       	self.view.Group[4]:SetActive(false)
    end)
end
return View