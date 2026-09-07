@testset "Uncertainty utilities" begin
    interval = mean_confidence_interval([1.0, 2.0, 3.0, 4.0]; method = :student_t)
    @test interval.lower < interval.mean < interval.upper

    bootstrap = mean_confidence_interval(
        [1.0, 2.0, 3.0, 4.0];
        method = :bootstrap,
        bootstrap_replicates = 100,
        seed = 7,
    )
    @test bootstrap.lower <= bootstrap.mean <= bootstrap.upper

    low, high = wilson_interval(0, 10)
    @test low == 0.0
    @test 0.0 < high < 1.0
end
