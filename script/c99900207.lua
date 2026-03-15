-- T-Class Rapture Grave Digger
-- ID: 99900207
local s,id=GetID()
local ID_RAPTURE = 0xc22
local ID_HERETIC = 0xc20

function s.initial_effect(c)
	-- กฎการอัญเชิญพิเศษ (Xyz Summon ไม่ได้)
	c:EnableReviveLimit()
	
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(s.splimit)
	c:RegisterEffect(e0)

	-- 1. Ignition: Destroy 1 Machine & 1 Rapture -> Special Summon from Extra/GY
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_EXTRA+LOCATION_GRAVE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- 2. Quick Effect (Extra Deck): Opponent 4+ Monster Effects (Field/GY) -> Dump & Recover
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOGRAVE+CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
	e2:SetRange(LOCATION_EXTRA)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.trcon)
	e2:SetTarget(s.trtg)
	e2:SetOperation(s.trop)
	c:RegisterEffect(e2)

	-- 3. Continuous: ATK Boost (Overlay Count * 200)
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_UPDATE_ATTACK)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetValue(s.atkval)
	c:RegisterEffect(e3)

	-- 4. Trigger: Attach Destroyed Cards as Material
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_DESTROYED)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCondition(s.attcon)
	e4:SetTarget(s.atttg)
	e4:SetOperation(s.attop)
	c:RegisterEffect(e4)

	-- 5. Ignition: Detach 1 -> Add 1 from GY
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,3))
	e5:SetCategory(CATEGORY_TOHAND)
	e5:SetType(EFFECT_TYPE_IGNITION)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCost(s.thcost)
	e5:SetTarget(s.thtg)
	e5:SetOperation(s.thop)
	c:RegisterEffect(e5)

	-- ==================================================================
	-- Global System: นับจำนวนการใช้เอฟเฟคมอนสเตอร์ของอีกฝ่าย (บนสนาม และ สุสาน)
	-- ==================================================================
	if not s.global_check then
		s.global_check = true
		local ge1 = Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_CHAINING)
		ge1:SetOperation(s.checkop_ch)
		Duel.RegisterEffect(ge1, 0)
	end
end

-- ==================================================================
-- Logic 1: Summon & Attach
-- ==================================================================
function s.splimit(e,se,sp,st)
	return not (st&SUMMON_TYPE_XYZ==SUMMON_TYPE_XYZ)
end

function s.pair_check(sg,e,tp)
	local cards = {}
	for tc in aux.Next(sg) do table.insert(cards, tc) end
	if #cards == 2 then
		local valid_pair = (cards[1]:IsRace(RACE_MACHINE) and cards[2]:IsSetCard(ID_RAPTURE))
						or (cards[2]:IsRace(RACE_MACHINE) and cards[1]:IsSetCard(ID_RAPTURE))
		local c=e:GetHandler()
		if c:IsLocation(LOCATION_EXTRA) then
			return valid_pair and Duel.GetLocationCountFromEx(tp,tp,sg,c)>0
		else
			return valid_pair and Duel.GetMZoneCount(tp,sg)>0
		end
	end
	return false
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return false end
	local c=e:GetHandler()
	local rg=Duel.GetMatchingGroup(Card.IsCanBeEffectTarget,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	if chk==0 then 
		return c:IsCanBeSpecialSummoned(e,0,tp,true,true) and rg:CheckSubGroup(s.pair_check,2,2,e,tp) 
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local sg=rg:SelectSubGroup(tp,s.pair_check,false,2,2,e,tp)
	Duel.SetTargetCard(sg)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,sg,2,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g_all=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS)
	if not g_all or not c:IsRelateToEffect(e) then return end
	local g=g_all:Filter(Card.IsRelateToEffect,nil,e)
	if #g==2 and Duel.Destroy(g,REASON_EFFECT)==2 then
		if Duel.SpecialSummon(c,0,tp,tp,true,true,POS_FACEUP)>0 then
			local og=g:Filter(Card.IsLocation,nil,LOCATION_GRAVE+LOCATION_REMOVED)
			if #og>0 then Duel.Overlay(c,og) end
		end
	end
end

-- ==================================================================
-- Logic 2: Global Counter (Monster Effect Field/GY) & Extra Deck Trigger
-- ==================================================================
function s.checkop_ch(e,tp,eg,ep,ev,re,r,rp)
	local loc = Duel.GetChainInfo(ev, CHAININFO_TRIGGERING_LOCATION)
	
	if re:IsActiveType(TYPE_MONSTER) and (loc==LOCATION_MZONE or loc==LOCATION_GRAVE) then
		Duel.RegisterFlagEffect(rp,id,RESET_PHASE+PHASE_END,0,1)
	end
end

function s.trcon(e,tp,eg,ep,ev,re,r,rp)
	local ph = Duel.GetCurrentPhase()
	if ph ~= PHASE_MAIN1 and ph ~= PHASE_MAIN2 then return false end
	-- [แก้ไข] เช็คว่าอีกฝ่ายใช้งานเอฟเฟคครบ 4 ครั้งขึ้นไป
	return Duel.GetFlagEffect(1-tp,id) >= 4
end

function s.dump_filter(c)
	return (c:IsSetCard(ID_RAPTURE) or c:IsSetCard(ID_HERETIC)) and c:IsAbleToGrave()
end

function s.trtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.IsExistingMatchingCard(s.dump_filter,tp,LOCATION_DECK,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE)
end

function s.trop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g1=Duel.SelectMatchingCard(tp,s.dump_filter,tp,LOCATION_DECK,0,1,1,nil)
	if #g1>0 and Duel.SendtoGrave(g1,REASON_EFFECT)>0 then
		local g2=Duel.GetMatchingGroup(Card.IsAbleToHand,tp,LOCATION_GRAVE,0,nil)
		if #g2>0 and Duel.SelectYesNo(tp,aux.Stringid(id,4)) then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
			local sg=g2:Select(tp,1,1,nil)
			Duel.SendtoHand(sg,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,sg)
		end
	end
end

-- ==================================================================
-- Logic 3, 4 & 5: ATK, Attach, Recovery
-- ==================================================================
function s.atkval(e,c)
	return c:GetOverlayCount()*200
end

function s.attfilter(c,e,tp)
	return c:IsPreviousLocation(LOCATION_ONFIELD) and c:IsLocation(LOCATION_GRAVE+LOCATION_REMOVED) and not c:IsType(TYPE_TOKEN)
end

function s.attcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.attfilter,1,nil,e,tp)
end

function s.atttg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsType(TYPE_XYZ) end
	Duel.SetTargetCard(eg)
end

function s.attop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or c:IsFacedown() then return end
	local g=eg:Filter(s.attfilter,nil,e,tp):Filter(Card.IsRelateToEffect,nil,e)
	if #g>0 then
		Duel.Overlay(c,g)
	end
end

function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsAbleToHand,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,Card.IsAbleToHand,tp,LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end