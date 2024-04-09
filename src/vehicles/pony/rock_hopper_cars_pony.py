from train import HopperCarRockConsist, FreightCar


def main(roster_id, **kwargs):
    # --------------- standard gauge ---------------------------------------------------------------

    consist = HopperCarRockConsist(
        roster_id=roster_id,
        roster_id_providing_module=kwargs["roster_id_providing_module"],
        base_numeric_id=24100,
        gen=4,
        subtype="B",
        intro_year_offset=7,  # let's be a little bit later for this one
        sprites_complete=True,
    )

    consist.add_unit(type=FreightCar, chassis="4_axle_sparse_24px")

    consist = HopperCarRockConsist(
        roster_id=roster_id,
        roster_id_providing_module=kwargs["roster_id_providing_module"],
        base_numeric_id=24120,
        gen=4,
        subtype="C",
        intro_year_offset=7,  # let's be a little bit later for this one
        sprites_complete=True,
    )

    consist.add_unit(type=FreightCar, chassis="4_axle_sparse_32px")

    consist = HopperCarRockConsist(
        roster_id=roster_id,
        roster_id_providing_module=kwargs["roster_id_providing_module"],
        base_numeric_id=24140,
        gen=5,
        subtype="B",
        sprites_complete=True,
    )

    consist.add_unit(type=FreightCar, chassis="4_axle_sparse_24px")

    consist = HopperCarRockConsist(
        roster_id=roster_id,
        roster_id_providing_module=kwargs["roster_id_providing_module"],
        base_numeric_id=24160,
        gen=5,
        subtype="C",
        sprites_complete=True,
    )

    consist.add_unit(type=FreightCar, chassis="4_axle_sparse_32px")
