### Installation step

if (NOT CMAKE_INSTALL_LIB_DIR)
	set(CMAKE_INSTALL_LIB_DIR lib)
endif()

if (NOT CMAKE_INSTALL_INCLUDE_DIR)
	set(CMAKE_INSTALL_INCLUDE_DIR include)
endif()

if (NOT CMAKE_INSTALL_ARCHIVE_DIR)
	set(CMAKE_INSTALL_ARCHIVE_DIR lib)
endif()

if (NOT CMAKE_INSTALL_BIN_DIR)
	set(CMAKE_INSTALL_BIN_DIR bin)
endif()

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

set(WEBRTC_BUILD_ROOT ${CMAKE_BINARY_DIR}/src/out/${CMAKE_BUILD_TYPE})


# Installing library files

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
	#${WEBRTC_BUILD_ROOT}/obj/api/audio_codecs/builtin_audio_decoder_factory/builtin_audio_decoder_factory.o
)

list(LENGTH OBJ_EXCLUDES OBJ_EXCLUDES_LEN)

if (${OBJ_EXCLUDES_LEN} GREATER "0")
	list(REMOVE_ITEM OBJ_FILES ${OBJ_EXCLUDES})
endif()

set(OBJECT_FILES "")

foreach(ofile ${OBJ_FILES})
	string(FIND ${ofile} "test" IS_TEST)
	if (${IS_TEST} EQUAL -1)
		# the object file is not a test
		set(OBJECT_FILES ${OBJECT_FILES} ${ofile})
	endif()
endforeach()

set_source_files_properties(${OBJECT_FILES}
	PROPERTIES
	EXTERNAL_OBJECT true
	GENERATED true
)

# Create the library with these object files
add_library(webrtc STATIC ${OBJECT_FILES})
add_dependencies(webrtc webrtc_build)

set_target_properties(
	webrtc PROPERTIES
	LINKER_LANGUAGE C
)

# Modify the extension based on OS
#set(WEBRTC_LIB_EXT "a")

#if (WIN32)
#	set(WEBRTC_LIB_EXT "lib")
#endif()

#file(GLOB_RECURSE
#	WEBRTC_LIBS
#	${WEBRTC_BUILD_ROOT}/*.${WEBRTC_LIB_EXT}
#)
#set(WEBRTC_LIBRARIES "")
#
#foreach(lib ${WEBRTC_LIBS})
#	string(FIND ${lib} "test" IS_TEST)
#	if (${IS_TEST} EQUAL -1)
#		# Get the name of the library without directory or extension
#		get_filename_component(lib_name ${lib} NAME_WE)
#		
#		# remove the "lib" from libxxx 
#		string(REPLACE "lib" "" lib_target_name ${lib_name})
#		
#		# Add it for later configuration file
#		set(WEBRTC_LIBRARIES ${WEBRTC_LIBRARIES} ${lib_target_name})
#	endif()
#	
#	# Actually install the library 
#	install(
#		FILES ${lib}
#		DESTINATION ${CMAKE_INSTALL_LIB_DIR}
#		COMPONENT Libraries
#	)
#
#endforeach()

#message(STATUS "${WEBRTC_LIBRARIES}")

#install(
#	FILES ${WEBRTC_LIBRARY}
#	DESTINATION ${CMAKE_INSTALL_LIB_DIR}
#	COMPONENT Libraries
#)
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
		DESTINATION ${CMAKE_INSTALL_INCLUDE_DIR}/${RELATIVE_PATH}
		COMPONENT Headers
	)
endforeach()

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
	INSTALL_DESTINATION ${CMAKE_INSTALL_LIB_DIR}/cmake/webrtc
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
	DESTINATION ${CMAKE_INSTALL_LIB_DIR}/cmake/webrtc
)

export(PACKAGE ${PROJECT_NAME})
