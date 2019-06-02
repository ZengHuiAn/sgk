local View = {}



function View:Start(data)
	self.view = SGK.UIReference.Setup(self.gameObject);
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject).onClick = function ( object )
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.bg.close.gameObject).onClick = function ( object )
        DialogStack.Pop()
    end
end


function View:OnDestory()

end

function View:listEvent()
    return {
    }
end

function View:onEvent(event,data)

end


return View;