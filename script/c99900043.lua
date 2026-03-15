-- Heretic Nikke Nihilister
-- ID: 99900043
local s,id=GetID()
local ID_NIKKE = 0xc02
local ID_HERETIC = 0xc20

function s.initial_effect(c)
	c:EnableReviveLimit()

	-- 1. Ritual Summon Procedure
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetTarget(s.rittg)
	e1:SetOperation(s.ritop)
	c:RegisterEffect(e1)

	-- 2. Stats (ATK/DEF) - Max 2700
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetValue(s.atkval)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EFFECT_UPDATE_DEFENSE)
	e3:SetValue(s.defval)
	c:RegisterEffect(e3)

	-- 3. Protection for "Heretic" monsters
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetCode(EFFECT_UNRELEASABLE_SUMMON)
	e4:SetRange(LOCATION_MZONE)
	e4:SetTargetRange(LOCATION_MZONE,0)
	e4:SetTarget(s.protfilter)
	e4:SetValue(1)
	c:RegisterEffect(e4)
	local e5=e4:Clone()
	e5:SetCode(EFFECT_UNRELEASABLE_NONSUMMON)
	c:RegisterEffect(e5)
	
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_FIELD)
	e6:SetRange(LOCATION_MZONE)
	e6:SetCode(EFFECT_CANNOT_BE_FUSION_MATERIAL)
	e6:SetTargetRange(LOCATION_MZONE,0)
	e6:SetTarget(s.protfilter)
	e6:SetValue(s.matlimit)
	c:RegisterEffect(e6)
	local e7=e6:Clone()
	e7:SetCode(EFFECT_CANNOT_BE_SYNCHRO_MATERIAL)
	c:RegisterEffect(e7)
	local e8=e6:Clone()
	e8:SetCode(EFFECT_CANNOT_BE_XYZ_MATERIAL)
	c:RegisterEffect(e8)
	local e9=e6:Clone()
	e9:SetCode(EFFECT_CANNOT_BE_LINK_MATERIAL)
	c:RegisterEffect(e9)

	-- 4. Tribute & Burn (Updated: Tribute as Cost)
	local e10=Effect.CreateEffect(c)
	e10:SetDescription(aux.Stringid(id,1))
	e10:SetCategory(CATEGORY_DAMAGE)
	e10:SetType(EFFECT_TYPE_IGNITION)
	e10:SetRange(LOCATION_MZONE)
	e10:SetCountLimit(1)
	e10:SetCost(s.burncost) -- Tribute as COST
	e10:SetTarget(s.burntg)
	e10:SetOperation(s.burnop)
	c:RegisterEffect(e10)

	-- 5. Anti-Response (Punishment: Non-Heretic Only)
	local e11=Effect.CreateEffect(c)
	e11:SetDescription(aux.Stringid(id,2))
	e11:SetCategory(CATEGORY_REMOVE)
	e11:SetType(EFFECT_TYPE_QUICK_F)
	e11:SetCode(EVENT_CHAINING)
	e11:SetRange(LOCATION_MZONE)
	e11:SetCountLimit(1,id+EFFECT_COUNT_CODE_CHAIN)
	e11:SetCondition(s.bancon)
	e11:SetTarget(s.bantg)
	e11:SetOperation(s.banop)
	c:RegisterEffect(e11)
end

-- ==================================================================
-- Logic 1: Ritual Summon
-- ==================================================================
function s.mat_filter(c)
	return (c:IsRace(RACE_MACHINE) or c:IsSetCard(ID_NIKKE)) and
		   ((c:IsLocation(LOCATION_GRAVE) and c:IsAbleToRemoveAsCost(POS_FACEDOWN)) or
			(c:IsLocation(LOCATION_REMOVED) and c:IsFaceup()))
end
function s.check_materials(sg)
	if #sg~=2 then return false end
	return sg:IsExists(Card.IsRace,1,nil,RACE_MACHINE) and sg:IsExists(Card.IsSetCard,1,nil,ID_NIKKE)
end
function s.rittg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		local mg=Duel.GetMatchingGroup(s.mat_filter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,nil)
		return c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_RITUAL,tp,false,true)
			and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and mg:CheckSubGroup(s.check_materials,2,2)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end
function s.ritop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local mg=Duel.GetMatchingGroup(s.mat_filter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,nil)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	if not c:IsRelateToEffect(e) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local sg=mg:SelectSubGroup(tp,s.check_materials,false,2,2)
	if sg then
		c:SetMaterial(sg)
		local g_rem = sg:Filter(Card.IsLocation, nil, LOCATION_REMOVED)
		if #g_rem > 0 then Duel.SendtoGrave(g_rem, REASON_RULE+REASON_RETURN) end
		Duel.Remove(sg, POS_FACEDOWN, REASON_COST+REASON_MATERIAL+REASON_RITUAL)
		Duel.BreakEffect() 
		Duel.SpecialSummon(c,SUMMON_TYPE_RITUAL,tp,tp,false,true,POS_FACEUP)
		c:CompleteProcedure()
	end
end

-- ==================================================================
-- Logic 2: Stats (Max 2700)
-- ==================================================================
function s.atkval(e,c)
	local count = Duel.GetMatchingGroupCount(Card.IsFacedown,0,LOCATION_REMOVED,LOCATION_REMOVED,nil)
	return math.min(count * 300, 2700)
end
function s.defval(e,c)
	local count = Duel.GetMatchingGroupCount(Card.IsFacedown,0,LOCATION_REMOVED,LOCATION_REMOVED,nil)
	return -math.min(count * 300, 2700)
end

-- ==================================================================
-- Logic 3: Protection
-- ==================================================================
function s.protfilter(e,c)
	return c:IsSetCard(ID_HERETIC)
end
function s.matlimit(e,c,sumtype,tp)
	return true
end

-- ==================================================================
-- Logic 4: Tribute & Burn (Updated: Tribute as Cost)
-- ==================================================================
function s.burncost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	-- เงื่อนไข: ต้องมีมอนสเตอร์ที่สังเวยได้ (Releasable) ในสนามไหนก็ได้ที่ไม่ใช่ตัวเอง
	if chk==0 then 
		return Duel.IsExistingMatchingCard(Card.IsReleasable,tp,LOCATION_MZONE,LOCATION_MZONE,1,c)
	end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	-- เลือกสังเวย 1 ใบ (Cost)
	local g=Duel.SelectMatchingCard(tp,Card.IsReleasable,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,c)
	-- สั่ง Release ตรงนี้เลย โดยใส่ REASON_COST
	Duel.Release(g,REASON_COST)
end

function s.burntg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end -- ผ่านเสมอเพราะเช็คไปแล้วใน Cost
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,0)
end

function s.burnop(e,tp,eg,ep,ev,re,r,rp)
	-- ทำดาเมจตามจำนวนรีมูฟคว่ำหน้า * 200
	local count=Duel.GetMatchingGroupCount(Card.IsFacedown,tp,LOCATION_REMOVED,LOCATION_REMOVED,nil)
	if count>0 then
		Duel.Damage(1-tp,count*200,REASON_EFFECT)
	end
end

-- ==================================================================
-- Logic 5: Anti-Response
-- ==================================================================
function s.bancon(e,tp,eg,ep,ev,re,r,rp)
	if ev<2 then return false end
	local pe=Duel.GetChainInfo(ev-1,CHAININFO_TRIGGERING_EFFECT)
	if not pe or pe:GetHandler()~=e:GetHandler() then return false end
	
	local rc=re:GetHandler()
	if rc:IsSetCard(ID_HERETIC) then return false end

	return true
end

function s.bantg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local rc=re:GetHandler()
	Duel.SetTargetCard(rc)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,rc,1,0,0)
end

function s.banop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.Remove(tc,POS_FACEDOWN,REASON_EFFECT)
	end
end