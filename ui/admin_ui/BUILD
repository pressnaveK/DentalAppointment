load("@build_bazel_rules_nodejs//:index.bzl", "nodejs_binary", "npm_package_bin")
load("@io_bazel_rules_docker//container:container.bzl", "container_image", "container_push")

# TypeScript compilation and build
npm_package_bin(
    name = "build",
    tool = "@admin_ui_npm//vite:bin",
    args = ["build"],
    data = [
        "package.json",
        "tsconfig.json",
        "tsconfig.app.json",
        "tsconfig.node.json",
        "vite.config.ts",
        "index.html",
        "@admin_ui_npm//:node_modules",
    ] + glob([
        "src/**/*",
        "public/**/*",
    ]),
    output_dir = True,
)

# Development server
npm_package_bin(
    name = "dev",
    tool = "@admin_ui_npm//vite:bin",
    args = ["dev", "--host", "0.0.0.0"],
    data = [
        "package.json",
        "tsconfig.json",
        "tsconfig.app.json",
        "tsconfig.node.json",
        "vite.config.ts",
        "index.html",
        "@admin_ui_npm//:node_modules",
    ] + glob([
        "src/**/*",
        "public/**/*",
    ]),
)

# Linting
npm_package_bin(
    name = "lint",
    tool = "@admin_ui_npm//eslint:bin",
    args = ["."],
    data = [
        "eslint.config.js",
        "@admin_ui_npm//:node_modules",
    ] + glob([
        "src/**/*",
    ]),
)

# Docker image for admin UI
container_image(
    name = "admin_ui_image",
    base = "@nginx_alpine//image",
    files = [":build"],
    directory = "/usr/share/nginx/html",
    ports = ["80"],
    visibility = ["//visibility:public"],
)

# Container push rule (optional - for registry push)
container_push(
    name = "push_admin_ui",
    image = ":admin_ui_image",
    registry = "your-registry.com",
    repository = "chat-appointment/admin-ui",
    tag = "latest",
)