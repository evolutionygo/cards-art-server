-- Nikke Nayuta (Token)
-- ID: 99900038
local s,id=GetID()
local ID_NIKKE = 0xc02

function s.initial_effect(c)
	-- Token นี้มีเอฟเฟกต์ในตัว (Built-in Effects)
	
	-- 1. Reflect Battle Damage & No Damage for Controller
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_PRE_BATTLE_DAMAGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetOperation(s.reflect_op)
	c:RegisterEffect(e1)

	-- 2. Immunity to Negation
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCode(EFFECT_IMMUNE_EFFECT)
	e3:SetValue(s.negate_immune_filter)
	c:RegisterEffect(e3)
end

-- ==================================================================
-- [Logic] Reflect Damage (Updated Limit: 900)
-- ==================================================================
function s.reflect_op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- เช็คว่าดาเมจเกิดจากการต่อสู้ของ Token ตัวนี้หรือไม่
	if c~=Duel.GetAttacker() and c~=Duel.GetAttackTarget() then return end
	
	-- ถ้าเรา (tp) ต้องรับดาเมจ (ev)
	if ep==tp and ev>0 then
		local dmg = ev
		-- [FIX] แก้ไขตัวเลขสูงสุดเป็น 900
		if dmg > 900 then dmg = 900 end 
		
		-- 1. สะท้อนดาเมจไปหาอีกฝ่าย
		Duel.Damage(1-tp,dmg,REASON_BATTLE)
		
		-- 2. เปลี่ยนดาเมจที่เราจะโดนให้เป็น 0
		Duel.ChangeBattleDamage(tp,0)
	end
end

-- ==================================================================
-- [Logic] Immunity to Negation (Non-Nikke Only)
-- ==================================================================
function s.negate_immune_filter(e,te)
	-- 1. ถ้าคนใช้เป็น Nikke ให้ผ่านตลอด (ไม่กันพวกเดียวกันเอง)
	if te:GetOwner():IsSetCard(ID_NIKKE) then return false end

	-- 2. เช็คว่าเป็นเอฟเฟกต์ประเภท Disable/Negate หรือไม่
	if (te:GetType() & EFFECT_TYPE_ACTIONS) ~= 0 then
		local cat = te:GetCategory()
		return (cat & CATEGORY_DISABLE)~=0 or (cat & CATEGORY_NEGATE)~=0
	end

	-- 3. เช็ค Continuous Effect
	local ec = te:GetCode()
	return ec==EFFECT_DISABLE or ec==EFFECT_DISABLE_EFFECT or ec==EFFECT_DISABLE_CHAIN
end