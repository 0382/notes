using LinearAlgebra
using PyPlot
using SpecialFunctions # gamma
using FastGaussQuadrature # gausshermite
using ClassicalOrthogonalPolynomials # Hermite

const ħ = 1.05457e-34
const mₑ = 9.10938e-31
const eV = 1.60217e-19
const nm = 1e-9

# 有限深方势阱参数
const V₀ = 5eV
const R = 0.5nm
const a = 0.1nm

# 谐振子基矢参数
const ħω = 0.8eV
const α = √(mₑ * ħω) / ħ

# 空间离散化点数（实际是 2N + 1）
const N = 10000

function V_ws(x::AbstractFloat)
    -V₀ / (1 + exp((abs(x) - R) / a))
end

function Nn(n)
    √(α / (√π * exp2(n) * gamma(n+1)))
end

function Nmn(m, n)
    1. / √(π * exp2(m+n) * gamma(m+1) * gamma(n+1))
end

function V_mat(V::Function, nmax::Integer)
    Vmat = zeros(nmax, nmax)
    # 由于厄米多项式的震荡性质，这里离散点数最好多一点
    ξ, w = gausshermite(1000)
    v = @. V(ξ/α)
    Hxn = Hermite()[ξ, 1:nmax]

    for m = 1:nmax
        for n = m:nmax
            Vmat[m, n] = sum(@. v * Nmn(m-1,n-1) * w * Hxn[:, m] * Hxn[:, n])
        end
    end
    return Symmetric(Vmat)
end

function solve_1d_ho(V::Function, nmax::Integer)
    T = zeros(nmax, nmax)
    for n = 1:nmax
        T[n, n] = 0.5ħω * (n - 0.5) # julia 下标是从 1 开始的，但是谐振子 n 是从 0 开始的
        if n+2 <= nmax
            T[n, n+2] = -0.25ħω * √(n*(n+1))
        end
    end
    H = Symmetric(T) + V_mat(V, nmax)
    eigen(H, -V₀, 0)
end

function solve_1d_space(V::Function, x0::AbstractFloat)
    @assert x0 > 0
    Δx = x0/N
    x = -x0:Δx:x0
    t = ħ^2 / (2mₑ * Δx^2)
    d = @. V(x) + 2t
    H = SymTridiagonal(d, -t * ones(length(x)-1))
    eigen(H, -V₀, 0.)
end

function test_ho()
    clf()
    println("solve with harmonic oscillator basis")
    println("ħω = ", ħω / eV, "eV")
    nmax = 10
    vals, vecs = solve_1d_ho(V_ws, nmax)
    x = collect(-3nm:0.001nm:3nm)
    ξ = α * x
    Hxn = Hermite()[ξ, 1:nmax]
    wx = @. exp(-0.5ξ^2)
    nn = @. Nn(1:nmax)
    ψxn = @. Hxn * wx * nn'
    wave = ψxn * vecs
    for (i, e) in enumerate(vals)
        println("$(i)th bound state energy is $(e/eV)eV")
        plot(x./nm, wave[:, i], label="$(i)th state")
    end
    legend()
    xlabel(raw"$x$/nm")
    savefig("woods-saxon-ho.png")
end

function test_space()
    clf()
    println("solve with space basis")
    x0 = 3nm
    x = collect(-x0:x0/N:x0) ./ 1nm
    vals, vecs = solve_1d_space(V_ws, x0)
    for (i, e) in enumerate(vals)
        println("$(i)th bound state energy is $(e/eV)eV")
        plot(x, vecs[:, i], label = "$(i)th state")
    end
    xlabel(raw"$x$/nm")
    legend()
    savefig("woods-saxon-space.png")
end

test_ho()
test_space()