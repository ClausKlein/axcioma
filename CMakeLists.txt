# IMPORTANT:
# CMake should be called via ".../brix11 execute cmake", as then all the brix11
# generated environment variables will be set automatically.

cmake_minimum_required(VERSION 3.25...4.1)
#
# see https://cmake.org/cmake/help/latest/index.html for introduction
#
# cmake -B ../build -G Ninja -S .
# DESTDIR=../installdir cmake --install ../build --prefix /
#
option(CMAKE_EXPORT_COMPILE_COMMANDS "for clang-tidy" ON)

project(
  itaox11
  VERSION 2.6.0.1
  LANGUAGES CXX
)

# ================================
# add dependencies
# ================================
include(cmake/GlobalSettings.cmake)

include(GenerateTaoIdl)
include(GNUInstallDirs)

add_library(itaox11 INTERFACE)

set(TAOX11_INCLUDE_DIRS $ENV{TAOX11_ROOT} $ENV{TAOX11_ROOT}/orbsvcs #
                        $ENV{ACE_ROOT} $ENV{TAO_ROOT} $ENV{TAO_ROOT}/orbsvcs
)
foreach(dir_ ${TAOX11_INCLUDE_DIRS})
  cmake_path(GET dir_ FILENAME filename)
  if("${filename}" STREQUAL "taox11")
    message(TRACE "install dir ${dir_}/tao/x11")
    install(
      DIRECTORY ${dir_}/tao/x11 # NOTE: without attached /
      DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/tao
      FILES_MATCHING
      PATTERN "*.h"
      PATTERN "*.cpp" # NOTE: we need tao/x11/logger/logstream_t.cpp
    )
  elseif("${filename}" STREQUAL "orbsvcs")
    message(TRACE "install dir ${dir_}/orbsvcs")
    install(
      DIRECTORY ${dir_}/orbsvcs # NOTE: without attached /
      DESTINATION ${CMAKE_INSTALL_INCLUDEDIR} # or TYPE INCLUDE
      FILES_MATCHING
      PATTERN "*.h"
    )
  else()
    set(INCLUDE_DIR $<LOWER_CASE:${filename}>)
    message(TRACE "install dir ${dir_}/${INCLUDE_DIR}/")
    install(
      DIRECTORY ${dir_}/${INCLUDE_DIR} # NOTE: without attached /
      DESTINATION ${CMAKE_INSTALL_INCLUDEDIR} # or TYPE INCLUDE
      FILES_MATCHING
      PATTERN "*.shobj" EXCLUDE
      PATTERN "*.h"
      PATTERN "*.inl"
      PATTERN "*.pidl"
      PATTERN "*.cpp"
    )
  endif()
endforeach()
list(TRANSFORM TAOX11_INCLUDE_DIRS PREPEND "$<BUILD_INTERFACE:")
list(TRANSFORM TAOX11_INCLUDE_DIRS APPEND ">")
message(TRACE "${TAOX11_INCLUDE_DIRS}")

# use original headers:
target_include_directories(
  itaox11 SYSTEM INTERFACE ${TAOX11_INCLUDE_DIRS} $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
)

# the installed stagedir/include subdirs:
# include/ace
# include/tao/x11
# include/orbsvcs
# include/MgmtLocalAPI

# see $HOME/Workspace/cpp/axcioma/stagedir/lib
set(TAOX11_LIBRARIES
    ACE
    TAO
    TAO_AnyTypeCode
    TAO_Catior_i
    TAO_CodecFactory
    TAO_Compression
    TAO_CosNaming
    TAO_CosNaming_Serv
    TAO_CosNaming_Skel
    TAO_IDL_BE
    TAO_IDL_FE
    TAO_IORManip
    TAO_IORTable
    TAO_ImR_Client
    TAO_Messaging
    TAO_PI
    TAO_PortableServer
    TAO_RTCORBA
    TAO_Svc_Utils
    TAO_Valuetype
    TAO_ZIOP
    taox11
    taox11_anytypecode
    taox11_bidir_giop
    taox11_codecfactory
    taox11_cosnaming_skel
    taox11_cosnaming_stub
    taox11_dynamicany
    taox11_ifr_client_skel
    taox11_ifr_client_stub
    taox11_ior_interceptor
    taox11_ior_table
    taox11_messaging
    taox11_ort
    taox11_pi
    taox11_pi_server
    taox11_portable_server
    taox11_typecodefactory
    taox11_valuetype
    x11_logger
)

target_link_libraries(itaox11 INTERFACE ${TAOX11_LIBRARIES})
# use original libs:
target_link_directories(
  itaox11 INTERFACE $<BUILD_INTERFACE:$ENV{X11_BASE_ROOT}/stagedir/lib>
  $<INSTALL_INTERFACE:${CMAKE_INSTALL_LIBDIR}>
)
target_compile_features(itaox11 INTERFACE cxx_std_17)

message(TRACE "X11_BASE_ROOT=$ENV{X11_BASE_ROOT}")
foreach(lib_ ${TAOX11_LIBRARIES})
  find_library(
    ${lib_}_LIBRARY
    NAMES ${lib_} ${lib_}s ${lib_}d ${lib_}sd
    # XXX NO_DEFAULT_PATH
    PATHS $ENV{ACE_ROOT}/lib $ENV{X11_BASE_ROOT}/lib $ENV{X11_BASE_ROOT}/stagedir/lib # XXX REQUIRED
  )
  if(${lib_}_FOUND)
    message(STATUS "Found lib ${${lib_}_LIBRARY}")
    list(APPEND FOUND_TAOX11_LIBRARIES ${${lib_}_LIBRARY})
    # NOTE: this installs only symlinks witch are not usable! XXX  install(FILES ${${lib_}_LIBRARY} TYPE LIB)
    get_filename_component(REAL_SRC "${${lib_}_LIBRARY}" REALPATH)
    # instead file(COPY "${REAL_SRC}" DESTINATION "$ENV{STAGE_DIR}/lib/${${lib_}_LIBRARY}")
    install(FILES ${REAL_SRC} TYPE LIB)
  else()
    message(WARNING "${${lib_}_LIBRARY}")
  endif()
endforeach()

# TODO(CK): append postfix 's' for static and 'd' for debug!
target_link_libraries(itaox11 INTERFACE ${TAOX11_LIBRARIES})
# use original libs:
target_link_directories(
  itaox11 INTERFACE $<BUILD_INTERFACE:$ENV{ACE_ROOT}/lib> $<BUILD_INTERFACE:$ENV{X11_BASE_ROOT}/lib>
  $<BUILD_INTERFACE:$ENV{X11_BASE_ROOT}/stagedir/lib> $<INSTALL_INTERFACE:${CMAKE_INSTALL_LIBDIR}>
)

# NOTE: install all libs, more than yet used, but with symlinks to dll's! CK
if(UNIX)
  install(DIRECTORY $ENV{X11_BASE_ROOT}/stagedir/lib/ TYPE LIB)
else()
  install(DIRECTORY $ENV{ACE_ROOT}/lib/ TYPE LIB)
  install(DIRECTORY $ENV{X11_BASE_ROOT}/lib/ TYPE LIB)
endif()

# NOTE: With attached / means contents (*.so *.lib *.a pkgconfig)! CK
install(DIRECTORY $ENV{RIDL_ROOT}/ DESTINATION ${CMAKE_INSTALL_LIBDIR})

# NOTE: needed for run_test.pl
install(
  DIRECTORY $ENV{ACE_ROOT}/bin/PerlACE
  DESTINATION ${CMAKE_INSTALL_DATADIR}/perl5
)

# NOTE: needed for ridlc
install(
  DIRECTORY $ENV{TAOX11_ROOT}/ridlbe
  DESTINATION ${CMAKE_INSTALL_DATADIR}/taox11
)
install(
  FILES $ENV{TAOX11_ROOT}/tao/x11/base/versionx11.h
  DESTINATION ${CMAKE_INSTALL_DATADIR}/taox11/tao/x11/base
)

# stagedir/lib
# ├── ridl
# └── x86_64-linux-gnu
#     ├── cmake
#     │   ├── idl2cpp
#     │   └── itaox11
#     ├── idl2cpp
#     └── pkgconfig

install(
  DIRECTORY $ENV{X11_BASE_ROOT}/bin/
  TYPE BIN
  USE_SOURCE_PERMISSIONS
)
if(UNIX)
  install(
    DIRECTORY $ENV{X11_BASE_ROOT}/stagedir/bin/
    TYPE BIN
    USE_SOURCE_PERMISSIONS
  )
else()
  install(
    DIRECTORY $ENV{ACE_ROOT}/bin/
    TYPE BIN
    USE_SOURCE_PERMISSIONS
  )
endif()

# stagedir/bin
# ├── ace_gperf
# ├── brix11
# ├── brix11.bat
# ├── fuzzers
# ├── ridlc
# ├── ridlc.bat
# ├── tao_catior
# ├── tao_cosnaming
# └── tao_idl

if(APPLE) # "think different", indeed! CK
  # see
  # https://opensource.apple.com/source/clang/clang-703.0.31/src/tools/clang/docs/MSVCCompatibility.rst.auto.html
  target_compile_options(itaox11 INTERFACE -Wdeprecated-declarations)
  target_compile_definitions(itaox11 INTERFACE ACE_HAS_IPV6 ACE_HAS_VERSIONED_NAMESPACE=1 ACE_HAS_CUSTOM_EXPORT_MACROS=0)
  target_compile_definitions(itaox11 INTERFACE __ACE_INLINE__)
elseif(UNIX)
  # see https://clang.llvm.org/docs/ClangCommandLineReference.html
  if(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    # Parse templated function definitions at the end of the translation unit
    target_compile_options(itaox11 INTERFACE -fdelayed-template-parsing)
    target_compile_definitions(itaox11 INTERFACE ACE_HAS_CUSTOM_EXPORT_MACROS=0)
  else()
    target_compile_definitions(itaox11 INTERFACE ACE_HAS_VERSIONED_NAMESPACE=1)
  endif()
  target_compile_definitions(itaox11 INTERFACE _GNU_SOURCE)
  # Give inline C++ member functions hidden visibility by default
  target_compile_options(itaox11 INTERFACE -fvisibility=hidden -fvisibility-inlines-hidden -fno-strict-aliasing)
  target_compile_options(itaox11 INTERFACE -Wdeprecated-declarations)
  target_compile_definitions(itaox11 INTERFACE __ACE_INLINE__)
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
  target_compile_options(itaox11 INTERFACE /bigobj)
  target_compile_definitions(
    itaox11 INTERFACE _CONSOLE _CRT_NONSTDC_NO_WARNINGS _CRT_SECURE_NO_WARNINGS _CRT_SECURE_NO_DEPRECATE
                      _CRT_NONSTDC_NO_DEPRECATE _WINSOCK_DEPRECATED_NO_WARNINGS #NO! CK ACE_AS_STATIC_LIBS
  )
  target_compile_options(
    itaox11
    INTERFACE /JMC
              /GR
              /GS
              /Gd
              /fp:precise
              /Zc:inline
              /Zc:wchar_t
              /Zc:forScope
              /ZI
              /Gm-
              /nologo
              /Ob1
  )
  target_link_options(itaox11 INTERFACE /FORCE:MULTIPLE)
endif()

# NOTE: With attached / means contents, but install *.cmake only! CK
install(
  DIRECTORY cmake/
  DESTINATION ${CMAKE_INSTALL_DATADIR}/cmake/modules
  FILES_MATCHING
  PATTERN "*.cmake"
)

#
# gersemi: off
#
CPMAddPackage("gh:TheLartians/PackageProject.cmake@1.13.0")

packageProject(
  NAME itaox11
  VERSION ${PROJECT_VERSION} NAMESPACE Axcioma
  BINARY_DIR ${PROJECT_BINARY_DIR}
  INCLUDE_DIR include
  INCLUDE_DESTINATION ${CMAKE_INSTALL_INCLUDEDIR} INCLUDE_HEADER_PATTERN "*.h"
  COMPATIBILITY SameMajorVersion DISABLE_VERSION_SUFFIX YES
)

enable_testing()

if(NOT MSVC AND NOT APPLE)
  # NOTE: EXCLUDE_FROM_ALL must be OFF or targets will NOT be installed! CK
  CPMAddPackage(
    NAME Callback_Quoter
    GITHUB_REPOSITORY "ClausKlein/Callback_Quoter"
    GIT_TAG 6e4b1f50e70a2ee8e224bf1b176a915053f8e8d6
    EXCLUDE_FROM_ALL OFF
    OPTIONS "CMAKE_UNITY_BUILD NO"
  )
endif()
#
# gersemi: on
#

set(CPACK_GENERATOR "TGZ")
include(CPack)
