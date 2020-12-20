find_program(DEPOT_TOOLS_GCLIENT NAMES gclient gclient.bat)

include(FindPackageHandleStandardArgs)

find_package_handle_standard_args(
	DepotTools
	REQUIRED_VARS DEPOT_TOOLS_GCLIENT
	FAIL_MESSAGE "Could not find gclient executable"
)


