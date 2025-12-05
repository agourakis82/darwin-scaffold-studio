"""
Ontology Module Tests
Tests for OBO Foundry integration and ontology lookups
"""

using Test
using DarwinScaffoldStudio

@testset "Ontology Module" begin
    @testset "OBO Foundry Terms" begin
        # Test UBERON (anatomy)
        @test haskey(DarwinScaffoldStudio.Ontology.OBOFoundry.UBERON, "bone tissue")
        bone = DarwinScaffoldStudio.Ontology.OBOFoundry.UBERON["bone tissue"]
        @test bone.id == "UBERON:0002481"
        @test occursin("bone", lowercase(bone.name))

        # Test CL (cell types)
        @test haskey(DarwinScaffoldStudio.Ontology.OBOFoundry.CL, "osteoblast")
        osteoblast = DarwinScaffoldStudio.Ontology.OBOFoundry.CL["osteoblast"]
        @test osteoblast.id == "CL:0000062"

        # Test CHEBI (chemicals)
        @test haskey(DarwinScaffoldStudio.Ontology.OBOFoundry.CHEBI, "hydroxyapatite")
        ha = DarwinScaffoldStudio.Ontology.OBOFoundry.CHEBI["hydroxyapatite"]
        @test startswith(ha.id, "CHEBI:")
    end

    @testset "Tissue Library" begin
        TL = DarwinScaffoldStudio.Ontology.TissueLibrary

        # Test bone tissue entry
        @test haskey(TL.TISSUE_DATABASE, "bone")
        bone = TL.TISSUE_DATABASE["bone"]
        @test bone.ontology_id == "UBERON:0002481"
        @test bone.optimal_porosity[1] <= bone.optimal_porosity[2]
        @test bone.optimal_pore_size[1] <= bone.optimal_pore_size[2]

        # Test cartilage
        @test haskey(TL.TISSUE_DATABASE, "cartilage")
        cartilage = TL.TISSUE_DATABASE["cartilage"]
        @test cartilage.ontology_id == "UBERON:0002418"
    end

    @testset "Cell Library" begin
        CL = DarwinScaffoldStudio.Ontology.CellLibrary

        # Test osteoblast entry
        @test haskey(CL.CELL_DATABASE, "osteoblast")
        osteoblast = CL.CELL_DATABASE["osteoblast"]
        @test osteoblast.ontology_id == "CL:0000062"
        @test osteoblast.size_um[1] <= osteoblast.size_um[2]

        # Test chondrocyte
        @test haskey(CL.CELL_DATABASE, "chondrocyte")
    end

    @testset "Material Library" begin
        ML = DarwinScaffoldStudio.Ontology.MaterialLibrary

        # Test hydroxyapatite
        @test haskey(ML.MATERIAL_DATABASE, "hydroxyapatite")
        ha = ML.MATERIAL_DATABASE["hydroxyapatite"]
        @test ha.elastic_modulus_gpa > 0
        @test ha.biocompatibility in [:excellent, :good, :moderate, :poor]

        # Test PCL
        @test haskey(ML.MATERIAL_DATABASE, "pcl")
    end

    @testset "Extended Libraries" begin
        # Disease Library
        DL = DarwinScaffoldStudio.Ontology.DiseaseLibrary
        @test haskey(DL.DISEASE_DATABASE, "osteoporosis")
        osteoporosis = DL.DISEASE_DATABASE["osteoporosis"]
        @test startswith(osteoporosis.ontology_id, "DOID:")

        # Process Library
        PL = DarwinScaffoldStudio.Ontology.ProcessLibrary
        @test haskey(PL.BIOLOGICAL_PROCESS_DATABASE, "ossification")

        # Fabrication Library
        FL = DarwinScaffoldStudio.Ontology.FabricationLibrary
        @test haskey(FL.FABRICATION_DATABASE, "3d_bioprinting")
    end

    @testset "OntologyManager Lookup" begin
        OM = DarwinScaffoldStudio.Ontology.OntologyManager

        # Test tissue lookup
        bone_info = OM.lookup_tissue("bone")
        @test bone_info !== nothing
        @test bone_info.ontology_id == "UBERON:0002481"

        # Test cell lookup
        osteoblast_info = OM.lookup_cell("osteoblast")
        @test osteoblast_info !== nothing
        @test osteoblast_info.ontology_id == "CL:0000062"

        # Test material lookup
        ha_info = OM.lookup_material("hydroxyapatite")
        @test ha_info !== nothing
    end

    @testset "Cross-Ontology Relations" begin
        COR = DarwinScaffoldStudio.Ontology.CrossOntologyRelations

        # Test tissue-cell relations
        @test haskey(COR.TISSUE_CELL_RELATIONS, "UBERON:0002481")  # bone
        bone_cells = COR.TISSUE_CELL_RELATIONS["UBERON:0002481"]
        @test "CL:0000062" in bone_cells  # osteoblast

        # Test material-tissue compatibility
        @test haskey(COR.MATERIAL_TISSUE_COMPATIBILITY, "CHEBI:ite")  # hydroxyapatite group
    end
end

println("✅ Ontology tests passed!")
