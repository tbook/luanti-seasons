seasons.texture_plan = {}

-- Placeholder planning hooks for seasonal visuals.
-- Expected future outputs:
-- - leaf color transition weighting
-- - grass browning weighting
-- - per-node probabilities derived from state

function seasons.texture_plan.get_leaf_fall_probability(state, k)
	k = k or 1.0
	return math.max(0, math.min(1, seasons.model.fallness(state) * k))
end
