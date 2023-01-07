using LinearAlgebra
using PyPlot
const plt = PyPlot

# 尽管很多时候我们不会使用国际单位制，这里我们为了代码与公式更好的对应，
# 以及降低理解难度，我们统一采取国际单位制

const ħ = 1.05457e-34
const eV = 1.60217e-19
const MeV = 1.60217e-13
const c = 299792458
const ma = 938.919MeV/c^2 # 质子和中子的平均质量
const fm = 1e-15

# 离散化点数
const N = 10000

function V_Woods_Saxon(r::AbstractFloat, V₀ = 50MeV, R = 5fm, a = 0.5fm)
    -V₀ / (1 + exp((r - R)/a))
end

function solve_center(l::Integer, V::Function, R0::AbstractFloat)
    @assert R0 > 0
    Δr = R0 / N
    r = range(Δr, R0; length=N)
    t = ħ^2 / (2ma * Δr^2)
    d = @. V(r) + 2t + ħ^2 * l * (l+1) / (2ma * r^2)
    H = SymTridiagonal(d, -t*ones(length(r)-1))
    eigen(H, -50MeV, 0.)
end

function main()
    R0 = 30fm
    Δr = R0 / N
    r = range(Δr, R0; length=N)
    for l = 0:2
        vals, vecs = solve_center(l, V_Woods_Saxon, R0)
        for (n, e) in enumerate(vals)
            println("$(n)th bound state energy of l = $l is $(e/MeV)MeV")
            plt.plot(r/fm, vecs[:, n], label="n=$n, l=$l")
        end
    end
    plt.xlabel(raw"$x$/fm")
    plt.legend()
    plt.show()
end