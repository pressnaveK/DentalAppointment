load("@build_bazel_rules_nodejs//:index.bzl", "nodejs_binary", "npm_package_bin")
load("@io_bazel_rules_docker//nodejs:image.bzl", "nodejs_image")
load("@io_bazel_rules_docker//container:container.bzl", "container_push")

# TypeScript compilation
npm_package_bin(
    name = "compile",
    tool = "@user_service_npm//@nestjs/cli:bin",
    args = ["build"],
    data = [
        "package.json",
        "tsconfig.json",
        "tsconfig.build.json",
        "nest-cli.json",
    ] + glob([
        "src/**/*.ts",
        "test/**/*.ts",
    ]),
    output_dir = True,
)

# Node.js binary
nodejs_binary(
    name = "user_service",
    data = [
        ":compile",
        "@user_service_npm//:node_modules",
    ],
    entry_point = "dist/main.js",
    visibility = ["//visibility:public"],
)

# Docker image for user service
nodejs_image(
    name = "user_service_image",
    data = [
        ":compile",
        "@user_service_npm//:node_modules",
    ],
    entry_point = "dist/main.js",
    base = "@nodejs18_alpine//image",
)

# Linting
npm_package_bin(
    name = "lint",
    tool = "@user_service_npm//eslint:bin",
    args = [
        "--ext", ".ts",
        "--fix",
        "src",
        "test",
    ],
    data = [
        "eslint.config.mjs",
        "@user_service_npm//:node_modules",
    ] + glob([
        "src/**/*.ts",
        "test/**/*.ts",
    ]),
)

# Testing
npm_package_bin(
    name = "test",
    tool = "@user_service_npm//jest:bin",
    data = [
        "package.json",
        "@user_service_npm//:node_modules",
    ] + glob([
        "src/**/*.ts",
        "test/**/*.ts",
    ]),
)

# Container push rule (optional - for registry push)
container_push(
    name = "push_user_service",
    image = ":user_service_image",
    registry = "your-registry.com",
    repository = "chat-appointment/user-service",
    tag = "latest",
)