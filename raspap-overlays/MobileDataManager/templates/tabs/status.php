<!-- status tab -->
<div class="tab-pane fade" id="mdmstatus">
  <h4 class="mt-3 mb-3"><?php echo _("Modem Information"); ?></h4>

  <?php if (!$__template_data['modemDetected']) : ?>
    <p class="text-muted"><?php echo _("No modem detected."); ?></p>
  <?php else : ?>

    <?php
      $modemInfo = $__template_data['modemInfo'];
      $modemStatus = $__template_data['modemStatus'];
      $signalInfo = $__template_data['signalInfo'];
      $simInfo = $__template_data['simInfo'];
      $bearerInfo = $__template_data['bearerInfo'];
    ?>

    <!-- Modem general info -->
    <div class="row">
      <div class="col-md-6">
        <div class="card mb-3">
          <div class="card-header"><i class="fas fa-microchip me-2"></i><?php echo _("Hardware"); ?></div>
          <div class="card-body p-0">
            <table class="table table-sm mb-0">
              <tbody>
                <?php
                  $hwFields = [
                    'manufacturer' => _('Manufacturer'),
                    'model' => _('Model'),
                    'firmware revision' => _('Firmware'),
                    'revision' => _('Revision'),
                    'carrier configuration' => _('Carrier config'),
                    'h/w revision' => _('Hardware revision'),
                    'equipment id' => _('IMEI'),
                  ];
                  $hw = $modemInfo['Hardware'] ?? $modemInfo['General'] ?? [];
                  // Also check 3GPP section for equipment id
                  $threeGpp = $modemInfo['3GPP'] ?? [];
                  foreach ($hwFields as $key => $label) :
                    $value = $hw[$key] ?? $threeGpp[$key] ?? ($modemInfo['General'][$key] ?? null);
                    if ($value === null) continue;
                ?>
                <tr>
                  <td class="w-50"><strong><?php echo $label; ?></strong></td>
                  <td><?php echo htmlspecialchars($value); ?></td>
                </tr>
                <?php endforeach; ?>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <div class="col-md-6">
        <div class="card mb-3">
          <div class="card-header"><i class="fas fa-info-circle me-2"></i><?php echo _("Status"); ?></div>
          <div class="card-body p-0">
            <table class="table table-sm mb-0">
              <tbody>
                <?php foreach ($modemStatus as $key => $value) : ?>
                  <?php if ($value === 'N/A') continue; ?>
                  <tr>
                    <td class="w-50"><strong><?php echo htmlspecialchars(ucfirst($key)); ?></strong></td>
                    <td>
                      <?php if ($key === 'state') : ?>
                        <?php
                          $badgeClass = 'bg-secondary';
                          if ($value === 'connected') $badgeClass = 'bg-success';
                          elseif ($value === 'registered') $badgeClass = 'bg-info';
                          elseif ($value === 'searching') $badgeClass = 'bg-warning';
                          elseif (strpos($value, 'failed') !== false || strpos($value, 'disabled') !== false) $badgeClass = 'bg-danger';
                        ?>
                        <span class="badge <?php echo $badgeClass; ?>"><?php echo htmlspecialchars($value); ?></span>
                      <?php elseif ($key === 'signal quality') : ?>
                        <?php
                          $pct = intval($value);
                          $barClass = 'bg-danger';
                          if ($pct >= 70) $barClass = 'bg-success';
                          elseif ($pct >= 40) $barClass = 'bg-warning';
                        ?>
                        <div class="progress" style="height: 20px;">
                          <div class="progress-bar <?php echo $barClass; ?>" role="progressbar"
                            style="width: <?php echo $pct; ?>%"
                            aria-valuenow="<?php echo $pct; ?>" aria-valuemin="0" aria-valuemax="100">
                            <?php echo htmlspecialchars($value); ?>
                          </div>
                        </div>
                      <?php else : ?>
                        <?php echo htmlspecialchars($value); ?>
                      <?php endif; ?>
                    </td>
                  </tr>
                <?php endforeach; ?>

                <?php
                  // Show operator from 3GPP section
                  $operator = $modemInfo['3GPP']['operator name'] ?? null;
                  if ($operator) :
                ?>
                <tr>
                  <td class="w-50"><strong><?php echo _("Operator"); ?></strong></td>
                  <td><?php echo htmlspecialchars($operator); ?></td>
                </tr>
                <?php endif; ?>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>

    <!-- SIM card info -->
    <?php if (!empty($simInfo) && !isset($simInfo['error'])) : ?>
    <div class="row">
      <div class="col-md-6">
        <div class="card mb-3">
          <div class="card-header"><i class="fas fa-sim-card me-2"></i><?php echo _("SIM Card"); ?></div>
          <div class="card-body p-0">
            <table class="table table-sm mb-0">
              <tbody>
                <?php
                  $simFields = [
                    'imsi' => _('IMSI'),
                    'iccid' => _('ICCID'),
                    'operator id' => _('Operator ID'),
                    'operator name' => _('Operator'),
                    'emergency numbers' => _('Emergency numbers'),
                  ];
                  $simProps = $simInfo['Properties'] ?? $simInfo['General'] ?? [];
                  foreach ($simFields as $key => $label) :
                    $value = $simProps[$key] ?? null;
                    if ($value === null) continue;
                ?>
                <tr>
                  <td class="w-50"><strong><?php echo $label; ?></strong></td>
                  <td><?php echo htmlspecialchars($value); ?></td>
                </tr>
                <?php endforeach; ?>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
    <?php elseif (isset($simInfo['error'])) : ?>
      <div class="alert alert-warning">
        <i class="fas fa-exclamation-triangle me-2"></i>
        <?php echo htmlspecialchars($simInfo['error']); ?>
      </div>
    <?php endif; ?>

    <!-- Signal details -->
    <?php if (!empty($signalInfo)) : ?>
    <div class="row">
      <div class="col-md-6">
        <div class="card mb-3">
          <div class="card-header"><i class="fas fa-signal me-2"></i><?php echo _("Signal Details"); ?></div>
          <div class="card-body p-0">
            <table class="table table-sm mb-0">
              <tbody>
                <?php foreach ($signalInfo as $section => $fields) : ?>
                  <?php if (!is_array($fields)) continue; ?>
                  <tr class="table-light">
                    <td colspan="2"><strong><?php echo htmlspecialchars($section); ?></strong></td>
                  </tr>
                  <?php foreach ($fields as $key => $value) : ?>
                  <tr>
                    <td class="w-50 ps-4"><?php echo htmlspecialchars($key); ?></td>
                    <td><?php echo htmlspecialchars($value); ?></td>
                  </tr>
                  <?php endforeach; ?>
                <?php endforeach; ?>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
    <?php endif; ?>

    <!-- Bearer info (active data session) -->
    <?php if (!empty($bearerInfo)) : ?>
    <div class="row">
      <div class="col-md-6">
        <div class="card mb-3">
          <div class="card-header"><i class="fas fa-exchange-alt me-2"></i><?php echo _("Active Bearer"); ?></div>
          <div class="card-body p-0">
            <table class="table table-sm mb-0">
              <tbody>
                <?php foreach ($bearerInfo as $section => $fields) : ?>
                  <?php if (!is_array($fields)) continue; ?>
                  <tr class="table-light">
                    <td colspan="2"><strong><?php echo htmlspecialchars($section); ?></strong></td>
                  </tr>
                  <?php foreach ($fields as $key => $value) : ?>
                  <tr>
                    <td class="w-50 ps-4"><?php echo htmlspecialchars($key); ?></td>
                    <td><?php echo htmlspecialchars($value); ?></td>
                  </tr>
                  <?php endforeach; ?>
                <?php endforeach; ?>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
    <?php endif; ?>

    <!-- Raw mmcli output for debugging -->
    <h4 class="mt-3 mb-3"><?php echo _("Raw modem data"); ?></h4>
    <div class="row">
      <div class="col-md-8">
        <div class="accordion" id="rawDataAccordion">
          <div class="accordion-item">
            <h2 class="accordion-header">
              <button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#rawMmcli">
                <?php echo _("mmcli output (click to expand)"); ?>
              </button>
            </h2>
            <div id="rawMmcli" class="accordion-collapse collapse">
              <div class="accordion-body">
                <pre class="mb-0"><?php
                  foreach ($modemInfo as $section => $fields) {
                    echo htmlspecialchars($section) . "\n";
                    if (is_array($fields)) {
                      foreach ($fields as $k => $v) {
                        echo "  " . htmlspecialchars($k) . ": " . htmlspecialchars($v) . "\n";
                      }
                    }
                    echo "\n";
                  }
                ?></pre>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

  <?php endif; ?>
</div><!-- /.tab-pane -->
