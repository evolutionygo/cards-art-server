-- Hero Nikke Laplace
-- ID: 99900019
local s,id=GetID()
local NIKKE_SET_ID = 0xc02
local FIELD_SPELL_ID = 99900016

function s.initial_effect(c)
	-- [Xyz Summon Procedure] (Manual Brute Force)
	c:EnableReviveLimit()
	local e0=Effect.CreateEffect(c)
	e0:SetDescription(1165)
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetCode(EFFECT_SPSUMMON_PROC)
	e0:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e0:SetRange(LOCATION_EXTRA)
	e0:SetCondition(s.xyzcon)
	e0:SetTarget(s.xyztg)
	e0:SetOperation(s.xyzop)
	e0:SetValue(SUMMON_TYPE_XYZ)
	c:RegisterEffect(e0)

	-- 1. If Xyz Summoned: Attach 1 Monster & Transfer Materials
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e1:SetCondition(s.matcon)
	e1:SetTarget(s.mattg)
	e1:SetOperation(s.matop)
	c:RegisterEffect(e1)
	
	-- 2. Field Synergy (Gain ATK from Materials)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCondition(s.envcon)
	e2:SetValue(s.envval)
	c:RegisterEffect(e2)
	
	-- 3. Detach & Gain (Half LP + Pierce)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_ATKCHANGE)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1)
	e3:SetCost(s.boostcost)
	e3:SetOperation(s.boostop)
	c:RegisterEffect(e3,false,REGISTER_FLAG_DETACH_XMAT)

	-- 4. Protection: Absorb instead of Leaving (Except This Card + Transfer Materials)
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e4:SetCode(EFFECT_SEND_REPLACE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetTarget(s.reptg)
	e4:SetValue(s.repval)
	e4:SetOperation(s.repop)
	c:RegisterEffect(e4)
end

-- =======================================================================
-- [MANUAL XYZ LOGIC]
-- =======================================================================

-- [แก้ไขจุดนี้จุดเดียว] เพิ่ม Race Machine
function s.xyzfilter(c,xyzc)
	return c:IsFaceup() and c:IsRace(RACE_MACHINE) and c:IsLevel(7) and c:IsCanBeXyzMaterial(xyzc)
end

function s.xyzcheck(g,tp,xyzc)
	return g:GetCount()==2 and Duel.GetLocationCountFromEx(tp,tp,g,xyzc)>0
end
function s.xyzcon(e,c,og,min,max)
	if c==nil then return true end
	local tp=c:GetControler()
	local mg=nil
	if og then mg=og:Filter(s.xyzfilter,nil,c)
	else mg=Duel.GetMatchingGroup(s.xyzfilter,tp,LOCATION_MZONE,0,nil,c) end
	return mg:CheckSubGroup(s.xyzcheck,2,2,tp,c)
end
function s.xyztg(e,tp,eg,ep,ev,re,r,rp,chk,c,og,min,max)
	if og and not min then return true end
	local mg=nil
	if og then mg=og:Filter(s.xyzfilter,nil,c)
	else mg=Duel.GetMatchingGroup(s.xyzfilter,tp,LOCATION_MZONE,0,nil,c) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
	local g=mg:SelectSubGroup(tp,s.xyzcheck,false,2,2,tp,c)
	if g and #g>0 then
		g:KeepAlive()
		e:SetLabelObject(g)
		return true
	end
	return false
end
function s.xyzop(e,tp,eg,ep,ev,re,r,rp,c,og,min,max)
	local g=e:GetLabelObject()
	if not g then return end
	c:SetMaterial(g)
	Duel.Overlay(c,g)
	g:DeleteGroup()
end

-- =======================================================================
-- [Effect 1] Attach Monster & Transfer Materials
-- =======================================================================
function s.matcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_XYZ)
end
function s.matfilter(c)
	return c:IsType(TYPE_MONSTER) and not c:IsType(TYPE_TOKEN)
end
function s.mattg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and s.matfilter(chkc) and chkc~=e:GetHandler() end
	if chk==0 then return Duel.IsExistingTarget(s.matfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,e:GetHandler()) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
	Duel.SelectTarget(tp,s.matfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,e:GetHandler())
end
function s.matop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if c:IsRelateToEffect(e) and tc:IsRelateToEffect(e) and not tc:IsImmuneToEffect(e) then
		local og=tc:GetOverlayGroup()
		if #og>0 then
			Duel.Overlay(c,og) -- ย้ายของเก่ามาที่ Laplace
		end
		Duel.Overlay(c,Group.FromCards(tc)) -- ย้ายตัวมันเองตามมา
	end
end

-- =======================================================================
-- [Effect 2] Field Synergy
-- =======================================================================
function s.envfilter(c)
	return c:IsCode(FIELD_SPELL_ID) and c:IsFaceup()
end
function s.envcon(e)
	return Duel.IsExistingMatchingCard(s.envfilter,e:GetHandlerPlayer(),LOCATION_ONFIELD,0,1,nil)
end
function s.envval(e,c)
	local g=c:GetOverlayGroup()
	local atk=0
	for tc in aux.Next(g) do
		if tc:GetBaseAttack()>0 then 
			atk=atk+tc:GetBaseAttack() 
		end
	end
	return atk
end

-- =======================================================================
-- [Effect 3] Boost ATK & Pierce
-- =======================================================================
function s.boostcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end
function s.boostop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and c:IsFaceup() then
		local opponent = 1-tp
		local val = Duel.GetLP(opponent)
		local half_val = math.floor(val / 2)
		if half_val > 0 then
			Duel.Hint(HINT_NUMBER,tp,half_val)
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_ATTACK)
			e1:SetValue(half_val)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			c:RegisterEffect(e1)
		end
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_PIERCE)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		c:RegisterEffect(e2)
	end
end

-- =======================================================================
-- [Effect 4] Absorb instead of Leaving (Except This Card)
-- =======================================================================
function s.repfilter(c,tp,handler)
	return c:IsControler(tp) and c:IsSetCard(NIKKE_SET_ID) and c:IsOnField()
		and c:IsType(TYPE_MONSTER)
		and c:IsReason(REASON_EFFECT) and c:GetReasonPlayer()==1-tp
		and c~=handler -- ต้องไม่ใช่ Laplace
end
function s.xyz_dest_filter(c)
	return c:IsFaceup() and c:IsSetCard(NIKKE_SET_ID) and c:IsType(TYPE_XYZ)
end

function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local xyz_g=Duel.GetMatchingGroup(s.xyz_dest_filter,tp,LOCATION_MZONE,0,nil)
	
	if chk==0 then return eg:IsExists(s.repfilter,1,nil,tp,c) and #xyz_g>0 end
	
	if Duel.SelectYesNo(tp, aux.Stringid(id, 2)) then
		local g=eg:Filter(s.repfilter,nil,tp,c)
		local container=Group.CreateGroup()
		container:Merge(g)
		e:SetLabelObject(container)
		return true
	else
		return false
	end
end
function s.repval(e,c)
	return s.repfilter(c,e:GetHandlerPlayer(),e:GetHandler())
end

function s.repop(e,tp,eg,ep,ev,re,r,rp)
	local g=e:GetLabelObject()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	local xyz_g=Duel.GetMatchingGroup(s.xyz_dest_filter,tp,LOCATION_MZONE,0,nil)
	local dest=xyz_g:Select(tp,1,1,nil):GetFirst()
	
	if dest and #g>0 then
		Duel.Hint(HINT_CARD,0,id)
		
		-- Loop ย้ายวัตถุดิบเก่าก่อน
		for tc in aux.Next(g) do
			local og=tc:GetOverlayGroup()
			if #og>0 then
				Duel.Overlay(dest,og)
			end
		end
		
		-- ย้ายตัว Monster ตามไป
		Duel.Overlay(dest,g)
	end
end