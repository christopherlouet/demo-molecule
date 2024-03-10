import pytest


@pytest.mark.parametrize("name,version,distros", [
    ("nginx", "1.24", ["ubuntu", "rocky"]),
    ("php8.1-cli", "8.1", ["ubuntu"]),
    ("php8.1-common", "8.1", ["ubuntu"]),
    ("php8.1-fpm", "8.1", ["ubuntu"]),
    ("php-cli", "7.2", ["rocky"]),
    ("php-common", "7.2", ["rocky"]),
    ("php-fpm", "7.2", ["rocky"]),
])
def test_packages(host, name, version, distros):
    if host.system_info.distribution in distros:
        pkg = host.package(name)
        assert pkg.is_installed
        assert pkg.version.startswith(version)


@pytest.mark.parametrize("user,group", [
    ("app", "app"),
    ("nginx", "nginx"),
])
def test_users(host, user, group):
    usr = host.user(user)
    assert usr.exists
    assert usr.group == group


@pytest.mark.parametrize("filename,owner,group,mode", [
    ("/home/app/.bashrc", "app", "app", 0o644),
    ("/etc/nginx/conf.d/default.conf", "root", "root", 0o644),
    ("/usr/share/nginx/html/index.php", "nginx", "nginx", 0o644),
])
def test_confs(host, filename, owner, group, mode):
    target = host.file(filename)
    assert target.exists
    assert target.user == owner
    assert target.group == group
    assert target.mode == mode


@pytest.mark.parametrize("service_name,distros", [
    ("nginx", ["ubuntu", "rocky"]),
    ("php-fpm", ["rocky"]),
    ("php8.1-fpm", ["ubuntu"]),
])
def test_nginx_services(host, service_name, distros):
    if host.system_info.distribution in distros:
        service = host.service(service_name)
        assert service.is_enabled
        assert service.is_running


def test_nginx_status_code(host):
    command = host.run(f'curl -I http://localhost:80')
    assert command.rc == 0
    assert 'HTTP/1.1 200 OK' in command.stdout
