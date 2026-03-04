<div class="tab-pane active" id="mdmconnection">
  <h4 class="mt-3"><?php echo _("APN Settings"); ?></h4>
  <div class="row">
    <div class="mb-3 col-md-6 mt-2">
      <label for="apn"><?php echo _("Access Point Name (APN)"); ?></label>
      <input type="text" class="form-control" id="apn" name="apn"
        value="<?php echo htmlspecialchars($__template_data['connectionInfo']['apn'] ?? '', ENT_QUOTES); ?>"
        placeholder="e.g. internet, web.vodafone.de" required />
      <div class="invalid-feedback">
        <?php echo _("Please enter an APN."); ?>
      </div>
      <small class="form-text text-muted"><?php echo _("The APN provided by your mobile carrier."); ?></small>
    </div>
  </div>

  <div class="row">
    <div class="mb-3 col-md-6">
      <label for="nmUser"><?php echo _("Username"); ?> <small class="text-muted">(<?php echo _("optional"); ?>)</small></label>
      <input type="text" class="form-control" id="nmUser" name="nmUser"
        value="<?php echo htmlspecialchars($__template_data['connectionInfo']['username'] ?? '', ENT_QUOTES); ?>"
        placeholder="<?php echo _("Carrier username"); ?>" />
    </div>
  </div>

  <div class="row">
    <div class="mb-3 col-md-6">
      <label for="nmPass"><?php echo _("Password"); ?> <small class="text-muted">(<?php echo _("optional"); ?>)</small></label>
      <input type="password" class="form-control" id="nmPass" name="nmPass" value=""
        placeholder="<?php echo _("Carrier password"); ?>" />
      <small class="form-text text-muted"><?php echo _("Leave blank to keep existing password."); ?></small>
    </div>
  </div>

  <div class="row">
    <div class="mb-3 col-md-6">
      <label for="pinCode"><?php echo _("SIM PIN"); ?> <small class="text-muted">(<?php echo _("optional"); ?>)</small></label>
      <input type="password" class="form-control" id="pinCode" name="pinCode"
        value="<?php echo htmlspecialchars($__template_data['connectionInfo']['pin'] ?? '', ENT_QUOTES); ?>"
        placeholder="<?php echo _("SIM card PIN code"); ?>"
        pattern="\d{4,8}" />
      <small class="form-text text-muted"><?php echo _("4-8 digit PIN. Stored in the NM connection profile."); ?></small>
    </div>
  </div>

  <?php if ($__template_data['connectionInfo']['exists']) : ?>
    <h4 class="mt-3"><?php echo _("Connection Status"); ?></h4>
    <div class="row">
      <div class="col-md-6">
        <div class="table-responsive">
          <table class="table table-sm">
            <tbody>
              <tr>
                <td><strong><?php echo _("Profile name"); ?></strong></td>
                <td><?php echo htmlspecialchars($__template_data['connectionInfo']['name']); ?></td>
              </tr>
              <tr>
                <td><strong><?php echo _("State"); ?></strong></td>
                <td>
                  <?php if ($__template_data['connectionInfo']['active']) : ?>
                    <span class="badge bg-success"><?php echo _("Connected"); ?></span>
                  <?php else : ?>
                    <span class="badge bg-secondary"><?php echo _("Disconnected"); ?></span>
                  <?php endif; ?>
                </td>
              </tr>
              <?php if ($__template_data['connectionInfo']['active']) : ?>
              <tr>
                <td><strong><?php echo _("Device"); ?></strong></td>
                <td><code><?php echo htmlspecialchars($__template_data['connectionInfo']['device']); ?></code></td>
              </tr>
              <tr>
                <td><strong><?php echo _("IP Address"); ?></strong></td>
                <td><?php echo htmlspecialchars($__template_data['connectionInfo']['ip4']); ?></td>
              </tr>
              <tr>
                <td><strong><?php echo _("Gateway"); ?></strong></td>
                <td><?php echo htmlspecialchars($__template_data['connectionInfo']['gw4']); ?></td>
              </tr>
              <tr>
                <td><strong><?php echo _("DNS"); ?></strong></td>
                <td><?php echo htmlspecialchars($__template_data['connectionInfo']['dns4']); ?></td>
              </tr>
              <?php endif; ?>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  <?php else : ?>
    <div class="alert alert-info mt-3">
      <i class="fas fa-info-circle me-2"></i>
      <?php echo _("No GSM connection profile exists yet. Enter your APN above and click Save settings to create one."); ?>
    </div>
  <?php endif; ?>

  <?php
    $simInfo = $__template_data['simInfo'] ?? [];
    $simLock = $__template_data['modemInfo']['SIM']['state'] ?? '';
  ?>
  <?php if (stripos($simLock, 'locked') !== false) : ?>
    <h4 class="mt-3"><?php echo _("SIM Unlock"); ?></h4>
    <div class="row">
      <div class="mb-3 col-md-4">
        <label for="simPin"><?php echo _("Enter SIM PIN to unlock"); ?></label>
        <div class="input-group">
          <input type="password" class="form-control" id="simPin" name="simPin" pattern="\d{4,8}"
            placeholder="<?php echo _("PIN"); ?>" />
          <button type="submit" class="btn btn-outline-warning" name="unlockSim" value="1">
            <i class="fas fa-unlock me-1"></i><?php echo _("Unlock"); ?>
          </button>
        </div>
      </div>
    </div>
  <?php endif; ?>

</div><!-- /.tab-pane | connection tab -->
