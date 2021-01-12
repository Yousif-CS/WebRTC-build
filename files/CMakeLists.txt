cmake_minimum_required(VERSION 3.11)

project(WebRTC VERSION 0.1.1)

include(CMakePackageConfigHelpers)

set(CMAKE_MODULE_PATH
	${CMAKE_MODULE_PATH}
	${CMAKE_SOURCE_DIR}/cmake)

find_package(DepotTools REQUIRED)
find_package(Git REQUIRED)

# Configuration steps

set(fetch_cmd fetch --no-history --force --nohooks webrtc)

if(WIN32)
	set(fetch_cmd cmd /c ${fetch_cmd})
endif()


add_custom_command(
	OUTPUT ${CMAKE_BINARY_DIR}/.fetch_rslt
	COMMAND ${fetch_cmd}
)

add_custom_target(
	webrtc_fetch ALL
	DEPENDS ${CMAKE_BINARY_DIR}/.fetch_rslt
)

set(webrtc_release_branch cd src && git checkout -B rel-4280 refs/remotes/branch-heads/4280)

if(WIN32)
	set(webrtc_release_branch cmd /c ${webrtc_release_branch})
endif()

add_custom_command(
	OUTPUT ${CMAKE_BINARY_DIR}/rbranch
	COMMAND ${webrtc_release_branch}
)

add_custom_target(
	webrtc_release_branch ALL
	DEPENDS ${CMAKE_BINARY_DIR}/rbranch
)

add_dependencies(webrtc_release_branch webrtc_fetch)

set(webrtc_release_sync cd src && gclient sync -D)

if(WIN32)
	set(webrtc_release_sync cmd /c ${webrtc_release_sync})
endif()

add_custom_command(
	OUTPUT ${CMAKE_BINARY_DIR}/relsync
	COMMAND ${webrtc_release_sync}
)

add_custom_target(
	webrtc_release_sync ALL
	DEPENDS ${CMAKE_BINARY_DIR}/relsync
)

add_dependencies(webrtc_release_sync webrtc_release_branch)

if (NOT CMAKE_BUILD_TYPE)
	set(CMAKE_BUILD_TYPE Debug)
endif()

# debug or release build
set(BUILD_TYPE ${CMAKE_BUILD_TYPE})
if (BUILD_TYPE STREQUAL Release)
	message(STATUS "Generating Release build")
	set(BUILD_TYPE "is_debug=false")
else()
	set(BUILD_TYPE "")
endif()

set(webrtc_gen cd src && gn gen ${CMAKE_BINARY_DIR}/src/out/${CMAKE_BUILD_TYPE} 
		--args='${BUILD_TYPE} ${GN_ARGS} use_rtti=true rtc_include_tests=false rtc_enable_protobuf=false use_custom_libcxx=false use_custom_libcxx_for_host=false rtc_include_pulse_audio=false use_x11=false is_component_build=false enable_dsyms=true rtc_exclude_audio_processing_module=true')

add_custom_command(
		OUTPUT ${CMAKE_BINARY_DIR}/src/out/${CMAKE_BUILD_TYPE}/all
		COMMAND ${webrtc_gen}
)

add_custom_target(
	webrtc_gen ALL
	DEPENDS ${CMAKE_BINARY_DIR}/src/out/${CMAKE_BUILD_TYPE}/all
)

add_dependencies(webrtc_gen webrtc_release_sync)

set(webrtc_build ninja -C ${CMAKE_BINARY_DIR}/src/out/${CMAKE_BUILD_TYPE})

add_custom_command(
		OUTPUT ${CMAKE_BINARY_DIR}/src/out/${CMAKE_BUILD_TYPE}/libwebrtc.a
		COMMAND ${webrtc_build}
)

set(WEBRTC_LIBS ${CMAKE_BINARY_DIR}/src/out/${CMAKE_BUILD_TYPE}/obj/libwebrtc.a)
set(WEBRTC_INCLUDE_DIR ${CMAKE_BINARY_DIR}/src)

add_custom_target(
	webrtc_build ALL
	DEPENDS ${CMAKE_BINARY_DIR}/src/out/${CMAKE_BUILD_TYPE}/libwebrtc.a
)

add_dependencies(webrtc_build webrtc_gen)

### Installation step

# Versioning
set(WEBRTC_MAJOR_VERSION 0)
set(WEBRTC_MINOR_VERSION 1)
set(WEBRTC_BUILD_VERSION 1)

set(WEBRTC_VERSION ${WEBRTC_MAJOR_VERSION}.${WEBRTC_MINOR_VERSION}.${WEBRTC_BUILD_VERSION})
set(WEBRTC_API_VERSION ${WEBRTC_MAJOR_VERSION}.${WEBRTC_MINOR_VERSION})

set(WEBRTC_LIBRARY_PROPERTIES ${WEBRTC_LIBRARY_PROPERTIES} 
	VERSION "${WEBRTC}"
	SOVERSION "${WEBRTC_API_VERSION}"
)

# Installing library files

set(WEBRTC_BUILD_ROOT ${CMAKE_BINARY_DIR}/src/out/${CMAKE_BUILD_TYPE})

# Modify the extension based on OS
set(WEBRTC_LIB_EXT "a")

if (WIN32)
	set(WEBRTC_LIB_EXT "lib")
endif()

file(GLOB_RECURSE
	WEBRTC_LIBS
	${WEBRTC_BUILD_ROOT}/*.${WEBRTC_LIB_EXT}
)
set(WEBRTC_LIBRARIES "")

foreach(lib ${WEBRTC_LIBS})
	string(FIND ${lib} "test" IS_TEST)
	if (${IS_TEST} EQUAL -1)
		# Get the name of the library without directory or extension
		get_filename_component(lib_name ${lib} NAME_WE)
		
		# remove the "lib" from libxxx 
		string(REPLACE "lib" "" lib_target_name ${lib_name})
		
		# Add it for later configuration file
		set(WEBRTC_LIBRARIES ${WEBRTC_LIBRARIES} ${lib_target_name})
	endif()
	
	# Actually install the library 
	install(
		FILES ${lib}
		DESTINATION lib
		COMPONENT Libraries
	)

endforeach()

# Installing header files

file(
	GLOB_RECURSE HEADER_FILES
	RELATIVE ${CMAKE_BINARY_DIR}/src
	FOLLOW_SYMLINKS
	${CMAKE_BINARY_DIR}/src/net/*.h
	${CMAKE_BINARY_DIR}/src/talk/*.h
	${CMAKE_BINARY_DIR}/src/testing/*.h
	${CMAKE_BINARY_DIR}/src/third_party/*.h
	${CMAKE_BINARY_DIR}/src/webrtc/*.h
	${CMAKE_BINARY_DIR}/src/api/*.h
	${CMAKE_BINARY_DIR}/src/rtc_base/*.h
	${CMAKE_BINARY_DIR}/src/modules/*.h
	${CMAKE_BINARY_DIR}/src/pc/*.h
	${CMAKE_BINARY_DIR}/src/system_wrappers/*.h
	${CMAKE_BINARY_DIR}/src/common_video/*.h
	${CMAKE_BINARY_DIR}/src/media/*.h
	${CMAKE_BINARY_DIR}/src/call/*.h
	${CMAKE_BINARY_DIR}/src/p2p/*.h
	${CMAKE_BINARY_DIR}/src/logging/*.h
)

foreach(f ${HEADER_FILES})
	get_filename_component(RELATIVE_PATH ${f} DIRECTORY)
	install(
		FILES ${CMAKE_BINARY_DIR}/src/${f}
		DESTINATION include/${RELATIVE_PATH}
		COMPONENT Headers
	)
endforeach()

# Creating a target to install as a package

# Getting the object files required for the library

set(OBJ_EXT "o")

if (WIN32)
	set(OBJ_EXT "obj")
endif()

file(
	GLOB_RECURSE OBJ_FILES
# 	${WEBRTC_BUILD_ROOT}/obj/testing/*.${OBJ_EXT}
# 	${WEBRTC_BUILD_ROOT}/obj/third_party/*.${OBJ_EXT}
# 	${WEBRTC_BUILD_ROOT}/obj/api/*.${OBJ_EXT}
# 	${WEBRTC_BUILD_ROOT}/obj/rtc_base/*.${OBJ_EXT}
# 	${WEBRTC_BUILD_ROOT}/obj/modules/*.${OBJ_EXT}
# 	${WEBRTC_BUILD_ROOT}/obj/pc/*.${OBJ_EXT}
# 	${WEBRTC_BUILD_ROOT}/obj/system_wrappers/*.${OBJ_EXT}
# 	${WEBRTC_BUILD_ROOT}/obj/common_video/*.${OBJ_EXT}
# 	${WEBRTC_BUILD_ROOT}/obj/common_audio/*.${OBJ_EXT}
# 	${WEBRTC_BUILD_ROOT}/obj/media/*.${OBJ_EXT}
# 	${WEBRTC_BUILD_ROOT}/obj/call/*.${OBJ_EXT}
# 	${WEBRTC_BUILD_ROOT}/obj/p2p/*.${OBJ_EXT}
# 	${WEBRTC_BUILD_ROOT}/obj/logging/*.${OBJ_EXT}
# 	${WEBRTC_BUILD_ROOT}/obj/audio/*.${OBJ_EXT}
	${WEBRTC_BUILD_ROOT}/obj/*.${OBJ_EXT}
)

# Exclude protobuf files because we externally supply them
file(
	GLOB_RECURSE OBJ_EXCLUDES
	${WEBRTC_BUILD_ROOT}/obj/third_party/protobuf/*.${OBJ_EXT}
)

list(LENGTH OBJ_EXCLUDES OBJ_EXCLUDES_LEN)

if (${OBJ_EXCLUDES_LEN} GREATER "0")
	list(REMOVE_ITEM OBJ_FILES ${OBJ_EXCLUDES})
endif()

set_source_files_properties(${OBJ_FILES}
	PROPERTIES
	EXTERNAL_OBJECT true
	GENERATED true
)

set(OBJECT_FILES "")

foreach(ofile ${OBJ_FILES})
	string(FIND ${ofile} "test" IS_TEST)
	if (${IS_TEST} EQUAL -1)
		# the object file is not a test
		set(OBJECT_FILES ${OBJECT_FILES} ${ofile})
	endif()
endforeach()

# Create the library with these object files
add_library(webrtc STATIC ${OBJECT_FILES})

set_target_properties(
	webrtc PROPERTIES
	LINKER_LANGUAGE C
)

install(TARGETS webrtc
	EXPORT WebrtcTargets
 	LIBRARY DESTINATION lib
 	ARCHIVE DESTINATION lib
 	RUNTIME DESTINATION bin
 	INCLUDES DESTINATION include
)
 
install(
 	EXPORT WebrtcTargets
 	FILE WebrtcTargets.cmake
 	NAMESPACE ${PROJECT_NAME}::
 	DESTINATION lib/cmake/webrtc
)
 
configure_package_config_file(
 	${CMAKE_CURRENT_SOURCE_DIR}/Config.cmake.in
 	"${CMAKE_CURRENT_BINARY_DIR}/WebRTCConfig.cmake"
 	INSTALL_DESTINATION lib/cmake/webrtc
)

write_basic_package_version_file(
	${CMAKE_CURRENT_BINARY_DIR}/WebRTCConfigVersion.cmake
	VERSION ${PROJECT_VERSION}
	COMPATIBILITY AnyNewerVersion
)

install(
	FILES
 	"${CMAKE_CURRENT_BINARY_DIR}/WebRTCConfig.cmake"
	"${CMAKE_CURRENT_BINARY_DIR}/WebRTCConfigVersion.cmake"
 	DESTINATION lib/cmake/webrtc
)

export(PACKAGE ${PROJECT_NAME})
