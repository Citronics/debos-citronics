  <?php ob_start() ?>
    <input type="submit" class="btn btn-outline btn-primary" name="saveConnection" value="<?php echo _("Save settings"); ?>" />
    <?php if ($__template_data['connectionInfo']['exists']) : ?>
      <?php if ($__template_data['connectionInfo']['active']) : ?>
        <input type="submit" class="btn btn-warning" name="disconnectModem" value="<?php echo _("Disconnect"); ?>" />
      <?php else : ?>
        <input type="submit" class="btn btn-success" name="connectModem" value="<?php echo _("Connect"); ?>" />
      <?php endif; ?>
      <input type="submit" class="btn btn-outline-danger" name="deleteConnection" value="<?php echo _("Delete profile"); ?>"
        onclick="return confirm('<?php echo _("Delete this connection profile?"); ?>')" />
    <?php endif; ?>
  <?php $buttons = ob_get_clean(); ob_end_clean() ?>

  <div class="row">
    <div class="col-lg-12">
      <div class="card">
        <div class="card-header">
          <div class="row">
            <div class="col">
              <i class="<?php echo $__template_data['icon']; ?> me-2"></i><?php echo htmlspecialchars($__template_data['title']); ?>
            </div>
            <div class="col">
              <button class="btn btn-light btn-icon-split btn-sm service-status float-end">
                <span class="icon text-gray-600"><i class="fas fa-circle service-status-<?php echo $__template_data['serviceStatus']; ?>"></i></span>
                <span class="text service-status"><?php echo $__template_data['serviceName']; ?></span>
              </button>
            </div>
          </div><!-- /.row -->
        </div><!-- /.card-header -->

        <div class="card-body">
        <?php $status->showMessages(); ?>

          <?php if (!$__template_data['modemDetected']) : ?>
            <div class="alert alert-warning">
              <i class="fas fa-exclamation-triangle me-2"></i>
              <?php echo _("No modem detected. Ensure ModemManager is running and your modem is recognized."); ?>
              <br><small class="text-muted"><?php echo _("Check: systemctl status ModemManager / mmcli -L"); ?></small>
            </div>
          <?php endif; ?>

          <form role="form" action="<?php echo $__template_data['action']; ?>" method="POST" class="needs-validation" novalidate>
            <?php echo \RaspAP\Tokens\CSRF::hiddenField(); ?>
            <input type="hidden" name="conName" value="<?php echo htmlspecialchars($__template_data['connectionInfo']['name'] ?: 'gsm', ENT_QUOTES); ?>" />

            <!-- Nav tabs -->
            <ul class="nav nav-tabs">
              <li class="nav-item"><a class="nav-link active" id="mdm-connection-tab" href="#mdmconnection" data-bs-toggle="tab"><?php echo _("Connection"); ?></a></li>
              <li class="nav-item"><a class="nav-link" id="mdm-status-tab" href="#mdmstatus" data-bs-toggle="tab"><?php echo _("Modem Status"); ?></a></li>
              <li class="nav-item"><a class="nav-link" id="mdm-about-tab" href="#mdmabout" data-bs-toggle="tab"><?php echo _("About"); ?></a></li>
            </ul>

            <!-- Tab panes -->
            <div class="tab-content">
              <?php echo renderTemplate("tabs/connection", $__template_data, $__template_data['pluginName']) ?>
              <?php echo renderTemplate("tabs/status", $__template_data, $__template_data['pluginName']) ?>
              <?php echo renderTemplate("tabs/about", $__template_data, $__template_data['pluginName']) ?>
            </div><!-- /.tab-content -->

            <?php echo $buttons ?>
          </form>
        </div><!-- /.card-body -->

        <div class="card-footer"><?php echo _("Information provided by ModemManager and NetworkManager"); ?></div>
      </div><!-- /.card -->
    </div><!-- /.col-lg-12 -->
  </div><!-- /.row -->
