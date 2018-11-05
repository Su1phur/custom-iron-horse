from train import MailEngineMetroConsist, MetroUnit

consist = MailEngineMetroConsist(id='tideway',
                                 base_numeric_id=2200,
                                 name='Tideway',
                                 role='mail_metro',
                                 power=1100,
                                 gen=3,
                                 sprites_complete=True)

consist.add_unit(type=MetroUnit,
                 weight=30,
                 vehicle_length=8,
                 # set capacity for freight; mail will be automatically calculated
                 capacity=30,
                 chassis='railcar',
                 repeat=2)
