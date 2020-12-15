cmake_minimum_required(VERSION 3.11)

project(WebRTC)

set(CMAKE_MODULE_PATH
	${CMAKE_MODULE_PATH}
	${CMAKE_CURRENT_SOURCE_DIR}/cmake)


find_package(DepotTools REQUIRED)
find_package(Git REQUIRED)

# Configuration steps

set(gclient_config
		${DEPOT_TOOLS_GCLIENT} config --name webrtc 
		https://chromium.googlesource.com/external/webrtc.git
)

if(WIN32)
	set(gclient_config cmd /c ${gclient_config})
endif()


add_custom_command(
		OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/.gclient		
	COMMAND ${gclient_config}
)

add_custom_target(
	webrtc_configuration ALL
	DEPENDS	${CMAKE_CURRENT_BINARY_DIR}/.gclient
)

set(gclient_sync ${DEPOT_TOOLS_GCLIENT} 
	sync -n -D
)

if (WIN32)
	set(gclient_sync cmd /c ${gclient_sync})
endif()

add_custom_command(
	OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/all.gyp
	COMMAND ${gclient_sync}
)

add_custom_target(
	webrtc_synchronization ALL
	DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/all.gyp
)

add_dependencies(webrtc_synchronization webrtc_configuration)

if(DEFINED ENV{GYP_DEFINES})
	message("WARNING 'GYP_DEFINES' is already set to ENV{GYP_DEFINES}")
else()
	if(APPLE)
		set(ENV{GYP_DEFINES} "target_arch=x64")
	else()
		set(ENV{GYP_DEFINES} "target_arch=ia32")
	endif()
endif()

set(gclient_runhooks ${DEPOT_TOOLS_GCLIENT} runhooks)

if (WIN32)
	set(gclient_runhooks cmd /c ${gclient_runhooks})
endif()

add_custom_command(
	OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/out
	COMMAND ${gclient_runhooks}
)

add_custom_target(
	webrtc_runhooks ALL
	DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/out
)

add_dependencies(webrtc_runhooks webrtc_synchronization)


if (NOT CMAKE_BUILD_TYPE)
	set(CMAKE_BUILD_TYPE Debug)
endif()

set(webrtc_gen cd webrtc && gn gen ${GN_ARGS} ${CMAKE_CURRENT_BINARY_DIR}/out/${CMAKE_BUILD_TYPE})

add_custom_command(
		OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/out/${CMAKE_BUILD_TYPE}/all.ninja
		COMMAND ${webrtc_gen}
)

add_custom_target(
	webrtc_gen ALL
	DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/out/${CMAKE_BUILD_TYPE}/all.ninja
)

add_dependencies(webrtc_gen webrtc_runhooks)

set(webrtc_build ninja -v -C ${CMAKE_CURRENT_BINARY_DIR}/out/${CMAKE_BUILD_TYPE})

add_custom_command(
		OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/out/${CMAKE_BUILD_TYPE}/libwebrtc.a
		COMMAND ${webrtc_build}
)

set(WEBRTC_LIBS ${CMAKE_CURRENT_BINARY_DIR}/out/${CMAKE_BUILD_TYPE}/obj/libwebrtc.a)
set(WEBRTC_INCLUDE_DIR ${CMAKE_CURRENT_BINARY_DIR}/webrtc)

add_custom_target(
	webrtc_build ALL
	DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/out/${CMAKE_BUILD_TYPE}/libwebrtc.a
)

add_dependencies(webrtc_build webrtc_gen)

#Installing the library and exporting it
# add_library(${PROJECT_NAME} STATIC IMPORTED GLOBAL)
# add_dependencies(${PROJECT_NAME} webrtc_build)
# set_target_properties(
# 	${PROJECT_NAME}
# 	PROPERTIES
# 	IMPORTED_LOCATION ${WEBRTC_LIBS}
# 	INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_CURRENT_BINARY_DIR}/src
# )

install(
	FILES ${WEBRTC_LIBS}
	DESTINATION lib	
)

install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/webrtc
		DESTINATION include)
