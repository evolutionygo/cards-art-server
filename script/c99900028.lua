-- Only One (Nikke)
-- ID: 99900028
local s,id=GetID()
local NIKKE_SET_ID = 0xc02
local ID_RAPI = 99900000 -- ID ของ Nikke Rapi

function s.initial_effect(c)
	c:EnableReviveLimit()
	
	-- 0. Cannot be Synchro Summoned (Rule)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(aux.FALSE)
	c:RegisterEffect(e0)

	-- 1. Special Summon Procedure
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_IGNORE_IMMUNE)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	
	-- 1.5 Summon cannot be negated
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_CANNOT_DISABLE_SPSUMMON)
	e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	c:RegisterEffect(e2)

	-- 2. Self Immunity
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_IMMUNE_EFFECT)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetValue(s.efilter)
	c:RegisterEffect(e3)

	-- 3. Material & Tribute Lock
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCode(EFFECT_UNRELEASABLE_SUM)
	e4:SetValue(1)
	c:RegisterEffect(e4)
	local e5=e4:Clone()
	e5:SetCode(EFFECT_UNRELEASABLE_NONSUM)
	c:RegisterEffect(e5)
	local e_fus=e4:Clone()
	e_fus:SetCode(EFFECT_CANNOT_BE_FUSION_MATERIAL)
	c:RegisterEffect(e_fus)
	local e_syn=e4:Clone()
	e_syn:SetCode(EFFECT_CANNOT_BE_SYNCHRO_MATERIAL)
	c:RegisterEffect(e_syn)
	local e_xyz=e4:Clone()
	e_xyz:SetCode(EFFECT_CANNOT_BE_XYZ_MATERIAL)
	c:RegisterEffect(e_xyz)
	local e_lnk=e4:Clone()
	e_lnk:SetCode(EFFECT_CANNOT_BE_LINK_MATERIAL)
	c:RegisterEffect(e_lnk)

	-- 4. Hand Trap from Extra Deck (> 8 Actions)
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,0))
	e6:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e6:SetType(EFFECT_TYPE_QUICK_O)
	e6:SetCode(EVENT_FREE_CHAIN)
	e6:SetRange(LOCATION_EXTRA)
	e6:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
	e6:SetCountLimit(1, id)
	e6:SetCondition(s.ct_spcon)
	e6:SetTarget(s.ct_sptg)
	e6:SetOperation(s.ct_spop)
	c:RegisterEffect(e6)

	-- 5. On Summon: Floodgate (Absolute Lock)
	local e7=Effect.CreateEffect(c)
	e7:SetDescription(aux.Stringid(id,1))
	e7:SetCategory(CATEGORY_DISABLE)
	e7:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e7:SetCode(EVENT_SPSUMMON_SUCCESS)
	e7:SetTarget(s.floodgate_tg)
	e7:SetOperation(s.floodgate_op)
	c:RegisterEffect(e7)

	-- 6. [แก้ไข] Banish Self + Player Action Banish Opponent & SS (No Limit)
	local e8=Effect.CreateEffect(c)
	e8:SetDescription(aux.Stringid(id,2))
	e8:SetCategory(CATEGORY_REMOVE+CATEGORY_SPECIAL_SUMMON)
	e8:SetType(EFFECT_TYPE_QUICK_O)
	e8:SetCode(EVENT_FREE_CHAIN)
	e8:SetRange(LOCATION_MZONE)
	e8:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	-- ลบ SetCountLimit ออก
	e8:SetTarget(s.tag_tg)
	e8:SetOperation(s.tag_op)
	c:RegisterEffect(e8)

	-- [Global Counter System]
	if not s.global_check then
		s.global_check=true
		local ge1=Effect.GlobalEffect()
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_SPSUMMON_SUCCESS)
		ge1:SetOperation(s.check_sum)
		Duel.RegisterEffect(ge1,0)
		local ge1b=Effect.GlobalEffect()
		ge1b:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1b:SetCode(EVENT_SUMMON_SUCCESS)
		ge1b:SetOperation(s.check_sum)
		Duel.RegisterEffect(ge1b,0)
		local ge2=Effect.GlobalEffect()
		ge2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge2:SetCode(EVENT_CHAINING)
		ge2:SetOperation(s.check_eff)
		Duel.RegisterEffect(ge2,0)
	end
end

-- Global Logic
function s.check_sum(e,tp,eg,ep,ev,re,r,rp)
	local tc=eg:GetFirst()
	if tc:GetSummonPlayer() then
		Duel.RegisterFlagEffect(tc:GetSummonPlayer(),id,RESET_PHASE+PHASE_END,0,1)
	end
end
function s.check_eff(e,tp,eg,ep,ev,re,r,rp)
	if re:IsActiveType(TYPE_MONSTER) then
		Duel.RegisterFlagEffect(rp,id,RESET_PHASE+PHASE_END,0,1)
	end
end

-- Summon Logic
function s.rapi_filter(c)
	return c:IsCode(ID_RAPI) and c:IsAbleToRemoveAsCost()
end
function s.spfilter(c)
	return c:IsSetCard(NIKKE_SET_ID) and c:IsType(TYPE_MONSTER) 
		and c:GetOriginalLevel()>0 
		and c:IsAbleToGraveAsCost()
end
function s.spcheck(g,tp,c)
	if g:GetClassCount(Card.GetOriginalLevel) ~= #g then return false end
	return Duel.GetLocationCountFromEx(tp,tp,g,c)>0
end
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	if not Duel.IsExistingMatchingCard(s.rapi_filter,tp,LOCATION_GRAVE,0,1,nil) then return false end
	local g=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,nil)
	return g:CheckSubGroup(s.spcheck,2,2,tp,c)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,c)
	local g=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local rg=Duel.SelectMatchingCard(tp,s.rapi_filter,tp,LOCATION_GRAVE,0,1,1,nil)
	if #rg>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
		local sg=g:SelectSubGroup(tp,s.spcheck,false,2,2,tp,c)
		if sg then
			sg:Merge(rg) sg:KeepAlive() e:SetLabelObject(sg)
			return true
		end
	end
	return false
end
function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=e:GetLabelObject()
	if not g then return end
	local rapi=g:Filter(Card.IsLocation,nil,LOCATION_GRAVE)
	local mat=g:Filter(aux.NOT(Card.IsLocation),nil,LOCATION_GRAVE)
	Duel.Remove(rapi,POS_FACEUP,REASON_COST)
	Duel.SendtoGrave(mat,REASON_COST)
	g:DeleteGroup()
end

-- Immunity
function s.efilter(e,te)
	return te:GetOwner()~=e:GetOwner()
end

-- Trap from Extra Logic
function s.ct_spcon(e,tp,eg,ep,ev,re,r,rp)
	return (Duel.GetCurrentPhase()==PHASE_MAIN1 or Duel.GetCurrentPhase()==PHASE_MAIN2)
		and Duel.GetFlagEffect(1-tp,id) >= 8
end
function s.ct_sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCountFromEx(tp)>0 
		and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,true,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
	Duel.SetChainLimit(aux.FALSE)
end
function s.ct_spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,true,false,POS_FACEUP)
	end
end

-- Floodgate Reset Logic
function s.floodgate_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetChainLimit(aux.FALSE)
end

function s.floodgate_op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local reset_flag = RESET_PHASE+PHASE_END
	
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetTargetRange(0,1)
	e1:SetReset(reset_flag)
	Duel.RegisterEffect(e1,tp)

	local e1b=e1:Clone()
	e1b:SetCode(EFFECT_CANNOT_SUMMON)
	Duel.RegisterEffect(e1b,tp)

	local e1c=e1:Clone()
	e1c:SetCode(EFFECT_CANNOT_MSET)
	Duel.RegisterEffect(e1c,tp)

	local e1d=e1:Clone()
	e1d:SetCode(EFFECT_CANNOT_FLIP_SUMMON)
	Duel.RegisterEffect(e1d,tp)
	
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_ACTIVATE)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e2:SetTargetRange(0,1)
	e2:SetValue(s.aclimit)
	e2:SetReset(reset_flag)
	Duel.RegisterEffect(e2,tp)
	
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_ONFIELD,nil)
	if #g>0 then
		Duel.Hint(HINT_CARD,0,id)
		for tc in aux.Next(g) do
			Duel.NegateRelatedChain(tc,RESET_TURN_SET)
			local e3=Effect.CreateEffect(c)
			e3:SetType(EFFECT_TYPE_SINGLE)
			e3:SetCode(EFFECT_DISABLE)
			e3:SetReset(RESET_EVENT+RESETS_STANDARD+reset_flag)
			tc:RegisterEffect(e3)
			local e4=Effect.CreateEffect(c)
			e4:SetType(EFFECT_TYPE_SINGLE)
			e4:SetCode(EFFECT_DISABLE_EFFECT)
			e4:SetReset(RESET_EVENT+RESETS_STANDARD+reset_flag)
			tc:RegisterEffect(e4)
		end
	end
end
function s.aclimit(e,re,tp)
	return re:IsActiveType(TYPE_MONSTER)
end

-- =======================================================================
-- [REWORKED] Self Banish & Player Action Banish Logic
-- =======================================================================
function s.sp_nikke_filter(c,e,tp,mc)
	if not (c:IsSetCard(NIKKE_SET_ID) and c:IsType(TYPE_MONSTER) and c:IsCanBeSpecialSummoned(e,0,tp,true,false)) then return false end
	-- mc คือตัวที่กำลังจะถูกส่งออกนอกเกมเพื่อเคลียร์โซน
	if c:IsLocation(LOCATION_EXTRA) then
		return Duel.GetLocationCountFromEx(tp,tp,mc,c)>0
	else
		return Duel.GetMZoneCount(tp,mc)>0
	end
end

function s.attach_filter(c)
	return c:IsSetCard(NIKKE_SET_ID) and c:IsType(TYPE_MONSTER)
end

function s.tag_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then 
		return c:IsAbleToRemove() 
		   and Duel.GetFieldGroupCount(1-tp,LOCATION_ONFIELD,0)>0
		   and Duel.IsExistingMatchingCard(s.sp_nikke_filter,tp,LOCATION_DECK+LOCATION_EXTRA,0,1,nil,e,tp,c)
	end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,c,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,1-tp,LOCATION_ONFIELD)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK+LOCATION_EXTRA)
	Duel.SetChainLimit(aux.FALSE)
end

function s.tag_op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	
	-- 1. รีมูฟตัวเองออกจากเกมก่อนด้วยเอฟเฟค
	if Duel.Remove(c,POS_FACEUP,REASON_EFFECT)>0 then
		-- 2. บังคับอีกฝ่ายเลือกรีมูฟการ์ดตัวเอง
		local opp_g=Duel.GetFieldGroup(1-tp,LOCATION_ONFIELD,0)
		if #opp_g>0 then
			Duel.Hint(HINT_SELECTMSG,1-tp,HINTMSG_REMOVE)
			local rg=opp_g:Select(1-tp,1,1,nil)
			if #rg>0 and Duel.Remove(rg,POS_FACEUP,REASON_RULE)>0 then
				
				-- 3. จากนั้นอัญเชิญพิเศษ (ส่ง nil เข้าไปเพราะตัวเก่าไม่อยู่แล้ว โซนว่างแล้ว)
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
				local sg=Duel.SelectMatchingCard(tp,s.sp_nikke_filter,tp,LOCATION_DECK+LOCATION_EXTRA,0,1,1,nil,e,tp,nil)
				local tc=sg:GetFirst()
				
				if tc and Duel.SpecialSummon(tc,0,tp,tp,true,false,POS_FACEUP)>0 then
					local e1=Effect.CreateEffect(c)
					e1:SetType(EFFECT_TYPE_SINGLE)
					e1:SetCode(EFFECT_SET_ATTACK)
					e1:SetValue(tc:GetAttack()/2)
					e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
					tc:RegisterEffect(e1)
					
					if not tc:IsType(TYPE_LINK) then
						local e2=e1:Clone()
						e2:SetCode(EFFECT_SET_DEFENSE)
						e2:SetValue(tc:GetDefense()/2)
						tc:RegisterEffect(e2)
					end
					
					local e3=Effect.CreateEffect(c)
					e3:SetType(EFFECT_TYPE_SINGLE)
					e3:SetCode(EFFECT_DISABLE)
					e3:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
					tc:RegisterEffect(e3)
					
					local e4=Effect.CreateEffect(c)
					e4:SetType(EFFECT_TYPE_SINGLE)
					e4:SetCode(EFFECT_DISABLE_EFFECT)
					e4:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
					tc:RegisterEffect(e4)
					
					if tc:IsType(TYPE_XYZ) then
						Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
						local matg=Duel.SelectMatchingCard(tp,s.attach_filter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
						if #matg>0 then Duel.Overlay(tc,matg) end
					end
				end
			end
		end
	end
end