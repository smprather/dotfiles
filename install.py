#!/usr/bin/env python3
from __future__ import print_function

import argparse
import fnmatch
import gzip
import os
import re
import shutil
import stat
import subprocess
import sys
import tempfile
import zipfile


FONT_EXCLUDES = (
    "*.bdf",
    "*.eot",
    "*.fon",
    "*.otf",
    "*.pcf",
    "*.ttc",
    "*.ttf",
    "*.woff",
    "*.woff2",
)

BASH_LAYERS = ("corp", "site", "project", "user")
BASH_ENTRYPOINTS = (".bashrc", ".bash_profile", ".bash_login", ".profile")


def eprint(*args):
    print(*args, file=sys.stderr)


def command_exists(name):
    return shutil.which(name) is not None


def run(cmd, cwd=None, env=None, check=True, stdout=None, stderr=None):
    return subprocess.run(cmd, cwd=cwd, env=env, check=check, stdout=stdout, stderr=stderr)


def output(cmd, cwd=None, env=None, check=True):
    proc = subprocess.run(cmd, cwd=cwd, env=env, check=check, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    return proc.stdout.decode("utf-8", "replace")


def remove_path(path):
    if os.path.islink(path) or os.path.isfile(path):
        os.unlink(path)
    elif os.path.isdir(path):
        shutil.rmtree(path)


def lns(target, link_name, unsafe=False, verbose=False):
    if os.path.lexists(link_name):
        if os.path.isdir(link_name) and not os.path.islink(link_name):
            if not unsafe:
                eprint("Error: '{}' exists as a directory and cannot be removed (use --unsafe to override)".format(link_name))
                sys.exit(1)
            if verbose:
                eprint("rm -rf '{}'".format(link_name))
            shutil.rmtree(link_name)
        else:
            if verbose:
                eprint("rm -f '{}'".format(link_name))
            os.unlink(link_name)
    if verbose:
        eprint("ln -s {} {}".format(target, link_name))
    os.symlink(target, link_name)


def mkdirn(base_dir):
    target_dir = base_dir
    counter = 1
    while os.path.exists(target_dir):
        target_dir = "{}.{}".format(base_dir, counter)
        counter += 1
    os.makedirs(target_dir)
    return target_dir


def rsync_dir(src, dest, delete=False, excludes=None):
    cmd = ["rsync", "-a"]
    if delete:
        cmd.append("--delete")
    for pattern in excludes or ():
        cmd.append("--exclude={}".format(pattern))
    cmd.extend([src.rstrip("/") + "/", dest.rstrip("/") + "/"])
    run(cmd)


def install_path(src, dest, links_mode):
    if links_mode:
        lns(src, dest, verbose=True)
        return

    if os.path.isdir(src) and not os.path.islink(src):
        if os.path.lexists(dest):
            remove_path(dest)
        os.makedirs(dest)
        rsync_dir(src, dest)
        print("  rsync: {}/ -> {}/".format(src, dest))
    else:
        if os.path.lexists(dest):
            remove_path(dest)
        parent = os.path.dirname(dest)
        if parent:
            ensure_dir(parent)
        shutil.copy2(src, dest)
        print("  cp: {} -> {}".format(src, dest))


def backup_item(src, dest):
    ensure_dir(os.path.dirname(dest))
    cmd = ["rsync", "-a"]
    for pattern in FONT_EXCLUDES:
        cmd.append("--exclude={}".format(pattern))
    cmd.extend([src, dest])
    run(cmd)


def is_wsl():
    try:
        with open("/proc/version", "r") as fh:
            return re.search(r"microsoft|wsl", fh.read(), re.IGNORECASE) is not None
    except IOError:
        return False


def uname(flag):
    return output(["uname", flag]).strip()


def ldd_is_musl():
    proc = subprocess.run(["ldd", "--version"], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    return b"musl" in proc.stdout.lower()


def treesitter_platform_id():
    libc = "musl" if ldd_is_musl() else "glibc"
    return "{}-{}-{}".format(uname("-s").lower(), uname("-m"), libc)


def glibc_version_id():
    try:
        text = output(["getconf", "GNU_LIBC_VERSION"], check=False).strip()
        parts = text.split()
        if len(parts) >= 2:
            return parts[1]
    except OSError:
        pass
    proc = subprocess.run(["ldd", "--version"], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    match = re.search(rb"[0-9]+\.[0-9]+", proc.stdout)
    return match.group(0).decode("ascii") if match else ""


def glibc_version_num(version):
    match = re.match(r"^([0-9]+)\.([0-9]+)", version or "")
    if not match:
        return 0
    return int(match.group(1)) * 1000 + int(match.group(2))


def read_os_release():
    data = {}
    try:
        with open("/etc/os-release", "r") as fh:
            for line in fh:
                line = line.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                key, value = line.split("=", 1)
                data[key] = value.strip().strip('"')
    except IOError:
        pass
    return data


def prebuilt_exact_platform_ids():
    arch = uname("-m")
    if ldd_is_musl():
        return ["linux.{}.musl".format(arch), "linux-{}-musl".format(arch)]

    glibc_version = glibc_version_id()
    glibc_id = "glibc{}".format(glibc_version.replace(".", "p")) if glibc_version else ""
    osr = read_os_release()
    distro_id = osr.get("ID", "")
    id_like = osr.get("ID_LIKE", "")
    version_id = osr.get("VERSION_ID", "")
    platform_id = osr.get("PLATFORM_ID", "")
    el_id = ""

    if platform_id.startswith("platform:el"):
        el_id = platform_id[len("platform:"):]
    elif any(x in (" " + distro_id + " " + id_like + " ") for x in (" rhel ", " centos ", " almalinux ", " rocky ", " ol ")):
        el_id = "el{}".format(version_id.split(".", 1)[0])

    ids = []
    if el_id and glibc_id:
        ids.append("{}.{}.{}".format(el_id, arch, glibc_id))
    if glibc_id:
        ids.append("linux.{}.{}".format(arch, glibc_id))
    ids.append("linux.{}.glibc".format(arch))
    ids.append("linux-{}-glibc".format(arch))
    return ids


def select_prebuilt_platform_dir(root_dir):
    for candidate in prebuilt_exact_platform_ids():
        path = os.path.join(root_dir, candidate)
        if os.path.isdir(path):
            return path

    arch = uname("-m")
    host_num = glibc_version_num(glibc_version_id())
    if not host_num:
        return None

    best_dir = None
    best_num = 0
    if not os.path.isdir(root_dir):
        return None
    for name in os.listdir(root_dir):
        path = os.path.join(root_dir, name)
        if not os.path.isdir(path):
            continue
        if not (fnmatch.fnmatch(name, "el*.{}.glibc*p*".format(arch)) or fnmatch.fnmatch(name, "linux.{}.glibc*p*".format(arch))):
            continue
        match = re.search(r"\.glibc([0-9]+)p([0-9]+)$", name)
        if not match:
            continue
        build_num = glibc_version_num("{}.{}".format(match.group(1), match.group(2)))
        if build_num <= host_num and build_num > best_num:
            best_num = build_num
            best_dir = path
    return best_dir


def install_mode(args):
    if args.dev:
        return "dev"
    if args.links:
        return "links"
    return "copy"


def install_prebuilt_binaries(repo_dir, home):
    root_dir = os.path.join(repo_dir, "pre_built")
    dest_bin_dir = os.path.join(home, ".local", "bin")
    dest_lib64_dir = os.path.join(home, ".local", "lib64")

    print("Installing pre-built binaries...")
    if not os.path.isdir(root_dir):
        print("  No pre_built directory found, skipping")
        return

    src_dir = select_prebuilt_platform_dir(root_dir)
    if not src_dir:
        print("  No matching pre-built platform found, skipping")
        print("  Checked: {}".format(" ".join(prebuilt_exact_platform_ids())))
        return

    bin_dir = os.path.join(src_dir, "bin")
    if os.path.isdir(bin_dir):
        ensure_dir(dest_bin_dir)
        for gz_file in sorted(fnmatch.filter([os.path.join(bin_dir, x) for x in os.listdir(bin_dir)], "*.gz")):
            dest_file = os.path.join(dest_bin_dir, os.path.basename(gz_file[:-3]))
            with gzip.open(gz_file, "rb") as src, open(dest_file, "wb") as dest:
                shutil.copyfileobj(src, dest)
            os.chmod(dest_file, 0o755)
            print("  gzip: {} -> {}".format(gz_file, dest_file))

    lib64_dir = os.path.join(src_dir, "lib64")
    if os.path.isdir(lib64_dir):
        ensure_dir(dest_lib64_dir)
        for gz_file in sorted(fnmatch.filter([os.path.join(lib64_dir, x) for x in os.listdir(lib64_dir)], "*.gz")):
            dest_file = os.path.join(dest_lib64_dir, os.path.basename(gz_file[:-3]))
            with gzip.open(gz_file, "rb") as src, open(dest_file, "wb") as dest:
                shutil.copyfileobj(src, dest)
            os.chmod(dest_file, 0o644)
            print("  gzip: {} -> {}".format(gz_file, dest_file))

    patch_prebuilt_binary_rpaths(dest_bin_dir)
    check_prebuilt_binary_dependencies(dest_bin_dir)
    print("  Installed: {}/ -> {}/.local/".format(src_dir, home))


def patch_prebuilt_binary_rpaths(dest_bin_dir):
    patchelf = os.path.join(dest_bin_dir, "patchelf")
    rpath = "$ORIGIN/../lib64:$ORIGIN/../lib"
    if not os.path.isfile(patchelf) or not os.access(patchelf, os.X_OK):
        print("  Warning: vendored patchelf not installed; skipping pre-built binary RPATH patching")
        return

    for name in sorted(os.listdir(dest_bin_dir)) if os.path.isdir(dest_bin_dir) else []:
        binary = os.path.join(dest_bin_dir, name)
        if binary == patchelf or not os.path.isfile(binary) or not os.access(binary, os.X_OK):
            continue
        proc = subprocess.run([patchelf, "--print-interpreter", binary], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        if proc.returncode != 0:
            continue
        proc = subprocess.run([patchelf, "--set-rpath", rpath, binary])
        if proc.returncode != 0:
            print("  Warning: failed to patch RPATH for {}".format(binary))
            continue
        print("  patchelf: set RPATH on {} to {}".format(binary, rpath))


def check_prebuilt_binary_dependencies(dest_bin_dir):
    if not command_exists("ldd"):
        print("  Warning: ldd is not available; skipping pre-built dependency check")
        return

    missing = False
    for name in sorted(os.listdir(dest_bin_dir)) if os.path.isdir(dest_bin_dir) else []:
        binary = os.path.join(dest_bin_dir, name)
        if not os.path.isfile(binary) or not os.access(binary, os.X_OK):
            continue
        proc = subprocess.run(["ldd", binary], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
        out = proc.stdout.decode("utf-8", "replace")
        if "not found" in out:
            missing = True
            print("  Warning: missing shared libraries for {}".format(binary))
            for line in out.splitlines():
                if "not found" in line:
                    print("    {}".format(line.split()[0]))
    if not missing:
        print("  Shared library check OK")


def font_member(name):
    lower = name.lower()
    return lower.endswith((".ttf", ".otf", ".pcf", ".bdf", ".pcf.gz", ".bdf.gz"))


def extract_font_zip(zip_path, user_fonts_dir):
    print("  Extracting: {} -> {}/".format(zip_path, user_fonts_dir))
    with zipfile.ZipFile(zip_path, "r") as zf:
        for member in zf.namelist():
            if not font_member(member):
                continue
            dest = os.path.join(user_fonts_dir, os.path.basename(member))
            if not os.path.basename(member):
                continue
            with zf.open(member) as src, open(dest, "wb") as out:
                shutil.copyfileobj(src, out)


def install_fonts(repo_dir, home):
    vendor_fonts_dir = os.path.join(repo_dir, "fonts")
    user_fonts_dir = os.path.join(home, ".local", "share", "fonts")

    if not os.path.isdir(vendor_fonts_dir):
        print("Installing fonts...")
        print("  No vendored fonts directory found, skipping")
        return

    print("Installing fonts...")
    if os.path.islink(user_fonts_dir):
        print("  Removing symlink: {}".format(user_fonts_dir))
        os.unlink(user_fonts_dir)
    elif os.path.isdir(user_fonts_dir):
        backup_path = user_fonts_dir + ".bak"
        counter = 1
        while os.path.exists(backup_path):
            backup_path = "{}.bak.{}".format(user_fonts_dir, counter)
            counter += 1
        print("  Backing up existing fonts dir: {} -> {}".format(user_fonts_dir, backup_path))
        shutil.move(user_fonts_dir, backup_path)
    os.makedirs(user_fonts_dir, exist_ok=True)

    for name in sorted(os.listdir(vendor_fonts_dir)):
        if name.endswith(".zip"):
            extract_font_zip(os.path.join(vendor_fonts_dir, name), user_fonts_dir)

    tmp_dir = None
    try:
        for name in sorted(os.listdir(vendor_fonts_dir)):
            if not name.endswith(".zip.part-000"):
                continue
            if tmp_dir is None:
                tmp_dir = tempfile.mkdtemp(prefix="dotfiles-fonts.", dir="/tmp")
            first_part = os.path.join(vendor_fonts_dir, name)
            split_base = first_part[:-len(".part-000")]
            rejoined_zip = os.path.join(tmp_dir, os.path.basename(split_base))
            print("  Rejoining: {}.part-* -> {}".format(split_base, rejoined_zip))
            with open(rejoined_zip, "wb") as dest:
                for part in sorted(os.path.join(vendor_fonts_dir, x)
                                   for x in fnmatch.filter(os.listdir(vendor_fonts_dir),
                                                           os.path.basename(split_base) + ".part-*")):
                    with open(part, "rb") as src:
                        shutil.copyfileobj(src, dest)
            extract_font_zip(rejoined_zip, user_fonts_dir)
    finally:
        if tmp_dir:
            shutil.rmtree(tmp_dir)

    for tool in ("mkfontscale", "mkfontdir"):
        if command_exists(tool):
            proc = subprocess.run([tool, user_fonts_dir], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            if proc.returncode != 0:
                print("  Warning: {} failed for {}".format(tool, user_fonts_dir))

    if command_exists("fc-cache"):
        proc = subprocess.run(["fc-cache", "-f", user_fonts_dir], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if proc.returncode != 0:
            print("  Warning: fc-cache failed for {}".format(user_fonts_dir))
    else:
        print("  Warning: fc-cache is not available; fontconfig cache was not refreshed")

    if is_wsl():
        print("  WSL note: Linux GUI apps use these fonts through fontconfig.")
        print("  WSL note: Windows Terminal needs fonts installed on the Windows side.")


def install_treesitter_parsers(repo_dir, home):
    platform = treesitter_platform_id()
    src_dir = os.path.join(repo_dir, "treesitter", "prebuilt", platform)
    dest_dir = os.path.join(home, ".local", "share", "nvim", "tree-sitter-parsers")

    print("Installing Tree-sitter parsers...")
    if not os.path.isdir(os.path.join(src_dir, "parser")):
        print("  No prebuilt parsers for {}, skipping".format(platform))
        return

    for subdir in ("parser", "queries", "build-info", "parser-info", "registry"):
        src = os.path.join(src_dir, subdir)
        if os.path.isdir(src):
            dest = os.path.join(dest_dir, subdir)
            ensure_dir(dest)
            rsync_dir(src, dest)
    print("  Installed: {}/ -> {}/".format(src_dir, dest_dir))


def install_nvim_treesitter_vendor(repo_dir, home):
    src_root = os.path.join(repo_dir, "treesitter", "vendor")
    dest_root = os.path.join(home, ".local", "share", "nvim", "dotfiles", "vendor")
    print("Installing vendored nvim-treesitter...")
    if not (os.path.isdir(os.path.join(src_root, "nvim-treesitter")) and os.path.isdir(os.path.join(src_root, "treesitter-parser-registry"))):
        print("  Vendored nvim-treesitter is missing, skipping")
        return

    ensure_dir(dest_root)
    rsync_dir(os.path.join(src_root, "nvim-treesitter"), os.path.join(dest_root, "nvim-treesitter"), delete=True, excludes=(".git",))
    rsync_dir(os.path.join(src_root, "treesitter-parser-registry"), os.path.join(dest_root, "treesitter-parser-registry"), delete=True, excludes=(".git",))
    print("  Installed: {}/ -> {}/".format(src_root, dest_root))


def restore_backup(backup_dir, home):
    if not os.path.isdir(backup_dir):
        eprint("Error: Backup directory not found: {}".format(backup_dir))
        sys.exit(1)

    print("Restoring dotfiles from backup: {}".format(backup_dir))
    print("")
    print("Removing current dotfiles...")
    bash_config = os.path.join(home, ".config", "bash")
    if os.path.islink(bash_config):
        os.unlink(bash_config)
    elif os.path.isdir(bash_config):
        remove_if_exists(os.path.join(bash_config, "global"))
        for name in ("functions.sh", "README.md", "bashrc"):
            remove_if_exists(os.path.join(bash_config, name))

    for rel in list(BASH_ENTRYPOINTS) + [".vimrc", ".tmux.conf", ".editorconfig", ".tmux", ".vim",
                                        ".config/nvim", ".config/tmux", ".config/editorconfig", ".config/starship", ".config/vim"]:
        path = os.path.join(home, rel)
        if os.path.exists(path) or os.path.islink(path):
            print("  Removing: {}".format(path))
            remove_path(path)

    print("")
    print("Restoring files from backup...")
    if not os.listdir(backup_dir):
        eprint("Error: Backup directory is empty")
        sys.exit(1)
    run(["cp", "-rPp", ".", home], cwd=backup_dir)
    print("")
    print("Backup restored successfully!")
    print("")
    print("Restored from: {}".format(backup_dir))


def remove_if_exists(path):
    if os.path.exists(path) or os.path.islink(path):
        remove_path(path)


def ensure_dir(path):
    """Create directory at path, first removing any dangling or non-directory symlink."""
    if os.path.islink(path) and not os.path.isdir(path):
        print("  Removing stale symlink: {}".format(path))
        os.unlink(path)
    os.makedirs(path, exist_ok=True)


def preserve_bash_layers_from_symlink(home):
    bash_config = os.path.join(home, ".config", "bash")
    saved = {}
    if os.path.islink(bash_config):
        for layer in BASH_LAYERS:
            src = os.path.join(bash_config, layer)
            if os.path.isdir(src):
                tmp = tempfile.mkdtemp(prefix="dotfiles_bash_{}_".format(layer), dir="/tmp")
                shutil.rmtree(tmp)
                shutil.copytree(src, tmp, symlinks=True)
                saved[layer] = tmp
        os.unlink(bash_config)
        os.makedirs(bash_config, exist_ok=True)
        for layer, tmp in saved.items():
            shutil.move(tmp, os.path.join(bash_config, layer))
    else:
        os.makedirs(bash_config, exist_ok=True)
        remove_if_exists(os.path.join(bash_config, "global"))
        for name in ("functions.sh", "README.md", "bashrc"):
            remove_if_exists(os.path.join(bash_config, name))


def install_bash(repo_dir, home, links_mode):
    bash_config = os.path.join(home, ".config", "bash")
    preserve_bash_layers_from_symlink(home)
    install_path(os.path.join(repo_dir, "bash", "global"), os.path.join(bash_config, "global"), links_mode)
    install_path(os.path.join(repo_dir, "bash", "functions.sh"), os.path.join(bash_config, "functions.sh"), links_mode)
    install_path(os.path.join(repo_dir, "bash", "README.md"), os.path.join(bash_config, "README.md"), links_mode)
    install_path(os.path.join(repo_dir, "bash", "bashrc"), os.path.join(bash_config, "bashrc"), links_mode)
    for entrypoint in BASH_ENTRYPOINTS:
        lns(".config/bash/bashrc", os.path.join(home, entrypoint), verbose=True)


def backup_existing(home, repo_dir):
    backup_rel = mkdirn(os.path.join(home, "dotfiles_backups", "backup"))
    backup_dir = os.path.abspath(backup_rel)
    print("Making backups in: {}".format(backup_dir))
    for rel in list(BASH_ENTRYPOINTS) + [".vimrc", ".vim", ".tmux", ".tmux.conf", ".editorconfig",
                                        ".config/vim", ".config/nvim", ".config/bash/global",
                                        ".config/bash/functions.sh", ".config/bash/README.md",
                                        ".config/bash/bashrc", ".config/tmux", ".config/starship",
                                        ".config/editorconfig"]:
        path = os.path.join(home, rel)
        if not (os.path.exists(path) or os.path.islink(path)):
            continue
        if os.path.islink(path):
            link_target = os.readlink(path)
            real = os.path.realpath(path) if os.path.exists(path) else ""
            if link_target.startswith(repo_dir) or real.startswith(repo_dir):
                print("  Skipping (points to repo): {}".format(rel))
                continue
        print("  Backing up: {}".format(rel))
        backup_item(path, os.path.join(backup_dir, rel))
    print("")
    return backup_dir


def install_dev_mode(repo_dir, home):
    config_dir = os.path.join(home, ".config")
    for name in ("nvim", "vim", "tmux", "starship", "editorconfig"):
        remove_if_exists(os.path.join(config_dir, name))
        lns(os.path.join(repo_dir, name), os.path.join(config_dir, name), verbose=True)

    install_bash(repo_dir, home, links_mode=True)
    lns(".config/vim/vimrc", os.path.join(home, ".vimrc"), verbose=True)
    lns(".config/vim/vim", os.path.join(home, ".vim"), verbose=True)
    lns(".config/tmux/tmux.conf", os.path.join(home, ".tmux.conf"), verbose=True)
    lns(".config/tmux/tmux", os.path.join(home, ".tmux"), verbose=True)
    lns(".config/editorconfig/editorconfig", os.path.join(home, ".editorconfig"), verbose=True)


def install_copy_or_links_mode(repo_dir, home, links_mode):
    for entrypoint in BASH_ENTRYPOINTS:
        remove_if_exists(os.path.join(home, entrypoint))
    install_bash(repo_dir, home, links_mode)

    nvim_config = os.path.join(home, ".config", "nvim")
    remove_if_exists(nvim_config)
    for sub in ("after/lsp", "after/ftplugin", "lsp", "lua/custom/plugins"):
        os.makedirs(os.path.join(nvim_config, sub), exist_ok=True)
    for rel in ("lua/custom/plugins/init.lua", "lua/kickstart", "doc", "lazy-lock.json", "README.md", "LICENSE.md", "init.lua"):
        install_path(os.path.join(repo_dir, "nvim", rel), os.path.join(nvim_config, rel), links_mode)
    for src in sorted(glob_paths(os.path.join(repo_dir, "nvim", "lsp"))):
        install_path(src, os.path.join(nvim_config, "lsp", os.path.basename(src)), links_mode)
    for src in sorted(glob_paths(os.path.join(repo_dir, "nvim", "after", "ftplugin"))):
        install_path(src, os.path.join(nvim_config, "after", "ftplugin", os.path.basename(src)), links_mode)
    for src in sorted(glob_paths(os.path.join(repo_dir, "nvim", "after", "lsp"))):
        install_path(src, os.path.join(nvim_config, "after", "lsp", os.path.basename(src)), links_mode)
    if not links_mode:
        plugins_dir = os.path.join(repo_dir, "nvim", "lua", "kickstart", "plugins")
        for src in sorted(glob_paths(plugins_dir)):
            install_path(src, os.path.join(nvim_config, "lua", "kickstart", "plugins", os.path.basename(src)), links_mode)

    remove_if_exists(os.path.join(home, ".vimrc"))
    remove_if_exists(os.path.join(home, ".vim"))
    vim_config = os.path.join(home, ".config", "vim")
    remove_if_exists(vim_config)
    os.makedirs(os.path.join(vim_config, "vim", "pack", "vendor", "start"), exist_ok=True)
    os.makedirs(os.path.join(vim_config, "vim", "pack", "vendor", "opt"), exist_ok=True)
    for start_or_opt in ("start", "opt"):
        for plugin_dir in sorted(glob_paths(os.path.join(repo_dir, "vim", "vim", "pack", "vendor", start_or_opt))):
            install_path(plugin_dir, os.path.join(vim_config, "vim", "pack", "vendor", start_or_opt, os.path.basename(plugin_dir)), links_mode)
    install_path(os.path.join(repo_dir, "vim", "vimrc"), os.path.join(vim_config, "vimrc"), links_mode)
    lns(".config/vim/vimrc", os.path.join(home, ".vimrc"), verbose=True)

    remove_if_exists(os.path.join(home, ".tmux.conf"))
    remove_if_exists(os.path.join(home, ".tmux"))
    tmux_config = os.path.join(home, ".config", "tmux")
    remove_if_exists(tmux_config)
    os.makedirs(os.path.join(tmux_config, "tmux", "plugins"), exist_ok=True)
    for plugin_dir in sorted(glob_paths(os.path.join(repo_dir, "tmux", "vendor", "plugins"))):
        install_path(plugin_dir, os.path.join(tmux_config, "tmux", "plugins", os.path.basename(plugin_dir)), links_mode)
    install_path(os.path.join(repo_dir, "tmux", "tmux.conf"), os.path.join(tmux_config, "tmux.conf"), links_mode)
    install_path(os.path.join(repo_dir, "tmux", "tmux-3col-layout.sh"), os.path.join(tmux_config, "tmux-3col-layout.sh"), links_mode)
    lns(".config/tmux/tmux.conf", os.path.join(home, ".tmux.conf"), verbose=True)
    lns(".config/tmux/tmux", os.path.join(home, ".tmux"), verbose=True)

    remove_if_exists(os.path.join(home, ".editorconfig"))
    editorconfig_dir = os.path.join(home, ".config", "editorconfig")
    remove_if_exists(editorconfig_dir)
    os.makedirs(editorconfig_dir, exist_ok=True)
    install_path(os.path.join(repo_dir, "editorconfig", "editorconfig"), os.path.join(editorconfig_dir, "editorconfig"), links_mode)
    lns(".config/editorconfig/editorconfig", os.path.join(home, ".editorconfig"), verbose=True)

    starship_dir = os.path.join(home, ".config", "starship")
    remove_if_exists(starship_dir)
    os.makedirs(starship_dir, exist_ok=True)
    install_path(os.path.join(repo_dir, "starship", "starship.toml"), os.path.join(starship_dir, "starship.toml"), links_mode)


def glob_paths(path):
    if not os.path.isdir(path):
        return []
    return [os.path.join(path, x) for x in os.listdir(path)]


def install_git_hooks(repo_dir, dev_mode):
    print("Installing git hooks...")
    if not dev_mode:
        print("  Skipped (use --dev for repo development hooks)")
        return
    hooks_dir = os.path.join(repo_dir, "hooks")
    if not os.path.isdir(hooks_dir):
        print("  No hooks directory found, skipping")
        return
    dest_dir = os.path.join(repo_dir, ".git", "hooks")
    for hook in sorted(os.listdir(hooks_dir)):
        src = os.path.join(hooks_dir, hook)
        if os.path.isfile(src) and "README" not in hook:
            dest = os.path.join(dest_dir, hook)
            shutil.copy2(src, dest)
            mode = os.stat(dest).st_mode
            os.chmod(dest, mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)
            print("  Installed: {}".format(hook))


def run_post_install_hooks(hooks, repo_dir, home, args, backup_dir):
    for hook in hooks:
        print("Running post-install hook: {}".format(hook))
        env = os.environ.copy()
        env.update({
            "DOTFILES_REPO": repo_dir,
            "DOTFILES_HOME": home,
            "DOTFILES_MODE": install_mode(args),
            "DOTFILES_BACKUP_DIR": backup_dir,
            "DOTFILES_NO_BACKUP": "1" if args.no_backup else "0",
            "DOTFILES_NO_FONTS": "1" if args.no_fonts else "0",
        })
        run(["bash", hook], env=env)


def run_layer_install_scripts(home):
    for layer in BASH_LAYERS:
        install_script = os.path.join(home, ".config", "bash", layer, "install.sh")
        if os.path.isfile(install_script) and os.access(install_script, os.R_OK):
            print("Sourcing '{}' ...".format(install_script))
            run(["bash", "-c", 'source "$1"', "bash", install_script])


def parse_args(argv):
    parser = argparse.ArgumentParser(
        prog="./install",
        description="Install dotfiles to the home directory.",
        add_help=False,
        formatter_class=argparse.RawTextHelpFormatter,
    )
    parser.add_argument("--dev", action="store_true")
    parser.add_argument("--links", action="store_true")
    parser.add_argument("--no-backup", action="store_true", dest="no_backup")
    parser.add_argument("--no-fonts", action="store_true", dest="no_fonts")
    parser.add_argument("--post-install-hook", action="append", default=[])
    parser.add_argument("--restore-backup")
    parser.add_argument("--verbose", action="store_true")
    parser.add_argument("--help", "-h", action="store_true")
    args, unknown = parser.parse_known_args(argv)
    if args.help:
        print_help()
        sys.exit(0)
    if unknown:
        eprint("Unknown option: {}".format(unknown[0]))
        eprint("Usage: ./install [--dev] [--links] [--no-backup] [--no-fonts] [--post-install-hook <script>] [--verbose] [--restore-backup <dir>]")
        eprint("Run './install --help' for details.")
        sys.exit(1)
    return args


def print_help():
    print("""Usage: ./install [OPTIONS]

Install dotfiles to the home directory.

Options:
  (default)                  Copy files from repo - no symlinks to the repo remain.
                             Re-run ./install after repo changes to update.

  --links                    Symlink individual files/dirs to the repo instead of copying.
                             Changes in the repo take effect immediately.

  --dev                      Directory-level symlinks to the repo (e.g. ~/.config/nvim -> repo/nvim).
                             Easiest when editing files frequently. Skips backups.

  --no-backup                Skip creating a backup of existing dotfiles before installing.

  --no-fonts                 Skip installing vendored fonts to ~/.local/share/fonts.

  --post-install-hook <script>
                             Run a corp/site/user script after global install steps.
                             Can be given multiple times; hooks run in argument order.
                             Hooks run with bash and receive DOTFILES_* env vars.

  --restore-backup <dir>     Restore dotfiles from a previous backup directory.
                             Example: ./install --restore-backup dotfiles_backups/backup.1

  --help, -h                 Show this help message.""")


def main(argv):
    if not command_exists("rsync"):
        eprint("Error: This script requires rsync.")
        return 1

    args = parse_args(argv)
    repo_dir = os.path.dirname(os.path.abspath(__file__))
    home = os.path.expanduser("~")

    if args.restore_backup:
        restore_backup(args.restore_backup, home)
        return 0

    print("Dotfiles repo base directory: {}".format(repo_dir))

    hooks = []
    for hook in args.post_install_hook:
        if not os.path.isfile(hook) or not os.access(hook, os.R_OK):
            eprint("Error: Post-install hook is not readable: {}".format(hook))
            return 1
        hooks.append(os.path.abspath(hook))

    print("Changing directory to ~")
    os.chdir(home)

    backup_dir = ""
    if not args.dev and not args.no_backup:
        backup_dir = backup_existing(home, repo_dir)

    ensure_dir(os.path.join(home, ".config"))
    if args.dev:
        install_dev_mode(repo_dir, home)
    else:
        install_copy_or_links_mode(repo_dir, home, args.links)

    if args.no_fonts:
        print("Installing fonts...")
        print("  Skipped (--no-fonts)")
    else:
        install_fonts(repo_dir, home)

    install_prebuilt_binaries(repo_dir, home)
    install_nvim_treesitter_vendor(repo_dir, home)
    install_treesitter_parsers(repo_dir, home)
    install_git_hooks(repo_dir, args.dev)
    run_post_install_hooks(hooks, repo_dir, home, args, backup_dir)
    run_layer_install_scripts(home)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
