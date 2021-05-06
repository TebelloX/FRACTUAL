cmake_minimum_required(VERSION 3.0.0)
project(engine VERSION 0.1.0)

include(CTest)
enable_testing()

# add SFML libraries
# set(SFML_STATIC_LIBRARIES TRUE)
set(SFML_DIR "Y:/SFML-2.5.1/lib/cmake/SFML")
find_package(SFML COMPONENTS system window graphics main audio REQUIRED)

add_executable(engine engine.cpp app.o)

include_directories(${PROJECT_SOURCE_DIR}/include)

target_link_libraries(engine sfml-system sfml-window sfml-graphics sfml-main sfml-audio)

set(CPACK_PROJECT_NAME ${PROJECT_NAME})
set(CPACK_PROJECT_VERSION ${PROJECT_VERSION})
include(CPack)