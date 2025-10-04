load("@rules_python//python:defs.bzl", "py_binary", "py_library")
load("@io_bazel_rules_docker//python:image.bzl", "py_image")
load("@io_bazel_rules_docker//container:container.bzl", "container_push")
load("@bot_service_deps//:requirements.bzl", "requirement")

py_library(
    name = "bot_service_lib",
    srcs = glob(["*.py"], exclude = ["main.py"]),
    deps = [
        requirement("fastapi"),
        requirement("uvicorn"),
        requirement("langchain"),
        requirement("pydantic"),
        requirement("sqlalchemy"),
    ],
    visibility = ["//visibility:public"],
)

py_binary(
    name = "bot_service",
    srcs = ["main.py"],
    deps = [
        ":bot_service_lib",
        requirement("fastapi"),
        requirement("uvicorn"),
        requirement("langchain"),
        requirement("pydantic"),
        requirement("sqlalchemy"),
    ],
    main = "main.py",
)

# Docker image for bot service
py_image(
    name = "bot_service_image",
    srcs = ["main.py"],
    deps = [
        ":bot_service_lib",
        requirement("fastapi"),
        requirement("uvicorn"),
        requirement("langchain"),
        requirement("pydantic"),
        requirement("sqlalchemy"),
    ],
    main = "main.py",
    base = "@python3_11_distroless//image",
)

# Container push rule (optional - for registry push)
container_push(
    name = "push_bot_service",
    image = ":bot_service_image",
    registry = "your-registry.com",
    repository = "chat-appointment/bot-service",
    tag = "latest",
)