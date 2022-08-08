using LinearAlgebra
using PyPlot
using Printf
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

# 空间离散化点数（实际是 2N + 1）
const N = 10000

function V_ws(x::AbstractFloat)
    -V₀ / (1 + exp((abs(x) - R) / a))
end

function V_ho(ħω::AbstractFloat, x::AbstractFloat)
    ω = ħω / ħ
    0.5 * mₑ * ω^2 * x^2 - V₀
end

function main()
    x0 = 3nm
    x = collect(-x0:x0/N:x0)
    for ħω in (0.5:0.1:1.2) * eV
        vho = @. V_ho(ħω, x) / eV
        plot(x / nm, vho, label=@sprintf("%.1feV", ħω / eV))
    end
    vws = @. V_ws(x) / eV
    plot(x / nm, vws, "r-", label="Woods-Saxon")
    ylim(-V₀ / eV, V₀ / eV)
    xlabel(raw"$x$/nm")
    ylabel(raw"$V$/eV")
    legend()
    show()
end

main()