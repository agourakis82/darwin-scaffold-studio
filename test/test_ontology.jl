"""
Ontology Module Tests
Tests for OBO Foundry integration and ontology lookups
"""

using Test
using DarwinScaffoldStudio

@testset "Ontology Module" begin
    @testset "OBO Foundry Terms" begin
        # Test UBERON dict exists and has entries (keyed by ID like "UBERON:0002481")
        @test !isempty(DarwinScaffoldStudio.Ontology.OBOFoundry.UBERON)
        @test haskey(DarwinScaffoldStudio.Ontology.OBOFoundry.UBERON, "UBERON:0002481")  # bone tissue

        # Test CL dict exists (keyed by ID like "CL:0000062")
        @test !isempty(DarwinScaffoldStudio.Ontology.OBOFoundry.CL)
        @test haskey(DarwinScaffoldStudio.Ontology.OBOFoundry.CL, "CL:0000062")  # osteoblast

        # Test CHEBI dict exists
        @test !isempty(DarwinScaffoldStudio.Ontology.OBOFoundry.CHEBI)
    end

    @testset "Tissue Library" begin
        TL = DarwinScaffoldStudio.Ontology.TissueLibrary

        # Test TISSUES dict exists and has entries
        @test !isempty(TL.TISSUES)

        # Test get_tissue function with known ID
        bone_info = TL.get_tissue("UBERON:0002481")
        @test bone_info !== nothing
    end

    @testset "Cell Library" begin
        CL = DarwinScaffoldStudio.Ontology.CellLibrary

        # Test CELLS dict exists and has entries
        @test !isempty(CL.CELLS)
    end

    @testset "Material Library" begin
        ML = DarwinScaffoldStudio.Ontology.MaterialLibrary

        # Test MATERIALS dict exists and has entries
        @test !isempty(ML.MATERIALS)
    end

    @testset "Disease Library" begin
        DL = DarwinScaffoldStudio.Ontology.DiseaseLibrary

        # Test DISEASES dict exists and has content
        @test !isempty(DL.DISEASES)

        # Test bone disorders exist
        @test !isempty(DL.BONE_DISORDERS)
    end

    @testset "Cross-Ontology Relations" begin
        COR = DarwinScaffoldStudio.Ontology.CrossOntologyRelations

        # Test tissue-cell relations dict exists
        @test !isempty(COR.TISSUE_CELL_RELATIONS)

        # Test bone has cell relations
        @test haskey(COR.TISSUE_CELL_RELATIONS, "UBERON:0002481")
    end
end

println("✅ Ontology tests passed!")
