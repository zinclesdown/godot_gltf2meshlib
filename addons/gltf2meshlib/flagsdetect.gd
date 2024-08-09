extends Resource

## Abilities to detect "Flags" from filename or sth else.
## Currently only 2 types of flag are supported.


# FlagsInfo object, parse flags from name when initialized.
class FlagsInfo:
	var DO_NOT_IMPORT := false
	var IMPORT_AS_COLLISION := false

	# I hate those ugly strings
	const FLAGS = {
		"--noimp": "DO_NOT_IMPORT",
		"--collision": "IMPORT_AS_COLLISION",
		"-col": "IMPORT_AS_COLLISION",
	}

	func _init(name: String) -> void:
		for flag in FLAGS.keys():
			if name.find(flag) != -1:
				self[FLAGS[flag]] = true

	func _to_string() -> String:
		return (
			"DO_NOT_IMPORT: "
			+ str(self.DO_NOT_IMPORT)
			+ ", IMPORT_AS_COLLISION: "
			+ str(self.IMPORT_AS_COLLISION)
		)


## a file should be imported or not
static func do_not_import(name: String) -> bool:
	return FlagsInfo.new(name).DO_NOT_IMPORT == true


## a file should be imported as collision or not
static func import_as_collision(name: String) -> bool:
	return FlagsInfo.new(name).IMPORT_AS_COLLISION == true
