local View = {}
local ItemHelper = require "utils.ItemHelper"


function View:Start(data)
	-- ERROR_LOG(sprinttb(data));
	local gid = data.gid;
	local desc = data.desc;
	local Consume = data.Consume;

	local Reward = data.Reward;
	local name = data.name;

	local callback = data.callback;

	self.view = SGK.UIReference.Setup(self.gameObject);
	self.view.bg.title[UI.Text].text = name or "没有收到回复";

	self.view.bg.Desc.desc[UI.Text].text = desc;

	if Consume and #Consume > 0 then
		for i=1,4 do
			local item = self.view.bg.Consume.icons["ItemIcon"..(tostring(i))];
			if Consume[i] then
				local cfg = ItemHelper.Get(Consume[i].type,Consume[i].id);
				item[SGK.ItemIcon]:SetInfo(cfg,true,Consume[i].count)
				
				item["ItemIcon"..(tostring(i))][SGK.ItemIcon].showDetail= true
				item["ItemIcon"..(tostring(i))].ItemDesc.gameObject:SetActive(false)
			else
				item.Frame.gameObject:SetActive(false);
			end
		end
	else
		self.view.bg.Consume.gameObject:SetActive(false);
		self.view.bg[UnityEngine.RectTransform].sizeDelta = CS.UnityEngine.Vector2(681,600);
		self.view.bg.center.gameObject:SetActive(false);
	end
	if Reward and #Reward >0 then
		for i=1,4 do
			local item = self.view.bg.Reward.icons["ItemIcon"..(tostring(i))];
			if Reward[i] then
				local cfg = ItemHelper.Get(Reward[i].type,Reward[i].id);
				item[SGK.ItemIcon]:SetInfo(cfg,true,Reward[i].count)
				item[SGK.ItemIcon].showDetail= true
				item.ItemDesc.gameObject:SetActive(false)
			else
				item.Frame.gameObject:SetActive(false);
			end
		end
	else
		self.view.bg.Reward.gameObject:SetActive(false);

		if not Consume or #Consume <=0 then
			self.view.bg[UnityEngine.RectTransform].sizeDelta = CS.UnityEngine.Vector2(681,400);
			self.view.bg.center.gameObject:SetActive(false);
		else
			self.view.bg[UnityEngine.RectTransform].sizeDelta = CS.UnityEngine.Vector2(681,600);
		end
	end




	CS.UGUIClickEventListener.Get(self.view.bg.btnOK.gameObject,true).onClick = function (obj)
		if callback then
			callback();
		end
		DialogStack.Pop();
	end

	CS.UGUIClickEventListener.Get(self.view.bg.btnClose.gameObject,true).onClick = function (obj)
		DialogStack.Pop();
	end

	
	

end





return View;