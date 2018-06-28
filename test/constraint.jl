_isequal(p, q) = all(JuMP.isequal_canonical.(coefficients(p), coefficients(q)))
function _isequal(x::AbstractArray, y::AbstractArray)
    size(x) == size(y) && all(_isequal.(x, y))
end

@testset "@constraint macro with polynomials" begin
    m = Model()
    setpolymodule!(m, TestPolyModule)
    @variable m α
    @variable m β
    @polyvar x y
    p = α * x*y + β * x^2
    #q = MatPolynomial([α β; β α], [x])
    q = α*x^2 + β*x*y + α*y^2
    @test macroexpand(:(@constraint(m, p))).head == :error
    @test macroexpand(:(@constraint(m, begin p >= 0 end))).head == :error
    @test macroexpand(:(@constraint(m, +(p, p, p)))).head == :error
    @test macroexpand(:(@constraint(m, p >= 0, 1))).head == :error
    #@test macroexpand(:(@constraint(m, p >= 0, domain = (@set x >= -1 && x <= 1, domain = y >= -1 && y <= 1)))).head == :error
    @test macroexpand(:(@constraint(m, p + 0, domain = (@set x >= -1 && x <= 1)))).head == :error

    function testcon(m, cref, set::ZeroPoly, p, ineqs, eqs, basis=PolyJuMP.MonomialBasis, kwargs=[])
        @test isa(cref, ConstraintRef{Model, PolyJuMP.PolyConstraint})
        c = cref.index
        @test c.set == set
        # == between JuMP affine expression is not accurate, e.g. β + α != α + β
        # == 0 is not defined either
        # c.p and p can be matrices
        @test _isequal(c.p, p)
        if isempty(ineqs)
            @test c isa PolyJuMP.ZeroConstraint
        else
            @test c isa PolyJuMP.ZeroConstraintWithDomain
        end
    end
    function testcon(m, cref, set, p, ineqs, eqs, basis=PolyJuMP.MonomialBasis, kwargs=[])
        @test isa(cref, ConstraintRef{Model, PolyJuMP.PolyConstraint})
        c = PolyJuMP.getdelegate(cref)
        @test c.basis == basis
        @test c.set == set
        @test c.kwargs == kwargs
        # == between JuMP affine expression is not accurate, e.g. β + α != α + β
        # == 0 is not defined either
        # c.p and p can be matrices
        @test _isequal(c.p, p)
        if isempty(ineqs)
            if isempty(eqs)
                @test isa(c.domain, FullSpace)
            else
                @test isa(c.domain, AlgebraicSet)
                @test equalities(c.domain) == eqs
            end
        else
            @test isa(c.domain, BasicSemialgebraicSet)
            @test inequalities(c.domain) == ineqs
            @test equalities(c.domain) == eqs
        end
    end

    f(x, y) = @set x + y == 2
    dom = @set x^2 + y^2 == 1 && x^3 + x*y^2 + y >= 1
    testcon(m, @constraint(m, p >= q + 1, domain = @set y >= 1 && dom), TestPolyModule.TestNonNegConstraint(), p - q - 1, [y-1, x^3 + x*y^2 + y - 1], [x^2 + y^2 - 1])
    testcon(m, @constraint(m, p <= q), TestPolyModule.TestNonNegConstraint(), q - p, [], [])
    testcon(m, @constraint(m, q - p in NonNegPoly()), TestPolyModule.TestNonNegConstraint(), q - p, [], [])
    testcon(m, @constraint(m, p + q >= 0, domain = @set x == y^3), TestPolyModule.TestNonNegConstraint(), p + q, [], [x - y^3])
    testcon(m, @constraint(m, p == q, domain = @set x == 1 && f(x, y)), ZeroPoly(), p - q, [], [x - 1, x + y - 2])
    testcon(m, @constraint(m, p == q, domain = dom), ZeroPoly(), p - q, [x^3 + x*y^2 + y - 1], [x^2 + y^2 - 1])
    testcon(m, @constraint(m, p - q in ZeroPoly(), domain = @set x == 1 && f(x, y)), ZeroPoly(), p - q, [], [x - 1, x + y - 2])
    testcon(m, @SDconstraint(m, [p q; q 0] ⪰ [0 0; 0 p]), TestPolyModule.TestNonNegMatrixConstraint(), [p q; q -p], [], [])
    testcon(m, @constraint(m, p <= q, maxdegree=1), TestPolyModule.TestNonNegConstraint(), q - p, [], [], MonomialBasis, [(:maxdegree, 1)])
end
