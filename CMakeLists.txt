#
# MACHINE GENERATED FILE. DO NOT EDIT.
#
# CMake build file for four
#
# This file has been generated by lut.Builder 1.2.0
#

cmake_minimum_required(VERSION 2.8)
# --------------------------------------------------------------
#  four
# --------------------------------------------------------------
set(MODULE_NAME four)

# Where to install files
set(INSTALL_PATH "${CMAKE_BINARY_DIR}/lib" CACHE STRING "Install directory path")

# --------------------------------------------------------------
#  module
# --------------------------------------------------------------
add_custom_target(${MODULE_NAME} true)

# --------------------------------------------------------------
#  install                                     
# --------------------------------------------------------------
install(DIRECTORY ${MODULE_NAME}
  DESTINATION ${INSTALL_PATH}
)


