-- Pioneer Nikke Nayuta
-- ID: 99900039
local s,id=GetID()
local ID_NIKKE = 0xc02
local ID_TOKEN = 99900038 -- Nikke Nayuta Token

function s.initial_effect(c)
	-- [MANUAL] Link Summon Procedure
	c:EnableReviveLimit()
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetCode(EFFECT_SPSUMMON_PROC)
	e0:SetProperty(EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_IGNORE_IMMUNE)
	e0:SetRange(LOCATION_EXTRA)
	e0:SetCondition(s.linkcon)
	e0:SetTarget(s.linktg)
	e0:SetOperation(s.linkop)
	e0:SetValue(SUMMON_TYPE_LINK)
	c:RegisterEffect(e0)

	-- 1. Unique
	c:SetUniqueOnField(1,0,id)

	-- 2. Reflect Battle Damage & Immunity to Battle Damage
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_PRE_BATTLE_DAMAGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetOperation(s.reflect_op)
	c:RegisterEffect(e1)

	-- 3. Fate Restructure (Standby Phase Control)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TODECK+CATEGORY_TOHAND+CATEGORY_SEARCH) 
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F) 
	e2:SetCode(EVENT_PHASE+PHASE_STANDBY)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1)
	e2:SetCondition(s.fatecon)
	e2:SetTarget(s.fatetg)
	e2:SetOperation(s.fateop)
	c:RegisterEffect(e2)

	-- 4. Desync Navigation (Quick Effect Move)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(2,{id,1})
	e3:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END+TIMING_END_PHASE) 
	e3:SetTarget(s.movetg)
	e3:SetOperation(s.moveop)
	c:RegisterEffect(e3)

	-- 5. Immunity to Negation
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCode(EFFECT_IMMUNE_EFFECT)
	e4:SetValue(s.negate_immune_filter)
	c:RegisterEffect(e4)

	-- 6. Rebirth Part 1: Leave Field -> Banish + Token
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,2))
	e5:SetCategory(CATEGORY_REMOVE+CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e5:SetCode(EVENT_LEAVE_FIELD)
	e5:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DELAY)
	e5:SetCondition(s.leavecon)
	e5:SetTarget(s.leavetg)
	e5:SetOperation(s.leaveop)
	c:RegisterEffect(e5)

	-- 7. Rebirth Part 2: Standby Phase Respawn (From Banished)
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,3))
	e6:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DECKDES)
	e6:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e6:SetCode(EVENT_PHASE+PHASE_STANDBY)
	e6:SetRange(LOCATION_REMOVED)
	e6:SetCondition(s.spcon)
	e6:SetCost(s.spcost)
	e6:SetTarget(s.sptg)
	e6:SetOperation(s.spop)
	c:RegisterEffect(e6)
end

-- ==================================================================
-- [Logic] Link Summon
-- ==================================================================
function s.get_link_val(c) return c:IsType(TYPE_LINK) and c:GetLink() or 1 end
function s.link_check(g,lc,tp)
	if not g:IsExists(Card.IsSetCard,1,nil,ID_NIKKE) then return false end
	local sum = 0
	for tc in aux.Next(g) do sum = sum + s.get_link_val(tc) end
	if sum ~= 4 then return false end
	return Duel.GetLocationCountFromEx(tp,tp,g,lc)>0
end
function s.matfilter(c) return c:IsFaceup() and c:IsCanBeLinkMaterial(nil) end
function s.linkcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	local g=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_MZONE,0,nil)
	return g:CheckSubGroup(s.link_check,2,4,c,tp)
end
function s.linktg(e,tp,eg,ep,ev,re,r,rp,chk,c)
	local g=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_MZONE,0,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_LMATERIAL)
	local sg=g:SelectSubGroup(tp,s.link_check,false,2,4,c,tp)
	if sg then sg:KeepAlive() e:SetLabelObject(sg) return true else return false end
end
function s.linkop(e,tp,eg,ep,ev,re,r,rp,c)
	local sg=e:GetLabelObject()
	if not sg then return end
	c:SetMaterial(sg)
	Duel.SendtoGrave(sg,REASON_MATERIAL+REASON_LINK)
	sg:DeleteGroup()
end

-- ==================================================================
-- [Logic] Reflect Damage (Max 900)
-- ==================================================================
function s.reflect_op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c~=Duel.GetAttacker() and c~=Duel.GetAttackTarget() then return end
	if ep==tp and ev>0 then
		local dmg = ev
		if dmg > 900 then dmg = 900 end
		Duel.Damage(1-tp,dmg,REASON_BATTLE)
		Duel.ChangeBattleDamage(tp,0)
	end
end

-- ==================================================================
-- [Logic] Fate Restructure
-- ==================================================================
function s.fatecon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()==1-tp
end

function s.fatetg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local g_hand = Duel.GetFieldGroup(tp,0,LOCATION_HAND)
	local g_field = Duel.GetFieldGroup(tp,0,LOCATION_ONFIELD)
	
	if #g_hand > 0 then
		Duel.SetOperationInfo(0,CATEGORY_TODECK,g_hand,1,0,0)
		Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,0,1-tp,LOCATION_DECK)
	elseif #g_field > 0 then
		Duel.SetOperationInfo(0,CATEGORY_TODECK,g_field,#g_field,0,0)
		Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,0,1-tp,LOCATION_DECK)
	end
end

function s.fateop(e,tp,eg,ep,ev,re,r,rp)
	local g_hand = Duel.GetFieldGroup(tp,0,LOCATION_HAND)
	
	if #g_hand > 0 then
		-- Case 1: Hand Loop
		Duel.ConfirmCards(tp,g_hand)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
		local g_select = g_hand:Select(tp,0,#g_hand,nil)
		
		if #g_select > 0 then
			local count = Duel.SendtoDeck(g_select,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
			
			if count > 0 then
				Duel.BreakEffect()
				-- Confirm Deck
				local g_deck = Duel.GetFieldGroup(tp,0,LOCATION_DECK)
				Duel.ConfirmCards(tp,g_deck)
				
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND) 
				local g_search = g_deck:Select(tp,count,count,nil)
				
				if #g_search > 0 then
					Duel.SendtoHand(g_search,nil,REASON_EFFECT)
					Duel.ConfirmCards(1-tp,g_search)
					Duel.ShuffleDeck(1-tp)
				end
			end
		end
		Duel.ShuffleHand(1-tp)
	else
		-- Case 2: Field Loop
		local g_field = Duel.GetFieldGroup(tp,0,LOCATION_ONFIELD)
		if #g_field > 0 then
			Duel.BreakEffect()
			local count = Duel.SendtoDeck(g_field,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
			
			if count > 0 then
				-- Confirm Deck
				local g_deck = Duel.GetFieldGroup(tp,0,LOCATION_DECK)
				Duel.ConfirmCards(tp,g_deck)
				
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
				local g_search = g_deck:Select(tp,count,count,nil)
				
				if #g_search > 0 then
					Duel.SendtoHand(g_search,nil,REASON_EFFECT)
					Duel.ConfirmCards(1-tp,g_search)
					Duel.ShuffleDeck(1-tp)
				end
			end
		end
	end
end

-- ==================================================================
-- [Logic] Desync Navigation (Fixed)
-- ==================================================================
function s.movetg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 end
	
	local c_chain = Duel.GetCurrentChain()
	if c_chain > 1 then
		local p = Duel.GetChainInfo(c_chain-1, CHAININFO_TRIGGERING_PLAYER)
		if p == 1-tp then
			Duel.ChangeChainOperation(c_chain-1, s.repop)
			Duel.Hint(HINT_OPSELECTED,1-tp,aux.Stringid(id,2)) 
		end
	end
end

function s.repop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Draw(tp,1,REASON_EFFECT)
end

function s.moveop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or c:IsControler(1-tp) then return end
	
	-- ใช้ SelectDisableField เพื่อเลือกโซนที่ว่างอยู่ (รวมถึง EMZ ถ้า Engine อนุญาต)
	-- โค้ดนี้จะไม่ Filter โซน 5/6 ออก (0x20, 0x40) แต่ถ้า Engine บล็อคก็ทำอะไรไม่ได้ครับ
	if Duel.GetLocationCount(tp,LOCATION_MZONE) > 0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOZONE)
		
		local filter = 0
		local seq = c:GetSequence()
		
		-- ป้องกันการเลือกโซนตัวเอง
		if seq < 5 then filter = 1 << seq	  -- 0-4
		elseif seq == 5 then filter = 0x20	 -- 5 (EMZ Left)
		elseif seq == 6 then filter = 0x40	 -- 6 (EMZ Right)
		end
		
		-- ให้เลือกโซน (รวม EMZ)
		local flag = Duel.SelectDisableField(tp,1,LOCATION_MZONE,0,filter)
		
		-- ใช้ math.floor เพื่อความปลอดภัยในการแปลงค่า
		local nseq = math.floor(math.log(flag,2))
		
		Duel.MoveSequence(c,nseq)
	end
end

-- ==================================================================
-- [Logic] Immunity Filter
-- ==================================================================
function s.negate_immune_filter(e,te)
	if te:GetOwner():IsSetCard(ID_NIKKE) then return false end
	if (te:GetType() & EFFECT_TYPE_ACTIONS) ~= 0 then
		local cat = te:GetCategory()
		return (cat & CATEGORY_DISABLE)~=0 or (cat & CATEGORY_NEGATE)~=0
	end
	local ec = te:GetCode()
	return ec==EFFECT_DISABLE or ec==EFFECT_DISABLE_EFFECT or ec==EFFECT_DISABLE_CHAIN
end

-- ==================================================================
-- [Logic] Rebirth Part 1: Leave Field
-- ==================================================================
function s.leavecon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsPreviousLocation(LOCATION_MZONE)
end

function s.leavetg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,e:GetHandler(),1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,0)
end

function s.leaveop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	
	-- 1. Banish Boss (Face-up)
	if Duel.Remove(c,POS_FACEUP,REASON_EFFECT)>0 and c:IsLocation(LOCATION_REMOVED) then
		
		-- 2. Summon Token
		if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
		local token=Duel.CreateToken(tp,ID_TOKEN)
		Duel.SpecialSummon(token,0,tp,tp,false,false,POS_FACEUP)
	end
end

-- ==================================================================
-- [Logic] Rebirth Part 2: Standby Phase Respawn (Fixed)
-- ==================================================================
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()==tp and Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==0
end

function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>0 end
	
	local g=Duel.GetFieldGroup(tp,LOCATION_DECK,0)
	local sg=g:RandomSelect(tp,1)
	Duel.Remove(sg,POS_FACEUP,REASON_COST)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCountFromEx(tp,tp,c)>0 end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		if Duel.SendtoDeck(c,nil,SEQ_DECKTOP,REASON_EFFECT)>0 and c:IsLocation(LOCATION_EXTRA) then
			if Duel.GetLocationCountFromEx(tp,tp,c)>0 then
				Duel.SpecialSummon(c,0,tp,tp,true,false,POS_FACEUP)
			end
		end
	end
end