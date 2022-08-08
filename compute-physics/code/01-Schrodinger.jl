using LinearAlgebra
using PyPlot
using Roots

# 尽管很多时候我们不会使用国际单位制，这里我们为了代码与公式更好的对应，
# 以及降低理解难度，我们统一采取国际单位制

const ħ = 1.05457e-34
const mₑ = 9.10938e-31
const eV = 1.60217e-19
const nm = 1e-9

# 有限深方势阱参数
const V₀ = 5eV
const a = 1nm

# 离散化点数（实际是 2N + 1）
const N = 10000

function V_well(x::AbstractFloat)
    abs(x) < a / 2 ? -V₀ : 0.
end

"有限深方势阱的解析解（虽然求解超越方程是数值的）"
function exact_well()
    c = mₑ * V₀ * a^2 / 2ħ^2
    f(ξ) = ξ*tan(ξ) - √(c - ξ^2)
    g(ξ) = -ξ*cot(ξ) - √(c - ξ^2)
    even_ξ = fzeros(f, 0, √c)
    odd_ξ = fzeros(g, 0, √c)
    # 由于函数性质比较奇异，可能会出现一些奇怪的根，将其去掉
    deleteat!(even_ξ, @. abs(f(even_ξ)) > 1)
    deleteat!(odd_ξ, @. abs(g(odd_ξ)) > 1)
    even_energy = @. 2even_ξ^2 * ħ^2 / (a^2 * mₑ) - V₀
    odd_energy = @. 2odd_ξ^2 * ħ^2 / (a^2 * mₑ) - V₀
    for (i, e) in enumerate(even_energy)
        println("$(i)th even parity state is $(e/eV)eV")
    end
    for (i, e) in enumerate(odd_energy)
        println("$(i)th odd parity state is $(e/eV)eV")
    end
end

function solve_1d(V::Function, x0::AbstractFloat)
    @assert x0 > 0
    Δx = x0/N
    x = -x0:Δx:x0
    t = ħ^2 / (2mₑ * Δx^2)
    d = @. V(x) + 2t
    H = SymTridiagonal(d, -t * ones(length(x)-1))
    eigen(H, -V₀, 0.)
end

function main()
    # exact solve
    exact_well()
    # numeric solve
    x0 = 3nm
    x = collect(-x0:x0/N:x0) ./ 1nm
    vals, vecs = solve_1d(V_well, x0)
    for (i, e) in enumerate(vals)
        println("$(i)th bound state energy is $(e/eV)eV")
        plot(x, vecs[:, i], label = "$(i)th state")
    end
    xlabel(raw"$x$/nm")
    legend()
    # savefig("well.png")
    show()
end

main()
