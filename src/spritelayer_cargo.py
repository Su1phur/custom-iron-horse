from spritelayer_cargos import registered_spritelayer_cargos

# this is simply manually maintained, and is to prevent nml warnings about unused switches
suppression_list = [("cargo_sprinter", 16), ("cargo_sprinter", 24)]


class CargoBase(object):
    """ Base class for (spritelayer) cargos """

    # sets of cargo sprites of specific length and appearance
    # each set corresponds to a spritesheet which will be generated by the graphics processor
    # each set is used for a specific group of cargo labels or classes
    # each set may have one or more spriterows
    # spriterows are chosen randomly when vehicles load new cargo
    # rows are composed by the graphics processor, and may include variations for
    # - combinations of cargo lengths
    # - combinations of cargo types
    # - cargo colours
    def __init__(self, **kwargs):
        self.platform_type = kwargs.get("platform_type", None)
        self.subtype = kwargs.get("subtype", None)
        self.label = kwargs.get("label", None)
        # set all_platform_types_with_floor_heights per subclass
        self.all_platform_types_with_floor_heights = {}
        # configure gestalt_graphics in the subclass
        self.gestalt_graphics = None

    @property
    def all_platform_types(self):
        return self.all_platform_types_with_floor_heights.keys()

    @property
    def floor_height_for_platform_type(self):
        # crude resolution of floor height for each platform type
        return self.all_platform_types_with_floor_heights[self.platform_type]

    @property
    def id(self):
        return (
            self.base_id
            + "_"
            + self.platform_type
            + "_"
            + self.subtype
            + "_"
            + self.label
            + "_"
            + str(self.length)
            + "px"
        )

    @property
    def cargos_by_platform_type_and_length(self):
        # structure optimised for rendering into nml switch stack
        # just walking over all the cargos into a flat set of spritesets triggers the nfo / nml 255 limit for switch results, so the switches are interleaved in a specific way to avoid that
        result = {}
        for platform_type in self.all_platform_types:
            result[platform_type] = {}
            platform_lengths = [16, 24, 32]
            for platform_length in platform_lengths:
                if (platform_type, platform_length) not in suppression_list:
                    result[platform_type][
                        platform_length
                    ] = get_cargos_matching_platform_type_and_length(
                        platform_type, platform_length
                    )
        return result

    def cargo_has_random_variants_for_subtype_and_label(
        self, platform_type, platform_length, subtype, label
    ):
        # !! this is a shim to a module method for legacy reasons, needs refactored to a class method
        return cargo_has_random_variants_for_subtype_and_label(
            platform_type, platform_length, subtype, label
        )

    def get_next_cargo_switch(self, platform_type, platform_length, subtype, label):
        # this is stupid, exists solely to optimise out random switches with only 1 item, which nml could do for us, but I dislike seeing the nml warnings
        # seriously TMWFTLB
        if self.cargo_has_random_variants_for_subtype_and_label(
            platform_type, platform_length, subtype, label
        ):
            return (
                "switch_spritelayer_cargos_"
                + self.base_id
                + "_random_"
                + platform_type
                + "_"
                + str(platform_length)
                + "px_"
                + subtype
                + "_"
                + label
            )
        else:
            return (
                "switch_spritelayer_cargos_"
                + self.base_id
                + "_"
                + platform_type
                + "_"
                + str(platform_length)
                + "px_"
                + subtype
                + "_"
                + label
                + "_0"
            )


# module root method, because $reasons (some of the calls are in template where a CargoBase object isn't in scope, so it can't be a class method as it looks like it should be)
def cargo_has_random_variants_for_subtype_and_label(platform_type, platform_length, subtype, label):
    result = False
    for cargo in get_cargos_matching_platform_type_and_length(
        platform_type, platform_length
    ):
        if (cargo.subtype == subtype) and (cargo.label == label):
            if len(cargo.variants) > 1:
                result = True
    return result


def get_cargos_matching_platform_type_and_length(platform_type, platform_length):
    result = []
    for cargo in registered_spritelayer_cargos:
        if (cargo.platform_type == platform_type) and (cargo.length == platform_length):
            result.append(cargo)
    return result


def register_cargo(cargo_subtype_to_subclass_mapping, subtype, container_type_with_cargo_label):
    for cargo_type in cargo_subtype_to_subclass_mapping[subtype]:
        for platform_type in cargo_type.compatible_platform_types:
            cargo = cargo_type(
                platform_type=platform_type,
                subtype=container_type_with_cargo_label[0:-5],
                label=container_type_with_cargo_label[-4:]
            )
            # suppression of unused cargos to prevent nml warnings further down the chain
            if (platform_type, cargo.length) not in suppression_list:
                registered_spritelayer_cargos.append(cargo)
