<!-- about tab -->
<div class="tab-pane fade" id="mdmabout">
  <h4 class="mt-3 mb-3"><?php echo _("About"); ?></h4>
  <div class="col-12 mb-2">
    <code><?php echo $__template_data['pluginName']; ?></code> <?php echo _("was created by ") . $__template_data['author']; ?>.
  </div>
  <div class="col-12 mb-2">
    <?php echo _("Plugin description") . ": " . $__template_data['description']; ?>.
  </div>
  <div class="col-12 mb-2">
    <?php echo _("This plugin manages 4G/LTE QMI modems via ModemManager (mmcli) and NetworkManager (nmcli)."); ?>
    <?php echo _("Designed for devices like the Fairphone 2 running mainline Linux with rmtfs."); ?>
  </div>
  <div class="col-12 mb-3">
    <h5 class="mt-3"><?php echo _("Requirements"); ?></h5>
    <ul>
      <li><code>modem-manager</code> &mdash; <?php echo _("ModemManager daemon"); ?></li>
      <li><code>network-manager</code> &mdash; <?php echo _("NetworkManager daemon"); ?></li>
      <li><code>libqmi-utils</code> &mdash; <?php echo _("QMI modem utilities (provides qmicli)"); ?></li>
      <li><code>rmtfs</code> &mdash; <?php echo _("Remote filesystem service for Qualcomm modems"); ?></li>
    </ul>
  </div>
  <div class="col-12 mb-3">
    <h5><?php echo _("Quick setup"); ?></h5>
    <p><?php echo _("From the command line:"); ?></p>
    <pre class="bg-light p-2">nmcli connection add type gsm ifname '*' con-name gsm apn &lt;YOUR_APN&gt;
nmcli connection up gsm</pre>
    <p><?php echo _("Or use the Connection tab in this plugin to configure the same via the web interface."); ?></p>
  </div>
  <div class="col-6 mb-3">
    GitHub <i class="fa-brands fa-github"></i> <a href="<?php echo $__template_data['uri']; ?>" target="_blank" rel="noopener"><?php echo $__template_data['pluginName']; ?></a>
  </div>
</div><!-- /.tab-pane -->
