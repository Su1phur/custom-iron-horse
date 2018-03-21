from train import EngineConsist, DieselEngineUnit

consist = EngineConsist(id='justicialista',
                        base_numeric_id=250,
                        title='Justicialista',
                        power=5880,  # yes, really, it's high powered
                        speed=85,
                        intro_date=1955)

consist.add_unit(type=DieselEngineUnit,
                 weight=114,
                 vehicle_length=8,
                 spriterow_num=0)

consist.add_unit(type=DieselEngineUnit,
                 weight=114,
                 vehicle_length=8,
                 spriterow_num=1)

