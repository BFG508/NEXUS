@enum Action::UInt8 begin
    Defect = 0
    Cooperate = 1
end

struct PrisonersDilemma
    temptation::Float64
    reward::Float64
    punishment::Float64
    sucker::Float64

    function PrisonersDilemma(
        temptation::Real = 5.0,
        reward::Real = 3.0,
        punishment::Real = 1.0,
        sucker::Real = 0.0,
    )
        t = Float64(temptation)
        r = Float64(reward)
        p = Float64(punishment)
        s = Float64(sucker)
        t > r > p > s || throw(ArgumentError("Prisoner's Dilemma requires T > R > P > S."))
        return new(t, r, p, s)
    end
end

"""Return the pair of payoffs for one Prisoner's Dilemma interaction."""
@inline function game_payoff(game::PrisonersDilemma, a::Action, b::Action)
    if a == Cooperate
        return b == Cooperate ? (game.reward, game.reward) : (game.sucker, game.temptation)
    end
    return b == Cooperate ? (game.temptation, game.sucker) : (game.punishment, game.punishment)
end

"""Return the row-player payoff matrix ordered as cooperate, defect."""
function prisoners_dilemma_matrix(game::PrisonersDilemma = PrisonersDilemma())
    return [game.reward game.sucker; game.temptation game.punishment]
end
