cmake_minimum_required(VERSION 2.8.11)
project(recodex-broker-lb-simulator)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++14 -Wall")

include_directories(AFTER, broker/vendor/spdlog/include)
include_directories(AFTER, broker/vendor/cppzmq)

set(SOURCE_FILES
        simulator.cpp

        broker/src/worker_registry.cpp
        broker/src/worker_registry.h
        broker/src/config/broker_config.cpp
        broker/src/config/broker_config.h
        broker/src/config/log_config.h
        broker/src/config/notifier_config.h
        broker/src/reactor/command_holder.h
        broker/src/reactor/command_holder.cpp
        broker/src/helpers/string_to_hex.h
        broker/src/helpers/string_to_hex.cpp
        broker/src/helpers/curl.h
        broker/src/helpers/curl.cpp
        broker/src/helpers/logger.h
        broker/src/helpers/logger.cpp
        broker/src/worker.h
        broker/src/worker.cpp
        broker/src/reactor/message_container.h
        broker/src/reactor/message_container.cpp
        broker/src/handlers/broker_handler.h
        broker/src/handlers/broker_handler.cpp
        broker/src/queuing/queue_manager_interface.h
        broker/src/queuing/multi_queue_manager.cpp
        broker/src/queuing/multi_queue_manager.h
        broker/src/notifier/status_notifier.h
        broker/src/notifier/reactor_status_notifier.cpp
        broker/src/notifier/reactor_status_notifier.h
        broker/src/broker_connect.cpp
        broker/src/handlers/status_notifier_handler.h
        broker/src/handlers/status_notifier_handler.cpp
        broker/src/reactor/reactor.h
        broker/src/reactor/reactor.cpp
        broker/src/reactor/socket_wrapper_base.cpp
        broker/src/reactor/socket_wrapper_base.h
        broker/src/reactor/message_container.h
        broker/src/reactor/message_container.cpp
        broker/src/reactor/handler_interface.h
        broker/src/reactor/router_socket_wrapper.h
        broker/src/reactor/router_socket_wrapper.cpp
        )

add_executable(lb-simulator ${SOURCE_FILES})
target_link_libraries(lb-simulator yaml-cpp)
target_link_libraries(lb-simulator -lboost_system)
target_link_libraries(lb-simulator -lboost_filesystem)
target_link_libraries(lb-simulator -lpthread)
target_link_libraries(lb-simulator -lzmq)
target_link_libraries(lb-simulator -lcurl)
