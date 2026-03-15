-- Goddess Nikke Rapunzel
-- ID: 99900034
local s,id=GetID()
local ID_NIKKE = 0xc02

function s.initial_effect(c)
	c:EnableReviveLimit()

	-- Link Summon
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

	-- 1. Aura Heal (Trigger on Summon)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_RECOVER)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCondition(s.healcon)
	e1:SetOperation(s.healop)
	c:RegisterEffect(e1)
	
	local e1b=e1:Clone()
	e1b:SetCode(EVENT_SUMMON_SUCCESS)
	c:RegisterEffect(e1b)

	-- 2. Blessing Buff (Quick Effect)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DEFCHANGE+CATEGORY_TODECK)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCountLimit(1,id)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
	e2:SetCost(s.buffcost)
	e2:SetTarget(s.bufftg)
	e2:SetOperation(s.buffop)
	c:RegisterEffect(e2)

	-- 3. Resurrection (Ignition Effect - Main Phase Only)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_IGNITION) 
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id+100)
	e3:SetCost(s.spcost)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
end

-- ==================================================================
-- Link Logic
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
-- 1. Aura Heal
-- ==================================================================
function s.healfilter(c,ec)
	return (c:IsRace(RACE_MACHINE) or c:IsSetCard(ID_NIKKE)) 
		and ec:GetLinkedGroup():IsContains(c)
end
function s.healcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.healfilter,1,nil,e:GetHandler())
end
function s.healop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=eg:Filter(s.healfilter,nil,c)
	local heal_amount=0
	for tc in aux.Next(g) do
		local val = (tc:GetAttack() + tc:GetDefense()) / 2
		if val > 0 then heal_amount = heal_amount + val end
	end
	if heal_amount > 0 then
		Duel.Hint(HINT_CARD,0,id)
		Duel.Recover(tp, math.floor(heal_amount), REASON_EFFECT)
	end
end

-- ==================================================================
-- 2. Blessing Buff
-- ==================================================================
function s.buffcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsAbleToDeck,tp,0,LOCATION_GRAVE,2,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectMatchingCard(tp,Card.IsAbleToDeck,tp,0,LOCATION_GRAVE,2,2,nil)
	Duel.SendtoDeck(g,nil,SEQ_DECKBOTTOM,REASON_COST)
end
function s.bufffilter(c)
	return c:IsFaceup() and c:IsSetCard(ID_NIKKE)
end
function s.bufftg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local c=e:GetHandler()
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.bufffilter(chkc) and chkc~=c end
	if chk==0 then return Duel.IsExistingTarget(s.bufffilter,tp,LOCATION_MZONE,0,1,c) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	Duel.SelectTarget(tp,s.bufffilter,tp,LOCATION_MZONE,0,1,1,c)
end
function s.buffop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	
	local g_opp=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil)
	local max_atk=0
	if #g_opp>0 then
		local max_c=g_opp:GetMaxGroup(Card.GetAttack):GetFirst()
		if max_c then max_atk=max_c:GetAttack() end
	end
	
	local function apply_buff(target_card)
		if target_card:IsFaceup() and target_card:IsRelateToEffect(e) then
			if max_atk > 0 then
				local e1=Effect.CreateEffect(c)
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetCode(EFFECT_UPDATE_ATTACK)
				e1:SetValue(max_atk)
				e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
				target_card:RegisterEffect(e1)
				
				local e2=e1:Clone()
				e2:SetCode(EFFECT_UPDATE_DEFENSE)
				target_card:RegisterEffect(e2)
			end
			
			local e3=Effect.CreateEffect(c)
			e3:SetDescription(3110) 
			e3:SetType(EFFECT_TYPE_SINGLE)
			e3:SetCode(EFFECT_IMMUNE_EFFECT)
			e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CLIENT_HINT)
			e3:SetRange(LOCATION_MZONE)
			e3:SetValue(s.unaffectedval)
			e3:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			target_card:RegisterEffect(e3)
		end
	end
	
	if c:IsRelateToEffect(e) then apply_buff(c) end
	if tc then apply_buff(tc) end
end
function s.unaffectedval(e,te)
	return te:GetOwnerPlayer()~=e:GetHandlerPlayer()
end

-- ==================================================================
-- 3. Resurrection (Modified Cost: No Face-down)
-- ==================================================================
-- [UPDATE] Filter: เอาเฉพาะ (อยู่ในสุสาน) หรือ (อยู่ในรีมูฟ และ หงายหน้า)
function s.costfilter(c)
	return c:IsAbleToDeck() and (c:IsLocation(LOCATION_GRAVE) or (c:IsLocation(LOCATION_REMOVED) and c:IsFaceup()))
end

function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,3,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	-- ใช้ costfilter แทน IsAbleToDeck
	local g=Duel.SelectMatchingCard(tp,s.costfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,3,3,nil)
	Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_COST)
end

function s.spfilter(c,e,tp)
	return c:IsSetCard(ID_NIKKE) and c:IsType(TYPE_MONSTER) and c:IsCanBeSpecialSummoned(e,0,tp,true,false)
end
function s.attachfilter(c)
	return c:IsSetCard(ID_NIKKE) and c:IsType(TYPE_MONSTER)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK+LOCATION_EXTRA,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK+LOCATION_EXTRA)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK+LOCATION_EXTRA,0,1,1,nil,e,tp)
	local tc=g:GetFirst()
	
	if tc and Duel.SpecialSummon(tc,0,tp,tp,true,false,POS_FACEUP)>0 then
		if tc:IsType(TYPE_XYZ) then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
			local matg=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.attachfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
			if #matg>0 then
				Duel.Overlay(tc,matg)
			end
		end
	end
	
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetCode(EFFECT_SKIP_DP)
	e1:SetTargetRange(1,0)
	e1:SetReset(RESET_PHASE+PHASE_DRAW+RESET_SELF_TURN)
	Duel.RegisterEffect(e1,tp)

	local e2=Effect.CreateEffect(e:GetHandler())
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e2:SetCode(EFFECT_CANNOT_DRAW)
	e2:SetDescription(aux.Stringid(id,3)) 
	e2:SetTargetRange(1,0)
	e2:SetReset(RESET_PHASE+PHASE_END+RESET_SELF_TURN, 2)
	Duel.RegisterEffect(e2,tp)

	local e3=e2:Clone()
	e3:SetCode(EFFECT_CANNOT_TO_HAND)
	e3:SetTarget(s.no_add_target)
	Duel.RegisterEffect(e3,tp)
end

function s.no_add_target(e,c)
	return c:IsLocation(LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED)
end