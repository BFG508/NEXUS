@testset "End-to-end pipeline" begin
    root = normpath(joinpath(@__DIR__, ".."))
    config_path = joinpath(root, "config", "pipeline_test.toml")
    mktempdir() do temp_dir
        result = run_pipeline(config_path; results_dir_override = temp_dir)
        @test result.documents == 6
        @test result.concepts == 4
        @test isfile(joinpath(temp_dir, "report.md"))
        @test isfile(joinpath(temp_dir, "tables", "concept_frequency.csv"))
        @test isfile(joinpath(temp_dir, "tables", "semantic_shift.csv"))
        @test isfile(joinpath(temp_dir, "figures", "concept_frequency.svg"))
    end
end
