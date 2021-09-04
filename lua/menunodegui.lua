Hooks:PostHook(MenuNodeGui,"_setup_item_rows","tacticallean_checkforholdthekeydependency",function(self,...)
    if not (_G.HoldTheKey or self._HAS_SHOWN_HOLDTHEKEY_MISSING_PROMPT) then
        QuickMenu:new(
           managers.localization:text("menu_taclean_missing_htk_prompt_title"),
           managers.localization:text("menu_taclean_missing_htk_prompt_desc"),
		   {
                {
                    text = managers.localization:text("menu_ok"),
                    is_cancel_button = true
                }
            },
            true
        )
		self._HAS_SHOWN_HOLDTHEKEY_MISSING_PROMPT = true
	end
end)