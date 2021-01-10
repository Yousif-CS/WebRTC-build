cmake_minimum_required(VERSION 3.11)

project(WebRTC)

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
		--args='${BUILD_TYPE} ${GN_ARGS} use_rtti=true rtc_include_tests=false rtc_enable_protobuf=false use_custom_libcxx=false use_custom_libcxx_for_host=false rtc_include_pulse_audio=false use_x11=false is_component_build=false enable_dsyms=true')

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

#Installing the library and exporting it
# add_library(${PROJECT_NAME} STATIC IMPORTED GLOBAL)
# add_dependencies(${PROJECT_NAME} webrtc_build)
# set_target_properties(
# 	${PROJECT_NAME}
# 	PROPERTIES
# 	IMPORTED_LOCATION ${WEBRTC_LIBS}
# 	INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_BINARY_DIR}/src
# )

#install(
#	FILES ${WEBRTC_LIBS}
#	DESTINATION lib	
#)

#install(DIRECTORY ${CMAKE_BINARY_DIR}/src
#		DESTINATION include)
