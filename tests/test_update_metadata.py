import subprocess
import unittest
from pathlib import Path


SOURCE = (Path(__file__).resolve().parents[1] /
          "root/usr/share/AdGuardHome/update_core.sh").read_text()
FUNCTIONS = SOURCE[SOURCE.index("check_if_already_running(){"):
                   SOURCE.index("\nmain(){")]


class UpdateMetadataTest(unittest.TestCase):
    def run_shell(self, script):
        return subprocess.run(
            ["bash", "-c", "set -e\n" + FUNCTIONS + "\n" + script],
            capture_output=True, text=True,
        )

    def test_channel_metadata_and_arm64_asset(self):
        result = self.run_shell("""
uci() { printf '%s' "$selected_channel"; }
curl() {
    case "${*: -1}" in
        */beta/version.json) printf 'v1.0.0-b.2';;
        */release/version.json) printf 'v0.107.80';;
        *) return 1;;
    esac
}
jsonfilter() {
    case "$*" in
        *'@.version') printf '%s' "$2";;
        *'@.download_linux_arm64') printf 'https://static.adtidy.org/core.tar.gz';;
        *) return 1;;
    esac
}
for selected_channel in beta ''; do
    load_update_metadata
    printf '%s %s\n' "$latest_ver" "$(metadata_value download_linux_arm64)"
done
""")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.splitlines(), [
            "v1.0.0-b.2 https://static.adtidy.org/core.tar.gz",
            "v0.107.80 https://static.adtidy.org/core.tar.gz",
        ])

    def test_missing_metadata_is_rejected(self):
        result = self.run_shell("""
uci() { return 1; }
curl() { return 22; }
if load_update_metadata; then exit 1; else test "$?" -eq 1; fi
""")
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_prerelease_suffix_is_preserved(self):
        result = self.run_shell("""
core() { echo 'AdGuard Home, version v1.0.0-b.2'; }
core_version core
""")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "v1.0.0-b.2")
