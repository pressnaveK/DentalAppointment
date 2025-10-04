workspace(name = "chat_appointment")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# Rules for Node.js
http_archive(
    name = "build_bazel_rules_nodejs",
    sha256 = "5dd1e5dea1322174c57d3ca7b899da381d516220793d0adef3ba03b9d23baa8e",
    urls = ["https://github.com/bazelbuild/rules_nodejs/releases/download/5.8.4/rules_nodejs-5.8.4.tar.gz"],
)

load("@build_bazel_rules_nodejs//:repositories.bzl", "build_bazel_rules_nodejs_dependencies")
build_bazel_rules_nodejs_dependencies()

load("@build_bazel_rules_nodejs//:index.bzl", "node_repositories", "npm_install")
node_repositories(
    node_version = "18.19.0",
    npm_version = "10.2.3",
)

# Rules for Python
http_archive(
    name = "rules_python",
    sha256 = "c68bdc4fbec25de5b5493b8819cfc877c4ea299c0dcb15c244c5a00208cde311",
    strip_prefix = "rules_python-0.31.0",
    url = "https://github.com/bazelbuild/rules_python/releases/download/0.31.0/rules_python-0.31.0.tar.gz",
)

load("@rules_python//python:repositories.bzl", "py_repositories", "python_register_toolchains")
py_repositories()

python_register_toolchains(
    name = "python3_11",
    python_version = "3.11",
)

load("@python3_11//:defs.bzl", "interpreter")
load("@rules_python//python:pip.bzl", "pip_parse")

# Rules for Docker
http_archive(
    name = "io_bazel_rules_docker",
    sha256 = "b1e80761a8a8243d03ebca8845e9cc1ba6c82ce7c5179ce2b295cd36f7e394bf",
    urls = ["https://github.com/bazelbuild/rules_docker/releases/download/v0.25.0/rules_docker-v0.25.0.tar.gz"],
)

load("@io_bazel_rules_docker//repositories:repositories.bzl", container_repositories = "repositories")
container_repositories()

load("@io_bazel_rules_docker//repositories:deps.bzl", container_deps = "deps")
container_deps()

load("@io_bazel_rules_docker//python:image.bzl", _py_image_repos = "repositories")
_py_image_repos()

load("@io_bazel_rules_docker//nodejs:image.bzl", _nodejs_image_repos = "repositories")
_nodejs_image_repos()

# Install Python dependencies for bot_service
pip_parse(
    name = "bot_service_deps",
    requirements_lock = "//api/bot_service:requirements.txt",
)

load("@bot_service_deps//:requirements.bzl", "install_deps")
install_deps()

# Install npm dependencies for user_service
npm_install(
    name = "user_service_npm",
    package_json = "//api/user_service:package.json",
    package_lock_json = "//api/user_service:package-lock.json",
)

# Install npm dependencies for admin_ui
npm_install(
    name = "admin_ui_npm",
    package_json = "//ui/admin_ui:package.json",
    package_lock_json = "//ui/admin_ui:package-lock.json",
)

# Install npm dependencies for client_ui
npm_install(
    name = "client_ui_npm",
    package_json = "//ui/client_ui:package.json",
    package_lock_json = "//ui/client_ui:package-lock.json",
)