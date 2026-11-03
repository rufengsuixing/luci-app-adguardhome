import os
from pathlib import Path
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[1]


class UpgradeStopTests(unittest.TestCase):
    def test_upgrade_stops_service_without_instance_argument(self):
        source = (ROOT / 'root/usr/share/AdGuardHome/update_core.sh').read_text()
        calls = [line.strip() for line in source.splitlines()
                 if '/etc/init.d/AdGuardHome stop' in line]
        self.assertEqual(len(calls), 2)
        for call in calls:
            command = call.replace('/etc/init.d/AdGuardHome', 'service_stub')
            result = subprocess.run(
                ['sh', '-c', 'service_stub() { printf "%s|%s|%s" '
                 '"$ADGUARDHOME_SKIP_BACKUP" "$#" "$1"; }; ' + command],
                capture_output=True, text=True, check=True)
            self.assertEqual(result.stdout, '1|1|stop')

    def test_stop_backup_policy(self):
        source = (ROOT / 'root/etc/init.d/AdGuardHome').read_text()
        start = source.index('stop_service()')
        function = source[start:source.index('\n}', start) + 2]
        for skip, expected in [('0', 'backup\n'), ('1', '')]:
            with self.subTest(skip=skip):
                result = subprocess.run(
                    ['bash', '-c', 'config_load() { :; }; _do_redirect() { :; }; '
                     'do_crontab() { :; }; config_get() { backupfile=filters; }; '
                     'backup() { echo backup; }; touch() { :; }; ' + function +
                     '\nstop_service'],
                    env=dict(os.environ, ADGUARDHOME_SKIP_BACKUP=skip),
                    capture_output=True, text=True, check=True)
                self.assertEqual(result.stdout.replace('AdGuardHome service disabled\n', ''), expected)


if __name__ == '__main__':
    unittest.main()
