using PyPlot

ħω = [0.3, 0.5, 0.8, 1, 1.5, 2, 3, 4, 5]
e3 = [
    -1.654920303622706,
    -2.0076361280459634,
    -2.0581341565847344,
    -2.058051894257295,
    -2.058527642454781,
    -2.0528589392589116,
    -1.9980427292267227,
    -1.8298075670415028,
    -1.5424051778120673
]

plot(ħω, e3, "rx")
plot(ħω, e3, "cyan")
xlabel(raw"$\hbar\omega$/eV")
ylabel(raw"$E_3$/eV")
savefig("woods-saxon-hw-depent.png")