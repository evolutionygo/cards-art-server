-- Heretic Factory Machine
-- ID: 99900046
local s,id=GetID()
local ID_NIKKE = 0xc02
local ID_HERETIC = 0xc20
local COUNTER_MaterialH = 0x1011

function s.initial_effect(c)
	c:EnableCounterPermit(COUNTER_MaterialH)

	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_REMOVE)
	e2:SetRange(LOCATION_FZONE)
	e2:SetOperation(s.ctop_rem)
	c:RegisterEffect(e2)
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_SUMMON_SUCCESS)
	e3:SetRange(LOCATION_FZONE)
	e3:SetOperation(s.ctop_sum)
	c:RegisterEffect(e3)
	local e4=e3:Clone()
	e4:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e4)

	-- Auto Protection (Pay 4: Hand/Deck)
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,0))
	e5:SetCategory(CATEGORY_REMOVE)
	e5:SetType(EFFECT_TYPE_QUICK_F)
	e5:SetCode(EVENT_CHAINING)
	e5:SetRange(LOCATION_FZONE)
	e5:SetCountLimit(1,EFFECT_COUNT_CODE_CHAIN)
	e5:SetCondition(s.autochain_con)
	e5:SetTarget(s.autochain_tg)
	e5:SetOperation(s.autochain_op)
	c:RegisterEffect(e5)

	-- Ignition Effects (Shared Limit, Nerfed to 3/5/7)
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,1))
	e6:SetType(EFFECT_TYPE_IGNITION)
	e6:SetRange(LOCATION_FZONE)
	e6:SetCountLimit(2,id)
	e6:SetCost(s.eff_cost)
	e6:SetTarget(s.eff_tg)
	e6:SetOperation(s.eff_op)
	c:RegisterEffect(e6)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	local ct=Duel.GetMatchingGroupCount(Card.IsFacedown,tp,LOCATION_REMOVED,LOCATION_REMOVED,nil)
	if ct>0 then e:GetHandler():AddCounter(COUNTER_MaterialH,ct) end
end

function s.remfilter(c) return c:IsFacedown() end
function s.ctop_rem(e,tp,eg,ep,ev,re,r,rp)
	local ct=eg:FilterCount(s.remfilter,nil)
	if ct>0 then e:GetHandler():AddCounter(COUNTER_MaterialH,ct) end
end

function s.sumfilter(c,tp) return c:IsRace(RACE_MACHINE) and c:IsLevelAbove(5) and c:IsControler(tp) end
function s.ctop_sum(e,tp,eg,ep,ev,re,r,rp)
	local ct=eg:FilterCount(s.sumfilter,nil,tp)
	if ct>0 then e:GetHandler():AddCounter(COUNTER_MaterialH,ct) end
end

-- Automatic Protection Logic (Cost 4)
function s.autochain_con(e,tp,eg,ep,ev,re,r,rp)
	if rp==tp or not e:GetHandler():IsCanRemoveCounter(tp,COUNTER_MaterialH,4,REASON_COST) then return false end
	if ev<2 then return false end
	local pe=Duel.GetChainInfo(ev-1,CHAININFO_TRIGGERING_EFFECT)
	if not pe or not pe:GetHandler():IsSetCard(ID_HERETIC) then return false end
	if re:GetHandler():IsSetCard(ID_HERETIC) then return false end
	return Duel.IsExistingMatchingCard(nil,tp,0,LOCATION_REMOVED,1,nil)
end

function s.autochain_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
end

function s.autochain_op(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsCanRemoveCounter(tp,COUNTER_MaterialH,4,REASON_COST) then return end
	e:GetHandler():RemoveCounter(tp,COUNTER_MaterialH,4,REASON_COST)

	local g1=Duel.GetFieldGroup(tp,0,LOCATION_HAND)
	local g2=Duel.GetFieldGroup(tp,0,LOCATION_DECK)
	g1:Merge(g2)
	
	if #g1>0 then
		local sg=g1:RandomSelect(tp,1)
		if Duel.Remove(sg,POS_FACEDOWN,REASON_EFFECT)>0 then
			local g_rem=Duel.GetFieldGroup(tp,0,LOCATION_REMOVED)
			if #g_rem>0 then
				Duel.ChangeChainOperation(ev,s.repop)
			end
		end
	end
end

function s.repop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetFieldGroup(tp,LOCATION_REMOVED,0)
	if #g>0 then
		local sg=g:RandomSelect(tp,1)
		Duel.SendtoDeck(sg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
	end
end

-- Ignition Effects Logic
function s.eff2_dump_filter(c) return c:IsRace(RACE_MACHINE) and c:IsAbleToGrave() end
function s.eff2_add_filter(c) return c:IsSetCard(ID_HERETIC) and c:IsAbleToHand() end
function s.check_mode2(tp)
	return Duel.IsExistingMatchingCard(s.eff2_dump_filter,tp,LOCATION_DECK,0,1,nil)
	   and Duel.IsExistingMatchingCard(s.eff2_add_filter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil)
end

function s.eff4_filter(c,e,tp)
	return c:IsSetCard(ID_HERETIC) and c:IsAbleToHand() and c:GetLevel()>0
		and Duel.IsExistingMatchingCard(s.eff4_ss_filter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil,c:GetLevel(),e,tp)
end
function s.eff4_ss_filter(c,lv,e,tp)
	return c:IsSetCard(ID_HERETIC) and c:IsLevel(lv) and c:IsCanBeSpecialSummoned(e,0,tp,true,false)
end
function s.check_mode4(e,tp)
	return Duel.IsExistingMatchingCard(s.eff4_filter,tp,LOCATION_MZONE,0,1,nil,e,tp)
end

function s.check_mode6(tp)
	local opp_count = Duel.GetMatchingGroupCount(Card.IsAbleToRemoveAsCost,tp,0,LOCATION_ONFIELD+LOCATION_EXTRA,nil,POS_FACEDOWN)
	return Duel.IsExistingMatchingCard(nil,tp,LOCATION_REMOVED,0,2,nil) and opp_count >= 1
end

function s.eff_cost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	-- [แก้ไข] เช็คเคาน์เตอร์ >= 3, 5, 7
	if chk==0 then 
		local ct=c:GetCounter(COUNTER_MaterialH)
		local b1 = ct>=3 and s.check_mode2(tp)
		local b2 = ct>=5 and s.check_mode4(e,tp)
		local b3 = ct>=7 and s.check_mode6(tp)
		return b1 or b2 or b3
	end
	
	local ct=c:GetCounter(COUNTER_MaterialH)
	local b1 = ct>=3 and s.check_mode2(tp)
	local b2 = ct>=5 and s.check_mode4(e,tp)
	local b3 = ct>=7 and s.check_mode6(tp)
	
	local ops={}
	local opval={}
	local off=1
	
	if b1 then ops[off]=aux.Stringid(id,2) opval[off]=1 off=off+1 end
	if b2 then ops[off]=aux.Stringid(id,3) opval[off]=2 off=off+1 end
	if b3 then ops[off]=aux.Stringid(id,4) opval[off]=3 off=off+1 end
	
	local op=Duel.SelectOption(tp,table.unpack(ops))
	local sel=opval[op+1]
	e:SetLabel(sel)
	
	-- [แก้ไข] หักเคาน์เตอร์ตามคอสต์ใหม่ 3, 5, 7
	if sel==1 then c:RemoveCounter(tp,COUNTER_MaterialH,3,REASON_COST)
	elseif sel==2 then c:RemoveCounter(tp,COUNTER_MaterialH,5,REASON_COST)
	elseif sel==3 then c:RemoveCounter(tp,COUNTER_MaterialH,7,REASON_COST)
	end
end

function s.eff_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	local sel=e:GetLabel()
	if chk==0 then return true end
	
	if sel==1 then
		e:SetCategory(CATEGORY_TOGRAVE+CATEGORY_TOHAND+CATEGORY_SEARCH)
		Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
		Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
	elseif sel==2 then
		e:SetCategory(CATEGORY_TOHAND+CATEGORY_SPECIAL_SUMMON)
		Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_MZONE)
		Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK)
	elseif sel==3 then
		e:SetCategory(CATEGORY_TOGRAVE+CATEGORY_REMOVE)
		Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,2,tp,LOCATION_REMOVED)
		Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,1-tp,LOCATION_ONFIELD+LOCATION_EXTRA)
	end
end

function s.eff_op(e,tp,eg,ep,ev,re,r,rp)
	local sel=e:GetLabel()
	
	if sel==1 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
		local g1=Duel.SelectMatchingCard(tp,s.eff2_dump_filter,tp,LOCATION_DECK,0,1,1,nil)
		if #g1>0 and Duel.SendtoGrave(g1,REASON_EFFECT)>0 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
			local g2=Duel.SelectMatchingCard(tp,s.eff2_add_filter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
			if #g2>0 then
				Duel.SendtoHand(g2,nil,REASON_EFFECT)
				Duel.ConfirmCards(1-tp,g2)
			end
		end
		
	elseif sel==2 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
		local g=Duel.SelectMatchingCard(tp,s.eff4_filter,tp,LOCATION_MZONE,0,1,1,nil,e,tp)
		if #g>0 then
			local tc=g:GetFirst()
			local lv=tc:GetLevel()
			if Duel.SendtoHand(tc,nil,REASON_EFFECT)>0 then
				Duel.ConfirmCards(1-tp,tc)
				if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
				local sg=Duel.SelectMatchingCard(tp,s.eff4_ss_filter,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil,lv,e,tp)
				if #sg>0 then
					Duel.SpecialSummon(sg,0,tp,tp,true,false,POS_FACEUP)
				end
			end
		end
		
	elseif sel==3 then
		local g_own=Duel.GetFieldGroup(tp,LOCATION_REMOVED,0)
		if #g_own>=2 then
			local sg_own=g_own:RandomSelect(tp,2)
			if Duel.SendtoGrave(sg_own,REASON_EFFECT+REASON_RETURN)>0 then
				local g_opp=Duel.GetMatchingGroup(Card.IsAbleToRemoveAsCost,tp,0,LOCATION_ONFIELD+LOCATION_EXTRA,nil,POS_FACEDOWN)
				if #g_opp>=1 then
					local sg_opp=g_opp:RandomSelect(tp,1)
					Duel.Remove(sg_opp,POS_FACEDOWN,REASON_EFFECT)
				end
			end
		end
	end
end