<?php

/**
 * MobileDataManager
 *
 * A RaspAP plugin to manage 4G/LTE QMI modems via ModemManager and NetworkManager.
 * Designed for devices like the Fairphone 2 running Linux with rmtfs + ModemManager.
 *
 * Uses mmcli for modem status/information and nmcli for connection management.
 * Connection profiles are created with: nmcli connection add type gsm ifname '*' con-name gsm apn <APN>
 * Connections are activated with: nmcli connection up gsm
 *
 * plugins/MobileDataManager                              (folder)
 * plugins/MobileDataManager/MobileDataManager.php        (file)
 * namespace RaspAP\Plugins\MobileDataManager              (namespace)
 * class MobileDataManager implements PluginInterface      (class)
 *
 * @description A plugin to manage 4G/LTE modems via ModemManager/NetworkManager
 * @author      Marc
 * @license     https://github.com/raspap/raspap-webgui/blob/master/LICENSE
 * @see         src/RaspAP/Plugins/PluginInterface.php
 * @see         src/RaspAP/UI/Sidebar.php
 */

namespace RaspAP\Plugins\MobileDataManager;

use RaspAP\Plugins\PluginInterface;
use RaspAP\UI\Sidebar;

class MobileDataManager implements PluginInterface
{

    private string $pluginPath;
    private string $pluginName;
    private string $templateMain;

    // Default NM connection profile name
    const NM_CON_NAME = 'gsm';

    public function __construct(string $pluginPath, string $pluginName)
    {
        $this->pluginPath = $pluginPath;
        $this->pluginName = $pluginName;
        $this->templateMain = 'main';
    }

    /**
     * Initializes the plugin and creates a sidebar item
     *
     * @param Sidebar $sidebar an instance of the Sidebar
     */
    public function initialize(Sidebar $sidebar): void
    {
        $label = _('Mobile Data');
        $icon = 'fas fa-signal';
        $action = 'plugin__'.$this->getName();
        $priority = 55;

        $sidebar->addItem($label, $icon, $action, $priority);
    }

    /**
     * Handles a page action by processing inputs and rendering the plugin template
     *
     * @param string $page the current page route
     */
    public function handlePageAction(string $page): bool
    {
        if (strpos($page, "/plugin__" . $this->getName()) !== 0) {
            return false;
        }

        $status = new \RaspAP\Messages\StatusMessage;

        if (!empty($_POST)) {
            $this->handlePostActions($status);
        }

        // Gather data for templates
        $modemDetected = $this->isModemDetected();
        $modemInfo = $this->getModemInfo();
        $modemStatus = $this->extractModemStatus($modemInfo);
        $signalInfo = $this->getSignalInfo();
        $simInfo = $this->getSimInfo($modemInfo);
        $connectionInfo = $this->getConnectionInfo();
        $bearerInfo = $this->getBearerInfo($modemInfo);

        // Determine service status for the LED indicator
        $serviceStatus = 'down';
        if ($modemDetected && ($modemStatus['state'] ?? '') === 'connected') {
            $serviceStatus = 'up';
        } elseif ($modemDetected) {
            $serviceStatus = 'idle';
        }

        $__template_data = [
            'title' => _('Mobile Data'),
            'description' => _('Manage 4G/LTE modem via ModemManager and NetworkManager'),
            'author' => 'Marc',
            'uri' => 'https://github.com/Spin42/MobileDataManager',
            'icon' => 'fas fa-signal',
            'serviceStatus' => $serviceStatus,
            'serviceName' => 'ModemManager.service',
            'action' => 'plugin__'.$this->getName(),
            'pluginName' => $this->getName(),
            'modemDetected' => $modemDetected,
            'modemInfo' => $modemInfo,
            'modemStatus' => $modemStatus,
            'signalInfo' => $signalInfo,
            'simInfo' => $simInfo,
            'connectionInfo' => $connectionInfo,
            'bearerInfo' => $bearerInfo,
        ];

        echo $this->renderTemplate($this->templateMain, compact(
            "status",
            "__template_data"
        ));
        return true;
    }

    /**
     * Renders a template from inside the plugin's template directory
     *
     * @param string $templateName
     * @param array $__data
     */
    public function renderTemplate(string $templateName, array $__data = []): string
    {
        $templateFile = "{$this->pluginPath}/{$this->getName()}/templates/{$templateName}.php";

        if (!file_exists($templateFile)) {
            return "Template file {$templateFile} not found.";
        }
        if (!empty($__data)) {
            extract($__data);
        }

        ob_start();
        include $templateFile;
        return ob_get_clean();
    }

    /**
     * Process POST form submissions
     */
    private function handlePostActions(\RaspAP\Messages\StatusMessage $status): void
    {
        if (isset($_POST['saveConnection'])) {
            $this->saveConnectionSettings($status);
        } elseif (isset($_POST['connectModem'])) {
            $this->connectModem($status);
        } elseif (isset($_POST['disconnectModem'])) {
            $this->disconnectModem($status);
        } elseif (isset($_POST['unlockSim'])) {
            $this->unlockSim($status);
        } elseif (isset($_POST['deleteConnection'])) {
            $this->deleteConnection($status);
        }
    }

    // -----------------------------------------------------------------
    //  Actions: nmcli connection management
    // -----------------------------------------------------------------

    /**
     * Create or update a GSM connection profile via nmcli.
     * This mirrors: nmcli connection add type gsm ifname '*' con-name gsm apn <APN>
     */
    private function saveConnectionSettings(\RaspAP\Messages\StatusMessage $status): void
    {
        $apn = trim($_POST['apn'] ?? '');
        $conName = trim($_POST['conName'] ?? self::NM_CON_NAME);
        $username = trim($_POST['nmUser'] ?? '');
        $password = trim($_POST['nmPass'] ?? '');
        $pinCode = trim($_POST['pinCode'] ?? '');

        if (empty($apn)) {
            $status->addMessage('APN is required.', 'danger');
            return;
        }

        // Check if connection already exists
        $connectionExists = $this->nmConnectionExists($conName);

        if ($connectionExists) {
            $cmd = sprintf(
                "sudo nmcli connection modify %s gsm.apn %s",
                escapeshellarg($conName),
                escapeshellarg($apn)
            );
            if (!empty($username)) {
                $cmd .= " gsm.username " . escapeshellarg($username);
            } else {
                $cmd .= " gsm.username ''";
            }
            if (!empty($password)) {
                $cmd .= " gsm.password " . escapeshellarg($password);
            } else {
                $cmd .= " gsm.password ''";
            }
            if (!empty($pinCode)) {
                $cmd .= " gsm.pin " . escapeshellarg($pinCode);
            } else {
                $cmd .= " gsm.pin ''";
            }
        } else {
            $cmd = sprintf(
                "sudo nmcli connection add type gsm ifname %s con-name %s apn %s",
                escapeshellarg('*'),
                escapeshellarg($conName),
                escapeshellarg($apn)
            );
            if (!empty($username)) {
                $cmd .= " gsm.username " . escapeshellarg($username);
            }
            if (!empty($password)) {
                $cmd .= " gsm.password " . escapeshellarg($password);
            }
            if (!empty($pinCode)) {
                $cmd .= " gsm.pin " . escapeshellarg($pinCode);
            }
        }

        exec($cmd . " 2>&1", $output, $retval);
        if ($retval === 0) {
            $verb = $connectionExists ? 'updated' : 'created';
            $status->addMessage("Connection profile '{$conName}' {$verb} successfully.", 'success');
        } else {
            $status->addMessage('Failed to save connection: ' . implode(' ', $output), 'danger');
        }
    }

    /**
     * Bring up the GSM connection: nmcli connection up <name>
     */
    private function connectModem(\RaspAP\Messages\StatusMessage $status): void
    {
        $conName = trim($_POST['conName'] ?? self::NM_CON_NAME);
        exec("sudo nmcli connection up " . escapeshellarg($conName) . " 2>&1", $output, $retval);
        if ($retval === 0) {
            $status->addMessage('Mobile data connection activated.', 'success');
        } else {
            $status->addMessage('Failed to connect: ' . implode(' ', $output), 'danger');
        }
    }

    /**
     * Bring down the GSM connection: nmcli connection down <name>
     */
    private function disconnectModem(\RaspAP\Messages\StatusMessage $status): void
    {
        $conName = trim($_POST['conName'] ?? self::NM_CON_NAME);
        exec("sudo nmcli connection down " . escapeshellarg($conName) . " 2>&1", $output, $retval);
        if ($retval === 0) {
            $status->addMessage('Mobile data connection deactivated.', 'success');
        } else {
            $status->addMessage('Failed to disconnect: ' . implode(' ', $output), 'danger');
        }
    }

    /**
     * Delete a GSM connection profile: nmcli connection delete <name>
     */
    private function deleteConnection(\RaspAP\Messages\StatusMessage $status): void
    {
        $conName = trim($_POST['conName'] ?? self::NM_CON_NAME);
        exec("sudo nmcli connection delete " . escapeshellarg($conName) . " 2>&1", $output, $retval);
        if ($retval === 0) {
            $status->addMessage("Connection profile '{$conName}' deleted.", 'success');
        } else {
            $status->addMessage('Failed to delete connection: ' . implode(' ', $output), 'danger');
        }
    }

    /**
     * Unlock SIM card with PIN via mmcli
     */
    private function unlockSim(\RaspAP\Messages\StatusMessage $status): void
    {
        $pin = trim($_POST['simPin'] ?? '');
        if (empty($pin) || !preg_match('/^\d{4,8}$/', $pin)) {
            $status->addMessage('Invalid SIM PIN. Must be 4-8 digits.', 'danger');
            return;
        }

        $modemIndex = $this->getModemIndex();
        if ($modemIndex === null) {
            $status->addMessage('No modem detected.', 'danger');
            return;
        }

        exec("sudo mmcli -m {$modemIndex} --pin=" . escapeshellarg($pin) . " 2>&1", $output, $retval);
        if ($retval === 0) {
            $status->addMessage('SIM unlocked successfully.', 'success');
        } else {
            $status->addMessage('Failed to unlock SIM: ' . implode(' ', $output), 'danger');
        }
    }

    // -----------------------------------------------------------------
    //  ModemManager queries (mmcli)
    // -----------------------------------------------------------------

    /**
     * Check if ModemManager detects any modem
     */
    public function isModemDetected(): bool
    {
        return $this->getModemIndex() !== null;
    }

    /**
     * Get the first modem index from: mmcli -L
     */
    private function getModemIndex(): ?int
    {
        exec("mmcli -L 2>/dev/null", $lines, $retval);
        if ($retval !== 0) return null;

        foreach ($lines as $line) {
            if (preg_match('/\/Modem\/(\d+)/', $line, $m)) {
                return (int)$m[1];
            }
        }
        return null;
    }

    /**
     * Get full modem info: mmcli -m <index>
     * Returns parsed key-value pairs grouped by section.
     */
    public function getModemInfo(): array
    {
        $idx = $this->getModemIndex();
        if ($idx === null) return [];

        exec("mmcli -m {$idx} 2>/dev/null", $lines);
        return $this->parseMmcliOutput($lines);
    }

    /**
     * Extract relevant status fields from modem info
     */
    public function extractModemStatus(array $modemInfo): array
    {
        $fields = [
            'state', 'power state', 'access tech',
            'signal quality', 'failed reason',
        ];

        $result = [];
        foreach ($fields as $field) {
            $result[$field] = $modemInfo['Status'][$field] ?? 'N/A';
        }
        return $result;
    }

    /**
     * Get signal quality details: mmcli -m <index> --signal-get
     */
    public function getSignalInfo(): array
    {
        $idx = $this->getModemIndex();
        if ($idx === null) return [];

        exec("mmcli -m {$idx} --signal-get 2>/dev/null", $lines);
        return $this->parseMmcliOutput($lines);
    }

    /**
     * Get SIM card information: mmcli -i <sim-index>
     */
    public function getSimInfo(array $modemInfo): array
    {
        $simPath = $modemInfo['SIM']['primary sim path'] ?? '';
        if (empty($simPath) || $simPath === 'none') {
            return ['error' => 'No SIM card detected'];
        }

        if (preg_match('/\/SIM\/(\d+)/', $simPath, $m)) {
            exec("mmcli -i {$m[1]} 2>/dev/null", $lines);
            return $this->parseMmcliOutput($lines);
        }
        return [];
    }

    /**
     * Get bearer (active data session) information: mmcli -b <bearer-index>
     */
    public function getBearerInfo(array $modemInfo): array
    {
        // Bearer paths may be listed as space-separated or in a "paths" key
        $bearerPaths = $modemInfo['Bearers']['paths'] ?? '';
        if (empty($bearerPaths) || strpos($bearerPaths, 'none') !== false) {
            return [];
        }

        if (preg_match('/\/Bearer\/(\d+)/', $bearerPaths, $m)) {
            exec("mmcli -b {$m[1]} 2>/dev/null", $lines);
            return $this->parseMmcliOutput($lines);
        }
        return [];
    }

    // -----------------------------------------------------------------
    //  NetworkManager queries (nmcli)
    // -----------------------------------------------------------------

    /**
     * Check if a NM connection profile with the given name exists
     */
    private function nmConnectionExists(string $name): bool
    {
        exec("nmcli -t -f NAME connection show 2>/dev/null", $lines);
        return in_array($name, $lines);
    }

    /**
     * Get current NM GSM connection profile details
     */
    public function getConnectionInfo(): array
    {
        $result = [
            'exists' => false,
            'active' => false,
            'name' => '',
            'apn' => '',
            'username' => '',
            'pin' => '',
            'device' => '',
            'ip4' => '',
            'gw4' => '',
            'dns4' => '',
        ];

        // Find the first gsm-type connection
        exec("nmcli -t -f NAME,TYPE connection show 2>/dev/null", $lines);
        foreach ($lines as $line) {
            $parts = explode(':', $line);
            if (count($parts) >= 2 && $parts[1] === 'gsm') {
                $result['exists'] = true;
                $result['name'] = $parts[0];
                break;
            }
        }

        if (!$result['exists']) {
            return $result;
        }

        $conName = escapeshellarg($result['name']);

        // Read APN, username, pin
        exec("nmcli -t connection show {$conName} 2>/dev/null", $detailLines);
        foreach ($detailLines as $line) {
            if (strpos($line, 'gsm.apn:') === 0) {
                $result['apn'] = substr($line, strlen('gsm.apn:'));
            } elseif (strpos($line, 'gsm.username:') === 0) {
                $result['username'] = substr($line, strlen('gsm.username:'));
            } elseif (strpos($line, 'gsm.pin:') === 0) {
                $result['pin'] = substr($line, strlen('gsm.pin:'));
            }
        }

        // Check if active and get device
        exec("nmcli -t -f NAME,DEVICE connection show --active 2>/dev/null", $activeLines);
        foreach ($activeLines as $line) {
            $parts = explode(':', $line);
            if (count($parts) >= 2 && $parts[0] === $result['name']) {
                $result['active'] = true;
                $result['device'] = $parts[1];
                break;
            }
        }

        // If active, get IP details from the device
        if ($result['active'] && !empty($result['device'])) {
            $dev = escapeshellarg($result['device']);
            exec("nmcli -t -f IP4.ADDRESS,IP4.GATEWAY,IP4.DNS device show {$dev} 2>/dev/null", $ipLines);
            foreach ($ipLines as $line) {
                if (strpos($line, 'IP4.ADDRESS') === 0) {
                    $result['ip4'] = preg_replace('/^IP4\.ADDRESS\[\d+\]:/', '', $line);
                } elseif (strpos($line, 'IP4.GATEWAY') === 0) {
                    $result['gw4'] = preg_replace('/^IP4\.GATEWAY:/', '', $line);
                } elseif (strpos($line, 'IP4.DNS') === 0) {
                    $dns = preg_replace('/^IP4\.DNS\[\d+\]:/', '', $line);
                    $result['dns4'] = empty($result['dns4']) ? $dns : $result['dns4'] . ', ' . $dns;
                }
            }
        }

        return $result;
    }

    // -----------------------------------------------------------------
    //  Parsing helpers
    // -----------------------------------------------------------------

    /**
     * Parse mmcli tabular output into a nested associative array.
     *
     * mmcli outputs sections like:
     *   --------------------------------
     *   General  |                 path: /org/freedesktop/ModemManager1/Modem/0
     *            |            device id: abc123
     *   --------------------------------
     *   Status   |                state: connected
     *
     * @param array $lines raw output lines
     * @return array nested [Section => [key => value]]
     */
    private function parseMmcliOutput(array $lines): array
    {
        $result = [];
        $currentSection = 'General';

        foreach ($lines as $line) {
            if (preg_match('/^[\s\-]+$/', $line) || trim($line) === '') {
                continue;
            }

            if (preg_match('/^\s*([^|]*?)\s*\|\s*(.+)$/', $line, $m)) {
                $sectionPart = trim($m[1]);
                $kvPart = trim($m[2]);

                if (!empty($sectionPart)) {
                    $currentSection = $sectionPart;
                }

                // Split on first colon only
                if (preg_match('/^(.+?):\s*(.*)$/', $kvPart, $kv)) {
                    $key = trim($kv[1]);
                    $value = trim($kv[2]);
                    $result[$currentSection][$key] = $value;
                }
            }
        }

        return $result;
    }

    /**
     * Returns an abbreviated class name (required by PluginManager)
     */
    public static function getName(): string
    {
        return basename(str_replace('\\', '/', static::class));
    }

}
