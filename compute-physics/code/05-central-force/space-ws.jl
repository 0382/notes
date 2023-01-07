using LinearAlgebra

const m = 939 # Mev/c^2
const ħ = 197.326 # MeV c fm

N = 8 # 中子数
Z = 8 # 质子数
A = N + Z # 核子数

ħω = 41 / cbrt(A) # MeV
α = √(m * ħω) / ħ


@show ħω
@show α

function Vws(r)
    V0 = 51
    a = 0.67 # fm
    R = 1.27cbrt(A)
    return -V0 / (1 + exp((r - R)/a))
end

function Vc(r)
    R = 1.27cbrt(A)
    r ≤ R && return 1.44 * Z * (3 - (r/R)^2) / 2R
    r > R && return 1.44 * Z / r
end

function Vls(r)
    V0 = 51
    a = 0.67 # fm
    R = 1.27cbrt(A)
    Vls0 = 0.44V0 * 1.27^2
    t = exp((r-R)/a)
    return -Vls0 / (r*a) * t / (1 + t)^2
end

"""
    solve_ws_space(l::Integer, dj::Integer)
l: 轨道角动量
dj: 总角动量的两倍（因为总角动量是半整数）
"""
function solve_ws_space(l::Integer, dj::Integer)
    j = dj / 2.0
    V(r) = begin
        # 想计算中子，删掉 Vc 项就好了
        Vws(r) + Vc(r) + 0.5(j*(j+1) - l*(l+1) - 3/4)*Vls(r)
    end

    Δx = 0.1
    N = 100
    x = collect(1:N) * Δx
    efactor = ħ^2 / 2m
    d = @. 2efactor / (Δx)^2 + (V(x) + efactor * l*(l+1)/(x^2))
    e = fill(-efactor/(Δx)^2, N-1)
    H = SymTridiagonal(d, e)
    vals, vecs = eigen(H, V(0), 0)
    for (i, e) in enumerate(vals)
        println("$(i)th bound state is $(e)MeV")
    end
end