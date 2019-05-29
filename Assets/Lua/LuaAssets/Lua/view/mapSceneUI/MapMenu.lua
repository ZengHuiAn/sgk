

local View = {}


function View:Start(args)
    self.args = args or self.args or {}

    self.view = SGK.UIReference.Setup(self.gameObject);
    for _, v in ipairs(self.args.menus) do
        local btn = SGK.UIReference.Setup(UnityEngine.GameObject.Instantiate(self.view.Button.gameObject, self.view.transform))
        btn:SetActive(true);
        btn.Text[UnityEngine.UI.Text].text = v.name;
        CS.UGUIClickEventListener.Get(btn.gameObject).onClick = function ()
            DialogStack.Pop();
            v.action();
        end
    end
end

function View:Close()
    DialogStack.Pop();
end

return View;