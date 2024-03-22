from train import EngineConsist, MetroUnit


def main(roster_id, **kwargs):
    consist = EngineConsist(
        roster_id=roster_id,
        id="mulberry",
        base_numeric_id=24430,
        name="Mulberry",
        role="metro",
        role_child_branch_num=1,
        power_by_power_source={
            "METRO": 1200,
        },
        random_reverse=True,
        gen=3,
        intro_year_offset=3,  # introduce later than gen epoch by design
        fixed_run_cost_points=120,  # substantial cost bonus for balance against same-era steam engines
        extended_vehicle_life=True,
        # note that livery names are metadata only and can repeat for different spriterows
        additional_liveries=["INDUSTRIAL_YELLOW"],
        sprites_complete=True,
    )

    consist.add_unit(
        type=MetroUnit, weight=48, vehicle_length=8, spriterow_num=0
    )

    consist.description = (
        """."""
    )
    consist.foamer_facts = """Metropolitan Railway electric locos"""

    return consist
