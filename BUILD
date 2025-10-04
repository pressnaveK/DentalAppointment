# Root BUILD file for workspace-wide targets

load("@io_bazel_rules_docker//container:container.bzl", "container_push")

# Convenience target to build all services
alias(
    name = "all_services",
    actual = select({
        "//conditions:default": [
            "//api/bot_service:bot_service",
            "//api/user_service:user_service",
        ],
    }),
)

# Convenience target to build all UIs
alias(
    name = "all_uis",
    actual = select({
        "//conditions:default": [
            "//ui/admin_ui:build",
            "//ui/client_ui:build",
        ],
    }),
)

# Convenience target to build all Docker images
alias(
    name = "all_images",
    actual = select({
        "//conditions:default": [
            "//api/bot_service:bot_service_image",
            "//api/user_service:user_service_image",
            "//ui/admin_ui:admin_ui_image",
            "//ui/client_ui:client_ui_image",
        ],
    }),
)

# Test all services
test_suite(
    name = "all_tests",
    tests = [
        "//api/user_service:test",
        # Add other test targets as they become available
    ],
)

# Lint all services
alias(
    name = "all_lint",
    actual = select({
        "//conditions:default": [
            "//api/user_service:lint",
            "//ui/admin_ui:lint",
            "//ui/client_ui:lint",
        ],
    }),
)