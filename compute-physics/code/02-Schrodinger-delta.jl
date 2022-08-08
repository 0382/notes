using LinearAlgebra
using PyPlot
using SpecialFunctions # gamma
using ClassicalOrthogonalPolynomials # hermiteh

const ħ = 1.05457e-34
const mₑ = 9.10938e-31
const eV = 1.60217e-19
const nm = 1e-9

# 势阱参数
const γ = 0.1eV * nm

function Nn(n, ħω)
    α = √(mₑ * ħω) / ħ
    √(α / (√π * exp2(n) * gamma(n+1)))
end

function solve_delta(nmax::Integer, ħω::AbstractFloat)
    T = zeros(nmax, nmax)
    V = zeros(nmax, nmax)
    for n = 1:nmax
        T[n, n] = 0.5ħω * (n - 0.5) # julia 下标是从 1 开始的，但是谐振子 n 是从 0 开始的
        if n+2 <= nmax
            T[n, n+2] = -0.25ħω * √(n*(n+1))
        end
    end
    for m = 1:nmax
        for n = m:nmax
            V[m, n] = -γ * Nn(m-1, ħω) * Nn(n-1, ħω) * hermiteh(m-1, 0.) * hermiteh(n-1, 0.)
        end
    end
    H = Symmetric(T + V)
    eigen(H, 1:1)
end

function main()
    exact_energy = -mₑ * γ^2 / 2ħ^2
    L = ħ^2 / (mₑ * γ) # characteristic length
    println("exact solution: energy is ", exact_energy / eV, "eV")
    println("characteristic length is ", L / nm, "nm")

    x = collect(-3nm:0.001nm:3nm)
    exact_wave = @. exp(-abs(x)/L) / √L
    plot(x / nm, exact_wave, label="exact wave")
    
    nmax = 50
    for ħω in [0.1, 1, 10] * eV
        vals, vecs = solve_delta(nmax, ħω)
        println("solve with ħω = $(ħω/eV)eV, E = $(vals[1]/eV)eV")
        α = √(mₑ * ħω) / ħ
        ξ = α * x
        Hxn = Hermite()[ξ, 1:nmax]
        wx = @. exp(-0.5ξ^2)
        nn = @. Nn(1:nmax, ħω)
        ψxn = @. Hxn * wx * nn'
        wave = ψxn * vecs
        plot(x / nm, abs.(wave[:, 1]), label="ħω=$(ħω/eV)eV")
    end
    legend()
    xlabel(raw"$x$/nm")
    savefig("delta-wave.png")
end

main()
