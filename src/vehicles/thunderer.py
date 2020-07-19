from train import EngineConsist, SteamEngineUnit, SteamEngineTenderUnit


def main(roster_id):
    consist = EngineConsist(roster_id=roster_id,
                            id='thunderer',
                            base_numeric_id=4830,
                            name='2-6-0 Thunderer',
                            role='heavy_express',
                            role_child_branch_num=-1,
                            replacement_consist_id='kelpie', # this Joker ends with Wyvern, long-lived
                            power=1250,
                            tractive_effort_coefficient=0.18,
                            gen=2,
                            fixed_run_cost_points=160, # give a bonus so this can be a genuine mixed-traffic engine
                            intro_date_offset=10, # introduce later than gen epoch by design
                            sprites_complete=False)

    consist.add_unit(type=SteamEngineUnit,
                     weight=62,
                     vehicle_length=5,
                     spriterow_num=0)

    consist.add_unit(type=SteamEngineTenderUnit,
                     weight=30,
                     vehicle_length=3,
                     spriterow_num=1)

    return consist
