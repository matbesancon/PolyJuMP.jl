@testset "PolyModule" begin
    m = Model()
    # Triggers the creation of polydata
    @test isnull(PolyJuMP.getpolydata(m).nonnegpolydefault)
    @test_throws ErrorException PolyJuMP.getdefault(m, NonNegPoly)
    @test isnull(PolyJuMP.getpolydata(m).nonnegpolymatrixdefault)
    @test_throws ErrorException PolyJuMP.getdefault(m, NonNegPolyMatrix)
    setpolymodule!(m, TestPolyModule)
    @test PolyJuMP.getdefault(m, NonNegPoly) == TestPolyModule.TestNonNegConstraint
    @test PolyJuMP.getdefault(m, NonNegPolyMatrix) == TestPolyModule.TestNonNegMatrixConstraint
    PolyJuMP.setdefault!(m, NonNegPolyMatrix, TestPolyModule.TestNonNegConstraint)
    @test PolyJuMP.getdefault(m, NonNegPolyMatrix) == TestPolyModule.TestNonNegConstraint
end
